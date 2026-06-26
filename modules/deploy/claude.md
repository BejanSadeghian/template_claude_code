# Deploy: staged CD

The same flow every time: **release → dev → staging → prod**.
- Push to `main` → `release` (semantic-release: conventional commits → version + GitHub Release) → **dev deploys automatically**.
- **staging** and **prod** each wait on a **manual approval** (GitHub Environment required reviewers). Promotion is the one intentional human gate.
- Target(s) come from `claude/project.md` → Deployment → `targets` (`railway` / `azure` / both); `scripts/deploy.sh <env>` dispatches. Same deploy path for every environment.
- After each stage, `scripts/verify-deploy.sh <env>` must exit 0.
- Release numbers use semantic-release (semver); staging/prod carry that version.
- Per-environment URLs/secrets live on the GitHub Environment (dev/staging/production), not in code.
- semantic-release owns release tags; if the local `pre-push` semver bump double-tags, push releases with `[skip version]` or `SKIP_VERSION_BUMP=1`.
