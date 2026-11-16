# Jugendkompass auf dem eigenen VPS

Alles, was bisher bei Supabase Cloud, Vercel und Lovable läuft, liegt danach in
`/docker/jugendkompass` auf dem VPS, hinter dem vorhandenen Traefik mit Let's Encrypt.
Firebase bleibt nur für Push (FCM).

```
/docker/jugendkompass/
├── jugendkompass.env          ← zentrale Konfiguration (Secrets!)
├── functions.env              ← Secrets der Edge Functions
├── docker-compose.web.yml     ← nginx (www, Apex, Admin, Panel) + Share-Dienst
├── docker-compose.supabase.yml
├── scripts/                   ← setup, migrate-db, migrate-storage, deploy-functions, cron, backup
├── sql/
├── web/                       ← nginx-Template, Share-Server
├── sites/{www,admin,translate}← gebaute Webseiten (kommen per GitHub Actions)
├── supabase/                  ← offizieller Supabase-Stack (setup.sh lädt ihn)
├── migration/                 ← Dumps und Logs der Migration
└── backups/
```

| Adresse | Dienst |
| --- | --- |
| `api.jugendkompass.com` | Supabase (REST, Auth, Storage, Realtime, Functions). Unter `/` das Studio mit Passwort |
| `www.jugendkompass.com` | Flutter-Web, Share-Links (`/post/<id>` usw.), `.well-known` |
| `jugendkompass.com` | `.well-known` direkt, sonst Weiterleitung auf www |
| `admin.jugendkompass.com` | Admin-PWA |
| `translate.jugendkompass.com` | Übersetzungs-Panel |

Alle Skripte als root (oder mit sudo) aus `/docker/jugendkompass` starten.

---

## 1. Einmalig einrichten (Montag/Dienstag)

**Voraussetzungen auf dem VPS:** Docker mit Compose v2.24+, git, openssl, rsync,
Traefik mit Let's-Encrypt-Resolver. Mindestens 4 vCPU, 8 GB RAM, 80 GB SSD.

1. **DNS** (beim Domain-Anbieter): A-Records `api`, `admin`, `translate` auf die
   VPS-IP. `www` und die Hauptdomain bleiben bis zur Umstellung bei Vercel.
   TTL von `www` und `@` schon jetzt auf 300 Sekunden senken.
2. **Dateien auf den Server:** Inhalt von `deploy/vps/` nach `/docker/jugendkompass/`
   kopieren, z.B. vom eigenen Rechner:
   ```bash
   rsync -av deploy/vps/ root@SERVER:/docker/jugendkompass/
   ```
3. **Konfiguration:**
   ```bash
   cd /docker/jugendkompass
   cp jugendkompass.env.example jugendkompass.env
   cp functions.env.example functions.env
   chmod 600 jugendkompass.env functions.env
   nano jugendkompass.env    # Domains, Traefik-Namen, JWT_SECRET, ANON_KEY, SERVICE_ROLE_KEY, CLOUD_*
   nano functions.env        # FCM, Anthropic, Lovable, Resend, Telegram
   ```
   - `TRAEFIK_NETWORK`, `TRAEFIK_ENTRYPOINT`, `TRAEFIK_CERTRESOLVER` wie bei Attendix.
   - `JWT_SECRET`, `ANON_KEY`, `SERVICE_ROLE_KEY` **aus der Cloud übernehmen**
     (Dashboard → Project Settings → API Keys / JWT Keys, jeweils "Legacy").
     Nur so bleiben App-Logins und alle Schlüssel gültig.
   - Die Werte der Function-Secrets kann das Supabase-Dashboard nicht anzeigen.
     FCM-Schlüssel ggf. in der Firebase Console neu erzeugen. Den Anthropic-Key
     und das Worker-Secret der Übersetzung übernimmt `migrate-db.sh` ohnehin aus dem Vault.
4. **Setup und Start:**
   ```bash
   bash scripts/setup.sh
   cd supabase && docker compose pull && docker compose up -d --wait && cd ..
   docker compose -f docker-compose.web.yml up -d
   ```
   Kontrolle: `https://api.jugendkompass.com/` fragt nach dem Studio-Login
   (Benutzer/Passwort: `DASHBOARD_USERNAME`/`DASHBOARD_PASSWORD` in `supabase/.env`).

## 2. Probelauf mit echten Daten

```bash
bash scripts/migrate-db.sh --test       # ca. 5 Minuten
bash scripts/migrate-storage.sh         # ca. 13 GB, je nach Leitung 20–60 Minuten
bash scripts/deploy-functions.sh
bash scripts/backup.sh                  # einmal testen, dann als Cronjob eintragen (siehe Kopf der Datei)
```

Im Testmodus sind alle Cron-Jobs auf dem VPS aus, und die gespeicherten
Push-Tokens sind ungültig gemacht. **Echte Nutzer bekommen also keine Pushes vom VPS.**
Ein Testgerät, das eine App-Version mit der neuen URL startet, registriert sich neu und
bekommt Pushes.

