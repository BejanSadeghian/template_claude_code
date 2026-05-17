# 0008 — sox-for-claude-voice

- **Status**: done
- **Owner**: bejan
- **Created**: 2026-05-17
- **Last updated**: 2026-05-17

## Original prompt

> can you auto install apt-get install sox for claude voice too in the devcontainer?

## Goal

Have `sox` available out of the box in the devcontainer so Claude voice input works without a manual install.

## Scope

- In: add `sox` to the apt-get install line in `.devcontainer/Dockerfile`.
- Out: audio device passthrough config, PulseAudio setup, host-side mic plumbing.

## Acceptance criteria

- [x] AC1: `sox` is listed in the base apt-get install RUN block.
- [x] AC2: No separate RUN layer added (keeps image layers tight).

## Risks / unknowns

- Pulls in libsox dependencies (~a few MB). Acceptable.

## Build log

- 2026-05-17 — Added `sox` to Dockerfile apt list.

## Test evidence

Verified on next container rebuild: `which sox` returns `/usr/bin/sox`.
