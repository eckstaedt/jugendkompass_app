// Edge Function: send-test-push
// Sendet eine Test-Push an ausgewählte Einträge der Tabelle test_push_devices.
// Nur Admins (auth.uid() muss is_admin = true sein).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
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

async function sendFcm(
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
  imageUrl?: string,
) {
  const accessToken = await getFcmAccessToken();
  if (!accessToken || !FCM_PROJECT_ID) {
    return { ok: false, status: 0, error: "FCM nicht konfiguriert" };
  }
  const notification: Record<string, string> = { title, body };
  if (imageUrl) notification.image = imageUrl;
  const message: Record<string, unknown> = {
    token,
    notification,
    data,
  };
  if (imageUrl) {
    message.android = { notification: { image: imageUrl } };
    message.apns = {
      payload: { aps: { "mutable-content": 1 } },
      fcm_options: { image: imageUrl },
    };
  }
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ message }),
    },
  );
  if (res.ok) return { ok: true, status: res.status };
  return { ok: false, status: res.status, error: await res.text() };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    // Auth check
    const authHeader = req.headers.get("Authorization") ?? "";
    const jwt = authHeader.replace(/^Bearer\s+/i, "");
    if (!jwt) {
      return new Response(JSON.stringify({ error: "Nicht authentifiziert" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const userClient = createClient(SUPABASE_URL, ANON_KEY, {
      global: { headers: { Authorization: `Bearer ${jwt}` } },
      auth: { persistSession: false },
    });
    const { data: userData, error: userErr } = await userClient.auth.getUser();
    if (userErr || !userData.user) {
      return new Response(JSON.stringify({ error: "Ungültiges Token" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const admin = createClient(SUPABASE_URL, SERVICE_ROLE, { auth: { persistSession: false } });
    const { data: isAdminData, error: adminErr } = await admin.rpc("is_admin", {
      user_id: userData.user.id,
    });
    if (adminErr || !isAdminData) {
      return new Response(JSON.stringify({ error: "Nur für Admins" }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = await req.json().catch(() => ({}));
    const deviceIds: string[] = Array.isArray(body.device_ids) ? body.device_ids : [];
    const title: string = String(body.title ?? "").trim();
    const text: string = String(body.body ?? "").trim();
    const extraData: Record<string, string> = body.data ?? {};
    const imageUrl: string | undefined =
      typeof body.image_url === "string" && body.image_url.trim() ? body.image_url.trim() : undefined;

    if (deviceIds.length === 0 || !title || !text) {
      return new Response(
        JSON.stringify({ error: "device_ids, title und body sind erforderlich" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const { data: devices, error: devErr } = await admin
      .from("test_push_devices")
      .select("id, label, fcm_token, language")
      .in("id", deviceIds);
    if (devErr) throw devErr;

    const results: Array<{
      id: string;
      label: string;
      ok: boolean;
      status: number;
      error?: string;
    }> = [];

    for (const d of devices ?? []) {
      try {
        const r = await sendFcm(
          d.fcm_token,
          title,
          text,
          {
            type: "test",
            language: d.language ?? "de",
            ...extraData,
          },
          imageUrl,
        );
        results.push({ id: d.id, label: d.label, ok: r.ok, status: r.status, error: r.error });
      } catch (e) {
        results.push({
          id: d.id,
          label: d.label,
          ok: false,
          status: 0,
          error: (e as Error).message,
        });
      }
    }

    return new Response(JSON.stringify({ results }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("send-test-push error", e);
    return new Response(JSON.stringify({ error: (e as Error).message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
