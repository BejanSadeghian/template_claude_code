# Claude operating rules for this repo

Be terse. Bullets > prose. Tables when comparing. No preamble, no recap, no emojis. Only expand if I ask.

## Stack-specific rules
- Node/TS webapp → also read `claude/CLAUDE.node-webapp.md`
- iOS app + web API → also read `claude/CLAUDE.ios-webapi.md`
- `/verify` playbook lives in `claude/commands/`.
- If unsure which stack, ask one question, then proceed.

## Remote-first, auto-push (mandatory)

Keep the remote up to date automatically. There is no keyword trigger — **never** wait for me to say commit / push / ship / deploy, and **never** ask "want me to commit/push?", "want a PR?", "should I deploy?", or "should I hold so you can test?". Just do it. The only time you ask is a genuine fork-in-the-road decision that's mine to make — never a permission-to-proceed gate.

- After any meaningful, working change, stage it, commit with a conventional message, `git push`, and deploy if a deploy path is configured. No confirmation, no file-list recap.
- Open a PR yourself when branching is warranted; don't ask first.
- Commit at logical checkpoints rather than batching unrelated work into one blob.
- The remote is the source of truth. If local and remote diverge, reconcile (pull/rebase) before pushing rather than forcing.
- Don't push obviously broken work — run the relevant checks first (see Definition of done). If something fails, fix it or say so; don't sit on green work waiting for permission.

Trivial-only sessions (a single typo/format tweak) can still be one commit — just push it.

## Cross-project shared memory (optional submodule)

If `claude/shared/CLAUDE.md` exists (i.e. a downstream repo has run `bash scripts/shared-claude.sh init <url>`), **also** read it. Those are cross-project rules; project-level rules in this file take precedence on direct conflict.

When you decide to save a feedback/preference memory:
- **Project-specific** (relevant only here) → local `memory/` per the auto-memory rules.
- **Cross-project** (a rule that would apply in any of my repos) → draft a file under `claude/shared/proposals/<YYYY-MM-DD>-<slug>.md` and commit + push inside the submodule:
  ```sh
  git -C claude/shared add proposals/<file>.md
  git -C claude/shared commit -m "propose: <slug>"
  git -C claude/shared push
  ```
  Use your best judgment on which bucket. Default to project-specific if unsure.

If `claude/shared/` does **not** exist, the shared mechanism is disabled — keep everything in local `memory/`. Do not prompt me to set it up.

## Continuous async workflow

I want a continuous async workflow. My job is ideation and planning — I will describe and refine features in conversation with you. Your job is to dispatch agents to build them the moment the idea is solid enough to act on, without interrupting me.

Rules:
- When a task is clear enough to build, dispatch developer + test-engineer immediately and background them.
- Don't wait for me to say "go build it" — use your judgment on readiness.
- Confirm dispatch in one line ("dispatched developer + test-engineer on [feature]") then stay in planning mode with me.
- Surface agent results as a brief interruption only when they need a genuine decision from me, or when a feature is fully green, pushed, and deployed.
- If agents hit a blocker, flag it quickly and ask what I want to do, then get back to planning.

Mechanics (non-negotiable so parallel agents don't clobber each other):
- Always dispatch with `isolation: "worktree"` so each task gets an isolated checkout + branch.
- Never dispatch two tasks that touch the same files concurrently. If a conflict is unavoidable, queue the second and tell me in one line.
- Rebuild your dispatch state each turn from `git worktree list`, not memory.

## Definition of done

A task is **not done** until all of these pass — verify each, do not assume:

| Step | How to verify |
|---|---|
| Lint + typecheck | `pnpm lint && pnpm typecheck` (or stack equivalent) returns 0 |
| Unit tests | `pnpm test` — 0 failures, coverage not regressed |
| Integration / API tests | `pnpm test:api` |
| UI / E2E tests (if webapp) | `pnpm test:e2e` |
| Local hooks | `pre-commit` and `pre-push` ran clean |
| Pushed | `git push` exit 0; the commit is visible on the remote |
| Deploy succeeded (if configured) | `scripts/verify-deploy.sh` exit 0 (smoke + health endpoint) |

If any step fails, fix it — do not silently mark complete.

## Commits

- Commit and push directly to `main` by default. Branches + PRs only when isolation actually helps (long-running work, risky refactors, external collaborators).
- Conventional commits: `feat:`, `fix:`, `chore:`, `docs:`, `test:`, `refactor:`. Use `feat!:` or include `BREAKING CHANGE:` in the body for major bumps.

## Versioning (semver, auto)

- The `VERSION` file and matching `v*` git tags are the source of truth.
- `pre-push` hook auto-bumps based on conventional commits since the last tag (`feat!:`/BREAKING → major, `feat:` → minor, others → patch).
- Add `[skip version]` to a commit message to exclude it from the bump, or `SKIP_VERSION_BUMP=1 git push` to skip the hook for one push.
- Force a bump manually: `bash scripts/bump-version.sh [patch|minor|major]`.

## Testing defaults

- Always add tests when adding code paths. New endpoint → new API test. New screen/page → new E2E test.
- Prefer real implementations over mocks. Mock only at process boundaries (network, time, randomness, fs).
- Run the full local suite before pushing, even if a hook would catch it.

## Runbook + services

- Anything that requires an external service (Postgres, Redis, Stripe, Resend, Railway plugin, S3, etc.) **must** be documented in `docs/runbook/SERVICES.md` in the same commit it's introduced.
- Recreate steps for blowing away cloud env: `docs/runbook/RECREATE.md`. Update it when infra changes.

## Model selection

- Don't pin a model. Use whatever model the running CLI is set to; I switch with `/model` (including the latest, e.g. Fable). Never hardcode a model id in settings or scripts.

## Network + secrets

- Outbound network is unrestricted in this container. The user authenticates anything sensitive. See `.devcontainer/init-firewall.sh` (and git history) to restore a default-deny allowlist if needed.
- Never write secrets to disk outside `.env` (gitignored). Never log secrets.

## Token discipline

- Default reply: bullets/table, ≤ 10 lines unless asked.
- Code edits: smallest diff that satisfies the request.
- No unsolicited recaps of changes already shown in the diff.
