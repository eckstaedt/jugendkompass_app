# Supabase Projektstruktur

**Projekt:** Jugendkompass
**Projekt-ID:** vdcdibvclaulqxfjyzpq

---

## Tabellen

### `users`
| Spalte | Typ | Nullable | Default |
|--------|-----|----------|---------|
| id | uuid | Nein | – |
| email | text | Nein | – |
| firstName | text | Nein | `''` |
| lastName | text | Nein | `''` |
| role | text | Nein | `'user'` |
| created_at | timestamptz | Nein | `now()` |

**RLS:** Admins sehen alle, User nur eigene Daten.

---

### `profiles`
| Spalte | Typ | Nullable | Default |
|--------|-----|----------|---------|
| id | uuid | Nein | `gen_random_uuid()` |
| user_id | uuid | Nein | – |
| name | text | Nein | – |
| created_at | timestamptz | Nein | `now()` |

**RLS:** Jeder User kann nur eigene Daten lesen, erstellen und aktualisieren.

---

### `content`
Zentrale Tabelle für alle Inhaltstypen. Wird als FK von Posts, Impulsen, Versen, Polls und Videos referenziert.

| Spalte | Typ | Nullable | Default |
|--------|-----|----------|---------|
| id | uuid | Nein | `uuid_generate_v4()` |
| content_type | text | Nein | – |
| status | text | Nein | `'draft'` |
| created_at | timestamptz | Ja | `now()` |

**content_type Werte:** `post`, `impulse`, `verse`, `poll`, `video`, `message`

**RLS:** Jeder kann lesen, authentifizierte User können erstellen/aktualisieren.

---

### `content_translations`
Speichert automatische Übersetzungen (Claude) für alle Content-Felder (en, ru, es, pl, tr, he). Deutsch (`de`) ist die Quellsprache und liegt direkt in den Quelltabellen. Details: `TRANSLATION.md`.

| Spalte | Typ | Nullable | Default |
|--------|-----|----------|---------|
| id | uuid | Nein | `gen_random_uuid()` |
| content_id | uuid | Nein | – |
| language | text | Nein | – |
| field_name | text | Nein | – |
| value | text | Nein | – |
| source_hash | text | Ja | – |
| status | text | Nein | `'auto'` |
| created_at | timestamptz | Nein | `now()` |
| updated_at | timestamptz | Nein | `now()` |

**FK:** `content_id` → `content.id`

**Sprachen:** aus `translation_targets` (aktuell `en`, `ru`, `es`, `pl`, `tr`, `he`; DE ist Quellsprache)

**status:** `auto` (vom Worker, wird bei Quelländerung neu übersetzt) oder `manual` (wird nie überschrieben). `source_hash` = SHA-256 des deutschen Quelltexts.

**field_name Beispiele:** `title`, `body`, `impulse_text`, `verse`, `reference`, `question`, `message`, `description`, `option:<uuid>` (für Poll-Optionen)

**Trigger:** `touch_content_translations_updated_at` aktualisiert `updated_at` bei UPDATE.

**RLS:** Jeder kann lesen, nur Admins können erstellen/bearbeiten/löschen.

---

### `entity_translations`
Übersetzungen für Zeilen ohne `content_id` (`edition`, `category`). Spalten: `entity_type`, `entity_id`, `language`, `field_name`, `value`, `source_hash`, `status`. Unique: (entity_type, entity_id, language, field_name).

**RLS:** Jeder kann lesen, nur Admins/Service-Role schreiben.

---

### `translation_jobs` / `translation_targets`
Queue des Übersetzungs-Workers (`pending`/`processing`/`completed`/`failed`, `revision`, Backoff) und aktive Zielsprachen. Monitoring: View `translation_queue_status`.

---

### `device_tokens`
Geräte-Registrierung für Push-Notifications und Sprachpräferenz.

| Spalte | Typ | Nullable | Default |
|--------|-----|----------|---------|
| id | uuid | Nein | `gen_random_uuid()` |
| device_id | text | Nein | – |
| platform | text | Nein | `'ios'` |
| fcm_token | text | Ja | – |
| language | text | Nein | `'de'` |
| verse_notifications | boolean | Nein | `true` |
| content_notifications | boolean | Nein | `true` |
| notification_hour | integer | Nein | `7` |
| notification_minute | integer | Nein | `0` |
| created_at | timestamptz | Nein | `now()` |

**RLS:** Vollzugriff für anonyme und authentifizierte Nutzer (Geräteregistrierung ohne Login).

---

### `app_analytics`
Analytics tracking für App-Installationen und App-Öffnungen.

