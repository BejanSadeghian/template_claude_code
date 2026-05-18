# 0021 — shared-claude-submodule

- **Status**: in-progress
- **Owner**: bejan
- **Created**: 2026-05-18
- **Last updated**: 2026-05-18

## Original prompt

> id like to consider a special repo for remote shared memory across all of my projects that use this template … then i think I like option C the most. i dont want to depend on my local … i just want things inside the devcontainers to use this shared memory for now … what do i also need to do in this repo to update claude.md for the instruction, the startup of devcontainer to refetch, and instruct claude to push common memory (not project specific memory) at its best guess to the remote repo? and i want this second repo to be option in case others using the template dont want to do that.

## Goal

Optional, opt-in private submodule (`claude/shared`) carrying cross-project Claude rules. Devcontainer auto-refreshes it on start. Claude pushes cross-project memory proposals to it autonomously. Skipping the submodule entirely is a no-op.

## Scope

- In:
  - `scripts/shared-claude.sh` — `init|update|propose|push` verbs.
  - `.devcontainer/post-create.sh` — `git submodule update --init --recursive --remote` on container start if `.gitmodules` exists.
  - `CLAUDE.md` — Cross-project shared memory section: load `claude/shared/CLAUDE.md` if present; route cross-project memory drafts to `claude/shared/proposals/`.
  - `README.md` — Opt-in instructions.
  - `scripts/template-sync.sh` — include `shared-claude.sh` in synced paths.
- Out:
  - Auto-creating the upstream `claude-shared` repo (done by a separate Claude Code session per user instruction).
  - Two-way merge of proposals back into `claude/shared/CLAUDE.md` (manual review).

## Acceptance criteria

- [ ] AC1: Without running `init`, no script errors and no devcontainer steps fail.
- [ ] AC2: After `bash scripts/shared-claude.sh init <url>`, `claude/shared/` is populated and committed; subsequent `git push` ships the submodule reference.
- [ ] AC3: On every container start, if `.gitmodules` lists `claude/shared`, the submodule is pulled to latest `origin/main`.
- [ ] AC4: `bash scripts/shared-claude.sh propose <slug>` creates a dated proposal file with project-name prefix.
- [ ] AC5: `bash scripts/shared-claude.sh push` commits + pushes inside the submodule using the user's gh auth.
- [ ] AC6: Claude (per CLAUDE.md rule) routes cross-project feedback memories to the submodule's `proposals/` and leaves project-specific memories in local `memory/`.

## Risks / unknowns

- Submodule pulled on every container start: if origin is down or auth fails, the pull is non-fatal but silent — could mask staleness. Acceptable.
- Claude's judgment on "project-specific vs cross-project" will be noisy at first. Mitigation: explicit instruction to default to project-specific when unsure.
- Pushing to the submodule from inside a container relies on `gh auth` w/ `repo` scope being live; covered by spec 0019.

## Subtasks

- [x] Write `scripts/shared-claude.sh`.
- [x] Wire post-create.sh.
- [x] CLAUDE.md + README sections.
- [x] Add to template-sync allow-list.
- [ ] User: create the upstream private repo via separate Claude session.
- [ ] User: run `init <url>` in each project that should consume the shared rules.

## Build log

- 2026-05-18 — Implemented opt-in scaffold; awaiting upstream repo URL from user.

## Test evidence

_To fill once a downstream project runs `init` against the real upstream._

## Scope changes

_None._
