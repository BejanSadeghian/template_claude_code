# Storybook

- **Keep Storybook in sync with every UI change** — add/update the story in the same commit as the component. `build-storybook` must pass (it's part of the definition of done for UI work).
- Storybook is the living UI reference I review and mark up on — never let it drift from the components.
- It builds on every push; if `RAILWAY_TOKEN` is set it deploys to Railway (optional), else it's uploaded as a build artifact.
