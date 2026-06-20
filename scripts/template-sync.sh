#!/bin/bash
# Interactive template-update sync.
# Invoked from .devcontainer/post-create.sh on container start (TTY only).
# Can also be run manually: `bash scripts/template-sync.sh`.
set -euo pipefail

TEMPLATE_REMOTE="${TEMPLATE_REMOTE:-template}"
TEMPLATE_BRANCH="${TEMPLATE_BRANCH:-main}"
IGNORE_FILE=".template-sync-ignore"
SOURCE_FILE=".template-source"

# Resolve TEMPLATE_URL precedence:
#   1. Env var TEMPLATE_URL (explicit override)
#   2. First non-comment URL line in .template-source
#   3. Hardcoded fallback (this repo's canonical upstream)
if [ -z "${TEMPLATE_URL:-}" ] && [ -f "$SOURCE_FILE" ]; then
    TEMPLATE_URL="$(grep -E '^[^#[:space:]]' "$SOURCE_FILE" | head -1 || true)"
fi
TEMPLATE_URL="${TEMPLATE_URL:-https://github.com/BejanSadeghian/template_claude_code.git}"

# Template-owned paths. Anything outside this list is never touched.
PATHS=(
    .devcontainer
    .github
    claude
    scripts/template-sync.sh
    scripts/template-status.sh
    scripts/setup-hooks.sh
    scripts/verify-deploy.sh
    scripts/bump-version.sh
    scripts/update.sh
    scripts/auth-bootstrap.sh
    scripts/shared-claude.sh
    .vscode/tasks.json
    hooks/pre-commit
    hooks/pre-push
    docs/runbook
    docs/TEMPLATE.md
    CLAUDE.md
)

cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

# If this *is* the template repo itself, nothing to do.
ORIGIN_URL="$(git config --get remote.origin.url 2>/dev/null || true)"
if [ "$ORIGIN_URL" = "$TEMPLATE_URL" ] || [ "${ORIGIN_URL%.git}" = "${TEMPLATE_URL%.git}" ]; then
    exit 0
fi

# Ensure template remote exists and points at the right URL.
if ! git remote get-url "$TEMPLATE_REMOTE" >/dev/null 2>&1; then
    git remote add "$TEMPLATE_REMOTE" "$TEMPLATE_URL"
else
    CURRENT="$(git remote get-url "$TEMPLATE_REMOTE")"
    [ "$CURRENT" = "$TEMPLATE_URL" ] || git remote set-url "$TEMPLATE_REMOTE" "$TEMPLATE_URL"
fi

git fetch --quiet "$TEMPLATE_REMOTE" "$TEMPLATE_BRANCH" 2>/dev/null || {
    # Offline / no access — silent skip.
    exit 0
}

TEMPLATE_SHA="$(git rev-parse "$TEMPLATE_REMOTE/$TEMPLATE_BRANCH")"

# Check ignore list.
if [ -f "$IGNORE_FILE" ] && grep -qx "$TEMPLATE_SHA" "$IGNORE_FILE"; then
    exit 0
fi

# Filter paths to those that actually exist on the template side.
EXISTING_PATHS=()
for p in "${PATHS[@]}"; do
    if git cat-file -e "$TEMPLATE_REMOTE/$TEMPLATE_BRANCH:$p" 2>/dev/null; then
        EXISTING_PATHS+=("$p")
    fi
done
[ "${#EXISTING_PATHS[@]}" -eq 0 ] && exit 0

# Any diff for template-owned paths between HEAD and template tip?
DIFF_FILES="$(git diff --name-only HEAD "$TEMPLATE_REMOTE/$TEMPLATE_BRANCH" -- "${EXISTING_PATHS[@]}" 2>/dev/null || true)"
if [ -z "$DIFF_FILES" ]; then
    exit 0
fi

