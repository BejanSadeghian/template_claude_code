#!/usr/bin/env bash
# Provider-agnostic deploy for a single environment.
# Usage: scripts/deploy.sh <dev|staging|prod>
# Target (railway|azure|both) comes from DEPLOY_TARGET or claude/project.md → "targets".
# Per-environment URLs/tokens come from the GitHub Environment (vars/secrets) at runtime.
set -euo pipefail

ENV="${1:?usage: deploy.sh <dev|staging|prod>}"
TARGET="${DEPLOY_TARGET:-}"
if [ -z "$TARGET" ] && [ -f claude/project.md ]; then
  TARGET="$(grep -E '^- *targets:' claude/project.md | head -1 | sed 's/.*targets:[[:space:]]*//; s/[[:space:]]*#.*//' | tr -d ' ')"
fi
TARGET="${TARGET:-railway}"
echo "==> deploy '$ENV' via '$TARGET' (release ${RELEASE_VERSION:-none})"

deploy_railway() {
  command -v railway >/dev/null 2>&1 || npm i -g @railway/cli@4
  [ -n "${RAILWAY_TOKEN:-}" ] || { echo "RAILWAY_TOKEN not set — skipping railway"; return 0; }
  # One service per `railway up`; map the GitHub env to a Railway environment.
  railway up --service "${RAILWAY_SERVICE:-web}" --environment "$ENV"
}

deploy_azure() {
  [ -n "${AZURE_CREDENTIALS:-}" ] || { echo "AZURE_CREDENTIALS not set — skipping azure"; return 0; }
  # Convention: one Web App per env, e.g. myapp-dev / myapp-staging / myapp-prod.
  az webapp deploy --name "${AZURE_WEBAPP_NAME:-app}-$ENV" --src-path . --type zip
}

case "$TARGET" in
  *railway*) deploy_railway ;;
esac
case "$TARGET" in
  *azure*) deploy_azure ;;
esac
case "$TARGET" in
  *railway*|*azure*) ;;
  *) echo "unknown DEPLOY_TARGET '$TARGET' — edit scripts/deploy.sh"; exit 1 ;;
esac
