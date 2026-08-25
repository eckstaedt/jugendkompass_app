-- Migration: Add per-device toggle + preferred hour for the "Bibelleseplan"
-- daily reminder push notification, mirroring the existing Vers des Tages
-- notification settings pattern.

ALTER TABLE device_tokens
  ADD COLUMN IF NOT EXISTS bible_plan_notifications_enabled boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS bible_plan_notification_hour integer NOT NULL DEFAULT 6;

COMMENT ON COLUMN device_tokens.bible_plan_notifications_enabled IS 'Opt-in/out for the daily Bibelleseplan reminder push.';
COMMENT ON COLUMN device_tokens.bible_plan_notification_hour IS 'Preferred local hour (0-23) for the daily Bibelleseplan reminder push. Default 6.';
