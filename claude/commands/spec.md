# /spec — capture intent before code

Use whenever the user gives a feature request, todo list, or non-trivial prompt.

Steps:
1. Find next id: `ls docs/specs | grep -E '^[0-9]{4}-' | sort | tail -1` → increment.
2. Slug: kebab-case, ≤ 5 words.
3. Copy `docs/specs/TEMPLATE.md` to `docs/specs/NNNN-<slug>.md`.
4. Fill: Prompt (verbatim), Goal, Scope, Out of scope, Acceptance criteria (each testable), Risks, Subtasks.
5. Commit just the spec on `main`: `git add docs/specs/NNNN-<slug>.md && git commit -m "spec: NNNN-<slug>"`.

Then proceed to implementation. Append progress notes to the spec under "Build log" as you go. Tick acceptance checkboxes only when verified. If isolation is genuinely needed (risky refactor, long-running work, external collaborator), branch off — otherwise stay on `main`.
