#!/usr/bin/env bash
# Verify a Railway deployment is healthy. Exit 0 = good.
# Usage: scripts/verify-deploy.sh [production|staging]
set -euo pipefail

ENV="${1:-production}"
case "$ENV" in
  production) APP_URL="${APP_URL:-https://example.com}" ;;
  staging)    APP_URL="${STAGING_URL:-https://staging.example.com}" ;;
  *) echo "Unknown env: $ENV"; exit 2 ;;
esac

echo "==> Verifying $ENV at $APP_URL"

# 1. Health endpoint
echo "--> /healthz"
HEALTH=$(curl -fsS --max-time 10 "$APP_URL/healthz") || {
  echo "FAIL: /healthz unreachable"; exit 1;
}
echo "$HEALTH" | jq -e '.status == "ok"' >/dev/null || {
  echo "FAIL: /healthz did not report ok: $HEALTH"; exit 1;
}

# 2. Build/version sanity (if endpoint exposes it)
if VERSION=$(curl -fsS --max-time 5 "$APP_URL/version" 2>/dev/null); then
  echo "--> version: $VERSION"
fi

# 3. Smoke E2E (Playwright @smoke project) — only if config present and Playwright installed
if [ -f playwright.config.ts ] || [ -f playwright.config.js ]; then
  echo "--> smoke E2E"
  if command -v pnpm >/dev/null 2>&1; then
    APP_URL="$APP_URL" pnpm exec playwright test --project=smoke || {
      echo "FAIL: smoke E2E failed"; exit 1;
    }
  fi
fi

# 4. Railway service status (if linked + token present)
if command -v railway >/dev/null 2>&1 && [ -n "${RAILWAY_TOKEN:-}" ]; then
  echo "--> railway status"
  STATUS=$(railway status --json 2>/dev/null | jq -r '.deployments[0].status' || echo "UNKNOWN")
  case "$STATUS" in
    SUCCESS|UNKNOWN) ;;
    *) echo "FAIL: Railway deploy status=$STATUS"; exit 1 ;;
  esac
fi

echo "==> $ENV looks healthy."
