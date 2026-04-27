# Claude operating rules for this repo

Be terse. Bullets > prose. Tables when comparing. No preamble, no recap, no emojis. Only expand if I ask.

## Stack-specific rules
- Node/TS webapp → also read `claude/CLAUDE.node-webapp.md`
- iOS app + web API → also read `claude/CLAUDE.ios-webapi.md`
- Slash command playbooks live in `claude/commands/` — `/spec`, `/ship`, `/verify`.
- If unsure which stack, ask one question, then proceed.

## Spec-first workflow (mandatory)

Whenever I give you a todo list, a feature request, or a non-trivial prompt, **before writing code**:

1. Create or update a spec at `docs/specs/NNNN-<slug>.md` using `docs/specs/TEMPLATE.md`.
   - `NNNN` = next zero-padded integer. Run `ls docs/specs | grep -E '^[0-9]{4}-' | tail -1` to find the last one.
   - Slug = kebab-case, ≤ 5 words.
2. The spec records: my prompt verbatim, restated goal, scope boundaries, acceptance criteria (testable), out-of-scope notes, risks, and a checklist of subtasks.
3. Create a branch named `spec/NNNN-<slug>` (or `feat/NNNN-<slug>` for build work).
4. Commit the spec **first**, in its own commit, before any implementation.
5. As you build, append progress notes + any deviation from the spec to the same file under "Build log". Update acceptance status inline.
6. If I prompt mid-feature, append the new prompt under "Build log" with a timestamp; never silently change scope.

## Definition of done

A task is **not done** until all of these pass — verify each, do not assume:

| Step | How to verify |
|---|---|
| Lint + typecheck | `pnpm lint && pnpm typecheck` (or stack equivalent) returns 0 |
| Unit tests | `pnpm test` — 0 failures, coverage not regressed |
| Integration / API tests | `pnpm test:api` |
| UI / E2E tests (if webapp) | `pnpm test:e2e` |
| Local hooks | `pre-commit` and `pre-push` ran clean |
| Branch pushed | `git push` exit 0; `gh api repos/:owner/:repo/commits/<sha>` returns the commit |
| PR opened | `gh pr view --json state,url` shows OPEN; CI green |
| PR merged (if applicable) | `gh pr view --json state` shows MERGED |
| Deploy succeeded | `scripts/verify-deploy.sh` exit 0 (smoke + health endpoint) |
| Spec updated | Acceptance checkboxes ticked, Build log finalized |

If any step fails, fix it or open a follow-up spec — do not silently mark complete.

## Branching + commits

- One feature → one branch → one PR. Never push to `main` directly.
- Conventional commits: `feat:`, `fix:`, `chore:`, `docs:`, `test:`, `refactor:`.
- Reference spec id in commit body: `Spec: 0042`.
- Keep PR description = spec summary + test evidence.

## Testing defaults

- Always add tests when adding code paths. New endpoint → new API test. New screen/page → new E2E test.
- Prefer real implementations over mocks. Mock only at process boundaries (network, time, randomness, fs).
- Run the full local suite before pushing, even if a hook would catch it.

## Runbook + services

- Anything that requires an external service (Postgres, Redis, Stripe, Resend, Railway plugin, S3, etc.) **must** be documented in `docs/runbook/SERVICES.md` the same PR it's introduced.
- Recreate steps for blowing away cloud env: `docs/runbook/RECREATE.md`. Update it when infra changes.

## Anything missing?

If you spot something the user asked for but is not yet wired (test framework, lint config, env var, runbook entry, GitHub workflow, deploy hook), **add a spec for it** under `docs/specs/` and call it out at the end of your reply in one line.

## Network + secrets

- Outbound is firewalled to an allowlist (`.devcontainer/allowed-domains.txt`). If a tool fails on network, edit that file and `sudo /usr/local/bin/init-firewall.sh`.
- Never write secrets to disk outside `.env` (gitignored). Never log secrets.

## Token discipline

- Default reply: bullets/table, ≤ 10 lines unless asked.
- Code edits: smallest diff that satisfies the spec.
- No unsolicited recaps of changes already shown in the diff.
