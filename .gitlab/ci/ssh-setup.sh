#!/bin/sh
# SSH-Zugang zum VPS für rsync-Deploys (Alpine- oder Debian-Image).
#
# CI/CD-Variablen (Gruppe oder Projekt):
#   VPS_SSH_HOST          Hostname/IP
#   VPS_SSH_USER          Benutzer mit Schreibrecht auf /docker/jugendkompass/sites
#   VPS_SSH_KEY           Typ "File": privater Schlüssel (nur für Deploys)
#   VPS_SSH_KNOWN_HOSTS   Typ "File": Ausgabe von ssh-keyscan -p <port> <host>
#   VPS_SSH_PORT          optional, Standard 22
for v in VPS_SSH_HOST VPS_SSH_USER VPS_SSH_KEY VPS_SSH_KNOWN_HOSTS; do
  eval "val=\${$v:-}"
  if [ -z "$val" ]; then echo "CI/CD-Variable $v fehlt."; exit 1; fi
done
if command -v apk >/dev/null 2>&1; then
  apk add --no-cache rsync openssh-client >/dev/null
elif ! command -v rsync >/dev/null 2>&1 || ! command -v ssh >/dev/null 2>&1; then
  apt-get update -qq && apt-get install -y -qq rsync openssh-client >/dev/null
fi
install -m 700 -d ~/.ssh
# File-Variablen enthalten einen Pfad, normale Variablen den Inhalt selbst
if [ -f "$VPS_SSH_KEY" ]; then cp "$VPS_SSH_KEY" ~/.ssh/id_deploy; else printf '%s\n' "$VPS_SSH_KEY" > ~/.ssh/id_deploy; fi
if [ -f "$VPS_SSH_KNOWN_HOSTS" ]; then cp "$VPS_SSH_KNOWN_HOSTS" ~/.ssh/known_hosts; else printf '%s\n' "$VPS_SSH_KNOWN_HOSTS" > ~/.ssh/known_hosts; fi
chmod 600 ~/.ssh/id_deploy
export RSH="ssh -i $HOME/.ssh/id_deploy -p ${VPS_SSH_PORT:-22} -o BatchMode=yes"
