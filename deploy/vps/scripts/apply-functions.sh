#!/usr/bin/env bash
# Übernimmt Edge Functions aus einem Upload-Ordner (CI: rsync von supabase/functions/)
# in die laufende Supabase-Instanz und startet den Functions-Container neu.
#
#   sudo bash scripts/apply-functions.sh /docker/jugendkompass/incoming/functions [name ...]
#
# Ohne Namen werden alle Functions im Ordner übernommen. "main" (Router des
# Edge-Runtime) wird nie überschrieben. Aufgerufen vom GitLab-Job backend:functions.
set -euo pipefail
. "$(dirname "$0")/lib.sh"

src="${1:?Upload-Ordner angeben}"; shift || true
[ -d "$src" ] || die "$src fehlt."
target="$SUPABASE_DIR/volumes/functions"
SKIP="main migrate-firebase-storage functions-admin-variant"

names=("$@")
if [ "${#names[@]}" -eq 0 ]; then
  for d in "$src"/*/; do names+=("$(basename "$d")"); done
fi

backup="$WORK_DIR/functions-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup"
for name in "${names[@]}"; do
  case " $SKIP " in *" $name "*) echo "   übersprungen: $name"; continue ;; esac
  [ -d "$src/$name" ] || die "$src/$name fehlt."
  [ -d "$target/$name" ] && cp -a "$target/$name" "$backup/"
  rm -rf "${target:?}/$name"
  cp -a "$src/$name" "$target/$name"
  echo "   $name"
done
log "Sicherung der vorherigen Fassungen: $backup"

log "Starte Functions-Container neu"
(cd "$SUPABASE_DIR" && docker compose restart functions)
