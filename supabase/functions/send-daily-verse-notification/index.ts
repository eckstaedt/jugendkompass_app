// Supabase Edge Function: Send Daily Verse Notifications
// This function should be triggered by a cron job that runs every hour
// and sends verse notifications to devices based on their notification_hour setting

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const FCM_PROJECT_ID = Deno.env.get('FCM_PROJECT_ID')!
const FCM_SERVICE_ACCOUNT_KEY = Deno.env.get('FCM_SERVICE_ACCOUNT_KEY')!

serve(async (req) => {
  try {
    // Initialize Supabase client
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // Get current hour in UTC (Supabase stores times in UTC)
    // Note: Device notification times are stored in local time, so we need to handle timezone conversion
    const now = new Date()
    const currentHour = now.getUTCHours()

    console.log(`Running verse notification check for hour: ${currentHour}`)

    // Get today's verse
    const today = now.toISOString().split('T')[0] // YYYY-MM-DD
    const { data: verseData, error: verseError } = await supabase
      .from('verse_of_the_day')
      .select('*')
      .eq('date', today)
      .maybeSingle()

    if (verseError) {
      console.error('Error fetching verse:', verseError)
      return new Response(JSON.stringify({ error: 'Failed to fetch verse' }), { status: 500 })
    }

    if (!verseData) {
      console.log('No verse found for today')
      return new Response(JSON.stringify({ message: 'No verse for today' }), { status: 200 })
    }

    // Get all devices that:
    // 1. Have verse_notifications enabled
    // 2. Have fcm_token (registered for push)
    // 3. Have notification_hour matching current hour (accounting for timezone)
    // Note: This is simplified - in production you'd want to handle timezones properly
    const { data: devices, error: devicesError } = await supabase
      .from('device_tokens')
      .select('fcm_token, language, notification_hour, notification_minute')
      .eq('verse_notifications', true)
      .not('fcm_token', 'is', null)

    if (devicesError) {
      console.error('Error fetching devices:', devicesError)
      return new Response(JSON.stringify({ error: 'Failed to fetch devices' }), { status: 500 })
    }

    if (!devices || devices.length === 0) {
      console.log('No devices to notify')
      return new Response(JSON.stringify({ message: 'No devices to notify' }), { status: 200 })
    }

    // Filter devices by current hour (simplified - assumes all devices in same timezone)
    const devicesToNotify = devices.filter(d => d.notification_hour === currentHour)

    if (devicesToNotify.length === 0) {
      console.log(`No devices scheduled for hour ${currentHour}`)
      return new Response(JSON.stringify({ message: `No devices for hour ${currentHour}` }), { status: 200 })
    }

    console.log(`Sending verse notification to ${devicesToNotify.length} devices`)

    // Get FCM access token
    const accessToken = await getAccessToken()

    // Group devices by language
    const devicesByLanguage: Record<string, string[]> = {}
    for (const device of devicesToNotify) {
      const lang = device.language || 'de'
      if (!devicesByLanguage[lang]) {
        devicesByLanguage[lang] = []
      }
      devicesByLanguage[lang].push(device.fcm_token)
    }

    // Send notifications per language group
    let successCount = 0
    let failureCount = 0

    for (const [language, tokens] of Object.entries(devicesByLanguage)) {
      const title = getLocalizedTitle(language)
      const body = `${verseData.verse} - ${verseData.reference}`

      try {
        const result = await sendFCMMessages(tokens, title, body, null, accessToken)
        successCount += result.successCount
        failureCount += result.failureCount
      } catch (error) {
        console.error(`Error sending to ${language} devices:`, error)
        failureCount += tokens.length
      }
    }

    return new Response(
      JSON.stringify({
        message: 'Verse notifications sent',
        verse: verseData.reference,
        success: successCount,
        failure: failureCount,
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Function error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

function getLocalizedTitle(language: string): string {
  const titles: Record<string, string> = {
    de: 'Vers des Tages',
    en: 'Verse of the Day',
    ru: 'Стих Дня',
    es: 'Versículo del Día',
    pl: 'Werset Dnia',
  }
  return titles[language] || titles.de
}

async function getAccessToken(): Promise<string> {
  const serviceAccount = JSON.parse(FCM_SERVICE_ACCOUNT_KEY)

  const jwtHeader = btoa(JSON.stringify({ alg: "RS256", typ: "JWT" }))
  const now = Math.floor(Date.now() / 1000)
  const jwtClaimSet = btoa(JSON.stringify({
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  }))

  const unsignedToken = `${jwtHeader}.${jwtClaimSet}`

  // Import private key
  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(serviceAccount.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  )

  // Sign the token
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    privateKey,
    new TextEncoder().encode(unsignedToken)
  )

  const signedToken = `${unsignedToken}.${btoa(String.fromCharCode(...new Uint8Array(signature)))}`

  // Exchange JWT for access token
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${signedToken}`,
  })

  const data = await response.json()
  return data.access_token
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const pemContents = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "")
  const binary = atob(pemContents)
  const bytes = new Uint8Array(binary.length)
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i)
  }
  return bytes.buffer
}

async function sendFCMMessages(
  tokens: string[],
  title: string,
  body: string,
  imageUrl: string | null,
  accessToken: string
): Promise<{ successCount: number; failureCount: number }> {
  let successCount = 0
  let failureCount = 0

  // Send in batches of 500 (FCM limit)
  const batchSize = 500
  for (let i = 0; i < tokens.length; i += batchSize) {
    const batch = tokens.slice(i, i + batchSize)

    for (const token of batch) {
      try {
        const message: any = {
          message: {
            token,
            notification: { title, body },
            data: { type: 'verse' },
          },
        }

        if (imageUrl) {
          message.message.notification.image = imageUrl
        }

        const response = await fetch(
          `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer ${accessToken}`,
            },
            body: JSON.stringify(message),
          }
        )

        if (response.ok) {
          successCount++
        } else {
          failureCount++
          console.error(`FCM send failed for token:`, await response.text())
        }
      } catch (error) {
        failureCount++
        console.error(`Error sending to token:`, error)
      }
    }
  }

  return { successCount, failureCount }
}
