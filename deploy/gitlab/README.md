# Umzug nach GitLab + CI/CD

Ziel: Ein Monorepo `jugendkompass/jugendkompass` auf `gitlab.bethaus-speyer.de` (App im Wurzelordner,
Admin-PWA in `admin/`). GitLab CI ersetzt alle GitHub Actions; jeder Merge auf `develop` oder
`main` erzeugt automatisch Store-Builds.

| Was | Datei |
| --- | --- |
| Pipeline | `.gitlab-ci.yml`, `.gitlab/ci/{app,stores,tasks,admin}.yml` |
| Store-Uploads | `fastlane/Fastfile`, `Gemfile`; iOS: `ios/ci_scripts/ci_post_clone.sh` (Xcode Cloud) |
| Repo kopieren | `deploy/gitlab/move-repos.sh` |
| Linux-Runner | `deploy/gitlab/runner/docker-compose.yml` |

## Ablauf im Alltag

Arbeit läuft über Feature-Branches → Merge Request nach `develop` → Merge Request `develop` → `main`.

| Auslöser | Was passiert |
| --- | --- |
| Merge Request | Flutter-Analyse + Tests, Web-Build; Admin: Typecheck, Lint, Build (jeweils nur bei Änderungen) |
| Merge auf `develop` | Android → Play **internal**, iOS → **TestFlight intern** (Xcode Cloud) |
| Merge auf `main` | Android → Play **Closed Testing** (`alpha`), iOS → **TestFlight extern** (Xcode Cloud); Web-App, Panel und Admin per rsync auf den VPS |
| Klick auf `android:production` (main) | dieselbe Version in Play **production** (`PLAY_ROLLOUT=0.2` → 20 % gestaffelt) |
| Klick auf `ios:submit-review` (main) | neuester TestFlight-Build der Version zur **App-Store-Prüfung** (`RELEASE_NOTES`, `IOS_AUTO_RELEASE=true`) |
| Pipeline-Zeitpläne | Hintergrund-Aufgaben (Audio, Untertitel, Bilder) |

Store-Builds laufen nur, wenn sich App-Code geändert hat (`lib/`, `assets/`, `android/`, `ios/`,
`pubspec.*`, `dotenv`); ein reiner Admin- oder Doku-Merge baut keine App.
Von Hand: *Build → Pipelines → Run pipeline* auf `develop` oder `main`.

**Versionen**: Der Name kommt aus `version:` in `pubspec.yaml`, die Build-Nummer zählt die Pipeline
(Android: höchster versionCode in Play + 1) bzw. Xcode Cloud selbst hoch.
Wichtig: Sobald eine Version im App Store veröffentlicht ist, nimmt Apple keine weiteren Builds
mit derselben Versionsnummer an. Nach jedem Release also auf `develop` die Version erhöhen
(z. B. `2.3.8+72` → `2.3.9+72`).

Der Play-Track für `main` steht in `PLAY_EXTERNAL_TRACK` (`.gitlab-ci.yml`, Standard `alpha` = geschlossener
Test; `beta` = offener Test). In der Play Console muss dieser Track eine Testergruppe haben.

## 1. Repo umziehen

```bash
export GITLAB_TOKEN=glpat-…   # GitLab → Preferences → Access tokens, Scope "api"
bash deploy/gitlab/move-repos.sh
```

Legt die private Gruppe `jugendkompass` mit dem Projekt `jugendkompass` an, kopiert alle Branches
und Tags (ohne Pipelines auszulösen) und legt `develop` an. Das Admin-Repo wird nicht mehr gebraucht:
seine Historie steckt schon in `admin/`.

Danach im GitLab-Projekt:

- *Settings → Repository → Protected branches*: `main` und `develop` schützen (Merge nur per MR,
  Push für niemanden). Die Store-Variablen sind „protected“ und stehen nur auf diesen Branches zur Verfügung.
