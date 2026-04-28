# /ship — push, deploy, verify

Run only after local `pnpm verify` (or stack equivalent) is green.

Steps (verify each, do not skip):

1. **Commit clean**: `git status` → empty.
2. **Push**: `git push`. Confirm: `gh api "repos/{owner}/{repo}/commits/$(git rev-parse HEAD)"` returns 200.
3. **CI green** (if configured): `gh run watch` on the latest run for this commit. If red, fix on `main` — do not deploy red.
4. **Deploy**: Railway auto-deploys from `main`. Wait for service status:
   ```
   railway status --json | jq -r '.deployments[0].status'
   ```
   Loop until `SUCCESS` or fail after 10 min.
5. **Verify**: `scripts/verify-deploy.sh production` exit 0.
6. **Spec finalize**: tick remaining acceptance boxes in `docs/specs/NNNN-<slug>.md`, commit `docs: close NNNN`, push.

Only now report "done". If any step fails, surface the failure verbatim — do not retry silently more than twice.

If you're working on a branch (optional, only for risky/long-running work), substitute step 2 with `gh pr create` → `gh pr merge --squash` once CI passes.
