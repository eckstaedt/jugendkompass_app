#!/usr/bin/env bash
# Nächtliches Backup: Datenbank-Dump (komprimiert) + Storage-Dateien.
# Behält 14 Tage. Als root-Cronjob eintragen:
#   15 3 * * * /docker/jugendkompass/scripts/backup.sh >> /docker/jugendkompass/backups/backup.log 2>&1
#
# Optional BACKUP_RSYNC_TARGET in jugendkompass.env (z.B. user@backupserver:/backups/jugendkompass)
# – dann wird der Backup-Ordner zusätzlich dorthin gespiegelt.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
load_config

dest="$JK_ROOT/backups"
stamp="$(date +%Y%m%d-%H%M)"
mkdir -p "$dest/db" "$dest/storage"
chmod 700 "$dest"

log "Datenbank-Dump"
docker exec "$DB_CONTAINER" pg_dump -U supabase_admin -d postgres -Fc \
  --exclude-table-data='net._http_response' >"$dest/db/jugendkompass-$stamp.dump"

log "Storage spiegeln"
rsync -a --delete "$SUPABASE_DIR/volumes/storage/" "$dest/storage/current/"

find "$dest/db" -name '*.dump' -mtime +14 -delete

if [ -n "${BACKUP_RSYNC_TARGET:-}" ]; then
  log "Kopiere nach $BACKUP_RSYNC_TARGET"
  rsync -a --delete "$dest/db" "$dest/storage" "$BACKUP_RSYNC_TARGET/"
fi
log "Backup fertig ($stamp)"
