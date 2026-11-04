const { createClient } = window.supabase;

const CFG = window.TP_CONFIG;
const sb = createClient(CFG.supabaseUrl, CFG.supabaseAnonKey, {
  auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true },
});

// ─── Constants ──────────────────────────────────────────────────────────────
const TYPES = {
  post: { label: "Artikel", icon: "📰" },
  message: { label: "Nachrichten", icon: "💬" },
  impulse: { label: "Impulse", icon: "💡" },
  video: { label: "Videos", icon: "🎬" },
  verse: { label: "Tagesverse", icon: "📖" },
  poll: { label: "Umfragen", icon: "📊" },
  edition: { label: "Ausgaben", icon: "📚" },
  category: { label: "Kategorien", icon: "🏷️" },
};
const LANGS = {
  en: "Englisch", ru: "Russisch", es: "Spanisch", pl: "Polnisch", tr: "Türkisch", he: "Hebräisch",
  fr: "Französisch", it: "Italienisch", uk: "Ukrainisch", ro: "Rumänisch", pt: "Portugiesisch", ar: "Arabisch",
};
const STATUS_LABEL = {
  pending: "wartend", processing: "in Arbeit", completed: "fertig", failed: "fehlgeschlagen",
  queued: "eingereiht", retry: "Retry", requeued: "erneut eingereiht", admin: "Admin",
};

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
  audios: { rows: null, q: "", filter: "all", uploading: {} },
  drawer: null,
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
function typeLabel(t) { return TYPES[t] ? `${TYPES[t].icon} ${TYPES[t].label}` : t; }
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
      <h1>🌍 Übersetzung</h1>
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
  if (state.tab === "audio" && state.audios.rows === null) await loadAudios();
  if (state.drawer) await refreshDrawer();
}

