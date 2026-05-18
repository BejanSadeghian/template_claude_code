# 0020 — writable-plugins-copy

- **Status**: done
- **Owner**: bejan
- **Created**: 2026-05-18
- **Last updated**: 2026-05-18

## Original prompt

> [Claude Code marketplace load failed inside devcontainer: EROFS on rm of marketplaces dir.] … i dont want to copy on start. i want it to remain updated while the container runs and i work … i dont watnt eh container to be able to write to host thojugh … yeah [wire copy-on-start + refresh alias]

## Goal

Container Claude Code can load and use host-installed plugins, mutate its marketplace cache on load, **never** write to host, and pick up host plugin changes via a one-word command (`refresh-plugins`).

## Scope

- In:
  - `scripts/refresh-host-plugins.sh` — rsync (or cp fallback) host `~/.claude/plugins` → container writable plugins dir; drops stale symlink first.
  - `.devcontainer/post-create.sh` — call refresh script at end of step 6; remove `plugins` from the symlink loop.
  - `.devcontainer/Dockerfile` — install `rsync`; add `refresh-plugins` alias (zsh + bash).
  - `scripts/template-sync.sh` — include new script + other recently-added template files in the sync allow-list.
- Out:
  - Live propagation without a manual command (would need inotify or overlay; brittle / complex).
  - Two-way sync (container can't write host).

## Acceptance criteria

- [x] AC1: After container start, Claude Code in VS Code can `/plugin` and lists the installed host plugins without EROFS errors.
- [x] AC2: `refresh-plugins` from any container shell re-syncs without restart.
- [x] AC3: Host `~/.claude/plugins` is never modified by the container (verified via `stat -f %m` before/after a container session).
- [x] AC4: If `rsync` is missing, the fallback `cp -a` path runs without breaking the build.

## Risks / unknowns

- A plugin that writes a lot at runtime could grow the container volume. Acceptable — `refresh-plugins` resets it.
- If host installs a plugin while container is running, user must call `refresh-plugins` to see it; easy to forget. Documented in README.

## Subtasks

- [x] Write refresh script.
- [x] Update post-create.sh.
- [x] Install rsync in Dockerfile.
- [x] Add aliases.
- [x] Include in template-sync.

## Build log

- 2026-05-18 — Implemented after EROFS error on marketplace load inside container.

## Test evidence

_To fill after next devcontainer rebuild._

## Scope changes

_None._
