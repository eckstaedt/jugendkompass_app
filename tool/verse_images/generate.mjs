#!/usr/bin/env node
// Generates the "Vers des Tages" share images (nature photo + verse) for the
// upcoming days and stores them in Supabase Storage (bucket `verse-images`,
// folder `auto/`).
//
// A row gets a (new) image when
//   - image_url is empty, or
//   - the image was generated automatically (image_source_hash is set) and the
//     verse text / reference was edited afterwards (hash no longer matches).
// Images uploaded manually in the admin panel (image_source_hash = NULL) are
// never touched.
//
// Usage:
//   SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... node generate.mjs [--days 45] [--from 2026-11-04]
//   node generate.mjs --preview out/ --input verses.json [--from 2026-11-04] [--days 14]
//     (renders local JPEGs from a JSON list [{date, verse, reference}], no upload)

import { createHash } from 'node:crypto';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { join } from 'node:path';
import { pickDesign } from './design.mjs';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');

const args = Object.fromEntries(
  process.argv.slice(2).reduce((acc, cur, i, all) => {
    if (cur.startsWith('--')) acc.push([cur.slice(2), all[i + 1]?.startsWith('--') ? 'true' : all[i + 1] ?? 'true']);
    return acc;
  }, []),
);

const DAYS = Number(args.days ?? process.env.DAYS_AHEAD ?? 45);
const todayBerlin = new Intl.DateTimeFormat('en-CA', { timeZone: 'Europe/Berlin' }).format(new Date());
const FROM = args.from ?? todayBerlin;
const MONTHS = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'];

const addDays = (iso, n) => {
  const d = new Date(`${iso}T12:00:00Z`);
  d.setUTCDate(d.getUTCDate() + n);
  return d.toISOString().slice(0, 10);
};
const dateLabel = (iso) => {
  const [y, m, d] = iso.split('-').map(Number);
  return `${d}. ${MONTHS[m - 1]} ${y}`;
};
export const sourceHash = (verse, reference) =>
  createHash('sha1').update(`${verse}\n${reference}`).digest('hex');

// ---------------------------------------------------------------- fetching
async function fetchRetry(url, init = {}, tries = 4) {
  let lastErr;
  for (let i = 0; i < tries; i++) {
    try {
      const res = await fetch(url, init);
      if (res.ok || (res.status >= 400 && res.status < 500 && res.status !== 429)) return res;
      lastErr = new Error(`${res.status} ${await res.text()}`);
    } catch (e) {
      lastErr = e;
    }
    await new Promise((r) => setTimeout(r, 1000 * 2 ** i));
  }
  throw lastErr;
}

const fontCache = new Map();
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36';
async function fontFaceCss(family, weight) {
  const key = `${family}:${weight}`;
  if (fontCache.has(key)) return fontCache.get(key);
  const url = `https://fonts.googleapis.com/css2?family=${encodeURIComponent(family).replace(/%20/g, '+')}:wght@${weight}&display=block`;
  const css = await (await fetchRetry(url, { headers: { 'User-Agent': UA } })).text();
  let out = '';
  // only the latin + latin-ext subsets (German text)
  for (const m of css.matchAll(/\/\*\s*(latin(?:-ext)?)\s*\*\/\s*@font-face\s*{([^}]*)}/g)) {
    const src = m[2].match(/url\((https:[^)]+)\)/)[1];
    const range = m[2].match(/unicode-range:([^;]+);/)?.[1] ?? '';
    const buf = Buffer.from(await (await fetchRetry(src)).arrayBuffer());
    out += `@font-face{font-family:'${family}';font-style:normal;font-weight:${weight};font-display:block;` +
      `src:url(data:font/woff2;base64,${buf.toString('base64')}) format('woff2');unicode-range:${range};}\n`;
  }
  if (!out) throw new Error(`Font not found: ${family} ${weight}`);
  fontCache.set(key, out);
  return out;
}

async function imageDataUrl(url) {
  const res = await fetchRetry(url, { redirect: 'follow' });
  if (!res.ok) throw new Error(`Image download failed ${res.status}: ${url}`);
  const buf = Buffer.from(await res.arrayBuffer());
  return `data:${res.headers.get('content-type') ?? 'image/jpeg'};base64,${buf.toString('base64')}`;
}

// ---------------------------------------------------------------- render
const DRAW_SRC = readFileSync(new URL('./draw.js', import.meta.url), 'utf8');

