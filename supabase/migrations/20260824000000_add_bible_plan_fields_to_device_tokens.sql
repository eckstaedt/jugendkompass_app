-- Migration: Add fields needed for the "Bibel in 365 Tagen" daily reminder push.
--
-- user_name           — the display name the user entered (onboarding / profile),
--                        synced from the app so we can personalize push notifications
--                        (e.g. "Lisa, dein Bibelleseplan wartet auf dich! 📖").
-- bible_plan_started  — true once the user tapped "Bibelleseplan starten" on the
--                        intro screen. Only devices with this flag set receive the
--                        daily 06:30 reminder push (send-bible-plan-notification).

ALTER TABLE device_tokens
  ADD COLUMN IF NOT EXISTS user_name text,
  ADD COLUMN IF NOT EXISTS bible_plan_started boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN device_tokens.user_name IS 'Display name entered by the user, used to personalize push notifications.';
COMMENT ON COLUMN device_tokens.bible_plan_started IS 'True once the user started the Bibel in 365 Tagen reading plan. Gates the daily 06:30 reminder push.';
