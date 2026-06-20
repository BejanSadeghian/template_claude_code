# Deploy: Railway

- `deploy.yml` runs on push to `main`: guards `RAILWAY_TOKEN`, `railway up`, then smoke-checks.
- After a deploy, verify health with `scripts/verify-deploy.sh production` (exit 0).
- Document services + recreate steps in `docs/runbook/deploy-railway.md`.
- Secrets: `RAILWAY_TOKEN` (CI), `APP_URL` (repo variable). Never commit them.