// ─── Shell ──────────────────────────────────────────────────────────────────
function renderShell() {
  $("#app").innerHTML = `
    <header class="topbar"><div class="topbar-inner">
      <div class="brand">🌍 Übersetzung <small>Jugendkompass</small></div>
      <nav class="tabs" id="tabs"></nav>
      <div class="spacer"></div>
      <span class="live" id="live"><span class="dot off"></span> verbinde …</span>
      <div class="user">${esc(state.session.user.email)} <button class="btn sm" id="logout">Abmelden</button></div>
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
    ["logs", "Logs"],
    ["audio", "Audios"],
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
      <div class="icon">💳</div>
      <div class="txt"><strong>Claude-Guthaben ist aufgebraucht</strong>
        Die Anthropic-API lehnt Anfragen ab („credit balance is too low“). ${fmtN(t.failed)} Jobs sind deshalb fehlgeschlagen.
        Guthaben aufladen und danach alle fehlgeschlagenen Übersetzungen neu starten.</div>
      <div class="btn-row">
        <a class="btn solid-danger" href="${CFG.billingUrl}" target="_blank" rel="noopener">Guthaben aufladen ↗</a>
        <button class="btn" data-act="retry-all">↻ Alle fehlgeschlagenen neu starten</button>
      </div></div>`;
  }
  if (o.auth_error) {
    return `<div class="banner bad"><div class="icon">🔑</div>
      <div class="txt"><strong>API-Key ungültig oder fehlt</strong>Den Secret <span class="mono">ANTHROPIC_API_KEY</span> der Edge Function <span class="mono">process-translation-jobs</span> im Supabase-Dashboard prüfen.</div>
      <div class="btn-row"><a class="btn" target="_blank" rel="noopener" href="https://supabase.com/dashboard/project/vdcdibvclaulqxfjyzpq/functions/secrets">Supabase Secrets ↗</a>
      <button class="btn" data-act="retry-all">↻ Fehlgeschlagene neu starten</button></div></div>`;
  }
  if (t.failed > 0) {
    return `<div class="banner warn"><div class="icon">⚠️</div>
      <div class="txt"><strong>${fmtN(t.failed)} Übersetzungen fehlgeschlagen</strong>Details im Tab „Jobs“ (Filter: fehlgeschlagen).</div>
      <div class="btn-row"><button class="btn" data-act="retry-all">↻ Alle neu starten</button>
      <button class="btn" data-act="goto-failed">Ansehen</button></div></div>`;
  }
  if (t.pending + t.processing === 0 && t.all > 0) {
    return `<div class="banner ok"><div class="icon">✅</div><div class="txt"><strong>Alles übersetzt</strong>Neue oder geänderte Inhalte werden automatisch übersetzt.</div></div>`;
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
        return action("", async () => `${typeLabel(type)}: ${fmtN(await rpc("tp_rerun_type", { p_content_type: type, p_force: false }))} Jobs eingereiht`);
      }
      if (a === "force-type") {
        if (!confirm(`${typeLabel(type)} komplett neu übersetzen?\n\nAlle automatischen Übersetzungen dieser Kategorie werden neu erzeugt (verbraucht Claude-Guthaben). Manuelle Korrekturen bleiben erhalten. Bis zur neuen Übersetzung bleiben die alten sichtbar.`)) return;
        return action("", async () => `${typeLabel(type)}: ${fmtN(await rpc("tp_rerun_type", { p_content_type: type, p_force: true }))} Jobs neu übersetzen`);
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
        <button class="btn" data-act="run-now">▶ Worker jetzt starten</button>
        <button class="btn primary" data-act="retry-all" ${t.failed ? "" : "disabled"}>↻ Alle Fehlgeschlagenen neu</button>
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
      <button class="btn sm" data-act="retry-type" data-type="${type}" ${q.failed ? "" : "disabled"}>↻ Fehlgeschlagene</button>
      <button class="btn sm" data-act="rerun-type" data-type="${type}">Neu prüfen</button>
      <button class="btn sm danger" data-act="force-type" data-type="${type}">Komplett neu</button>
      <button class="btn sm" data-act="goto-type" data-type="${type}">Jobs →</button>
    </div>
  </div>`;
}

function audioCard(a, langs) {
  if (!a) return "";
  const total = Number(a.total || 0);
  return `<div class="card card-pad">
    <div class="type-head"><div class="name">🎧 Audios (vertont)</div><span class="muted small">${fmtN(total)} Audios</span></div>
    <div class="chips"><span class="chip">manuell hochgeladen</span></div>
    ${langs.map((l) => {
      const n = Number(a.languages?.[l] || 0);
      const pct = total ? Math.min(100, Math.round((n / total) * 100)) : 0;
      return `<div class="lang-row"><span class="code">${esc(l)}</span><div class="bar"><span class="${pct >= 100 ? "full" : ""}" style="width:${pct}%"></span></div><span class="pct">${fmtN(n)}/${fmtN(total)}</span></div>`;
    }).join("")}
    <div class="type-actions"><button class="btn sm" onclick="document.querySelector('[data-tab=audio]').click()">Audios verwalten →</button></div>
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
        ${Object.keys(TYPES).map((t) => `<option value="${t}" ${j.type === t ? "selected" : ""}>${typeLabel(t)}</option>`).join("")}
      </select>
      <input class="input" id="f-q" placeholder="Suche: Titel, ID oder Fehlertext" value="${esc(j.q)}" style="flex:1;min-width:200px">
      <button class="btn" id="f-retry">↻ Gefilterte Fehlgeschlagene neu</button>
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
        <td><button class="btn sm" data-rerun="${i}">↻</button></td>
      </tr>`).join("")}</tbody></table>
    <div class="pager">
      <span class="muted small">${fmtN(j.offset + 1)}–${fmtN(Math.min(j.offset + j.limit, j.total))} von ${fmtN(j.total)}</span>
      <button class="btn sm" id="pg-prev" ${j.offset === 0 ? "disabled" : ""}>←</button>
      <button class="btn sm" id="pg-next" ${j.offset + j.limit >= j.total ? "disabled" : ""}>→</button>
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
document.addEventListener("keydown", (e) => { if (e.key === "Escape") closeDrawer(); });

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
    <button class="btn sm close" id="dr-close">✕</button>
    <div class="muted small">${typeLabel(j.content_type)} · Job #${j.id}</div>
    <h2>${esc(j.title)}</h2>
    <div style="margin-top:6px">${statusChip(j.status)}</div>
    <div class="btn-row" style="margin-top:14px">
      <button class="btn primary" id="dr-rerun">↻ Neu übersetzen (nur Geändertes)</button>
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
    ${d.translations === null ? `<div class="muted">Lade …</div>` : Object.keys(byLang).length === 0 ? `<div class="muted">Noch keine Übersetzungen vorhanden.</div>` :
      Object.entries(byLang).map(([lang, fields]) => `<div class="tr-block"><header><span>${esc(langName(lang))}</span><span class="muted small">${esc(ago(fields[0].updated_at))}</span></header>
        ${fields.map((f) => `<div class="f"><b>${esc(f.field_name)} ${f.status === "manual" ? "· manuell" : ""}</b><div>${esc(f.value)}</div></div>`).join("")}</div>`).join("")}
    <h3 style="margin-top:20px">Verlauf</h3>
    ${d.events === null ? `<div class="muted">Lade …</div>` : d.events.length === 0 ? `<div class="muted small">Keine Einträge (Verlauf wird seit Einrichtung des Panels aufgezeichnet).</div>` :
      `<table><tbody>${d.events.map((e) => `<tr><td class="small muted" style="white-space:nowrap">${esc(fmtTime(e.created_at))}</td><td>${statusChip(e.event)}</td><td class="small">${esc(shortError(e.message) || "")}</td></tr>`).join("")}</tbody></table>`}
  </div>`;
  el.querySelector(".drawer").scrollTop = prevScroll;
  $("#dr-close").onclick = closeDrawer;
  $("#dr-rerun").onclick = () => action("", async () => { await rpc("tp_rerun_record", { p_content_type: j.content_type, p_record_id: j.record_id, p_force: false }); await refreshDrawer(); return "Neu eingereiht"; });
  $("#dr-force").onclick = () => {
    if (!confirm("Alle automatischen Übersetzungen dieses Eintrags neu erzeugen?")) return;
    action("", async () => { await rpc("tp_rerun_record", { p_content_type: j.content_type, p_record_id: j.record_id, p_force: true }); await refreshDrawer(); return "Wird komplett neu übersetzt"; });
  };
}

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
        ${Object.keys(TYPES).map((t) => `<option value="${t}" ${ev.type === t ? "selected" : ""}>${typeLabel(t)}</option>`).join("")}
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
function activeLangs() {
  return (state.overview?.languages || []).filter((l) => l.active).map((l) => l.code);
}