| Spalte | Typ | Nullable | Default |
|--------|-----|----------|---------|
| id | uuid | Nein | `gen_random_uuid()` |
| device_id | text | Nein | – |
| event_type | text | Nein | – |
| platform | text | Nein | `'unknown'` |
| app_version | text | Ja | – |
| created_at | timestamptz | Nein | `now()` |

**event_type Werte:** `install` (erste App-Installation), `app_open` (App-Öffnung)

**platform Werte:** `ios`, `android`, `web`

**Indizes:** `device_id`, `event_type`, `created_at DESC`

**RLS:** Jeder kann insert (anonyme Analytics), nur Admins können lesen.

**RPC Funktion:** `get_analytics_summary()` liefert aggregierte Analytics-Daten (nur für Admins).

---

### `posts`
| Spalte | Typ | Nullable | Default |
|--------|-----|----------|---------|
| id | uuid | Nein | `uuid_generate_v4()` |
| title | text | Nein | – |
| body | text | Nein | – |
| category_id | uuid | Ja | – |
| edition_id | uuid | Ja | – |
| content_id | uuid | Ja | – |
| audio_id | uuid | Ja | – |
| image_url | text | Ja | – |
| created_at | timestamptz | Nein | `now()` |

**FK:** `category_id` → `categories.id`, `edition_id` → `editions.id`, `content_id` → `content.id`, `audio_id` → `audios.id`

**RLS:** Jeder kann lesen, nur Admins können erstellen/bearbeiten/löschen.

---

### `categories`
| Spalte | Typ | Nullable | Default |
|--------|-----|----------|---------|
| id | uuid | Nein | `uuid_generate_v4()` |
| name | text | Nein | – |
| created_at | timestamptz | Nein | `now()` |

**RLS:** Jeder kann lesen, nur Admins können verwalten.

---

### `editions`
| Spalte | Typ | Nullable | Default |
|--------|-----|----------|---------|
| id | uuid | Nein | `uuid_generate_v4()` |
| name | text | Nein | – |
| title | text | Ja | – |
| body | text | Ja | – |
| image_url | text | Ja | – |
| pdf_url | text | Ja | – |
| published_at | timestamptz | Ja | – |

**RLS:** Jeder kann lesen, nur Admins können verwalten.

---

### `audios`
| Spalte | Typ | Nullable | Default |
|--------|-----|----------|---------|
| id | uuid | Nein | `uuid_generate_v4()` |
| url | text | Nein | – |
| created_at | timestamptz | Nein | `now()` |

**RLS:** Jeder kann lesen, authentifizierte User können CRUD.

---

### `impulses`
| Spalte | Typ | Nullable | Default |
|--------|-----|----------|---------|
| id | uuid | Nein | `uuid_generate_v4()` |
| content_id | uuid | Nein | – |
| title | text | Nein | – |
| date | date | Nein | – |
| impulse_text | text | Nein | – |
| image_url | text | Ja | – |
| created_at | timestamptz | Nein | `now()` |

**FK:** `content_id` → `content.id`

**Trigger:** `BEFORE INSERT` → `handle_impulse_content()` (erstellt automatisch Content-Eintrag)

**RLS:** Admins können alles, jeder kann veröffentlichte Impulse sehen.

---

### `verse_of_the_day`
| Spalte | Typ | Nullable | Default |
|--------|-----|----------|---------|
| id | uuid | Nein | `gen_random_uuid()` |
| content_id | uuid | Nein | – |
| verse | text | Nein | – |
| reference | text | Nein | – |
| date | date | Nein | `CURRENT_DATE` |
| created_at | timestamptz | Nein | `now()` |
| usage_count | integer | Nein | `0` |
| pool_id | bigint | Ja | – |
| auto_scheduled | boolean | Nein | `false` |
| image_source_hash | text | Ja | – |
| text_key / ref_key | text (generated) | Ja | – |

**FK:** `content_id` → `content.id`, `pool_id` → `verse_pool.id`

**Unique:** `date` (genau ein Vers pro Tag)

**Trigger:** `BEFORE INSERT` → `handle_verse_content()` (erstellt automatisch Content-Eintrag), `trg_verse_of_the_day_pool` (verknüpft mit `verse_pool`)

**Automatische Planung:** immer 10 Jahre im Voraus (`schedule_verses_of_the_day`, pg_cron `verse-schedule-maintenance`). Ein Vers max. 1× pro Kalenderjahr und ≥ 365 Tage Abstand. Details: `tool/verse_schedule/README.md`. Bilder: `image_source_hash` gesetzt = automatisch erzeugt (Workflow `verse-images.yml`), `NULL` = manuell.

