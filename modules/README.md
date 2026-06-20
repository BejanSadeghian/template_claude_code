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
| `stack-web` | Node/TS CI + Playwright E2E workflows, the web stack guide, web definition-of-done rules. |
| `stack-ios` | Xcode CI workflow, the iOS stack guide, iOS definition-of-done rules. |
| `deploy-railway` | Railway deploy-verify workflow, `verify-deploy.sh`, runbook. |
| `deploy-azure` | Azure Web App deploy workflow, `verify-deploy.sh`. |

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
