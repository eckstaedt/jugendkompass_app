const { createClient } = window.supabase;

const CFG = window.TP_CONFIG;
const sb = createClient(CFG.supabaseUrl, CFG.supabaseAnonKey, {
  auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true },
});

// ─── Constants ──────────────────────────────────────────────────────────────
const TYPES = {
  post: { label: "Artikel", icon: "newspaper" },
  message: { label: "Nachrichten", icon: "message-square" },
  impulse: { label: "Impulse", icon: "lightbulb" },
  video: { label: "Videos", icon: "clapperboard" },
  verse: { label: "Tagesverse", icon: "book-open" },
  poll: { label: "Umfragen", icon: "chart-column" },
  edition: { label: "Ausgaben", icon: "library" },
  category: { label: "Kategorien", icon: "tag" },
};
const LANGS = {
  en: "Englisch", ru: "Russisch", es: "Spanisch", pl: "Polnisch", tr: "Türkisch", he: "Hebräisch",
  fr: "Französisch", it: "Italienisch", uk: "Ukrainisch", ro: "Rumänisch", pt: "Portugiesisch", ar: "Arabisch",
};
const STATUS_LABEL = {
  pending: "wartend", processing: "in Arbeit", completed: "fertig", failed: "fehlgeschlagen",
  queued: "eingereiht", retry: "Retry", requeued: "erneut eingereiht", admin: "Admin",
};

// ─── Icons (Lucide, ISC license – https://lucide.dev) ──────────────────────
const ICONS = {
  "file-plus": '<path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z" /> <path d="M14 2v4a2 2 0 0 0 2 2h4" /> <path d="M9 15h6" /> <path d="M12 18v-6" />',
  "sparkles": '<path d="M9.937 15.5A2 2 0 0 0 8.5 14.063l-6.135-1.582a.5.5 0 0 1 0-.962L8.5 9.936A2 2 0 0 0 9.937 8.5l1.582-6.135a.5.5 0 0 1 .963 0L14.063 8.5A2 2 0 0 0 15.5 9.937l6.135 1.581a.5.5 0 0 1 0 .964L15.5 14.063a2 2 0 0 0-1.437 1.437l-1.582 6.135a.5.5 0 0 1-.963 0z" /> <path d="M20 3v4" /> <path d="M22 5h-4" /> <path d="M4 17v2" /> <path d="M5 18H3" />',
  "plus": '<path d="M5 12h14" /> <path d="M12 5v14" />',
  "globe": '<circle cx="12" cy="12" r="10" /> <path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20" /> <path d="M2 12h20" />',
  "newspaper": '<path d="M4 22h16a2 2 0 0 0 2-2V4a2 2 0 0 0-2-2H8a2 2 0 0 0-2 2v16a2 2 0 0 1-2 2Zm0 0a2 2 0 0 1-2-2v-9c0-1.1.9-2 2-2h2" /> <path d="M18 14h-8" /> <path d="M15 18h-5" /> <path d="M10 6h8v4h-8V6Z" />',
  "message-square": '<path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />',
  "lightbulb": '<path d="M15 14c.2-1 .7-1.7 1.5-2.5 1-.9 1.5-2.2 1.5-3.5A6 6 0 0 0 6 8c0 1 .2 2.2 1.5 3.5.7.7 1.3 1.5 1.5 2.5" /> <path d="M9 18h6" /> <path d="M10 22h4" />',
  "clapperboard": '<path d="M20.2 6 3 11l-.9-2.4c-.3-1.1.3-2.2 1.3-2.5l13.5-4c1.1-.3 2.2.3 2.5 1.3Z" /> <path d="m6.2 5.3 3.1 3.9" /> <path d="m12.4 3.4 3.1 4" /> <path d="M3 11h18v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2Z" />',
  "book-open": '<path d="M12 7v14" /> <path d="M3 18a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1h5a4 4 0 0 1 4 4 4 4 0 0 1 4-4h5a1 1 0 0 1 1 1v13a1 1 0 0 1-1 1h-6a3 3 0 0 0-3 3 3 3 0 0 0-3-3z" />',
  "chart-column": '<path d="M3 3v16a2 2 0 0 0 2 2h16" /> <path d="M18 17V9" /> <path d="M13 17V5" /> <path d="M8 17v-3" />',
  "library": '<path d="m16 6 4 14" /> <path d="M12 6v14" /> <path d="M8 8v12" /> <path d="M4 4v16" />',
  "tag": '<path d="M12.586 2.586A2 2 0 0 0 11.172 2H4a2 2 0 0 0-2 2v7.172a2 2 0 0 0 .586 1.414l8.704 8.704a2.426 2.426 0 0 0 3.42 0l6.58-6.58a2.426 2.426 0 0 0 0-3.42z" /> <circle cx="7.5" cy="7.5" r=".5" fill="currentColor" />',
  "headphones": '<path d="M3 14h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-7a9 9 0 0 1 18 0v7a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h3" />',
  "rotate-cw": '<path d="M21 12a9 9 0 1 1-9-9c2.52 0 4.93 1 6.74 2.74L21 8" /> <path d="M21 3v5h-5" />',
  "rotate-ccw": '<path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8" /> <path d="M3 3v5h5" />',
  "external-link": '<path d="M15 3h6v6" /> <path d="M10 14 21 3" /> <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6" />',
  "arrow-right": '<path d="M5 12h14" /> <path d="m12 5 7 7-7 7" />',
  "arrow-left": '<path d="m12 19-7-7 7-7" /> <path d="M19 12H5" />',
  "pencil": '<path d="M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z" /> <path d="m15 5 4 4" />',
  "square-pen": '<path d="M12 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" /> <path d="M18.375 2.625a1 1 0 0 1 3 3l-9.013 9.014a2 2 0 0 1-.853.505l-2.873.84a.5.5 0 0 1-.62-.62l.84-2.873a2 2 0 0 1 .506-.852z" />',
  "play": '<polygon points="6 3 20 12 6 21 6 3" />',
  "x": '<path d="M18 6 6 18" /> <path d="m6 6 12 12" />',
  "credit-card": '<rect width="20" height="14" x="2" y="5" rx="2" /> <line x1="2" x2="22" y1="10" y2="10" />',
  "triangle-alert": '<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3" /> <path d="M12 9v4" /> <path d="M12 17h.01" />',
  "save": '<path d="M15.2 3a2 2 0 0 1 1.4.6l3.8 3.8a2 2 0 0 1 .6 1.4V19a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2z" /> <path d="M17 21v-7a1 1 0 0 0-1-1H8a1 1 0 0 0-1 1v7" /> <path d="M7 3v4a1 1 0 0 0 1 1h7" />',
  "key-round": '<path d="M2.586 17.414A2 2 0 0 0 2 18.828V21a1 1 0 0 0 1 1h3a1 1 0 0 0 1-1v-1a1 1 0 0 1 1-1h1a1 1 0 0 0 1-1v-1a1 1 0 0 1 1-1h.172a2 2 0 0 0 1.414-.586l.814-.814a6.5 6.5 0 1 0-4-4z" /> <circle cx="16.5" cy="7.5" r=".5" fill="currentColor" />',
  "circle-check": '<circle cx="12" cy="12" r="10" /> <path d="m9 12 2 2 4-4" />',
  "copy": '<rect width="14" height="14" x="8" y="8" rx="2" ry="2" /> <path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2" />',
  "eye": '<path d="M2.062 12.348a1 1 0 0 1 0-.696 10.75 10.75 0 0 1 19.876 0 1 1 0 0 1 0 .696 10.75 10.75 0 0 1-19.876 0" /> <circle cx="12" cy="12" r="3" />',
  "check": '<path d="M20 6 9 17l-5-5" />',
  "upload": '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /> <polyline points="17 8 12 3 7 8" /> <line x1="12" x2="12" y1="3" y2="15" />',
  "refresh-cw": '<path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8" /> <path d="M21 3v5h-5" /> <path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16" /> <path d="M8 16H3v5" />',
  "log-out": '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" /> <polyline points="16 17 21 12 16 7" /> <line x1="21" x2="9" y1="12" y2="12" />',
};
function ic(name, cls = "") {
  return `<svg class="ic ${cls}" viewBox="0 0 24 24" aria-hidden="true" focusable="false">${ICONS[name] || ""}</svg>`;
}

// ─── State ──────────────────────────────────────────────────────────────────
const state = {
  session: null,
  isAdmin: false,
  tab: localGet("tp_tab") || "overview",
  overview: null,
  overviewError: null,
  lastPoll: null,
  jobs: { status: "", type: "", q: "", offset: 0, limit: 50, rows: [], total: 0 },
  events: { event: "", type: "", rows: [] },
  runs: [],
  audios: { rows: null, q: "", filter: "all", uploading: {}, jobs: {}, jobsError: null },
  images: { groups: null, q: "", filter: "all", worker: null, error: null },
  content: { type: "", q: "", offset: 0, limit: 50, rows: [], total: 0, loaded: false },
  drawer: null,
  editor: null,
  busy: false,
};
let pollTimer = null;

// ─── Utils ──────────────────────────────────────────────────────────────────
function localGet(k) { try { return localStorage.getItem(k); } catch { return null; } }
function localSet(k, v) { try { localStorage.setItem(k, v); } catch { /* ignore */ } }
const $ = (sel, root = document) => root.querySelector(sel);
const esc = (v) => String(v ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
const fmtN = (n) => Number(n ?? 0).toLocaleString("de-DE");
function fmtTime(ts) {
  if (!ts) return "–";
  const d = new Date(ts);
  return d.toLocaleString("de-DE", { day: "2-digit", month: "2-digit", hour: "2-digit", minute: "2-digit", second: "2-digit" });
}
function ago(ts) {
  if (!ts) return "nie";
  const s = Math.round((Date.now() - new Date(ts).getTime()) / 1000);
  if (s < 0) return "in " + dur(-s);
  if (s < 60) return "vor " + s + " s";
  return "vor " + dur(s);
}
function dur(s) {
  if (s < 60) return s + " s";
  if (s < 3600) return Math.round(s / 60) + " min";
  if (s < 86400) return Math.round(s / 3600) + " h";
  return Math.round(s / 86400) + " Tagen";
}
function langName(c) { return LANGS[c] ? `${LANGS[c]} (${c})` : c; }
function typeLabel(t) { return TYPES[t] ? `<span class="with-ic">${ic(TYPES[t].icon)}${TYPES[t].label}</span>` : esc(t); }
function typeText(t) { return TYPES[t]?.label || t; }
function statusChip(s) { return `<span class="status ${esc(s)}">${esc(STATUS_LABEL[s] || s)}</span>`; }
function shortError(e) {
  if (!e) return "";
  const m = String(e).match(/"message"\s*:\s*"([^"]+)"/);
  const lang = String(e).match(/translation to (\w+) failed/);
  return (lang ? `[${lang[1]}] ` : "") + (m ? m[1] : String(e)).slice(0, 300);
}
function toast(msg, bad = false) {
  const t = $("#toast");
  t.textContent = msg;
  t.className = "toast" + (bad ? " bad" : "");
  t.hidden = false;
  clearTimeout(toast._t);
  toast._t = setTimeout(() => (t.hidden = true), bad ? 6000 : 3200);
}
async function rpc(name, args = {}) {
  const { data, error } = await sb.rpc(name, args);
  if (error) throw new Error(error.message);
  return data;
}
async function action(label, fn) {
  if (state.busy) return;
  state.busy = true;
  document.body.style.cursor = "progress";
  try {
    const res = await fn();
    toast(typeof res === "string" ? res : label);
    await refreshAll();
  } catch (e) {
    toast("Fehler: " + e.message, true);
  } finally {
    state.busy = false;
    document.body.style.cursor = "";
  }
}

// ─── Auth ───────────────────────────────────────────────────────────────────
async function boot() {
  const { data } = await sb.auth.getSession();
  state.session = data.session;
  sb.auth.onAuthStateChange((_e, session) => {
    const changed = (session?.user?.id || null) !== (state.session?.user?.id || null);
    state.session = session;
    if (changed) start();
  });
  start();
}

async function start() {
  stopPolling();
  if (!state.session) return renderLogin();
  try {
    state.isAdmin = await rpc("tp_is_admin");
  } catch {
    state.isAdmin = false;
  }
  if (!state.isAdmin) return renderNoAccess();
  renderShell();
  await refreshAll();
  startPolling();
}

