# Modules

Opt-in building blocks. Nothing here is active until you add it. Use the `module`
command (alias for `bash scripts/module.sh`) or run the `setup` wizard.

```
module list                 # show modules + whether each is installed
module add deploy-railway   # copy a module's files into the repo
module remove deploy-azure  # remove the files a module added
```

## Available

| Module | What it adds |
|---|---|
| `stack-web` | Node/TS CI (lint/typecheck/test/build + preflight) + hosted Playwright E2E, web stack guide, web definition-of-done. |
| `stack-ios` | Xcode CI workflow, the iOS stack guide, iOS definition-of-done rules. |
| `deploy` | **Staged CD** (recommended): release (semantic-release) → dev auto → staging approval → prod approval. Provider-agnostic (`scripts/deploy.sh` → railway/azure), `setup-environments.sh` for the approval gates. |
| `deploy-railway` | Simple single-environment Railway deploy (`railway up` + smoke). Use `deploy` for the staged pipeline. |
| `deploy-azure` | Simple single-environment Azure Web App deploy. Use `deploy` for the staged pipeline. |
| `storybook` | Build Storybook on every push, optional Railway deploy; living UI reference to mark up on. |
| `agentic-e2e` | AI user-journey testing of the deployed app: scripted Playwright + a Claude vision judge (`qa/journeys.json`). |
| `compliance` | License check that fails on GPL/AGPL/SSPL, notices LGPL (push/PR + weekly). |
| `lighthouse` | Weekly Lighthouse performance/a11y/SEO audit of the deployed URL. |
| `claude-action` | `anthropics/claude-code-action` on `@claude` mentions in issues/PRs. |

## Anatomy of a module

```
modules/<name>/
  about            # one-line description (shown by `module list`)
  files/           # mirrored into the repo root on `add` (paths preserved)
  claude.md        # optional: copied to claude/modules/<name>.md so Claude follows its rules
  notes.md         # optional: printed after `add` (manual follow-ups)
```

`module remove` deletes exactly the files the module's `files/` tree maps to, plus
`claude/modules/<name>.md`. Your own edits to other files are never touched.
