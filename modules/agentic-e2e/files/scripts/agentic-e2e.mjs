#!/usr/bin/env node
// Agentic E2E: drive deterministic Playwright steps for each user journey, then
// let Claude (vision) judge whether the journey's acceptance criteria were met.
//
// Why this shape: scripted navigation = cheap + low-flake; the LLM is used only
// as a judge at the end state. Reuses your existing Playwright + ANTHROPIC_API_KEY,
// no SaaS. Define journeys in qa/journeys.json.
//
//   E2E_BASE_URL   deployed URL to test (required)
//   ANTHROPIC_API_KEY   required
//   CLAUDE_JUDGE_MODEL  optional, default claude-sonnet-4-6
import { chromium } from 'playwright';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';

const BASE = (process.env.E2E_BASE_URL || '').replace(/\/$/, '');
const KEY = process.env.ANTHROPIC_API_KEY;
const MODEL = process.env.CLAUDE_JUDGE_MODEL || 'claude-sonnet-4-6';

if (!BASE) { console.error('E2E_BASE_URL is required'); process.exit(2); }
if (!KEY) { console.error('ANTHROPIC_API_KEY is required'); process.exit(2); }

const journeys = JSON.parse(readFileSync('qa/journeys.json', 'utf8'));
mkdirSync('qa/artifacts', { recursive: true });

// Minimal step interpreter: "goto:/path" "click:Text" "fill:#sel=value" "wait:1000" "press:Enter"
async function runStep(page, step) {
  const i = step.indexOf(':');
  const op = step.slice(0, i);
  const arg = step.slice(i + 1);
  if (op === 'goto') await page.goto(BASE + arg, { waitUntil: 'domcontentloaded' });
  else if (op === 'click') await page.getByText(arg, { exact: false }).first().click({ timeout: 15000 });
  else if (op === 'fill') { const [sel, ...v] = arg.split('='); await page.fill(sel, v.join('=')); }
  else if (op === 'wait') await page.waitForTimeout(Number(arg) || 1000);
  else if (op === 'press') await page.keyboard.press(arg);
  else throw new Error(`unknown step op: ${op}`);
}

async function judge(journey, screenshotB64, visibleText) {
  const prompt =
    `You are a strict QA judge verifying a user journey on a deployed web app.\n` +
    `Journey: ${journey.name}\n` +
    `Acceptance criteria: ${journey.expect}\n\n` +
    `You are given a screenshot of the final page state and its visible text.\n` +
    `Decide if the criteria are clearly met. Respond with ONLY JSON: ` +
    `{"pass": boolean, "reason": "<one sentence>"}.\n\nVisible text:\n${visibleText.slice(0, 4000)}`;
  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: { 'content-type': 'application/json', 'x-api-key': KEY, 'anthropic-version': '2023-06-01' },
    body: JSON.stringify({
      model: MODEL,
      max_tokens: 400,
      messages: [{ role: 'user', content: [
        { type: 'text', text: prompt },
        { type: 'image', source: { type: 'base64', media_type: 'image/png', data: screenshotB64 } },
      ] }],
    }),
  });
  if (!res.ok) throw new Error(`Anthropic API ${res.status}: ${await res.text()}`);
  const data = await res.json();
  const text = data.content?.map((c) => c.text || '').join('') ?? '';
  const m = text.match(/\{[\s\S]*\}/);
  return JSON.parse(m ? m[0] : text);
}

const browser = await chromium.launch();
const results = [];
for (const journey of journeys) {
  const page = await browser.newPage();
  const slug = journey.name.toLowerCase().replace(/[^a-z0-9]+/g, '-').slice(0, 60);
  try {
    await page.goto(BASE + (journey.goto || '/'), { waitUntil: 'domcontentloaded' });
    for (const step of journey.steps || []) await runStep(page, step);
    await page.waitForTimeout(500);
    const shot = await page.screenshot({ fullPage: true });
    writeFileSync(`qa/artifacts/${slug}.png`, shot);
    const text = await page.evaluate(() => document.body?.innerText || '');
    const verdict = await judge(journey, shot.toString('base64'), text);
    results.push({ name: journey.name, ...verdict });
    console.log(`${verdict.pass ? '✓' : '✗'} ${journey.name} — ${verdict.reason}`);
  } catch (e) {
    results.push({ name: journey.name, pass: false, reason: `error: ${e.message}` });
    console.log(`✗ ${journey.name} — error: ${e.message}`);
  } finally {
    await page.close();
  }
}
await browser.close();

writeFileSync('qa/artifacts/results.json', JSON.stringify(results, null, 2));
const failed = results.filter((r) => !r.pass);
console.log(`\n${results.length - failed.length}/${results.length} journeys passed.`);
process.exit(failed.length ? 1 : 0);
