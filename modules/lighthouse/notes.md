Lighthouse installed.
- Set the repo variable APP_URL (or pass a URL via workflow_dispatch).
- Thresholds live in lighthouserc.json (currently "warn" — change to "error" to gate).
- Reports upload as artifacts + temporary public storage; switch to an LHCI server for private history.
