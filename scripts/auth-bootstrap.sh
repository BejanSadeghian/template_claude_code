#!/usr/bin/env bash
# Auth bootstrap. Runs on devcontainer start via .vscode/tasks.json.
# Skip with SKIP_AUTH_BOOTSTRAP=1. Idempotent — only prompts if not already logged in.
#
# Login mode (default: web — browser/device flow, no username/password):
#   - env CLAUDE_AUTH_WEB=0  → force credential/token entry instead
#   - or set "Auth: password" in claude/project.md (via the `setup` wizard)
set -u

[ "${SKIP_AUTH_BOOTSTRAP:-}" = "1" ] && { echo "auth-bootstrap: skipped"; exit 0; }
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)" 2>/dev/null || true

# Resolve auth mode: env wins, else project profile, else default web.
AUTH_WEB="${CLAUDE_AUTH_WEB:-}"
if [ -z "$AUTH_WEB" ]; then
    if [ -f claude/project.md ] && grep -qiE '^- *Auth: *password' claude/project.md; then
        AUTH_WEB=0
    else
        AUTH_WEB=1
    fi
fi

echo "── auth bootstrap ───────────────────────────────────"
[ "$AUTH_WEB" = "1" ] && echo "  mode: web (browser / device code — no passwords)" \
                      || echo "  mode: credentials (CLAUDE_AUTH_WEB=0 / Auth: password)"

# GitHub — request the scopes this template needs:
#   repo      push code (private repos)
#   workflow  push .github/workflows/* (REQUIRED — CI/deploy modules add workflows;
#             without it, any push touching a workflow file is rejected by GitHub)
#   project   GitHub Projects (v2) read/write
#   read:org  org membership / teams
GH_SCOPES="repo,workflow,project,read:org"
if command -v gh >/dev/null 2>&1; then
    if ! gh auth status >/dev/null 2>&1; then
        if [ "$AUTH_WEB" = "1" ]; then
            echo "GitHub: not logged in. Launching browser device flow…"
            echo "  → open the printed github.com URL in your host browser and enter the code."
            gh auth login --hostname github.com --git-protocol https --web --scopes "$GH_SCOPES" \
                || echo "  (gh login skipped/failed — re-run: gh auth login -w -s $GH_SCOPES)"
        else
            echo "GitHub: not logged in. Interactive credential/token entry…"
            gh auth login --hostname github.com --git-protocol https --scopes "$GH_SCOPES" \
                || echo "  (gh login skipped/failed — re-run: gh auth login -s $GH_SCOPES)"
        fi
    else
        # Already logged in — ensure workflow + project scopes (older logins lack them).
        have="$(gh auth status 2>&1 | grep -io "token scopes:.*" || true)"
        need=""
        case "$have" in *workflow*) ;; *) need="workflow" ;; esac
        case "$have" in *project*) ;; *) need="${need:+$need,}project" ;; esac
        if [ -n "$need" ]; then
            echo "GitHub: ✓ logged in — adding missing scope(s): $need"
            gh auth refresh --hostname github.com --scopes "$need" \
                || echo "  (scope refresh skipped/failed — re-run: gh auth refresh -s $need)"
        else
            echo "GitHub: ✓ logged in (repo, workflow, project)"
        fi
    fi
else
    echo "GitHub: gh not installed; skipping"
fi

# Railway (optional) — browser flow; --browserless for headless code entry
if command -v railway >/dev/null 2>&1; then
    if ! railway whoami >/dev/null 2>&1; then
        echo "Railway: not logged in. Launching login…"
        if [ "$AUTH_WEB" = "1" ]; then
            railway login || echo "  (railway login skipped/failed)"
        else
            railway login --browserless || echo "  (railway login skipped/failed)"
        fi
    else
        echo "Railway: ✓ logged in"
    fi
else
    echo "Railway: railway CLI not installed; skipping"
fi

# Azure (optional) — device-code (browser page + code); no password CLI flow.
if command -v az >/dev/null 2>&1; then
    if ! az account show >/dev/null 2>&1; then
        echo "Azure: not logged in. Launching device-code flow…"
        echo "  → open the printed URL in your host browser and enter the code."
        az login --use-device-code --only-show-errors >/dev/null \
            || echo "  (az login skipped/failed — re-run: az login --use-device-code)"
    else
        echo "Azure: ✓ logged in"
    fi
else
    echo "Azure: az CLI not installed; skipping"
fi

echo "─────────────────────────────────────────────────────"
