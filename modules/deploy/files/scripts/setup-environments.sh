#!/usr/bin/env bash
# Create the dev/staging/prod GitHub Environments and gate staging+prod with a
# required reviewer (the manual-approval step). Run once per repo.
# Requires: gh CLI authed with repo admin. Usage: scripts/setup-environments.sh <reviewer-username>
set -euo pipefail

REV="${1:?usage: setup-environments.sh <github-username-to-require-as-reviewer>}"
REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
UID_="$(gh api "users/$REV" -q .id)"

# dev: automatic (no protection)
gh api -X PUT "repos/$REPO/environments/dev" >/dev/null && echo "env: dev (auto)"

# staging + production: require a reviewer → manual approval before deploy
for e in staging production; do
  gh api -X PUT "repos/$REPO/environments/$e" --input - >/dev/null <<JSON
{"reviewers":[{"type":"User","id":$UID_}]}
JSON
  echo "env: $e (manual approval — reviewer: $REV)"
done

echo "Done. Set per-environment variables (APP_URL) + secrets (RAILWAY_TOKEN / AZURE_CREDENTIALS) in repo Settings → Environments."
