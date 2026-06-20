# Deploy: Railway

- Railway auto-deploys from `main`; the `Deploy verify` workflow runs after CI succeeds.
- After a deploy, verify health with `scripts/verify-deploy.sh production` (exit 0).
- Document services + recreate steps in `docs/runbook/deploy-railway.md`.
- Secrets: `RAILWAY_TOKEN` (CI), `APP_URL` (repo variable). Never commit them.
