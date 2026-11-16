-- Läuft gegen die CLOUD-Datenbank und gibt SQL aus, das auf dem VPS nach dem
-- Schema-Restore ausgeführt wird. Erfasst, was ein reiner public-Dump nicht
-- mitnimmt: Storage-Policies, Trigger auf auth.users, Realtime-Publication.
\pset format unaligned
\pset tuples_only on

-- Storage-Policies (storage.objects / storage.buckets)
select format(
  'DROP POLICY IF EXISTS %I ON %I.%I; CREATE POLICY %I ON %I.%I AS %s FOR %s TO %s%s%s;',
  policyname, schemaname, tablename,
  policyname, schemaname, tablename,
  permissive, cmd,
  (select string_agg(case when r = 'public' then 'public' else quote_ident(r) end, ', ') from unnest(roles) r),
  coalesce(' USING (' || qual || ')', ''),
  coalesce(' WITH CHECK (' || with_check || ')', ''))
from pg_policies
where schemaname = 'storage'
order by tablename, policyname;

-- Eigene Trigger auf auth.users (z.B. on_auth_user_created)
select format('DROP TRIGGER IF EXISTS %I ON auth.users; ', t.tgname) || pg_get_triggerdef(t.oid) || ';'
from pg_trigger t
where t.tgrelid = 'auth.users'::regclass and not t.tgisinternal;

-- Realtime-Publication
select 'DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = ''supabase_realtime'') THEN CREATE PUBLICATION supabase_realtime; END IF; END $$;';
select format(
  'DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = ''supabase_realtime'' AND schemaname = %L AND tablename = %L) THEN ALTER PUBLICATION supabase_realtime ADD TABLE %I.%I; END IF; END $$;',
  schemaname, tablename, schemaname, tablename)
from pg_publication_tables
where pubname = 'supabase_realtime';
