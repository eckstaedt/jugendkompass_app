-- Counts (or with :apply = 'yes' rewrites) storage URL references in the CLOUD DB.
-- Only data columns in public, only the /storage/v1/ prefix. Functions are NOT touched.
SET session_replication_role = replica;
SELECT set_config('jk.old', :'old_prefix', false), set_config('jk.new', :'new_prefix', false), set_config('jk.apply', :'apply', false);
DO $$
DECLARE
  old_p text := current_setting('jk.old');
  new_p text := current_setting('jk.new');
  do_apply boolean := current_setting('jk.apply') = 'yes';
  r record; n bigint; total bigint := 0;
BEGIN
  FOR r IN
    SELECT c.table_name, c.column_name, c.data_type
    FROM information_schema.columns c
    JOIN information_schema.tables t ON t.table_schema = c.table_schema AND t.table_name = c.table_name
    WHERE c.table_schema = 'public' AND t.table_type = 'BASE TABLE'
      AND c.data_type IN ('text', 'character varying', 'json', 'jsonb', 'ARRAY')
      AND c.is_generated = 'NEVER' AND c.is_updatable = 'YES'
    ORDER BY 1, 2
  LOOP
    IF r.data_type = 'ARRAY' THEN
      EXECUTE format('SELECT count(*) FROM public.%I WHERE %I::text LIKE ''%%'' || $1 || ''%%''', r.table_name, r.column_name) INTO n USING old_p;
      IF n > 0 THEN RAISE NOTICE 'ARRAY column needs manual handling: %.% (% rows)', r.table_name, r.column_name, n; END IF;
      CONTINUE;
    END IF;
    IF do_apply THEN
      EXECUTE format('UPDATE public.%I SET %I = replace(%I::text, $1, $2)::%s WHERE %I::text LIKE ''%%'' || $1 || ''%%''',
        r.table_name, r.column_name, r.column_name,
        CASE r.data_type WHEN 'character varying' THEN 'varchar' ELSE r.data_type END, r.column_name)
      USING old_p, new_p;
      GET DIAGNOSTICS n = ROW_COUNT;
    ELSE
      EXECUTE format('SELECT count(*) FROM public.%I WHERE %I::text LIKE ''%%'' || $1 || ''%%''', r.table_name, r.column_name) INTO n USING old_p;
    END IF;
    IF n > 0 THEN RAISE NOTICE '%.%: % rows', r.table_name, r.column_name, n; total := total + n; END IF;
  END LOOP;
  RAISE NOTICE 'TOTAL %: % values', CASE WHEN do_apply THEN 'rewritten' ELSE 'to rewrite' END, total;
END $$;
SELECT 'replication_role now: ' || current_setting('session_replication_role');
RESET session_replication_role;