function renderLogin(error = "") {
  $("#app").innerHTML = `
    <div class="card login">
      <h1 class="with-ic"><span class="app-mark">${ic("globe")}</span>Übersetzung</h1>
      <p class="muted">Jugendkompass · Admin-Panel für automatische Übersetzungen</p>
      <form id="login">
        <label>E-Mail</label>
        <input class="input" type="email" name="email" required autocomplete="username" value="${esc(localGet("tp_email") || "")}">
        <label>Passwort</label>
        <input class="input" type="password" name="password" autocomplete="current-password">
        <button class="btn primary" type="submit">Anmelden</button>
        <button class="btn" type="button" id="magic">Login-Link per E-Mail senden</button>
        ${error ? `<div class="err">${esc(error)}</div>` : ""}
        <p class="muted small" style="margin-top:16px">Zugang nur für Admins der Jugendkompass-App (gleiche Zugangsdaten wie im Admin-Bereich).</p>
      </form>
    </div>`;
  $("#login").addEventListener("submit", async (e) => {
    e.preventDefault();
    const f = new FormData(e.target);
    localSet("tp_email", f.get("email"));
    if (!f.get("password")) return renderLogin("Bitte Passwort eingeben oder Login-Link anfordern.");
    const { error: err } = await sb.auth.signInWithPassword({ email: f.get("email"), password: f.get("password") });
    if (err) renderLogin(err.message === "Invalid login credentials" ? "E-Mail oder Passwort falsch." : err.message);
  });
  $("#magic").addEventListener("click", async () => {
    const email = $("#login [name=email]").value.trim();
    if (!email) return renderLogin("Bitte E-Mail eingeben.");
    localSet("tp_email", email);
    const { error: err } = await sb.auth.signInWithOtp({
      email, options: { shouldCreateUser: false, emailRedirectTo: location.origin + location.pathname },
    });
    if (err) return renderLogin(err.message);
    toast("Login-Link wurde an " + email + " gesendet.");
  });
}

function renderNoAccess() {
  $("#app").innerHTML = `
    <div class="card login">
      <h1>Kein Zugriff</h1>
      <p class="muted">Der Account <b>${esc(state.session?.user?.email)}</b> ist kein Admin (users.role ≠ 'admin').</p>
      <button class="btn" id="logout">Abmelden</button>
    </div>`;
  $("#logout").onclick = () => sb.auth.signOut();
}

// ─── Polling ────────────────────────────────────────────────────────────────
function startPolling() {
  stopPolling();
  pollTimer = setInterval(() => {
    if (document.hidden) return;
    refreshAll(true);
  }, CFG.pollMs);
}
function stopPolling() { if (pollTimer) clearInterval(pollTimer); pollTimer = null; }
document.addEventListener("visibilitychange", () => { if (!document.hidden && state.isAdmin) refreshAll(true); });

async function refreshAll(silent = false) {
  try {
    state.overview = await rpc("tp_overview");
    state.overviewError = null;
    state.lastPoll = new Date();
  } catch (e) {
    state.overviewError = e.message;
    if (!silent) toast("Fehler beim Laden: " + e.message, true);
  }
  renderHeader();
  if (state.tab === "overview") renderOverview();
  if (state.tab === "jobs") await loadJobs();
  if (state.tab === "logs") await loadLogs();
  if (state.tab === "credits") renderCredits();
  if (state.tab === "audio") {
    if (state.audios.rows === null) await loadAudios();
    else if (!state._audioTick || Date.now() - state._audioTick > 10000) { state._audioTick = Date.now(); await refreshAudioJobs(); }
  }
  if (state.tab === "images" && (!state._imgTick || Date.now() - state._imgTick > 20000) && !$("#cmp-bg")) { state._imgTick = Date.now(); await loadImages(); }
  if (state.tab === "edit" && !state.content.loaded) await loadContent();
  if (state.drawer) await refreshDrawer();
}

// ─── Shell ──────────────────────────────────────────────────────────────────
function renderShell() {
  $("#app").innerHTML = `
    <header class="topbar"><div class="topbar-inner">
      <div class="brand"><span class="app-mark">${ic("globe")}</span>Übersetzung <small>Jugendkompass</small></div>
      <nav class="tabs" id="tabs"></nav>
      <div class="spacer"></div>
      <span class="live" id="live"><span class="dot off"></span> verbinde …</span>
      <div class="user"><span class="email" title="${esc(state.session.user.email)}">${esc(state.session.user.email)}</span><button class="btn sm icon-only" id="logout" aria-label="Abmelden" title="Abmelden">${ic("log-out")}</button></div>
    </div></header>
    <main id="main"></main>`;
  $("#logout").onclick = () => sb.auth.signOut();
  switchTab(state.tab, true);
}

function switchTab(tab, initial = false) {
  state.tab = tab;
  localSet("tp_tab", tab);
  const main = $("#main");
  main.innerHTML = "";
  if (tab === "overview") main.innerHTML = `<div id="ov"></div>`;
  if (tab === "jobs") renderJobsShell();
  if (tab === "logs") renderLogsShell();
  if (tab === "audio") renderAudioShell();
  if (tab === "images") renderImageShell();
  if (tab === "edit") { state.content.loaded = false; renderContentShell(); }
  if (tab === "credits") main.innerHTML = `<div id="cr"></div>`;
  renderHeader();
  if (!initial) refreshAll(true);
}

function totals() {
  const q = state.overview?.queue || [];
  const t = { pending: 0, processing: 0, completed: 0, failed: 0 };
  for (const r of q) for (const k of Object.keys(t)) t[k] += Number(r[k] || 0);
  t.all = t.pending + t.processing + t.completed + t.failed;
  return t;
}

function workerState() {
  const o = state.overview;
  if (!o) return { cls: "off", text: "verbinde …" };
  const t = totals();
  if (o.credit_error && t.failed + t.pending > 0 && t.processing === 0) return { cls: "bad", text: "Guthaben leer" };
  if (o.auth_error) return { cls: "bad", text: "API-Key ungültig" };
  if (t.processing > 0) return { cls: "", text: `übersetzt gerade (${t.processing})` };
  if (t.pending > 0) return { cls: "", text: `${fmtN(t.pending)} in Warteschlange` };
  return { cls: "", text: "bereit" };
}

function renderHeader() {
  const t = totals();
  const tabs = [
    ["overview", "Übersicht"],
    ["jobs", "Jobs", t.failed],
    ["edit", "Bearbeiten"],
    ["logs", "Logs"],
    ["audio", "Audios"],
    ["images", "Bilder"],
    ["credits", "Claude-Guthaben", state.overview?.credit_error ? "!" : 0],
  ];
  const nav = $("#tabs");
  if (!nav) return;
  nav.innerHTML = tabs.map(([k, l, c]) =>
    `<button class="tab ${state.tab === k ? "active" : ""}" data-tab="${k}">${l}${c ? `<span class="count">${typeof c === "number" ? fmtN(c) : c}</span>` : ""}</button>`).join("");
  nav.querySelectorAll("[data-tab]").forEach((b) => (b.onclick = () => switchTab(b.dataset.tab)));
  const ws = workerState();
  $("#live").innerHTML = state.overviewError
    ? `<span class="dot bad"></span> Verbindung gestört`
    : `<span class="dot ${ws.cls}"></span> live · ${esc(ws.text)} · ${state.lastPoll ? state.lastPoll.toLocaleTimeString("de-DE") : ""}`;
}

// ─── Banner ─────────────────────────────────────────────────────────────────
function creditBanner() {
  const o = state.overview;
  if (!o) return "";
  const t = totals();
  if (o.credit_error) {
    return `<div class="banner bad">
      <div class="icon">${ic("credit-card")}</div>
      <div class="txt"><strong>Claude-Guthaben ist aufgebraucht</strong>
        Die Anthropic-API lehnt Anfragen ab („credit balance is too low“). ${fmtN(t.failed)} Jobs sind deshalb fehlgeschlagen.
        Guthaben aufladen und danach alle fehlgeschlagenen Übersetzungen neu starten.</div>
      <div class="btn-row">
        <a class="btn solid-danger" href="${CFG.billingUrl}" target="_blank" rel="noopener">Guthaben aufladen${ic("external-link","trail")}</a>
        <button class="btn" data-act="retry-all">${ic("rotate-cw")}Alle fehlgeschlagenen neu starten</button>
      </div></div>`;
  }
  if (o.auth_error) {
    return `<div class="banner bad"><div class="icon">${ic("key-round")}</div>
      <div class="txt"><strong>API-Key ungültig oder fehlt</strong>Den Secret <span class="mono">ANTHROPIC_API_KEY</span> der Edge Function <span class="mono">process-translation-jobs</span> im Supabase-Dashboard prüfen.</div>
      <div class="btn-row"><a class="btn" target="_blank" rel="noopener" href="https://supabase.com/dashboard/project/vdcdibvclaulqxfjyzpq/functions/secrets">Supabase Secrets${ic("external-link","trail")}</a>
      <button class="btn" data-act="retry-all">${ic("rotate-cw")}Fehlgeschlagene neu starten</button></div></div>`;
  }
  if (t.failed > 0) {
    return `<div class="banner warn"><div class="icon">${ic("triangle-alert")}</div>
      <div class="txt"><strong>${fmtN(t.failed)} Übersetzungen fehlgeschlagen</strong>Details im Tab „Jobs“ (Filter: fehlgeschlagen).</div>
      <div class="btn-row"><button class="btn" data-act="retry-all">${ic("rotate-cw")}Alle neu starten</button>
      <button class="btn" data-act="goto-failed">Ansehen</button></div></div>`;
  }
  if (t.pending + t.processing === 0 && t.all > 0) {
    return `<div class="banner ok"><div class="icon">${ic("circle-check")}</div><div class="txt"><strong>Alles übersetzt</strong>Neue oder geänderte Inhalte werden automatisch übersetzt.</div></div>`;
  }
  return "";
}

function bindCommonActions(root) {
  root.querySelectorAll("[data-act]").forEach((el) => {
    const a = el.dataset.act;
    el.onclick = () => {
      const type = el.dataset.type || null;
      if (a === "retry-all") return action("", async () => `${fmtN(await rpc("tp_retry_failed", { p_content_type: null }))} Jobs neu gestartet`);
      if (a === "retry-type") return action("", async () => `${fmtN(await rpc("tp_retry_failed", { p_content_type: type }))} Jobs neu gestartet`);
      if (a === "run-now") return action("", async () => { await rpc("tp_run_now"); return "Worker angestoßen"; });
      if (a === "rerun-type") {
        return action("", async () => `${typeText(type)}: ${fmtN(await rpc("tp_rerun_type", { p_content_type: type, p_force: false }))} Jobs eingereiht`);
      }
      if (a === "force-type") {
        if (!confirm(`${typeText(type)} komplett neu übersetzen?\n\nAlle automatischen Übersetzungen dieser Kategorie werden neu erzeugt (verbraucht Claude-Guthaben). Manuelle Korrekturen bleiben erhalten. Bis zur neuen Übersetzung bleiben die alten sichtbar.`)) return;
        return action("", async () => `${typeText(type)}: ${fmtN(await rpc("tp_rerun_type", { p_content_type: type, p_force: true }))} Jobs neu übersetzen`);
      }
      if (a === "goto-failed") { state.jobs.status = "failed"; state.jobs.type = type || ""; state.jobs.offset = 0; return switchTab("jobs"); }
      if (a === "goto-type") { state.jobs.status = ""; state.jobs.type = type; state.jobs.offset = 0; return switchTab("jobs"); }
    };
  });
}

// ─── Overview ───────────────────────────────────────────────────────────────
function renderOverview() {
  const root = $("#ov");
  if (!root) return;
  const o = state.overview;
  if (!o) { root.innerHTML = `<div class="empty">${state.overviewError ? esc(state.overviewError) : "Lade …"}</div>`; return; }
  const t = totals();
  const langs = (o.languages || []).filter((l) => l.active).map((l) => l.code);
  const queueBy = Object.fromEntries((o.queue || []).map((q) => [q.content_type, q]));

  root.innerHTML = `
    ${creditBanner()}
    <div class="grid kpis">
      <div class="card kpi"><div class="label">Jobs gesamt</div><div class="value">${fmtN(t.all)}</div></div>
      <div class="card kpi ok"><div class="label">Fertig</div><div class="value">${fmtN(t.completed)}</div></div>
      <div class="card kpi warn"><div class="label">Wartend</div><div class="value">${fmtN(t.pending)}</div></div>
      <div class="card kpi info"><div class="label">In Arbeit</div><div class="value">${fmtN(t.processing)}</div></div>
      <div class="card kpi bad"><div class="label">Fehlgeschlagen</div><div class="value">${fmtN(t.failed)}</div></div>
      <div class="card kpi"><div class="label">Fertig (24 h)</div><div class="value">${fmtN(o.completed_24h)}</div></div>
    </div>
    <div class="section-title">
      <div><h2>Inhaltskategorien</h2><p>Abdeckung je Sprache · zuletzt fertig: ${esc(ago(o.last_completed_at))} · letzte Aktivität: ${esc(ago(o.last_activity_at))}</p></div>
      <div class="spacer"></div>
      <div class="btn-row">
        <button class="btn" data-act="run-now">${ic("play")}Worker jetzt starten</button>
        <button class="btn primary" data-act="retry-all" ${t.failed ? "" : "disabled"}>${ic("rotate-cw")}Alle Fehlgeschlagenen neu</button>
      </div>
    </div>
    <div class="grid types">
      ${(o.coverage || []).map((c) => typeCard(c, queueBy[c.content_type] || {}, langs)).join("")}
      ${audioCard(o.audio, langs)}
    </div>
    <p class="muted small" style="margin-top:18px">Zielsprachen: ${langs.map((l) => esc(langName(l))).join(", ")} · Quellsprache: Deutsch.
      „Neu prüfen“ übersetzt nur fehlende oder geänderte Felder (günstig). „Komplett neu“ erzeugt alle automatischen Übersetzungen der Kategorie neu.</p>`;
  bindCommonActions(root);
}

