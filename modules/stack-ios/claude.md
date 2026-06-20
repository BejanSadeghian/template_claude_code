# Stack: iOS + web API

Full stack guide: `claude/CLAUDE.ios-webapi.md`.

## Definition of done (iOS)
Not done until all pass — verify, don't assume:
- App builds for the simulator; `scripts/ios-test.sh` passes.
- Unit + UI tests green.
- API contract tests pass (if a web API backs the app).
- `pre-commit` + `pre-push` hooks clean; pushed.

## Testing
- New screen/flow → new UI test. New API endpoint → new contract test.
