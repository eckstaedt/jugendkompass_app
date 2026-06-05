// Edge Function: dispatch-message-pushes
// Manueller Trigger zum Versand einer Kurznachricht-Push an alle App-Nutzer.
// Body: { message_id: number, force?: boolean }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_PROJECT_ID = Deno.env.get("FCM_PROJECT_ID") ?? "";
const FCM_SERVICE_ACCOUNT_JSON =
  Deno.env.get("FCM_SERVICE_ACCOUNT_JSON") ??
  Deno.env.get("FCM_SERVICE_ACCOUNT_KEY") ??
  "";

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

async function sendFcm(token: string, title: string, body: string, data: Record<string, string>, imageUrl?: string) {
  const accessToken = await getFcmAccessToken();
  if (!accessToken || !FCM_PROJECT_ID) return { ok: false, status: 0, body: "FCM not configured" };
  const notification: Record<string, string> = { title, body };
  if (imageUrl) notification.image = imageUrl;
  const message: Record<string, unknown> = { token, notification, data };
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
      headers: { Authorization: `Bearer ${accessToken}`, "Content-Type": "application/json" },
      body: JSON.stringify({ message }),
    },
  );
  return { ok: res.ok, status: res.status, body: res.ok ? undefined : await res.text() };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    // Auth: admin only
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    const userClient = createClient(SUPABASE_URL, Deno.env.get("SUPABASE_ANON_KEY")!, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: claims } = await userClient.auth.getClaims(authHeader.replace("Bearer ", ""));
    const userId = claims?.claims?.sub;
    if (!userId) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE, { auth: { persistSession: false } });
    const { data: isAdmin } = await supabase.rpc("is_admin", { user_id: userId });
    if (!isAdmin) {
      return new Response(JSON.stringify({ error: "Forbidden" }), {
        status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = await req.json().catch(() => ({} as any));
    const messageId: number | undefined =
      typeof body?.message_id === "number" ? body.message_id : undefined;
    const force: boolean = body?.force === true;
    if (!messageId) {
      return new Response(JSON.stringify({ error: "message_id is required" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: msg, error: msgErr } = await supabase
      .from("messages")
      .select("id, content_id, title, message, image_url, notification_sent_at")
      .eq("id", messageId)
      .maybeSingle();
    if (msgErr) throw msgErr;
    if (!msg) {
      return new Response(JSON.stringify({ error: "Nachricht nicht gefunden" }), {
        status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (!force) {
      const { data: claimed, error: claimErr } = await supabase
        .from("messages")
        .update({ notification_sent_at: new Date().toISOString() })
        .eq("id", msg.id)
        .is("notification_sent_at", null)
        .select("id")
        .maybeSingle();
      if (claimErr) throw claimErr;
      if (!claimed) {
        return new Response(JSON.stringify({ error: "Bereits gesendet" }), {
          status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
    } else {
      await supabase
        .from("messages")
        .update({ notification_sent_at: new Date().toISOString() })
        .eq("id", msg.id);
    }

    const translations: Record<string, Record<string, string>> = {};
    if (msg.content_id) {
      const { data: trs } = await supabase
        .from("content_translations")
        .select("language, field_name, value")
        .eq("content_id", msg.content_id)
        .in("field_name", ["title", "message"]);
      for (const r of trs ?? []) {
        translations[r.language] ??= {};
        translations[r.language][r.field_name] = r.value as string;
      }
    }

    const origTitle = msg.title ?? "Neue Kurznachricht";
    const origBody = msg.message ?? "";

    const { data: tokens, error: tokErr } = await supabase
      .from("device_tokens")
      .select("fcm_token, language")
      .not("fcm_token", "is", null)
      .eq("content_notifications", true);
    if (tokErr) throw tokErr;

    let sent = 0;
    for (const t of tokens ?? []) {
      const lang = (t as any).language || "de";
      const title = truncate(stripHtml(translations[lang]?.title ?? origTitle), 80);
      const text = truncate(stripHtml(translations[lang]?.message ?? origBody), 240);
      try {
        const r = await sendFcm((t as any).fcm_token, title || "Jugendkompass", text, {
          contentType: "message",
          contentId: msg.content_id ?? "",
          entity_id: String(msg.id),
          language: lang,
        }, (msg as any).image_url ?? undefined);
        if (r.ok) sent++;
        else console.warn("FCM fail", lang, r.status, r.body);
      } catch (e) {
        console.error("FCM exception", e);
      }
    }

    return new Response(
      JSON.stringify({ message_id: msg.id, sent, total: tokens?.length ?? 0 }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("dispatch-message-pushes error", e);
    return new Response(JSON.stringify({ error: (e as Error).message }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
