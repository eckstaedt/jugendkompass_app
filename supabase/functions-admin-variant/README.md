# Abweichende Fassungen aus dem früheren Admin-Repo – klären, dann löschen

Diese Edge Functions lagen in beiden alten Repos, in unterschiedlichen Fassungen:
`_shared`, `dispatch-edition-pushes`, `dispatch-impulse-pushes`, `dispatch-message-pushes`,
`dispatch-video-pushes`, `send-push-notification`.

Die Fassung in `supabase/functions/` stammt aus dem App-Repo, die hier aus dem Admin-Repo.
Maßgeblich ist, was auf dem VPS läuft (`/docker/jugendkompass/supabase/volumes/functions`,
dorthin kopiert von `deploy/vps/scripts/deploy-functions.sh` aus der Cloud).
Sobald dieser Stand in `supabase/functions/` übernommen ist, wird dieser Ordner gelöscht.