function renderAudioShell() {
  const a = state.audios;
  $("#main").innerHTML = `
    <div class="banner ok" style="background:var(--info-soft);border-color:transparent">
      <div class="icon">🎧</div>
      <div class="txt"><strong>Vertonte Audios</strong>Lade zu jedem deutschen Audio eine übersetzte Version hoch und wähle die Sprache.
      Stellt jemand die App z. B. auf Englisch, hört er automatisch die englische Datei. Ohne Übersetzung wird das deutsche Original abgespielt.</div>
    </div>
    <div class="toolbar">
      <input class="input" id="a-q" placeholder="Audio / Artikel suchen" value="${esc(a.q)}" style="flex:1;min-width:200px">
      <select class="input" id="a-filter">
        <option value="all" ${a.filter === "all" ? "selected" : ""}>Alle Audios</option>
        <option value="missing" ${a.filter === "missing" ? "selected" : ""}>Mit fehlenden Sprachen</option>
        <option value="has" ${a.filter === "has" ? "selected" : ""}>Mit Übersetzungen</option>
      </select>
      <button class="btn" id="a-reload">⟳ Aktualisieren</button>
    </div>
    <div class="card" id="audio-list"><div class="empty">Lade …</div></div>`;
  let deb;
  $("#a-q").oninput = (e) => { clearTimeout(deb); deb = setTimeout(() => { a.q = e.target.value.trim().toLowerCase(); renderAudioList(); }, 200); };
  $("#a-filter").onchange = (e) => { a.filter = e.target.value; renderAudioList(); };
  $("#a-reload").onclick = () => loadAudios();
  if (a.rows) renderAudioList();
}

async function loadAudios() {
  try {
    state.audios.rows = await rpc("tp_audios");
  } catch (e) {
    const el = $("#audio-list");
    if (el) el.innerHTML = `<div class="empty">Fehler: ${esc(e.message)}</div>`;
    return;
  }
  renderAudioList();
}

