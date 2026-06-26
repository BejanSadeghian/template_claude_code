# template_claude_code

A VS Code devcontainer + workflow scaffold for shipping software with Claude Code as the primary builder. It treats Claude as a teammate: your job is ideation and review; Claude's job is to plan, implement, verify, and keep the remote up to date automatically.

## Contents

- [Purpose](#purpose)
- [Features](#features)
- [What this is not](#what-this-is-not)
- [Getting started](#getting-started)
  - [Start a new project from this template](#start-a-new-project-from-this-template)
  - [Adopt this template in an existing repo](#adopt-this-template-in-an-existing-repo)
  - [Use the template locally (no GitHub)](#use-the-template-locally-no-github)
  - [Pull the latest template changes into a project](#pull-the-latest-template-changes-into-a-project)
- [Configuration](#configuration)
- [Notes & caveats](#notes--caveats)
- [Contributing](#contributing)

## Purpose

Most "AI-assisted" starter kits leave the human in the loop for every step. This one inverts that: remote-first auto-push (no keyword trigger), definition-of-done verification, async subagent dispatch, git tag automation, and a devcontainer pre-wired so Claude Code is the first thing you see when the workspace opens. You stay in the conversation; the scaffolding handles the bookkeeping.

## Features

| Area | What you get |
|---|---|
| Devcontainer | Debian 13 + Node 24, gh, Railway CLI, Azure CLI, ripgrep/fd, Python tooling, `sox` for voice. Permissive outbound network. Full passwordless sudo. |
| Claude Code defaults | Starts in `bypassPermissions` mode. CLI alias for `--dangerously-skip-permissions`. Extension force-upgraded on every container start. Auto-open Claude panel on folder open. |
| Tooling auto-update | Every container start updates Claude Code + Railway + Azure CLIs. Run it any time by hand with the single-word `update` command. |
| Claude config | Single writable named volume at `/home/node/.claude` (`CLAUDE_CONFIG_DIR`), matching Anthropic's official devcontainer. `settings.json` is writable so `/model` works; plugins/skills/auth persist across rebuilds. Host `~/.claude` is **not** mounted. |
| Auth bootstrap | Browser/device-code login for `gh`, `railway`, and `az` on first container start — no passwords. GitHub gets `repo,workflow,project,read:org` (the `workflow` scope is required to push the modules' workflow files); existing logins are auto-refreshed. Opt into credential entry with `setup` / `CLAUDE_AUTH_WEB=0`. Skip with `SKIP_AUTH_BOOTSTRAP=1`. |
| `setup` wizard | One command picks app type (web/iOS), git workflow (main or branch+PR), CI on/off, deploy target, and auth mode — writes `claude/project.md` (the profile Claude obeys) and installs the matching modules. |
| Pick-and-choose modules | Nothing deploy/CI-specific is bundled. `module add deploy-railway` / `deploy-azure` / `stack-web` / `stack-ios` drop in only what you want (workflows + verify scripts + CLAUDE rules). |
| Custom instructions | `claude/preferences.md` (shared) and `CLAUDE.local.md` (personal, gitignored) for always-follow rules Claude reads every session. |
| Remote-first auto-push | No keyword trigger. Claude commits + pushes after every meaningful change; destination (straight to `main`, or branch+PR) follows `claude/project.md`. |
| Continuous async workflow | Orchestrator Claude dispatches developer + test-engineer subagents in isolated git worktrees as soon as a task is solid. You keep planning; results surface only on blockers or full-green. |
| Auto semver | Conventional commits drive `feat!:`/`feat:`/`fix:` → major/minor/patch. `pre-push` bumps `VERSION` and tags `vX.Y.Z`. |
| Template sync | Every container start checks for upstream template updates; `template-status` shows how far behind you are, `template-update` applies them per-SHA. |
| Cross-project shared memory | Optional private submodule at `claude/shared/` for rules that apply across all your repos. |
| Per-repo identity | Window title = repo name; random VS Code title-bar color per clone so windows are visually distinct. |

## What this is not

- **Not a framework or stack.** No React, no FastAPI, no Rails. Bring your own.
- **Not provider-locked.** No deploy provider or CI is bundled by default. `module add deploy-railway` / `deploy-azure` adds the one you want; the shape is reusable for Fly/Render/AWS.
- **Not a hands-off agent.** You make the decisions; Claude executes, verifies, and pushes — to `main` or a branch+PR per your `claude/project.md`.
- **Not for one-off scripts.** The profile/module/versioning weight pays off on projects you'll be back to next quarter.
- **Not opinionated about test frameworks.** Lint/test/deploy commands come from the stack module you install (`stack-web` is pnpm-based; swap or edit freely). Core ships none.

## Getting started

### Start a new project from this template

```bash
cd ~/Dev   # or wherever you keep repos
gh repo create <new-name> --template BejanSadeghian/template_claude_code --private --clone
cd <new-name>
code .     # then "Reopen in Container"
```

If `--clone` races the template copy (rare) and you see `couldn't find remote ref refs/heads/main`, wait a few seconds and `gh repo clone <your-gh-account>/<new-name>` manually.

Fallback (no template flag):

```bash
git clone https://github.com/BejanSadeghian/template_claude_code.git <new-name>
cd <new-name>
rm -rf .git && git init -b main
gh repo create <new-name> --private --source=. --push
```

Once the container is up, on first start it will:

1. Auto-prompt browser/device-code login for `gh`, `railway`, and `az` (skips if already authed — no passwords).
2. Auto-open the Claude Code panel and `docs/TEMPLATE.md` (your version + commands).
3. Update the bundled CLIs (Claude Code, Railway, Azure) — same as running `update`.
4. Print `template-status` and check for upstream template updates.

Then run **`setup`** once to pick your app type, git workflow, CI, deploy target, and auth mode — it writes `claude/project.md` and installs the matching modules. Add always-follow rules in `claude/preferences.md`. Read `CLAUDE.md` for the working rules; full guide in [`docs/TEMPLATE.md`](docs/TEMPLATE.md).

Optional: link a shared rules repo (see [Cross-project shared memory](#cross-project-shared-memory)):

```bash
bash scripts/shared-claude.sh init https://github.com/<you>/claude-shared.git
git push
```

### Adopt this template in an existing repo

If your project doesn't have `scripts/template-sync.sh` yet, bootstrap it once:

```bash
cd /path/to/your-existing-repo

TEMPLATE_URL=https://github.com/BejanSadeghian/template_claude_code.git
git remote add template "$TEMPLATE_URL"
git fetch template main

git checkout template/main -- scripts/template-sync.sh
echo "$TEMPLATE_URL" > .template-source
chmod +x scripts/template-sync.sh

git add scripts/template-sync.sh .template-source
git commit -m "chore: adopt template-sync"

bash scripts/template-sync.sh   # diffs template-owned paths and prompts
```

After that, every container start runs `template-sync.sh` and offers `accept/reject/defer/skip-this-version`.

### Use the template locally (no GitHub)

Don't have or don't want a GitHub account? You only need `git` and Docker. The GitHub-only features (PR flows) skip silently when `gh` isn't authed; auto-push just targets whatever remote you configure.

```bash
# 1. Clone the template tree, drop its history, start your own repo
git clone https://github.com/BejanSadeghian/template_claude_code.git my-project
cd my-project
rm -rf .git
git init -b main
git add -A
git commit -m "chore: bootstrap from template_claude_code"

# 2. Optional: a local bare remote so `git push` has somewhere to go
mkdir -p ~/git-remotes
git init --bare ~/git-remotes/my-project.git
git remote add origin ~/git-remotes/my-project.git
git push -u origin main

# 3. Open in VS Code, "Reopen in Container"
code .
```

Inside the container, add `SKIP_AUTH_BOOTSTRAP=1` to `.devcontainer/devcontainer.json` → `containerEnv` so the gh/railway/az login prompts don't fire.

What you keep without GitHub: devcontainer build, Claude Code (CLI + extension), writable container-local Claude config volume, remote-first auto-push, `pre-commit` + `pre-push` hooks, auto semver bumps + local `v*` tags, and `template-sync.sh` (only needs anonymous HTTPS to github.com to pull template updates).

What you lose / replace: `gh pr create` → not relevant solo. For the optional `claude/shared/` submodule, either delete it (`git rm claude/shared && git rm .gitmodules`) or point it at a local bare repo: `git submodule add -b main /absolute/path/to/claude-shared.git claude/shared`.

Fully air-gapped? Pre-pull `node:24-trixie` and drop `.template-source` (or ignore fetch warnings). Install any Claude plugins inside the container (`/plugin`); they persist in the config volume.

### Pull the latest template changes into a project

Short commands (aliases available in every container terminal):

| Command | What it does |
|---|---|
| `template-status` | Show your version, whether you're behind upstream, and the commands. Read-only. |
| `template-update` | Pull the latest template changes (interactive). Same as `bash scripts/template-sync.sh`. |
| `update` | Update the installed CLIs (Claude Code, Railway, Azure). |

`template-status` runs and `docs/TEMPLATE.md` opens automatically on every container start, so you always see your version. **Updates auto-apply on start** when your template-owned paths are clean (committed locally for you; push when ready) — opt out with `TEMPLATE_AUTOSYNC=0`. Running `template-update` yourself in a terminal gives the interactive per-file diff with four choices: accept, reject (permanent for that SHA), defer, or skip-this-version. It only touches template-owned paths — never your app code. See [`docs/TEMPLATE.md`](docs/TEMPLATE.md).

## Configuration

| Knob | Where | Default |
|---|---|---|
| Container build args | `.devcontainer/devcontainer.json` → `build.args` | Node 24, Claude Code `latest`, git-delta, zsh-in-docker |
| VS Code extensions | `.devcontainer/devcontainer.json` → `customizations.vscode.extensions` | anthropic.claude-code + sensible defaults |
| Auto-open Claude Code + template status on folder open | `.vscode/tasks.json` | on |
| Window title | `.vscode/settings.json` → `window.title` | `${rootName}` (just the repo name) |
| Window / title-bar color | `.vscode/settings.json` → `workbench.colorCustomizations` (delete file + rebuild for a new random hue) | random per repo |
| `claudeCode.initialPermissionMode` | `.devcontainer/devcontainer.json` settings | `bypassPermissions` |
| Project profile (app type, git workflow, CI, deploy, auth) | run `setup` → writes `claude/project.md` | unset (run `setup`) |
| Always-follow custom rules | `claude/preferences.md` (shared) · `CLAUDE.local.md` (personal, gitignored) | empty |
| Installed modules | `module add/remove <name>` (sources in `modules/`) | none |
| Auth login mode | `setup` (web vs password) or env `CLAUDE_AUTH_WEB=0` | web/browser |
| Skip auth bootstrap | env `SKIP_AUTH_BOOTSTRAP=1` | off |
| Update bundled CLIs | run `update` (or `bash scripts/update.sh`); also runs on every container start | on start |
| Skip version bump on push | env `SKIP_VERSION_BUMP=1` or `[skip version]` in commit msg | off |
| Cross-project shared submodule | `bash scripts/shared-claude.sh init <url>` | not initialized |
| Active model | `/model` in Claude Code (persisted to your writable `~/.claude/settings.json`) | not pinned |

## Notes & caveats

- **Forking this template?** The default `.gitmodules` points at `BejanSadeghian/claude-shared` (private). If you don't have access, submodule init fails silently — no error, just an empty `claude/shared/` and the shared-rules section in `CLAUDE.md` is skipped. To use your own shared repo: `git rm claude/shared`, delete `.gitmodules`, commit, then `bash scripts/shared-claude.sh init <your-url>`.
- **Claude config is container-local and writable.** We follow Anthropic's official devcontainer: a single writable named volume holds `/home/node/.claude`, and host `~/.claude` is **not** mounted. This is deliberate — the old read-only host mount made `~/.claude/settings.json` read-only, so `/model` failed with "read-only file system". Now `/model` and any settings change just work, and everything you install (plugins, skills, auth) persists in the volume across rebuilds. Trade-off: a fresh container starts with no host plugins — install them inside (`/plugin`) or log in once; the volume keeps them.
- **`--dangerously-skip-permissions` is the default** inside the devcontainer (CLI alias + VS Code extension `bypassPermissions`). Acceptable because outbound network is permissive but the container is isolated from host. Never give the container a long-lived production token.
- **Claude Code is auto-updated** on every container start (`npm update -g @anthropic-ai/claude-code`). Pin with the `CLAUDE_CODE_VERSION` build arg if you need reproducibility.
- **Model is never pinned.** Use `/model` to pick any model the running CLI supports (including the latest, e.g. Fable). The choice persists in the writable container `settings.json`; nothing in this template hardcodes a model id.
- **Async subagent dispatch requires `git worktree`.** The orchestrator uses isolated worktrees so parallel agents don't clobber each other.
- **Deploy/CI is modular, not bundled.** The default repo wires no provider or workflows. `module add deploy-railway` / `deploy-azure` drops in that provider's `verify-deploy.sh`, workflow, and CLAUDE rules; `stack-web` / `stack-ios` drops in CI + the stack's definition-of-done. Pick only what you use.
- **Window title + title-bar color** are written to `.vscode/settings.json` on first start: `window.title` = `${rootName}` (just the repo name, no "Dev Container:" prefix) and a random per-repo color under `workbench.colorCustomizations`. Edit either there; delete the file and rebuild for a new hue. See [`docs/TEMPLATE.md`](docs/TEMPLATE.md).

## Contributing

Contributors very welcome. Process for external changes:

1. **Open an issue first** describing the problem or proposed change. Get a thumbs-up before doing heavy work.
2. **Fork** the repo and create a feature branch from `main`.
3. **Implement.** Use Claude Code if you want — you'll find the dod/runbook workflow lighter that way — but it's not required.
4. **Open a pull request** against `main`. PRs are **required** for external contributors (the maintainer commits direct to `main`; you don't). The PR description should reference the issue and explain the change.
5. **Pass the local hooks** (`pre-commit` + `pre-push`) before pushing. CI re-runs them.

Good places to start:

- File an issue describing a friction point in the workflow.
- Add or improve a module under `modules/` (a new stack, or a deploy provider).
- Tighten a deploy module's runbook against a provider you use.
- Propose a cross-project rule via an issue (the shared rules repo is private; the issue is the right surface).

By participating you agree to the project's MIT license. Be kind in reviews — bullets, no preamble, no recap.
