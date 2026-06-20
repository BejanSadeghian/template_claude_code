# Stack: Web (Node/TS)

Full stack guide: `claude/CLAUDE.node-webapp.md`.

## Definition of done (web)
Not done until all pass — verify, don't assume:
- `pnpm lint && pnpm typecheck` → 0
- `pnpm test` → 0 failures, coverage not regressed
- `pnpm test:api` (integration / API)
- `pnpm test:e2e` (Playwright, if present)
- `pre-commit` + `pre-push` hooks clean
- pushed; commit visible on remote

## Testing
- New endpoint → new API test. New screen/page → new E2E test.
- Prefer real implementations; mock only at process boundaries (network, time, randomness, fs).
