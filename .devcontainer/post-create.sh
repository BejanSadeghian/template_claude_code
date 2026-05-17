#!/bin/bash
# Idempotent project bootstrap. Runs onCreate (root for SSH copy) and postStart (--start).
set -euo pipefail

WORKSPACE="${WORKSPACE:-/workspace}"
MODE="${1:-init}"

# Step 1: copy host SSH read-only mount into ~/.ssh with proper perms (only on init, as root)
if [ "$MODE" = "init" ] && [ -d /home/node/.ssh-host ]; then
    install -d -m 700 -o node -g node /home/node/.ssh
    cp -r /home/node/.ssh-host/. /home/node/.ssh/ 2>/dev/null || true
    chown -R node:node /home/node/.ssh
    find /home/node/.ssh -type f -exec chmod 600 {} \;
    find /home/node/.ssh -type f -name '*.pub' -exec chmod 644 {} \;
fi

# Drop privileges for the rest if we were invoked as root on init
if [ "$MODE" = "init" ] && [ "$(id -u)" = "0" ]; then
    exec sudo -u node "$0" --start-from-init
fi
[ "$MODE" = "--start-from-init" ] && MODE="init-as-node"

cd "$WORKSPACE"

# Step 2: stable random titleBar color per project (only set if missing)
SETTINGS=".vscode/settings.json"
if [ ! -f "$SETTINGS" ] || ! grep -q "titleBar.activeBackground" "$SETTINGS" 2>/dev/null; then
    mkdir -p .vscode
    HUE=$(( RANDOM % 360 ))
    # HSL -> hex via python (always present in container)
    BG=$(python3 - <<PY
import colorsys
h = $HUE / 360
r,g,b = colorsys.hls_to_rgb(h, 0.35, 0.65)
print('#%02x%02x%02x' % (int(r*255), int(g*255), int(b*255)))
PY
)
    FG=$(python3 - <<PY
import colorsys
h = $HUE / 360
r,g,b = colorsys.hls_to_rgb(h, 0.92, 0.65)
print('#%02x%02x%02x' % (int(r*255), int(g*255), int(b*255)))
PY
)
    cat > "$SETTINGS" <<JSON
{
  "workbench.colorCustomizations": {
    "titleBar.activeBackground": "$BG",
    "titleBar.activeForeground": "$FG",
    "titleBar.inactiveBackground": "$BG",
    "titleBar.inactiveForeground": "$FG",
    "activityBar.background": "$BG",
    "activityBar.foreground": "$FG",
    "statusBar.background": "$BG",
    "statusBar.foreground": "$FG"
  }
}
JSON
    echo "Set window banner color to $BG (hue $HUE)"
fi

# Step 3: gh auth status (best-effort — don't fail container on this)
if command -v gh >/dev/null 2>&1; then
    if ! gh auth status >/dev/null 2>&1; then
        echo "[hint] Run 'gh auth login' in this terminal to enable PR / deploy verification."
    fi
fi

# Step 4: install JS deps if a manifest exists
if [ -f package.json ]; then
    if command -v pnpm >/dev/null 2>&1 && [ -f pnpm-lock.yaml ]; then
        pnpm install --frozen-lockfile || pnpm install || true
    elif [ -f package-lock.json ]; then
        npm ci || npm install || true
    fi
fi

# Step 4b: wire git hooks to ./hooks
if [ -d hooks ] && [ -d .git ]; then
    bash scripts/setup-hooks.sh || true
fi

# Step 5: pre-commit hooks for Python projects
if [ -f .pre-commit-config.yaml ] && command -v pre-commit >/dev/null 2>&1; then
    pre-commit install || true
fi

# Step 6: prompt for template updates (TTY only; silent if up-to-date)
if [ "$MODE" = "--start" ] && [ -f scripts/template-sync.sh ] && [ -d .git ]; then
    bash scripts/template-sync.sh || true
fi

echo "post-create: done ($MODE)"