function typeCard(c, q, langs) {
  const total = Number(c.total || 0);
  const rows = langs.map((l) => {
    const n = Number(c.languages?.[l] || 0);
    const pct = total ? Math.min(100, Math.round((n / total) * 100)) : 0;
    return `<div class="lang-row"><span class="code">${esc(l)}</span>
      <div class="bar"><span class="${pct >= 100 ? "full" : ""}" style="width:${pct}%"></span></div>
      <span class="pct">${fmtN(n)}/${fmtN(total)}</span></div>`;
  }).join("");
  const type = c.content_type;
  return `<div class="card card-pad">
    <div class="type-head"><div class="name">${typeLabel(type)}</div><span class="muted small">${fmtN(total)} Einträge</span></div>
    <div class="chips">
      ${q.processing ? `<span class="chip info">${fmtN(q.processing)} in Arbeit</span>` : ""}
      ${q.pending ? `<span class="chip warn">${fmtN(q.pending)} wartend</span>` : ""}
      ${q.failed ? `<span class="chip bad">${fmtN(q.failed)} fehlgeschlagen</span>` : ""}
      ${q.completed ? `<span class="chip ok">${fmtN(q.completed)} fertig</span>` : ""}
      ${!q.processing && !q.pending && !q.failed && !q.completed ? `<span class="chip">keine Jobs</span>` : ""}
    </div>
    ${rows}
    ${q.failed && q.last_error ? `<div class="small" style="color:var(--bad);margin-top:8px">${esc(shortError(q.last_error))}</div>` : ""}
    <div class="type-actions">
      <button class="btn sm" data-act="retry-type" data-type="${type}" ${q.failed ? "" : "disabled"}>${ic("rotate-cw")}Fehlgeschlagene</button>
      <button class="btn sm" data-act="rerun-type" data-type="${type}">Neu prüfen</button>
      <button class="btn sm danger" data-act="force-type" data-type="${type}">Komplett neu</button>
      <button class="btn sm" data-act="goto-type" data-type="${type}">Jobs${ic("arrow-right","trail")}</button>
    </div>
  </div>`;
}

function audioCard(a, langs) {
  if (!a) return "";
  const total = Number(a.total || 0);
  return `<div class="card card-pad">
    <div class="type-head"><div class="name">${ic("headphones")}Audios (vertont)</div><span class="muted small">${fmtN(total)} Audios</span></div>
    <div class="chips"><span class="chip">manuell hochgeladen</span></div>
    ${langs.map((l) => {
      const n = Number(a.languages?.[l] || 0);
      const pct = total ? Math.min(100, Math.round((n / total) * 100)) : 0;
      return `<div class="lang-row"><span class="code">${esc(l)}</span><div class="bar"><span class="${pct >= 100 ? "full" : ""}" style="width:${pct}%"></span></div><span class="pct">${fmtN(n)}/${fmtN(total)}</span></div>`;
    }).join("")}
    <div class="type-actions"><button class="btn sm" onclick="document.querySelector('[data-tab=audio]').click()">Audios verwalten${ic("arrow-right","trail")}</button></div>
  </div>`;
}

// ─── Jobs ───────────────────────────────────────────────────────────────────
function renderJobsShell() {
  const j = state.jobs;
  $("#main").innerHTML = `
    <div id="jobs-banner"></div>
    <div class="toolbar">
      <select class="input" id="f-status">
        <option value="">Alle Status</option>
        ${["failed", "pending", "processing", "completed"].map((s) => `<option value="${s}" ${j.status === s ? "selected" : ""}>${STATUS_LABEL[s]}</option>`).join("")}
      </select>
      <select class="input" id="f-type">
        <option value="">Alle Kategorien</option>
        ${Object.keys(TYPES).map((t) => `<option value="${t}" ${j.type === t ? "selected" : ""}>${esc(typeText(t))}</option>`).join("")}
      </select>
      <input class="input" id="f-q" placeholder="Suche: Titel, ID oder Fehlertext" value="${esc(j.q)}" style="flex:1;min-width:200px">
      <button class="btn" id="f-retry">${ic("rotate-cw")}Gefilterte Fehlgeschlagene neu</button>
    </div>
    <div class="card"><div class="table-wrap" id="jobs-table"><div class="empty">Lade …</div></div></div>`;
  $("#f-status").onchange = (e) => { j.status = e.target.value; j.offset = 0; loadJobs(); };
  $("#f-type").onchange = (e) => { j.type = e.target.value; j.offset = 0; loadJobs(); };
  let deb;
  $("#f-q").oninput = (e) => { clearTimeout(deb); deb = setTimeout(() => { j.q = e.target.value.trim(); j.offset = 0; loadJobs(); }, 300); };
  $("#f-retry").onclick = () => action("", async () => `${fmtN(await rpc("tp_retry_failed", { p_content_type: j.type || null }))} Jobs neu gestartet`);
}

async function loadJobs() {
  const j = state.jobs;
  const b = $("#jobs-banner");
  if (b) { b.innerHTML = creditBanner(); bindCommonActions(b); }
  try {
    const rows = await rpc("tp_jobs", {
      p_status: j.status || null, p_content_type: j.type || null, p_search: j.q || null, p_limit: j.limit, p_offset: j.offset,
    });
    j.rows = rows || [];
    j.total = j.rows[0]?.total_count ?? 0;
  } catch (e) {
    const el = $("#jobs-table");
    if (el) el.innerHTML = `<div class="empty">Fehler: ${esc(e.message)}</div>`;
    return;
  }
  renderJobsTable();
}

function renderJobsTable() {
  const el = $("#jobs-table");
  if (!el) return;
  const j = state.jobs;
  if (!j.rows.length) { el.innerHTML = `<div class="empty">Keine Jobs für diesen Filter.</div>`; return; }
  el.innerHTML = `<table>
    <thead><tr><th>Status</th><th>Kategorie</th><th>Inhalt</th><th>Versuche</th><th>Aktualisiert</th><th></th></tr></thead>
    <tbody>${j.rows.map((r, i) => `
      <tr class="click" data-i="${i}">
        <td>${statusChip(r.status)}</td>
        <td class="small">${typeLabel(r.content_type)}</td>
        <td><div class="title">${esc(r.title)}</div>
          ${r.last_error ? `<div class="err">${esc(shortError(r.last_error))}</div>` : ""}
          ${r.status === "pending" && r.next_retry_at && new Date(r.next_retry_at) > new Date() ? `<div class="small muted">nächster Versuch ${esc(ago(r.next_retry_at))}</div>` : ""}</td>
        <td class="small">${r.attempts}</td>
        <td class="small muted" title="${esc(fmtTime(r.updated_at))}">${esc(ago(r.updated_at))}</td>
        <td><button class="btn sm" data-rerun="${i}" aria-label="Neu übersetzen" title="Neu übersetzen">${ic("rotate-cw")}</button></td>
      </tr>`).join("")}</tbody></table>
    <div class="pager">
      <span class="muted small">${fmtN(j.offset + 1)}–${fmtN(Math.min(j.offset + j.limit, j.total))} von ${fmtN(j.total)}</span>
      <button class="btn sm" id="pg-prev" aria-label="Vorherige Seite" ${j.offset === 0 ? "disabled" : ""}>${ic("arrow-left")}</button>
      <button class="btn sm" id="pg-next" aria-label="Nächste Seite" ${j.offset + j.limit >= j.total ? "disabled" : ""}>${ic("arrow-right")}</button>
    </div>`;
  el.querySelectorAll("tr[data-i]").forEach((tr) => (tr.onclick = (e) => {
    if (e.target.closest("[data-rerun]")) return;
    openDrawer(j.rows[Number(tr.dataset.i)]);
  }));
  el.querySelectorAll("[data-rerun]").forEach((b) => (b.onclick = () => {
    const r = j.rows[Number(b.dataset.rerun)];
    action("", async () => { await rpc("tp_rerun_record", { p_content_type: r.content_type, p_record_id: r.record_id, p_force: false }); return "Neu eingereiht"; });
  }));
  $("#pg-prev").onclick = () => { j.offset = Math.max(0, j.offset - j.limit); loadJobs(); };
  $("#pg-next").onclick = () => { j.offset += j.limit; loadJobs(); };
}

// ─── Drawer (job detail) ────────────────────────────────────────────────────
async function openDrawer(job) {
  state.drawer = { job, translations: null, events: null };
  renderDrawer();
  await refreshDrawer();
}
async function refreshDrawer() {
  const d = state.drawer;
  if (!d) return;
  const [tr, ev, jobRows] = await Promise.all([
    rpc("tp_record_translations", { p_content_type: d.job.content_type, p_record_id: d.job.record_id }).catch(() => []),
    sb.from("translation_events").select("*").eq("content_type", d.job.content_type).eq("record_id", d.job.record_id)
      .order("created_at", { ascending: false }).limit(50).then((r) => r.data || []),
    rpc("tp_jobs", { p_status: null, p_content_type: d.job.content_type, p_search: d.job.record_id, p_limit: 1, p_offset: 0 }).catch(() => []),
  ]);
  if (state.drawer !== d) return;
  if (jobRows?.[0]) d.job = jobRows[0];
  d.translations = tr;
  d.events = ev;
  renderDrawer();
}
function closeDrawer() { state.drawer = null; $("#drawer")?.remove(); }
document.addEventListener("keydown", (e) => {
  if (e.key !== "Escape") return;
  if (state.editor) return closeEditor();
  closeDrawer();
});

function renderDrawer() {
  const d = state.drawer;
  if (!d) return;
  let el = $("#drawer");
  if (!el) {
    el = document.createElement("div");
    el.id = "drawer";
    el.className = "overlay";
    el.onclick = (e) => { if (e.target === el) closeDrawer(); };
    document.body.appendChild(el);
  }
  const prevScroll = el.querySelector(".drawer")?.scrollTop || 0;
  const j = d.job;
  const byLang = {};
  for (const t of d.translations || []) (byLang[t.language] ||= []).push(t);
  el.innerHTML = `<div class="drawer">
    <button class="btn sm icon-only close" id="dr-close" aria-label="Schließen">${ic("x")}</button>
    <div class="muted small">${typeLabel(j.content_type)} · Job #${j.id}</div>
    <h2>${esc(j.title)}</h2>
    <div style="margin-top:6px">${statusChip(j.status)}</div>
    <div class="btn-row" style="margin-top:14px">
      <button class="btn primary" id="dr-edit">${ic("square-pen")}Übersetzungen bearbeiten</button>
      <button class="btn" id="dr-rerun">${ic("rotate-cw")}Neu übersetzen (nur Geändertes)</button>
      <button class="btn danger" id="dr-force">Komplett neu übersetzen</button>
    </div>
    <dl class="kv">
      <dt>Datensatz-ID</dt><dd class="mono">${esc(j.record_id)}</dd>
      <dt>Versuche</dt><dd>${j.attempts} · Revision ${j.revision}</dd>
      <dt>Aktualisiert</dt><dd>${esc(fmtTime(j.updated_at))} (${esc(ago(j.updated_at))})</dd>
      <dt>Fertig seit</dt><dd>${esc(fmtTime(j.completed_at))}</dd>
      ${j.status === "pending" ? `<dt>Nächster Versuch</dt><dd>${esc(fmtTime(j.next_retry_at))}</dd>` : ""}
      ${j.locked_by ? `<dt>Worker</dt><dd class="mono">${esc(j.locked_by)}</dd>` : ""}
    </dl>
    ${j.last_error ? `<h3>Letzter Fehler</h3><pre class="log">${esc(j.last_error)}</pre>` : ""}
    <h3 style="margin-top:20px">Übersetzungen</h3>
    ${d.translations === null ? `<div class="muted">Lade …</div>` : Object.keys(byLang).length === 0 ? `<div class="empty-create"><div class="muted">Für diesen Eintrag gibt es noch keine Übersetzung.</div><button class="btn primary sm" id="dr-create">${ic("plus")}Übersetzung erstellen</button></div>` :
      Object.entries(byLang).map(([lang, fields]) => `<div class="tr-block"><header><span>${esc(langName(lang))}</span><span class="muted small">${esc(ago(fields[0].updated_at))}</span></header>
        ${fields.map((f) => `<div class="f"><b>${esc(f.field_name)} ${f.status === "manual" ? "· manuell" : ""}</b><div>${esc(f.value)}</div></div>`).join("")}</div>`).join("")}
    <h3 style="margin-top:20px">Verlauf</h3>
    ${d.events === null ? `<div class="muted">Lade …</div>` : d.events.length === 0 ? `<div class="muted small">Keine Einträge (Verlauf wird seit Einrichtung des Panels aufgezeichnet).</div>` :
      `<table><tbody>${d.events.map((e) => `<tr><td class="small muted" style="white-space:nowrap">${esc(fmtTime(e.created_at))}</td><td>${statusChip(e.event)}</td><td class="small">${esc(shortError(e.message) || "")}</td></tr>`).join("")}</tbody></table>`}
  </div>`;
  el.querySelector(".drawer").scrollTop = prevScroll;
  $("#dr-close").onclick = closeDrawer;
  $("#dr-edit").onclick = () => openEditor(j.content_type, j.record_id, j.title);
  const cr = $("#dr-create");
  if (cr) cr.onclick = () => openEditor(j.content_type, j.record_id, j.title);
  $("#dr-rerun").onclick = () => action("", async () => { await rpc("tp_rerun_record", { p_content_type: j.content_type, p_record_id: j.record_id, p_force: false }); await refreshDrawer(); return "Neu eingereiht"; });
  $("#dr-force").onclick = () => {
    if (!confirm("Alle automatischen Übersetzungen dieses Eintrags neu erzeugen?")) return;
    action("", async () => { await rpc("tp_rerun_record", { p_content_type: j.content_type, p_record_id: j.record_id, p_force: true }); await refreshDrawer(); return "Wird komplett neu übersetzt"; });
  };
}

