#!/usr/bin/env bash
# Show this repo's template version, whether it's behind the upstream template,
# and the short commands you can run. Read-only: never changes anything.
# Run it with the `template-status` alias, or it runs on container start.
set -u

TEMPLATE_REMOTE="${TEMPLATE_REMOTE:-template}"
TEMPLATE_BRANCH="${TEMPLATE_BRANCH:-main}"
SOURCE_FILE=".template-source"

cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

CURRENT_VERSION="$( [ -f VERSION ] && tr -d ' \n' < VERSION || echo '?' )"

# Template-owned paths (mirror of the list in scripts/template-sync.sh).
PATHS=(
    .devcontainer modules claude/settings.json claude/commands
    scripts/template-sync.sh scripts/template-status.sh scripts/module.sh
    scripts/setup.sh scripts/setup-hooks.sh scripts/bump-version.sh scripts/update.sh
    scripts/auth-bootstrap.sh scripts/shared-claude.sh
    .vscode/tasks.json hooks/pre-commit hooks/pre-push docs/runbook
    docs/TEMPLATE.md CLAUDE.md
)

# Resolve the upstream template URL (env > .template-source > fallback).
if [ -z "${TEMPLATE_URL:-}" ] && [ -f "$SOURCE_FILE" ]; then
    TEMPLATE_URL="$(grep -E '^[^#[:space:]]' "$SOURCE_FILE" | head -1 || true)"
fi
TEMPLATE_URL="${TEMPLATE_URL:-https://github.com/BejanSadeghian/template_claude_code.git}"

echo "── template status ──────────────────────────────────"
echo "  version (this repo):  $CURRENT_VERSION"

ORIGIN_URL="$(git config --get remote.origin.url 2>/dev/null || true)"
IS_TEMPLATE=0
if [ "$ORIGIN_URL" = "$TEMPLATE_URL" ] || [ "${ORIGIN_URL%.git}" = "${TEMPLATE_URL%.git}" ]; then
    IS_TEMPLATE=1
fi

if [ "$IS_TEMPLATE" = "1" ]; then
    echo "  upstream:             (this IS the template repo)"
else
    # Make sure the template remote exists / points at the right URL.
    if ! git remote get-url "$TEMPLATE_REMOTE" >/dev/null 2>&1; then
        git remote add "$TEMPLATE_REMOTE" "$TEMPLATE_URL" 2>/dev/null || true
    else
        CUR="$(git remote get-url "$TEMPLATE_REMOTE" 2>/dev/null || true)"
        [ "$CUR" = "$TEMPLATE_URL" ] || git remote set-url "$TEMPLATE_REMOTE" "$TEMPLATE_URL" 2>/dev/null || true
    fi

    if git fetch --quiet "$TEMPLATE_REMOTE" "$TEMPLATE_BRANCH" 2>/dev/null; then
        UP_VERSION="$(git show "$TEMPLATE_REMOTE/$TEMPLATE_BRANCH:VERSION" 2>/dev/null | tr -d ' \n' || echo '?')"
        echo "  version (upstream):   $UP_VERSION"

        # Which template-owned paths exist upstream and actually differ?
        EXISTING=()
        for p in "${PATHS[@]}"; do
            git cat-file -e "$TEMPLATE_REMOTE/$TEMPLATE_BRANCH:$p" 2>/dev/null && EXISTING+=("$p")
        done
        DIFF_FILES=""
        [ "${#EXISTING[@]}" -gt 0 ] && \
            DIFF_FILES="$(git diff --name-only HEAD "$TEMPLATE_REMOTE/$TEMPLATE_BRANCH" -- "${EXISTING[@]}" 2>/dev/null || true)"
        NUM_FILES="$( [ -n "$DIFF_FILES" ] && printf '%s\n' "$DIFF_FILES" | wc -l | tr -d ' ' || echo 0 )"

        echo
        if [ "$NUM_FILES" -eq 0 ]; then
            echo "  ✓ up to date with the template."
        else
            newer=""
            if [ "$CURRENT_VERSION" != "?" ] && [ "$UP_VERSION" != "?" ] && [ "$CURRENT_VERSION" != "$UP_VERSION" ]; then
                top="$(printf '%s\n%s\n' "$CURRENT_VERSION" "$UP_VERSION" | sort -V | tail -1)"
                [ "$top" = "$UP_VERSION" ] && newer=" (behind: $CURRENT_VERSION → $UP_VERSION)"
            fi
            echo "  ⚠ $NUM_FILES template-owned file(s) differ from upstream$newer"
            echo "    run:  template-update     # review + apply template changes"
        fi
    else
        echo "  upstream:             (offline — could not reach $TEMPLATE_URL)"
    fi
fi

cat <<'EOF'

  commands:
    setup             configure this project (app type, git, CI, deploy, auth)
    module            list / add / remove opt-in modules
    template-status   show this panel (version + behind check)
    template-update   pull the latest template changes (interactive)
    update            update the CLIs (Claude Code, Railway, Azure)

  full guide: docs/TEMPLATE.md
──────────────────────────────────────────────────────
EOF
