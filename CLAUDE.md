# Claude operating rules for this repo

Be terse. Bullets > prose. Tables when comparing. No preamble, no recap, no emojis. Only expand if I ask.

## Read these first (project config)

Before acting, read and follow, in order:
1. `claude/project.md` — the project profile (app type, git workflow, CI, deploy, auth, feature board, owner). **Obey it.** If it's missing, tell me to run `setup`.
2. `claude/preferences.md` — my always-follow custom instructions (e.g. where TODOs live). Obey it.
3. `claude/modules/*.md` — rules added by installed modules (stack / deploy specifics, e.g. exact lint/test/deploy commands).
4. `claude/shared/CLAUDE.md` if it exists — cross-project rules. This file wins on direct conflict.

## Shipping — push every green, no gate

Pushing = shipping: CD runs in GitHub Actions, so a push to `main` auto-deploys to **dev**.
- Merge every green sub-agent branch to `main` and push immediately — no "ship" gate, no asking, no keyword. Git destination follows `claude/project.md` → Git workflow (`main` = straight to main, no PRs; `branch-pr` = branch + auto-PR).
- Pause only for: destructive/irreversible actions, scope changes, or failed verification.
- Don't push obviously broken work — run the stack's Definition of done first; fix failures or say so.
- The remote is the source of truth; reconcile (pull/rebase) before pushing, don't force.
- Promotion to staging/prod is gated by manual approval (see `claude/project.md` → Deployment) — that's the one place a human gate is intentional.

## Delegate work, stay responsive

Do substantive/long work in backgrounded sub-agents so the main thread stays free for me.
- Dispatch builds, investigations, infra/deploy debugging, refactors, and one-offs as sub-agents with `isolation: "worktree"` and `run_in_background: true`.
- Keep inline only the quick can't-delegate steps: dispatching, merging green branches, pushing, answering me.
- Worktree mechanics: never two agents on the same files concurrently (queue the second); each agent commits on its own branch and does NOT push/merge — you merge the green result.
- Rebuild dispatch state each turn from `git worktree list`, not memory.
- Ping me (PushNotification) when a delegated task completes.

## Feature tracking — GitHub Project

Track every requested feature on the GitHub Project board **named after this repo** (project id, Status field id, lane option ids, and the owner to ping live in `claude/project.md`). One board per repo — never mix repos on a board. Bootstrap the board once with `bash scripts/feature-board.sh`.
- Cards are **real repo issues labeled `feature`** (not draft items), so assignment/@mention notifies me.
- Lanes live on the Status field, viewed as a board: **Presented** (described, before building) → **Active** (building) → **Verify** (green + tested, awaiting my verification) → **Closed** (I confirm).
- On move to **Verify**: also `gh issue edit <n> --add-assignee <owner>` + a "✅ Ready to verify" comment. A Projects field change alone sends NO notification — the assignment is what pings me (GitHub Mobile + email).
- Rework loop: if I reject a Verify item (message, comment, or drag back), move Verify → Active, rebuild, return to Verify (re-assign + re-ping). You can't see board drags passively — act on my message/comment.
- Proactively remind me of anything sitting in **Verify**.
- **Create a card** (when I request a feature): write a real **description** for the issue body — what's being built, why, and acceptance criteria. If my request was terse or cryptic, expand it into a clear description; don't just paste my words. Then make the issue, add it to the board, set lane to Presented:
  ```sh
  url=$(gh issue create --label feature --title "<feature>" --body "<clear description + acceptance criteria>" | tail -1)
  gh project item-add <projectNumber> --owner <owner> --url "$url"
  # then set Status → Presented (ids from claude/project.md):
  itemId=$(gh project item-list <projectNumber> --owner <owner> --format json \
    | python3 -c "import sys,json;print(next(i['id'] for i in json.load(sys.stdin)['items'] if i.get('content',{}).get('url')=='$url'))")
  gh project item-edit --id "$itemId" --project-id <project-id> --field-id <status-field-id> --single-select-option-id <Presented optId>
  ```
- **Move a card** (change lane): `gh project item-edit --id <itemId> --project-id <project-id> --field-id <status-field-id> --single-select-option-id <optId>` (ids in `claude/project.md`; needs the gh `project` scope).

## UI changes — show before/after

Any change that alters the UI: capture **before and after screenshots** (via Playwright / the `agentic-e2e` harness, or a manual shot) and attach both to the feature issue and the "✅ Ready to verify" comment, so I can compare. Don't call a UI change done on description alone.

## Definition of done

Not done until all pass — verify each, do not assume:
- Lint + typecheck clean, tests pass — use the exact commands from the stack module (`claude/modules/*`).
- Local hooks (`pre-commit`, `pre-push`) ran clean.
- Pushed; the commit is visible on the remote.
- If a deploy is configured: the **dev** deploy succeeded and `scripts/verify-deploy.sh` exits 0.
- Any project-specific gates declared in `claude/project.md` / modules (e.g. Storybook updated + deployed, extra deploy targets) — verify, don't assume.

## Build full scope

Build everything requested — never defer or cherry-pick a subset. Deliver the full scope in tested slices.

## Commits

- Conventional commits: `feat:`, `fix:`, `chore:`, `docs:`, `test:`, `refactor:`. Use `feat!:` or `BREAKING CHANGE:` for a major bump.
- Destination + PR behavior per the Git workflow above.

## Versioning (semver, auto)

- The `VERSION` file and matching `v*` git tags are the source of truth.
- `pre-push` auto-bumps from conventional commits since the last tag (`feat!:`/BREAKING → major, `feat:` → minor, else patch).
- `[skip version]` in a message excludes it; `SKIP_VERSION_BUMP=1 git push` skips the hook once; `bash scripts/bump-version.sh [patch|minor|major]` forces one.
- Staging/prod deploys carry a semantic-release version (release number) — see `claude/project.md` → Deployment.

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
