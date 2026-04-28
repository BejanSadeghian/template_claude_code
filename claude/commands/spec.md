# /spec — capture intent at commit time

Trigger: when the user asks to commit, push, or ship — not on every prompt. During iteration, no spec.

Steps:
1. Find next id: `ls docs/specs | grep -E '^[0-9]{4}-' | sort | tail -1` → increment.
2. Slug: kebab-case, ≤ 5 words.
3. Copy `docs/specs/TEMPLATE.md` to `docs/specs/NNNN-<slug>.md`.
4. Fill: the consolidated prompts that drove the work (paste verbatim, in order), Goal, Scope, Out of scope, Acceptance criteria (each testable, tick what's already verified), Risks, What was built.
5. Stage the spec with the work and commit together: `git add docs/specs/NNNN-<slug>.md <impl files> && git commit`. For large diffs, split: spec-only commit first, then implementation.

Skip the spec entirely for trivial commits (typo fixes, formatting, comment tweaks, dependency bumps).

If a follow-up prompt extends the same area later, append the new prompt to the existing spec's "Build log" before the next commit.
