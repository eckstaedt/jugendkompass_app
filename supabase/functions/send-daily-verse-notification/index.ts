// Supabase Edge Function: Send Daily Verse Notifications
// Triggered by a cron job every hour.
// Filters devices whose notification_hour matches the current local hour
// in the device's stored timezone. Sends the localized verse via FCM.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// ─── Firebase Config (aus Secrets) ──────────────────────────────────────────

const FCM_PROJECT_ID = Deno.env.get("FCM_PROJECT_ID") ?? "jugendkompass-46aa7";

interface ServiceAccountKey {
  client_email: string;
  private_key: string;
  token_uri: string;
}

const FCM_SERVICE_ACCOUNT: ServiceAccountKey = loadServiceAccount();

/** Firebase-Dienstkonto aus dem Secret FCM_SERVICE_ACCOUNT_JSON (nie im Code ablegen!). */
function loadServiceAccount(): ServiceAccountKey {
  const raw = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON") ?? Deno.env.get("FCM_SERVICE_ACCOUNT_KEY") ?? "";
  if (!raw) throw new Error("Secret FCM_SERVICE_ACCOUNT_JSON fehlt");
  const sa = JSON.parse(raw);
  return {
    client_email: sa.client_email,
    private_key: sa.private_key,
    token_uri: sa.token_uri ?? "https://oauth2.googleapis.com/token",
  };
}

// ─── Helpers ────────────────────────────────────────────────────────────────

/** Returns the current local hour (0-23) in the given IANA timezone. */
function localHourInTimezone(date: Date, timezone: string): number {
  try {
    const formatter = new Intl.DateTimeFormat('en-US', {
      timeZone: timezone,
      hour: 'numeric',
      hour12: false,
    })
    const str = formatter.format(date)
    const h = parseInt(str, 10)
    return isNaN(h) ? 0 : h % 24
  } catch {
    return date.getUTCHours()
  }
}

function getLocalizedTitle(language: string): string {
  const titles: Record<string, string> = {
    de: 'Vers des Tages 📖',
    en: 'Verse of the Day 📖',
    ru: 'Стих Дня 📖',
    es: 'Versículo del Día 📖',
    pl: 'Werset Dnia 📖',
    tr: 'Günün Ayeti 📖',
    he: 'פסוק היום 📖',
  }
  return titles[language] || titles.de
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

serve(async (_req) => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)
    const now = new Date()

    console.log(`[verse] Running at UTC ${now.toISOString()}`)

    // ── 1. Fetch today's German base verse ──────────────────────────────────
    const today = now.toISOString().split('T')[0]
    const { data: verseData, error: verseError } = await supabase
      .from('verse_of_the_day')
      .select('*')
      .eq('date', today)
      .maybeSingle()

    if (verseError) {
      console.error('[verse] Error fetching verse:', verseError)
      return new Response(JSON.stringify({ error: 'Failed to fetch verse' }), { status: 500 })
    }

    if (!verseData) {
      console.log('[verse] No verse found for today')
      return new Response(JSON.stringify({ message: 'No verse for today' }), { status: 200 })
    }

    // ── 2. Fetch all devices with verse notifications enabled ───────────────
    const { data: devices, error: devicesError } = await supabase
      .from('device_tokens')
      .select('fcm_token, language, notification_hour, timezone')
      .eq('verse_notifications', true)
      .not('fcm_token', 'is', null)

    if (devicesError) {
      console.error('[verse] Error fetching devices:', devicesError)
      return new Response(JSON.stringify({ error: 'Failed to fetch devices' }), { status: 500 })
    }

    if (!devices || devices.length === 0) {
      console.log('[verse] No devices to notify')
      return new Response(JSON.stringify({ message: 'No devices to notify' }), { status: 200 })
    }

    // ── 3. Filter by timezone-aware local hour ──────────────────────────────
    const devicesToNotify = devices.filter(d => {
      const tz = d.timezone || 'Europe/Berlin'
      const localHour = localHourInTimezone(now, tz)
      return localHour === d.notification_hour
    })

    if (devicesToNotify.length === 0) {
      console.log('[verse] No devices scheduled for this hour')
      return new Response(JSON.stringify({ message: 'No devices for this hour' }), { status: 200 })
    }

    console.log(`[verse] Sending to ${devicesToNotify.length} devices`)

    // ── 4. Get FCM access token ─────────────────────────────────────────────
    const accessToken = await getAccessToken(FCM_SERVICE_ACCOUNT)
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`

    // ── 5. Group by language ────────────────────────────────────────────────
    const devicesByLanguage: Record<string, string[]> = {}
    for (const device of devicesToNotify) {
      const lang = device.language || 'de'
      if (!devicesByLanguage[lang]) devicesByLanguage[lang] = []
      devicesByLanguage[lang].push(device.fcm_token)
    }

    // ── 6. Send per language group with localized verse ─────────────────────
    let successCount = 0
    let failureCount = 0

    // Cache localized verses
    const verseCache: Record<string, { verse: string; reference: string }> = {
      de: { verse: verseData.verse, reference: verseData.reference },
    }

    for (const [language, tokens] of Object.entries(devicesByLanguage)) {
      const title = getLocalizedTitle(language)

      // Fetch localized verse if not German
      if (language !== 'de' && !verseCache[language]) {
        try {
          const { data: localized } = await supabase
            .rpc('get_verse_of_day_localized', { lang: language })
          if (localized && localized.verse) {
            verseCache[language] = { verse: localized.verse, reference: localized.reference }
          } else {
            verseCache[language] = verseCache['de']
          }
        } catch (e) {
          console.error(`[verse] Could not fetch localized verse for ${language}:`, e)
          verseCache[language] = verseCache['de']
        }
      }

      const { verse, reference } = verseCache[language] ?? verseCache['de']
      const body = `${verse} — ${reference}`

      console.log(`[verse] Sending ${language}: "${title}" to ${tokens.length} devices`)

      // Send to each token
      for (const token of tokens) {
        try {
          const message = {
            message: {
              token,
              notification: { title, body },
              // Data payload for deep linking
              data: {
                contentType: 'verse',
                contentId: verseData.id,
              },
              android: {
                notification: {
                  sound: "default",
                  channel_id: "verse_of_day",
                },
              },
              apns: {
                payload: {
                  aps: {
                    sound: "default",
                  },
                },
              },
            },
          }

          const res = await fetch(fcmUrl, {
            method: "POST",
            headers: {
              Authorization: `Bearer ${accessToken}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify(message),
          })

          if (res.ok) {
            successCount++
          } else {
            failureCount++
            const errorText = await res.text()
            console.error(`[verse] FCM send failed for token: ${errorText}`)
          }
        } catch (error) {
          failureCount++
          console.error(`[verse] Error sending to token:`, error)
        }
      }
    }

    return new Response(
      JSON.stringify({
        message: 'Verse notifications sent',
        verse: verseData.reference,
        devicesMatched: devicesToNotify.length,
        success: successCount,
        failure: failureCount,
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[verse] Function error:', error)
    return new Response(
      JSON.stringify({ error: String(error) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
