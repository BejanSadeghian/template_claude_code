# License compliance

- `scripts/check-licenses.mjs` fails the build on strong copyleft (GPL/AGPL/SSPL) and warns on LGPL.
- Runs on push/PR and weekly (Mon 06:00 UTC). Allowlist vetted exceptions with `LICENSE_ALLOW="pkg@ver,..."`.
- When adding a dependency, check its license; don't allowlist copyleft without understanding the obligation.
