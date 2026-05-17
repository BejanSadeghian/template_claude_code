# 0013 — cc-autoupdate-and-versions

- **Status**: done
- **Owner**: bejan
- **Created**: 2026-05-17
- **Last updated**: 2026-05-17

## Original prompt

> can you verify latest python, node, etc?
> does it update claude code as well in the container? I am not seeing all of the skills id expect.

## Goal

Keep the devcontainer image and Claude Code up to date without rebuilds, and bump pinned versions to current latest where painless.

## Scope

- In:
  - Bump Node base image 22 → 24 (current Active LTS, 24.15.0).
  - Bump `GIT_DELTA_VERSION` 0.18.2 → 0.19.2.
  - Add `npm update -g @anthropic-ai/claude-code` to `post-create.sh --start`.
- Out:
  - Bumping Python past 3.11 (would require switching from `bookworm` to `trixie`; tracked for a follow-up).
  - Pinning Claude Code to a specific version (the build arg already supports this).

## Acceptance criteria

- [x] AC1: Dockerfile `FROM` line uses `node:24-bookworm`.
- [x] AC2: `GIT_DELTA_VERSION` arg defaulted to `0.19.2` in both Dockerfile and devcontainer.json.
- [x] AC3: `post-create.sh --start` runs `npm update -g @anthropic-ai/claude-code` best-effort (silent failure).

## Risks / unknowns

- Node 22 → 24 may break consumers pinning to v22 APIs. Acceptable in a template (consumers can override `FROM`).
- npm update on every start adds a few seconds; tolerable.

## Build log

- 2026-05-17 — Bumped Node to 24, delta to 0.19.2, added CC auto-update to post-create.

## Follow-ups

- Investigate switching base to `node:24-trixie` to get Python 3.12+. Separate spec.
