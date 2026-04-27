# /verify — run the full local gate

Do not skip steps. Show output tails on failure.

| Gate | Command |
|---|---|
| Lint | `pnpm lint` |
| Typecheck | `pnpm typecheck` |
| Unit | `pnpm test` |
| API | `pnpm test:api` |
| E2E (webapp) | `pnpm test:e2e` |
| iOS (if present) | `scripts/ios-test.sh` |
| Hooks dry-run | `pre-commit run --all-files` (Python) or `pnpm lint-staged --diff HEAD` |

If `--quick` arg is passed, skip E2E + iOS. Otherwise run everything.
