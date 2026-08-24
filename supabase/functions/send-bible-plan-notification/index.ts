// Supabase Edge Function: send-bible-plan-notification
//
// Sends a daily 06:30 (local device time) motivational reminder push
// notification for the "Bibel in 365 Tagen" reading plan.
//
// Only devices that have `bible_plan_started = true` (i.e. the user tapped
// "Bibelleseplan starten" on the intro screen) receive this notification.
//
// Tapping the notification deep-links straight into the reading plan screen
// via the data payload: { contentType: "bible_plan" }.
//
// Intended to be triggered by an hourly cron job (e.g. pg_cron `30 * * * *`),
// mirroring send-daily-verse-notification. Each device's local hour is
// computed from its stored IANA `timezone` (defaults to Europe/Berlin), and
// only devices whose local hour is 6 receive the push (cron runs at :30).

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ─── Firebase Config (hardcoded for private project) ────────────────────────

const FCM_PROJECT_ID = "jugendkompass-46aa7";

interface ServiceAccountKey {
  client_email: string;
  private_key: string;
  token_uri: string;
}

const FCM_SERVICE_ACCOUNT: ServiceAccountKey = {
  client_email: "firebase-adminsdk-lqlr9@jugendkompass-46aa7.iam.gserviceaccount.com",
  private_key: Deno.env.get("FCM_PRIVATE_KEY") ?? "",
  token_uri: "https://oauth2.googleapis.com/token",
};

// ─── 50 motivating "Dein Bibelleseplan" messages ────────────────────────────
//
// Templates containing {name} are only used for devices that have a
// `user_name` stored; all others fall back to the name-less templates.

const MESSAGES_WITH_NAME: string[] = [
  "Guten Morgen {name}! ☀️ Dein Bibelleseplan wartet schon auf dich.",
  "{name}, heute ist ein neuer Tag in deinem Bibelleseplan – lies dein Kapitel! 📖",
  "Hey {name} 👋 Zeit für dein heutiges Kapitel in Deinem Bibelleseplan!",
  "{name}, ein Kapitel am Tag bringt dich näher ans Ziel. Dein Bibelleseplan ruft! 🚀",
  "Guten Morgen {name}! Dein Bibelleseplan hat heute wieder ein spannendes Kapitel für dich. 📚",
  "{name}, dranbleiben lohnt sich! Öffne jetzt Dein Bibelleseplan. 💪",
  "Ein neuer Tag, ein neues Kapitel, {name}! Dein Bibelleseplan wartet. ✨",
  "{name}, dein Weg durch die Bibel geht heute weiter. Dein Bibelleseplan ist bereit! 🙏",
  "Guten Morgen {name} ☕️ – starte den Tag mit Dein Bibelleseplan.",
  "{name}, verpass dein heutiges Kapitel nicht – Dein Bibelleseplan wartet auf dich! 📖",
  "Hey {name}, schon 5 Minuten Zeit für Dein Bibelleseplan heute? 🕊️",
  "{name}, Gottes Wort wartet auf dich – schau in Dein Bibelleseplan! ❤️",
  "Guten Morgen {name}! Ein Kapitel, ein Schritt weiter. Dein Bibelleseplan. 🌅",
  "{name}, du bist auf einem großartigen Weg – weiter geht's mit Dein Bibelleseplan! 🎯",
  "Zeit aufzuwachen, {name}! Dein Bibelleseplan hat heute etwas Gutes für dich. 📖✨",
  "{name}, lass den Tag mit einem Kapitel aus Dein Bibelleseplan beginnen. 🌤️",
  "Guten Morgen {name}! Dein heutiges Kapitel in Dein Bibelleseplan wartet schon. 📚",
  "{name}, dranbleiben zählt! Öffne jetzt Dein Bibelleseplan und lies weiter. 🔥",
  "Hey {name} 🌞 Nimm dir kurz Zeit für Dein Bibelleseplan heute Morgen.",
  "{name}, ein neues Kapitel wartet in Dein Bibelleseplan – viel Freude beim Lesen! 📖",
];

