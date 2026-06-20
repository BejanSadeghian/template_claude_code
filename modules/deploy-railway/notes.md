Railway deploy installed. Next:
- GitHub → Settings: add secret RAILWAY_TOKEN and variable APP_URL.
- `railway login` (auth-bootstrap handles this) then `railway link` to your project.
- Edit scripts/verify-deploy.sh (APP_URL / health checks) for your service.
