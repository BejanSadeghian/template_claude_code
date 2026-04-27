# /ship — push, PR, merge, deploy, verify

Run only after local `pnpm verify` (or stack equivalent) is green.

Steps (verify each, do not skip):

1. **Commit clean**: `git status` → empty. Push: `git push -u origin HEAD`.
2. **Push verified**: `gh api "repos/{owner}/{repo}/commits/$(git rev-parse HEAD)"` returns 200.
3. **PR**: `gh pr view --json state,url,isDraft`. If draft, `gh pr ready`. Body = spec summary + test evidence (paste `pnpm verify` tail).
4. **CI green**: `gh pr checks --watch` until all pass. If any fail, fix on this branch — do not merge red.
5. **Merge** (if appropriate): `gh pr merge --squash --delete-branch`. Re-check `gh pr view --json state` shows `MERGED`.
6. **Deploy**: Railway auto-deploys from `main`. Wait for service status:
   ```
   railway status --json | jq -r '.deployments[0].status'
   ```
   Loop until `SUCCESS` or fail after 10 min.
7. **Verify**: `scripts/verify-deploy.sh production` exit 0.
8. **Spec finalize**: tick remaining acceptance boxes in `docs/specs/NNNN-<slug>.md`, commit `docs: close NNNN`, push to `main` (or follow-up PR if main is protected).

Only now report "done". If any step fails, surface the failure verbatim — do not retry silently more than twice.