### `verse_pool`
Alle Verse, die die automatische Planung verwenden darf (Verse vor 2026, je Bibelstelle eine Zeile). Spalten: `id`, `verse`, `reference`, `ref_key`, `text_key`, `alt_ref_keys`, `is_active`, `source`. RLS: nur Admins.

**RLS:** Jeder kann lesen, nur Admins können erstellen/bearbeiten/löschen.

---

### `polls`
| Spalte | Typ | Nullable | Default |
|--------|-----|----------|---------|
| id | uuid | Nein | `gen_random_uuid()` |
| question | text | Nein | – |
| content_id | uuid | Nein | – |
| created_by | uuid | Ja | – |
| is_active | boolean | Ja | `true` |
| expires_at | timestamptz | Ja | – |
| created_at | timestamptz | Ja | `now()` |

**FK:** `content_id` → `content.id`

**RLS:** Jeder kann lesen, nur Admins können CRUD.

---

### `poll_options`
| Spalte | Typ | Nullable | Default |
|--------|-----|----------|---------|
| id | uuid | Nein | `gen_random_uuid()` |
| poll_id | uuid | Ja | – |
| option_text | text | Nein | – |
| votes | integer | Ja | `0` |
| created_at | timestamptz | Nein | `now()` |

**FK:** `poll_id` → `polls.id`

**RLS:** Jeder kann lesen, nur Admins können CRUD.

---

### `poll_votes`
| Spalte | Typ | Nullable | Default |
|--------|-----|----------|---------|
| id | uuid | Nein | `gen_random_uuid()` |
| poll_id | uuid | Ja | – |
| option_id | uuid | Ja | – |
| user_id | uuid | Ja | – |
| created_at | timestamptz | Ja | `now()` |

**FK:** `poll_id` → `polls.id`, `option_id` → `poll_options.id`

**RLS:** User können nur eigene Stimmen sehen, erstellen und aktualisieren.

---

### `messages`
| Spalte | Typ | Nullable | Default |
|--------|-----|----------|---------|
| id | integer | Nein | `nextval(...)` |
| title | text | Ja | – |
| message | text | Nein | – |
| content_id | uuid | Ja | – |
| image_url | text | Ja | – |
| created_by | uuid | Ja | – |
| created_at | timestamptz | Ja | `now()` |

**FK:** `content_id` → `content.id`

**Trigger:** `BEFORE INSERT` → `handle_message_content()` (erstellt automatisch Content-Eintrag)

**RLS:** Admins können alles, jeder kann lesen.

---

### `videos`
| Spalte | Typ | Nullable | Default |
|--------|-----|----------|---------|
| id | integer | Nein | `nextval(...)` |
| title | text | Nein | – |
| description | text | Ja | – |
| url | text | Nein | – |
| image_url | text | Ja | – |
| content_id | uuid | Nein | – |
| user_id | uuid | Ja | – |
| created_at | timestamptz | Ja | `now()` |

**FK:** `content_id` → `content.id`

**Trigger:** `BEFORE INSERT` → `handle_video_content()` (erstellt automatisch Content-Eintrag)

**RLS:** Admins können alles, jeder kann lesen.

---

### `activities`
| Spalte | Typ | Nullable | Default |
|--------|-----|----------|---------|
| id | uuid | Nein | `gen_random_uuid()` |
| user_id | uuid | Nein | – |
| action_type | text | Nein | – |
| entity_type | text | Nein | – |
| entity_id | uuid | Ja | – |
| description | text | Nein | – |
| created_at | timestamptz | Nein | `now()` |

**RLS:** Jeder kann lesen, User können nur eigene Einträge erstellen.

---

### `content_interactions`
| Spalte | Typ | Nullable | Default |
|--------|-----|----------|---------|
| id | uuid | Nein | `gen_random_uuid()` |
| device_id | text | Nein | – |
| content_type | text | Nein | – |
| content_id | text | Nein | – |
| content_title | text | Ja | – |
| language | text | Ja | `'de'` |
| platform | text | Nein | – |
| app_version | text | Ja | – |
| created_at | timestamptz | Nein | `now()` |

**Beschreibung:** Anonymes Tracking von Content-Interaktionen (Klicks/Views). Verwendet `device_id` statt `user_id` für anonyme Nutzer. `language` speichert die App-Sprache beim Aufruf ('de', 'en', etc.).

**RLS:** Jeder kann einfügen, nur Admins können lesen.

---

## Datenbank-Funktionen

