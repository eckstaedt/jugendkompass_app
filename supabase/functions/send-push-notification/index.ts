// Edge Function: send-push-notification
// Wird vom DB-Trigger notify_new_content() aufgerufen, wenn ein neuer
// Inhalt in posts / impulses / verse_of_the_day / messages / videos / polls
// eingefügt wird. Diese Version sendet pro Device-Token in der jeweiligen
// Sprache (device_tokens.language). Texte werden aus content_translations
// gezogen, mit Fallback auf das Original (DE).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY") ?? "";
const FCM_PROJECT_ID = Deno.env.get("FCM_PROJECT_ID") ?? "";
const FCM_SERVICE_ACCOUNT_JSON = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON") ?? "";

type TriggerPayload = {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  schema: string;
  record: Record<string, any> | null;
  old_record: Record<string, any> | null;
};

// Welche DB-Tabelle → Welche Felder sind Title/Body und welcher
// Notification-Toggle in device_tokens steuert das Senden.
const TABLE_MAP: Record<
  string,
  {
    titleField: string;
    bodyField: string;
    toggle: "verse_notifications" | "content_notifications";
    fallbackTitle?: string;
  }
> = {
  posts: { titleField: "title", bodyField: "body", toggle: "content_notifications" },
  impulses: { titleField: "title", bodyField: "impulse_text", toggle: "content_notifications" },
  messages: { titleField: "title", bodyField: "message", toggle: "content_notifications", fallbackTitle: "Neue Kurznachricht" },
  videos: { titleField: "title", bodyField: "description", toggle: "content_notifications" },
  polls: { titleField: "question", bodyField: "question", toggle: "content_notifications", fallbackTitle: "Neue Umfrage" },
  verse_of_the_day: { titleField: "reference", bodyField: "verse", toggle: "verse_notifications", fallbackTitle: "Vers des Tages" },
};

// Sehr einfacher HTML→Plain-Text Helfer für Notification-Body
function stripHtml(input: string | null | undefined): string {
  if (!input) return "";
  return input
    .replace(/<style[\s\S]*?<\/style>/gi, "")
    .replace(/<script[\s\S]*?<\/script>/gi, "")
    .replace(/<\/(p|div|br|li|h[1-6])>/gi, "\n")
    .replace(/<br\s*\/?\s*>/gi, "\n")
    .replace(/<[^>]+>/g, "")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/\s+\n/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

function truncate(s: string, max = 240): string {
  if (s.length <= max) return s;
  return s.slice(0, max - 1).trimEnd() + "…";
}

// ---------- FCM HTTP v1 (Service Account JWT) ----------
let cachedAccessToken: { token: string; exp: number } | null = null;

async function getFcmAccessToken(): Promise<string | null> {
  if (!FCM_SERVICE_ACCOUNT_JSON) return null;
  const now = Math.floor(Date.now() / 1000);
  if (cachedAccessToken && cachedAccessToken.exp - 60 > now) {
    return cachedAccessToken.token;
  }
  const sa = JSON.parse(FCM_SERVICE_ACCOUNT_JSON);
  const header = { alg: "RS256", typ: "JWT" };
  const claims = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
  const enc = (obj: unknown) =>
    btoa(JSON.stringify(obj))
      .replace(/=/g, "")
      .replace(/\+/g, "-")
      .replace(/\//g, "_");
  const unsigned = `${enc(header)}.${enc(claims)}`;

  const pem = (sa.private_key as string)
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const keyBytes = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    keyBytes,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sigBuf = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(unsigned),
  );
  const sig = btoa(String.fromCharCode(...new Uint8Array(sigBuf)))
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
  const jwt = `${unsigned}.${sig}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  if (!tokenRes.ok) {
    console.error("FCM token error", await tokenRes.text());
    return null;
  }
  const data = await tokenRes.json();
  cachedAccessToken = { token: data.access_token, exp: now + (data.expires_in ?? 3600) };
  return cachedAccessToken.token;
}

async function sendFcmV1(
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<{ ok: boolean; status: number; body?: string }> {
  const accessToken = await getFcmAccessToken();
  if (!accessToken || !FCM_PROJECT_ID) {
    return { ok: false, status: 0, body: "FCM v1 not configured" };
  }
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          data,
        },
      }),
    },
  );
  return { ok: res.ok, status: res.status, body: res.ok ? undefined : await res.text() };
}

// Legacy-Fallback (FCM Server Key) – nur falls FCM v1 nicht konfiguriert ist
async function sendFcmLegacy(
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
) {
  if (!FCM_SERVER_KEY) return { ok: false, status: 0, body: "FCM legacy key missing" };
  const res = await fetch("https://fcm.googleapis.com/fcm/send", {
    method: "POST",
    headers: {
      Authorization: `key=${FCM_SERVER_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ to: token, notification: { title, body }, data }),
  });
  return { ok: res.ok, status: res.status, body: res.ok ? undefined : await res.text() };
}

