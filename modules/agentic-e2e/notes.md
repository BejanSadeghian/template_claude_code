Agentic E2E installed. Next:
- Add repo secret ANTHROPIC_API_KEY and variable APP_URL (the deployed URL).
- Edit qa/journeys.json with your real user journeys.
- Runs nightly (07:30 UTC) and on demand (Actions → Agentic E2E → Run workflow, with an optional URL).
- Try locally: E2E_BASE_URL=https://your-app node scripts/agentic-e2e.mjs
- Optional: add Playwright MCP (`npx @playwright/mcp@latest`) to Claude Code to author journeys from natural language.
