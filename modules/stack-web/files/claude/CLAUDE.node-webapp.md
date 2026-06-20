# Node / TS webapp rules

## Toolchain (assume unless project says otherwise)
- Runtime: Node 22, pnpm
- Lint: ESLint flat config + Prettier
- Typecheck: `tsc --noEmit`
- Unit: Vitest
- API tests: Vitest + supertest (or msw for mocked clients)
- E2E / UI: Playwright

## Required scripts in `package.json`
```
"scripts": {
  "dev": "...",
  "build": "...",
  "lint": "eslint .",
  "lint:fix": "eslint . --fix",
  "typecheck": "tsc --noEmit",
  "test": "vitest run",
  "test:watch": "vitest",
  "test:api": "vitest run --dir tests/api",
  "test:e2e": "playwright test",
  "test:e2e:ui": "playwright test --ui",
  "verify": "pnpm lint && pnpm typecheck && pnpm test && pnpm test:api"
}
```

## Test layout
- `src/**/*.test.ts` — colocated unit tests
- `tests/api/**/*.test.ts` — HTTP/API contract tests, hit the actual route handler
- `tests/e2e/**/*.spec.ts` — Playwright UI tests

## API testing rules
- Every route gets >= 1 happy-path + 1 auth/validation failure test.
- Use a real test DB (sqlite or ephemeral postgres via Railway preview) — not mocks.
- Snapshot the OpenAPI schema in `tests/api/openapi.snapshot.json`; fail if it drifts unexpectedly.

## E2E rules
- One spec per critical user journey (signup, primary flow, payment if applicable).
- Run against `pnpm dev` started by the Playwright `webServer` config.
- Capture trace + video on failure (`use: { trace: 'on-first-retry', video: 'retain-on-failure' }`).

## Deploy verification
- `scripts/verify-deploy.sh <env>` — hits `/healthz` + runs a smoke Playwright project tagged `@smoke`.
- Default `<env>` to `production`. Staging URL lives in `.env.example`.
