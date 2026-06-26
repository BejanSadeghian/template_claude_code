#!/usr/bin/env bash
# First-time project setup wizard. Writes claude/project.md (the profile Claude
# follows) and installs the matching modules. Re-run any time with `setup`.
set -u
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

if [ ! -t 0 ] || [ ! -t 1 ]; then
    echo "Run 'setup' in an interactive terminal to configure this project."
    exit 0
fi

ask() { local q="$1" def="$2" reply; read -r -p "$q " reply </dev/tty; echo "${reply:-$def}"; }

echo "── project setup ────────────────────────────────────"

echo "App type:   1) web   2) ios"
case "$(ask 'choose [1]:' 1)" in 2|ios) APP=ios;; *) APP=web;; esac

echo "Git workflow:   1) commit straight to main (no PR)   2) feature branch + PR"
case "$(ask 'choose [1]:' 1)" in 2|branch*|pr) GW=branch-pr;; *) GW=main;; esac

case "$(ask 'Enable CI workflows? [Y/n]:' Y)" in n|N|no) CI=off;; *) CI=on;; esac

echo "Deploy target(s):   none | railway | azure   (comma-separate for multiple)"
DEPLOY="$(ask 'choose [none]:' none | tr -d ' ')"

case "$(ask 'Deploy Storybook to Railway? [y/N]:' N)" in y|Y|yes) SB=railway;; *) SB=off;; esac

echo "Auth login:   1) web/browser (no password)   2) username/password"
case "$(ask 'choose [1]:' 1)" in 2|password) AUTH=password;; *) AUTH=web;; esac

OWNER="$(gh repo view --json owner -q .owner.login 2>/dev/null || echo '')"

mkdir -p claude
cat > claude/project.md <<EOF
# Project profile

Claude reads this and follows it. Regenerate with \`setup\`.

- App type: $APP        # web | ios
- Git workflow: $GW     # main | branch-pr
- CI: $CI               # on | off
- Deploy: $DEPLOY       # none | railway | azure (comma-separated)
- Auth: $AUTH           # web | password

## Feature board (GitHub Project)

Bootstrap/refresh with \`bash scripts/feature-board.sh\` (needs the gh \`project\` scope).

- owner: $OWNER
- board:            # Project named after this repo (filled by feature-board.sh)
- project-id:       # PVT_...
- status-field-id:  # PVTSSF_...
- option Presented: #
- option Active:    #
- option Verify:    #
- option Closed:    #

## Deployment (staged)

- stages: dev → staging → prod
- dev: auto on push to \`main\`
- staging: manual approval (GitHub Environment required reviewers)
- prod: manual approval
- versioning: semantic-release (conventional commits → vX.Y.Z); staging & prod tag a release
- targets: $DEPLOY        # none | railway | azure | railway,azure
- storybook: $SB         # off | railway — if on, keep in sync with every UI change
EOF
echo "wrote claude/project.md"

bash scripts/module.sh add "stack-$APP" || true
if [ "$CI" = "off" ]; then
    rm -rf .github/workflows 2>/dev/null || true
    echo "CI disabled — removed .github/workflows"
fi
if [ -n "$DEPLOY" ] && [ "$DEPLOY" != "none" ]; then
    bash scripts/module.sh add deploy || true   # staged dev→staging→prod pipeline
fi
[ "$SB" = "railway" ] && bash scripts/module.sh add storybook

echo "─────────────────────────────────────────────────────"
echo "Done."
[ -n "$DEPLOY" ] && [ "$DEPLOY" != "none" ] && \
  echo "  • Deploy: run scripts/setup-environments.sh <you> to add staging/prod approval gates."
echo "  • Feature board: run feature-board to create the GitHub Project + capture its IDs."
echo "  • Optional extras: module add agentic-e2e compliance lighthouse claude-action"
echo "  • Edit claude/preferences.md for always-follow custom rules (e.g. where todos live)."
echo "  • Auth mode '$AUTH' applies next container start (or run: bash scripts/auth-bootstrap.sh)."
echo "  • Review changes, then commit."
