# 0004 — readme-template-two-step

- **Status**: done
- **Owner**: <github_account>
- **Created**: 2026-04-27
- **Last updated**: 2026-04-27

## Original prompt

> ok that worked, update my readme to tell me to do the two steps (repo create and repote clone)

## Goal

Document the two-step `gh repo create` then `gh repo clone` flow in the README so future bootstraps don't hit the `fatal: couldn't find remote ref refs/heads/main` race.

## Scope

- In: rewrite the "Each new project" snippet in `README.md` to use create-without-clone, verify branches, then clone. Update stale "What this gives you" bullets that still referred to the old spec-first / PR workflow.
- Out: changes to the fallback path or other sections.

## Acceptance criteria

- [x] AC1: README's preferred path uses `gh repo create … --private` (no `--clone`) followed by `gh api … branches` verification, then `gh repo clone`.
- [x] AC2: README explicitly calls out the async copy + race as the reason.
- [x] AC3: "What this gives you" no longer claims spec-first / branch+PR mandatory workflow.

## Risks / unknowns

- GitHub's async-copy timing is undocumented. If the verification call returns empty for >10s the user has to retry; that's acknowledged inline.

## Subtasks

- [x] Edit README quick start.
- [x] Refresh stale "What this gives you" bullets.

## Build log

- 2026-04-27 — Reproduced the race in `notetaking` repo bootstrap. Split into create → verify → clone in README. Also fixed two stale workflow bullets that survived earlier refactors (specs 0002, 0001-pivot).

## Test evidence

Docs-only change. The two-step flow is the exact sequence the user just ran successfully against `<github_account>/<repo>`.

## Scope changes

None.
