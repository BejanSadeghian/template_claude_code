# Recreate the cloud env from scratch

Goal: if every cloud resource is destroyed, these steps rebuild a working production within 60 minutes.

## Prereqs (on the operator's laptop)
- `gh`, `railway`, and `stripe` CLIs installed and authenticated.
- Repo cloned, this devcontainer running.
- Access to the team's password manager for service signups.

## Steps

### 1. Railway project
```
railway login
railway init --name <project-name>
railway link
railway add --plugin postgresql
railway add --plugin redis
```
Wait for plugins to provision; copy `DATABASE_URL` and `REDIS_URL` from the Railway dashboard if not auto-injected.

### 2. Service variables (Railway dashboard → Variables)
Copy each row from `SERVICES.md`. Required minimum:
- `NODE_ENV=production`
- `DATABASE_URL` (from plugin)
- `REDIS_URL` (from plugin)
- `RESEND_API_KEY`
- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`
- `SENTRY_DSN`
- `APP_URL=https://<your-railway-domain>`

### 3. Connect repo + first deploy
```
railway service connect <github-org>/<repo> --branch main
railway up
```

### 4. DB migrations
```
railway run pnpm db:migrate
railway run pnpm db:seed   # optional, dev/staging only
```

### 5. Stripe webhooks
```
stripe listen --forward-to https://<your-railway-domain>/api/webhooks/stripe
# Copy signing secret into STRIPE_WEBHOOK_SECRET on Railway.
```

### 6. DNS
Point CNAME to the Railway-provided host. Verify HTTPS resolves.

### 7. Verify
```
scripts/verify-deploy.sh production
```
Must exit 0. If not, see `INCIDENTS.md`.

### 8. CI secrets (GitHub → Settings → Secrets)
Mirror anything CI needs: `RAILWAY_TOKEN`, `STRIPE_TEST_KEY`, etc.

## Time budget
- Railway provisioning: ~10 min
- DNS propagation: ~15 min
- Everything else: ~5 min hands-on

## What to update when infra changes
1. This file (steps stay current).
2. `SERVICES.md` (inventory).
3. `.env.example` (placeholders).
4. `scripts/verify-deploy.sh` (smoke checks for any new endpoint or service).
