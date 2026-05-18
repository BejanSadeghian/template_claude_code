# template_claude_code

Modern Claude Code devcontainer + workflow scaffolding for VS Code.

## What this gives you

- **Devcontainer** (Node 22, gh, Railway CLI, ripgrep/fd, Python tooling, `sox` for Claude voice). Permissive outbound network — you auth what you need. Full passwordless `sudo` for the `node` user.
- **Host Claude reuse**: your entire host `~/.claude` is bind-mounted read-only into the container, and plugins/skills/settings are symlinked into the writable Claude config dir on start — Claude Code in the container sees what you've installed without copying.
- **Claude Code auto-update** on every container start (`npm update -g @anthropic-ai/claude-code`).
- **Template sync on container start**: detects updates to template-owned files and prompts to accept/reject/defer interactively (`scripts/template-sync.sh`).
- **Random per-clone VS Code banner color** so windows are visually distinct.
- **Spec-on-commit workflow** for Claude: iterate freely, then a versioned spec under `docs/specs/NNNN-*.md` is created at commit time.
- **Definition of done** scaffolding: lint, typecheck, unit, API, E2E, push verified, deploy verified.
- **CI on GitHub Actions** + matching local git hooks (`hooks/`).
- **Runbook** for Railway recreate-from-scratch + incidents.
- **Per-stack guidance**: Node/TS webapp and iOS-app + web API.

## Quick start: new repo from this template

**One-time (template owner):** on GitHub → repo → Settings → check **Template repository**.

