# Deploy: Azure

- Deploy runs via `.github/workflows/deploy-azure.yml` on push to `main`.
- After a deploy, verify health with `scripts/verify-deploy.sh production` (exit 0).
- Auth: `az login` (device-code by default) locally; CI uses the `AZURE_CREDENTIALS` secret (service principal) or OIDC. Never commit creds.
