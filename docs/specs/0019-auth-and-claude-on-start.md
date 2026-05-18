# 0019 — auth-and-claude-on-start

- **Status**: in-progress
- **Owner**: bejan
- **Created**: 2026-05-17
- **Last updated**: 2026-05-17

## Original prompt

> can we setup the dev container to automatically start logging in for gh and railway? ok to skip. and i want to open one claude code window on startup so we're ready to start. in that instance i might instrcut it to do something other than build.

## Goal

On devcontainer open, prompt the user through `gh` and `railway` logins (idempotent — skips if already authed) and best-effort auto-open the Claude Code panel so a chat is ready immediately.

## Scope

- In:
  - `scripts/auth-bootstrap.sh` — checks gh + railway, runs login flows if needed; `SKIP_AUTH_BOOTSTRAP=1` short-circuit.
  - `.vscode/tasks.json` — two `runOn: folderOpen` tasks: `auth-bootstrap` and `open-claude-code` (best-effort).
  - `.devcontainer/devcontainer.json` — `task.allowAutomaticTasks: on` so the tasks fire without per-folder consent.
  - `.gitignore` — allow `.vscode/tasks.json`.
- Out:
  - Non-interactive token storage (still requires user to complete OAuth in browser).
  - Other providers (AWS, GCP, etc.).

## Acceptance criteria

- [ ] AC1: On first container open, a dedicated terminal pops up showing the `auth-bootstrap` task output.
- [ ] AC2: If `gh auth status` already shows `project` scope, the script skips gh login silently.
- [ ] AC3: If `railway whoami` succeeds, the script skips railway login silently.
- [ ] AC4: `SKIP_AUTH_BOOTSTRAP=1` in container env makes the task a no-op.
- [ ] AC5: Best-effort: the Claude Code side panel is open after folder load. Exact extension command id may need adjustment — failure is silent.

## Risks / unknowns

- The `code --command` CLI flag works in recent VS Code builds but isn't documented as a stable API. If unavailable, the `open-claude-code` task is silently a no-op.
- The Claude Code extension's exact startup command id (`claudeCode.start` etc.) is guessed; user will confirm and we'll narrow the task command list.
- `task.allowAutomaticTasks: on` removes a security prompt — fine for a devcontainer the user controls, less fine on shared infra.

## Subtasks

- [ ] After first rebuild: confirm which `code --command` ID actually opens the panel; trim the chain in `tasks.json`.
- [ ] If `code --command` is unsupported, swap to a keybinding or extension-side setting.

## Build log

- 2026-05-17 — Spec created. Added auth-bootstrap.sh + tasks.json + devcontainer setting.

## Test evidence

_To fill after rebuild._

## Scope changes

_None._
