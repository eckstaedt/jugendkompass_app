// Edge Function: notify-new-subscription
// Wird vom DB-Trigger nach INSERT in public.subscriptions aufgerufen.
// Sendet eine Push-Benachrichtigung an alle Test-Geräte (test_push_devices).

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
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY") ?? "";
const RESEND_FROM = Deno.env.get("RESEND_FROM") ?? "Jugendkompass <onboarding@resend.dev>";

async function sendConfirmationEmail(sub: {
  email: string;
  first_name: string;
  last_name: string;
  street: string;
  postal_code: string;
  city: string;
  country: string;
  address_extra: string | null;
  shipping_method: string;
}) {
  if (!RESEND_API_KEY) {
    console.warn("RESEND_API_KEY nicht gesetzt – überspringe Bestätigungsmail");
    return;
  }
  const method = sub.shipping_method === "pickup" ? "Abholung" : "Standardversand";
  const addressLine = `${sub.street}${sub.address_extra ? ", " + sub.address_extra : ""}`;
  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 560px; margin: 0 auto; color: #1a1a1a;">
      <h2 style="color:#1a1a1a;">Vielen Dank für dein Print-Abo, ${sub.first_name}!</h2>
      <p>Wir haben dein Abonnement der Zeitschrift <strong>Jugendkompass</strong> erfolgreich empfangen.</p>
      <h3 style="margin-top:24px;">Deine Daten</h3>
      <p style="margin:4px 0;"><strong>Name:</strong> ${sub.first_name} ${sub.last_name}</p>
      <p style="margin:4px 0;"><strong>Adresse:</strong><br/>${addressLine}<br/>${sub.postal_code} ${sub.city}<br/>${sub.country}</p>
      <p style="margin:4px 0;"><strong>Versandart:</strong> ${method}</p>
      <p style="margin-top:24px;">Du erhältst die nächste Ausgabe automatisch per Post${sub.shipping_method === "pickup" ? " bzw. kannst sie abholen" : ""}.</p>
      <p>Bei Fragen antworte einfach auf diese E-Mail.</p>
      <p style="margin-top:32px;">Herzliche Grüße,<br/>Dein Jugendkompass-Team</p>
    </div>
  `;
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${RESEND_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: RESEND_FROM,
      to: [sub.email],
      subject: "Bestätigung deines Print-Abos – Jugendkompass",
      html,
    }),
  });
  if (!res.ok) {
    console.error("Resend Fehler", res.status, await res.text());
  }
}

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
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  if (!res.ok) { console.error("FCM token error", await res.text()); return null; }
  const data = await res.json();
  cachedAccessToken = { token: data.access_token, exp: now + (data.expires_in ?? 3600) };
  return cachedAccessToken.token;
}

async function sendFcm(token: string, title: string, body: string, data: Record<string, string>) {
  const accessToken = await getFcmAccessToken();
  if (!accessToken || !FCM_PROJECT_ID) return { ok: false, status: 0, error: "FCM nicht konfiguriert" };
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`,
    {
      method: "POST",
      headers: { Authorization: `Bearer ${accessToken}`, "Content-Type": "application/json" },
      body: JSON.stringify({ message: { token, notification: { title, body }, data } }),
    },
  );
  if (res.ok) return { ok: true, status: res.status };
  return { ok: false, status: res.status, error: await res.text() };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  try {
    const { subscription_id } = await req.json().catch(() => ({}));
    if (!subscription_id) {
      return new Response(JSON.stringify({ error: "subscription_id fehlt" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const admin = createClient(SUPABASE_URL, SERVICE_ROLE, { auth: { persistSession: false } });

    const { data: sub, error: subErr } = await admin
      .from("subscriptions")
      .select("first_name, last_name, city, shipping_method")
      .eq("id", subscription_id)
      .maybeSingle();
    if (subErr) throw subErr;
    if (!sub) {
      return new Response(JSON.stringify({ error: "Abo nicht gefunden" }), {
        status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: devices, error: devErr } = await admin
      .from("test_push_devices")
      .select("id, label, fcm_token");
    if (devErr) throw devErr;

    const title = "Neues Print-Abo";
    const method = sub.shipping_method === "pickup" ? "Abholung" : "Standardversand";
    const body = `${sub.first_name} ${sub.last_name} aus ${sub.city} (${method})`;

    const results: Array<{ id: string; ok: boolean; status: number; error?: string }> = [];
    for (const d of devices ?? []) {
      try {
        const r = await sendFcm(d.fcm_token, title, body, {
          type: "subscription",
          subscription_id: String(subscription_id),
        });
        results.push({ id: d.id, ok: r.ok, status: r.status, error: r.error });
      } catch (e) {
        results.push({ id: d.id, ok: false, status: 0, error: (e as Error).message });
      }
    }

    return new Response(JSON.stringify({ results }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("notify-new-subscription error", e);
    return new Response(JSON.stringify({ error: (e as Error).message }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
