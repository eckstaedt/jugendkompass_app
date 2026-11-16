#!/usr/bin/env bash
# Kopiert alle Storage-Dateien (ca. 13 GB) aus der Cloud auf den VPS – über die
# S3-Schnittstelle beider Seiten mit rclone. Wiederholbar: beim zweiten Lauf
# werden nur neue oder geänderte Dateien übertragen.
#
#   bash scripts/migrate-storage.sh
#
# Voraussetzung: migrate-db.sh ist gelaufen (Buckets existieren auf dem VPS).
set -euo pipefail
. "$(dirname "$0")/lib.sh"

load_config
require CLOUD_PROJECT_REF CLOUD_DB_URL CLOUD_S3_REGION CLOUD_S3_ACCESS_KEY_ID CLOUD_S3_SECRET_ACCESS_KEY

envf="$SUPABASE_DIR/.env"
VPS_KEY_ID="$(get_env "$envf" S3_PROTOCOL_ACCESS_KEY_ID)"
VPS_KEY_SECRET="$(get_env "$envf" S3_PROTOCOL_ACCESS_KEY_SECRET)"
VPS_REGION="$(get_env "$envf" REGION)"
NETWORK="jugendkompass_default"

docker network inspect "$NETWORK" >/dev/null 2>&1 || die "Docker-Netz $NETWORK fehlt – läuft der Supabase-Stack?"

buckets=$(psql_cloud -At -c "select id from storage.buckets order by id")
[ -n "$buckets" ] || die "Keine Buckets in der Cloud gefunden?"

rclone() {
  docker run --rm --network "$NETWORK" \
    -e RCLONE_CONFIG_CLOUD_TYPE=s3 \
    -e RCLONE_CONFIG_CLOUD_PROVIDER=Other \
    -e RCLONE_CONFIG_CLOUD_ENDPOINT="https://${CLOUD_PROJECT_REF}.supabase.co/storage/v1/s3" \
    -e RCLONE_CONFIG_CLOUD_REGION="$CLOUD_S3_REGION" \
    -e RCLONE_CONFIG_CLOUD_ACCESS_KEY_ID="$CLOUD_S3_ACCESS_KEY_ID" \
    -e RCLONE_CONFIG_CLOUD_SECRET_ACCESS_KEY="$CLOUD_S3_SECRET_ACCESS_KEY" \
    -e RCLONE_CONFIG_CLOUD_FORCE_PATH_STYLE=true \
    -e RCLONE_CONFIG_VPS_TYPE=s3 \
    -e RCLONE_CONFIG_VPS_PROVIDER=Other \
    -e RCLONE_CONFIG_VPS_ENDPOINT="http://kong:8000/storage/v1/s3" \
    -e RCLONE_CONFIG_VPS_REGION="$VPS_REGION" \
    -e RCLONE_CONFIG_VPS_ACCESS_KEY_ID="$VPS_KEY_ID" \
    -e RCLONE_CONFIG_VPS_SECRET_ACCESS_KEY="$VPS_KEY_SECRET" \
    -e RCLONE_CONFIG_VPS_FORCE_PATH_STYLE=true \
    "$RCLONE_IMAGE" "$@"
}

log "Teste Zugriff auf beide Seiten"
rclone lsd cloud: >/dev/null || die "Kein Zugriff auf den Cloud-Storage (CLOUD_S3_* prüfen)."
rclone lsd vps: >/dev/null || die "Kein Zugriff auf den VPS-Storage."

for b in $buckets; do
  log "Bucket $b"
  rclone sync "cloud:$b" "vps:$b" \
    --size-only --fast-list --s3-no-check-bucket \
    --transfers 8 --checkers 16 \
    --s3-upload-cutoff 16M --s3-chunk-size 16M \
    --stats 30s --stats-one-line
done

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
