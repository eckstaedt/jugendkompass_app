-- =============================================================================
-- PUSH NOTIFICATIONS SETUP für Jugendkompass
-- =============================================================================
-- Sendet Push-Benachrichtigungen bei neuen Inhalten:
--   posts (mit audio_id)  → "Neuer Podcast"
--   posts (ohne audio_id) → "Neuer Artikel"
--   videos                → "Neues Video"
--   messages              → "Neue Kurznachricht"
--   editions              → "Neue Ausgabe"
--   impulses              → "Neuer Impuls"
--
-- Führe dieses SQL im Supabase SQL Editor aus.
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

-- 2. pg_net Extension für HTTP-Aufrufe
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- 3. Generische Trigger-Funktion für alle Content-Typen
-- ─── WICHTIG: Ersetze die Platzhalter unten! ───
CREATE OR REPLACE FUNCTION notify_new_content()
RETURNS trigger AS $$
DECLARE
  edge_function_url text;
  payload jsonb;
  supabase_url text;
  service_key text;
BEGIN
  -- ╔══════════════════════════════════════════════════════════════╗
  -- ║  HIER DEINE WERTE EINFÜGEN:                                ║
  -- ╚══════════════════════════════════════════════════════════════╝
  supabase_url := 'https://vdcdibvclaulqxfjyzpq.supabase.co';
  service_key  := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZkY2RpYnZjbGF1bHF4Zmp5enBxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NTQ1OTE4OSwiZXhwIjoyMDgxMDM1MTg5fQ.I29tT_hib4cHHfwY-Iep_lA9iSBjP0UL7xKNUb1TDyQ';

  edge_function_url := supabase_url || '/functions/v1/send-push-notification';

  -- Baue das Payload mit dem Tabellennamen und den neuen Daten
  payload := jsonb_build_object(
    'type', 'INSERT',
    'table', TG_TABLE_NAME,
    'schema', TG_TABLE_SCHEMA,
    'record', to_jsonb(NEW),
    'old_record', null
  );

  -- Sende HTTP-Anfrage an die Edge Function
  PERFORM net.http_post(
    url     := edge_function_url,
    body    := payload,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || service_key
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Trigger für alle Content-Tabellen erstellen

-- Posts (Artikel & Podcasts)
DROP TRIGGER IF EXISTS on_new_post_send_push ON posts;
CREATE TRIGGER on_new_post_send_push
  AFTER INSERT ON posts
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_content();

-- Videos
DROP TRIGGER IF EXISTS on_new_video_send_push ON videos;
CREATE TRIGGER on_new_video_send_push
  AFTER INSERT ON videos
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_content();

-- Kurznachrichten
DROP TRIGGER IF EXISTS on_new_message_send_push ON messages;
CREATE TRIGGER on_new_message_send_push
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_content();

-- Ausgaben
DROP TRIGGER IF EXISTS on_new_edition_send_push ON editions;
CREATE TRIGGER on_new_edition_send_push
  AFTER INSERT ON editions
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_content();

-- Impulse
DROP TRIGGER IF EXISTS on_new_impulse_send_push ON impulses;
CREATE TRIGGER on_new_impulse_send_push
  AFTER INSERT ON impulses
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_content();

-- =============================================================================
-- FERTIG!
-- =============================================================================
--
-- NÄCHSTE SCHRITTE:
--
-- 1. Ersetze 'DEINE_SUPABASE_URL' oben mit deiner echten Supabase URL
--    (z.B. https://vdcdibvclaulqxfjyzpq.supabase.co)
--
-- 2. Ersetze 'DEIN_SERVICE_ROLE_KEY' mit deinem Service Role Key
--    (Supabase Dashboard → Settings → API → service_role key)
--
-- 3. Deploye die Edge Function:
--    supabase functions deploy send-push-notification
--
-- 4. Setze die Secrets für die Edge Function:
--    Supabase Dashboard → Edge Functions → send-push-notification → Secrets:
--    - FCM_PROJECT_ID          = "jugendkompass-46aa7"
--    - FCM_SERVICE_ACCOUNT_KEY = <ganzer JSON-Inhalt des Firebase Service Account Keys>
--      (Firebase Console → Projekteinstellungen → Dienstkonten →
--       "Neuen privaten Schlüssel generieren")
--
-- =============================================================================
