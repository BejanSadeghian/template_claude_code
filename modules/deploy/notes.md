Staged deploy installed. One-time setup:
- Create the environments + approval gates: `bash scripts/setup-environments.sh <your-github-username>`
  (creates dev/staging/production; staging+prod require your approval before deploying).
- Per-environment config (repo Settings → Environments → each env):
    variable APP_URL = that environment's URL
    secret RAILWAY_TOKEN  (and/or AZURE_CREDENTIALS)
- Set the target in claude/project.md → Deployment → `targets: railway` (or `azure`, or `railway,azure`).
- Edit scripts/deploy.sh for your service names (RAILWAY_SERVICE / AZURE_WEBAPP_NAME).
- semantic-release needs conventional commits; it tags + creates a GitHub Release on each push to main.
