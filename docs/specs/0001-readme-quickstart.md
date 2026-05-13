# 0001 — readme-quickstart

- **Status**: in-progress
- **Branch**: `feat/0001-readme-quickstart`
- **Owner**: <github_account>
- **Created**: 2026-04-27
- **Last updated**: 2026-04-27

## Original prompt

> how do i setup a new repo with this? I want to refer to the remote template
>
> can you add that as a quick start in the readme and push to the repo?

## Goal

Document how to bootstrap a new project from this repo (as a GitHub template, or via clone+reset) so a new user can stand up a fresh repo without re-deriving the steps.

## Scope

- In: a "Quick start: new repo from this template" section in `README.md` covering the `gh repo create --template` path and the clone+reset fallback.
- Out: changes to template behavior, scripts, or CI; renaming the existing "First-time setup" section.

## Acceptance criteria

- [x] AC1: `README.md` contains a "Quick start" section above "First-time setup".
- [x] AC2: Section shows both the `--template` path and the clone+reset fallback.
- [x] AC3: Section notes the one-time "Template repository" toggle in GitHub settings.
- [x] AC4: Branch pushed and PR opened against `main`.

## Risks / unknowns

- The `--template` flag requires the source repo to be marked as a template in GitHub settings; called out inline.

## Subtasks

- [x] Add Quick start section to README.
- [x] Commit spec, then README, on a feature branch.
- [x] Push branch and open PR.

## Build log

- 2026-04-27 — Spec created.
- 2026-04-27 — README quick start section added.
- 2026-04-27 — Branch pushed; PR opened.

## Test evidence

Docs-only change. Verified by rendering `README.md` locally and confirming the new section appears above "First-time setup".

## Scope changes

None.
