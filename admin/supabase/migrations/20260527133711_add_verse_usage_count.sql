-- Fügt usage_count zur verse_of_the_day Tabelle hinzu
ALTER TABLE public.verse_of_the_day ADD COLUMN IF NOT EXISTS usage_count INTEGER NOT NULL DEFAULT 0;
