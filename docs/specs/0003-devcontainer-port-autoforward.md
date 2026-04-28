# 0003 — devcontainer-port-autoforward

- **Status**: done
- **Owner**: BejanSadeghian
- **Created**: 2026-04-27
- **Last updated**: 2026-04-27

## Original prompt

> also, in the dev container, i tent to have port clashes. How can i randomly assign or should i just not another assigning a mapped port?
>
> [after options presented] k

## Goal

Stop pinning fixed host ports so multiple devcontainers can run concurrently without colliding on `localhost:3000` etc.

## Scope

- In: drop the `forwardPorts` array from `.devcontainer/devcontainer.json`; rely on VS Code's auto-detect-and-forward to assign a free host port for each container listener. Add `otherPortsAttributes.onAutoForward = "notify"` so any unlabeled listener still surfaces.
- Out: scripted per-project port offsets, host-side reverse proxies, changes to app code or env wiring.

## Acceptance criteria

- [x] AC1: `forwardPorts` removed from `.devcontainer/devcontainer.json`.
- [x] AC2: `portsAttributes` labels (3000, 3001, 5173, 8000, 8080) preserved so the Ports panel still names them when detected.
- [x] AC3: `otherPortsAttributes` set so newly listening ports still notify.
- [x] AC4: JSON parses (validated via `python -m json.tool`).

## Risks / unknowns

- Bookmarks like `http://localhost:3000` no longer point at a specific project — users must check the VS Code Ports panel for the actual host port. Acceptable trade for clash-free multi-container work.
- Some tooling (e.g. CORS allowlists pinned to `localhost:3000`) may need to widen to a range or use the panel-provided URL.

## Subtasks

- [x] Edit `.devcontainer/devcontainer.json`.
- [x] Validate JSON.

## Build log

- 2026-04-27 — Removed `forwardPorts`, added `otherPortsAttributes`. Auto-forward picks the next free host port per listener.

## Test evidence

- `python -m json.tool .devcontainer/devcontainer.json > /dev/null` exits 0 (valid JSON).
- Behavior verification deferred to next container rebuild — VS Code's auto-forwarding is documented behavior.

## Scope changes

None.