// ─── Content list (manual editing entry point) ─────────────────────────────
function renderContentShell() {
  const c = state.content;
  $("#main").innerHTML = `
    <div class="banner info">
      <div class="icon">${ic("square-pen")}</div>
      <div class="txt"><strong>Übersetzungen manuell eintragen</strong>Beitrag wählen, Sprache wählen, Text eintragen und speichern.
      Manuell gespeicherte Felder werden von der automatischen Übersetzung <b>nie überschrieben</b> – über „Automatisch“ lässt sich das jederzeit wieder aufheben.</div>
    </div>
    <div class="toolbar">
      <select class="input" id="c-type">
        <option value="">Alle Kategorien</option>
        ${Object.keys(TYPES).map((t) => `<option value="${t}" ${c.type === t ? "selected" : ""}>${esc(typeText(t))}</option>`).join("")}
      </select>
      <input class="input" id="c-q" placeholder="Titel oder ID suchen" value="${esc(c.q)}" style="flex:1;min-width:200px">
    </div>
    <div class="card"><div class="table-wrap" id="content-table"><div class="empty">Lade …</div></div></div>
    <p class="muted small" style="margin-top:12px">Legende: <span class="lp full">EN</span> vollständig ·
      <span class="lp part">EN</span> teilweise · <span class="lp none">EN</span> fehlt · <span class="lp full">EN${ic("pencil","xs")}</span> enthält manuelle Übersetzung</p>`;
  $("#c-type").onchange = (e) => { c.type = e.target.value; c.offset = 0; loadContent(); };
  let deb;
  $("#c-q").oninput = (e) => { clearTimeout(deb); deb = setTimeout(() => { c.q = e.target.value.trim(); c.offset = 0; loadContent(); }, 300); };
}

async function loadContent() {
  const c = state.content;
  try {
    const rows = await rpc("tp_content_list", { p_content_type: c.type || null, p_search: c.q || null, p_limit: c.limit, p_offset: c.offset });
    c.rows = rows || [];
    c.total = c.rows[0]?.total_count ?? 0;
    c.loaded = true;
  } catch (e) {
    const el = $("#content-table");
    if (el) el.innerHTML = `<div class="empty">Fehler: ${esc(e.message)}${/tp_content_list/.test(e.message) ? "<br><span class='small'>Migration <span class='mono'>20261110120000_translation_manual_edit.sql</span> ist noch nicht eingespielt.</span>" : ""}</div>`;
    return;
  }
  renderContentTable();
}

function renderContentTable() {
  const el = $("#content-table");
  if (!el) return;
  const c = state.content;
  const langs = activeLangs();
  if (!c.rows.length) { el.innerHTML = `<div class="empty">Keine Einträge gefunden.</div>`; return; }
  el.innerHTML = `<table>
    <thead><tr><th>Kategorie</th><th>Inhalt</th><th>Sprachen</th><th></th></tr></thead>
    <tbody>${c.rows.map((r, i) => `
      <tr class="click" data-i="${i}">
        <td class="small" style="white-space:nowrap">${typeLabel(r.content_type)}</td>
        <td><div class="title">${esc(r.title)}</div><div class="small muted">${esc(r.created_at ? fmtTime(r.created_at) : "")}</div></td>
        <td><div class="lps">${langs.map((l) => {
          const x = r.langs?.[l] || { n: 0, manual: 0 };
          const cls = x.n >= r.field_count && r.field_count > 0 ? "full" : x.n > 0 ? "part" : "none";
          return `<span class="lp ${cls}" title="${esc(langName(l))}: ${x.n}/${r.field_count} Felder${x.manual ? `, ${x.manual} manuell` : ""}">${esc(l.toUpperCase())}${x.manual ? ic("pencil", "xs") : ""}</span>`;
        }).join("")}</div></td>
        <td>${Object.keys(r.langs || {}).length ? `<button class="btn sm">${ic("square-pen")}Bearbeiten</button>` : `<button class="btn sm primary">${ic("plus")}Erstellen</button>`}</td>
      </tr>`).join("")}</tbody></table>
    <div class="pager">
      <span class="muted small">${fmtN(c.offset + 1)}–${fmtN(Math.min(c.offset + c.limit, c.total))} von ${fmtN(c.total)}</span>
      <button class="btn sm" id="cp-prev" aria-label="Vorherige Seite" ${c.offset === 0 ? "disabled" : ""}>${ic("arrow-left")}</button>
      <button class="btn sm" id="cp-next" aria-label="Nächste Seite" ${c.offset + c.limit >= c.total ? "disabled" : ""}>${ic("arrow-right")}</button>
    </div>`;
  el.querySelectorAll("tr[data-i]").forEach((tr) => (tr.onclick = () => {
    const r = c.rows[Number(tr.dataset.i)];
    openEditor(r.content_type, r.record_id, r.title);
  }));
  $("#cp-prev").onclick = () => { c.offset = Math.max(0, c.offset - c.limit); loadContent(); };
  $("#cp-next").onclick = () => { c.offset += c.limit; loadContent(); };
}

// ─── Editor (manual translation per record / language / field) ─────────────
const RTL = new Set(["he", "ar"]);

async function openEditor(type, recordId, title) {
  const langs = activeLangs();
  state.editor = {
    type, recordId, title, lang: localGet("tp_edit_lang") && langs.includes(localGet("tp_edit_lang")) ? localGet("tp_edit_lang") : langs[0],
    source: null, translations: {}, drafts: {}, preview: {}, error: null, saving: false,
  };
  renderEditor();
  await loadEditor();
}

async function loadEditor() {
  const ed = state.editor;
  if (!ed) return;
  try {
    const data = await rpc("tp_record_editor", { p_content_type: ed.type, p_record_id: ed.recordId });
    if (state.editor !== ed) return;
    ed.source = data.source || [];
    ed.translations = {};
    for (const t of data.translations || []) ed.translations[`${t.language}|${t.field_name}`] = t;
    ed.error = null;
  } catch (e) {
    ed.error = e.message;
  }
  renderEditor();
}

function editorDirty(ed = state.editor) {
  return ed ? Object.keys(ed.drafts).filter((k) => ed.drafts[k] !== (ed.translations[k]?.value ?? "")) : [];
}

function closeEditor(force = false) {
  const ed = state.editor;
  if (!ed) return;
  const dirty = editorDirty(ed);
  if (!force && dirty.length && !confirm(`${dirty.length} ungespeicherte Änderung(en) verwerfen?`)) return;
  state.editor = null;
  $("#editor")?.remove();
  if (state.tab === "edit") loadContent();
  if (state.drawer) refreshDrawer();
}

function renderEditor() {
  const ed = state.editor;
  if (!ed) return;
  let el = $("#editor");
  if (!el) {
    el = document.createElement("div");
    el.id = "editor";
    el.className = "overlay";
    el.style.zIndex = 45;
    el.onclick = (e) => { if (e.target === el) closeEditor(); };
    document.body.appendChild(el);
  }
  const prevScroll = el.querySelector(".drawer")?.scrollTop || 0;
  const langs = activeLangs();
  const dirty = editorDirty(ed);
  const langInfo = (l) => {
    if (!ed.source) return "";
    const done = ed.source.filter((f) => ed.translations[`${l}|${f.field_name}`]).length;
    const man = ed.source.filter((f) => ed.translations[`${l}|${f.field_name}`]?.status === "manual").length;
    const d = dirty.some((k) => k.startsWith(l + "|"));
    return `<span class="lp ${done >= ed.source.length && ed.source.length ? "full" : done ? "part" : "none"}">${done}/${ed.source.length}${man ? ic("pencil", "xs") : ""}</span>${d ? `<span class="dirty-dot" title="Ungespeicherte Änderungen"></span>` : ""}`;
  };

  let body;
  if (ed.error) body = `<div class="empty">Fehler: ${esc(ed.error)}${/tp_record_editor/.test(ed.error) ? "<br><span class='small'>Migration <span class='mono'>20261110120000_translation_manual_edit.sql</span> ist noch nicht eingespielt.</span>" : ""}</div>`;
  else if (!ed.source) body = `<div class="muted">Lade …</div>`;
  else if (!ed.source.length) body = `<div class="empty">Dieser Eintrag hat keine übersetzbaren Texte.</div>`;
  else body = (ed.source.some((f) => ed.translations[`${ed.lang}|${f.field_name}`]) ? "" : createPanel(ed)) + ed.source.map((f) => fieldEditor(ed, f)).join("");

  el.innerHTML = `<div class="drawer editor">
    <button class="btn sm icon-only close" data-ed="close" aria-label="Schließen">${ic("x")}</button>
    <div class="muted small">${typeLabel(ed.type)} · Übersetzungen bearbeiten</div>
    <h2>${esc(ed.title || ed.recordId)}</h2>
    <div class="lang-tabs">
      ${langs.map((l) => `<button class="tab ${ed.lang === l ? "active" : ""}" data-lang="${l}">${esc(LANGS[l] || l)} ${langInfo(l)}</button>`).join("")}
    </div>
    <div class="editor-bar">
      <span class="muted small">Quelle: Deutsch → Ziel: <b>${esc(langName(ed.lang))}</b></span>
      <div class="spacer"></div>
${ed.source?.some((f) => ed.translations[`${ed.lang}|${f.field_name}`]) ? `<button class="btn sm" data-ed="reset-lang" title="Alle manuellen Texte dieser Sprache verwerfen und automatisch neu übersetzen">${ic("rotate-ccw")}Sprache automatisch</button>` : ""}
      <button class="btn sm primary" data-ed="save-lang" ${dirty.some((k) => k.startsWith(ed.lang + "|")) ? "" : "disabled"}>${ic("save")}Alle Änderungen (${esc(ed.lang.toUpperCase())}) speichern</button>
    </div>
    ${body}
  </div>`;
  el.querySelector(".drawer").scrollTop = prevScroll;
  bindEditor(el);
}

function createPanel(ed) {
  const name = LANGS[ed.lang] || ed.lang;
  const started = ed.source.some((f) => (ed.drafts[`${ed.lang}|${f.field_name}`] ?? "").trim());
  return `<div class="create-panel">
    <div class="cp-icon">${ic("file-plus")}</div>
    <div class="cp-txt"><strong>Neue Übersetzung auf ${esc(name)}</strong>
      Für diesen Eintrag gibt es noch keine ${esc(name.toLowerCase())}e Fassung. Text unten selbst eintragen, mit dem deutschen Original als Vorlage beginnen oder Claude übersetzen lassen.</div>
    <div class="btn-row">
      <button class="btn sm primary" data-ed="create-empty">${ic("plus")}Selbst eintragen</button>
      <button class="btn sm" data-ed="create-copy" ${started ? "disabled" : ""}>${ic("copy")}Original als Vorlage</button>
      <button class="btn sm" data-ed="create-auto">${ic("sparkles")}Automatisch übersetzen</button>
    </div>
  </div>`;
}

