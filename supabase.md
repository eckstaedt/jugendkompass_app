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

**HOW_TO_USE** audios sind nur eine ergänzung zu den posts und sollen nicht als einzelne verwendet werden. Immer nur in Kobination mit posts.

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

**FK:** `content_id` → `content.id`

**Trigger:** `BEFORE INSERT` → `handle_verse_content()` (erstellt automatisch Content-Eintrag)

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

## Views

| View | Beschreibung |
|------|-------------|
| `content_feed` | Aggregierter Content-Feed aller Inhaltstypen |

---

## Datenbank-Funktionen

| Funktion | Rückgabe | Beschreibung |
|----------|----------|-------------|
| `is_admin()` | boolean | Prüft ob aktueller User Admin ist |
| `is_admin(user_id)` | boolean | Prüft ob gegebener User Admin ist |
| `get_current_user_role()` | text | Gibt Rolle des aktuellen Users zurück |
| `increment_poll_votes(option_id)` | void | Erhöht Stimmenanzahl einer Poll-Option |
| `get_vers_des_tages_today_json()` | jsonb | Gibt heutigen Vers als JSON zurück |
| `handle_impulse_content()` | trigger | Erstellt Content-Eintrag für neuen Impuls |
| `handle_verse_content()` | trigger | Erstellt Content-Eintrag für neuen Vers |
| `handle_message_content()` | trigger | Erstellt Content-Eintrag für neue Nachricht |
| `handle_video_content()` | trigger | Erstellt Content-Eintrag für neues Video |
| `handle_new_user_role()` | trigger | Backward-Compatibility Trigger für User-Rollen |

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

---

## Enum-Typen

| Enum | Werte |
|------|-------|
| `app_role` | `admin`, `user` |
