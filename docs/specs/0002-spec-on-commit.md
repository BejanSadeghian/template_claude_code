# 0002 — spec-on-commit

- **Status**: done
- **Owner**: BejanSadeghian
- **Created**: 2026-04-27
- **Last updated**: 2026-04-27

## Original prompt

> merge the PR. can you also then remove the PR first approach? I think its a waste of time now. i dont want that in the template repo.
>
> and can you update specs when prompting only when committing? I dont want every prompt tp be a new spec. ill prompt for a while before i want a spec. bascially before we commit

(The first prompt above is included for context — it was satisfied in commit `48d0f9d` before this spec rule existed. This spec covers the second prompt.)

## Goal

Shift the spec workflow from "spec on every prompt" to "spec at commit time" so that iterative prompting doesn't generate spec churn.

## Scope

- In: rewrite `Spec-first workflow` section in `CLAUDE.md` to `Spec-on-commit`; update `claude/commands/spec.md` and `docs/specs/README.md` to match.
- Out: changing what a spec contains, the numbering scheme, the template structure, or the DoD table.

## Acceptance criteria

- [x] AC1: `CLAUDE.md` instructs Claude to create specs only when the user asks to commit/push/ship — not on every prompt.
- [x] AC2: `claude/commands/spec.md` describes the new commit-time trigger.
- [x] AC3: `docs/specs/README.md` reflects spec-at-commit timing.
- [x] AC4: Trivial commits (typo, formatting, dep bumps) explicitly carved out.
- [x] AC5: Follow-up prompts on the same area route to the existing spec's Build log.

## Risks / unknowns

- Risk: a long iterative session ends up with a spec that paraphrases prompts inaccurately. Mitigation: rule says paste prompts verbatim.

## Subtasks

- [x] Update `CLAUDE.md`.
- [x] Update `/spec` slash command.
- [x] Update `docs/specs/README.md`.
- [x] Add this spec, commit alongside the rule change.

## Build log

- 2026-04-27 — Rule rewrite + slash command + specs README updated. Spec authored at commit time per the new rule.

## Test evidence

Docs-only change. Verified by re-reading `CLAUDE.md`, `claude/commands/spec.md`, `docs/specs/README.md` — all three consistently describe the commit-time trigger.

## Scope changes

None.
