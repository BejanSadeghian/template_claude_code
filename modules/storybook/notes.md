Storybook module installed.
- Needs a `build-storybook` script and a `.storybook/` config in your project.
- Optional Railway deploy: add a `storybook` GitHub Environment with secret RAILWAY_TOKEN, and a Railway service named `storybook` (or set STORYBOOK_SERVICE).
- Without RAILWAY_TOKEN it just uploads `storybook-static` as a workflow artifact.
- Set `storybook: railway` in claude/project.md → Deployment so Claude keeps it in sync.
