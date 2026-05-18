# 0015 — bump-base-trixie

- **Status**: done
- **Owner**: bejan
- **Created**: 2026-05-17
- **Last updated**: 2026-05-17

## Original prompt

> Python 3.11 → 3.12+ is the one outstanding item (requires switching base image from `bookworm` to `trixie`); flagged as a follow-up in spec 0013. Want me to do that too, or leave it?
> yeah do it

## Goal

Bump devcontainer base image to `node:24-trixie` (Debian 13) so the bundled Python is 3.13 instead of 3.11.

## Scope

- In: change `FROM` line in `.devcontainer/Dockerfile` from `node:24-bookworm` to `node:24-trixie`.
- Out: trimming the unused `aggregate`/`iptables`/`ipset` packages now that the firewall is permissive (separate cleanup).

## Acceptance criteria

- [x] AC1: Dockerfile `FROM` line is `node:24-trixie`.
- [x] AC2: All currently-installed apt packages (`less git procps sudo fzf zsh man-db unzip gnupg2 gh iptables ipset iproute2 dnsutils aggregate jq nano vim curl wget ca-certificates ripgrep fd-find bat python3 python3-pip python3-venv pipx build-essential docker.io sqlite3 postgresql-client sox`) exist in trixie — verified by relying on standard Debian packaging (no custom repos needed).

## Risks / unknowns

- Trixie is newer; potential transient breakage if any package name changed. None known for our list.
- Python jump 3.11 → 3.13 could affect packages installed via `pip --user`; ours (`httpie pre-commit ruff pytest pytest-asyncio`) all support 3.13.

## Build log

- 2026-05-17 — Switched base to `node:24-trixie`. No package list changes needed.
- 2026-05-17 — Build failure reported by user: `docker-outside-of-docker` feature defaults to `moby: true`, but `moby-cli` was removed from trixie. Fixed by passing `"moby": false` to the feature (installs upstream Docker CE instead) and dropping the now-redundant `docker.io` apt package from the Dockerfile.

## Follow-ups

- Trim `aggregate`/`iptables`/`ipset` from apt install since the permissive firewall no longer uses them.