- *Settings → Repository → Branch defaults*: Standard-Branch `main`; für neue MRs Ziel `develop`
  (*Settings → Merge requests → Default target*).
- *Settings → CI/CD → General pipelines → Timeout*: **6h** (Hintergrund-Aufgaben laufen bis 5,5 h).
- Lokale Klone: `git clone git@gitlab.bethaus-speyer.de:jugendkompass/jugendkompass.git`

## 2. Runner

### Linux-Runner (alle Jobs außer iOS)

Docker-Executor, **ohne Tag** und mit „Run untagged jobs“. Flutter-, Android-,
Web- und Admin-Builds sowie die Hintergrund-Aufgaben laufen hier. Whisper (Untertitel)
und die KI-Stimmen brauchen viel CPU – mindestens 4 Kerne / 8 GB RAM, besser mehr.

```bash
mkdir -p /docker/gitlab-runner && cd /docker/gitlab-runner
cp <repo>/deploy/gitlab/runner/docker-compose.yml .
docker compose up -d
# Token: GitLab → Projekt (oder Gruppe) jugendkompass → Settings → CI/CD → Runners → New runner
#        (Linux, "Run untagged jobs" an) → Token kopieren
docker exec -it jk-gitlab-runner gitlab-runner register \
  --url https://gitlab.bethaus-speyer.de --token glrt-… \
  --executor docker --docker-image alpine:3.22 --name jk-linux
```

In `config/config.toml` danach `concurrent = 4` setzen (gleichzeitige Jobs).

### iOS mit Xcode Cloud (empfohlen)

Apple baut die App auf eigenen Macs; 25 Stunden im Monat sind im Developer-Programm enthalten
(ein Build dauert ca. 15–20 Minuten). Flutter installiert `ios/ci_scripts/ci_post_clone.sh`
(gleiche Version wie `FLUTTER_VERSION` in `.gitlab-ci.yml`).

Einmalig, nachdem das Repo auf GitLab liegt:

1. **GitLab verbinden**: Xcode → Settings → Accounts → „+“ → *GitLab Self-Managed*,
   URL `https://gitlab.bethaus-speyer.de` (Xcode führt durch die Anmeldung per OAuth-App).
2. In Xcode `ios/Runner.xcworkspace` öffnen → *Product → Xcode Cloud → Create Workflow*,
   Produkt „Runner“, Quelle `jugendkompass/jugendkompass`.
3. Zwei Workflows anlegen (beide: Environment Xcode/macOS „Latest Release“,
   *Actions*: **Archive** – iOS, Distribution **App Store Connect**):
   - **Develop**: *Start Conditions* → Branch Changes auf `develop` (Dateien: Auto-cancel an);
     *Post-Actions* → **TestFlight Internal Testing** → interne Gruppe
   - **Main**: *Start Conditions* → Branch Changes auf `main`;
     *Post-Actions* → **TestFlight Internal Testing** und **TestFlight External Testing** → externe Gruppe
     (der erste Build jeder Version geht kurz in Apples Beta-Review)
   - Optional bei beiden unter *Start Conditions → Files and Folders*: nur bei Änderungen in
     `lib/`, `assets/`, `ios/`, `pubspec.yaml`, `pubspec.lock`, `dotenv` starten (spart Build-Stunden)
4. Buildnummer: App Store Connect → App → *Xcode Cloud → Settings → Build Number* →
   „Next Build Number“ auf **72** setzen (höher als die letzte hochgeladene 71).
5. Probelauf: in App Store Connect beim Workflow „Develop“ *Start Build*.

Signieren übernimmt Xcode Cloud selbst (automatisches Signing, Team MXM3YWAKPL inkl. Widget und
Notification-Service). Die Einreichung zur Prüfung startest du danach in GitLab mit `ios:submit-review`
(oder direkt in App Store Connect).

### Alternative: eigener Mac als Runner

