#!/usr/bin/env bash
# Wire repo to use ./hooks instead of .git/hooks.
# Run once after clone (post-create.sh also calls this).
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

git config core.hooksPath hooks
git config push.followTags true
chmod +x hooks/* scripts/*.sh 2>/dev/null || true
echo "Git hooks path → ./hooks; push.followTags = true"
