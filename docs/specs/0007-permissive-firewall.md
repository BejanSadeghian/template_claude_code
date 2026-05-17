# 0007 — permissive-firewall

- **Status**: done
- **Owner**: bejan
- **Created**: 2026-05-17
- **Last updated**: 2026-05-17

## Original prompt

> can you update this repo so the firewall is very permissive? I dont care if Claude reaches out to everything. Ill auth what i need

## Goal

Remove the default-deny outbound firewall from the devcontainer so Claude can reach any host without allowlist edits.

## Scope

- In: rewrite `.devcontainer/init-firewall.sh` to flush rules and set ACCEPT policies; drop `allowed-domains.txt` from build; update CLAUDE.md note.
- Out: removing the script entirely, changing sudoers, changing devcontainer.json postStartCommand.

## Acceptance criteria

- [x] AC1: `init-firewall.sh` sets INPUT/OUTPUT/FORWARD policies to ACCEPT and references no allowlist.
- [x] AC2: `.devcontainer/allowed-domains.txt` removed; Dockerfile no longer COPYs it.
- [x] AC3: CLAUDE.md network section reflects permissive default and points at git history for restoring deny.

## Risks / unknowns

- Reduced isolation if running with `--dangerously-skip-permissions`. Acceptable per user.

## Build log

- 2026-05-17 — Spec created alongside the change.
- 2026-05-17 — Rewrote init-firewall.sh; removed allowed-domains.txt + Dockerfile COPY; updated CLAUDE.md.

## Test evidence

Script change is config-only; will take effect on next container rebuild via `postStartCommand`.
