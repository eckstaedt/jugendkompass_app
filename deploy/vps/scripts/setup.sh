#!/usr/bin/env bash
# Richtet den Jugendkompass-Stack unter /docker/jugendkompass ein.
# Idempotent: kann nach Änderungen an jugendkompass.env erneut laufen.
# Generierte Passwörter (Postgres usw.) bleiben dabei erhalten.
#
#   sudo bash /docker/jugendkompass/scripts/setup.sh
set -euo pipefail
. "$(dirname "$0")/lib.sh"

load_config
require API_DOMAIN WWW_DOMAIN APEX_DOMAIN ADMIN_DOMAIN TRANSLATE_DOMAIN \
        TRAEFIK_NETWORK TRAEFIK_ENTRYPOINT TRAEFIK_CERTRESOLVER \
        JWT_SECRET ANON_KEY SERVICE_ROLE_KEY

command -v docker >/dev/null || die "docker fehlt"
command -v git >/dev/null || die "git fehlt"
command -v openssl >/dev/null || die "openssl fehlt"
docker compose version >/dev/null 2>&1 || die "docker compose (v2) fehlt"
docker network inspect "$TRAEFIK_NETWORK" >/dev/null 2>&1 \
  || die "Docker-Netz '$TRAEFIK_NETWORK' existiert nicht. TRAEFIK_NETWORK prüfen (docker network ls)."

# --- 1. Offiziellen Supabase-Docker-Stand holen ----------------------------------
if [ ! -f "$SUPABASE_DIR/docker-compose.yml" ]; then
  log "Lade Supabase Self-Hosting ($SUPABASE_SELFHOST_TAG)"
  src="$(mktemp -d)"
  git clone -q --depth 1 --branch "$SUPABASE_SELFHOST_TAG" --filter=blob:none --sparse \
    https://github.com/supabase/supabase.git "$src"
  git -C "$src" sparse-checkout set docker
  mkdir -p "$SUPABASE_DIR"
  cp -a "$src/docker/." "$SUPABASE_DIR/"
  rm -rf "$src"
else
  log "Supabase-Stack schon vorhanden ($SUPABASE_DIR)"
fi

cp "$JK_ROOT/docker-compose.supabase.yml" "$SUPABASE_DIR/docker-compose.jugendkompass.yml"

# --- 2. JWT-Prüfung pro Function statt global ------------------------------------
main_ts="$SUPABASE_DIR/volumes/functions/main/index.ts"
if ! grep -q VERIFY_JWT_FUNCTIONS "$main_ts"; then
  log "Patche Functions-Router: JWT-Prüfung nur für VERIFY_JWT_FUNCTIONS"
  sed -i \
    -e "s|^const VERIFY_JWT = Deno.env.get('VERIFY_JWT') === 'true'|const VERIFY_JWT = Deno.env.get('VERIFY_JWT') === 'true'\nconst VERIFY_JWT_FUNCTIONS = (Deno.env.get('VERIFY_JWT_FUNCTIONS') ?? '').split(',').map((s) => s.trim()).filter(Boolean)|" \
    -e "s|if (req.method !== 'OPTIONS' && VERIFY_JWT) {|if (req.method !== 'OPTIONS' \&\& (VERIFY_JWT \|\| VERIFY_JWT_FUNCTIONS.includes(new URL(req.url).pathname.split('/')[1]))) {|" \
    "$main_ts"
  grep -q "VERIFY_JWT_FUNCTIONS.includes" "$main_ts" || die "Patch von $main_ts fehlgeschlagen (Upstream geändert?)"
fi

# --- 3. supabase/.env erzeugen bzw. aktualisieren --------------------------------
envf="$SUPABASE_DIR/.env"
if [ ! -f "$envf" ]; then
  log "Erzeuge $envf mit neuen internen Passwörtern"
  cp "$SUPABASE_DIR/.env.example" "$envf"
  set_env "$envf" POSTGRES_PASSWORD "$(rand_hex 24)"
  set_env "$envf" SECRET_KEY_BASE "$(rand_hex 32)"
  set_env "$envf" VAULT_ENC_KEY "$(rand_hex 16)"
  set_env "$envf" PG_META_CRYPTO_KEY "$(rand_hex 16)"
  set_env "$envf" LOGFLARE_PUBLIC_ACCESS_TOKEN "$(rand_hex 24)"
  set_env "$envf" LOGFLARE_PRIVATE_ACCESS_TOKEN "$(rand_hex 24)"
  set_env "$envf" S3_PROTOCOL_ACCESS_KEY_ID "$(rand_hex 16)"
  set_env "$envf" S3_PROTOCOL_ACCESS_KEY_SECRET "$(rand_hex 32)"
  set_env "$envf" POOLER_TENANT_ID "jugendkompass"
  set_env "$envf" DASHBOARD_PASSWORD "${DASHBOARD_PASSWORD:-$(rand_hex 16)}"