async function render(page, { date, verse, reference }) {
  const design = pickDesign(date, verse.length);
  const css = (await fontFaceCss(design.familyVerse, design.weightVerse)) +
    (await fontFaceCss(design.familyMeta, design.weightMeta)) +
    (design.layout === 'quote' ? await fontFaceCss(design.familyVerse, 700).catch(() => '') : '');
  await page.setContent(`<!doctype html><html><head><style>${css}</style></head><body></body></html>`);
  await page.addScriptTag({ content: DRAW_SRC });
  const dataUrl = await page.evaluate(
    (input) => drawVerseImage(input), // eslint-disable-line no-undef
    { verse, reference, dateLabel: dateLabel(date), design, imageDataUrl: await imageDataUrl(design.imageUrl) },
  );
  return { design, jpeg: Buffer.from(dataUrl.split(',')[1], 'base64') };
}

// ---------------------------------------------------------------- supabase
function supabase() {
  const url = process.env.SUPABASE_URL?.replace(/\/$/, '');
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) throw new Error('SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required');
  const headers = { apikey: key, Authorization: `Bearer ${key}` };
  return {
    async rows(from, to) {
      const q = `${url}/rest/v1/verse_of_the_day?select=id,date,verse,reference,image_url,image_source_hash` +
        `&date=gte.${from}&date=lte.${to}&order=date.asc`;
      const res = await fetchRetry(q, { headers });
      if (!res.ok) throw new Error(`select failed: ${res.status} ${await res.text()}`);
      return res.json();
    },
    async upload(path, jpeg) {
      const res = await fetchRetry(`${url}/storage/v1/object/verse-images/${path}`, {
        method: 'POST',
        headers: { ...headers, 'Content-Type': 'image/jpeg', 'x-upsert': 'true', 'Cache-Control': 'max-age=31536000' },
        body: jpeg,
      });
      if (!res.ok) throw new Error(`upload failed: ${res.status} ${await res.text()}`);
      return `${url}/storage/v1/object/public/verse-images/${path}`;
    },
    async remove(path) {
      await fetchRetry(`${url}/storage/v1/object/verse-images`, {
        method: 'DELETE',
        headers: { ...headers, 'Content-Type': 'application/json' },
        body: JSON.stringify({ prefixes: [path] }),
      }).catch(() => {});
    },
    async update(id, patch) {
      const res = await fetchRetry(`${url}/rest/v1/verse_of_the_day?id=eq.${id}`, {
        method: 'PATCH',
        headers: { ...headers, 'Content-Type': 'application/json', Prefer: 'return=minimal' },
        body: JSON.stringify(patch),
      });
      if (!res.ok) throw new Error(`update failed: ${res.status} ${await res.text()}`);
    },
  };
}

// ---------------------------------------------------------------- main
async function main() {
  const to = addDays(FROM, DAYS - 1);
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 400, height: 400 } });
  let done = 0;
  let failed = 0;

  try {
    if (args.preview) {
      mkdirSync(args.preview, { recursive: true });
      const list = JSON.parse(readFileSync(args.input, 'utf8'));
      for (const row of list.filter((r) => r.date >= FROM && r.date <= to)) {
        const { design, jpeg } = await render(page, row);
        const file = join(args.preview, `${row.date}.jpg`);
        writeFileSync(file, jpeg);
        console.log(`${row.date}  ${design.layout.padEnd(6)} ${design.familyVerse.padEnd(22)} img ${design.imageId}  -> ${file}`);
        done++;
      }
      return;
    }

    const db = supabase();
    const rows = await db.rows(FROM, to);
    console.log(`Checking ${rows.length} verse rows ${FROM} … ${to}`);
    for (const row of rows) {
      const hash = sourceHash(row.verse, row.reference);
      const hasImage = !!row.image_url;
      const isAuto = !!row.image_source_hash;
      if (hasImage && (!isAuto || row.image_source_hash === hash)) continue;
      try {
        const { design, jpeg } = await render(page, row);
        const path = `auto/${row.date}-${hash.slice(0, 10)}.jpg`;
        const publicUrl = await db.upload(path, jpeg);
        await db.update(row.id, { image_url: publicUrl, image_source_hash: hash });
        const old = row.image_url?.split('/verse-images/')[1];
        if (isAuto && old && old.startsWith('auto/') && old !== path) await db.remove(old);
        console.log(`✓ ${row.date}  ${design.layout} / ${design.familyVerse} / photo ${design.imageId}`);
        done++;
      } catch (e) {
        failed++;
        console.error(`✗ ${row.date}: ${e.message}`);
      }
    }
  } finally {
    await browser.close();
  }
  console.log(`Done: ${done} image(s) rendered, ${failed} failed.`);
  if (failed) process.exitCode = 1;
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
