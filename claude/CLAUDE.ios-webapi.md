# iOS app + web API rules

This template assumes a **monorepo** with two surfaces:
- `api/` — Node/TS server deployed to Railway. See `claude/CLAUDE.node-webapp.md` for API rules.
- `ios/` — Swift / SwiftUI app, built with Xcode on macOS host (Linux devcontainer cannot build iOS).

## Working split
- The devcontainer handles `api/` work (lint, test, deploy).
- For `ios/` changes, claude can edit Swift sources, but build/test runs on the host via:
  - `xcodebuild -scheme App -destination 'platform=iOS Simulator,name=iPhone 16' test`
  - Wrap that in `scripts/ios-test.sh` so CI + local both call one entrypoint.

## API contract is the source of truth
- API exposes OpenAPI at `/openapi.json` in dev.
- iOS uses generated client from that schema: `swift-openapi-generator` invoked by `scripts/gen-ios-client.sh`.
- Any API change → regenerate iOS client → run iOS tests. Fail the spec's "done" check if the client is stale.

## iOS testing
- Unit tests: `XCTest` under `ios/AppTests/`
- UI tests: `XCUITest` under `ios/AppUITests/`
- Snapshot tests: `swift-snapshot-testing` for SwiftUI views
- Run all three before marking done:
  ```
  xcodebuild test -scheme App -destination 'platform=iOS Simulator,name=iPhone 16'
  ```

## API testing for iOS endpoints
- Every endpoint consumed by iOS gets a contract test that pins request + response shape.
- When iOS adds a screen that calls a new endpoint, the same commit adds the API test.

## CI shape
- `.github/workflows/ci.yml` runs API tests on `ubuntu-latest`.
- iOS workflow runs on `macos-latest` with caching of `~/Library/Developer/Xcode/DerivedData`.

## Deploy verification (combined)
- API: `scripts/verify-deploy.sh production` (Railway health + smoke).
- iOS: TestFlight upload via `fastlane beta`; verify build appears in App Store Connect API before "done".

## Secrets
- API secrets: Railway env (never committed).
- iOS signing: stored in `match` repo (private), credentials only on host + CI.
