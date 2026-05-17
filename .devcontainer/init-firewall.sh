#!/bin/bash
# Permissive firewall: allow all outbound traffic.
# This template intentionally trusts the dev container — the user authenticates
# anything sensitive themselves. To restore a default-deny allowlist, see
# git history for the previous version of this script and allowed-domains.txt.
set -euo pipefail

iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
ipset destroy allowed-domains 2>/dev/null || true

iptables -P INPUT  ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

echo "Firewall: permissive (all outbound allowed)"
