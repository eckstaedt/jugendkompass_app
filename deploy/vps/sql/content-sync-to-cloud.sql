-- VPS -> old Supabase cloud: content sync so old app versions keep seeing new content.
-- Runs inside the VPS database (pg_cron + dblink). Rows are compared by a hash per
-- primary key; only changed / new / deleted rows are sent. In the cloud the writes run
-- with session_replication_role = replica: no triggers (no pushes, no translation jobs).
create extension if not exists dblink with schema extensions;
create schema if not exists jk_sync;
revoke all on schema jk_sync from public, anon, authenticated;

create table if not exists jk_sync.content_tables (tbl text primary key, ord int not null);
insert into jk_sync.content_tables (tbl, ord) values
  ('categories', 1), ('content', 2), ('posts', 3), ('impulses', 4), ('messages', 5), ('videos', 6),
  ('audios', 7), ('polls', 8), ('poll_options', 9), ('verse_of_the_day', 10), ('editions', 11),
  ('app_announcements', 12), ('content_translations', 13), ('entity_translations', 14),
  ('audio_translations', 15), ('image_translations', 16), ('video_subtitles', 17)
on conflict (tbl) do update set ord = excluded.ord;

create table if not exists jk_sync.content_seen (tbl text not null, pk text not null, h text not null, primary key (tbl, pk));

-- primary key columns of a table, in index order
create or replace function jk_sync.pk_cols(t text) returns text[] language sql stable as $f$
  select array_agg(a.attname::text order by k.ord)
  from pg_index i
  cross join lateral unnest(i.indkey) with ordinality as k(attnum, ord)
  join pg_attribute a on a.attrelid = i.indrelid and a.attnum = k.attnum
  where i.indrelid = ('public.' || quote_ident(t))::regclass and i.indisprimary
$f$;

-- writable (non-generated) columns
create or replace function jk_sync.data_cols(t text) returns text[] language sql stable as $f$
  select array_agg(column_name::text order by ordinal_position) from information_schema.columns
  where table_schema = 'public' and table_name = t and is_generated = 'NEVER'
$f$;

-- SQL text that yields (pk, hash) for every row of table t (same on both sides)
create or replace function jk_sync.hash_query(t text) returns text language sql stable as $f$
  select format('select json_build_array(%s)::text as pk, md5(row_to_json(x)::text) as h from public.%I x',
                (select string_agg(format('x.%I', c), ', ') from unnest(jk_sync.pk_cols(t)) c), t)
$f$;

create or replace function jk_sync.cloud_connect() returns void language plpgsql security definer set search_path = public, extensions as $f$
begin
  if 'jkcloud' = any(coalesce(dblink_get_connections(), '{}')) then return; end if;
  perform dblink_connect('jkcloud', (select decrypted_secret from vault.decrypted_secrets where name = 'jk_cloud_db_url'));
  perform dblink_exec('jkcloud', 'set timezone = ''UTC''');
end $f$;

-- Seed "seen" with the CLOUD's current hashes, so the first real run sends exactly the differences.
create or replace function jk_sync.seed_from_cloud() returns text language plpgsql security definer set search_path = public, extensions as $f$
declare r record; n bigint; total bigint := 0;
begin
  perform set_config('timezone', 'UTC', true);
  perform jk_sync.cloud_connect();
  delete from jk_sync.content_seen;
  for r in select tbl from jk_sync.content_tables order by ord loop
    insert into jk_sync.content_seen (tbl, pk, h)
      select r.tbl, c.pk, c.h from dblink('jkcloud', jk_sync.hash_query(r.tbl)) as c(pk text, h text);
    get diagnostics n = row_count; total := total + n;
  end loop;
  perform dblink_disconnect('jkcloud');
  return format('seeded %s cloud rows', total);
end $f$;

