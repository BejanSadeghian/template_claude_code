# Services

> **Default rows below are a Railway-flavored example.** Replace with your own
> services — the *table shape* is what matters: every external dep gets one row.

Inventory of every external dependency. Update in the same PR that introduces a new service.

| Service | Purpose | Env vars | Where managed | Cost tier |
|---|---|---|---|---|
| Railway (project: `<name>`) | App hosting + Postgres + Redis | `RAILWAY_TOKEN` (CI only) | Railway dashboard | starter |
| Postgres (Railway plugin) | Primary DB | `DATABASE_URL` | Railway plugin | included |
| Redis (Railway plugin) | Cache / queues | `REDIS_URL` | Railway plugin | included |
| Resend | Transactional email | `RESEND_API_KEY` | resend.com | free tier |
| Stripe | Payments | `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` | dashboard.stripe.com | per-tx |
| Sentry | Error tracking | `SENTRY_DSN` | sentry.io | dev tier |
| GitHub | Repo + CI + secrets | n/a | github.com | included |
| GitHub Project v2 (`Specs`) | Kanban board mirroring `docs/specs/*` | local `gh` token w/ `project` scope | github.com/users/.../projects | included |

## Conventions
- Every secret has a corresponding entry in `.env.example` (with a placeholder, not the real value).
- Every secret used by CI is mirrored to GitHub Actions secrets.
- Every secret used in production is mirrored to Railway service variables.
- When you add a service: edit this table, add to `.env.example`, add to `RECREATE.md`, and add a smoke check to `scripts/verify-deploy.sh`.

## One-time setup: GitHub Specs project

```sh
gh auth refresh -s project        # grant Projects v2 scope to your existing login
bash scripts/setup-github-project.sh   # creates label, project, Status field; idempotent
bash scripts/sync-specs-to-github.sh   # backfill issues + board for existing specs
```

After this, `hooks/pre-push` keeps the board in sync. Override with `SKIP_SPEC_SYNC=1 git push`.
