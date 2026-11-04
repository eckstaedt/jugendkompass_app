// Ersetzt Vercel auf dem VPS: liefert den Flutter-Web-Build aus und
// bedient die Share-Links (web/api/share.js) mit denselben Rewrites wie web/vercel.json.
'use strict';
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');

const ROOT = path.resolve(process.env.WEB_ROOT || '/srv/web');
const PORT = Number(process.env.PORT || 8080);
const share = require(path.join(ROOT, 'api', 'share.js'));

const SHARE_TYPES =
  'post|artikel|audio|video|verse|vers|message|kurznachricht|impulse|impuls|edition|ausgabe|poll|umfrage|content';
const reTyped = new RegExp(`^/(${SHARE_TYPES})/([^/]+)/?$`);
const reShare = /^\/share\/([^/]+)\/([^/]+)\/?$/;

const TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.webp': 'image/webp',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.mp3': 'audio/mpeg',
  '.txt': 'text/plain; charset=utf-8',
  '.map': 'application/json',
};
const NO_CACHE = new Set(['index.html', 'flutter_service_worker.js', 'flutter_bootstrap.js', 'version.json', 'manifest.json']);

function sendFile(req, res, file) {
  const ext = path.extname(file).toLowerCase();
  let type = TYPES[ext] || 'application/octet-stream';
  // apple-app-site-association / assetlinks.json haben keine Endung bzw. müssen JSON sein
  if (file.includes(`${path.sep}.well-known${path.sep}`)) type = 'application/json';
  res.writeHead(200, {
    'Content-Type': type,
    'Cache-Control': NO_CACHE.has(path.basename(file)) ? 'no-cache' : 'public, max-age=3600',
  });
  if (req.method === 'HEAD') return res.end();
  fs.createReadStream(file).pipe(res);
}

function runShare(req, res, query) {
  req.query = query;
  Promise.resolve(share(req, res)).catch((err) => {
    console.error('[share]', err);
    if (!res.headersSent) res.writeHead(500, { 'Content-Type': 'text/plain' });
    res.end('Fehler');
  });
}

http
  .createServer((req, res) => {
    const url = new URL(req.url, 'http://localhost');
    let p;
    try {
      p = decodeURIComponent(url.pathname);
    } catch {
      res.writeHead(400);
      return res.end();
    }
    const query = Object.fromEntries(url.searchParams);

    if (p === '/healthz') {
      res.writeHead(200);
      return res.end('ok');
    }

    let m;
    if ((m = p.match(reTyped))) return runShare(req, res, { ...query, type: m[1], id: m[2] });
    if ((m = p.match(reShare))) return runShare(req, res, { ...query, type: m[1], id: m[2] });
    if (p === '/open' || p === '/api/share') return runShare(req, res, query);

    const file = path.join(ROOT, p);
    if (file !== ROOT && !file.startsWith(ROOT + path.sep)) {
      res.writeHead(400);
      return res.end();
    }
    fs.stat(file, (err, st) => {
      if (!err && st.isFile()) return sendFile(req, res, file);
      const idx = path.join(file, 'index.html');
      if (!err && st.isDirectory() && fs.existsSync(idx)) return sendFile(req, res, idx);
      if (path.extname(p)) {
        res.writeHead(404);
        return res.end('Not found');
      }
      sendFile(req, res, path.join(ROOT, 'index.html')); // SPA-Fallback
    });
  })
  .listen(PORT, () => console.log(`jugendkompass web on :${PORT}`));