function renderAudioList() {
  const el = $("#audio-list");
  if (!el || !state.audios.rows) return;
  const langs = activeLangs();
  const a = state.audios;
  let rows = state.audios.rows;
  if (a.q) rows = rows.filter((r) => `${r.title} ${r.edition || ""} ${r.url}`.toLowerCase().includes(a.q));
  if (a.filter === "missing") rows = rows.filter((r) => langs.some((l) => !r.translations.find((t) => t.language === l)));
  if (a.filter === "has") rows = rows.filter((r) => r.translations.length > 0);
  if (!rows.length) { el.innerHTML = `<div class="empty">Keine Audios gefunden.</div>`; return; }
  const shown = rows.slice(0, 150);
  el.innerHTML = shown.map((r) => {
    const tr = Object.fromEntries(r.translations.map((t) => [t.language, t]));
    const missing = langs.filter((l) => !tr[l]);
    return `<div class="audio-item" data-audio="${r.audio_id}">
      ${r.image_url ? `<img class="thumb" src="${esc(r.image_url)}" alt="" loading="lazy">` : `<div class="thumb"></div>`}
      <div>
        <div class="audio-title">${esc(r.title)}</div>
        <div class="muted small">${r.edition ? esc(r.edition) + " · " : ""}<a href="${esc(r.url)}" target="_blank" rel="noopener">Original (Deutsch) ↗</a></div>
        <div class="audio-langs">
          ${langs.map((l) => tr[l]
            ? `<span class="lang-pill has" title="${esc(tr[l].file_name || "")}">✓ ${esc(l.toUpperCase())}
                <button title="Anhören" data-play="${esc(tr[l].url)}">▶</button>
                <button title="Entfernen" data-del="${esc(tr[l].id)}" data-path="${esc(tr[l].storage_path || "")}" data-lang="${esc(l)}">✕</button></span>`
            : `<span class="lang-pill missing">${esc(l.toUpperCase())} fehlt</span>`).join("")}
        </div>
        <div class="upload-row">
          <select class="input" data-lang-select>
            ${langs.map((l) => `<option value="${l}" ${missing[0] === l ? "selected" : ""}>${esc(langName(l))}${tr[l] ? " – ersetzen" : ""}</option>`).join("")}
          </select>
          <input type="file" accept="audio/*,.mp3,.m4a,.aac,.wav,.ogg" data-file>
          <button class="btn primary sm" data-upload>⬆ Hochladen</button>
          <div class="progress" hidden><span></span></div>
        </div>
        <div data-player></div>
      </div>
    </div>`;
  }).join("") + (rows.length > shown.length ? `<div class="empty small">${fmtN(rows.length - shown.length)} weitere – bitte Suche verwenden.</div>` : "");

  el.querySelectorAll("[data-play]").forEach((b) => (b.onclick = () => {
    const host = b.closest(".audio-item").querySelector("[data-player]");
    host.innerHTML = `<audio controls autoplay src="${esc(b.dataset.play)}" style="margin-top:10px;width:100%"></audio>`;
  }));
  el.querySelectorAll("[data-del]").forEach((b) => (b.onclick = async () => {
    if (!confirm(`Übersetzte Audio (${b.dataset.lang.toUpperCase()}) entfernen? Die App spielt dann wieder das deutsche Original.`)) return;
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
    ${o?.credit_error ? creditBanner() : `<div class="banner ok"><div class="icon">💳</div><div class="txt"><strong>Guthaben aktuell kein Problem</strong>In den letzten 3 Tagen kein „credit balance too low“-Fehler.</div></div>`}
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
          <a class="btn primary" href="${CFG.billingUrl}" target="_blank" rel="noopener">Guthaben aufladen ↗</a>
          <a class="btn" href="${CFG.usageUrl}" target="_blank" rel="noopener">Verbrauch ansehen ↗</a>
        </div>
      </div>
      <div class="card card-pad">
        <h2>2 · Übersetzungen neu starten</h2>
        <p class="muted">Nach dem Aufladen alle fehlgeschlagenen Jobs erneut einreihen. Bereits fertige Felder werden nicht nochmal übersetzt.</p>
        <div class="kv"><dt>Fehlgeschlagen</dt><dd><b style="color:var(--bad)">${fmtN(t.failed)}</b></dd>
          <dt>Wartend</dt><dd>${fmtN(t.pending)}</dd><dt>In Arbeit</dt><dd>${fmtN(t.processing)}</dd></div>
        <div class="btn-row">
          <button class="btn primary" data-act="retry-all" ${t.failed ? "" : "disabled"}>↻ Alle fehlgeschlagenen neu starten</button>
          <button class="btn" data-act="run-now">▶ Worker jetzt starten</button>
        </div>
      </div>
      <div class="card card-pad">
        <h2>API-Key wechseln</h2>
        <p class="muted">Falls ein anderer Anthropic-Account genutzt werden soll: neuen Key in der Console erstellen und in Supabase als Secret <span class="mono">ANTHROPIC_API_KEY</span> hinterlegen. Danach hier „Alle fehlgeschlagenen neu starten“.</p>
        <div class="btn-row">
          <a class="btn" href="https://console.anthropic.com/settings/keys" target="_blank" rel="noopener">API-Keys ↗</a>
          <a class="btn" href="https://supabase.com/dashboard/project/vdcdibvclaulqxfjyzpq/functions/secrets" target="_blank" rel="noopener">Supabase Secrets ↗</a>
        </div>
      </div>
    </div>`;
  bindCommonActions(root);
}

boot();
