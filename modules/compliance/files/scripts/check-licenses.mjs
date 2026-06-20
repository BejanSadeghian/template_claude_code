#!/usr/bin/env node
// License compliance gate.
//   - FAILS on strong copyleft: GPL, AGPL, SSPL
//   - NOTICES (warns, doesn't fail) on weak copyleft: LGPL
// Uses license-checker-evergreen (the maintained fork) via npx — no persistent dep.
// Allowlist vetted exceptions: LICENSE_ALLOW="pkg@1.2.3,other@0.1.0"
import { execFileSync } from 'node:child_process';

let raw;
try {
  raw = execFileSync(
    'npx',
    ['-y', 'license-checker-evergreen', '--production', '--json'],
    { encoding: 'utf8', stdio: ['ignore', 'pipe', 'inherit'], maxBuffer: 64 * 1024 * 1024 },
  );
} catch (e) {
  console.error('license scan failed:', e.message);
  process.exit(2);
}

const pkgs = JSON.parse(raw);
const FAIL = /\b(?:A?GPL|SSPL)\b/i; // GPL / AGPL / SSPL  (note: does not match LGPL)
const NOTICE = /\bLGPL\b/i;         // LGPL — allowed, warn only
const allow = new Set(
  (process.env.LICENSE_ALLOW || '').split(',').map((s) => s.trim()).filter(Boolean),
);

const failed = [];
const noticed = [];
for (const [name, info] of Object.entries(pkgs)) {
  if (allow.has(name)) continue;
  const lic = String(info.licenses || '');
  if (NOTICE.test(lic) && !FAIL.test(lic)) noticed.push(`${name}: ${lic}`);
  else if (FAIL.test(lic)) failed.push(`${name}: ${lic}`);
}

if (noticed.length) {
  console.warn('⚠ LGPL dependencies (allowed — review for static linking):');
  noticed.forEach((l) => console.warn('  ' + l));
}
if (failed.length) {
  console.error('\n✗ Disallowed copyleft (GPL/AGPL/SSPL):');
  failed.forEach((l) => console.error('  ' + l));
  console.error('\nVet and allowlist exceptions with LICENSE_ALLOW="pkg@ver,...".');
  process.exit(1);
}
console.log('✓ License check passed (no GPL/AGPL/SSPL in production deps).');