Nur falls Xcode Cloud nicht passt. In GitLab die Variable `IOS_BUILDER=gitlab-mac` setzen und
den Xcode-Cloud-Workflow deaktivieren. Einmalig auf dem Mac:

```bash
xcode-select --install                 # plus aktuelles Xcode aus dem App Store, einmal starten
brew install gitlab-runner ruby cocoapods
echo 'export PATH="/opt/homebrew/opt/ruby/bin:$PATH"' >> ~/.zprofile
# Token: Projekt → Settings → CI/CD → Runners → New runner, Plattform macOS, Tag "macos",
#        "Run untagged jobs" AUS
gitlab-runner register --url https://gitlab.bethaus-speyer.de --token glrt-… \
  --executor shell --name jk-mac
brew services start gitlab-runner
```

Der Job `ios:testflight` signiert über den App-Store-Connect-Schlüssel („cloud-managed signing“),
der Mac muss nur laufen, wenn auf `develop`/`main` gemergt wird.

## 3. CI/CD-Variablen

*Projekt jugendkompass → Settings → CI/CD → Variables*.
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
| `ASC_KEY_ID` | Variable, protected | App Store Connect → Integrations → Key ID | Review-Einreichung |
| `ASC_ISSUER_ID` | Variable, protected | Issuer ID | Review-Einreichung |
| `ASC_KEY_P8` | **File**, protected | Inhalt der `AuthKey_XXXX.p8` | Review-Einreichung |

Hinweise:
- **Play-Service-Account**: Play Console → *Users and permissions* → Service-Account-E-Mail
  einladen, App `Jugendkompass`, Rechte „Releases verwalten“ (inkl. Production) und
  „App-Informationen ansehen“. Der JSON-Schlüssel kommt aus Google Cloud → IAM → Service Accounts.
- **App-Store-Connect-Schlüssel**: *Users and Access → Integrations → App Store Connect API →
  Team Keys*, Rolle **App Manager** reicht für die Review-Einreichung (**Admin** nur beim eigenen Mac-Runner,
  damit Xcode Verteilungszertifikate selbst anlegen darf).
  Wer bei GitHub schon `APP_STORE_CONNECT_*` hatte, kann denselben Schlüssel nehmen.
- **Optional pro Lauf**: `PLAY_ROLLOUT`, `RELEASE_NOTES`, `IOS_AUTO_RELEASE` beim manuellen
  Job als Variable mitgeben.

## 4. Hintergrund-Aufgaben (Pipeline-Zeitpläne)

*Build → Pipeline schedules → New schedule*, Ziel-Branch `main`,
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

1. Runner und Variablen einrichten, Repo kopieren (Schritte 1–3).
2. Testlauf in GitLab: MR nach `develop` (Prüfung), Merge → Play internal + Xcode Cloud „Develop“,
   *Run pipeline* mit `TASK=verse-images` (Hintergrund).
3. **GitHub Actions abschalten** (sonst laufen Zeitpläne und Deploys doppelt): in beiden GitHub-Repos
   *Settings → Actions → General → Disable actions*. Vercel- und Lovable-Verknüpfung entfernen.
4. Zeitpläne in GitLab anlegen (Schritt 4).
5. Server-Quellen umstellen: auf dem VPS in `/docker/jugendkompass-src`
   `git remote set-url origin git@gitlab.bethaus-speyer.de:jugendkompass/jugendkompass.git` und den
   öffentlichen Deploy-Key unter *Settings → Repository → Deploy keys* (nur lesen) eintragen.
6. Beide GitHub-Repos archivieren (*Settings → General → Archive*) oder das App-Repo als Spiegel behalten:
   GitLab *Settings → Repository → Mirroring repositories* → Push-Mirror nach GitHub
   (nötig, wenn Claude weiter direkt am Code mitarbeiten soll). Danach die alten GitHub-Secrets löschen.

Die alten Workflows unter `.github/workflows/` bleiben bis Schritt 3 im Repo und werden danach entfernt.