const MESSAGES_GENERIC: string[] = [
  "Guten Morgen! ☀️ Dein Bibelleseplan wartet schon auf dich.",
  "Heute ist ein neuer Tag in deinem Bibelleseplan – lies dein Kapitel! 📖",
  "Zeit für dein heutiges Kapitel in Dein Bibelleseplan! 👋",
  "Ein Kapitel am Tag bringt dich näher ans Ziel. Dein Bibelleseplan ruft! 🚀",
  "Dein Bibelleseplan hat heute wieder ein spannendes Kapitel für dich. 📚",
  "Dranbleiben lohnt sich! Öffne jetzt Dein Bibelleseplan. 💪",
  "Ein neuer Tag, ein neues Kapitel! Dein Bibelleseplan wartet. ✨",
  "Dein Weg durch die Bibel geht heute weiter. Dein Bibelleseplan ist bereit! 🙏",
  "Guten Morgen ☕️ – starte den Tag mit Dein Bibelleseplan.",
  "Verpass dein heutiges Kapitel nicht – Dein Bibelleseplan wartet auf dich! 📖",
  "Schon 5 Minuten Zeit für Dein Bibelleseplan heute? 🕊️",
  "Gottes Wort wartet auf dich – schau in Dein Bibelleseplan! ❤️",
  "Guten Morgen! Ein Kapitel, ein Schritt weiter. Dein Bibelleseplan. 🌅",
  "Du bist auf einem großartigen Weg – weiter geht's mit Dein Bibelleseplan! 🎯",
  "Zeit aufzuwachen! Dein Bibelleseplan hat heute etwas Gutes für dich. 📖✨",
  "Lass den Tag mit einem Kapitel aus Dein Bibelleseplan beginnen. 🌤️",
  "Guten Morgen! Dein heutiges Kapitel in Dein Bibelleseplan wartet schon. 📚",
  "Dranbleiben zählt! Öffne jetzt Dein Bibelleseplan und lies weiter. 🔥",
  "Nimm dir kurz Zeit für Dein Bibelleseplan heute Morgen. 🌞",
  "Ein neues Kapitel wartet in Dein Bibelleseplan – viel Freude beim Lesen! 📖",
  "Kleine Schritte, große Wirkung – dein heutiges Kapitel wartet in Dein Bibelleseplan. 🌱",
  "Bleib dran! Dein Bibelleseplan freut sich auf dich heute Morgen. 😊",
  "Ein frischer Tag, ein frisches Kapitel – Dein Bibelleseplan ruft dich. 🌄",
  "Starte deinen Tag mit Gottes Wort – Dein Bibelleseplan wartet. 🙌",
  "Dein Bibelleseplan ist bereit – bist du es auch? 📖😄",
  "Guten Morgen! Vergiss dein Kapitel in Dein Bibelleseplan nicht. ⏰",
  "Jeder Tag zählt auf deinem Weg durch die Bibel – auf geht's! 🚶‍♂️📖",
  "Es ist wieder soweit: Dein Bibelleseplan hat ein neues Kapitel für dich. 📆",
  "Ein Kapitel näher am Ziel – öffne jetzt Dein Bibelleseplan! 🏁",
  "Guten Morgen! Zeit, in Dein Bibelleseplan weiterzulesen. 🌻",
];

/** Pick a random personalized message, falling back to a generic one if no name is stored. */
function pickMessage(userName: string | null): string {
  if (userName && userName.trim().length > 0) {
    const pool = MESSAGES_WITH_NAME;
    const template = pool[Math.floor(Math.random() * pool.length)];
    return template.replaceAll("{name}", userName.trim());
  }
  const pool = MESSAGES_GENERIC;
  return pool[Math.floor(Math.random() * pool.length)];
}

// ─── Helpers ────────────────────────────────────────────────────────────────

