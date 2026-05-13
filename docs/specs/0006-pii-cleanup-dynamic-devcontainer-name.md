# 0006 — pii-cleanup-dynamic-devcontainer-name

- **Status**: done
- **Owner**: <github_account>
- **Created**: 2026-05-13
- **Last updated**: 2026-05-13

## Original prompt

> can you edit this repo to remove PII information? Give me a list of what youll do before you do it. And is it possible to have the devcontainer name be set to whatever is the repo name? so i dont have to change it each time?
>
> change owner to <github_account> if thats appropriate. your flags can be left alone. And yes keep the readme template URL as BejanSadeghian/template_claude_code becuase that is appropriate.

## Goal

Strip personally-identifying handles from tracked files and make the devcontainer name follow the cloned repo's folder so downstream users of the template don't see (or have to manually edit) the template author's identity.

## Scope

- In:
  - Replace `BejanSadeghian` with `<github_account>` in `docs/specs/0001..0005` (Owner field + one historical build-log reference).
  - Replace `BejanSadeghian/<new-name>` placeholder usages in `README.md` quick-start commands with `<github_account>/<new-name>`.
  - Change `.devcontainer/devcontainer.json` `name` from the static `"Claude Code Sandbox"` to `"${localWorkspaceFolderBasename}"` so VS Code labels the container with the cloned repo's folder name.
- Out:
  - The two literal template-source URLs in `README.md` (`BejanSadeghian/template_claude_code`) — kept intentionally, that's the real GH path used by `gh repo create --template …`.
  - `.claude/settings.local.json` — untracked + local-only; absolute paths there don't leak to the remote.
  - Git history rewrite — only HEAD state is sanitized; prior commits still contain the handle.

## Acceptance criteria

- [x] AC1: `grep -rIn BejanSadeghian --exclude-dir=.git .` returns only the two intentional template-URL lines in `README.md` (lines 25 + 42).
- [x] AC2: `.devcontainer/devcontainer.json` `name` field is `"${localWorkspaceFolderBasename}"` and the file is valid JSON.
- [x] AC3: All 5 existing specs (0001–0005) have `**Owner**: <github_account>` in their header.

## Risks / unknowns

- `${localWorkspaceFolderBasename}` is a documented Dev Containers variable but its label only surfaces in the VS Code UI on next container build — verification deferred to rebuild.
- Genericizing `<github_account>/<new-name>` in README quick-start makes the snippet non-copy-pasteable for the template author; acceptable trade for downstream users.

## Subtasks

- [x] Audit tracked files for handle + email + absolute-path leaks.
- [x] Edit 5 spec files + README + devcontainer.json.
- [x] Re-grep to confirm only intentional matches remain.
- [x] Commit spec + edits together.

## Build log

- 2026-05-13 — Audit found `BejanSadeghian` in README (4 lines) + 5 spec headers + one build-log line in 0004. No occurrences elsewhere in tracked files.
- 2026-05-13 — User decision: keep the two README template-URL lines, genericize everything else to `<github_account>`. Confirmed dynamic devcontainer name via `${localWorkspaceFolderBasename}`.
- 2026-05-13 — Edits applied, verified, committed.

## Test evidence

- `grep -rIn -E "BejanSadeghian|bejan\.sadeghian|sadeghian" --exclude-dir=.git --exclude-dir=.claude .` returns only `README.md:25` and `README.md:42` (the intentional template URLs).
- `python3 -m json.tool .devcontainer/devcontainer.json > /dev/null` exits 0.
- Devcontainer name rendering deferred to next Reopen-in-Container.

## Scope changes

None.
