#!/usr/bin/env bash
# Gemeinsame Helfer für die Jugendkompass-VPS-Skripte.
set -euo pipefail

# Basisverzeichnis auf dem Server (überschreibbar für Tests).
JK_ROOT="${JK_ROOT:-/docker/jugendkompass}"
SUPABASE_DIR="$JK_ROOT/supabase"
WORK_DIR="$JK_ROOT/migration"
DB_CONTAINER="jk-db"
# Offizieller Self-Hosting-Stand, getestet für diesen Umzug.
SUPABASE_SELFHOST_TAG="self-hosted/v0.8.4"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mFEHLER:\033[0m %s\n' "$*" >&2; exit 1; }

load_config() {
  local f="$JK_ROOT/jugendkompass.env"
  [ -f "$f" ] || die "$f fehlt. Vorlage: jugendkompass.env.example"
  set -a
  # shellcheck disable=SC1090
  . "$f"
  set +a
}

require() {
  local v
  for v in "$@"; do
    [ -n "${!v:-}" ] || die "$v ist in jugendkompass.env nicht gesetzt."
  done
}

# Ziel-Datenbank (VPS) als Superuser über den laufenden Container.
psql_vps() {
  docker exec -i "$DB_CONTAINER" psql -U supabase_admin -d postgres -v ON_ERROR_STOP=1 -X -q "$@"
}

# Quell-Datenbank (Cloud). Läuft im DB-Container, der psql 17 mitbringt.
psql_cloud() {
  docker exec -i -e PGCONNECT_TIMEOUT=15 "$DB_CONTAINER" psql "$CLOUD_DB_URL" -v ON_ERROR_STOP=1 -X -q "$@"
}

pg_dump_cloud() {
  docker exec -i "$DB_CONTAINER" pg_dump "$CLOUD_DB_URL" "$@"
}

# Setzt KEY=VALUE in einer .env-Datei (ersetzt oder hängt an).
set_env() {
  local file="$1" key="$2" value="$3" tmp
  tmp="$(mktemp)"
  if grep -q "^${key}=" "$file"; then
    awk -v k="$key" -v v="$value" 'BEGIN{FS=OFS="="} $1==k {print k "=" v; next} {print}' "$file" >"$tmp"
  else
    cat "$file" >"$tmp"
    printf '%s=%s\n' "$key" "$value" >>"$tmp"
  fi
  cat "$tmp" >"$file"
  rm -f "$tmp"
}

get_env() {
  grep "^$2=" "$1" | head -n1 | cut -d= -f2-
}

rand_hex() { openssl rand -hex "$1"; }

stack() {
  (cd "$SUPABASE_DIR" && docker compose "$@")
}
