# This template — version & commands

This repo was scaffolded from [`template_claude_code`](https://github.com/BejanSadeghian/template_claude_code).
This page opens automatically on container start so you can see your version,
whether you're behind the upstream template, and the short commands available.

> Live status (version + behind check) prints in the terminal on start. Run it
> any time with `template-status`.

## Short commands

| Command | What it does |
|---|---|
| `template-status` | Show your template version, whether you're behind upstream, and these commands. Read-only. |
| `template-update` | Pull the latest template changes (interactive: accept / reject / defer / skip-this-version). Commits locally; you push. |
| `update` | Update the installed CLIs (Claude Code, Railway, Azure). Also runs on every container start. |

Each is just a short alias for `bash scripts/<name>.sh` — type the short name from any terminal.

## Window appearance (title + color)

Both live in **`.vscode/settings.json`** (generated on first container start):

- **Window title** — `"window.title": "${rootName}"` shows just the repo name (no "Dev Container: …" prefix). Change the value to taste; VS Code variables like `${rootName}`, `${activeEditorShort}`, `${separator}` are available.
- **Title-bar / activity-bar color** — under `"workbench.colorCustomizations"`. Edit the hex values directly, or delete `.vscode/settings.json` and rebuild the container to get a fresh random hue.

## Versioning

- Your version lives in the `VERSION` file (semver); matching `v*` git tags are created on push.
- `template-status` compares it against the upstream template's `VERSION` and lists the template-owned files that differ.

## How template updates work

`template-update` only touches **template-owned paths** (`.devcontainer/`, `.github/`,
`claude/`, the template `scripts/*`, `hooks/`, `docs/runbook/`, `docs/TEMPLATE.md`,
`CLAUDE.md`). Your application code is never touched.

For each batch of upstream changes you get a per-SHA choice:

| Choice | Effect |
|---|---|
| **accept** | Fast-forward template-owned files to upstream, commit locally (review + push). |
| **reject** | Record the SHA in `.template-sync-ignore` so it never re-prompts (commit the file to make it stick). |
| **defer** | Re-prompt next container start. |
| **skip-this-version** | Skip just this SHA; future template commits still prompt. |

If you changed template-owned files locally, `template-update` won't auto-stage over them —
commit or stash first.

> **Devcontainer changes need a rebuild.** Updates to `.devcontainer/*` or the
> `Dockerfile` only take effect after **Dev Containers: Rebuild Container**.
