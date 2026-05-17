# 0014 — de-railway-stub-soft-spec-template-url

- **Status**: done
- **Owner**: bejan
- **Created**: 2026-05-17
- **Last updated**: 2026-05-17

## Original prompt

> ok with all of your notes to be honest. go ahead and do all of it.
> if detailway you mean a stub that does default to dailway but can be edited by any other user then yes. and yes to the rest

## Goal

Make the template usable by people who don't deploy to Railway, don't want the spec workflow, or fork the template into their own — without removing the helpful defaults.

## Scope

- In:
  - Mark `scripts/verify-deploy.sh` Railway block as the replaceable default; add a header explaining how to swap providers.
  - Add "default example — replace for your provider" callouts to `docs/runbook/RECREATE.md`, `SERVICES.md`, `INCIDENTS.md`.
  - Add README section "Don't want the spec workflow?" with deletion recipe.
  - Add README section "Provider-coupled bits" pointing to the Railway defaults.
  - Add `.template-source` file with the upstream URL; teach `scripts/template-sync.sh` to read it (env > file > hardcoded fallback).
  - Update README first-time setup wording: user authenticates own providers; mention `.template-source` edit on fork; remove stale setup-hooks line.
- Out:
  - Deleting Railway code paths.
  - Adding Fly / Render / Vercel concrete examples (out of scope; left as a future spec).

## Acceptance criteria

- [x] AC1: `scripts/verify-deploy.sh` header documents Railway as default and how to swap.
- [x] AC2: All three runbook files have a "default example — replace" callout in the first lines.
- [x] AC3: README has a "Don't want the spec workflow?" section with a one-liner removal recipe.
- [x] AC4: README has a "Provider-coupled bits" section.
- [x] AC5: `.template-source` exists with the upstream URL.
- [x] AC6: `scripts/template-sync.sh` resolves `TEMPLATE_URL` from env > `.template-source` > hardcoded fallback.
- [x] AC7: `bash scripts/template-sync.sh` still no-ops on the template repo itself (exit 0, no output).

## Risks / unknowns

- `.template-source` is *not* in the template-sync `PATHS` allowlist on purpose — child repos that change it should keep that change across template syncs.

## Build log

- 2026-05-17 — Added stub-style provider markers across runbook and verify-deploy.sh.
- 2026-05-17 — Added soft-launch and provider-coupled sections to README.
- 2026-05-17 — Introduced `.template-source` and taught template-sync.sh to read it.
- 2026-05-17 — Smoke test: `template-sync.sh` exit 0 with no output on the template repo (AC7).
