# Runbook: Railway deploy

| Item | Value |
|---|---|
| Provider | Railway |
| Deploy trigger | push to `main` (Railway auto-deploy) |
| Verify | `scripts/verify-deploy.sh production` |
| Secrets | `RAILWAY_TOKEN` (CI), `APP_URL` (repo variable) |

## Recreate
1. `railway login` → `railway init` / `railway link`.
2. Add Postgres/Redis plugins as needed; copy connection vars.
3. Set GitHub repo secret `RAILWAY_TOKEN` and variable `APP_URL`.
4. Push to `main`; watch CI → Deploy verify.
