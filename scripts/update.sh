#!/usr/bin/env bash
# One-shot updater for the container's tooling.
# Run it by hand with the `update` alias, or automatically on container start
# (post-create.sh --start). Best-effort: a single tool failing never aborts.
set -u

echo "── update ───────────────────────────────────────────"

# Claude Code + the other global npm CLIs
if command -v npm >/dev/null 2>&1; then
  echo "• Claude Code / npm globals"
  npm update -g \
    @anthropic-ai/claude-code \
    pnpm typescript tsx vitest playwright @playwright/test \
    >/dev/null 2>&1 || true
fi

# Railway CLI (re-running the installer upgrades in place)
if command -v railway >/dev/null 2>&1; then
  echo "• Railway CLI"
  curl -fsSL https://railway.app/install.sh | sh >/dev/null 2>&1 || true
fi

# Azure CLI
if command -v az >/dev/null 2>&1; then
  echo "• Azure CLI"
  az upgrade --yes --only-show-errors >/dev/null 2>&1 || true
fi

echo "update: done"
echo "─────────────────────────────────────────────────────"
