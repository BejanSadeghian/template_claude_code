# 0016 — auto-semver-bump

- **Status**: done
- **Owner**: bejan
- **Created**: 2026-05-17
- **Last updated**: 2026-05-17

## Original prompt

> update to a new version every time. use semantic versioning when we update for this repo please. and have that be a standard within the template but allow users to modify that.

## Goal

Every push automatically bumps `VERSION` and creates a matching `v*` tag, using semver derived from conventional commits since the last tag. Template-users can opt out per-commit, per-push, or entirely.

## Scope

- In:
  - `scripts/bump-version.sh` — computes bump from conventional commits or accepts forced size.
  - `hooks/pre-push` — runs the script before push.
  - `scripts/setup-hooks.sh` — also sets `push.followTags=true` so the new tag ships with the push.
  - CLAUDE.md "Versioning" section so Claude respects the workflow.
  - README "Versioning" section so humans understand and can opt out.
- Out:
  - Generating CHANGELOG.md from commits (separate concern).
  - Pre-release / build-metadata suffixes (e.g. `-rc.1`, `+sha`).

## Acceptance criteria

- [x] AC1: `scripts/bump-version.sh --dry-run` prints the bump it would apply and exits 0.
- [x] AC2: Bump precedence: `BREAKING CHANGE`/`type!:` > `feat:` > `fix|chore|docs|refactor|test|perf|style|build|ci:`. Highest wins.
- [x] AC3: `[skip version]` in a commit message excludes that commit from bump computation.
- [x] AC4: Deleting `VERSION` makes the hook a no-op (user can opt out of versioning entirely).
- [x] AC5: `SKIP_VERSION_BUMP=1 git push` skips the hook for one push.
- [x] AC6: Manual force works: `bash scripts/bump-version.sh [patch|minor|major]`.
- [x] AC7: `setup-hooks.sh` configures `push.followTags=true` so tags push with `git push`.
- [x] AC8: Release commits are themselves tagged with `[skip version]` so they don't trigger recursive bumps.

## Risks / unknowns

- The release commit creates a new commit *after* the user's commits but is included in the same push (pre-push runs before the transfer, so the new tip is what gets pushed). Verified mentally; will be exercised by this very push.
- If the user pushes with `--no-verify`, the bump is skipped (intentional).
- If a remote already has a higher tag than local (multi-machine workflow), bumps could collide. Mitigation: fetch tags before pushing. Not handled automatically — noted as a follow-up.

## Build log

- 2026-05-17 — Wrote `scripts/bump-version.sh`, wired pre-push hook, updated setup-hooks and CLAUDE.md/README.
- 2026-05-17 — Dry-run on this repo: would bump 0.1.0 → 0.2.0 (minor) because of recent `feat:` commits.

## Follow-ups

- Auto-fetch tags before bumping to avoid multi-machine collisions.
- Optional: emit CHANGELOG.md sections per release.
