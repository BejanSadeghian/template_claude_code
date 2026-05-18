# 0018 — devcontainer-claude-defaults

- **Status**: done
- **Owner**: bejan
- **Created**: 2026-05-17
- **Last updated**: 2026-05-17

## Original prompt

> can i have the dangerously skil permissions flag in the dev container be on by default? … i mean for the vs code extension? and id like to make sure the vs code extension latest is alwyas installed on startup … and make sure the vs code claude extension is always installed and latest is checked on startup

## Goal

In the devcontainer, Claude Code starts in `bypassPermissions` mode by default (CLI alias + VS Code extension settings), and the VS Code Claude extension is force-upgraded to latest on every container start.

## Scope

- In:
  - `.devcontainer/Dockerfile` — `claude` shell alias for zsh and bash that appends `--dangerously-skip-permissions`.
  - `.devcontainer/devcontainer.json` — VS Code settings: `claudeCode.allowDangerouslySkipPermissions=true`, `claudeCode.initialPermissionMode=bypassPermissions`; `postStartCommand` runs `code --install-extension anthropic.claude-code --force`.
- Out:
  - Changing the host-level (non-container) Claude defaults.
  - Pinning the extension to a specific version.

## Acceptance criteria

- [x] AC1: `claude` in a container terminal (zsh or bash) is equivalent to `claude --dangerously-skip-permissions`.
- [x] AC2: VS Code Claude Code panel opens in `bypassPermissions` mode on first launch in the devcontainer.
- [x] AC3: Every container start runs `code --install-extension anthropic.claude-code --force`, upgrading the extension if a newer version is on the marketplace.
- [x] AC4: Override per-call: `\claude ...` or `command claude ...` skips the alias.

## Risks / unknowns

- The `code` CLI is only on `$PATH` once the VS Code server is up; running it from `postStartCommand` works because that hook fires after the server is ready. Guarded with `|| true` so a slow/missing CLI doesn't break startup.
- The two VS Code settings names (`claudeCode.allowDangerouslySkipPermissions`, `claudeCode.initialPermissionMode`) were provided by the user from the extension settings UI; if the extension renames them in a future version, defaults silently revert to the new mechanism.

## Build log

- 2026-05-17 — Added zsh + bash alias in Dockerfile.
- 2026-05-17 — Added `claudeCode.*` settings + force-install in postStartCommand.

## Test evidence

Verified after a container rebuild on the author's machine: `type claude` shows the alias; Claude Code panel header shows `bypass permissions`; extension version matches marketplace latest after `postStartCommand`.

## Scope changes

_None._
