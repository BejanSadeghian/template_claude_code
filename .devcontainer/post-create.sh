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

# Step 6: surface host ~/.claude (plugins, skills, settings) via symlinks
# Host ~/.claude is mounted read-only at /home/node/.claude-host.
# /home/node/.claude is a writable named volume (sessions, history, projects).
# We symlink the discovery paths from host into the writable dir so Claude Code
# sees host plugins/skills/settings without copying or losing write state.
HOST_CLAUDE="/home/node/.claude-host"
LOCAL_CLAUDE="/home/node/.claude"
if [ -d "$HOST_CLAUDE" ]; then
    mkdir -p "$LOCAL_CLAUDE"
    # `plugins` must be writable (Claude Code mutates marketplace cache on load).
    # `settings.json` is handled separately below (Claude Code writes the model
    # choice into it, so it must be writable too). Everything else is read-only
    # on consume, so symlinks are fine.
    for item in skills plugins.json marketplaces commands agents output-styles; do
        SRC="$HOST_CLAUDE/$item"
        DST="$LOCAL_CLAUDE/$item"
        [ -e "$SRC" ] || continue
        if [ -L "$DST" ] && [ "$(readlink "$DST")" = "$SRC" ]; then
            continue
        fi
        rm -rf "$DST"
        ln -s "$SRC" "$DST"
    done
    # settings.json: copy (writable) instead of symlinking the read-only host
    # mount. Claude Code persists the active model (e.g. `/model`) into this
    # file; a read-only symlink makes the switch fail with "settings read only"
    # and pins you to whatever the host last selected. Seed from host on first
    # run only — never clobber a writable copy the user has since edited (so the
    # in-container model choice survives container restarts).
    SRC="$HOST_CLAUDE/settings.json"
    DST="$LOCAL_CLAUDE/settings.json"
    if [ -e "$SRC" ] && { [ -L "$DST" ] || [ ! -e "$DST" ]; }; then
        rm -f "$DST"
        cp "$SRC" "$DST"
        chmod u+w "$DST"
    fi
    # plugins/: copy host → container so it's writable. Re-syncable via `refresh-plugins`.
    if [ -x "$WORKSPACE/scripts/refresh-host-plugins.sh" ]; then
        bash "$WORKSPACE/scripts/refresh-host-plugins.sh" || true
    fi
fi

# Step 6c: refresh any submodules (notably claude/shared if the user opted in).
# No-op if .gitmodules is absent.
if [ -f .gitmodules ]; then
    git submodule update --init --recursive --remote 2>/dev/null || true
fi

# Step 7: keep container tooling up to date (every container start).
# Same thing the `update` alias runs by hand: Claude Code, Railway, Azure CLI.
if [ -f scripts/update.sh ]; then
    bash scripts/update.sh || true
elif command -v npm >/dev/null 2>&1; then
    npm update -g @anthropic-ai/claude-code >/dev/null 2>&1 || true
fi

# Step 8: prompt for template updates (TTY only; silent if up-to-date)
if [ "$MODE" = "--start" ] && [ -f scripts/template-sync.sh ] && [ -d .git ]; then
    bash scripts/template-sync.sh || true
fi

echo "post-create: done ($MODE)"
