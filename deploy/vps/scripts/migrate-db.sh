#!/usr/bin/env bash
# Kopiert die Datenbank aus der Supabase Cloud auf den VPS.
#
#   bash scripts/migrate-db.sh --test            Probelauf (Pushes/Cron bleiben aus)
#   bash scripts/migrate-db.sh --test --reset    Probelauf wiederholen (VPS-DB wird neu aufgesetzt)
#   bash scripts/migrate-db.sh --final --reset   Umstellung: Cron auf dem VPS an, echte Push-Tokens
#
# Die Cloud wird nur gelesen. Auf dem VPS ersetzt --reset die komplette Datenbank;
# bereits kopierte Dateien (Storage) bleiben erhalten.
set -euo pipefail
. "$(dirname "$0")/lib.sh"

MODE=""
RESET=0
YES=0
for a in "$@"; do
  case "$a" in
    --test) MODE=test ;;
    --final) MODE=final ;;
    --reset) RESET=1 ;;
    --yes) YES=1 ;;
    *) die "Unbekannte Option: $a" ;;
  esac
done
[ -n "$MODE" ] || die "Bitte --test oder --final angeben."

load_config
require CLOUD_DB_URL CLOUD_PROJECT_REF API_DOMAIN
OLD_URL="https://${CLOUD_PROJECT_REF}.supabase.co"
NEW_URL="https://${API_DOMAIN}"
SQL_DIR="$JK_ROOT/sql"
RUN="$WORK_DIR/db-$(date +%Y%m%d-%H%M%S)-$MODE"
mkdir -p "$RUN"
chmod 700 "$WORK_DIR" "$RUN"

docker ps --format '{{.Names}}' | grep -qx "$DB_CONTAINER" || die "Container $DB_CONTAINER läuft nicht. Erst den Supabase-Stack starten."

log "Teste Verbindung zur Cloud"
psql_cloud -c "select 1" >/dev/null || die "Keine Verbindung zu CLOUD_DB_URL (Session-Pooler-URL und Passwort prüfen)."

if [ "$MODE" = final ]; then
  on=$(psql_cloud -At -c "select count(*) from cron.job where active")
  [ "$on" = "0" ] || die "In der Cloud sind noch $on Cron-Jobs aktiv (doppelte Pushes!). Erst: bash scripts/cron.sh cloud off"
fi

existing=$(psql_vps -At -c "select count(*) from pg_tables where schemaname='public'")
if [ "$existing" != "0" ]; then
  [ "$RESET" = 1 ] || die "Die VPS-Datenbank enthält schon $existing Tabellen. Zum Wiederholen --reset angeben."
  if [ "$YES" != 1 ]; then
    read -r -p "VPS-Datenbank wird komplett ersetzt. Zum Fortfahren RESET eingeben: " answer
    [ "$answer" = "RESET" ] || die "Abgebrochen."
  fi
  log "Sichere Storage-Einträge des VPS (damit Dateien nicht neu kopiert werden müssen)"
  docker exec "$DB_CONTAINER" pg_dump -U supabase_admin -d postgres --data-only \
    --table=storage.objects >"$RUN/vps-storage-objects.sql"
  log "Setze VPS-Datenbank neu auf"
  stack down
  rm -rf "$SUPABASE_DIR/volumes/db/data"
  stack up -d --wait
fi

# --- 1. Export aus der Cloud ----------------------------------------------------
log "Exportiere Schema (public)"
pg_dump_cloud --schema-only --schema=public --quote-all-identifiers --no-publications --no-subscriptions \
  | sed -E 's/^CREATE SCHEMA "/CREATE SCHEMA IF NOT EXISTS "/' >"$RUN/schema.sql"

log "Exportiere Storage-Policies, Auth-Trigger, Realtime-Publication"
psql_cloud <"$SQL_DIR/export-extras.sql" >"$RUN/extras.sql"

log "Exportiere Daten (public, auth, storage.buckets)"
pg_dump_cloud --data-only --quote-all-identifiers \
  --schema=public --schema=auth \
  --exclude-table-data='auth.schema_migrations' >"$RUN/data.sql"
pg_dump_cloud --data-only --quote-all-identifiers --table=storage.buckets >"$RUN/buckets.sql"

