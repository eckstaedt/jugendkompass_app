#!/usr/bin/env bash
# Kopiert alle Storage-Dateien (ca. 13 GB) aus der Cloud auf den VPS.
# Download über die öffentlichen Objekt-URLs der Cloud (alle Buckets sind public),
# Upload über die Storage-API des VPS. Wiederholbar: beim nächsten Lauf werden
# nur fehlende oder in der Größe abweichende Dateien übertragen.
#
#   bash scripts/migrate-storage.sh
#
# Voraussetzung: migrate-db.sh ist gelaufen (Buckets existieren auf dem VPS).
set -euo pipefail
. "$(dirname "$0")/lib.sh"

load_config
require CLOUD_PROJECT_REF CLOUD_DB_URL SERVICE_ROLE_KEY

NETWORK="jugendkompass_default"
docker network inspect "$NETWORK" >/dev/null 2>&1 || die "Docker-Netz $NETWORK fehlt – läuft der Supabase-Stack?"

private=$(psql_cloud -At -c "select string_agg(id, ', ') from storage.buckets where not public")
[ -z "$private" ] || warn "Nicht öffentliche Buckets werden übersprungen: $private"

lists="$WORK_DIR/storage-lists"
mkdir -p "$lists"
log "Lese Dateilisten (Cloud und VPS)"
psql_cloud -At -c "select json_build_object('b', o.bucket_id, 'n', o.name, 's', (o.metadata->>'size')::bigint, 't', o.metadata->>'mimetype', 'c', o.metadata->>'cacheControl')
                   from storage.objects o join storage.buckets b on b.id = o.bucket_id
                   where b.public and o.metadata ? 'size'" >"$lists/cloud.jsonl"
psql_vps -At -c "select json_build_object('b', bucket_id, 'n', name, 's', (metadata->>'size')::bigint)
                 from storage.objects where metadata ? 'size'" >"$lists/vps.jsonl"

log "Kopiere Dateien"
docker run --rm --network "$NETWORK" \
  -v "$lists:/lists:ro" \
  -v "$JK_ROOT/scripts/copy-storage.mjs:/app/copy-storage.mjs:ro" \
  -e CLOUD_URL="https://${CLOUD_PROJECT_REF}.supabase.co" \
  -e VPS_STORAGE_URL="http://storage:5000" \
  -e SERVICE_ROLE_KEY \
  -e LIST_CLOUD=/lists/cloud.jsonl -e LIST_VPS=/lists/vps.jsonl \
  -e CONCURRENCY="${STORAGE_CONCURRENCY:-6}" \
  node:22-alpine node /app/copy-storage.mjs || warn "Nicht alle Dateien wurden kopiert (siehe oben). Vergleich folgt."

log "Übernehme Besitzer der Dateien (für Policies wie 'eigene Audios bearbeiten')"
{
  echo "create temp table o (bucket_id text, name text, owner uuid, owner_id text);"
  echo "copy o from stdin;"
  psql_cloud -c "copy (select bucket_id, name, owner, owner_id from storage.objects) to stdout"
  echo '\.'
  echo "update storage.objects s set owner = o.owner, owner_id = o.owner_id from o
        where s.bucket_id = o.bucket_id and s.name = o.name
          and (s.owner is distinct from o.owner or s.owner_id is distinct from o.owner_id);"
} | psql_vps >/dev/null

log "Vergleich Dateien pro Bucket (Cloud / VPS)"
q="select bucket_id, count(*), coalesce(sum((metadata->>'size')::bigint),0) from storage.objects group by 1 order by 1"
join -a1 -a2 -e 0 -o 0,1.2,2.2,1.3,2.3 \
  <(psql_cloud -At -F ' ' -c "$q" | sort) \
  <(psql_vps -At -F ' ' -c "$q" | sort) \
  | awk 'BEGIN{printf "%-14s %8s %8s %12s %12s\n","Bucket","Cloud","VPS","Cloud MB","VPS MB"}
         {printf "%-14s %8s %8s %12.1f %12.1f%s\n",$1,$2,$3,$4/1e6,$5/1e6,($2!=$3?"   <-- abweichend":"")}'
