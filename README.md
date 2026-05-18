# template_claude_code

A VS Code devcontainer + workflow scaffold for shipping software with Claude Code as the primary builder. It treats Claude as a teammate: your job is ideation and review; Claude's job is to plan, implement, and verify against versioned specs.

## Contents

- [Purpose](#purpose)
- [Features](#features)
- [What this is not](#what-this-is-not)
- [Getting started](#getting-started)
  - [Start a new project from this template](#start-a-new-project-from-this-template)
  - [Adopt this template in an existing repo](#adopt-this-template-in-an-existing-repo)
  - [Pull the latest template changes into a project](#pull-the-latest-template-changes-into-a-project)
- [Configuration](#configuration)
- [Notes & caveats](#notes--caveats)
- [Contributing](#contributing)

## Purpose

Most "AI-assisted" starter kits leave the human in the loop for every step. This one inverts that: spec-on-commit, definition-of-done verification, async subagent dispatch, GitHub Project + git tag automation, and a devcontainer pre-wired so Claude Code is the first thing you see when the workspace opens. You stay in the conversation; the scaffolding handles the bookkeeping.

## Features

| Area | What you get |
|---|---|
| Devcontainer | Debian 13 + Node 24, gh, Railway CLI, ripgrep/fd, Python tooling, `sox` for voice. Permissive outbound network. Full passwordless sudo. |
| Claude Code defaults | Starts in `bypassPermissions` mode. CLI alias for `--dangerously-skip-permissions`. Extension force-upgraded on every container start. Auto-open Claude panel on folder open. |
| Host plugin reuse | Host plugins copied into a writable container dir on start (rsync). Skills/commands/agents/settings symlinked live. `refresh-plugins` alias re-syncs after a host install. |
| Auth bootstrap | `gh auth login -s project` + `railway login` auto-prompt on container start if not already authed. Skip with `SKIP_AUTH_BOOTSTRAP=1`. |
| Spec-on-commit | Versioned specs under `docs/specs/NNNN-*.md` with status, acceptance criteria, build log. Spec is created when you say commit/push/ship — not on every prompt. |
| GitHub Project v2 sync | `pre-push` mirrors specs → GitHub issues + a "Specs" Project board. Local `gh` auth, no PAT secrets. Bootstrap once with `scripts/setup-github-project.sh`. |
| Continuous async workflow | Orchestrator Claude dispatches developer + test-engineer subagents in isolated git worktrees as soon as specs are solid. You keep planning; results surface only on blockers or full-green. |
| Auto semver | Conventional commits drive `feat!:`/`feat:`/`fix:` → major/minor/patch. `pre-push` bumps `VERSION` and tags `vX.Y.Z`. |
| Template sync | Every container start checks for upstream template updates and prompts `accept/reject/defer/skip-this-version` per SHA. |
| Cross-project shared memory | Optional private submodule at `claude/shared/` for rules that apply across all your repos. Claude routes "this would apply everywhere" feedback there. |
| Stack guidance | `claude/CLAUDE.node-webapp.md`, `claude/CLAUDE.ios-webapi.md` for stack-specific rules. |
| Runbook scaffolding | `docs/runbook/SERVICES.md`, `RECREATE.md`, `INCIDENTS.md` (Railway-flavored examples; replaceable). |
| CI + hooks | Local git hooks and matching GitHub Actions for lint, typecheck, unit, API, E2E, deploy verify. |
| Per-repo identity | Random VS Code title-bar color per clone so windows are visually distinct. |

## What this is not

- **Not a framework or stack.** No React, no FastAPI, no Rails. Bring your own.
- **Not provider-locked.** Railway is the *default example* for the deploy/runbook bits; swap for any provider — the shape is what matters.
- **Not a hands-off agent.** You write specs and decisions; Claude executes and verifies. The async workflow does not silently auto-merge — merges happen on your explicit "ship".
- **Not for one-off scripts.** The spec/runbook/versioning weight pays off on projects you'll be back to next quarter.
- **Not opinionated about test frameworks.** The "definition of done" table assumes pnpm by default, but every check is replaceable with your stack equivalent.

## Getting started

### Start a new project from this template

GitHub's template flow copies asynchronously, so don't use `gh repo create --clone` — it races the copy. Split it:

```bash
# 1. create the repo from the template (no --clone)
gh repo create <new-name> --template BejanSadeghian/template_claude_code --private

# 2. confirm GitHub finished copying (should print "main")
gh api repos/<your-gh-account>/<new-name>/branches --jq '.[].name'

# 3. clone and open in VS Code
cd ~/Dev
gh repo clone <your-gh-account>/<new-name>
cd <new-name>
code .   # then "Reopen in Container"
```

Fallback (no template flag):

```bash
git clone https://github.com/BejanSadeghian/template_claude_code.git <new-name>
cd <new-name>
rm -rf .git && git init -b main
gh repo create <new-name> --private --source=. --push
```

Once the container is up, on first start it will:

1. Auto-prompt `gh auth login -s project` and `railway login` (skips if already authed).
2. Auto-open the Claude Code panel.
3. Run `template-sync.sh` to check for any upstream updates.

Then you tell Claude what you want to build. Read `CLAUDE.md` for the working rules.

Optional: hook up the Specs Project v2 board so each spec mirrors to a GitHub issue + kanban card:

```bash
bash scripts/setup-github-project.sh
bash scripts/sync-specs-to-github.sh   # backfill existing specs
```

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

### Pull the latest template changes into a project

Two ways:

| Trigger | What happens |
|---|---|
| Rebuild / restart devcontainer | `post-create.sh --start` runs `template-sync.sh` automatically |
| Manual | `bash scripts/template-sync.sh` from any terminal in the repo |

Either pops an interactive prompt with a per-file diff and four choices: accept, reject (permanent for that SHA), defer (re-prompt next start), or skip-this-version.

## Configuration

| Knob | Where | Default |
|---|---|---|
| Container build args | `.devcontainer/devcontainer.json` → `build.args` | Node 24, Claude Code `latest`, git-delta, zsh-in-docker |
| VS Code extensions | `.devcontainer/devcontainer.json` → `customizations.vscode.extensions` | anthropic.claude-code + sensible defaults |
| Auto-open Claude Code on folder open | `.vscode/tasks.json` | on |
| `claudeCode.initialPermissionMode` | `.devcontainer/devcontainer.json` settings | `bypassPermissions` |
| Skip auth bootstrap | env `SKIP_AUTH_BOOTSTRAP=1` | off |
| Skip version bump on push | env `SKIP_VERSION_BUMP=1` or `[skip version]` in commit msg | off |
| Skip spec-sync on push | env `SKIP_SPEC_SYNC=1` | off |
| Specs Project name | env `PROJECT_TITLE=<name>` for setup/sync scripts | `Specs` |
| Cross-project shared submodule | `bash scripts/shared-claude.sh init <url>` | not initialized |
| Spec workflow itself | delete `docs/specs/`, `docs/runbook/`, and matching CLAUDE.md sections to opt out | on |

## Notes & caveats

- **Forking this template?** The default `.gitmodules` points at `BejanSadeghian/claude-shared` (private). If you don't have access, submodule init fails silently — no error, just an empty `claude/shared/` and the shared-rules section in `CLAUDE.md` is skipped. To use your own shared repo: `git rm claude/shared`, delete `.gitmodules`, commit, then `bash scripts/shared-claude.sh init <your-url>`.
- **Container cannot write to host.** Host `~/.claude` is mounted read-only. Plugins are *copied* into the container on start (not symlinked), so Claude Code can mutate marketplace cache without EROFS. Trade-off: install a new plugin on the host → run `refresh-plugins` in the container (or restart) to pick it up.
- **`--dangerously-skip-permissions` is the default** inside the devcontainer (CLI alias + VS Code extension `bypassPermissions`). Acceptable because outbound network is permissive but the container is isolated from host. Never give the container a long-lived production token.
- **Claude Code is auto-updated** on every container start (`npm update -g @anthropic-ai/claude-code`). Pin with the `CLAUDE_CODE_VERSION` build arg if you need reproducibility.
- **Specs Project v2 sync runs locally** under your `gh auth`, not in GitHub Actions. Web edits or teammate pushes won't sync until you push from your machine. Fine for solo work.
- **Async subagent dispatch requires `git worktree`.** The orchestrator uses isolated worktrees so parallel agents don't clobber each other. Subagents commit on their own branch but do not push or merge — that's manual.
- **Provider-coupled examples.** `scripts/verify-deploy.sh`, `docs/runbook/*` are Railway-flavored. Replace per provider; keep the shape.
- **Random title-bar color** is written to `.vscode/settings.json` on first start. Delete the file and rerun `post-create.sh` for a new hue.

## Contributing

Contributors very welcome. Process for external changes:

1. **Open an issue first** describing the problem or proposed change. Get a thumbs-up before doing heavy work.
2. **Fork** the repo and create a feature branch from `main`.
3. **Write a spec.** Every contribution — feature, fix, or doc change beyond a typo — needs a file at `docs/specs/NNNN-<slug>.md` based on `docs/specs/TEMPLATE.md`. Fill in the goal, scope, acceptance criteria, and risks. Using Claude Code to draft it is fine; using a plain editor is fine. The spec is what we review against.
4. **Implement.** Use Claude Code if you want — you'll find the spec/dod/runbook workflow lighter that way — but it's not required.
5. **Open a pull request** against `main`. PRs are **required** for external contributors (the maintainer commits direct to `main`; you don't). The PR description should reference the issue and the spec id (e.g. `Spec: 0042`). Make sure the spec's acceptance checkboxes are ticked and the Build log is finalized before requesting review.
6. **Pass the local hooks** (`pre-commit` + `pre-push`) before pushing. CI re-runs them.

Good places to start:

- File an issue describing a friction point in the workflow.
- Add a stack-specific guide under `claude/` (right now: Node webapp and iOS+webapi).
- Tighten a runbook section against a provider you use.
- Propose a cross-project rule via an issue (the shared rules repo is private; the issue is the right surface).

By participating you agree to the project's MIT license. Be kind in reviews — bullets, no preamble, no recap.
