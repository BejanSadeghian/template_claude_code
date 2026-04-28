# Specs

Numbered, versioned, one file per feature. Source of truth for intent.

- Filename: `NNNN-<slug>.md`. NNNN starts at 0001 and never resets.
- Slug: kebab-case, ≤ 5 words.
- Spec is committed **first**, before implementation, in its own commit on `main`.
- Branches + PRs are optional — use them only when isolation actually helps (risky refactor, long-running work, external collaborator).
- Append, don't rewrite. If scope changes, add a "Scope change" section with date — never delete prior content.

Use `TEMPLATE.md` as the starting point. The `/spec` slash command automates this.

## Why

- The spec is the contract Claude (or any future contributor) is held to.
- "Done" is defined by the acceptance criteria here, not by vibes.
- The build log captures every prompt, so we can replay decisions.
