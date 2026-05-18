#!/usr/bin/env bash
# Copy host ~/.claude/plugins → container ~/.claude/plugins (writable).
# Runs on container start and on demand via `refresh-plugins` alias.
# Host stays read-only; container gets its own writable copy.
set -u

HOST_PLUGINS="/home/node/.claude-host/plugins"
LOCAL_PLUGINS="/home/node/.claude/plugins"

if [ ! -d "$HOST_PLUGINS" ]; then
  echo "refresh-plugins: no host plugins dir; nothing to do"
  exit 0
fi

# Drop any stale symlink left over from previous symlink-based setup.
if [ -L "$LOCAL_PLUGINS" ]; then
  rm -f "$LOCAL_PLUGINS"
fi

mkdir -p "$LOCAL_PLUGINS"

if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete "$HOST_PLUGINS/" "$LOCAL_PLUGINS/"
else
  # Fallback: rm + cp. Slower but no dependency.
  find "$LOCAL_PLUGINS" -mindepth 1 -delete 2>/dev/null || true
  cp -a "$HOST_PLUGINS/." "$LOCAL_PLUGINS/"
fi

echo "refresh-plugins: synced host → container ($LOCAL_PLUGINS)"
