# Claude operating rules for this repo

Be terse. Bullets > prose. Tables when comparing. No preamble, no recap, no emojis. Only expand if I ask.

## Stack-specific rules
- Node/TS webapp → also read `claude/CLAUDE.node-webapp.md`
- iOS app + web API → also read `claude/CLAUDE.ios-webapi.md`
- Slash command playbooks live in `claude/commands/` — `/spec`, `/ship`, `/verify`.
- If unsure which stack, ask one question, then proceed.

## Spec-on-commit (mandatory)

I'll prompt and iterate freely without specs. **Do not create a spec just because a prompt arrived.** Only create one when I ask to commit (or push, or ship) — that's the trigger.

When I say commit / push / ship, just do it. **Never** ask "want me to commit/push?", "should I hold so you can test?", or any variant. No confirmation. No "hold so you can test first" offers. No file-list recap. Run the spec workflow, stage, commit, push. Period.

At commit time:

1. Create or update a spec at `docs/specs/NNNN-<slug>.md` using `docs/specs/TEMPLATE.md`.
   - `NNNN` = next zero-padded integer. Run `ls docs/specs | grep -E '^[0-9]{4}-' | tail -1` to find the last one.
   - Slug = kebab-case, ≤ 5 words.
2. The spec records: the consolidated prompts that drove the work (paste verbatim, in order), restated goal, scope, acceptance criteria (testable), out-of-scope notes, risks, what was actually built.
3. Stage the spec with the work and commit them together. For large diffs, optionally commit the spec first as its own commit, then the implementation.
4. If I follow up later with prompts that extend the same area, append them to the existing spec's "Build log" before the next commit.

Trivial commits (typo fixes, formatting, comment tweaks, dependency bumps) skip the spec.

On push, `hooks/pre-push` mirrors each spec to a GitHub issue + the "Specs" Project v2 board (`scripts/sync-specs-to-github.sh`). The spec file's `Status:` line is the source of truth; `done`/`abandoned` close the matching issue. Bootstrap once per repo with `bash scripts/setup-github-project.sh` (requires `gh auth refresh -s project`).

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

I want a continuous async workflow. My job is ideation and planning — I will describe features and refine specs in conversation with you. Your job is to dispatch agents to work against specs the moment they're solid enough to act on, without interrupting me.

Rules:
- When a spec is clear enough to build against, dispatch developer + test-engineer immediately and background them.
- Don't wait for me to say "go build it" — use your judgment on spec readiness.
- Confirm dispatch in one line ("dispatched developer + test-engineer on [feature]") then stay in planning mode with me.
- Surface agent results as a brief interruption only when they need a decision from me, or when a feature is fully green.
- If agents hit a blocker, flag it quickly and ask what I want to do, then get back to planning.

Mechanics (non-negotiable so parallel agents don't clobber each other):
- Always dispatch with `isolation: "worktree"` so each spec gets an isolated checkout + branch.
- Never dispatch two specs that touch the same files concurrently. If a conflict is unavoidable, queue the second and tell me in one line.
- Subagents commit on their own branch but do **not** push or merge. Merging to `main` only happens when I say ship.
- Rebuild your dispatch state each turn from `git worktree list` + spec `Status:` lines, not memory.

## Definition of done

A task is **not done** until all of these pass — verify each, do not assume:

| Step | How to verify |
|---|---|
| Lint + typecheck | `pnpm lint && pnpm typecheck` (or stack equivalent) returns 0 |
| Unit tests | `pnpm test` — 0 failures, coverage not regressed |
| Integration / API tests | `pnpm test:api` |
| UI / E2E tests (if webapp) | `pnpm test:e2e` |
| Local hooks | `pre-commit` and `pre-push` ran clean |
| Pushed | `git push` exit 0; `gh api repos/:owner/:repo/commits/<sha>` returns the commit |
| Deploy succeeded | `scripts/verify-deploy.sh` exit 0 (smoke + health endpoint) |
| Spec updated | Acceptance checkboxes ticked, Build log finalized |

If any step fails, fix it or open a follow-up spec — do not silently mark complete.

## Commits

- Commit directly to `main`. Branches + PRs are optional, only when isolation actually helps (long-running work, risky refactors, external collaborators).
- Conventional commits: `feat:`, `fix:`, `chore:`, `docs:`, `test:`, `refactor:`. Use `feat!:` or include `BREAKING CHANGE:` in the body for major bumps.
- Reference spec id in commit body: `Spec: 0042`.

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

## Anything missing?

If you spot something the user asked for but is not yet wired (test framework, lint config, env var, runbook entry, GitHub workflow, deploy hook), **add a spec for it** under `docs/specs/` and call it out at the end of your reply in one line.

## Network + secrets

- Outbound network is unrestricted in this container. The user authenticates anything sensitive. See `.devcontainer/init-firewall.sh` (and git history) to restore a default-deny allowlist if needed.
- Never write secrets to disk outside `.env` (gitignored). Never log secrets.

## Token discipline

- Default reply: bullets/table, ≤ 10 lines unless asked.
- Code edits: smallest diff that satisfies the spec.
- No unsolicited recaps of changes already shown in the diff.
