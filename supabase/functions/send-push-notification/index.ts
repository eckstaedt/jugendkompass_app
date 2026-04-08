// Supabase Edge Function: send-push-notification
//
// Triggered by Database Webhooks when new content is created.
// Sends push notifications to ALL registered devices via Firebase Cloud
// Messaging (FCM) HTTP v1 API.
//
// Supported tables & notification titles:
//   posts (with audio_id)  → "Neuer Podcast"
//   posts (without audio)  → "Neuer Artikel"
//   videos                 → "Neues Video"
//   messages               → "Neue Kurznachricht"
//   editions               → "Neue Ausgabe"
//   impulses               → "Neuer Impuls"
//
// Notification format:
//   - Image: image_url from the record (if available)
//   - Title: see above (e.g. "Neuer Artikel")
//   - Body:  the title/name of the content
//
// Environment variables (automatically provided by Supabase):
//   - SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY (auto-set)
// Firebase config is hardcoded below (private project).

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ─── Firebase Config (hardcoded for private project) ────────────────────────

const FCM_PROJECT_ID = "jugendkompass-46aa7";

const FCM_SERVICE_ACCOUNT: ServiceAccountKey = {
  client_email: "firebase-adminsdk-lqlr9@jugendkompass-46aa7.iam.gserviceaccount.com",
  private_key: "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCYhKa4DFSp0dQY\nUUwjXqg+2PnZPMigupvuPDfFvLxrjAsYNvMX9KCtxPXt01rl+hiMdIQwdyb8LgI0\neXIHiqQTfR3KDqdwMLomhaLHmA34ck1aM2jyLv8Xizh+Th/7xeD+vWL9HnD+ZPB2\nnVuYtYZnOhR5IFExzKfQTAxUCE25b85lnALi2XRHqKkUfab6Byu3sg55ePPoR3/x\nvi/yAUhChO3fH0XnJPzj91RY+8IkH8xPYE1aLPE3xRki8q54SgHl3axs4XX75s7l\nlSSJRq8/iHkY9+gsoC9Wqos4bjk0DyEH3XEaeL/cjOfY2Dhab4l0WYQxTqR372RU\n9E0MBoVDAgMBAAECggEADrMmUHHbzRxMqWVYhcYvSBNojVAG9DrYIY+LPpMww9rV\nDOnq5yGsRONJYrkutyCyMgNe5D7vsnmKu90CqQhrRPeXoexkpfMEVgcmR793hT0b\nCHkRAdqWuoGwGbhU69LIGzVMr6G5+ULoTD5hYCgKwrM92ujK+pZDjFdwDr9YImmm\nrmxkWWOPNRYPifD6cOnOvbE/DyB0uk+0/yzBKAtEkSCiKhhI2FirjYCvON3+1zvn\nVUzMu2/zUFR1ZVhRvbR3IR4sjY07PPMWx2hHj+0S31v0OLlzd2tvOkKPNznXemBX\nEyIvq7N9ikzO4z6Jue5fpvRpT5p7/qm2QAaiss0qeQKBgQDIi3qv0HOiQvVGnpqC\nfWNm4sSXOth8g2f1hQsDIcqfx/hj4vourADMW/7QzBjXMAV9OZzXWL561zE6n/Hz\nstM81nabTB/ZCdr3lrxY3QtK0H9GSVRwZhQt1XAUvPhbTA2GoUhsmXVvx4LlNiZP\no/T3tb9IkW9L7kmTITmAZI0YOwKBgQDCsWAiD6pug6qgFZxIYSaw2d9kYjXhsK9W\n6tXlELfWzq24YZH5RmMyFaElHb9n+bny9HGH3oIwk0nQYAm+Zc7Dsvblh7VH0+Zc\n6UeFfSb+ht+2ySrOVHuQxCE24YzRb1GmQaZaAQQ8NhixwhuWyP8TI71Mv0+Q6ED3\nAXqILvJ+mQKBgHYk/Z0wD79q9Paqn1n6pqHJPInfaARKoecZfvhUYvuooiOuZzcx\nq7K5C7BUXNoA92rjkwumw2i4986SxcaM9jckHXG18hk53h74VXOAnZNwq1pr/uvM\np1ytHj+JaELY1isXPwSDj5TPk8SXFxDaBYodL1iAHXI9KmkcLLUAB8NbAoGAZMj5\noOhHK+qQ+0n0mytfohFHKWoFxo12VyI+E9RxtotLNrWboVUkqJq1zsb1fNezwOd1\nlgZDku3MOkhdAukk/f24/d0gpMw25kYEtj+xXfVn/fFpbWIijTBamVRtV0WvGMfH\nW7RHAvxmEC8RpR7rnHbV2dL3V2ZDqxpi2fijo5ECgYEAr2oCcfSvSOgJoryWZhMI\n4Bf2J4qNfmnsErjZi7ITlQ/T8suf/Tuon5iHc8/C2spx7KztJ/mplgOINA911CCi\nzeJdX4Q63rBgz48wTo5k0LLazUiDLAGemKxUNBwMRhuwBk/IGBP0sdkOWvgULF1P\n1UiCGQeMIZe0z4fbnbjLfbY=\n-----END PRIVATE KEY-----\n",
  token_uri: "https://oauth2.googleapis.com/token",
};

// ─── Types ──────────────────────────────────────────────────────────────────

interface WebhookPayload {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  record: Record<string, unknown>;
  schema: string;
  old_record: null | Record<string, unknown>;
}

interface ServiceAccountKey {
  client_email: string;
  private_key: string;
  token_uri: string;
}

// ─── Notification mapping ───────────────────────────────────────────────────

