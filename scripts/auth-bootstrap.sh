#!/usr/bin/env bash
# Interactive auth bootstrap. Runs on devcontainer start via .vscode/tasks.json.
# Skip with SKIP_AUTH_BOOTSTRAP=1. Idempotent — only prompts if not already logged in.
set -u

[ "${SKIP_AUTH_BOOTSTRAP:-}" = "1" ] && { echo "auth-bootstrap: skipped"; exit 0; }

echo "── auth bootstrap ───────────────────────────────────"

# gh: needs `project` scope for Specs board sync.
if command -v gh >/dev/null 2>&1; then
  if ! gh auth status >/dev/null 2>&1; then
    echo "GitHub: not logged in. Launching device flow…"
    gh auth login -s project -w || echo "  (gh login skipped or failed — re-run later)"
  elif ! gh auth status 2>&1 | grep -qi 'project'; then
    echo "GitHub: logged in but missing 'project' scope. Refreshing…"
    gh auth refresh -s project || echo "  (refresh skipped or failed)"
  else
    echo "GitHub: ✓ logged in with project scope"
  fi
else
  echo "GitHub: gh not installed; skipping"
fi

# Railway (optional)
if command -v railway >/dev/null 2>&1; then
  if ! railway whoami >/dev/null 2>&1; then
    echo "Railway: not logged in. Launching browser flow…"
    railway login || echo "  (railway login skipped or failed — re-run later)"
  else
    echo "Railway: ✓ logged in"
  fi
else
  echo "Railway: railway CLI not installed; skipping"
fi

echo "─────────────────────────────────────────────────────"