### Allgemein
| Funktion | Rückgabe | Beschreibung |
|----------|----------|-------------|
| `is_admin()` / `is_admin(user_id)` | boolean | Prüft Admin-Status |
| `get_current_user_role()` | text | Rolle des aktuellen Users |
| `increment_poll_votes(option_id)` | void | Erhöht Stimmenanzahl einer Poll-Option |
| `increment_verse_usage(verse_id)` | void | Erhöht `usage_count` (Teilen/Speichern) für einen Vers |
| `get_vers_des_tages_today_json()` | jsonb | Heutiger Vers als JSON |

### Content-Trigger (BEFORE INSERT, erstellen Content-Eintrag)
| Funktion | Tabelle |
|----------|---------|
| `handle_impulse_content()` | impulses |
| `handle_verse_content()` | verse_of_the_day |
| `handle_message_content()` | messages |
| `handle_video_content()` | videos |
| `handle_new_user_role()` | users (Backward-Compat) |

### Übersetzungen (i18n)
| Funktion | Beschreibung |
|----------|-------------|
| `tr(content_id, lang, field, fallback)` | Liefert Übersetzung oder Fallback |
| `get_posts_localized(lang)` | Posts in Zielsprache |
| `get_impulses_localized(lang)` | Impulse in Zielsprache |
| `get_verse_of_day_localized(lang)` | Verse in Zielsprache |
| `get_messages_localized(lang)` | Messages in Zielsprache |
| `get_polls_localized(lang)` | Polls in Zielsprache |
| `get_poll_options_localized(lang)` | Poll-Optionen in Zielsprache |
| `get_videos_localized(lang)` | Videos in Zielsprache |
| `get_editions_localized(lang)` | Ausgaben in Zielsprache |
| `get_categories_localized(lang)` | Kategorien in Zielsprache |
| `touch_content_translations_updated_at()` | Trigger: aktualisiert `updated_at` |

### Notifications
| Funktion | Beschreibung |
|----------|-------------|
| `notify_new_content()` | Sendet Push via Edge Function `send-push-notification` |

### Auto-Translation v2 (siehe `TRANSLATION.md`)
| Funktion | Beschreibung |
|----------|-------------|
| `trg_enqueue_translation()` | Generischer Trigger auf posts, messages, impulses, videos, verse_of_the_day, polls, poll_options, editions, categories |
| `enqueue_translation(type, id)` | Job anlegen/erneuern (revision+1) |
| `claim_translation_jobs(n, worker)` | Jobs atomar übernehmen (SKIP LOCKED) |
| `finish_translation_job(...)` | Abschluss/Retry mit Backoff, Revisionsprüfung |
| `kick_translation_worker()` | Ruft Edge Function `process-translation-jobs` per pg_net auf (Vault-Secrets) |
| `enqueue_translation_backfill()` | Alle Inhalte erneut prüfen/übersetzen |
| `retry_failed_translations()` | Fehlgeschlagene Jobs erneut einreihen |

Die `get_*_localized`-RPCs werden von der App nicht mehr für Übersetzungen genutzt (nur `get_posts_localized('de')` als Datenquelle).

---

## Storage Buckets

Alle Buckets sind **öffentlich** (public).

| Bucket | Verwendung |
|--------|-----------|
| `posts` | Bilder für Beiträge |
| `impulses` | Bilder für Impulse |
| `messages` | Bilder für Nachrichten |
| `videos` | Video-Dateien |
| `audios` | Audio-Dateien |
| `Ausgaben` | Ausgaben-bezogene Dateien |
| `pdf` | PDF-Dateien |
| `pdfs` | PDF-Dateien (alternativ) |
| `storys` | Story-Dateien |
| `misc` | Sonstige Dateien |

---

## Edge Functions

| Funktion | JWT-Verifizierung | Beschreibung |
|----------|-------------------|-------------|
| `delete-user` | Ja | Löscht einen User (nur Admins) |
| `send-push-notification` | Nein | Sendet Push-Benachrichtigungen via FCM |
| `process-translation-jobs` | Nein (eigenes Secret `x-translation-secret`) | Übersetzungs-Worker (Claude), verarbeitet `translation_jobs` |

---

## Unterstützte Sprachen

- **Quellsprache:** `de` (Deutsch) – direkt in Quelltabellen
- **Übersetzungen:** `en`, `ru`, `es`, `pl`, `tr`, `he` – automatisch in `content_translations` / `entity_translations`

---

## Enum-Typen

| Enum | Werte |
|------|-------|
| `app_role` | `admin`, `user` |
