#!/usr/bin/env bash
# Health-verify a deployment. Exit 0 = healthy.
# Usage: scripts/verify-deploy.sh <dev|staging|prod>
# URL resolves from APP_URL (GitHub Environment variable, scoped per env) or
# the per-env override DEV_URL / STAGING_URL / PROD_URL.
set -euo pipefail

ENV="${1:-dev}"
case "$ENV" in
  dev)             URL="${DEV_URL:-${APP_URL:-}}" ;;
  staging)         URL="${STAGING_URL:-${APP_URL:-}}" ;;
  prod|production) URL="${PROD_URL:-${APP_URL:-}}" ;;
  *) echo "unknown env: $ENV"; exit 2 ;;
esac

if [ -z "$URL" ]; then
  echo "no URL configured for $ENV (set APP_URL on the $ENV environment) — skipping smoke."
  exit 0
fi

echo "==> verify $ENV at $URL"
code="$(curl -fsS -o /dev/null -w '%{http_code}' "$URL/health" || echo 000)"
[ "$code" = "200" ] || { echo "health check failed (HTTP $code)"; exit 1; }
echo "health OK ($code)"
curl -fsS -o /dev/null "$URL" || { echo "root unreachable"; exit 1; }
echo "==> $ENV healthy"
