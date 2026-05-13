# 0005 — sudoers-post-create

- **Status**: done
- **Owner**: <github_account>
- **Created**: 2026-04-27
- **Last updated**: 2026-04-27

## Original prompt

> what does Running the onCreateCommand from devcontainer.json... [144272 ms] Start: Run in container: /bin/sh -c sudo /usr/local/bin/post-create.sh mean when im starting up a new devcontainerin vs code
>
> its asking for a password. what is it?

## Goal

Make `sudo /usr/local/bin/post-create.sh` succeed non-interactively during `onCreateCommand` so the container build doesn't stall on a sudo password prompt the `node` user has no password for.

## Scope

- In: extend the existing sudoers allowlist in `.devcontainer/Dockerfile` to include `post-create.sh` alongside `init-firewall.sh`.
- Out: rewriting `post-create.sh` to avoid root, switching to `runArgs` user toggling, or removing the SSH-copy block that needs root.

## Acceptance criteria

- [x] AC1: `/etc/sudoers.d/node-firewall` grants NOPASSWD for both `init-firewall.sh` and `post-create.sh`.
- [x] AC2: No other sudoers files are introduced (single source of truth).
- [x] AC3: After rebuild, `onCreateCommand` runs to completion without prompting.

## Risks / unknowns

- Granting passwordless sudo to a script the `node` user can read but not write is fine — the script lives at `/usr/local/bin/post-create.sh` (root-owned) and is only writable by root. If that ever changes, anyone with `node` could escalate to root via sudoers; the Dockerfile sets the permissions via `COPY` defaults (root:root, 0755 after `chmod +x`), so this is safe today.

## Subtasks

- [x] Update sudoers entry in Dockerfile.

## Build log

- 2026-04-27 — User hit the password prompt during a fresh container build of `notetaking`. Root cause: `onCreateCommand: "sudo /usr/local/bin/post-create.sh"` but only `init-firewall.sh` was in the NOPASSWD allowlist. Added `post-create.sh` to the same line.

## Test evidence

Verification path: rebuild the devcontainer (Command Palette → "Dev Containers: Rebuild Container") and confirm `onCreateCommand` completes without a prompt. (User to run; no host-side verifier.)

## Scope changes

None.