/** Returns the current local hour (0-23) in the given IANA timezone. */
function localHourInTimezone(date: Date, timezone: string): number {
  try {
    const formatter = new Intl.DateTimeFormat("en-US", {
      timeZone: timezone,
      hour: "numeric",
      hour12: false,
    });
    const str = formatter.format(date);
    const h = parseInt(str, 10);
    return isNaN(h) ? 0 : h % 24;
  } catch {
    return date.getUTCHours();
  }
}

// ─── JWT / OAuth helpers ────────────────────────────────────────────────────

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

  const pemContents = sa.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const binaryDer = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer.buffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(unsignedToken),
  );

  const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");

  return `${unsignedToken}.${signatureB64}`;
}

async function getAccessToken(sa: ServiceAccountKey): Promise<string> {
  const jwt = await createSignedJwt(sa);
  const res = await fetch(sa.token_uri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const data = await res.json();
  if (!data.access_token) {
    throw new Error(`Failed to get access token: ${JSON.stringify(data)}`);
  }
  return data.access_token as string;
}

// ─── Main ───────────────────────────────────────────────────────────────────

serve(async (_req) => {
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    const now = new Date();

    console.log(`[bible-plan] Running at UTC ${now.toISOString()}`);

    // ── 1. Fetch devices that started the plan and have a push token ────────
    const { data: devices, error: devicesError } = await supabase
      .from("device_tokens")
      .select("fcm_token, user_name, timezone")
      .eq("bible_plan_started", true)
      .not("fcm_token", "is", null);

    if (devicesError) {
      console.error("[bible-plan] Error fetching devices:", devicesError);
      return new Response(JSON.stringify({ error: "Failed to fetch devices" }), { status: 500 });
    }

    if (!devices || devices.length === 0) {
      console.log("[bible-plan] No devices to notify");
      return new Response(JSON.stringify({ message: "No devices to notify" }), { status: 200 });
    }

    // ── 2. Filter to devices whose local time is currently 06:xx ─────────────
    const devicesToNotify = devices.filter((d) => {
      const tz = d.timezone || "Europe/Berlin";
      return localHourInTimezone(now, tz) === 6;
    });

    if (devicesToNotify.length === 0) {
      console.log("[bible-plan] No devices at 06:xx local time right now");
      return new Response(JSON.stringify({ message: "No devices for this hour" }), { status: 200 });
    }

    console.log(`[bible-plan] Sending to ${devicesToNotify.length} devices`);

    // ── 3. Get FCM access token ──────────────────────────────────────────────
    const accessToken = await getAccessToken(FCM_SERVICE_ACCOUNT);
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`;

    // ── 4. Send a personalized push per device ───────────────────────────────
    let successCount = 0;
    let failureCount = 0;

    await Promise.allSettled(
      devicesToNotify.map(async (device) => {
        const body = pickMessage(device.user_name as string | null);

        const message = {
          message: {
            token: device.fcm_token,
            notification: {
              title: "Dein Bibelleseplan",
              body,
            },
            data: {
              contentType: "bible_plan",
            },
            apns: {
              payload: {
                aps: { sound: "default" },
              },
            },
            android: {
              notification: {
                sound: "default",
                channel_id: "push_notifications",
              },
            },
          },
        };

        try {
          const res = await fetch(fcmUrl, {
            method: "POST",
            headers: {
              Authorization: `Bearer ${accessToken}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify(message),
          });

          if (res.ok) {
            successCount++;
          } else {
            failureCount++;
            const errorText = await res.text();
            console.error(`[bible-plan] FCM send failed: ${errorText}`);
          }
        } catch (error) {
          failureCount++;
          console.error("[bible-plan] Error sending to token:", error);
        }
      }),
    );

    return new Response(
      JSON.stringify({
        message: "Bible plan notifications sent",
        devicesMatched: devicesToNotify.length,
        success: successCount,
        failure: failureCount,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (error) {
    console.error("[bible-plan] Function error:", error);
    return new Response(JSON.stringify({ error: String(error) }), { status: 500 });
  }
});
