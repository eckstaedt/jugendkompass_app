#!/usr/bin/env bash
# Spielt EINE SQL-Migration in die VPS-Datenbank ein (mit ON_ERROR_STOP).
#
#   sudo bash scripts/apply-migration.sh /docker/jugendkompass/incoming/migration.sql
#
# Aufgerufen vom manuellen GitLab-Job backend:migration. Migrationen laufen bewusst
# nie automatisch: viele ältere Dateien wurden von Hand eingespielt und dürfen nicht erneut laufen.
set -euo pipefail
. "$(dirname "$0")/lib.sh"

file="${1:?SQL-Datei angeben}"
[ -f "$file" ] || die "$file fehlt."
log "Spiele $(basename "$file") ein"
psql_vps -1 < "$file"
log "Fertig."
