# template_claude_code

Modern Claude Code devcontainer + workflow scaffolding for VS Code.

## What this gives you

- **Sandboxed devcontainer** (Node 22, gh, Railway CLI, ripgrep/fd, Python tooling) with a default-deny firewall + editable allowlist (`.devcontainer/allowed-domains.txt`).
- **Random per-clone VS Code banner color** so windows are visually distinct.
- **Spec-on-commit workflow** for Claude: iterate freely, then a versioned spec under `docs/specs/NNNN-*.md` is created at commit time.
- **Strict definition of done**: lint, typecheck, unit, API, E2E, push verified, deploy verified — all checked.
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
gh api repos/BejanSadeghian/<new-name>/branches --jq '.[].name'

# 3. clone it locally
cd ~/Dev   # or wherever you keep repos
gh repo clone BejanSadeghian/<new-name>
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

Then inside the new repo's container: `gh auth login`, `railway login`, `bash scripts/setup-hooks.sh` (if `post-create.sh` didn't run it), and update project name references in `README.md` / `CLAUDE.md` before the first `/spec`.

## First-time setup

1. Clone, open in VS Code, "Reopen in Container".
2. On first start, `post-create.sh` picks a random title-bar color and writes `.vscode/settings.json` (it persists).
3. Authenticate: `gh auth login` and `railway login`.
4. Read `CLAUDE.md`. Open Claude Code and run `/spec` for your first feature.

## Files

| Path | What |
|---|---|
| `.devcontainer/Dockerfile` | Container image |
| `.devcontainer/devcontainer.json` | VS Code dev container config |
| `.devcontainer/init-firewall.sh` | Default-deny outbound firewall |
| `.devcontainer/allowed-domains.txt` | Edit this to broaden network access |
| `.devcontainer/post-create.sh` | Bootstraps color, hooks, deps |
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

## Adjust network access

Edit `.devcontainer/allowed-domains.txt`, then `sudo /usr/local/bin/init-firewall.sh`.

## Change the window color

Delete `.vscode/settings.json` and rerun `/usr/local/bin/post-create.sh`. A new random hue will be written.

## Use with `--dangerously-skip-permissions`

Outbound is firewalled, so the blast radius of an over-eager `claude --dangerously-skip-permissions` is bounded. Still, never give it a long-lived prod token in env. Keep secrets in Railway/CI, not the container.