Wiederholen geht jederzeit mit `bash scripts/migrate-db.sh --test --reset`.
Bereits kopierte Dateien bleiben dabei erhalten.

**Was testen:**
- [ ] App (Debug-Build mit `SUPABASE_URL=https://api.jugendkompass.com` in `dotenv`): Start, Inhalte, Bilder, Audio, Video, Umfrage abstimmen, Like
- [ ] Admin über GitHub-Workflow "Admin → VPS" bauen, dann `https://admin.jugendkompass.com`: Login, Bild hochladen, Entwurf speichern
- [ ] Push an das Testgerät (Admin → Test-Push)
- [ ] Übersetzungs-Panel über Workflow "Web → VPS", dann `https://translate.jugendkompass.com`
- [ ] Share-Link vorab: `curl --resolve www.jugendkompass.com:443:VPS-IP https://www.jugendkompass.com/post/<id>` enthält `og:image`
- [ ] Studio: Tabellen, Storage, Cron-Jobs (`cron.job`) sichtbar

## 3. GitHub einrichten

In **beiden** Repos (Settings → Secrets and variables → Actions):

| Name | Art | Wert |
| --- | --- | --- |
| `VPS_SSH_HOST` | Secret | Hostname/IP |
| `VPS_SSH_USER` | Secret | Deploy-Benutzer mit Schreibrecht auf `/docker/jugendkompass/sites` |
| `VPS_SSH_KEY` | Secret | eigener SSH-Schlüssel nur für Deploys |
| `VPS_SSH_KNOWN_HOSTS` | Secret | `ssh-keyscan -p PORT HOST` |
| `VPS_SSH_PORT` | Variable | nur falls nicht 22 |

Im App-Repo zusätzlich zur Umstellung: Variable `SUPABASE_URL=https://api.jugendkompass.com`
(für Verse-Bilder, englische Audios, Bildübersetzung) und Secret `SUPABASE_SERVICE_ROLE_KEY`
setzen, falls noch nicht vorhanden.

## 4. App-Version mit neuer URL (spätestens Mittwoch)

`dotenv` zeigt in diesem Branch schon auf `https://api.jugendkompass.com`.
Version in `pubspec.yaml` erhöhen, Tag setzen → iOS/Android-Workflows laden zu
TestFlight und Play hoch. In beiden Stores **manuelle Veröffentlichung** wählen und
erst am Umstellungstag freigeben. Die Prüfer nutzen bereits den VPS (Testdaten).

## 5. Umstellung (Samstag)

Vorher: keine Inhalte im Admin veröffentlichen (ca. 1–2 Stunden).

```bash
cd /docker/jugendkompass
bash scripts/cron.sh cloud off                 # Cloud-Jobs aus (umkehrbar)
bash scripts/migrate-db.sh --final --reset     # frische Kopie, Cron auf VPS an, echte Tokens
bash scripts/migrate-storage.sh                # nur noch neue Dateien
bash scripts/deploy-functions.sh               # falls seit dem Probelauf Functions geändert wurden
bash scripts/cron.sh status                    # Cloud: alles aus, VPS: alles an
```

Dann:
1. Telegram-Bot auf die neue Adresse umstellen:
   ```bash
   . functions.env
   curl "https://api.telegram.org/bot${TELEGRAM_PUSH_BOT_TOKEN}/setWebhook" \
     -d "url=https://api.jugendkompass.com/functions/v1/telegram-push-bot" \
     -d "secret_token=${TELEGRAM_PUSH_WEBHOOK_SECRET}"
   ```
2. Workflows "Web → VPS" (App-Repo) und "Admin → VPS" (Admin-Repo) starten.
3. **DNS:** `www` und `@` auf die VPS-IP. (Nach Freigabe – das ist der eigentliche Schalter.)
4. App-Versionen in App Store und Play freigeben.
5. Push an alle: "Neue Version verfügbar – bitte aktualisieren".
6. In beiden Workflows den `push`-Trigger einkommentieren, Repo-Variable `SUPABASE_URL` setzen.

**Rückweg** (falls etwas Grundlegendes nicht geht): DNS zurück auf Vercel,
`bash scripts/cron.sh vps off && bash scripts/cron.sh cloud on`. Die Cloud-Daten sind
unverändert, nur was in der Zwischenzeit auf dem VPS entstand, fehlt dort.

## 6. Danach

- Cloud-Projekt 2–4 Wochen weiterlaufen lassen (alte App-Versionen), dann pausieren.
- Vercel-Projekt und Lovable-Hosting abschalten, sobald alles stabil ist.
- `supabase-deploy.yml` deployt weiterhin in die Cloud – nicht mehr benutzen.
  Functions kommen bis auf Weiteres über `scripts/deploy-functions.sh` bzw. direkt nach
  `supabase/volumes/functions/<name>/` und `docker compose restart functions`.

## Häufige Befehle

```bash
cd /docker/jugendkompass/supabase
docker compose ps                     # Status
docker compose logs -f functions      # Function-Logs
docker compose logs -f auth
docker exec -it jk-db psql -U supabase_admin -d postgres
cd .. && bash scripts/cron.sh status
```
