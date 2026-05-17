#!/usr/bin/env bash
# Compute and apply a semver bump based on conventional commits since the
# last v* tag. Invoked from the pre-push hook (and runnable manually).
#
# Usage:
#   scripts/bump-version.sh              # auto from commits since last tag
#   scripts/bump-version.sh patch        # force patch
#   scripts/bump-version.sh minor        # force minor
#   scripts/bump-version.sh major        # force major
#   scripts/bump-version.sh --dry-run    # print what would happen, no writes
#
# Behavior:
#   - Reads current version from ./VERSION (no-op if file missing).
#   - Scans commits HEAD..<last-vTAG> (or all if no tag yet):
#       BREAKING CHANGE / type!:           -> major
#       feat:                              -> minor
#       fix|chore|docs|refactor|test|perf  -> patch
#       [skip version] in any commit msg   -> that commit ignored
#   - Highest applicable bump wins. No qualifying commits -> exit 0 (no bump).
#   - Writes new VERSION, commits "chore: release vX.Y.Z [skip version]",
#     creates annotated tag vX.Y.Z.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

VERSION_FILE="VERSION"
if [ ! -f "$VERSION_FILE" ]; then
    exit 0   # template-user opted out by deleting VERSION
fi

DRY=false
FORCE=""
case "${1:-}" in
    --dry-run) DRY=true ;;
    patch|minor|major) FORCE="$1" ;;
    "") ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
esac

CURRENT="$(tr -d '[:space:]' < "$VERSION_FILE")"
if ! echo "$CURRENT" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "VERSION file is not semver: $CURRENT" >&2
    exit 1
fi
IFS='.' read -r MAJ MIN PAT <<< "$CURRENT"

LAST_TAG="$(git tag --list 'v*' --sort=-v:refname | head -1 || true)"
if [ -n "$LAST_TAG" ]; then
    RANGE="$LAST_TAG..HEAD"
else
    RANGE="HEAD"
fi

# Subjects of qualifying commits (skip [skip version]).
SUBJECTS="$(git log --format='%s%n%b%n---END---' $RANGE 2>/dev/null | \
    awk 'BEGIN{RS="---END---\n"} !/\[skip version\]/' || true)"

if [ -z "$SUBJECTS" ] && [ -z "$FORCE" ]; then
    exit 0
fi

decide_bump() {
    if [ -n "$FORCE" ]; then echo "$FORCE"; return; fi
    if echo "$SUBJECTS" | grep -qE '(^|\n)(BREAKING CHANGE|[a-z]+(\(.+\))?!:)'; then
        echo major; return
    fi
    if echo "$SUBJECTS" | grep -qE '(^|\n)feat(\(.+\))?:'; then
        echo minor; return
    fi
    if echo "$SUBJECTS" | grep -qE '(^|\n)(fix|chore|docs|refactor|test|perf|style|build|ci)(\(.+\))?:'; then
        echo patch; return
    fi
    echo none
}

BUMP="$(decide_bump)"
if [ "$BUMP" = "none" ]; then
    exit 0
fi

case "$BUMP" in
    major) MAJ=$((MAJ+1)); MIN=0; PAT=0 ;;
    minor) MIN=$((MIN+1)); PAT=0 ;;
    patch) PAT=$((PAT+1)) ;;
esac
NEW="$MAJ.$MIN.$PAT"

echo "Version bump: $CURRENT -> $NEW ($BUMP)"
if $DRY; then exit 0; fi

# Refuse if the working tree is dirty in tracked files (besides VERSION).
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Working tree dirty — refusing to auto-bump. Commit or stash first." >&2
    exit 1
fi

echo "$NEW" > "$VERSION_FILE"
git add "$VERSION_FILE"
git commit -m "chore: release v$NEW [skip version]" >/dev/null
git tag -a "v$NEW" -m "v$NEW"
echo "Committed and tagged v$NEW. Push will include this commit + tag."