# Bail if working tree is dirty in any of those paths — too risky to auto-stage.
if ! git diff --quiet -- "${EXISTING_PATHS[@]}" 2>/dev/null || \
   ! git diff --cached --quiet -- "${EXISTING_PATHS[@]}" 2>/dev/null; then
    echo "── template updates available but skipping: uncommitted changes in template-owned paths ──"
    exit 0
fi

# Need a TTY for prompts.
if [ ! -t 0 ] || [ ! -t 1 ]; then
    echo "── template updates available (run scripts/template-sync.sh in a terminal) ──"
    echo "$DIFF_FILES" | sed 's/^/  /'
    exit 0
fi

NUM_COMMITS="$(git rev-list --count HEAD.."$TEMPLATE_REMOTE/$TEMPLATE_BRANCH" -- "${EXISTING_PATHS[@]}" 2>/dev/null || echo 0)"
NUM_FILES="$(echo "$DIFF_FILES" | wc -l | tr -d ' ')"

cat <<EOF

── template updates ────────────────────────────────
$NUM_COMMITS commits on $TEMPLATE_REMOTE/$TEMPLATE_BRANCH touch $NUM_FILES template-owned file(s):
EOF
git diff --stat HEAD "$TEMPLATE_REMOTE/$TEMPLATE_BRANCH" -- "${EXISTING_PATHS[@]}" | sed 's/^/  /'
echo "────────────────────────────────────────────────────"

prompt() {
    local q="$1" reply
    read -r -p "$q " reply </dev/tty
    echo "${reply:-}"
}

VIEW="$(prompt 'View full diff? [y/N/q]')"
case "$VIEW" in
    q|Q) exit 0 ;;
    y|Y) git --no-pager diff HEAD "$TEMPLATE_REMOTE/$TEMPLATE_BRANCH" -- "${EXISTING_PATHS[@]}" | ${PAGER:-less -R} ;;
esac

while true; do
    ACTION="$(prompt '[a]ccept / [r]eject / [d]efer / [s]kip-this-version ?')"
    case "$ACTION" in
        a|A)
            git checkout "$TEMPLATE_REMOTE/$TEMPLATE_BRANCH" -- "${EXISTING_PATHS[@]}"
            # Drop any paths that no longer exist upstream
            for p in "${EXISTING_PATHS[@]}"; do
                if ! git cat-file -e "$TEMPLATE_REMOTE/$TEMPLATE_BRANCH:$p" 2>/dev/null; then
                    git rm -r --ignore-unmatch "$p" >/dev/null 2>&1 || true
                fi
            done
            git add -- "${EXISTING_PATHS[@]}" 2>/dev/null || true
            if git diff --cached --quiet; then
                echo "Nothing to commit after merge (already in sync)."
                exit 0
            fi
            SHORT="${TEMPLATE_SHA:0:7}"
            git commit -m "chore: sync template $SHORT

Template-owned paths fast-forwarded from $TEMPLATE_REMOTE/$TEMPLATE_BRANCH @ $TEMPLATE_SHA.
Review the diff and push when ready."
            echo
            echo "Committed locally. Inspect with: git show HEAD"
            echo "Push when ready:               git push"
            exit 0
            ;;
        r|R)
            echo "$TEMPLATE_SHA" >> "$IGNORE_FILE"
            sort -u -o "$IGNORE_FILE" "$IGNORE_FILE"
            echo "Recorded $TEMPLATE_SHA in $IGNORE_FILE — will not re-prompt for this sha."
            echo "Tip: commit $IGNORE_FILE so the rejection sticks across clones."
            exit 0
            ;;
        s|S)
            echo "$TEMPLATE_SHA" >> "$IGNORE_FILE"
            sort -u -o "$IGNORE_FILE" "$IGNORE_FILE"
            echo "Skipped $TEMPLATE_SHA only. New template commits will still prompt."
            exit 0
            ;;
        d|D|"")
            echo "Deferred. Will re-prompt next container start."
            exit 0
            ;;
        *)
            echo "Unknown choice: $ACTION"
            ;;
    esac
done
