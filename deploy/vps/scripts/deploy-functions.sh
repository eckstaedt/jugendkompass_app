#!/usr/bin/env bash
# Holt den Code aller Edge Functions, wie er HEUTE in der Cloud deployt ist, und
# legt ihn auf dem VPS ab. So läuft auf dem VPS exakt dasselbe wie in der Cloud,
# auch wo App- und Admin-Repo unterschiedliche Stände derselben Function haben.
#
#   bash scripts/deploy-functions.sh
#
# Braucht SUPABASE_ACCESS_TOKEN in jugendkompass.env. Läuft die Supabase-CLI in
# einem Wegwerf-Container (kein Node auf dem Server nötig).
set -euo pipefail
. "$(dirname "$0")/lib.sh"

CLI_VERSION="2.122.1"
SKIP="migrate-firebase-storage"   # Einmal-Function, wird nicht mehr gebraucht

load_config
require SUPABASE_ACCESS_TOKEN CLOUD_PROJECT_REF

dl="$WORK_DIR/functions-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$dl"

log "Lade deployte Functions aus der Cloud (CLI $CLI_VERSION)"
docker run --rm -v "$dl:/w" -w /w -e SUPABASE_ACCESS_TOKEN \
  node:22-bookworm-slim \
  npx -y "supabase@$CLI_VERSION" functions download --project-ref "$CLOUD_PROJECT_REF" --use-api

src="$dl/supabase/functions"
[ -d "$src" ] || die "Download lieferte nichts ($src fehlt)."

target="$SUPABASE_DIR/volumes/functions"
for d in "$src"/*/; do
  name="$(basename "$d")"
  case " $SKIP " in *" $name "*) echo "   übersprungen: $name"; continue ;; esac
  rm -rf "${target:?}/$name"
  cp -a "$d" "$target/$name"
  echo "   $name"
done

log "Starte Functions-Container neu"
stack restart functions

log "Fertig. Logs ansehen: cd $SUPABASE_DIR && docker compose logs -f functions"
