#!/usr/bin/env bash
# Schaltet die geplanten Jobs (Tagesvers-Push, Edition-Pushes, Übersetzung …)
# in der Cloud oder auf dem VPS an oder aus. Es dürfen nie beide gleichzeitig
# an sein, sonst kommen Pushes doppelt. Jederzeit umkehrbar.
#
#   bash scripts/cron.sh status
#   bash scripts/cron.sh cloud off     # bei der Umstellung
#   bash scripts/cron.sh vps on
#   bash scripts/cron.sh cloud on      # Rückweg
set -euo pipefail
. "$(dirname "$0")/lib.sh"
load_config

show() {
  echo "Cloud:"; psql_cloud -At -F ' | ' -c "select jobname, schedule, case when active then 'AN' else 'aus' end from cron.job order by jobid" | sed 's/^/   /'
  echo "VPS:";   psql_vps   -At -F ' | ' -c "select jobname, schedule, case when active then 'AN' else 'aus' end from cron.job order by jobid" | sed 's/^/   /'
}

case "${1:-status} ${2:-}" in
  "status ") show ;;
  "cloud on")  require CLOUD_DB_URL; psql_cloud -c "update cron.job set active = true" ; show ;;
  "cloud off") require CLOUD_DB_URL; psql_cloud -c "update cron.job set active = false"; show ;;
  "vps on")
    on=$(psql_cloud -At -c "select count(*) from cron.job where active")
    [ "$on" = "0" ] || die "In der Cloud sind noch $on Jobs aktiv. Erst: bash scripts/cron.sh cloud off"
    psql_vps -c "update cron.job set active = true"; show ;;
  "vps off") psql_vps -c "update cron.job set active = false"; show ;;
  *) die "Aufruf: cron.sh status | cloud on|off | vps on|off" ;;
esac
