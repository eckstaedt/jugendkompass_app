// Supabase Edge Function: Send Daily Verse Notifications
// Triggered by a cron job every hour.
// Filters devices whose notification_hour matches the current local hour
// in the device's stored timezone. Sends the localized verse via FCM.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// ─── Firebase Config (hardcoded for private project) ────────────────────────

const FCM_PROJECT_ID = "jugendkompass-46aa7";

interface ServiceAccountKey {
  client_email: string;
  private_key: string;
  token_uri: string;
}

const FCM_SERVICE_ACCOUNT: ServiceAccountKey = {
  client_email: "firebase-adminsdk-lqlr9@jugendkompass-46aa7.iam.gserviceaccount.com",
  private_key: "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCYhKa4DFSp0dQY\nUUwjXqg+2PnZPMigupvuPDfFvLxrjAsYNvMX9KCtxPXt01rl+hiMdIQwdyb8LgI0\neXIHiqQTfR3KDqdwMLomhaLHmA34ck1aM2jyLv8Xizh+Th/7xeD+vWL9HnD+ZPB2\nnVuYtYZnOhR5IFExzKfQTAxUCE25b85lnALi2XRHqKkUfab6Byu3sg55ePPoR3/x\nvi/yAUhChO3fH0XnJPzj91RY+8IkH8xPYE1aLPE3xRki8q54SgHl3axs4XX75s7l\nlSSJRq8/iHkY9+gsoC9Wqos4bjk0DyEH3XEaeL/cjOfY2Dhab4l0WYQxTqR372RU\n9E0MBoVDAgMBAAECggEADrMmUHHbzRxMqWVYhcYvSBNojVAG9DrYIY+LPpMww9rV\nDOnq5yGsRONJYrkutyCyMgNe5D7vsnmKu90CqQhrRPeXoexkpfMEVgcmR793hT0b\nCHkRAdqWuoGwGbhU69LIGzVMr6G5+ULoTD5hYCgKwrM92ujK+pZDjFdwDr9YImmm\nrmxkWWOPNRYPifD6cOnOvbE/DyB0uk+0/yzBKAtEkSCiKhhI2FirjYCvON3+1zvn\nVUzMu2/zUFR1ZVhRvbR3IR4sjY07PPMWx2hHj+0S31v0OLlzd2tvOkKPNznXemBX\nEyIvq7N9ikzO4z6Jue5fpvRpT5p7/qm2QAaiss0qeQKBgQDIi3qv0HOiQvVGnpqC\nfWNm4sSXOth8g2f1hQsDIcqfx/hj4vourADMW/7QzBjXMAV9OZzXWL561zE6n/Hz\nstM81nabTB/ZCdr3lrxY3QtK0H9GSVRwZhQt1XAUvPhbTA2GoUhsmXVvx4LlNiZP\no/T3tb9IkW9L7kmTITmAZI0YOwKBgQDCsWAiD6pug6qgFZxIYSaw2d9kYjXhsK9W\n6tXlELfWzq24YZH5RmMyFaElHb9n+bny9HGH3oIwk0nQYAm+Zc7Dsvblh7VH0+Zc\n6UeFfSb+ht+2ySrOVHuQxCE24YzRb1GmQaZaAQQ8NhixwhuWyP8TI71Mv0+Q6ED3\nAXqILvJ+mQKBgHYk/Z0wD79q9Paqn1n6pqHJPInfaARKoecZfvhUYvuooiOuZzcx\nq7K5C7BUXNoA92rjkwumw2i4986SxcaM9jckHXG18hk53h74VXOAnZNwq1pr/uvM\np1ytHj+JaELY1isXPwSDj5TPk8SXFxDaBYodL1iAHXI9KmkcLLUAB8NbAoGAZMj5\noOhHK+qQ+0n0mytfohFHKWoFxo12VyI+E9RxtotLNrWboVUkqJq1zsb1fNezwOd1\nlgZDku3MOkhdAukk/f24/d0gpMw25kYEtj+xXfVn/fFpbWIijTBamVRtV0WvGMfH\nW7RHAvxmEC8RpR7rnHbV2dL3V2ZDqxpi2fijo5ECgYEAr2oCcfSvSOgJoryWZhMI\n4Bf2J4qNfmnsErjZi7ITlQ/T8suf/Tuon5iHc8/C2spx7KztJ/mplgOINA911CCi\nzeJdX4Q63rBgz48wTo5k0LLazUiDLAGemKxUNBwMRhuwBk/IGBP0sdkOWvgULF1P\n1UiCGQeMIZe0z4fbnbjLfbY=\n-----END PRIVATE KEY-----\n",
  token_uri: "https://oauth2.googleapis.com/token",
};

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
              data: { type: 'verse' },
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
