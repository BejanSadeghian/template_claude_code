#!/usr/bin/env bash
# Verify a deployment is healthy. Exit 0 = good.
# Usage: scripts/verify-deploy.sh [production|staging]
# Provider-neutral: checks a health endpoint + root reachability. Extend per provider.
set -euo pipefail

ENV="${1:-production}"
case "$ENV" in
  production) APP_URL="${APP_URL:-https://example.com}" ;;
  staging)    APP_URL="${STAGING_URL:-https://staging.example.com}" ;;
  *) echo "Unknown env: $ENV"; exit 2 ;;
esac

echo "==> Verifying $ENV at $APP_URL"

# 1. Health endpoint
code=$(curl -fsS -o /dev/null -w '%{http_code}' "$APP_URL/health" || echo 000)
[ "$code" = "200" ] || { echo "Health check failed (HTTP $code)"; exit 1; }
echo "Health OK ($code)"

# 2. Root reachable
curl -fsS -o /dev/null "$APP_URL" || { echo "Root unreachable"; exit 1; }
echo "Root OK"

echo "==> $ENV healthy"