function fieldEditor(ed, f) {
  const key = `${ed.lang}|${f.field_name}`;
  const tr = ed.translations[key];
  const value = key in ed.drafts ? ed.drafts[key] : tr?.value ?? "";
  const isDirty = key in ed.drafts && ed.drafts[key] !== (tr?.value ?? "");
  const stale = tr?.status === "manual" && tr.source_hash && tr.source_hash !== f.hash;
  const badge = !tr ? `<span class="chip">noch nicht übersetzt</span>`
    : tr.status === "manual" ? `<span class="chip info">${ic("pencil", "xs")}manuell</span>` : `<span class="chip ok">automatisch</span>`;
  const rows = f.kind === "text" ? Math.min(4, Math.max(1, Math.ceil(f.text.length / 70))) : Math.min(18, Math.max(4, Math.ceil(f.text.length / 80)));
  const dir = RTL.has(ed.lang) ? "rtl" : "ltr";
  const preview = f.kind === "html" && ed.preview[key];
  return `<div class="fe" data-field="${esc(f.field_name)}">
    <div class="fe-head">
      <b>${esc(f.label)}</b> ${badge}
      ${isDirty ? `<span class="chip warn">ungespeichert</span>` : ""}
      ${tr ? `<span class="muted small">${esc(ago(tr.updated_at))}</span>` : ""}
    </div>
    ${stale ? `<div class="fe-warn">${ic("triangle-alert")}Der deutsche Originaltext wurde nach dieser manuellen Übersetzung geändert – bitte prüfen.</div>` : ""}
    <div class="fe-grid">
      <div>
        <div class="fe-label">Deutsch (Original)</div>
        <div class="fe-src ${f.kind === "html" ? "mono" : ""}">${esc(f.text)}</div>
      </div>
      <div>
        <div class="fe-label">${esc(LANGS[ed.lang] || ed.lang)}${f.kind === "html" ? " <span class='muted'>(HTML – Tags wie im Original beibehalten)</span>" : ""}</div>
        ${preview
          ? `<iframe class="fe-preview" sandbox="" srcdoc="${esc(`<html dir="${dir}"><body style="font:14px/1.5 system-ui;margin:10px">${value}</body></html>`)}"></iframe>`
          : `<textarea class="input fe-ta ${f.kind === "html" ? "mono" : ""}" dir="${dir}" rows="${rows}" data-key="${esc(key)}" placeholder="Übersetzung eingeben …">${esc(value)}</textarea>`}
      </div>
    </div>
    <div class="fe-actions">
      <button class="btn sm primary" data-save="${esc(f.field_name)}" ${isDirty && value.trim() ? "" : "disabled"}>${tr ? `${ic("save")}Speichern` : `${ic("plus")}Erstellen`}</button>
      ${isDirty ? `<button class="btn sm" data-undo="${esc(f.field_name)}">Änderung verwerfen</button>` : ""}
      <button class="btn sm" data-copy="${esc(f.field_name)}" title="Deutschen Text als Ausgangspunkt übernehmen">${ic("copy")}Original übernehmen</button>
      ${f.kind === "html" ? `<button class="btn sm" data-preview="${esc(f.field_name)}">${preview ? `${ic("pencil")}Bearbeiten` : `${ic("eye")}Vorschau`}</button>` : ""}
      ${tr?.status === "manual" || (tr && !isDirty) ? `<button class="btn sm" data-reset="${esc(f.field_name)}" title="Manuellen Text verwerfen und von Claude neu übersetzen lassen">${ic("rotate-ccw")}Automatisch</button>` : ""}
    </div>
  </div>`;
}

function bindEditor(el) {
  const ed = state.editor;
  el.querySelector('[data-ed="close"]').onclick = () => closeEditor();
  el.querySelectorAll("[data-lang]").forEach((b) => (b.onclick = () => {
    ed.lang = b.dataset.lang;
    localSet("tp_edit_lang", ed.lang);
    el.querySelector(".drawer").scrollTop = 0;
    renderEditor();
  }));
  el.querySelectorAll("textarea[data-key]").forEach((ta) => (ta.oninput = () => {
    const key = ta.dataset.key;
    const wasDirty = key in ed.drafts && ed.drafts[key] !== (ed.translations[key]?.value ?? "");
    ed.drafts[key] = ta.value;
    const isDirty = ta.value !== (ed.translations[key]?.value ?? "");
    const fe = ta.closest(".fe");
    fe.querySelector("[data-save]").disabled = !(isDirty && ta.value.trim());
    if (wasDirty !== isDirty) {
      // re-render to update chips / buttons, keep the caret
      const pos = [ta.selectionStart, ta.selectionEnd];
      renderEditor();
      const n = $(`#editor textarea[data-key="${CSS.escape(key)}"]`);
      if (n) { n.focus(); n.setSelectionRange(pos[0], pos[1]); }
    } else {
      $('#editor [data-ed="save-lang"]').disabled = !editorDirty().some((k) => k.startsWith(ed.lang + "|"));
    }
  }));
  const fieldOf = (name) => ed.source.find((f) => f.field_name === name);
  el.querySelectorAll("[data-save]").forEach((b) => (b.onclick = () => saveFields([b.dataset.save])));
  el.querySelectorAll("[data-undo]").forEach((b) => (b.onclick = () => { delete ed.drafts[`${ed.lang}|${b.dataset.undo}`]; renderEditor(); }));
  el.querySelectorAll("[data-copy]").forEach((b) => (b.onclick = () => {
    const key = `${ed.lang}|${b.dataset.copy}`;
    const cur = key in ed.drafts ? ed.drafts[key] : ed.translations[key]?.value ?? "";
    if (cur.trim() && !confirm("Aktuellen Text durch das deutsche Original ersetzen?")) return;
    ed.drafts[key] = fieldOf(b.dataset.copy).text;
    renderEditor();
  }));
  el.querySelectorAll("[data-preview]").forEach((b) => (b.onclick = () => {
    const key = `${ed.lang}|${b.dataset.preview}`;
    ed.preview[key] = !ed.preview[key];
    renderEditor();
  }));
  el.querySelectorAll("[data-reset]").forEach((b) => (b.onclick = () => resetFields(b.dataset.reset)));
  el.querySelector('[data-ed="save-lang"]').onclick = () =>
    saveFields(editorDirty().filter((k) => k.startsWith(ed.lang + "|")).map((k) => k.split("|").slice(1).join("|")));
  const rl = el.querySelector('[data-ed="reset-lang"]');
  if (rl) rl.onclick = () => resetFields(null);
  const ce = el.querySelector('[data-ed="create-empty"]');
  if (ce) ce.onclick = () => el.querySelector("textarea[data-key]")?.focus();
  const cc = el.querySelector('[data-ed="create-copy"]');
  if (cc) cc.onclick = () => {
    for (const f of ed.source) ed.drafts[`${ed.lang}|${f.field_name}`] = f.text;
    renderEditor();
    el.querySelector("textarea[data-key]")?.focus();
  };
  const ca = el.querySelector('[data-ed="create-auto"]');
  if (ca) ca.onclick = async () => {
    try {
      await rpc("tp_rerun_record", { p_content_type: ed.type, p_record_id: ed.recordId, p_force: false });
      toast("Wird automatisch übersetzt – erscheint in der Regel nach wenigen Sekunden.");
      setTimeout(() => { if (state.editor === ed && !editorDirty(ed).length) loadEditor(); }, 15000);
    } catch (e) { toast("Fehler: " + e.message, true); }
  };
}

async function saveFields(fieldNames) {
  const ed = state.editor;
  if (!ed || ed.saving || !fieldNames.length) return;
  const lang = ed.lang;
  const todo = fieldNames.map((f) => ({ f, key: `${lang}|${f}` })).filter((x) => (ed.drafts[x.key] ?? "").trim());
  if (!todo.length) return toast("Leere Übersetzung kann nicht gespeichert werden – „Automatisch“ verwenden.", true);
  ed.saving = true;
  document.body.style.cursor = "progress";
  let ok = 0;
  try {
    for (const x of todo) {
      await rpc("tp_save_translation", { p_content_type: ed.type, p_record_id: ed.recordId, p_language: lang, p_field_name: x.f, p_value: ed.drafts[x.key] });
      ok++;
    }
    for (const x of todo) delete ed.drafts[x.key];
    toast(`${ok} Feld${ok === 1 ? "" : "er"} (${lang.toUpperCase()}) gespeichert – in der App sofort aktiv.`);
  } catch (e) {
    toast(`Fehler${ok ? ` nach ${ok} gespeicherten Feldern` : ""}: ${e.message}`, true);
  } finally {
    ed.saving = false;
    document.body.style.cursor = "";
  }
  await loadEditor();
}

async function resetFields(fieldName) {
  const ed = state.editor;
  if (!ed) return;
  const lang = ed.lang;
  const what = fieldName ? `das Feld „${ed.source.find((f) => f.field_name === fieldName)?.label || fieldName}“` : `alle Felder`;
  if (!confirm(`${what} in ${LANGS[lang] || lang} wieder automatisch übersetzen lassen?\n\nManuell eingetragener Text wird dabei durch eine neue Claude-Übersetzung ersetzt (bis dahin bleibt der aktuelle Text sichtbar).`)) return;
  try {
    await rpc("tp_reset_translation", { p_content_type: ed.type, p_record_id: ed.recordId, p_language: lang, p_field_name: fieldName });
    for (const k of Object.keys(ed.drafts)) if (k.startsWith(lang + "|") && (!fieldName || k === `${lang}|${fieldName}`)) delete ed.drafts[k];
    toast("Automatische Übersetzung eingereiht.");
  } catch (e) {
    toast("Fehler: " + e.message, true);
  }
  await loadEditor();
  refreshAll(true);
}

window.addEventListener("beforeunload", (e) => { if (editorDirty().length) { e.preventDefault(); e.returnValue = ""; } });

// ─── Logs ───────────────────────────────────────────────────────────────────
function renderLogsShell() {
  const ev = state.events;
  $("#main").innerHTML = `
    <div class="toolbar">
      <select class="input" id="l-event">
        <option value="">Alle Ereignisse</option>
        ${["failed", "retry", "completed", "processing", "queued", "requeued", "admin"].map((s) => `<option value="${s}" ${ev.event === s ? "selected" : ""}>${STATUS_LABEL[s]}</option>`).join("")}
      </select>
      <select class="input" id="l-type">
        <option value="">Alle Kategorien</option>
        ${Object.keys(TYPES).map((t) => `<option value="${t}" ${ev.type === t ? "selected" : ""}>${esc(typeText(t))}</option>`).join("")}
      </select>
      <span class="muted small">Live-Protokoll aller Statuswechsel der Übersetzungs-Jobs (21 Tage).</span>
    </div>
    <div class="card"><div class="table-wrap" id="logs-table" style="max-height:60vh;overflow:auto"><div class="empty">Lade …</div></div></div>
    <div class="section-title"><div><h2>Worker-Läufe</h2><p>Antworten der Edge Function <span class="mono">process-translation-jobs</span> (letzte ~6 h)</p></div></div>
    <div class="card"><div id="runs"><div class="empty">Lade …</div></div></div>`;
  $("#l-event").onchange = (e) => { ev.event = e.target.value; loadLogs(); };
  $("#l-type").onchange = (e) => { ev.type = e.target.value; loadLogs(); };
}

async function loadLogs() {
  const ev = state.events;
  let q = sb.from("translation_events").select("*").order("created_at", { ascending: false }).limit(300);
  if (ev.event) q = q.eq("event", ev.event);
  if (ev.type) q = q.eq("content_type", ev.type);
  const [{ data, error }, runs] = await Promise.all([q, rpc("tp_worker_runs", { p_limit: 30 }).catch(() => [])]);
  const el = $("#logs-table");
  if (el) {
    if (error) el.innerHTML = `<div class="empty">Fehler: ${esc(error.message)}</div>`;
    else if (!data.length) el.innerHTML = `<div class="empty">Noch keine Log-Einträge. Sobald Jobs laufen, erscheinen sie hier live.</div>`;
    else el.innerHTML = `<table><thead><tr><th>Zeit</th><th>Ereignis</th><th>Kategorie</th><th>Datensatz</th><th>Details</th></tr></thead><tbody>
      ${data.map((e) => `<tr><td class="small muted" style="white-space:nowrap">${esc(fmtTime(e.created_at))}</td><td>${statusChip(e.event)}</td>
        <td class="small">${e.content_type ? typeLabel(e.content_type) : "–"}</td>
        <td class="mono small">${e.record_id ? `<a href="#" data-open="${esc(e.content_type)}|${esc(e.record_id)}">${esc(e.record_id.slice(0, 8))}</a>` : "–"}</td>
        <td class="small" title="${esc(e.message || "")}">${esc(e.event === "processing" ? e.message || "" : shortError(e.message) || "")}${e.attempts ? ` <span class="muted">· Versuch ${e.attempts}</span>` : ""}</td></tr>`).join("")}
      </tbody></table>`;
    el.querySelectorAll("[data-open]").forEach((a) => (a.onclick = (e) => {
      e.preventDefault();
      const [type, id] = a.dataset.open.split("|");
      openDrawer({ content_type: type, record_id: id, title: id, id: "…", status: "", attempts: 0, revision: 0 });
    }));
  }
  const r = $("#runs");
  if (r) {
    r.innerHTML = !runs?.length ? `<div class="empty">Keine Worker-Läufe in den letzten Stunden.</div>` :
      `<table><tbody>${runs.map((x) => {
        let parsed = null;
        try { parsed = JSON.parse(x.body); } catch { /* raw */ }
        const ok = x.status_code >= 200 && x.status_code < 300 && parsed?.ok !== false;
        const failedResults = (parsed?.results || []).filter((y) => y.ok === false || y.status === "failed" || y.outcome === "failed" || y.outcome === "retry" || y.error);
        const summary = parsed ? (parsed.ok === false ? shortError(parsed.error) :
          `${parsed.processed ?? 0} Jobs verarbeitet · ${Math.round((parsed.durationMs ?? 0) / 1000)} s${failedResults.length ? ` · ${failedResults.length} mit Fehler` : ""}`) : (x.error_msg || "");
        return `<tr><td class="small muted" style="white-space:nowrap">${esc(fmtTime(x.created))}</td>
          <td>${ok ? (failedResults.length ? statusChip("retry") : statusChip("completed")) : statusChip("failed")}</td>
          <td class="small">HTTP ${x.status_code ?? "–"} · ${esc(summary)}
          <details><summary class="muted small">Rohdaten</summary><pre class="log">${esc(x.body || x.error_msg || "")}</pre></details></td></tr>`;
      }).join("")}</tbody></table>`;
  }
}

