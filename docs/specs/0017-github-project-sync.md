# 0017 — github-project-sync

- **Status**: in-progress
- **Owner**: bejan
- **Created**: 2026-05-17
- **Last updated**: 2026-05-17

## Original prompt

> ok maybe i want to do the github kanban project thing. how do i organize that and what do i need to add as automation to setup the github repo when i create a new one or if i have an existing? … can my gh auth be enough for that instead of the extra step? … k. then yea lets go.

## Goal

Mirror each `docs/specs/NNNN-<slug>.md` to a GitHub issue + a row in a "Specs" Project v2 board, with the spec's `Status` field as source of truth. Sync runs locally on pre-push under the user's `gh auth`, so no Actions PAT is required.

## Scope

- In:
  - `scripts/setup-github-project.sh` — idempotent bootstrap: label, project, status field+options, repo link.
  - `scripts/sync-specs-to-github.sh` — parse specs, upsert issues, set Project Status field, close on done/abandoned.
  - `hooks/pre-push` — call sync unless `SKIP_SPEC_SYNC=1`.
  - `docs/runbook/SERVICES.md` — note `gh auth refresh -s project` one-time step.
  - `CLAUDE.md` Spec-on-commit section — one line about sync.
- Out:
  - GitHub Actions workflow (deferred; no PAT/App needed under local-sync model).
  - Reverse sync (GitHub → spec). Spec file is canonical.
  - Multi-contributor concurrency safety.

## Acceptance criteria

- [ ] AC1: `scripts/setup-github-project.sh` is idempotent: re-running on a repo with the project already set up makes no changes and exits 0.
- [ ] AC2: After bootstrap, the repo has label `spec`, a Project v2 titled `Specs` linked to the repo, and a `Status` single-select field with options `draft, in-progress, done, abandoned`.
- [ ] AC3: `scripts/sync-specs-to-github.sh` creates one issue per spec missing on GitHub, titled `NNNN — <slug>`, body containing a link to the spec and a `<!-- spec:NNNN -->` marker, labeled `spec`.
- [ ] AC4: Existing issues are matched by `<!-- spec:NNNN -->` marker (not by title), so renames don't duplicate.
- [ ] AC5: After sync, every spec has a project item with `Status` matching the spec's `Status:` line.
- [ ] AC6: Specs with `Status: done` or `abandoned` have their issue closed; others are open.
- [ ] AC7: `pre-push` runs sync; `SKIP_SPEC_SYNC=1 git push` skips it.
- [ ] AC8: If `gh auth status` shows the token lacks `project` scope, sync prints a one-line instruction (`gh auth refresh -s project`) and exits 0 (non-fatal).

## Risks / unknowns

- `gh project` CLI surface still evolves; pinning to commands available in the version shipped by the devcontainer Dockerfile.
- Local-only sync means web edits / teammate pushes drift until next local push. Acceptable for solo template; revisit if multi-contributor.
- Project v2 field IDs are per-project; we resolve them every run rather than caching.

## Subtasks

- [ ] Write `scripts/setup-github-project.sh`.
- [ ] Write `scripts/sync-specs-to-github.sh`.
- [ ] Wire `hooks/pre-push`.
- [ ] Update `CLAUDE.md` and `docs/runbook/SERVICES.md`.
- [ ] Run setup + sync once on this repo, verify board.

## Build log

- 2026-05-17 — Spec created.

## Test evidence

_To fill after first successful sync._

## Scope changes

_None._
