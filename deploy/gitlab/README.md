# Umzug nach GitLab + CI/CD

Ziel: Beide Repos liegen auf `gitlab.bethaus-speyer.de`, GitLab CI ersetzt alle
GitHub Actions, und Releases gehen per Tag automatisch in die Stores.

| Was | Datei |
| --- | --- |
| App-Pipeline | `.gitlab-ci.yml`, `.gitlab/ci/{app,stores,tasks}.yml` |
| Store-Uploads | `fastlane/Fastfile`, `Gemfile` |
| Admin-Pipeline | `.gitlab-ci.yml` im Admin-Repo |
| Repos kopieren | `deploy/gitlab/move-repos.sh` |
| Linux-Runner | `deploy/gitlab/runner/docker-compose.yml` |

## Ablauf im Alltag

| Auslöser | Was passiert |
| --- | --- |
| Merge Request | Flutter-Analyse + Tests, Web-Build (App); Typecheck, Lint, Build (Admin) |
| Merge/Push auf `main` | Web-App + Übersetzungs-Panel bzw. Admin per rsync auf den VPS |
| Tag `vX.Y.Z` | Android → Play **internal**, iOS → **TestFlight** (automatisch) |
| Klick auf `android:production` | dieselbe Version in Play **production** (`PLAY_ROLLOUT=0.2` → 20 % gestaffelt) |
| Klick auf `ios:submit-review` | TestFlight-Build zur **App-Store-Prüfung** (`RELEASE_NOTES`, `IOS_AUTO_RELEASE=true`) |
| Pipeline-Zeitpläne | Hintergrund-Aufgaben (Audio, Untertitel, Bilder) |

Release machen:

```bash
# pubspec.yaml: version: 2.3.8+72   (Build-Nummer darf gleich bleiben, CI zählt selbst hoch)
git commit -am "release: 2.3.8" && git tag v2.3.8 && git push && git push --tags
```

Der Tag muss zur `version:` in `pubspec.yaml` passen, sonst bricht `release:verify` ab.
Build-Nummern: Android = höchster versionCode in Play + 1, iOS = höchste TestFlight-Nummer + 1
(jeweils mindestens die Nummer aus `pubspec.yaml`).
Testbuild ohne Tag: *Build → Pipelines → Run pipeline* auf `main` mit `STORE_BUILD=true`
(andere Branches sehen die geschützten Store-Variablen nicht).

## 1. Repos umziehen

```bash
export GITLAB_TOKEN=glpat-…   # GitLab → Preferences → Access tokens, Scope "api"
bash deploy/gitlab/move-repos.sh
```

Legt die private Gruppe `jugendkompass` mit den Projekten `app` und `admin` an und kopiert
alle Branches und Tags (ohne Pipelines auszulösen). Alternativ geht der GitLab-Import
„Import project → GitHub“, der auch Issues/PRs übernimmt.

Danach in beiden GitLab-Projekten:

- *Settings → Repository → Protected tags*: `v*` schützen (nur Maintainer).
  Die Store-Variablen sind „protected“ und stehen damit nur auf `main` und `v*`-Tags zur Verfügung.
- *Settings → CI/CD → General pipelines → Timeout*: **6h** (Hintergrund-Aufgaben laufen bis 5,5 h).
- Lokale Klone umstellen: `git remote set-url origin git@gitlab.bethaus-speyer.de:jugendkompass/app.git`

## 2. Runner

### Linux-Runner (alle Jobs außer iOS)

Docker-Executor, **ohne Tag** und mit „Run untagged jobs“. Flutter-, Android-,
Web- und Admin-Builds sowie die Hintergrund-Aufgaben laufen hier. Whisper (Untertitel)
und die KI-Stimmen brauchen viel CPU – mindestens 4 Kerne / 8 GB RAM, besser mehr.

```bash
mkdir -p /docker/gitlab-runner && cd /docker/gitlab-runner
cp <app-repo>/deploy/gitlab/runner/docker-compose.yml .
docker compose up -d
# Token: GitLab → Gruppe jugendkompass → Build → Runners → New group runner
#        (Linux, "Run untagged jobs" an) → Token kopieren
docker exec -it jk-gitlab-runner gitlab-runner register \
  --url https://gitlab.bethaus-speyer.de --token glrt-… \
  --executor docker --docker-image alpine:3.22 --name jk-linux
```

In `config/config.toml` danach `concurrent = 4` setzen (gleichzeitige Jobs).

### macOS-Runner (iOS)

iOS-Builds brauchen Xcode, also einen Mac. Einmalig auf dem Mac:

```bash
xcode-select --install                 # plus aktuelles Xcode aus dem App Store, einmal starten
brew install gitlab-runner ruby cocoapods
echo 'export PATH="/opt/homebrew/opt/ruby/bin:$PATH"' >> ~/.zprofile
# Token: Gruppe → Build → Runners → New group runner, Plattform macOS, Tag "macos",
#        "Run untagged jobs" AUS
gitlab-runner register --url https://gitlab.bethaus-speyer.de --token glrt-… \
  --executor shell --name jk-mac
brew services start gitlab-runner
```

Flutter installiert die Pipeline selbst (Version aus `FLUTTER_VERSION` nach `~/.flutter-sdks`).
Signieren: Xcode holt Zertifikat und Profile über den App-Store-Connect-Schlüssel
(„cloud-managed signing“) – keine .p12-Dateien oder Profile auf dem Mac nötig.
Der Mac muss nur laufen, wenn ein Release-Tag gebaut wird; der Job wartet sonst in der Warteschlange.

