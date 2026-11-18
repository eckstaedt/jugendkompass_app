// Vercel Serverless Function: landing page for shared Jugendkompass links.
//
//   https://www.jugendkompass.com/{type}/{id}   (rewritten here by vercel.json)
//   https://www.jugendkompass.com/open?type=…&id=…  (older links)
//
// When the app is installed, iOS Universal Links / Android App Links open the
// URL directly in the app and this page is never shown. It is only rendered
// for
//   1. link-preview crawlers (WhatsApp, iMessage, Telegram, Signal, …): the
//      Open Graph tags carry the content's title, teaser and cover image, so
//      the shared message shows a preview card with the cover picture;
//   2. people who don't have the app yet: they see the content preview and
//      buttons to open the app / install it / read it in the web app.
//
// Data comes from Supabase via the public anon key (RLS: published content is
// readable by everyone – the same key ships inside the app).

const SUPABASE_URL =
  process.env.SUPABASE_URL || 'https://api.jugendkompass.com';
const SUPABASE_ANON_KEY =
  process.env.SUPABASE_ANON_KEY ||
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZkY2RpYnZjbGF1bHF4Zmp5enBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU0NTkxODksImV4cCI6MjA4MTAzNTE4OX0.cuJ5OKNauU_-mKQ3oX8Yi88kEJq2o5fpADlYquAkZLw';

const SITE = 'https://www.jugendkompass.com';
const APP_STORE_URL = 'https://apps.apple.com/de/app/jugendkompass/id1559123537';
const APP_STORE_ID = '1559123537';
const ANDROID_PACKAGE = 'io.stephanus.jugendkompass';
const PLAY_STORE_URL = `https://play.google.com/store/apps/details?id=${ANDROID_PACKAGE}`;
const FALLBACK_IMAGE = `${SITE}/icons/Icon-512.png`;

const TYPE_ALIASES = {
  artikel: 'post',
  article: 'post',
  articles: 'post',
  audio: 'post',
  post_audio: 'post',
  podcast: 'post',
  videos: 'video',
  impuls: 'impulse',
  kurznachricht: 'message',
  messages: 'message',
  ausgabe: 'edition',
  editions: 'edition',
  umfrage: 'poll',
  polls: 'poll',
  vers: 'verse',
  verse_of_the_day: 'verse',
};

const TYPE_LABELS = {
  post: 'Artikel',
  video: 'Video',
  impulse: 'Impuls',
  message: 'Kurznachricht',
  edition: 'Ausgabe',
  poll: 'Umfrage',
  verse: 'Vers des Tages',
  content: 'Inhalt',
};

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const INT_RE = /^\d+$/;

// table, selected columns and how a row maps to { title, description, image }.
const SOURCES = {
  post: {
    table: 'posts',
    select: 'id,content_id,title,body,image_url',
    idType: 'uuid',
    map: (r) => ({ title: r.title, description: r.body, image: r.image_url }),
  },
  video: {
    table: 'videos',
    select: 'id,content_id,title,description,image_url,url',
    idType: 'int',
    map: (r) => ({ title: r.title, description: r.description, image: r.image_url }),
  },
  impulse: {
    table: 'impulses',
    select: 'id,content_id,title,impulse_text,image_url',
    idType: 'uuid',
    map: (r) => ({ title: r.title, description: r.impulse_text, image: r.image_url }),
  },
  message: {
    table: 'messages',
    select: 'id,content_id,title,message,image_url',
    idType: 'int',
    map: (r) => ({ title: r.title, description: r.message, image: r.image_url }),
  },
  edition: {
    table: 'editions',
    select: 'id,content_id,name,title,body,image_url',
    idType: 'uuid',
    map: (r) => ({
      title: [r.name, r.title].filter(Boolean).join(' – '),
      description: r.body,
      image: r.image_url,
    }),
  },
  poll: {
    table: 'polls',
    select: 'id,content_id,question',
    idType: 'uuid',
    map: (r) => ({ title: r.question, description: 'Stimm jetzt in der Jugendkompass-App ab!', image: null }),
  },
  verse: {
    table: 'verse_of_the_day',
    select: 'id,content_id,verse,reference,image_url',
    idType: 'uuid',
    map: (r) => ({
      title: r.reference ? `Vers des Tages – ${r.reference}` : 'Vers des Tages',
      description: r.verse,
      image: r.image_url,
    }),
  },
};