fi
chmod 600 "$envf"

log "Übernehme Werte aus jugendkompass.env"
set_env "$envf" COMPOSE_PROJECT_NAME "jugendkompass"
set_env "$envf" COMPOSE_FILE "docker-compose.yml:docker-compose.jugendkompass.yml"
set_env "$envf" JWT_SECRET "$JWT_SECRET"
set_env "$envf" ANON_KEY "$ANON_KEY"
set_env "$envf" SERVICE_ROLE_KEY "$SERVICE_ROLE_KEY"
set_env "$envf" SUPABASE_PUBLIC_URL "https://$API_DOMAIN"
set_env "$envf" API_EXTERNAL_URL "https://$API_DOMAIN/auth/v1"
set_env "$envf" SITE_URL "https://$WWW_DOMAIN"
set_env "$envf" ADDITIONAL_REDIRECT_URLS "https://$ADMIN_DOMAIN/**,https://$WWW_DOMAIN/**"
set_env "$envf" ENABLE_ANONYMOUS_USERS "true"   # App meldet sich anonym an (Umfragen, Likes)
set_env "$envf" ENABLE_EMAIL_SIGNUP "false"     # Admin-Konten entstehen über create-user
set_env "$envf" ENABLE_PHONE_SIGNUP "false"
set_env "$envf" DISABLE_SIGNUP "false"
set_env "$envf" FUNCTIONS_VERIFY_JWT "false"
set_env "$envf" VERIFY_JWT_FUNCTIONS "${VERIFY_JWT_FUNCTIONS:-}"
set_env "$envf" STUDIO_DEFAULT_ORGANIZATION "Jugendkompass"
set_env "$envf" STUDIO_DEFAULT_PROJECT "Jugendkompass"
set_env "$envf" API_DOMAIN "$API_DOMAIN"
set_env "$envf" TRAEFIK_NETWORK "$TRAEFIK_NETWORK"
set_env "$envf" TRAEFIK_ENTRYPOINT "$TRAEFIK_ENTRYPOINT"
set_env "$envf" TRAEFIK_CERTRESOLVER "$TRAEFIK_CERTRESOLVER"
[ -n "${DASHBOARD_USERNAME:-}" ] && set_env "$envf" DASHBOARD_USERNAME "$DASHBOARD_USERNAME"
[ -n "${DASHBOARD_PASSWORD:-}" ] && set_env "$envf" DASHBOARD_PASSWORD "$DASHBOARD_PASSWORD"
if [ -n "${SMTP_HOST:-}" ]; then
  set_env "$envf" SMTP_HOST "$SMTP_HOST"
  set_env "$envf" SMTP_PORT "${SMTP_PORT:-587}"
  set_env "$envf" SMTP_USER "${SMTP_USER:-}"
  set_env "$envf" SMTP_PASS "${SMTP_PASS:-}"
  set_env "$envf" SMTP_ADMIN_EMAIL "${SMTP_ADMIN_EMAIL:-}"
  set_env "$envf" SMTP_SENDER_NAME "${SMTP_SENDER_NAME:-Jugendkompass}"
fi

# --- 4. Function-Secrets, Web-Stack, Verzeichnisse -------------------------------
if [ ! -f "$JK_ROOT/functions.env" ]; then
  warn "functions.env fehlt – lege leere Vorlage an. Vor dem ersten Push-Test ausfüllen!"
  cp "$JK_ROOT/functions.env.example" "$JK_ROOT/functions.env"
fi
chmod 600 "$JK_ROOT/functions.env" "$JK_ROOT/jugendkompass.env"
ln -sfn jugendkompass.env "$JK_ROOT/.env"   # für docker-compose.web.yml
mkdir -p "$JK_ROOT/sites/www" "$JK_ROOT/sites/admin" "$JK_ROOT/sites/translate" "$WORK_DIR" "$JK_ROOT/backups"
for s in www admin translate; do
  [ -f "$JK_ROOT/sites/$s/index.html" ] || \
    printf '<!doctype html><meta charset="utf-8"><title>Jugendkompass</title><p>Wird gerade eingerichtet.</p>\n' \
      >"$JK_ROOT/sites/$s/index.html"
done

log "Fertig. Nächste Schritte:"
cat <<EOF
  cd $SUPABASE_DIR && docker compose pull && docker compose up -d --wait
  cd $JK_ROOT && docker compose -f docker-compose.web.yml up -d
  Studio: https://$API_DOMAIN/  (Login: siehe DASHBOARD_USERNAME/PASSWORD in $envf)
EOF