// ─── Audio ──────────────────────────────────────────────────────────────────
// All audios with their language versions and the status of the AI voice
// jobs (table audio_tts_jobs, written by tool/tts/generate_english_audio.py,
// GitHub workflow every 15 min). KI-Stimme: Englisch; andere Sprachen per Upload.
const TTS_LANGS = ["en"];
const AUDIO_FILTERS = [
  ["all", "Alle"],
  ["missing", "Ohne Englisch"],
  ["pending", "Wartend"],
  ["processing", "In Arbeit"],
  ["failed", "Fehlgeschlagen"],
  ["skipped", "Übersprungen"],
  ["done", "Fertig"],
];
const JOB_LABEL = { pending: "wartet", processing: "wird erzeugt", completed: "fertig", failed: "fehlgeschlagen", skipped: "übersprungen" };

function activeLangs() {
  return (state.overview?.languages || []).filter((l) => l.active).map((l) => l.code);
}

// Same search rules as in the app: case/umlaut/accent-insensitive, all words.
function normSearch(s) {
  return String(s || "").toLowerCase()
    .replace(/ä/g, "ae").replace(/ö/g, "oe").replace(/ü/g, "ue").replace(/ß/g, "ss")
    .normalize("NFD").replace(/[̀-ͯ]/g, "")
    .replace(/[^\p{L}\p{N}\s]/gu, " ").replace(/\s+/g, " ").trim();
}

function jobOf(audioId, lang) { return state.audios.jobs?.[`${audioId}|${lang}`]; }

function audioStatus(r, lang) {
  const tr = r.translations.find((t) => t.language === lang);
  const job = jobOf(r.audio_id, lang);
  if (job && (job.status === "processing" || job.status === "failed" || job.status === "skipped")) return job.status;
  if (job && job.status === "pending" && (!tr || job.force)) return "pending";
  if (tr) return "done";
  return "missing";
}

function renderAudioShell() {
  const a = state.audios;
  $("#main").innerHTML = `
    <div class="banner info">
      <div class="icon">${ic("headphones")}</div>
      <div class="txt"><strong>Audios in allen Sprachen</strong>Zu jedem deutschen Audio gibt es Sprachversionen. <b>Englisch erzeugt die KI-Stimme automatisch</b>
      (freies Modell Kokoro, liest die englische Übersetzung des Artikels). Weitere Sprachen oder eigene Aufnahmen lädst du hier hoch – eigene Uploads werden nie von der KI überschrieben.
      Neustarts werden spätestens nach ~15 Minuten bearbeitet.</div>
    </div>
    <div id="audio-kpis"></div>
    <div id="audio-running"></div>
    <div class="toolbar">
      <input class="input" id="a-q" placeholder="Suchen – Titel, Ausgabe, mehrere Wörter …" value="${esc(a.q)}" style="flex:1;min-width:220px">
      <button class="btn" id="a-retry-failed">${ic("rotate-cw")}Fehlgeschlagene neu starten</button>
      <button class="btn" id="a-reload">${ic("refresh-cw")}Aktualisieren</button>
    </div>
    <div class="chips" id="a-filters"></div>
    <div class="card" id="audio-list"><div class="empty">Lade …</div></div>`;
  let deb;
  $("#a-q").oninput = (e) => { clearTimeout(deb); deb = setTimeout(() => { a.q = e.target.value; renderAudioList(); }, 150); };
  $("#a-reload").onclick = () => loadAudios();
  $("#a-retry-failed").onclick = () => retryFailedAudios();
  if (a.rows) renderAudioList();
}

async function loadAudioJobs() {
  const { data, error } = await sb.from("audio_tts_jobs").select("*");
  if (error) { state.audios.jobsError = error.message; return; }
  state.audios.jobsError = null;
  state.audios.jobs = Object.fromEntries((data || []).map((j) => [`${j.audio_id}|${j.language}`, j]));
}

async function loadAudios() {
  try {
    const [rows] = await Promise.all([rpc("tp_audios"), loadAudioJobs()]);
    state.audios.rows = rows;
  } catch (e) {
    const el = $("#audio-list");
    if (el) el.innerHTML = `<div class="empty">Fehler: ${esc(e.message)}</div>`;
    return;
  }
  renderAudioList();
}

async function refreshAudioJobs() {
  await loadAudioJobs();
  renderAudioList();
}

async function requestTts(audioIds, lang = "en") {
  const rows = audioIds.map((id) => ({
    audio_id: id, language: lang, status: "pending", force: true, error: null,
    requested_at: new Date().toISOString(), updated_at: new Date().toISOString(),
  }));
  for (let i = 0; i < rows.length; i += 200) {
    const { error } = await sb.from("audio_tts_jobs").upsert(rows.slice(i, i + 200), { onConflict: "audio_id,language" });
    if (error) throw error;
  }
}

async function retryFailedAudios() {
  const failed = Object.values(state.audios.jobs || {}).filter((j) => j.status === "failed");
  if (!failed.length) return toast("Keine fehlgeschlagenen Audio-Jobs.");
  try {
    await requestTts(failed.map((j) => j.audio_id));
    toast(`${failed.length} Audio(s) neu eingereiht – Start spätestens in ~15 Minuten.`);
    await refreshAudioJobs();
  } catch (e) { toast("Fehler: " + e.message, true); }
}

function renderAudioKpis() {
  const rows = state.audios.rows || [];
  const langs = activeLangs();
  const count = { missing: 0, pending: 0, processing: 0, failed: 0, skipped: 0, done: 0 };
  let ai = 0, manual = 0;
  for (const r of rows) {
    count[audioStatus(r, "en")]++;
    const en = r.translations.find((t) => t.language === "en");
    if (en) (String(en.storage_path || "").startsWith("tts/") ? ai++ : manual++);
  }
  const k = $("#audio-kpis");
  if (k) k.innerHTML = `<div class="grid kpis" style="margin-bottom:14px">
      <div class="card kpi"><div class="label">Audios</div><div class="value">${fmtN(rows.length)}</div></div>
      <div class="card kpi ok"><div class="label">Englisch fertig</div><div class="value">${fmtN(ai + manual)}</div><div class="muted small">${fmtN(ai)} KI · ${fmtN(manual)} eigene</div></div>
      <div class="card kpi info"><div class="label">In Arbeit</div><div class="value">${fmtN(count.processing)}</div></div>
      <div class="card kpi"><div class="label">Wartend</div><div class="value">${fmtN(count.pending)}</div></div>
      <div class="card kpi bad"><div class="label">Fehlgeschlagen</div><div class="value">${fmtN(count.failed)}</div></div>
      <div class="card kpi warn"><div class="label">Übersprungen</div><div class="value">${fmtN(count.skipped)}</div><div class="muted small">Übersetzung fehlt</div></div>
    </div>
    ${state.audios.jobsError ? `<div class="banner warn"><div class="icon">${ic("triangle-alert")}</div><div class="txt"><strong>Job-Status nicht verfügbar</strong>${esc(state.audios.jobsError)}</div></div>` : ""}`;

  const running = Object.values(state.audios.jobs || {}).filter((j) => j.status === "processing");
  const byId = Object.fromEntries(rows.map((r) => [r.audio_id, r]));
  const el = $("#audio-running");
  if (el) el.innerHTML = running.length ? `<div class="card card-pad" style="margin-bottom:14px">
      <h2 style="margin-top:0">Laufende Jobs (${running.length})</h2>
      ${running.map((j) => `<div class="muted small" style="padding:4px 0">${ic("rotate-cw","xs")} <b>${esc(byId[j.audio_id]?.title || j.audio_id)}</b> · ${esc(j.language.toUpperCase())} · gestartet ${ago(j.started_at)} · Versuch ${j.attempts}</div>`).join("")}
    </div>` : "";

  const f = $("#a-filters");
  if (f) {
    f.innerHTML = AUDIO_FILTERS.map(([v, label]) => {
      const n = v === "all" ? rows.length : rows.filter((r) => audioStatus(r, "en") === v).length;
      return `<button class="chip ${state.audios.filter === v ? "info" : ""}" data-f="${v}" style="cursor:pointer;font-size:12px;padding:4px 10px">${esc(label)} · ${fmtN(n)}</button>`;
    }).join("");
    f.querySelectorAll("[data-f]").forEach((b) => (b.onclick = () => { state.audios.filter = b.dataset.f; renderAudioList(); }));
  }
}

function langPill(r, l) {
  const tr = r.translations.find((t) => t.language === l);
  const job = jobOf(r.audio_id, l);
  const st = audioStatus(r, l);
  const isAi = tr && String(tr.storage_path || "").startsWith("tts/");
  const play = tr ? `<button title="Anhören" aria-label="Anhören" data-play="${esc(tr.url)}">${ic("play","xs")}</button>` : "";
  const del = tr ? `<button title="Entfernen" aria-label="Entfernen" data-del="${esc(tr.id)}" data-path="${esc(tr.storage_path || "")}" data-lang="${esc(l)}">${ic("x","xs")}</button>` : "";
  const tip = job?.error ? ` title="${esc(job.error)}"` : (tr ? ` title="${esc(tr.file_name || "")}"` : "");
  if (st === "done") return `<span class="lang-pill has"${tip}>${ic("check","xs")}${esc(l.toUpperCase())}${isAi ? " · KI" : ""}${play}${del}</span>`;
  if (st === "processing") return `<span class="lang-pill" style="background:var(--info-soft);color:var(--info);border-color:transparent;padding-right:10px"${tip}>${ic("rotate-cw","xs")}${esc(l.toUpperCase())} wird erzeugt</span>`;
  if (st === "pending") return `<span class="lang-pill" style="padding-right:${tr ? 4 : 10}px"${tip}>${esc(l.toUpperCase())} wartet${play}</span>`;
  if (st === "failed") return `<span class="lang-pill" style="background:var(--bad-soft);color:var(--bad);border-color:transparent;padding-right:${tr ? 4 : 10}px"${tip}>${ic("triangle-alert","xs")}${esc(l.toUpperCase())} fehlgeschlagen${play}</span>`;
  if (st === "skipped") return `<span class="lang-pill" style="background:var(--warn-soft);color:var(--warn);border-color:transparent;padding-right:10px"${tip}>${esc(l.toUpperCase())} – Übersetzung fehlt</span>`;
  return `<span class="lang-pill missing">${esc(l.toUpperCase())} fehlt</span>`;
}