## 3. CI/CD-Variablen

*Gruppe jugendkompass → Settings → CI/CD → Variables* (gelten für App und Admin).
„Masked“ wo möglich, Store-Zugänge zusätzlich „Protected“.

| Name | Typ | Inhalt | Wofür |
| --- | --- | --- | --- |
| `VPS_SSH_HOST` | Variable | Hostname/IP | Web/Admin-Deploy |
| `VPS_SSH_USER` | Variable | Deploy-Benutzer | Web/Admin-Deploy |
| `VPS_SSH_KEY` | **File** | privater Deploy-Schlüssel (wie bei GitHub) | Web/Admin-Deploy |
| `VPS_SSH_KNOWN_HOSTS` | **File** | `ssh-keyscan -p PORT HOST` | Web/Admin-Deploy |
| `VPS_SSH_PORT` | Variable | nur falls nicht 22 | Web/Admin-Deploy |
| `SUPABASE_SERVICE_ROLE_KEY` | Variable, masked | Service-Role-Key (VPS = derselbe wie Cloud) | Hintergrund-Aufgaben |
| `GEMINI_API_KEY` | Variable, masked | Google AI Studio | Bildübersetzung |
| `ANDROID_KEYSTORE_BASE64` | Variable, masked, protected | `base64 -i upload-keystore.jks` (eine Zeile) | Android-Signatur |
| `ANDROID_KEYSTORE_PASSWORD` | Variable, masked, protected | | Android-Signatur |
| `ANDROID_KEY_ALIAS` | Variable, protected | | Android-Signatur |
| `ANDROID_KEY_PASSWORD` | Variable, masked, protected | | Android-Signatur |
| `PLAY_SERVICE_ACCOUNT_JSON` | **File**, protected | JSON des Google-Cloud-Service-Accounts | Play-Upload |
| `ASC_KEY_ID` | Variable, protected | App Store Connect → Integrations → Key ID | TestFlight/Review |
| `ASC_ISSUER_ID` | Variable, protected | Issuer ID | TestFlight/Review |
| `ASC_KEY_P8` | **File**, protected | Inhalt der `AuthKey_XXXX.p8` | TestFlight/Review |

Hinweise:
- **Play-Service-Account**: Play Console → *Users and permissions* → Service-Account-E-Mail
  einladen, App `Jugendkompass`, Rechte „Releases verwalten“ (inkl. Production) und
  „App-Informationen ansehen“. Der JSON-Schlüssel kommt aus Google Cloud → IAM → Service Accounts.
- **App-Store-Connect-Schlüssel**: *Users and Access → Integrations → App Store Connect API →
  Team Keys*, Rolle **Admin** (nur damit darf Xcode Verteilungszertifikate selbst anlegen).
  Wer bei GitHub schon `APP_STORE_CONNECT_*` hatte, kann denselben Schlüssel nehmen.
- **Optional pro Lauf**: `PLAY_ROLLOUT`, `RELEASE_NOTES`, `IOS_AUTO_RELEASE` beim manuellen
  Job als Variable mitgeben.

## 4. Hintergrund-Aufgaben (Pipeline-Zeitpläne)

*Projekt app → Build → Pipeline schedules → New schedule*, Ziel-Branch `main`,
Zeitzone Europe/Berlin, je eine Variable `TASK`:

| Beschreibung | Cron | `TASK` |
| --- | --- | --- |
| Englische Audios | `5 * * * *` | `english-audio` |
| Bildtexte übersetzen | `35 * * * *` | `image-translation` |
| Russische Audios | `20 3 * * *` | `russian-audio` |
| Polnische Audios | `50 3 * * *` | `polish-audio` |
| Vers-Bilder | `23 4 * * *` | `verse-images` |
| Video-Untertitel | `40 4 * * *` | `video-subtitles` |

Von Hand: *Build → Pipelines → Run pipeline* mit `TASK=<name>` (z. B. `verse-images` plus `DAYS=90`).
Gleiche Aufgaben laufen nie doppelt (`resource_group`).

## 5. Umschalten und GitHub abschalten

Reihenfolge, damit nichts doppelt läuft:

1. Runner und Variablen einrichten, Repos kopieren (Schritte 1–3).
2. In GitLab einen Testlauf: MR öffnen (Prüfung), `Run pipeline` auf `main` (Web-Deploy),
   `TASK=verse-images` (Hintergrund), `STORE_BUILD=true` (Play internal + TestFlight).
3. **GitHub Actions abschalten** (sonst laufen Zeitpläne doppelt): je Repo
   *Settings → Actions → General → Disable actions*.
4. Zeitpläne in GitLab anlegen (Schritt 4).
5. Server-Quellen umstellen: auf dem VPS in `/docker/jugendkompass-src`
   `git remote set-url origin git@gitlab.bethaus-speyer.de:jugendkompass/app.git` und den
   öffentlichen Deploy-Key dort unter *app → Settings → Repository → Deploy keys* (nur lesen) eintragen.
6. GitHub-Repos archivieren (*Settings → General → Archive*) oder als Spiegel behalten:
   GitLab *Settings → Repository → Mirroring repositories* → Push-Mirror nach GitHub.
   Nach dem Umzug die alten GitHub-Secrets löschen.

Die alten Workflows unter `.github/workflows/` bleiben bis Schritt 3 im Repo und werden danach entfernt.
