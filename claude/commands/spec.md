# /spec — capture intent before code

Use whenever the user gives a feature request, todo list, or non-trivial prompt.

Steps:
1. Find next id: `ls docs/specs | grep -E '^[0-9]{4}-' | sort | tail -1` → increment.
2. Slug: kebab-case, ≤ 5 words.
3. Copy `docs/specs/TEMPLATE.md` to `docs/specs/NNNN-<slug>.md`.
4. Fill: Prompt (verbatim), Goal, Scope, Out of scope, Acceptance criteria (each testable), Risks, Subtasks.
5. Create branch: `git checkout -b feat/NNNN-<slug>` (or `spec/...` for research-only).
6. Commit just the spec: `git add docs/specs/NNNN-<slug>.md && git commit -m "spec: NNNN-<slug>"`.
7. Push branch and open draft PR: `gh pr create --draft --title "feat(NNNN): <slug>" --body-file docs/specs/NNNN-<slug>.md`.

Then proceed to implementation. Append progress notes to the spec under "Build log" as you go. Tick acceptance checkboxes only when verified.
