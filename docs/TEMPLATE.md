# This template — setup, version & commands

This repo was scaffolded from [`template_claude_code`](https://github.com/BejanSadeghian/template_claude_code).
This page opens automatically on container start so you can see your setup, your
version, whether you're behind the upstream template, and the short commands.

> Live status (version + behind check) prints in the terminal on start. Run it
> any time with `template-status`.

## First-time setup — run `setup`

`setup` is an interactive wizard. It asks four things and configures the repo so
Claude follows your choices:

| Choice | Options |
|---|---|
| App type | `web` or `ios` |
| Git workflow | commit straight to **main** (no PR) · or **branch + PR** |
| CI | on / off |
| Deploy | `none` · `railway` · `azure` (pick any) |
| Auth login | **web/browser** (no password) · or username/password |

It writes **`claude/project.md`** (the profile Claude obeys) and installs the
matching [modules](../modules/README.md). Re-run `setup` any time to change.

## Customize what Claude always does

| File | Purpose |
|---|---|
| `claude/project.md` | The profile above — app type, git workflow, CI, deploy, auth. Claude obeys it. |
| `claude/preferences.md` | **Your always-follow custom rules** (e.g. "TODOs live in `docs/todo.md`"). Edit freely; Claude reads it every session. |
| `claude/modules/*.md` | Rules added automatically when you install a module. |
| `CLAUDE.local.md` | Personal, **gitignored** rules (not shared with the team). |

`CLAUDE.md` (committed, shared) is the stack-agnostic core and points Claude at all of the above.

## Short commands

| Command | What it does |
|---|---|
| `setup` | Interactive project wizard (writes `claude/project.md`, installs modules). |
| `module` | `module list` / `module add <name>` / `module remove <name>` — manage opt-in modules. |
| `template-status` | Show your version, whether you're behind upstream, and these commands. Read-only. |
| `template-update` | Pull the latest template changes (interactive: accept / reject / defer / skip). |
| `update` | Update the installed CLIs (Claude Code, Railway, Azure). Also runs on every container start. |

Each is a short alias for `bash scripts/<name>.sh` — type the short name from any terminal.

## Auth (no passwords by default)

On first container start, `gh`, `railway`, and `az` log in via **browser / device-code**
flow — no username or password typed. To force credential/token entry instead, choose
"username/password" in `setup` (sets `Auth: password` in `claude/project.md`) or set
`CLAUDE_AUTH_WEB=0`. Skip auth entirely with `SKIP_AUTH_BOOTSTRAP=1`.

## Window appearance (title + color)

Both live in **`.vscode/settings.json`** (generated on first container start):

- **Window title** — `"window.title": "${rootName}"` shows just the repo name (no "Dev Container: …" prefix). Change the value to taste; VS Code variables like `${rootName}`, `${activeEditorShort}`, `${separator}` are available.
- **Title-bar / activity-bar color** — under `"workbench.colorCustomizations"`. Edit the hex values directly, or delete `.vscode/settings.json` and rebuild the container to get a fresh random hue.

## Versioning

- Your version lives in the `VERSION` file (semver); matching `v*` git tags are created on push.
- `template-status` compares it against the upstream template's `VERSION` and lists the template-owned files that differ.

## How template updates work

`template-update` only touches **template-owned paths** (`.devcontainer/`, `modules/`,
`claude/settings.json`, `claude/commands/`, the template `scripts/*`, `hooks/`,
`docs/runbook/`, `docs/TEMPLATE.md`, `CLAUDE.md`). Your app code, your
`claude/project.md`, `claude/preferences.md`, and installed module files are never touched.

For each batch of upstream changes you get a per-SHA choice:

| Choice | Effect |
|---|---|
| **accept** | Fast-forward template-owned files to upstream, commit locally (review + push). |
| **reject** | Record the SHA in `.template-sync-ignore` so it never re-prompts (commit the file to make it stick). |
| **defer** | Re-prompt next container start. |
| **skip-this-version** | Skip just this SHA; future template commits still prompt. |

**On container start, updates auto-apply** when your template-owned paths are clean:
the sync commits them locally for you (no prompt) and tells you to push. It never
runs when those paths have uncommitted changes (you commit/stash first), and you can
turn auto-apply off with `TEMPLATE_AUTOSYNC=0` (then it just notifies). The four-choice
prompt above is for when you run `template-update` yourself in a terminal.

If you changed template-owned files locally, the sync won't stage over them — commit or stash first.

> **Devcontainer changes need a rebuild.** Auto-applied or not, updates to
> `.devcontainer/*` or the `Dockerfile` only take effect after **Dev Containers: Rebuild Container**.
