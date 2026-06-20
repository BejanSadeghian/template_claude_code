# Claude operating rules for this repo

Be terse. Bullets > prose. Tables when comparing. No preamble, no recap, no emojis. Only expand if I ask.

## Read these first (project config)

Before acting, read and follow, in order:
1. `claude/project.md` — the project profile (app type, git workflow, CI, deploy, auth). **Obey it.** If it's missing, tell me to run `setup`.
2. `claude/preferences.md` — my always-follow custom instructions (e.g. where TODOs live). Obey it.
3. `claude/modules/*.md` — rules added by installed modules (stack / deploy specifics, e.g. the exact lint/test commands).
4. `claude/shared/CLAUDE.md` if it exists — cross-project rules. This file wins on direct conflict.

## Remote-first, auto-push (mandatory)

Keep the remote up to date automatically. No keyword trigger — **never** wait for me to say commit / push / ship / deploy, and **never** ask "want me to commit/push?", "want a PR?", "should I deploy?", or "should I hold so you can test?". Just do it. Ask only for a genuine fork-in-the-road decision that's mine to make — never a permission-to-proceed gate.

- After any meaningful, working change: stage, commit (conventional message), push, and deploy if a deploy module is installed. No confirmation, no file-list recap.
- **Git destination follows `claude/project.md` → Git workflow:**
  - `main` → commit straight to `main`; no branches, no PRs.
  - `branch-pr` → create a feature branch and open a PR automatically (still no asking); keep it updated until merged.
- Commit at logical checkpoints, not one giant blob. The remote is the source of truth — reconcile (pull/rebase) before pushing; don't force.
- Don't push obviously broken work — run the stack's checks first (Definition of done). Fix failures or say so.

## Definition of done

Not done until all pass — verify each, do not assume:
- Lint + typecheck clean, tests pass — use the exact commands from your stack module (`claude/modules/*`). If no stack module is installed, run whatever checks the project defines.
- Local hooks (`pre-commit`, `pre-push`) ran clean.
- Pushed; the commit is visible on the remote.
- If a deploy module is installed: `scripts/verify-deploy.sh` exits 0.

If any step fails, fix it — don't silently mark complete.

## Commits

- Conventional commits: `feat:`, `fix:`, `chore:`, `docs:`, `test:`, `refactor:`. Use `feat!:` or `BREAKING CHANGE:` for a major bump.
- Destination + PR behavior per the Git workflow above.

## Versioning (semver, auto)

- The `VERSION` file and matching `v*` git tags are the source of truth.
- `pre-push` auto-bumps from conventional commits since the last tag (`feat!:`/BREAKING → major, `feat:` → minor, else patch).
- `[skip version]` in a message excludes it; `SKIP_VERSION_BUMP=1 git push` skips the hook once; `bash scripts/bump-version.sh [patch|minor|major]` forces one.

## Continuous async workflow

My job is ideation and planning; yours is to build the moment an idea is solid.
- When a task is clear enough, dispatch developer + test-engineer immediately and background them. Don't wait for "go build it".
- Confirm dispatch in one line, then stay in planning mode with me.
- Surface results only on a genuine decision, a blocker, or when a feature is green, pushed, and deployed.
- Mechanics: always `isolation: "worktree"`; never run two tasks touching the same files concurrently (queue the second); rebuild dispatch state each turn from `git worktree list`.

## Cross-project shared memory (optional submodule)

If `claude/shared/CLAUDE.md` exists (a repo ran `bash scripts/shared-claude.sh init <url>`), also read it. Project rules here win on conflict.
- Project-specific memory → local `memory/`.
- Cross-project (applies to any of my repos) → draft `claude/shared/proposals/<YYYY-MM-DD>-<slug>.md`, then commit + push inside the submodule. Default to project-specific if unsure.
- If `claude/shared/` doesn't exist, the mechanism is off — keep everything in `memory/`. Don't prompt me to set it up.

## Model selection

Don't pin a model. Use whatever the running CLI is set to; I switch with `/model` (including the latest, e.g. Fable). Never hardcode a model id in settings or scripts.

## Network + secrets

- Outbound network is unrestricted in this container; I authenticate anything sensitive. See `.devcontainer/init-firewall.sh` to restore a default-deny allowlist.
- Never write secrets outside `.env` (gitignored). Never log secrets.
- Document any external service you add in `docs/runbook/` (a deploy module may scaffold this).

## Token discipline

- Default reply: bullets/table, ≤ 10 lines unless asked.
- Code edits: smallest diff that satisfies the request. No unsolicited recaps of changes already in the diff.
