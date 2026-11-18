-- =============================================================================
-- PUSH NOTIFICATIONS SETUP für Jugendkompass
-- =============================================================================
-- Push-Benachrichtigungen werden NICHT mehr automatisch bei neuen Inhalten
-- gesendet. Stattdessen muss die Edge Function manuell aufgerufen werden.
--
-- Aufruf der Edge Function:
--   POST /functions/v1/send-push-notification
--   Body: { "content_type": "post", "content_id": "uuid-here" }
--   oder: { "table": "posts", "record": { ... } }
--
-- =============================================================================

-- 1. Stelle sicher, dass fcm_token Spalte existiert
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'device_tokens' AND column_name = 'fcm_token'
  ) THEN
    ALTER TABLE device_tokens ADD COLUMN fcm_token text;
  END IF;
END $$;

-- 2. pg_net Extension für HTTP-Aufrufe (falls später benötigt)
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- 3. ENTFERNE alte automatische Trigger (falls vorhanden)
DROP TRIGGER IF EXISTS on_new_post_send_push ON posts;
DROP TRIGGER IF EXISTS on_new_video_send_push ON videos;
DROP TRIGGER IF EXISTS on_new_message_send_push ON messages;
DROP TRIGGER IF EXISTS on_new_edition_send_push ON editions;
DROP TRIGGER IF EXISTS on_new_impulse_send_push ON impulses;

-- 4. Entferne alte Trigger-Funktion (optional, kann behalten werden)
-- DROP FUNCTION IF EXISTS notify_new_content();

-- =============================================================================
-- FERTIG!
-- =============================================================================
--
-- Push-Benachrichtigungen werden jetzt nur noch gesendet, wenn die Edge
-- Function manuell aufgerufen wird (z.B. über einen Button im Admin-Panel).
--
-- Beispiel-Aufruf mit curl:
--   curl -X POST \
--     'https://vdcdibvclaulqxfjyzpq.supabase.co/functions/v1/send-push-notification' \
--     -H 'Authorization: Bearer YOUR_SERVICE_ROLE_KEY' \
--     -H 'Content-Type: application/json' \
--     -d '{"content_type": "post", "content_id": "uuid-of-the-post"}'
--
-- =============================================================================
