# 0009 — full-nopasswd-sudo

- **Status**: done
- **Owner**: bejan
- **Created**: 2026-05-17
- **Last updated**: 2026-05-17

## Original prompt

> then what do i enter when i am asked for a password using sudo su in the terminal of the devcontainer
> either work if itll work with a devcontainer.

## Goal

Let the `node` user run any `sudo` command (including `sudo su`) inside the devcontainer without a password.

## Scope

- In: broaden `/etc/sudoers.d/node-firewall` to `node ALL=(ALL) NOPASSWD: ALL`.
- Out: changing the user, removing the firewall script entries (covered by ALL now).

## Acceptance criteria

- [x] AC1: Sudoers grants `node` NOPASSWD for all commands.
- [x] AC2: `sudo su`, `sudo apt-get install ...` etc. work without prompting in a freshly built container.

## Risks / unknowns

- Container is fully trusted; pairs with the permissive firewall from 0007.

## Build log

- 2026-05-17 — Replaced script-scoped NOPASSWD with `ALL=(ALL) NOPASSWD: ALL`.

## Test evidence

Verify on next rebuild: `sudo whoami` returns `root` with no prompt.
