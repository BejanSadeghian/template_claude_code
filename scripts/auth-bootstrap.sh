#!/usr/bin/env bash
# Interactive auth bootstrap. Runs on devcontainer start via .vscode/tasks.json.
# Skip with SKIP_AUTH_BOOTSTRAP=1. Idempotent — only prompts if not already logged in.
set -u

[ "${SKIP_AUTH_BOOTSTRAP:-}" = "1" ] && { echo "auth-bootstrap: skipped"; exit 0; }

echo "── auth bootstrap ───────────────────────────────────"

# gh: needs `project` scope for Specs board sync.
# Use the web (browser) device flow — no username/password, no token paste, no SSH key prompts.
if command -v gh >/dev/null 2>&1; then
  if ! gh auth status >/dev/null 2>&1; then
    echo "GitHub: not logged in. Launching browser device flow…"
    echo "  → you'll see a one-time code and a github.com URL — open it in your host browser."
    gh auth login --hostname github.com --git-protocol https --web --scopes project \
      || echo "  (gh login skipped or failed — re-run later with: gh auth login -w -s project)"
  elif ! gh auth status 2>&1 | grep -qi 'project'; then
    echo "GitHub: logged in but missing 'project' scope. Refreshing via browser…"
    gh auth refresh --hostname github.com --scopes project \
      || echo "  (refresh skipped or failed)"
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
