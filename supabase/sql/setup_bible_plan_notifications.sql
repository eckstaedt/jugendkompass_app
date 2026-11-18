-- ============================================================================
-- Setup: "Bibel in 365 Tagen" Daily Push Notification (Bibelleseplan)
-- ============================================================================
-- Führe dieses komplette Skript im Supabase SQL Editor aus. Es erledigt
-- alles Server-seitige, was für die tägliche 06:30 Uhr Push-Erinnerung noch
-- fehlt:
--
--   1. Fügt `user_name` und `bible_plan_started` zu `device_tokens` hinzu
--      (falls die Migration noch nicht angewendet wurde).
--   2. Aktiviert die `pg_cron` und `pg_net` Extensions.
--   3. Richtet einen Cron-Job ein, der stündlich zur Minute :30 die Edge
--      Function `send-bible-plan-notification` aufruft.
--
-- WICHTIG: Bevor du dieses Skript ausführst:
--   a) Ersetze <DEIN_SERVICE_ROLE_KEY> unten durch deinen echten Supabase
--      Service Role Key (Project Settings → API → service_role secret).
--   b) Stelle sicher, dass die Edge Function bereits deployed ist:
--        supabase functions deploy send-bible-plan-notification
--   c) Setze das Secret FCM_PRIVATE_KEY für die Function im Dashboard
--      (Edge Functions → send-bible-plan-notification → Secrets).
-- ============================================================================

-- ── 1. Spalten an device_tokens hinzufügen (idempotent) ─────────────────────

ALTER TABLE device_tokens
  ADD COLUMN IF NOT EXISTS user_name text,
  ADD COLUMN IF NOT EXISTS bible_plan_started boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN device_tokens.user_name IS 'Display name entered by the user, used to personalize push notifications.';
COMMENT ON COLUMN device_tokens.bible_plan_started IS 'True once the user started the Bibel in 365 Tagen reading plan. Gates the daily 06:30 reminder push.';

-- ── 2. Benötigte Extensions aktivieren ───────────────────────────────────────

CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- ── 3. Alten Cron-Job entfernen, falls er schon existiert (idempotent) ──────

SELECT cron.unschedule('send-bible-plan-notifications')
WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'send-bible-plan-notifications'
);

-- ── 4. Neuen Cron-Job einrichten: stündlich zur Minute :30 ──────────────────

SELECT cron.schedule(
  'send-bible-plan-notifications',
  '30 * * * *', -- jede Stunde zur Minute 30
  $$
  SELECT net.http_post(
    url := 'https://vdcdibvclaulqxfjyzpq.supabase.co/functions/v1/send-bible-plan-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer <DEIN_SERVICE_ROLE_KEY>'
    ),
    body := '{}'::jsonb
  );
  $$
);

-- ── 5. Kontrolle: Cron-Job wurde angelegt ───────────────────────────────────

SELECT jobid, jobname, schedule, active
FROM cron.job
WHERE jobname = 'send-bible-plan-notifications';
