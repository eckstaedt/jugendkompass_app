-- Läuft auf dem VPS nach dem Restore. Ersetzt die Cloud-URL durch die neue
-- API-URL in Daten (z.B. Storage-Links in posts, audios, videos, editions)
-- und in Datenbankfunktionen (net.http_post-Aufrufe der Trigger).
--
-- psql-Variablen: old_url (https://<ref>.supabase.co), new_url (https://api.…)

SET session_replication_role = replica;  -- keine Trigger (Übersetzung, Pushes) auslösen
SELECT set_config('jk.old_url', :'old_url', false), set_config('jk.new_url', :'new_url', false);

DO $$
DECLARE
  old_url text := current_setting('jk.old_url');
  new_url text := current_setting('jk.new_url');
  r record;
  n bigint;
  total bigint := 0;
BEGIN
  -- 1. Daten in public: alle Text- und JSON-Spalten
  FOR r IN
    SELECT c.table_schema, c.table_name, c.column_name, c.data_type
    FROM information_schema.columns c
    JOIN information_schema.tables t
      ON t.table_schema = c.table_schema AND t.table_name = c.table_name
    WHERE c.table_schema = 'public'
      AND t.table_type = 'BASE TABLE'
      AND c.data_type IN ('text', 'character varying', 'json', 'jsonb')
  LOOP
    EXECUTE format(
      'UPDATE %I.%I SET %I = replace(%I::text, $1, $2)::%s WHERE %I::text LIKE ''%%'' || $1 || ''%%''',
      r.table_schema, r.table_name, r.column_name, r.column_name,
      CASE r.data_type WHEN 'character varying' THEN 'varchar' ELSE r.data_type END,
      r.column_name)
    USING old_url, new_url;
    GET DIAGNOSTICS n = ROW_COUNT;
    IF n > 0 THEN
      RAISE NOTICE 'URL ersetzt: %.%.% (% Zeilen)', r.table_schema, r.table_name, r.column_name, n;
      total := total + n;
    END IF;
  END LOOP;
  RAISE NOTICE 'Daten: % Werte umgeschrieben', total;

  -- 2. Funktionen in public mit fest eingetragener URL
  FOR r IN
    SELECT p.oid, p.proname
    FROM pg_proc p
    WHERE p.pronamespace = 'public'::regnamespace
      AND p.prokind IN ('f', 'p')
      AND p.prosrc LIKE '%' || old_url || '%'
  LOOP
    EXECUTE replace(pg_get_functiondef(r.oid), old_url, new_url);
    RAISE NOTICE 'Funktion umgeschrieben: %', r.proname;
  END LOOP;
END $$;

RESET session_replication_role;

-- Kontrolle: es sollte nichts mehr auf die Cloud zeigen
SELECT 'Funktionen mit alter URL: ' || count(*)
FROM pg_proc WHERE pronamespace = 'public'::regnamespace AND prosrc LIKE '%' || :'old_url' || '%';
