# Incident response

Short. Use during fires; expand as you learn.

## First 5 minutes
1. Confirm scope: `scripts/verify-deploy.sh production`. Read failure.
2. Check Railway deployment log: `railway logs --service <name> --tail 200`.
3. Check Sentry for new error fingerprints in last 30 min.
4. If a deploy in the last hour caused it: `railway rollback` to previous deployment.

## Common failure modes

| Symptom | First check | Likely fix |
|---|---|---|
| 502 from Railway | `railway status` shows CRASHED | Rollback; inspect logs for boot error |
| DB connection errors | Postgres plugin status | Restart plugin; check `DATABASE_URL` parity |
| Stripe webhook 400s | `STRIPE_WEBHOOK_SECRET` mismatch | Re-copy from Stripe dashboard |
| All emails failing | Resend dashboard / quota | Rotate `RESEND_API_KEY` |
| Auth loops | Cookie domain mismatch after DNS change | Update `APP_URL` env |

## After resolution
- Open a spec `docs/specs/NNNN-incident-<short>.md` with timeline + root cause + prevention task list.
- Add a regression test that would have caught it.