log "Exportiere Vault-Secrets und Cron-Jobs"
psql_cloud -At -F $'\t' -c "select name, translate(encode(convert_to(decrypted_secret,'UTF8'),'base64'), E'\n', ''), coalesce(description,'') from vault.decrypted_secrets order by name" >"$RUN/vault.tsv"
psql_cloud -At -F $'\t' -c "select jobname, schedule, translate(encode(convert_to(command,'UTF8'),'base64'), E'\n', '') from cron.job order by jobid" >"$RUN/cron.tsv"
chmod 600 "$RUN"/*

ls -lh "$RUN"

# --- 2. Import auf dem VPS ------------------------------------------------------
log "Lege Extensions an"
psql_vps <<'SQL'
create extension if not exists "uuid-ossp" with schema extensions;
create extension if not exists pgcrypto with schema extensions;
create extension if not exists pgjwt with schema extensions;
create extension if not exists pg_net with schema extensions;
create extension if not exists pg_cron;
create extension if not exists supabase_vault with schema vault;
SQL

log "Importiere Schema"
psql_vps <"$RUN/schema.sql" >"$RUN/restore-schema.log" 2>&1 || { tail -20 "$RUN/restore-schema.log"; die "Schema-Import fehlgeschlagen (Log: $RUN/restore-schema.log)"; }

log "Importiere Policies/Trigger/Publication"
psql_vps <"$RUN/extras.sql" >"$RUN/restore-extras.log" 2>&1 || { tail -20 "$RUN/restore-extras.log"; die "Import der Extras fehlgeschlagen"; }

log "Importiere Daten"
{ echo "SET session_replication_role = replica;"; cat "$RUN/data.sql" "$RUN/buckets.sql"; } \
  | psql_vps --single-transaction >"$RUN/restore-data.log" 2>&1 \
  || { tail -20 "$RUN/restore-data.log"; die "Daten-Import fehlgeschlagen (Log: $RUN/restore-data.log)"; }

if [ -s "$RUN/vps-storage-objects.sql" ]; then
  log "Stelle Storage-Einträge des VPS wieder her"
  { echo "SET session_replication_role = replica;"; cat "$RUN/vps-storage-objects.sql"; } | psql_vps --single-transaction >/dev/null
fi

log "Schreibe Cloud-URL auf $NEW_URL um"
psql_vps -v old_url="$OLD_URL" -v new_url="$NEW_URL" <"$SQL_DIR/post-restore.sql"

log "Lege Vault-Secrets neu an"
while IFS=$'\t' read -r name b64 desc; do
  [ -n "$name" ] || continue
  psql_vps -v n="$name" -v b="$b64" -v d="$desc" -v o="$OLD_URL" -v u="$NEW_URL" >/dev/null <<'SQL'
delete from vault.secrets where name = :'n';
select vault.create_secret(replace(convert_from(decode(:'b','base64'),'UTF8'), :'o', :'u'), :'n', :'d');
SQL
  echo "   $name"
done <"$RUN/vault.tsv"

log "Lege Cron-Jobs neu an"
psql_vps -c "select cron.unschedule(jobid) from cron.job" >/dev/null
while IFS=$'\t' read -r name schedule b64; do
  [ -n "$name" ] || continue
  psql_vps -v n="$name" -v s="$schedule" -v b="$b64" -v o="$OLD_URL" -v u="$NEW_URL" >/dev/null <<'SQL'
select cron.schedule(:'n', :'s', replace(convert_from(decode(:'b','base64'),'UTF8'), :'o', :'u'));
SQL
  echo "   $name ($schedule)"
done <"$RUN/cron.tsv"

if [ "$MODE" = test ]; then
  log "Testmodus: Cron-Jobs AUS, Push-Tokens unbrauchbar gemacht (echte Nutzer bekommen nichts)"
  psql_vps -c "update cron.job set active = false" >/dev/null
  psql_vps -c "update public.device_tokens set fcm_token = 'TEST-' || fcm_token where fcm_token is not null and fcm_token not like 'TEST-%'" >/dev/null
else
  log "Finaler Modus: Cron-Jobs auf dem VPS AN"
  psql_vps -c "update cron.job set active = true" >/dev/null
fi

psql_vps -c "analyze" >/dev/null

# --- 3. Vergleich ---------------------------------------------------------------
log "Vergleich Cloud ↔ VPS"
q="select 'auth.users', count(*) from auth.users
   union all select 'public.posts', count(*) from public.posts
   union all select 'public.device_tokens', count(*) from public.device_tokens
   union all select 'storage.buckets', count(*) from storage.buckets
   union all select 'cron.job', count(*) from cron.job"
paste <(psql_cloud -At -F ' ' -c "$q") <(psql_vps -At -F ' ' -c "$q" | awk '{print $2}') \
  | awk 'BEGIN{printf "%-24s %10s %10s\n","Tabelle","Cloud","VPS"} {printf "%-24s %10s %10s\n",$1,$2,$3}'

log "Fertig. Dumps und Logs: $RUN"
if [ "$MODE" = test ]; then echo "Danach: bash scripts/migrate-storage.sh und bash scripts/deploy-functions.sh"; fi
