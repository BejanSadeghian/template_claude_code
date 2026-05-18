#!/usr/bin/env bash
# Mirror docs/specs/NNNN-<slug>.md to GitHub issues + the "Specs" Project v2.
# Local-only: runs under your `gh auth`. Spec file is source of truth.
# Skip with SKIP_SPEC_SYNC=1.
set -euo pipefail

[ "${SKIP_SPEC_SYNC:-}" = "1" ] && { echo "spec-sync: skipped (SKIP_SPEC_SYNC=1)"; exit 0; }

PROJECT_TITLE="${PROJECT_TITLE:-Specs}"
SPECS_DIR="docs/specs"

# --- preflight ---
command -v gh >/dev/null || { echo "spec-sync: gh not installed; skipping" >&2; exit 0; }
command -v jq >/dev/null || { echo "spec-sync: jq not installed; skipping" >&2; exit 0; }
[ -d "$SPECS_DIR" ] || { echo "spec-sync: no $SPECS_DIR; skipping"; exit 0; }
gh auth status >/dev/null 2>&1 || { echo "spec-sync: gh not authed; skipping" >&2; exit 0; }
if ! gh auth status 2>&1 | grep -qi 'project'; then
  echo "spec-sync: token missing 'project' scope. Run: gh auth refresh -s project" >&2
  exit 0
fi

OWNER="$(gh repo view --json owner -q .owner.login 2>/dev/null || true)"
REPO="$(gh repo view --json name -q .name 2>/dev/null || true)"
[ -n "$OWNER" ] && [ -n "$REPO" ] || { echo "spec-sync: not a GitHub repo; skipping"; exit 0; }
NWO="$OWNER/$REPO"

# Resolve project
PROJ_JSON="$(gh project list --owner "$OWNER" --format json --limit 200)"
PROJECT_NUMBER="$(jq -r --arg t "$PROJECT_TITLE" '.projects[] | select(.title==$t) | .number' <<<"$PROJ_JSON" | head -1)"
PROJECT_ID="$(jq -r --arg t "$PROJECT_TITLE" '.projects[] | select(.title==$t) | .id' <<<"$PROJ_JSON" | head -1)"
if [ -z "$PROJECT_NUMBER" ]; then
  echo "spec-sync: project '$PROJECT_TITLE' not found. Run scripts/setup-github-project.sh first." >&2
  exit 0
fi

# Resolve Status field + option IDs
FIELDS_JSON="$(gh project field-list "$PROJECT_NUMBER" --owner "$OWNER" --format json --limit 50)"
STATUS_FIELD_ID="$(jq -r '.fields[] | select(.name=="Status") | .id' <<<"$FIELDS_JSON" | head -1)"
declare -A OPT_ID
while IFS=$'\t' read -r name id; do
  [ -n "$name" ] && OPT_ID["$name"]="$id"
done < <(jq -r '.fields[] | select(.name=="Status") | .options[]? | [.name,.id] | @tsv' <<<"$FIELDS_JSON")

# Cache: existing spec-labelled issues (open + closed)
ISSUES_JSON="$(gh issue list --label spec --state all --limit 500 --json number,title,body,state)"

upsert_spec() {
  local file="$1"
  local base nnnn slug status title issue_num issue_body issue_state issue_url item_id opt_id
  base="$(basename "$file" .md)"
  nnnn="${base%%-*}"
  slug="${base#*-}"
  status="$(grep -E '^\- \*\*Status\*\*:' "$file" | head -1 | sed -E 's/.*: *//; s/[[:space:]]+$//' | awk '{print $1}')"
  case "$status" in draft|in-progress|done|abandoned) ;; *) status="draft" ;; esac
  title="$nnnn — $slug"

  # Match by marker in body
  issue_num="$(jq -r --arg m "<!-- spec:$nnnn -->" '.[] | select(.body|tostring|contains($m)) | .number' <<<"$ISSUES_JSON" | head -1)"

  if [ -z "$issue_num" ]; then
    issue_body="Spec: [\`$SPECS_DIR/$base.md\`](../blob/main/$SPECS_DIR/$base.md)

<!-- spec:$nnnn -->"
    issue_url="$(gh issue create --title "$title" --body "$issue_body" --label spec --json url -q .url 2>/dev/null \
      || gh issue create --title "$title" --body "$issue_body" --label spec)"
    issue_num="$(grep -oE '/issues/[0-9]+' <<<"$issue_url" | grep -oE '[0-9]+' | tail -1)"
    echo "  + #$issue_num created — $title"
    issue_state="OPEN"
  else
    # Ensure title is current (slug renames)
    current_title="$(jq -r --argjson n "$issue_num" '.[] | select(.number==$n) | .title' <<<"$ISSUES_JSON")"
    if [ "$current_title" != "$title" ]; then
      gh issue edit "$issue_num" --title "$title" >/dev/null
      echo "  ~ #$issue_num retitled — $title"
    fi
    issue_state="$(jq -r --argjson n "$issue_num" '.[] | select(.number==$n) | .state' <<<"$ISSUES_JSON")"
    issue_url="https://github.com/$NWO/issues/$issue_num"
  fi

  # Close / reopen based on status
  case "$status" in
    done|abandoned)
      [ "$issue_state" != "CLOSED" ] && gh issue close "$issue_num" >/dev/null && echo "  ✓ #$issue_num closed ($status)"
      ;;
    *)
      [ "$issue_state" = "CLOSED" ] && gh issue reopen "$issue_num" >/dev/null && echo "  ↻ #$issue_num reopened ($status)"
      ;;
  esac

  # Add to project, get item id
  item_id="$(gh project item-add "$PROJECT_NUMBER" --owner "$OWNER" --url "$issue_url" --format json 2>/dev/null | jq -r .id || true)"
  if [ -z "$item_id" ] || [ "$item_id" = "null" ]; then
    # Already in project — look it up
    item_id="$(gh project item-list "$PROJECT_NUMBER" --owner "$OWNER" --limit 500 --format json \
      | jq -r --argjson n "$issue_num" '.items[] | select(.content.number==$n) | .id' | head -1)"
  fi

  # Set Status field
  opt_id="${OPT_ID[$status]:-}"
  if [ -n "$item_id" ] && [ -n "$STATUS_FIELD_ID" ] && [ -n "$opt_id" ]; then
    gh project item-edit --id "$item_id" --field-id "$STATUS_FIELD_ID" \
      --single-select-option-id "$opt_id" --project-id "$PROJECT_ID" >/dev/null
  fi
}

shopt -s nullglob
specs=("$SPECS_DIR"/[0-9][0-9][0-9][0-9]-*.md)
echo "spec-sync: $NWO  project=$PROJECT_TITLE  specs=${#specs[@]}"
for f in "${specs[@]}"; do
  upsert_spec "$f"
done
echo "spec-sync: done"
