# 0011 — version-and-license

- **Status**: done
- **Owner**: bejan
- **Created**: 2026-05-17
- **Last updated**: 2026-05-17

## Original prompt

> can you update the version on the repo and add a MIT license

## Goal

Stamp the template with an initial version (0.1.0) and an MIT license.

## Scope

- In: top-level `VERSION` file (`0.1.0`), `LICENSE` (MIT, Bejan Sadeghian, 2026), annotated git tag `v0.1.0`.
- Out: changelog automation, release workflow, license headers in source files.

## Acceptance criteria

- [x] AC1: `VERSION` file exists at repo root containing `0.1.0`.
- [x] AC2: `LICENSE` exists at repo root with MIT text and 2026 copyright to Bejan Sadeghian.
- [x] AC3: Annotated tag `v0.1.0` points at the commit introducing these files.

## Risks / unknowns

- None.

## Build log

- 2026-05-17 — Added `VERSION` (0.1.0) and `LICENSE` (MIT). Tagged `v0.1.0`.
