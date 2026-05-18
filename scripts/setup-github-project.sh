#!/usr/bin/env bash
# Idempotent bootstrap of the "Specs" GitHub Project v2 for the current repo.
# Requires: gh (authed with `project` scope), jq.
set -euo pipefail

PROJECT_TITLE="${PROJECT_TITLE:-Specs}"
STATUS_OPTIONS=(draft in-progress done abandoned)

err() { printf '%s\n' "$*" >&2; }
need() { command -v "$1" >/dev/null 2>&1 || { err "missing: $1"; exit 1; }; }

need gh
need jq

if ! gh auth status >/dev/null 2>&1; then
  err "gh is not authenticated. Run: gh auth login"
  exit 1
fi

# Confirm token has project scope (best-effort; gh auth status text includes scopes).
if ! gh auth status 2>&1 | grep -qi 'project'; then
  err "Your gh token is missing the 'project' scope."
  err "Run: gh auth refresh -s project"
  exit 1
fi

OWNER="$(gh repo view --json owner -q .owner.login)"
REPO="$(gh repo view --json name -q .name)"
NWO="$OWNER/$REPO"

echo "Repo: $NWO  Project: $PROJECT_TITLE"

# 1) Label
if ! gh label list --json name -q '.[].name' | grep -qx spec; then
  gh label create spec --color BFD4F2 --description "Mirrors docs/specs/NNNN-*.md" >/dev/null
  echo "  + label 'spec' created"
else
  echo "  = label 'spec' exists"
fi

# 2) Find or create project
PROJECT_JSON="$(gh project list --owner "$OWNER" --format json --limit 200)"
PROJECT_NUMBER="$(jq -r --arg t "$PROJECT_TITLE" '.projects[] | select(.title==$t) | .number' <<<"$PROJECT_JSON" | head -1)"
if [ -z "$PROJECT_NUMBER" ]; then
  CREATE_OUT="$(gh project create --owner "$OWNER" --title "$PROJECT_TITLE" --format json)"
  PROJECT_NUMBER="$(jq -r .number <<<"$CREATE_OUT")"
  echo "  + project #$PROJECT_NUMBER created"
else
  echo "  = project #$PROJECT_NUMBER exists"
fi

# 3) Link project to this repo (no-op if already linked)
gh project link "$PROJECT_NUMBER" --owner "$OWNER" --repo "$NWO" >/dev/null 2>&1 || true

# 4) Status field + options
FIELDS_JSON="$(gh project field-list "$PROJECT_NUMBER" --owner "$OWNER" --format json --limit 50)"
STATUS_FIELD_ID="$(jq -r '.fields[] | select(.name=="Status") | .id' <<<"$FIELDS_JSON" | head -1)"

if [ -z "$STATUS_FIELD_ID" ]; then
  # Create with all options at once.
  OPTS_CSV="$(IFS=,; echo "${STATUS_OPTIONS[*]}")"
  gh project field-create "$PROJECT_NUMBER" --owner "$OWNER" \
    --name Status --data-type SINGLE_SELECT \
    --single-select-options "$OPTS_CSV" >/dev/null
  echo "  + Status field created (${OPTS_CSV})"
else
  # Ensure each option exists. gh CLI cannot add options to an existing single-select
  # field today; warn the user if any are missing.
  EXISTING="$(jq -r '.fields[] | select(.name=="Status") | .options[]?.name' <<<"$FIELDS_JSON" | tr '\n' ' ')"
  MISSING=()
  for o in "${STATUS_OPTIONS[@]}"; do
    grep -qw "$o" <<<"$EXISTING" || MISSING+=("$o")
  done
  if [ ${#MISSING[@]} -gt 0 ]; then
    err "  ! Status field is missing options: ${MISSING[*]}"
    err "    Add them manually in the project UI (Settings → Status field), then re-run."
  else
    echo "  = Status field has all options"
  fi
fi

echo "Bootstrap complete. Run scripts/sync-specs-to-github.sh to backfill."