-- Main sync. dry_run = true only reports.
create or replace function jk_sync.push_content(dry_run boolean default false) returns text
language plpgsql security definer set search_path = public, extensions as $f$
declare
  r record; pkc text[]; cols text[]; collist text; setlist text; pkjoin text; pkset text;
  n_up int; n_del int; report text := ''; batch json; stmt text; tot_up int := 0; tot_del int := 0;
begin
  perform set_config('timezone', 'UTC', true);
  if not dry_run then perform jk_sync.cloud_connect(); end if;
  for r in select tbl from jk_sync.content_tables order by ord loop
    pkc := jk_sync.pk_cols(r.tbl); cols := jk_sync.data_cols(r.tbl);
    collist := (select string_agg(format('%I', c), ', ') from unnest(cols) c);
    setlist := coalesce((select string_agg(format('%I = excluded.%I', c, c), ', ') from unnest(cols) c where c <> all(pkc)), '');
    pkjoin := (select string_agg(format('t.%I is not distinct from d.%I', c, c), ' and ') from unnest(pkc) c);
    pkset := (select string_agg(format('%I', c), ', ') from unnest(pkc) c);

    execute format('create temp table _cur on commit drop as %s', jk_sync.hash_query(r.tbl));
    create temp table _chg on commit drop as
      select c.pk, c.h from _cur c left join jk_sync.content_seen s on s.tbl = r.tbl and s.pk = c.pk
      where s.h is distinct from c.h;
    create temp table _del on commit drop as
      select s.pk from jk_sync.content_seen s where s.tbl = r.tbl and not exists (select 1 from _cur c where c.pk = s.pk);
    select count(*) into n_up from _chg; select count(*) into n_del from _del;

    if not dry_run and n_up > 0 then
      -- send changed rows in batches of 200
      for batch in
        execute format('select json_agg(row_to_json(x)) from (select x.*, ntile(greatest(1, ceil(%s / 200.0)::int)) over () as _b
                         from public.%I x join _chg c on c.pk = json_build_array(%s)::text) x group by _b',
                       n_up, r.tbl, (select string_agg(format('x.%I', c), ', ') from unnest(pkc) c))
      loop
        stmt := format('set session_replication_role = replica; insert into public.%I (%s) select %s from json_populate_recordset(null::public.%I, %L::json) on conflict (%s) do %s; reset session_replication_role;',
                       r.tbl, collist, collist, r.tbl, batch::text, pkset,
                       case when setlist = '' then 'nothing' else 'update set ' || setlist end);
        perform dblink_exec('jkcloud', stmt);
      end loop;
    end if;

    if not dry_run and n_del > 0 then
      stmt := format('set session_replication_role = replica; delete from public.%I t using json_populate_recordset(null::public.%I, %L::json) d where %s; reset session_replication_role;',
                     r.tbl, r.tbl,
                     (select json_agg((select json_object_agg(pkc[i], (d.pk::json)->>(i - 1)) from generate_subscripts(pkc, 1) i)) from _del d)::text,
                     pkjoin);
      perform dblink_exec('jkcloud', stmt);
    end if;

    if not dry_run then
      delete from jk_sync.content_seen s using _del d where s.tbl = r.tbl and s.pk = d.pk;
      insert into jk_sync.content_seen (tbl, pk, h) select r.tbl, pk, h from _chg
        on conflict (tbl, pk) do update set h = excluded.h;
    end if;

    if n_up > 0 or n_del > 0 then report := report || format('%s: +/~%s -%s; ', r.tbl, n_up, n_del); end if;
    tot_up := tot_up + n_up; tot_del := tot_del + n_del;
    drop table _cur; drop table _chg; drop table _del;
  end loop;
  if not dry_run then
    perform dblink_disconnect('jkcloud');
    insert into jk_sync.log (result) values ('content push: ' || coalesce(nullif(report, ''), 'no changes'));
  end if;
  return case when dry_run then 'DRY RUN ' else '' end || format('upserts=%s deletes=%s | %s', tot_up, tot_del, coalesce(nullif(report, ''), 'no changes'));
end $f$;
revoke all on all functions in schema jk_sync from public, anon, authenticated;
