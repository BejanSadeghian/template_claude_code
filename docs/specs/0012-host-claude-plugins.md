# 0012 — host-claude-plugins

- **Status**: done
- **Owner**: bejan
- **Created**: 2026-05-17
- **Last updated**: 2026-05-17

## Original prompt

> can i have the devcontainer adopt the plugins the user has pre-installed?
> is that copying what i have locally? I want the user plugins to be used

## Goal

Make the devcontainer's Claude Code see the host user's installed plugins and skills automatically — no copy, no rebuild.

## Scope

- In: bind-mount host `~/.claude/plugins` and `~/.claude/skills` (read-only) into the container's `/home/node/.claude/`, layered on top of the existing named volume.
- Out: sharing `~/.claude/projects`, settings, or auth state; making mounts read-write.

## Acceptance criteria

- [x] AC1: `devcontainer.json` `mounts` array binds `${localEnv:HOME}/.claude/plugins` → `/home/node/.claude/plugins` read-only.
- [x] AC2: Same for `${localEnv:HOME}/.claude/skills` → `/home/node/.claude/skills`.
- [x] AC3: Existing `claude-code-config-*` named volume for `/home/node/.claude` is preserved — only plugins/skills come from host; auth, projects, history stay container-isolated.

## Risks / unknowns

- If the host lacks `~/.claude/plugins` or `~/.claude/skills`, container start will fail. Mitigation: create the dirs on host (`mkdir -p ~/.claude/{plugins,skills}`) before first launch. Documented here.
- Read-only mount means Claude Code inside the container cannot install plugins; user must install on host.

## Build log

- 2026-05-17 — Added two bind mounts to devcontainer.json.
- 2026-05-17 — Additional prompt: "add this as a section into the readme. … I want users to auth whatever they need themselves … i also dont want to auto install plugins for them, which is why i want to refer to their own plugins. But anything else look off?"
- 2026-05-17 — Refreshed README to reflect 0007/0008/0009/0010/0011/0012: removed stale default-deny firewall + allowlist references, added "Host Claude plugins & skills" section, added host prereq step (`mkdir -p ~/.claude/{plugins,skills}`), updated file table with `scripts/template-sync.sh`, `VERSION`, `LICENSE`, removed `allowed-domains.txt` row, reframed first-time setup to clarify the user authenticates manually.
- 2026-05-17 — Additional prompt: "does it update claude code as well in the container? I am not seeing all of the skills id expect."
- 2026-05-17 — Discovered: mounting only `~/.claude/plugins` and `~/.claude/skills` misses `settings.json`, `plugins.json`, `marketplaces/` — so the container Claude Code doesn't know which plugins/skills are *enabled*. Pivoted approach: bind entire host `~/.claude` read-only to `/home/node/.claude-host`; on `post-create.sh --start` symlink discovery paths (`plugins`, `skills`, `settings.json`, `plugins.json`, `marketplaces`, `commands`, `agents`, `output-styles`) from host into the writable `/home/node/.claude` volume. Reads come from host, writes stay container-isolated.
- 2026-05-17 — Tradeoff acknowledged: host `settings.json` auth tokens are now visible to the container. Documented in README.