async function queryOne(table, select, column, value) {
  const url =
    `${SUPABASE_URL}/rest/v1/${table}?select=${encodeURIComponent(select)}` +
    `&${column}=eq.${encodeURIComponent(value)}&limit=1`;
  try {
    const res = await fetch(url, {
      headers: { apikey: SUPABASE_ANON_KEY, Authorization: `Bearer ${SUPABASE_ANON_KEY}` },
    });
    if (!res.ok) return null;
    const rows = await res.json();
    return Array.isArray(rows) && rows.length ? rows[0] : null;
  } catch (_) {
    return null;
  }
}

async function findInSource(type, id) {
  const src = SOURCES[type];
  if (!src) return null;
  const tries = [];
  if (UUID_RE.test(id)) tries.push(['content_id', id]);
  if (src.idType === 'uuid' ? UUID_RE.test(id) : INT_RE.test(id)) tries.push(['id', id]);
  if (type === 'video' && /^https?:\/\//i.test(id)) tries.push(['url', id]);
  for (const [column, value] of tries) {
    const row = await queryOne(src.table, src.select, column, value);
    if (row) return src.map(row);
  }
  return null;
}

async function findContent(type, id) {
  if (type !== 'content' && SOURCES[type]) {
    const hit = await findInSource(type, id);
    if (hit) return { type, ...hit };
  }
  // Generic content id (or wrong type): look it up in every table.
  if (!UUID_RE.test(id)) return null;
  const types = Object.keys(SOURCES);
  const results = await Promise.all(types.map((t) => findInSource(t, id)));
  const index = results.findIndex(Boolean);
  return index >= 0 ? { type: types[index], ...results[index] } : null;
}

function decodeEntities(s) {
  return s
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;|&apos;/g, "'")
    .replace(/&#(\d+);/g, (_, n) => String.fromCodePoint(Number(n)));
}

function plainText(html, max) {
  if (!html) return '';
  let text = decodeEntities(
    String(html)
      .replace(/<(br|\/p|\/div|\/h\d|\/li)[^>]*>/gi, ' ')
      .replace(/<[^>]+>/g, ''),
  )
    .replace(/\s+/g, ' ')
    .trim();
  if (max && text.length > max) {
    text = text.slice(0, max - 1).replace(/\s+\S*$/, '') + '…';
  }
  return text;
}

function esc(s) {
  return String(s ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function absoluteImage(url) {
  if (!url || typeof url !== 'string') return FALLBACK_IMAGE;
  const trimmed = url.trim();
  if (/^https:\/\//i.test(trimmed)) return trimmed;
  if (/^http:\/\//i.test(trimmed)) return trimmed.replace(/^http:/i, 'https:');
  if (trimmed.startsWith('/')) return `${SITE}${trimmed}`;
  return FALLBACK_IMAGE;
}

function renderPage({ type, id, content }) {
  const label = TYPE_LABELS[type] || 'Inhalt';
  const title = plainText(content?.title, 120) || `Jugendkompass – ${label}`;
  const description =
    plainText(content?.description, 200) ||
    'Artikel, Impulse, Videos, Podcasts und der Vers des Tages – in der Jugendkompass-App.';
  const image = absoluteImage(content?.image);
  const hasRealImage = image !== FALLBACK_IMAGE;

  const pathType = type === 'content' ? 'content' : type;
  const canonical = id
    ? `${SITE}/${encodeURIComponent(pathType)}/${encodeURIComponent(id)}`
    : `${SITE}/`;
  const appUrl = id
    ? `jugendkompass://${encodeURIComponent(pathType)}/${encodeURIComponent(id)}`
    : 'jugendkompass://open';
  const androidIntent = id
    ? `intent://${encodeURIComponent(pathType)}/${encodeURIComponent(id)}` +
      `#Intent;scheme=jugendkompass;package=${ANDROID_PACKAGE};` +
      `S.browser_fallback_url=${encodeURIComponent(PLAY_STORE_URL)};end`
    : PLAY_STORE_URL;
  const webAppUrl = id
    ? `${SITE}/?type=${encodeURIComponent(pathType)}&id=${encodeURIComponent(id)}`
    : `${SITE}/`;

  return `<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${esc(title)} · Jugendkompass</title>
  <meta name="description" content="${esc(description)}" />
  <link rel="canonical" href="${esc(canonical)}" />

  <meta property="og:type" content="article" />
  <meta property="og:site_name" content="Jugendkompass" />
  <meta property="og:locale" content="de_DE" />
  <meta property="og:url" content="${esc(canonical)}" />
  <meta property="og:title" content="${esc(title)}" />
  <meta property="og:description" content="${esc(description)}" />
  <meta property="og:image" content="${esc(image)}" />
  <meta property="og:image:secure_url" content="${esc(image)}" />
  <meta property="og:image:alt" content="${esc(title)}" />
  <meta name="twitter:card" content="${hasRealImage ? 'summary_large_image' : 'summary'}" />
  <meta name="twitter:title" content="${esc(title)}" />
  <meta name="twitter:description" content="${esc(description)}" />
  <meta name="twitter:image" content="${esc(image)}" />

  <meta name="apple-itunes-app" content="app-id=${APP_STORE_ID}, app-argument=${esc(canonical)}" />
  <link rel="icon" type="image/png" href="/favicon.png" />
  <style>
    :root { --bg:#f4f4f6; --card:#fff; --text:#111; --muted:#555; --border:rgba(0,0,0,.08); --accent:#c62828; }
    @media (prefers-color-scheme: dark) {
      :root { --bg:#0e0e10; --card:#1b1b1f; --text:#f2f2f2; --muted:#a8a8ad; --border:rgba(255,255,255,.12); }
    }
    * { box-sizing: border-box; }
    body { margin:0; min-height:100vh; display:grid; place-items:center; padding:16px;
      background:var(--bg); color:var(--text);
      font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif; }
    .card { width:100%; max-width:520px; background:var(--card); border:1px solid var(--border);
      border-radius:32px; overflow:hidden; box-shadow:0 10px 40px rgba(0,0,0,.08); }
    .cover { width:100%; aspect-ratio:16/10; object-fit:cover; display:block; background:var(--border); }
    .body { padding:20px 22px 24px; }
    .label { font-size:13px; font-weight:600; letter-spacing:.04em; text-transform:uppercase; color:var(--accent); }
    h1 { margin:6px 0 8px; font-size:22px; line-height:1.25; }
    p { margin:0; color:var(--muted); line-height:1.5; }
    .actions { display:grid; gap:10px; margin-top:20px; }
    a.btn { display:block; text-align:center; text-decoration:none; padding:13px 16px; border-radius:16px; font-weight:600; }
    a.primary { background:var(--accent); color:#fff; }
    a.secondary { border:1px solid var(--border); color:var(--text); }
    a.link { color:var(--muted); font-weight:500; padding:6px; }
  </style>
</head>
<body>
  <main class="card">
    ${hasRealImage ? `<img class="cover" src="${esc(image)}" alt="" />` : ''}
    <div class="body">
      <div class="label">${esc(label)}</div>
      <h1>${esc(title)}</h1>
      <p>${esc(description)}</p>
      <div class="actions">
        <a class="btn primary" id="openApp" href="${esc(appUrl)}">In der App öffnen</a>
        <a class="btn secondary" id="getApp" href="${esc(APP_STORE_URL)}">Jugendkompass-App laden</a>
        <a class="btn link" href="${esc(webAppUrl)}">Im Browser ansehen</a>
      </div>
    </div>
  </main>
  <script>
    (function () {
      var ua = navigator.userAgent || '';
      if (/android/i.test(ua)) {
        document.getElementById('openApp').href = ${JSON.stringify(androidIntent)};
        document.getElementById('getApp').href = ${JSON.stringify(PLAY_STORE_URL)};
      }
    })();
  </script>
</body>
</html>`;
}

module.exports = async function handler(req, res) {
  const query = req.query || {};
  const rawType = String(query.type || query.contentType || '').trim().toLowerCase();
  let id = String(query.id || query.contentId || '').trim();
  try {
    id = decodeURIComponent(id);
  } catch (_) {}
  id = id.replace(/^\/+|\/+$/g, '');

  const type = TYPE_ALIASES[rawType] || rawType || 'content';
  const content = id ? await findContent(type, id) : null;

  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.setHeader('Cache-Control', 'public, max-age=0, s-maxage=600, stale-while-revalidate=86400');
  res.statusCode = 200;
  res.end(renderPage({ type: content?.type || type, id, content }));
};
