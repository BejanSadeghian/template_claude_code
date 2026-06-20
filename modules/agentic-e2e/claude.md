# Agentic E2E (AI user journeys)

Instead of clicking through the app by hand, this runs user journeys against the
**deployed** app and has Claude judge whether each succeeded.

- Journeys live in `qa/journeys.json`: each has `name`, `goto` (path), `steps`
  (deterministic Playwright ops), and `expect` (natural-language acceptance criteria).
- `scripts/agentic-e2e.mjs` drives the steps, screenshots the end state, and asks
  Claude (vision) for a `{pass, reason}` verdict. Exit 1 if any journey fails.
- Step ops: `goto:/path`, `click:Visible text`, `fill:#selector=value`, `wait:1000`, `press:Enter`.
- **When adding a feature, add or update a journey in `qa/journeys.json`** so the AI covers it.
- Keep navigation scripted (cheap, low-flake); the LLM only judges the end state.
- Run locally: `E2E_BASE_URL=https://your-app node scripts/agentic-e2e.mjs` (needs `ANTHROPIC_API_KEY`).
- To author/heal journeys interactively, add the Playwright MCP server (`npx @playwright/mcp`) to Claude Code.
