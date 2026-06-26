#!/usr/bin/env bash
# Bootstrap the per-repo GitHub Project board for feature tracking.
# Creates (or finds) a Project named after this repo, ensures the `feature`
# label, captures the board IDs into claude/project.md.
#
# Requires: gh CLI authenticated with the `project` scope
#   (auth-bootstrap requests it; otherwise `gh auth refresh -s project`).
set -euo pipefail

command -v gh >/dev/null 2>&1 || { echo "gh CLI required (run inside the devcontainer)"; exit 1; }
cd "$(git rev-parse --show-toplevel)"

NAME="$(gh repo view --json name -q .name)"
OWNER="$(gh repo view --json owner -q .owner.login)"
echo "repo: $OWNER/$NAME"

# 1. `feature` label (no-op if present)
gh label create feature --color 1f883d --description "Tracked feature" 2>/dev/null \
  && echo "created label 'feature'" || echo "label 'feature' already exists"

# 2. find or create the Project (title == repo name)
NUM="$(gh project list --owner "$OWNER" --format json \
  | python3 -c "import sys,json;ps=json.load(sys.stdin).get('projects',[]);print(next((str(p['number']) for p in ps if p['title']=='$NAME'),''))")"
if [ -z "$NUM" ]; then
  echo "creating project '$NAME'…"
  NUM="$(gh project create --owner "$OWNER" --title "$NAME" --format json \
    | python3 -c 'import sys,json;print(json.load(sys.stdin)["number"])')"
fi
PID="$(gh project view "$NUM" --owner "$OWNER" --format json -q .id)"
echo "project #$NUM  id=$PID"

# 3. Status field id + the four lane option ids (matched by name)
mapfile -t L < <(gh project field-list "$NUM" --owner "$OWNER" --format json | python3 - <<'PY'
import sys, json
fields = json.load(sys.stdin).get("fields", [])
st = next((f for f in fields if f.get("name") == "Status"), None)
def opt(name):
    return next((o["id"] for o in (st.get("options", []) if st else []) if o["name"].lower() == name.lower()), "")
print(st["id"] if st else "")
for n in ("Presented", "Active", "Verify", "Closed"):
    print(opt(n))
PY
)
SFID="${L[0]:-}"; PRESENTED="${L[1]:-}"; ACTIVE="${L[2]:-}"; VERIFY="${L[3]:-}"; CLOSED="${L[4]:-}"
echo "status-field=$SFID  Presented=$PRESENTED Active=$ACTIVE Verify=$VERIFY Closed=$CLOSED"

if [ -z "${PRESENTED}${ACTIVE}${VERIFY}${CLOSED}" ]; then
  cat <<'MSG'
⚠ The Status field has no Presented/Active/Verify/Closed lanes yet.
  In the Project → Settings → Status, set the single-select options to exactly:
  Presented, Active, Verify, Closed — then re-run this script to capture their ids.
MSG
fi

# 4. persist into claude/project.md
PF="claude/project.md"
sed -i \
  -e "s|^- board:.*|- board: $NAME|" \
  -e "s|^- project-id:.*|- project-id: $PID|" \
  -e "s|^- status-field-id:.*|- status-field-id: $SFID|" \
  -e "s|^- option Presented:.*|- option Presented: $PRESENTED|" \
  -e "s|^- option Active:.*|- option Active: $ACTIVE|" \
  -e "s|^- option Verify:.*|- option Verify: $VERIFY|" \
  -e "s|^- option Closed:.*|- option Closed: $CLOSED|" \
  "$PF"
echo "wrote board IDs into $PF — set '- owner:' to your GitHub username, then commit."
