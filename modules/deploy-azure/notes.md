Azure deploy installed. Next:
- Create the target Azure Web App.
- GitHub → Settings: add secret AZURE_CREDENTIALS (service principal JSON) or configure OIDC.
- Set repo variables AZURE_WEBAPP_NAME and APP_URL.
- Edit .github/workflows/deploy-azure.yml for your app name / runtime.
