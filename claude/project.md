# Project profile

Claude reads this and follows it. Regenerate with `setup`.

- App type: web        # web | ios
- Git workflow: main   # main | branch-pr
- CI: on               # on | off
- Deploy: none         # none | railway | azure (comma-separated)
- Auth: web            # web | password

## Feature board (GitHub Project)

Owner to assign/@mention on Verify, plus the board IDs. Create/refresh with
`bash scripts/feature-board.sh` (writes the IDs below; needs the gh `project` scope).

- owner:            # your GitHub username, e.g. BejanSadeghian
- board:            # Project named after this repo (filled by feature-board.sh)
- project-id:       # PVT_...
- status-field-id:  # PVTSSF_...
- option Presented: #
- option Active:    #
- option Verify:    #
- option Closed:    #

## Deployment (staged)

The same promotion flow every time, regardless of target:

- stages: dev → staging → prod
- dev: auto on push to `main`
- staging: manual approval (GitHub Environment required reviewers)
- prod: manual approval
- versioning: semantic-release (conventional commits → vX.Y.Z); staging & prod tag a release number
- targets: none          # railway | azure | railway,azure
- storybook: off         # off | railway | <provider> — if on, keep in sync with every UI change
