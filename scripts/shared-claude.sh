#!/usr/bin/env bash
# Manage the optional claude/shared submodule (private cross-project rules repo).
# Opt-in: `shared-claude.sh init <url>`; everything else is a no-op until then.
set -euo pipefail

SUB_PATH="claude/shared"
CMD="${1:-help}"
shift || true

case "$CMD" in
  init)
    URL="${1:?usage: shared-claude.sh init <git-url>}"
    if [ -d "$SUB_PATH" ]; then
      echo "$SUB_PATH already exists. Aborting." >&2
      exit 1
    fi
    git submodule add -b main "$URL" "$SUB_PATH"
    git commit -m "feat: add claude-shared submodule

Cross-project Claude rules at $SUB_PATH/CLAUDE.md.
Update with: bash scripts/shared-claude.sh update"
    echo "✓ Submodule added at $SUB_PATH. Push when ready."
    ;;

  update)
    if [ ! -f .gitmodules ] || ! grep -q "$SUB_PATH" .gitmodules 2>/dev/null; then
      echo "no $SUB_PATH submodule configured; skipping"
      exit 0
    fi
    git submodule update --init --recursive --remote "$SUB_PATH"
    echo "✓ $SUB_PATH updated"
    ;;

  propose)
    SLUG="${1:?usage: shared-claude.sh propose <slug>}"
    if [ ! -d "$SUB_PATH" ]; then
      echo "no $SUB_PATH; run 'shared-claude.sh init <url>' first" >&2
      exit 1
    fi
    DATE="$(date -u +%Y-%m-%d)"
    FILE="$SUB_PATH/proposals/${DATE}-${SLUG}.md"
    mkdir -p "$(dirname "$FILE")"
    if [ ! -f "$FILE" ]; then
      cat > "$FILE" <<EOF
# ${SLUG}

- Proposed: ${DATE}
- From project: $(basename "$(pwd)")

## Why
(Why this rule would apply across my projects.)

## Suggested rule
(Concise wording, ready to lift into claude/shared/CLAUDE.md.)
EOF
    fi
    echo "Drafted $FILE. Edit, then: bash scripts/shared-claude.sh push '<commit msg>'"
    ;;

  push)
    [ -d "$SUB_PATH" ] || { echo "no $SUB_PATH; nothing to push"; exit 0; }
    git -C "$SUB_PATH" add -A
    if git -C "$SUB_PATH" diff --cached --quiet; then
      echo "no pending changes in $SUB_PATH"
      exit 0
    fi
    MSG="${1:-proposal from $(basename "$(pwd)")}"
    git -C "$SUB_PATH" commit -m "$MSG"
    git -C "$SUB_PATH" push
    echo "✓ Pushed $SUB_PATH"
    ;;

  *)
    cat <<EOF
shared-claude.sh — manage the optional claude/shared submodule.

  init <url>      Add the submodule and commit.
  update          Pull latest from origin/main.
  propose <slug>  Draft a cross-project rule under claude/shared/proposals/.
  push [msg]      Commit + push pending changes inside claude/shared.

Without 'init', everything else is a no-op. The submodule is optional.
EOF
    ;;
esac