/** Determine the notification title and body from the webhook payload. */
function getNotificationContent(
  table: string,
  record: Record<string, unknown>
): { title: string; body: string; imageUrl: string | null } | null {
  switch (table) {
    case "posts": {
      const hasAudio = record.audio_id != null;
      return {
        title: hasAudio ? "Neuer Podcast" : "Neuer Artikel",
        body: (record.title as string) || "Neuer Inhalt verfügbar",
        imageUrl: (record.image_url as string) || null,
      };
    }
    case "videos":
      return {
        title: "Neues Video",
        body: (record.title as string) || "Neues Video verfügbar",
        imageUrl: (record.image_url as string) || null,
      };
    case "messages":
      return {
        title: "Neue Kurznachricht",
        body: (record.title as string) || (record.message as string)?.substring(0, 100) || "Neue Kurznachricht",
        imageUrl: (record.image_url as string) || null,
      };
    case "editions":
      return {
        title: "Neue Ausgabe",
        body: (record.title as string) || (record.name as string) || "Neue Ausgabe verfügbar",
        imageUrl: (record.image_url as string) || null,
      };
    case "impulses":
      return {
        title: "Neuer Impuls",
        body: (record.title as string) || "Neuer Impuls verfügbar",
        imageUrl: (record.image_url as string) || null,
      };
    default:
      return null;
  }
}

// ─── JWT / OAuth helpers ────────────────────────────────────────────────────

/** Create a signed JWT for Google OAuth 2.0 service account flow. */
async function createSignedJwt(sa: ServiceAccountKey): Promise<string> {
  const header = { alg: "RS256", typ: "JWT" };
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: sa.token_uri,
    iat: now,
    exp: now + 3600,
  };

  const encode = (obj: unknown) =>
    btoa(JSON.stringify(obj))
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=+$/, "");

  const headerB64 = encode(header);
  const payloadB64 = encode(payload);
  const unsignedToken = `${headerB64}.${payloadB64}`;

  // Import the private key
  const pemContents = sa.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");

  const binaryKey = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(unsignedToken)
  );

  const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");

  return `${unsignedToken}.${signatureB64}`;
}

/** Exchange a signed JWT for a Google OAuth 2.0 access token. */
async function getAccessToken(sa: ServiceAccountKey): Promise<string> {
  const jwt = await createSignedJwt(sa);

  const res = await fetch(sa.token_uri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const data = await res.json();
  if (!data.access_token) {
    throw new Error(`Failed to get access token: ${JSON.stringify(data)}`);
  }
  return data.access_token;
}

// ─── Main ───────────────────────────────────────────────────────────────────

serve(async (req) => {
  try {
    // Parse the webhook payload
    const payload: WebhookPayload = await req.json();
    console.log(`[send-push] Received ${payload.type} on ${payload.table}`);

    // Only process INSERT events
    if (payload.type !== "INSERT") {
      return new Response(JSON.stringify({ message: "Ignoring non-INSERT event" }), {
        status: 200,
      });
    }

    // Determine notification content based on table
    const notification = getNotificationContent(payload.table, payload.record);
    if (!notification) {
      return new Response(
        JSON.stringify({ message: `No notification mapping for table: ${payload.table}` }),
        { status: 200 }
      );
    }

    console.log(`[send-push] ${notification.title}: "${notification.body}"`);

    // ── Get all FCM tokens from Supabase ──
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const { data: devices, error } = await supabase
      .from("device_tokens")
      .select("fcm_token")
      .eq("content_notifications", true)
      .not("fcm_token", "is", null);

    if (error) {
      console.error("[send-push] Error fetching devices:", error);
      return new Response(JSON.stringify({ error: error.message }), { status: 500 });
    }

    const tokens = (devices ?? [])
      .map((d: { fcm_token: string }) => d.fcm_token)
      .filter(Boolean);

    if (tokens.length === 0) {
      console.log("[send-push] No devices with FCM tokens found");
      return new Response(JSON.stringify({ message: "No devices" }), { status: 200 });
    }

    console.log(`[send-push] Sending to ${tokens.length} devices`);

    // ── Get FCM access token via service account ──
    const projectId = FCM_PROJECT_ID;
    const serviceAccount = FCM_SERVICE_ACCOUNT;
    const accessToken = await getAccessToken(serviceAccount);

    // ── Send notification to each device ──
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

    const results = await Promise.allSettled(
      tokens.map(async (token: string) => {
        const message: Record<string, unknown> = {
          message: {
            token,
            notification: {
              title: notification.title,
              body: notification.body,
              ...(notification.imageUrl ? { image: notification.imageUrl } : {}),
            },
            // iOS-specific: show image in notification
            apns: {
              payload: {
                aps: {
                  "mutable-content": 1,
                  sound: "default",
                },
              },
              ...(notification.imageUrl
                ? {
                    fcm_options: {
                      image: notification.imageUrl,
                    },
                  }
                : {}),
            },
            // Android-specific
            android: {
              notification: {
                sound: "default",
                channel_id: "push_notifications",
                ...(notification.imageUrl ? { image: notification.imageUrl } : {}),
              },
            },
          },
        };

        const res = await fetch(fcmUrl, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify(message),
        });

        const result = await res.json();
        if (!res.ok) {
          console.error(`[send-push] FCM error for token ${token.substring(0, 15)}...:`, result);
        }
        return result;
      })
    );

    const succeeded = results.filter((r) => r.status === "fulfilled").length;
    const failed = results.filter((r) => r.status === "rejected").length;

    console.log(`[send-push] Done: ${succeeded} succeeded, ${failed} failed`);

    return new Response(
      JSON.stringify({
        message: `Sent to ${succeeded}/${tokens.length} devices`,
        succeeded,
        failed,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("[send-push] Error:", err);
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 });
  }
});
