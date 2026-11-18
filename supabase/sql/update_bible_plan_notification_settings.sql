-- ============================================================================
-- Update: "Bibelleseplan" Push Notification Settings (Toggle + Uhrzeit)
-- ============================================================================
-- Führe dieses Skript im Supabase SQL Editor aus. Es ergänzt die im ersten
-- Setup-Skript (setup_bible_plan_notifications.sql) angelegte Struktur um
-- zwei weitere Spalten, damit Nutzer den Bibelleseplan-Push in den
-- Einstellungen (wie "Vers des Tages") ein-/ausschalten und die Uhrzeit
-- frei wählen können:
--
--   bible_plan_notifications_enabled — Opt-in/Opt-out Schalter (Default true)
--   bible_plan_notification_hour     — Bevorzugte Erinnerungsstunde, 0-23
--                                       (Default 6, also 06:xx Uhr)
--
-- Die Edge Function `send-bible-plan-notification` wurde bereits angepasst,
-- sodass sie ab jetzt pro Gerät bible_plan_notifications_enabled prüft und
-- die individuelle bible_plan_notification_hour statt eines fest verdrahteten
-- 06:00 verwendet. Nach diesem SQL musst du die Function daher neu deployen:
--
--   supabase functions deploy send-bible-plan-notification
-- ============================================================================

ALTER TABLE device_tokens
  ADD COLUMN IF NOT EXISTS bible_plan_notifications_enabled boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS bible_plan_notification_hour integer NOT NULL DEFAULT 6;

COMMENT ON COLUMN device_tokens.bible_plan_notifications_enabled IS 'Opt-in/out for the daily Bibelleseplan reminder push (Einstellungen → Push-Benachrichtigungen → Bibelleseplan).';
COMMENT ON COLUMN device_tokens.bible_plan_notification_hour IS 'Preferred local hour (0-23) for the daily Bibelleseplan reminder push. Default 6 (06:xx Uhr).';

-- ── Kontrolle ────────────────────────────────────────────────────────────────

SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'device_tokens'
  AND column_name IN (
    'bible_plan_started',
    'bible_plan_notifications_enabled',
    'bible_plan_notification_hour',
    'user_name'
  );
