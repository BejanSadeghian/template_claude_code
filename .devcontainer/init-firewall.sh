#!/bin/bash
# Default-deny outbound firewall with a curated allowlist.
# Goal: keep --dangerously-skip-permissions reasonably safe while letting
# normal dev (npm/pip/git/Railway/Anthropic/etc.) work uninterrupted.
set -euo pipefail
IFS=$'\n\t'

ALLOW_FILE="${ALLOW_FILE:-/etc/allowed-domains.txt}"

# 1. Preserve Docker's internal DNS NAT rules before flushing
DOCKER_DNS_RULES=$(iptables-save -t nat | grep "127\.0\.0\.11" || true)

iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
ipset destroy allowed-domains 2>/dev/null || true

if [ -n "$DOCKER_DNS_RULES" ]; then
    iptables -t nat -N DOCKER_OUTPUT 2>/dev/null || true
    iptables -t nat -N DOCKER_POSTROUTING 2>/dev/null || true
    echo "$DOCKER_DNS_RULES" | xargs -L 1 iptables -t nat
fi

# DNS, SSH, localhost
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT  -p udp --sport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT  -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT  -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

ipset create allowed-domains hash:net

# GitHub IP ranges (web/api/git/actions/packages)
echo "Fetching GitHub IP ranges..."
gh_ranges=$(curl -fsS https://api.github.com/meta || true)
if [ -z "$gh_ranges" ] || ! echo "$gh_ranges" | jq -e '.web and .api and .git' >/dev/null; then
    echo "ERROR: Failed to fetch GitHub meta" >&2; exit 1
fi
while read -r cidr; do
    [[ "$cidr" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]] || continue
    ipset add -exist allowed-domains "$cidr"
done < <(echo "$gh_ranges" | jq -r '(.web + .api + .git + .actions + .packages)[]?' | aggregate -q)

# Resolve allowlist
echo "Resolving allowlist from $ALLOW_FILE..."
while IFS= read -r raw; do
    domain="${raw%%#*}"; domain="${domain// /}"
    [ -z "$domain" ] && continue
    ips=$(dig +short +time=3 +tries=2 A "$domain" | grep -E '^[0-9.]+$' || true)
    if [ -z "$ips" ]; then
        echo "WARN: could not resolve $domain (skipping)" >&2
        continue
    fi
    while read -r ip; do
        [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || continue
        ipset add -exist allowed-domains "$ip"
    done <<< "$ips"
done < "$ALLOW_FILE"

# Host LAN (so localhost services on host are reachable)
HOST_IP=$(ip route | awk '/default/ {print $3; exit}')
if [ -n "${HOST_IP:-}" ]; then
    HOST_NETWORK=$(echo "$HOST_IP" | sed "s/\.[0-9]*$/.0\/24/")
    iptables -A INPUT  -s "$HOST_NETWORK" -j ACCEPT
    iptables -A OUTPUT -d "$HOST_NETWORK" -j ACCEPT
fi

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

iptables -A INPUT  -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT
iptables -A OUTPUT -j REJECT --reject-with icmp-admin-prohibited

# Verify
if curl --connect-timeout 5 -sf https://example.com >/dev/null 2>&1; then
    echo "ERROR: firewall failed open (example.com reachable)" >&2; exit 1
fi
if ! curl --connect-timeout 5 -sf https://api.github.com/zen >/dev/null 2>&1; then
    echo "ERROR: firewall failed closed (github API unreachable)" >&2; exit 1
fi
echo "Firewall ready (default-deny + allowlist from $ALLOW_FILE)"
