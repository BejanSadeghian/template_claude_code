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

echo "Auth login:   1) web/browser (no password)   2) username/password"
case "$(ask 'choose [1]:' 1)" in 2|password) AUTH=password;; *) AUTH=web;; esac

mkdir -p claude
cat > claude/project.md <<EOF
# Project profile

Claude reads this and follows it. Regenerate with \`setup\`.

- App type: $APP        # web | ios
- Git workflow: $GW     # main | branch-pr
- CI: $CI               # on | off
- Deploy: $DEPLOY       # none | railway | azure (comma-separated)
- Auth: $AUTH           # web | password
EOF
echo "wrote claude/project.md"

bash scripts/module.sh add "stack-$APP" || true
if [ "$CI" = "off" ]; then
    rm -rf .github/workflows 2>/dev/null || true
    echo "CI disabled — removed .github/workflows"
fi
if [ -n "$DEPLOY" ] && [ "$DEPLOY" != "none" ]; then
    OLD_IFS="$IFS"; IFS=','
    for d in $DEPLOY; do [ -n "$d" ] && bash scripts/module.sh add "deploy-$d"; done
    IFS="$OLD_IFS"
fi

echo "─────────────────────────────────────────────────────"
echo "Done."
echo "  • Optional extras: module add agentic-e2e compliance lighthouse claude-action"
echo "  • Edit claude/preferences.md for always-follow custom rules (e.g. where todos live)."
echo "  • Auth mode '$AUTH' applies next container start (or run: bash scripts/auth-bootstrap.sh)."
echo "  • Review changes, then commit."
