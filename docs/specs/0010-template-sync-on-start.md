# 0010 — template-sync-on-start

- **Status**: done
- **Owner**: bejan
- **Created**: 2026-05-17
- **Last updated**: 2026-05-17

## Original prompt

> what is a process to auto check for updates on the template repo?
> i like option 2. the local script. but how does the update actually happen / look like?
> can we have it automatically run the template sync but give the option to accept or reject?

## Goal

On container start, detect template-owned-file updates in the upstream template repo and let the user accept/reject/defer interactively.

## Scope

- In: `scripts/template-sync.sh`; hook in `.devcontainer/post-create.sh --start`; commits accepted updates directly to `main` (unpushed).
- Out: auto-push, conflict resolution, syncing non-template-owned paths, GitHub Action variant.

## Acceptance criteria

- [x] AC1: Script no-ops when the repo *is* the template (origin URL matches `TEMPLATE_URL`).
- [x] AC2: Adds/repoints `template` remote idempotently to `https://github.com/BejanSadeghian/template_claude_code.git`.
- [x] AC3: Only touches paths in the hardcoded `PATHS` allowlist.
- [x] AC4: Skips silently if working tree is dirty in those paths.
- [x] AC5: Non-TTY invocations print a banner and exit 0 (never block container start).
- [x] AC6: Accept creates a single local commit `chore: sync template <sha>` on `main`, unpushed.
- [x] AC7: Reject / skip-this-version records the template sha in `.template-sync-ignore`.
- [x] AC8: Defer (or blank) exits without changes; re-prompts next container start.

## Risks / unknowns

- Offline container start → `git fetch` fails; script swallows and exits (intended).
- If template renames a tracked path, the rename isn't detected; user sees a deletion + addition in the diff.

## Build log

- 2026-05-17 — Created `scripts/template-sync.sh` and wired into `post-create.sh --start`.

## Test evidence

- `bash -n` clean on both scripts.
- Manual run on this repo (which *is* the template) exits 0 with no output (AC1).
- Full end-to-end behavior verifies on first child-repo container start after this lands upstream.