**Each new project (preferred — uses GitHub's template flow):**

GitHub copies the template asynchronously, so do **not** use `--clone` on `gh repo create` — the clone races the copy and you'll hit `fatal: couldn't find remote ref refs/heads/main`. Split it into two steps:

```bash
# 1. create the repo from the template (no --clone)
gh repo create <new-name> --template BejanSadeghian/template_claude_code --private

# 2. confirm GitHub finished copying (should print "main")
gh api repos/<github_account>/<new-name>/branches --jq '.[].name'

# 3. clone it locally
cd ~/Dev   # or wherever you keep repos
gh repo clone <github_account>/<new-name>
cd <new-name>
code .     # then "Reopen in Container"
```

If step 2 returns nothing, wait a couple seconds and retry — the copy is still in flight.

**Fallback (no template flag — clone + reset history):**

```bash
git clone https://github.com/BejanSadeghian/template_claude_code.git <new-name>
cd <new-name>
rm -rf .git && git init -b main
gh repo create <new-name> --private --source=. --push
```

Then inside the new repo's container: `gh auth login -s project` (the `project` scope is needed for the Specs Project v2 sync; add any other provider logins you need), then update project name references in `README.md` / `CLAUDE.md`, and the URL in `.template-source` if you forked the template. `post-create.sh` will have wired git hooks already.

## First-time setup

1. **Host prereqs (one-time):** ensure `~/.claude` exists on your host (it does if you've ever run Claude Code). The container bind-mounts the whole directory; if it's missing, container start will fail.
   ```bash
   mkdir -p ~/.claude
   ```
2. Clone, open in VS Code, "Reopen in Container".
3. On first start, `post-create.sh` picks a random title-bar color and writes `.vscode/settings.json` (it persists).
4. Authenticate whatever you need yourself — e.g. `gh auth login -s project` (the `project` scope enables the Specs board sync), `railway login`. Nothing is auto-authed.
5. Read `CLAUDE.md`. Open Claude Code and run `/spec` for your first feature.

## Adopt template-sync in an existing (pre-sync) repo

If your repo was created from this template *before* `scripts/template-sync.sh` existed, bootstrap it once:

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

After this, every devcontainer start runs `template-sync.sh` and offers `accept/reject/defer/skip-this-version` for any new template changes.

## Cross-project shared memory (optional)

Want the same Claude rules across multiple projects spawned from this template? Stand up a private `claude-shared` repo once, then link it as a submodule in each project that wants it:

```sh
bash scripts/shared-claude.sh init https://github.com/<you>/claude-shared.git
git push
```

After that, every container start runs `git submodule update --remote claude/shared`, so the shared rules are fresh. Claude's `CLAUDE.md` instructions already know to load `claude/shared/CLAUDE.md` if present.

Helper subcommands:

| Command | What it does |
|---|---|
| `bash scripts/shared-claude.sh update` | Pull latest into `claude/shared` |
| `bash scripts/shared-claude.sh propose <slug>` | Draft a cross-project rule under `claude/shared/proposals/` |
| `bash scripts/shared-claude.sh push [msg]` | Commit + push pending changes inside the submodule |

Skip this entirely if you don't want it — nothing breaks. Memory stays project-local.

> **Forking this template?** The default `.gitmodules` points at `BejanSadeghian/claude-shared` (private). If you don't have access, the submodule init fails silently — no error, just an empty `claude/shared/` and the shared-rules section in CLAUDE.md is skipped. To use your own shared repo: `git rm claude/shared`, delete `.gitmodules`, commit, then `bash scripts/shared-claude.sh init <your-url>`.

## Host Claude config (plugins, skills, settings)

The devcontainer bind-mounts your entire host `~/.claude` read-only at `/home/node/.claude-host`. On every container start, `post-create.sh` symlinks these discovery paths from host into the writable Claude config dir (`/home/node/.claude`):

- `plugins/`, `skills/`, `commands/`, `agents/`, `output-styles/`, `marketplaces/`
- `settings.json`, `plugins.json`

So Claude Code in the container sees the same plugins, skills, and settings (incl. which marketplaces/plugins are enabled) as your host. Sessions, history, projects, and auth state stay container-isolated in a named volume.

Implications:
- Host is source of truth — install/update plugins on the host, restart the container.
- Auth tokens inside host `settings.json` will be visible to the container. Inspect your host settings if that matters to you.
- To opt out, remove the `~/.claude` bind in `.devcontainer/devcontainer.json` and the symlink step in `post-create.sh`.

## Versioning

The repo carries a `VERSION` file (semver) and matching `v*` git tags. The `pre-push` hook runs `scripts/bump-version.sh`, which:

- Reads conventional commits since the last `v*` tag.
- Bumps `MAJOR` on `BREAKING CHANGE` / `type!:`, `MINOR` on `feat:`, `PATCH` on `fix|chore|docs|refactor|test|perf|style|build|ci:`.
- Commits `chore: release vX.Y.Z [skip version]` and tags `vX.Y.Z`.
- `setup-hooks.sh` sets `push.followTags=true` so tags ship with the push.

Opt-outs:
- Add `[skip version]` to a commit subject/body — that commit doesn't count.
- `SKIP_VERSION_BUMP=1 git push` — skip the hook for one push.
- Delete `VERSION` — the hook becomes a no-op.
- Force a bump manually: `bash scripts/bump-version.sh [patch|minor|major]`.

## Don't want the spec workflow?

This template ships with an opinionated "spec-on-commit" workflow (`docs/specs/NNNN-*.md`, definition-of-done table, runbook scaffolding). If that's not your style, you can strip it out without affecting anything else:

```bash
rm -rf docs/specs docs/runbook
# Then in CLAUDE.md, delete the sections: "Spec-on-commit (mandatory)",
# "Definition of done", and "Runbook + services".
```

The devcontainer, host-plugin mount, template-sync, firewall config, sudo setup, and Claude Code auto-update will all still work.

## Provider-coupled bits

The deploy/runbook examples (`scripts/verify-deploy.sh`, `docs/runbook/RECREATE.md`, `docs/runbook/SERVICES.md`, `docs/runbook/INCIDENTS.md`) default to **Railway**. Each file has a header noting "default example — replace for your provider." The shape (sections, table columns, smoke check steps) is the part to keep; the Railway specifics are replaceable.

## Claude Code version

Pinned at image build time to whatever was `latest` then. `post-create.sh --start` runs `npm update -g @anthropic-ai/claude-code` on every container start to keep it current. Pin a specific version via the `CLAUDE_CODE_VERSION` build arg in `devcontainer.json` if you want reproducibility.

## Files

| Path | What |
|---|---|
| `.devcontainer/Dockerfile` | Container image |
| `.devcontainer/devcontainer.json` | VS Code dev container config |
| `.devcontainer/init-firewall.sh` | Permissive firewall (ACCEPT all). See git history to restore default-deny. |
| `.devcontainer/post-create.sh` | Bootstraps color, hooks, deps, template-sync prompt |
| `scripts/template-sync.sh` | Interactive: pull template-owned updates into this repo |
| `.template-source` | Upstream template URL — edit when you fork |
| `VERSION` / `LICENSE` | `0.1.0` / MIT |
| `CLAUDE.md` | Root rules for Claude |
| `claude/CLAUDE.node-webapp.md` | Node/TS stack rules |
| `claude/CLAUDE.ios-webapi.md` | iOS + web API rules |
| `claude/commands/` | Slash command playbooks |
| `claude/settings.json` | Project-scoped Claude Code settings |
| `docs/specs/` | Versioned specs (one per feature) |
| `docs/runbook/` | Services + recreate + incidents |
| `.github/workflows/` | CI, E2E, deploy verify |
| `hooks/` | Git pre-commit + pre-push (wired via `core.hooksPath`) |
| `scripts/verify-deploy.sh` | Smoke check for deployed env |
| `scripts/setup-hooks.sh` | Wire `core.hooksPath = hooks` |

## Change the window color

Delete `.vscode/settings.json` and rerun `/usr/local/bin/post-create.sh`. A new random hue will be written.

## Network access

Outbound is permissive by default — this template trusts the container and assumes you authenticate sensitive endpoints yourself. To restore a default-deny allowlist, see the previous version of `.devcontainer/init-firewall.sh` and `allowed-domains.txt` in git history.

## Use with `--dangerously-skip-permissions`

The firewall is permissive in this template, so the blast radius is the network reach of whatever credentials are present in the container. Never give the container a long-lived prod token in env. Keep secrets in Railway/CI, not the container. If you want a tighter network sandbox, restore the default-deny firewall from git history.
