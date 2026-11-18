#!/usr/bin/env bash
# Kopiert die GitHub-Repos mit allen Branches und Tags nach GitLab.
#
#   export GITLAB_TOKEN=glpat-…        # Personal Access Token, Scope "api"
#   export GITHUB_TOKEN=ghp_…          # nur nötig, falls die Repos privat sind (Scope "repo")
#   bash deploy/gitlab/move-repos.sh
#
# Legt die Gruppe GITLAB_GROUP (Standard "jugendkompass") und die Projekte an,
# falls sie fehlen. Kann gefahrlos mehrfach laufen (aktualisiert nur).
set -euo pipefail

GITLAB_URL="${GITLAB_URL:-https://gitlab.bethaus-speyer.de}"
GITLAB_GROUP="${GITLAB_GROUP:-jugendkompass}"
REPOS=("jugendkompass_app:app" "jugendkompass-admin:admin")   # GitHub-Name:GitLab-Projektpfad
: "${GITLAB_TOKEN:?GITLAB_TOKEN setzen (Scope api)}"

api() { curl -fsS -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$@"; }
urlenc() { python3 -c 'import sys,urllib.parse;print(urllib.parse.quote(sys.argv[1],safe=""))' "$1"; }

group_id=$(api "$GITLAB_URL/api/v4/groups/$(urlenc "$GITLAB_GROUP")" 2>/dev/null | python3 -c 'import sys,json;print(json.load(sys.stdin)["id"])' || true)
if [ -z "$group_id" ]; then
  echo "Lege Gruppe $GITLAB_GROUP an …"
  group_id=$(api -X POST "$GITLAB_URL/api/v4/groups" -d "name=Jugendkompass" -d "path=$GITLAB_GROUP" -d "visibility=private" \
    | python3 -c 'import sys,json;print(json.load(sys.stdin)["id"])')
fi

gh_auth=""
[ -n "${GITHUB_TOKEN:-}" ] && gh_auth="x-access-token:${GITHUB_TOKEN}@"
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT

for entry in "${REPOS[@]}"; do
  gh_name="${entry%%:*}"; gl_path="${entry##*:}"
  echo "== $gh_name → $GITLAB_GROUP/$gl_path"
  if ! api "$GITLAB_URL/api/v4/projects/$(urlenc "$GITLAB_GROUP/$gl_path")" >/dev/null 2>&1; then
    api -X POST "$GITLAB_URL/api/v4/projects" -d "name=$gl_path" -d "path=$gl_path" \
      -d "namespace_id=$group_id" -d "visibility=private" -d "initialize_with_readme=false" >/dev/null
  fi
  git clone --quiet --bare "https://${gh_auth}github.com/eckstaedt/${gh_name}.git" "$work/$gh_name.git"
  host="${GITLAB_URL#https://}"
  # Nur Branches und Tags (GitHub-PR-Refs würde GitLab ablehnen)
  # ci.skip: keine Pipelines (sonst würden alte Tags Store-Uploads auslösen)
  git -C "$work/$gh_name.git" push --quiet --force -o ci.skip \
    "https://oauth2:${GITLAB_TOKEN}@${host}/${GITLAB_GROUP}/${gl_path}.git" \
    'refs/heads/*:refs/heads/*' 'refs/tags/*:refs/tags/*'
  echo "   ok: $GITLAB_URL/$GITLAB_GROUP/$gl_path"
done
