// Kopiert Storage-Dateien aus der Supabase Cloud auf den VPS.
// Download über die öffentliche Objekt-URL (alle Buckets sind public),
// Upload über die normale Storage-API des VPS mit dem Service-Role-Key.
// Wird von migrate-storage.sh in einem node-Container gestartet.
//
// Umgebungsvariablen:
//   CLOUD_URL         https://<ref>.supabase.co
//   VPS_STORAGE_URL   http://storage:5000 (direkt, ohne Gateway-Zeitlimit)
//   SERVICE_ROLE_KEY  Service-Role-Key des VPS
//   LIST_CLOUD        JSONL: {"b":bucket,"n":name,"s":size,"t":mimetype,"c":cacheControl}
//   LIST_VPS          JSONL: {"b":bucket,"n":name,"s":size}  (schon vorhanden)
//   CONCURRENCY       parallele Übertragungen (Standard 6)
import { createWriteStream, openAsBlob, readFileSync } from 'node:fs';
import { mkdtemp, rm, stat } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { Readable } from 'node:stream';
import { pipeline } from 'node:stream/promises';

const { CLOUD_URL, VPS_STORAGE_URL, SERVICE_ROLE_KEY, LIST_CLOUD, LIST_VPS } = process.env;
const CONCURRENCY = Number(process.env.CONCURRENCY || 6);
for (const [k, v] of Object.entries({ CLOUD_URL, VPS_STORAGE_URL, SERVICE_ROLE_KEY, LIST_CLOUD, LIST_VPS })) {
  if (!v) { console.error(`${k} fehlt`); process.exit(2); }
}

const readList = (file) =>
  readFileSync(file, 'utf8').split('\n').filter((l) => l.trim()).map((l) => JSON.parse(l));
const encPath = (p) => p.split('/').map(encodeURIComponent).join('/');
const mb = (n) => (n / 1e6).toFixed(1);

const have = new Map(readList(LIST_VPS).map((o) => [`${o.b}/${o.n}`, Number(o.s)]));
const all = readList(LIST_CLOUD);
const todo = all.filter((o) => have.get(`${o.b}/${o.n}`) !== Number(o.s));
// kleine Dateien zuerst: Fehler zeigen sich sofort
todo.sort((a, b) => Number(a.s) - Number(b.s));

const totalBytes = todo.reduce((s, o) => s + Number(o.s), 0);
console.log(`${all.length} Dateien in der Cloud, ${all.length - todo.length} schon auf dem VPS, ${todo.length} zu kopieren (${mb(totalBytes)} MB)`);

const tmp = await mkdtemp(join(tmpdir(), 'jk-storage-'));
let done = 0, ok = 0, doneBytes = 0, seq = 0;
const failed = [];

async function copyOne(o) {
  const size = Number(o.s);
  const file = join(tmp, `f${seq++}`);
  try {
    const src = await fetch(`${CLOUD_URL}/storage/v1/object/public/${encodeURIComponent(o.b)}/${encPath(o.n)}`);
    if (!src.ok) throw new Error(`Download HTTP ${src.status}`);
    await pipeline(Readable.fromWeb(src.body), createWriteStream(file));
    const got = (await stat(file)).size;
    if (got !== size) throw new Error(`Größe ${got} statt ${size}`);

    const res = await fetch(`${VPS_STORAGE_URL}/object/${encodeURIComponent(o.b)}/${encPath(o.n)}`, {
      method: 'POST',
      headers: {
        authorization: `Bearer ${SERVICE_ROLE_KEY}`,
        apikey: SERVICE_ROLE_KEY,
        'content-type': o.t || 'application/octet-stream',
        'cache-control': o.c || 'max-age=3600',
        'x-upsert': 'true',
      },
      body: await openAsBlob(file),
    });
    if (!res.ok) throw new Error(`Upload HTTP ${res.status} ${(await res.text()).slice(0, 200)}`);
    await res.arrayBuffer();
  } finally {
    await rm(file, { force: true });
  }
}

async function withRetry(o) {
  for (let attempt = 1; ; attempt++) {
    try { return await copyOne(o); } catch (e) {
      if (attempt >= 3) throw e;
      await new Promise((r) => setTimeout(r, 2000 * attempt));
    }
  }
}

let next = 0;
let lastLog = Date.now();
async function worker() {
  while (next < todo.length) {
    const o = todo[next++];
    try {
      await withRetry(o);
      ok++;
    } catch (e) {
      failed.push(o);
      console.error(`FEHLER ${o.b}/${o.n}: ${e.message}`);
      // Bricht früh ab, wenn schon die ersten Dateien scheitern (falsche Konfiguration)
      if (ok === 0 && failed.length >= 3) { console.error('Die ersten Dateien schlagen alle fehl – Abbruch.'); process.exit(1); }
    }
    done++; doneBytes += Number(o.s);
    if (Date.now() - lastLog > 15000 || done === todo.length) {
      lastLog = Date.now();
      console.log(`${done}/${todo.length} Dateien, ${mb(doneBytes)}/${mb(totalBytes)} MB, Fehler: ${failed.length}`);
    }
  }
}
await Promise.all(Array.from({ length: CONCURRENCY }, worker));
await rm(tmp, { recursive: true, force: true });

if (failed.length) {
  console.error(`${failed.length} Dateien fehlgeschlagen. Skript einfach noch einmal starten – es kopiert nur, was fehlt.`);
  process.exit(1);
}
console.log('Alle Dateien kopiert.');