function renderAudioList() {
  renderAudioKpis();
  const el = $("#audio-list");
  if (!el || !state.audios.rows) return;
  const langs = activeLangs();
  const a = state.audios;
  let rows = state.audios.rows;
  const words = normSearch(a.q).split(" ").filter(Boolean);
  if (words.length) {
    rows = rows.filter((r) => {
      const hay = normSearch(`${r.title} ${r.edition || ""} ${r.translations.map((t) => t.file_name || "").join(" ")}`);
      return words.every((w) => hay.includes(w));
    });
  }
  // Filters follow the English (AI) version; other languages are uploads.
  if (a.filter !== "all") rows = rows.filter((r) => audioStatus(r, "en") === a.filter);
  if (!rows.length) { el.innerHTML = `<div class="empty">Keine Audios gefunden.</div>`; return; }
  const shown = rows.slice(0, 200);
  el.innerHTML = shown.map((r) => {
    const tr = Object.fromEntries(r.translations.map((t) => [t.language, t]));
    const missing = langs.filter((l) => !tr[l]);
    const job = jobOf(r.audio_id, "en");
    return `<div class="audio-item" data-audio="${r.audio_id}">
      ${r.image_url ? `<img class="thumb" src="${esc(r.image_url)}" alt="" loading="lazy">` : `<div class="thumb"></div>`}
      <div>
        <div class="audio-title">${esc(r.title)}</div>
        <div class="muted small">${r.edition ? esc(r.edition) + " · " : ""}${r.created_at ? new Date(r.created_at).toLocaleDateString("de-DE") + " · " : ""}
          <button class="btn sm" data-play="${esc(r.url)}" style="padding:2px 8px">${ic("play","xs")}Original (DE)</button>
          ${job?.status === "failed" && job.error ? `<span style="color:var(--bad)"> · ${esc(job.error.slice(0, 140))}</span>` : ""}</div>
        <div class="audio-langs">${langs.map((l) => langPill(r, l)).join("")}</div>
        <div class="upload-row">
          ${TTS_LANGS.map((l) => `<button class="btn sm" data-tts="${l}" title="Englische KI-Version neu erzeugen (ersetzt auch eigene Uploads)">${ic("sparkles")}KI-Stimme ${l.toUpperCase()} ${tr[l] ? "neu erzeugen" : "erzeugen"}</button>`).join("")}
          <select class="input" data-lang-select>
            ${langs.map((l) => `<option value="${l}" ${missing[0] === l ? "selected" : ""}>${esc(langName(l))}${tr[l] ? " – ersetzen" : ""}</option>`).join("")}
          </select>
          <input type="file" accept="audio/*,.mp3,.m4a,.aac,.wav,.ogg" data-file>
          <button class="btn primary sm" data-upload>${ic("upload")}Hochladen</button>
          <div class="progress" hidden><span></span></div>
        </div>
        <div data-player></div>
      </div>
    </div>`;
  }).join("") + (rows.length > shown.length ? `<div class="empty small">${fmtN(rows.length - shown.length)} weitere – bitte Suche oder Filter verwenden.</div>` : "");

  el.querySelectorAll("[data-play]").forEach((b) => (b.onclick = () => {
    const host = b.closest(".audio-item").querySelector("[data-player]");
    host.innerHTML = `<audio controls autoplay src="${esc(b.dataset.play)}" style="margin-top:10px;width:100%"></audio>`;
  }));
  el.querySelectorAll("[data-tts]").forEach((b) => (b.onclick = async () => {
    const item = b.closest(".audio-item");
    try {
      await requestTts([item.dataset.audio], b.dataset.tts);
      toast("Eingereiht – die KI-Stimme startet spätestens in ~15 Minuten.");
      await refreshAudioJobs();
    } catch (e) { toast("Fehler: " + e.message, true); }
  }));
  el.querySelectorAll("[data-del]").forEach((b) => (b.onclick = async () => {
    if (!confirm(`Audio (${b.dataset.lang.toUpperCase()}) entfernen? Die App spielt dann wieder das deutsche Original.`)) return;
    try {
      const { error } = await sb.from("audio_translations").delete().eq("id", b.dataset.del);
      if (error) throw error;
      if (b.dataset.path) await sb.storage.from(CFG.audioBucket).remove([b.dataset.path]);
      toast("Entfernt");
      await loadAudios();
      refreshAll(true);
    } catch (e) { toast("Fehler: " + e.message, true); }
  }));
  el.querySelectorAll("[data-upload]").forEach((b) => (b.onclick = () => uploadAudio(b.closest(".audio-item"))));
}

async function uploadAudio(item) {
  const audioId = item.dataset.audio;
  const lang = item.querySelector("[data-lang-select]").value;
  const file = item.querySelector("[data-file]").files?.[0];
  if (!file) return toast("Bitte zuerst eine Audiodatei auswählen.", true);
  if (file.size > 500 * 1024 * 1024) return toast("Datei ist zu groß (max. 500 MB).", true);
  const btn = item.querySelector("[data-upload]");
  const prog = item.querySelector(".progress");
  const bar = prog.querySelector("span");
  btn.disabled = true;
  prog.hidden = false;
  bar.style.width = "5%";
  const ext = (file.name.split(".").pop() || "mp3").toLowerCase().replace(/[^a-z0-9]/g, "") || "mp3";
  const path = `translations/${audioId}/${lang}-${Date.now()}.${ext}`;
  const existing = state.audios.rows.find((r) => r.audio_id === audioId)?.translations.find((t) => t.language === lang);
  try {
    await uploadWithProgress(path, file, (p) => (bar.style.width = Math.max(5, Math.round(p * 100)) + "%"));
    const { data: pub } = sb.storage.from(CFG.audioBucket).getPublicUrl(path);
    const { error } = await sb.from("audio_translations").upsert({
      audio_id: audioId, language: lang, url: pub.publicUrl, storage_path: path, file_name: file.name,
      created_by: state.session.user.id,
    }, { onConflict: "audio_id,language" });
    if (error) throw error;
    if (existing?.storage_path && existing.storage_path !== path) {
      await sb.storage.from(CFG.audioBucket).remove([existing.storage_path]).catch(() => {});
    }
    // An own upload ends a waiting AI job for this language.
    await sb.from("audio_tts_jobs").update({ status: "completed", force: false, error: null })
      .eq("audio_id", audioId).eq("language", lang).then(() => {}, () => {});
    toast(`${langName(lang)} gespeichert – in der App sofort aktiv.`);
    await loadAudios();
    refreshAll(true);
  } catch (e) {
    toast("Upload fehlgeschlagen: " + (e.message || e), true);
    btn.disabled = false;
    prog.hidden = true;
  }
}

// Storage upload via XHR for progress reporting
async function uploadWithProgress(path, file, onProgress) {
  const { data } = await sb.auth.getSession();
  const token = data.session?.access_token;
  const url = `${CFG.supabaseUrl}/storage/v1/object/${CFG.audioBucket}/${path.split("/").map(encodeURIComponent).join("/")}`;
  await new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    xhr.open("POST", url);
    xhr.setRequestHeader("Authorization", `Bearer ${token}`);
    xhr.setRequestHeader("apikey", CFG.supabaseAnonKey);
    xhr.setRequestHeader("x-upsert", "true");
    xhr.setRequestHeader("Content-Type", file.type || "audio/mpeg");
    xhr.setRequestHeader("cache-control", "max-age=31536000");
    xhr.upload.onprogress = (e) => { if (e.lengthComputable) onProgress(e.loaded / e.total); };
    xhr.onload = () => {
      if (xhr.status >= 200 && xhr.status < 300) return resolve();
      let msg = xhr.responseText;
      try { msg = JSON.parse(xhr.responseText).message || msg; } catch { /* raw */ }
      reject(new Error(`HTTP ${xhr.status}: ${msg}`));
    };
    xhr.onerror = () => reject(new Error("Netzwerkfehler"));
    xhr.send(file);
  });
}

// ─── Credits ────────────────────────────────────────────────────────────────
function renderCredits() {
  const root = $("#cr");
  if (!root) return;
  const o = state.overview;
  const t = totals();
  root.innerHTML = `
    ${o?.credit_error ? creditBanner() : `<div class="banner ok"><div class="icon">${ic("credit-card")}</div><div class="txt"><strong>Guthaben aktuell kein Problem</strong>In den letzten 3 Tagen kein „credit balance too low“-Fehler.</div></div>`}
    <div class="grid" style="grid-template-columns:repeat(auto-fit,minmax(320px,1fr))">
      <div class="card card-pad">
        <h2>1 · Guthaben aufladen</h2>
        <p class="muted">Die Übersetzungen laufen über die Anthropic-API (Claude). Das Guthaben wird in der Anthropic Console verwaltet.</p>
        <ol class="steps">
          <li>Mit dem Anthropic-Account anmelden, zu dem der <span class="mono">ANTHROPIC_API_KEY</span> gehört.</li>
          <li><b>Plans &amp; Billing → Buy credits</b> – Betrag wählen und bezahlen.</li>
          <li>Optional <b>Auto-Reload</b> aktivieren, damit das Guthaben nie wieder leer läuft.</li>
        </ol>
        <div class="btn-row" style="margin-top:14px">
          <a class="btn primary" href="${CFG.billingUrl}" target="_blank" rel="noopener">Guthaben aufladen${ic("external-link","trail")}</a>
          <a class="btn" href="${CFG.usageUrl}" target="_blank" rel="noopener">Verbrauch ansehen${ic("external-link","trail")}</a>
        </div>
      </div>
      <div class="card card-pad">
        <h2>2 · Übersetzungen neu starten</h2>
        <p class="muted">Nach dem Aufladen alle fehlgeschlagenen Jobs erneut einreihen. Bereits fertige Felder werden nicht nochmal übersetzt.</p>
        <div class="kv"><dt>Fehlgeschlagen</dt><dd><b style="color:var(--bad)">${fmtN(t.failed)}</b></dd>
          <dt>Wartend</dt><dd>${fmtN(t.pending)}</dd><dt>In Arbeit</dt><dd>${fmtN(t.processing)}</dd></div>
        <div class="btn-row">
          <button class="btn primary" data-act="retry-all" ${t.failed ? "" : "disabled"}>${ic("rotate-cw")}Alle fehlgeschlagenen neu starten</button>
          <button class="btn" data-act="run-now">${ic("play")}Worker jetzt starten</button>
        </div>
      </div>
      <div class="card card-pad">
        <h2>API-Key wechseln</h2>
        <p class="muted">Falls ein anderer Anthropic-Account genutzt werden soll: neuen Key in der Console erstellen und in Supabase als Secret <span class="mono">ANTHROPIC_API_KEY</span> hinterlegen. Danach hier „Alle fehlgeschlagenen neu starten“.</p>
        <div class="btn-row">
          <a class="btn" href="https://console.anthropic.com/settings/keys" target="_blank" rel="noopener">API-Keys${ic("external-link","trail")}</a>
          <a class="btn" href="https://supabase.com/dashboard/project/vdcdibvclaulqxfjyzpq/functions/secrets" target="_blank" rel="noopener">Supabase Secrets${ic("external-link","trail")}</a>
        </div>
      </div>
    </div>`;
  bindCommonActions(root);
}

boot();

// ─── Bilder (KI-Übersetzung der Schrift auf Titelbildern, Gemini) ───────────
const IMG_LANGS = ["en", "ru", "es", "pl", "tr", "he"];
const IMG_PRICE_USD = 0.039; // Gemini 2.5 Flash Image, pro bearbeitetem Bild
const IMG_TYPES = { posts: "Artikel", impulses: "Impuls", editions: "Ausgabe", messages: "Kurznachricht" };
const IMG_FILTERS = [
  ["all", "Alle"], ["done", "Übersetzt"], ["open", "Wartend"], ["failed", "Fehlgeschlagen"],
  ["no_text", "Ohne Text"], ["rejected", "Abgelehnt"],
];

async function loadImages() {
  const im = state.images;
  try {
    const rows = [];
    for (let from = 0; ; from += 1000) {
      const { data, error } = await sb.from("image_translations").select("*").order("requested_at", { ascending: false }).range(from, from + 999);
      if (error) throw error;
      rows.push(...data);
      if (data.length < 1000) break;
    }
    const { data: ws } = await sb.from("worker_status").select("*").eq("name", "image-translation").maybeSingle();
    const groups = new Map();
    for (const r of rows) {
      if (!groups.has(r.source_url)) groups.set(r.source_url, { source_url: r.source_url, title: r.title, entity_type: r.entity_type, requested_at: r.requested_at, langs: {} });
      groups.get(r.source_url).langs[r.language] = r;
    }
    im.groups = [...groups.values()];
    im.worker = ws || null;
    im.error = null;
  } catch (e) {
    im.error = e.message;
  }
  renderImageList();
}

function imgGroupStatus(g) {
  const s = Object.values(g.langs).map((r) => r.status);
  if (s.includes("processing")) return "open";
  if (s.includes("failed")) return "failed";
  if (s.includes("pending")) return "open";
  if (s.includes("completed")) return "done";
  if (s.includes("rejected")) return "rejected";
  return "no_text";
}