async function sendPush(
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
) {
  if (FCM_SERVICE_ACCOUNT_JSON && FCM_PROJECT_ID) {
    return sendFcmV1(token, title, body, data);
  }
  return sendFcmLegacy(token, title, body, data);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    // Auth: nur der DB-Trigger (Service-Role) darf diesen Endpunkt aufrufen
    const bearer = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "").trim();
    if (!bearer || bearer !== SERVICE_ROLE) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const payload = (await req.json()) as TriggerPayload;
    const tableCfg = TABLE_MAP[payload.table];
    if (!tableCfg || !payload.record) {
      return new Response(JSON.stringify({ skipped: true, reason: "table not mapped" }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE, {
      auth: { persistSession: false },
    });

    const record = payload.record;
    const contentId: string | null = record.content_id ?? null;
    const originalTitle: string =
      record[tableCfg.titleField] || tableCfg.fallbackTitle || "";
    const originalBody: string = record[tableCfg.bodyField] || "";

    // Übersetzungen für diesen content_id laden (alle Sprachen)
    const translations: Record<string, Record<string, string>> = {};
    if (contentId) {
      const { data: trs, error: trErr } = await supabase
        .from("content_translations")
        .select("language, field_name, value")
        .eq("content_id", contentId);
      if (trErr) console.error("translations fetch error", trErr);
      for (const r of trs ?? []) {
        translations[r.language] ??= {};
        translations[r.language][r.field_name] = r.value as string;
      }
    }

    const resolveText = (lang: string, field: string, fallback: string) =>
      translations[lang]?.[field] ?? fallback;

    // Aktive Tokens für die jeweilige Toggle-Spalte holen
    const { data: tokens, error: tokensErr } = await supabase
      .from("device_tokens")
      .select("fcm_token, language, " + tableCfg.toggle)
      .not("fcm_token", "is", null)
      .eq(tableCfg.toggle, true);

    if (tokensErr) {
      console.error("device_tokens fetch error", tokensErr);
      return new Response(JSON.stringify({ error: tokensErr.message }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const results: Array<{ token: string; lang: string; ok: boolean; status: number }> = [];

    // Doppelte fcm_token entfernen (ein Gerät kann mehrfach registriert sein)
    const seenTokens = new Set<string>();
    const uniqueTokens = (tokens ?? []).filter((t: any) => {
      if (!t.fcm_token || seenTokens.has(t.fcm_token)) return false;
      seenTokens.add(t.fcm_token);
      return true;
    });

    for (const t of uniqueTokens) {
      const token = (t as any).fcm_token as string;
      const lang = ((t as any).language as string) || "de";
      const title = truncate(
        stripHtml(resolveText(lang, tableCfg.titleField, originalTitle)),
        80,
      );
      const body = truncate(
        stripHtml(resolveText(lang, tableCfg.bodyField, originalBody)),
        240,
      );

      const data: Record<string, string> = {
        type: payload.table,
        content_id: contentId ?? "",
        entity_id: String(record.id ?? ""),
        language: lang,
      };

      try {
        const r = await sendPush(token, title || tableCfg.fallbackTitle || "Jugendkompass", body, data);
        results.push({ token: token.slice(0, 12) + "…", lang, ok: r.ok, status: r.status });
        if (!r.ok) console.warn("FCM send failed", lang, r.status, r.body);
      } catch (e) {
        console.error("FCM exception", e);
        results.push({ token: token.slice(0, 12) + "…", lang, ok: false, status: 0 });
      }
    }

    const sent = results.filter((r) => r.ok).length;
    return new Response(
      JSON.stringify({
        success: true,
        table: payload.table,
        content_id: contentId,
        total: results.length,
        sent,
        per_language: results.reduce<Record<string, number>>((acc, r) => {
          if (r.ok) acc[r.lang] = (acc[r.lang] ?? 0) + 1;
          return acc;
        }, {}),
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("send-push-notification error", e);
    return new Response(JSON.stringify({ error: (e as Error).message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
