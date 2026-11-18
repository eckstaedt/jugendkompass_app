// Edge Function: check-tomorrow-verse
// Läuft täglich um 10:00 Uhr (per pg_cron) und prüft, ob für den darauffolgenden
// Tag ein Vers des Tages existiert. Falls nicht, wird an alle Einträge in
// test_push_devices eine Erinnerungs-Push gesendet.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_PROJECT_ID = Deno.env.get("FCM_PROJECT_ID") ?? "";
const FCM_SERVICE_ACCOUNT_JSON =
  Deno.env.get("FCM_SERVICE_ACCOUNT_JSON") ??
  Deno.env.get("FCM_SERVICE_ACCOUNT_KEY") ??
  "";

let cachedAccessToken: { token: string; exp: number } | null = null;

async function getFcmAccessToken(): Promise<string | null> {
  if (!FCM_SERVICE_ACCOUNT_JSON) return null;
  const now = Math.floor(Date.now() / 1000);
  if (cachedAccessToken && cachedAccessToken.exp - 60 > now) return cachedAccessToken.token;
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
    btoa(JSON.stringify(obj)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
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
    .replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
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

async function sendFcm(token: string, title: string, body: string, data: Record<string, string>) {
  const accessToken = await getFcmAccessToken();
  if (!accessToken || !FCM_PROJECT_ID) {
    return { ok: false, status: 0, error: "FCM nicht konfiguriert" };
  }
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ message: { token, notification: { title, body }, data } }),
    },
  );
  if (res.ok) return { ok: true, status: res.status };
  return { ok: false, status: res.status, error: await res.text() };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const admin = createClient(SUPABASE_URL, SERVICE_ROLE, { auth: { persistSession: false } });

    // "Morgen" in Europe/Berlin bestimmen (Cron läuft in UTC um 09:00 UTC = 10:00 Berliner Winterzeit;
    // im Sommer 11:00 lokal — Datum bleibt aber praktisch identisch, weil noch früh am Tag).
    const berlinNow = new Date(
      new Date().toLocaleString("en-US", { timeZone: "Europe/Berlin" }),
    );
    const tomorrow = new Date(berlinNow);
    tomorrow.setDate(tomorrow.getDate() + 1);
    const tomorrowStr = tomorrow.toISOString().slice(0, 10); // YYYY-MM-DD

    const { data: existing, error: verseErr } = await admin
      .from("verse_of_the_day")
      .select("id")
      .eq("date", tomorrowStr)
      .limit(1);
    if (verseErr) throw verseErr;

    if (existing && existing.length > 0) {
      return new Response(
        JSON.stringify({ ok: true, tomorrow: tomorrowStr, verse_exists: true, sent: 0 }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const { data: devices, error: devErr } = await admin
      .from("test_push_devices")
      .select("id, label, fcm_token");
    if (devErr) throw devErr;

    const title = "Vers des Tages fehlt";
    const body = `Für morgen (${tomorrowStr}) ist noch kein Vers des Tages eingetragen.`;

    const results: Array<{ id: string; label: string; ok: boolean; status: number; error?: string }> = [];
    for (const d of devices ?? []) {
      try {
        const r = await sendFcm(d.fcm_token, title, body, {
          type: "missing_verse_reminder",
          date: tomorrowStr,
        });
        results.push({ id: d.id, label: d.label, ok: r.ok, status: r.status, error: r.error });
      } catch (e) {
        results.push({ id: d.id, label: d.label, ok: false, status: 0, error: (e as Error).message });
      }
    }

    return new Response(
      JSON.stringify({
        ok: true,
        tomorrow: tomorrowStr,
        verse_exists: false,
        sent: results.length,
        results,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("check-tomorrow-verse error", e);
    return new Response(JSON.stringify({ error: (e as Error).message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