function renderImageShell() {
  const im = state.images;
  $("#main").innerHTML = `
    <div class="banner info">
      <div class="icon">${ic("sparkles")}</div>
      <div class="txt"><strong>Schrift auf Titelbildern übersetzen</strong>Gemini prüft jedes Bild einmal auf Text. Bilder mit Text werden pro Sprache neu erzeugt –
      nur die Schrift wird ersetzt, Foto und Layout bleiben. Die App zeigt dann in jeder Sprache das passende Bild. <b>Neue Bilder laufen automatisch</b>;
      alte Bilder reihst du mit dem Button unten ein. Gefällt dir ein Ergebnis nicht: ablehnen (App zeigt wieder das Original) oder neu erzeugen.</div>
    </div>
    <div id="img-worker"></div>
    <div id="img-kpis"></div>
    <div class="toolbar">
      <input class="input" id="i-q" placeholder="Suchen – Titel …" value="${esc(im.q)}" style="flex:1;min-width:220px">
      <button class="btn primary" id="i-backfill">${ic("plus")}Alle bestehenden Bilder einreihen</button>
      <button class="btn" id="i-retry">${ic("rotate-cw")}Fehlgeschlagene neu starten</button>
      <button class="btn" id="i-reload">${ic("refresh-cw")}Aktualisieren</button>
    </div>
    <div class="chips" id="i-filters"></div>
    <div class="card" id="img-list"><div class="empty">Lade …</div></div>
    <div id="img-compare"></div>`;
  let deb;
  $("#i-q").oninput = (e) => { clearTimeout(deb); deb = setTimeout(() => { im.q = e.target.value; renderImageList(); }, 150); };
  $("#i-reload").onclick = () => loadImages();
  $("#i-retry").onclick = async () => {
    const failed = (im.groups || []).flatMap((g) => Object.values(g.langs)).filter((r) => r.status === "failed");
    if (!failed.length) return toast("Keine fehlgeschlagenen Bilder.");
    try { await requeueImages(failed); toast(`${failed.length} neu eingereiht – Start spätestens in ~30 Minuten.`); } catch (e) { toast("Fehler: " + e.message, true); }
  };
  $("#i-backfill").onclick = async () => {
    if (!confirm("Alle bestehenden Titelbilder (Artikel, Impulse, Ausgaben, Kurznachrichten) für die KI-Übersetzung einreihen?\n\n" +
      "Kosten: nur Bilder MIT Text werden bearbeitet (ca. 0,04 $ pro Bild und Sprache). Ohne Gemini-Guthaben passiert nichts.")) return;
    try {
      const { data, error } = await sb.rpc("enqueue_all_image_translations");
      if (error) throw error;
      toast(`${fmtN(data || 0)} Bild-Übersetzungen eingereiht.`);
      await loadImages();
    } catch (e) { toast("Fehler: " + e.message, true); }
  };
  if (im.groups) renderImageList(); else loadImages();
}

async function requeueImages(rows) {
  for (const r of rows) {
    const { error } = await sb.from("image_translations")
      .update({ status: "pending", force: true, error: null, attempts: 0, requested_at: new Date().toISOString(), updated_at: new Date().toISOString() })
      .eq("id", r.id);
    if (error) throw error;
  }
  await loadImages();
}

function renderImageWorker() {
  const el = $("#img-worker");
  if (!el) return;
  const w = state.images.worker;
  const open = (state.images.groups || []).flatMap((g) => Object.values(g.langs)).filter((r) => r.status === "pending" || r.status === "processing").length;
  if (state.images.error) {
    el.innerHTML = `<div class="banner warn"><div class="icon">${ic("triangle-alert")}</div><div class="txt"><strong>Noch nicht eingerichtet</strong>${esc(state.images.error)}</div></div>`;
  } else if (w?.state === "no_key" || !w) {
    el.innerHTML = `<div class="banner warn"><div class="icon">${ic("key-round")}</div><div class="txt"><strong>Gemini-Key fehlt</strong>
      In <a href="https://aistudio.google.com/apikey" target="_blank" rel="noopener">Google AI Studio</a> einen API-Key erstellen und auf GitHub unter
      Settings → Secrets and variables → Actions als <code>GEMINI_API_KEY</code> speichern. Danach Guthaben aufladen – der Rest läuft automatisch (alle 30 Minuten).</div></div>`;
  } else if (w.state === "no_credit") {
    el.innerHTML = `<div class="banner bad"><div class="icon">${ic("credit-card")}</div><div class="txt"><strong>Gemini-Guthaben aufgebraucht</strong>
      ${fmtN(open)} Übersetzungen warten. In <a href="https://aistudio.google.com/billing" target="_blank" rel="noopener">AI Studio → Billing</a> Guthaben aufladen – der nächste Lauf macht automatisch weiter.
      <div class="muted small">Stand ${fmtTime(w.updated_at)}</div></div></div>`;
  } else if (w.state === "bad_key") {
    el.innerHTML = `<div class="banner bad"><div class="icon">${ic("key-round")}</div><div class="txt"><strong>Gemini-Key ungültig</strong>Bitte das GitHub-Secret <code>GEMINI_API_KEY</code> erneuern.</div></div>`;
  } else {
    el.innerHTML = `<div class="banner ok"><div class="icon">${ic("circle-check")}</div><div class="txt"><strong>${w.state === "running" ? "Läuft" : "Bereit"}</strong>${esc(w.message || "")} · ${ago(w.updated_at)}</div></div>`;
  }
}

function renderImageKpis() {
  const groups = state.images.groups || [];
  const all = groups.flatMap((g) => Object.values(g.langs));
  const c = (s) => all.filter((r) => r.status === s).length;
  const open = c("pending") + c("processing");
  const withText = groups.filter((g) => Object.values(g.langs).some((r) => ["completed", "rejected"].includes(r.status))).length;
  const el = $("#img-kpis");
  if (el) el.innerHTML = `<div class="grid kpis" style="margin-bottom:14px">
    <div class="card kpi"><div class="label">Bilder</div><div class="value">${fmtN(groups.length)}</div><div class="muted small">${fmtN(withText)} mit Text</div></div>
    <div class="card kpi ok"><div class="label">Übersetzt</div><div class="value">${fmtN(c("completed"))}</div><div class="muted small">Bild × Sprache</div></div>
    <div class="card kpi info"><div class="label">Wartend</div><div class="value">${fmtN(open)}</div><div class="muted small">max. ~${(open * IMG_PRICE_USD).toFixed(2)} $</div></div>
    <div class="card kpi bad"><div class="label">Fehlgeschlagen</div><div class="value">${fmtN(c("failed"))}</div></div>
    <div class="card kpi"><div class="label">Ohne Text</div><div class="value">${fmtN(groups.filter((g) => imgGroupStatus(g) === "no_text").length)}</div><div class="muted small">bleiben Original</div></div>
  </div>`;
  const f = $("#i-filters");
  if (f) {
    f.innerHTML = IMG_FILTERS.map(([v, label]) => {
      const n = v === "all" ? groups.length : groups.filter((g) => imgGroupStatus(g) === v).length;
      return `<button class="chip ${state.images.filter === v ? "info" : ""}" data-f="${v}" style="cursor:pointer;font-size:12px;padding:4px 10px">${esc(label)} · ${fmtN(n)}</button>`;
    }).join("");
    f.querySelectorAll("[data-f]").forEach((b) => (b.onclick = () => { state.images.filter = b.dataset.f; renderImageList(); }));
  }
}

function imgPill(g, l) {
  const r = g.langs[l];
  const L = esc(l.toUpperCase());
  if (!r) return `<span class="lang-pill missing">${L} –</span>`;
  const tip = r.error ? ` title="${esc(r.error)}"` : "";
  const btn = `data-cmp="${esc(r.id)}"`;
  switch (r.status) {
    case "completed": return `<span class="lang-pill has" style="cursor:pointer;padding-right:10px" ${btn}>${ic("check","xs")}${L} ansehen</span>`;
    case "processing": return `<span class="lang-pill" style="background:var(--info-soft);color:var(--info);border-color:transparent;padding-right:10px">${ic("rotate-cw","xs")}${L} läuft</span>`;
    case "pending": return `<span class="lang-pill" style="padding-right:10px">${L} wartet</span>`;
    case "failed": return `<span class="lang-pill" style="background:var(--bad-soft);color:var(--bad);border-color:transparent;padding-right:10px"${tip}>${ic("triangle-alert","xs")}${L} Fehler</span>`;
    case "rejected": return `<span class="lang-pill" style="background:var(--warn-soft);color:var(--warn);border-color:transparent;cursor:pointer;padding-right:10px" ${btn}>${L} abgelehnt</span>`;
    default: return `<span class="lang-pill missing">${L} kein Text</span>`;
  }
}

function renderImageList() {
  renderImageWorker();
  renderImageKpis();
  const el = $("#img-list");
  if (!el) return;
  const im = state.images;
  if (im.error) { el.innerHTML = `<div class="empty">Die Datenbank-Tabelle fehlt noch.</div>`; return; }
  if (!im.groups) return;
  let groups = im.groups;
  const words = normSearch(im.q).split(" ").filter(Boolean);
  if (words.length) groups = groups.filter((g) => { const h = normSearch(g.title); return words.every((w) => h.includes(w)); });
  if (im.filter !== "all") groups = groups.filter((g) => imgGroupStatus(g) === im.filter);
  if (!groups.length) {
    el.innerHTML = `<div class="empty">${im.groups.length ? "Keine Bilder gefunden." : "Noch keine Bilder eingereiht – neue Bilder kommen automatisch, alte über „Alle bestehenden Bilder einreihen“."}</div>`;
    return;
  }
  const shown = groups.slice(0, 150);
  el.innerHTML = shown.map((g, i) => `<div class="audio-item" data-g="${i}">
      <img class="thumb" src="${esc(g.source_url)}" alt="" loading="lazy">
      <div>
        <div class="audio-title">${esc(g.title || g.source_url.split("/").pop())}</div>
        <div class="muted small">${esc(IMG_TYPES[g.entity_type] || g.entity_type || "")}${imgGroupStatus(g) === "no_text" ? ` · <button class="btn sm" data-force style="padding:2px 8px">${ic("sparkles")}Trotzdem übersetzen</button>` : ""}</div>
        <div class="audio-langs">${IMG_LANGS.map((l) => imgPill(g, l)).join("")}</div>
      </div>
    </div>`).join("") + (groups.length > shown.length ? `<div class="empty small">${fmtN(groups.length - shown.length)} weitere – bitte Suche oder Filter verwenden.</div>` : "");
  el.querySelectorAll("[data-cmp]").forEach((b) => (b.onclick = () => {
    const g = shown[b.closest("[data-g]").dataset.g];
    openCompare(g, Object.values(g.langs).find((r) => r.id === b.dataset.cmp));
  }));
  el.querySelectorAll("[data-force]").forEach((b) => (b.onclick = async () => {
    const g = shown[b.closest("[data-g]").dataset.g];
    try { await requeueImages(Object.values(g.langs)); toast("Eingereiht – Start spätestens in ~30 Minuten."); } catch (e) { toast("Fehler: " + e.message, true); }
  }));
}

function openCompare(g, r) {
  const host = $("#img-compare");
  host.innerHTML = `<div class="drawer-backdrop" id="cmp-bg" style="position:fixed;inset:0;background:rgba(0,0,0,.55);z-index:50;display:grid;place-items:center;padding:16px">
    <div class="card card-pad" style="max-width:980px;width:100%;max-height:92vh;overflow:auto">
      <div style="display:flex;gap:8px;align-items:center;margin-bottom:12px;flex-wrap:wrap">
        <strong style="flex:1">${esc(g.title || "")} · ${esc(langName(r.language))}</strong>
        ${r.status === "completed" ? `<button class="btn" id="cmp-reject">${ic("x")}Ablehnen (Original zeigen)</button>` : `<button class="btn" id="cmp-accept">${ic("check")}Doch verwenden</button>`}
        <button class="btn" id="cmp-redo">${ic("sparkles")}Neu erzeugen</button>
        <button class="btn icon-only" id="cmp-close" aria-label="Schließen">${ic("x")}</button>
      </div>
      <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:12px">
        <figure style="margin:0"><img src="${esc(g.source_url)}" style="width:100%;border-radius:10px"><figcaption class="muted small">Original (DE)</figcaption></figure>
        <figure style="margin:0"><img src="${esc(r.url || "")}" style="width:100%;border-radius:10px"><figcaption class="muted small">${esc(langName(r.language))}</figcaption></figure>
      </div>
    </div></div>`;
  const close = () => (host.innerHTML = "");
  $("#cmp-close").onclick = close;
  $("#cmp-bg").onclick = (e) => { if (e.target.id === "cmp-bg") close(); };
  const set = async (fields, msg) => {
    try {
      const { error } = await sb.from("image_translations").update({ ...fields, updated_at: new Date().toISOString() }).eq("id", r.id);
      if (error) throw error;
      toast(msg); close(); await loadImages();
    } catch (e) { toast("Fehler: " + e.message, true); }
  };
  $("#cmp-reject") && ($("#cmp-reject").onclick = () => set({ status: "rejected" }, "Abgelehnt – die App zeigt das Original."));
  $("#cmp-accept") && ($("#cmp-accept").onclick = () => set({ status: "completed" }, "Wird wieder verwendet."));
  $("#cmp-redo").onclick = () => set({ status: "pending", force: true, error: null, attempts: 0, requested_at: new Date().toISOString() }, "Eingereiht – Start spätestens in ~30 Minuten.");
}
