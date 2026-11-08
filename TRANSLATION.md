# Übersetzungssystem (v2)

Die App ist komplett mehrsprachig: **de** (Quelle), **en, ru, es, pl, tr, he**.

| Bereich | Wie übersetzt | Wo |
|---|---|---|
| UI-Texte | statisch, im Code | `lib/core/localization/` |
| Inhalte aus der Datenbank | automatisch per Claude (Anthropic API) | `content_translations`, `entity_translations` |
| Bibel-Buchnamen (Leseplan) | statisch | `lib/core/localization/bible_books.dart` |
| Push-Benachrichtigungen | übersetzter Titel aus der DB | `send-push-notification` |

Das alte Gemini-/MyMemory-System wurde vollständig entfernt.

---

## 1. Inhalte aus der Datenbank

### Ablauf

```
Admin speichert Artikel (posts INSERT/UPDATE)
        │  Trigger trg_translate_posts (nur wenn title/body sich ändern)
        ▼
translation_jobs  (pending, revision+1)
        │  kick_translation_worker() → pg_net → sofort
        │  + pg_cron alle 2 Minuten als Sicherheitsnetz
        ▼
Edge Function process-translation-jobs
        │  claim (SKIP LOCKED) → Quelltexte laden → SHA-256 je Feld
        │  nur geänderte/fehlende Felder → Claude (alle Sprachen parallel)
        │  Validierung: alle Segmente vorhanden, HTML-Tags erhalten, Länge plausibel
        ▼
content_translations / entity_translations (source_hash, status='auto')
        ▼
App: ContentLocalizer legt Übersetzungen über die deutschen Datensätze
```

Übersetzt werden:

| Typ | Tabelle | Felder |
|---|---|---|
| post | posts | title, body (HTML) |
| message | messages | title, message |
| impulse | impulses | title, impulse_text |
| video | videos | title, description |
| verse | verse_of_the_day | verse, reference (lokalisierte Bibelstelle) |
| poll | polls + poll_options | question, `option:<id>` |
| edition | editions | name, title, body → `entity_translations` |
| category | categories | name → `entity_translations` |

### Stabilität

- **Änderungen werden neu übersetzt**: jedes Feld speichert `source_hash`; ändert sich der deutsche Text, wird genau dieses Feld neu übersetzt.
- **Keine verlorenen Edits**: Jobs haben eine `revision`. Wird ein Artikel während der Übersetzung erneut geändert, wird der Job nicht als erledigt markiert, sondern erneut verarbeitet.
- **Retries mit Backoff** (1, 2, 4 … 60 min, max. 8 Versuche), hängende Jobs werden nach 10 min wieder freigegeben.
- **Manuelle Korrekturen bleiben**: Zeilen mit `status = 'manual'` werden nie überschrieben.
- **App fällt pro Feld auf Deutsch zurück**, solange noch keine Übersetzung existiert – nie Fehler/Leere.
- Lange Artikel werden an HTML-Absatzgrenzen gesplittet und verlustfrei wieder zusammengesetzt.

### Einmalige Einrichtung (automatisch per GitHub Actions)

Der Workflow `.github/workflows/supabase-deploy.yml` läuft bei jedem Push auf `main`, der etwas unter `supabase/` ändert. Er setzt den Anthropic-Key, deployt die Edge Functions, spielt neue/geänderte Migrationen ein und startet die Übersetzung.

Einmalig drei Repository-Secrets anlegen (GitHub → Settings → Secrets and variables → Actions → *New repository secret*):

| Secret | Woher |
|---|---|
| `SUPABASE_ACCESS_TOKEN` | https://supabase.com/dashboard/account/tokens → *Generate new token* |
| `SUPABASE_DB_URL` | Supabase Dashboard → *Connect* → *Session pooler* → URI kopieren, `[YOUR-PASSWORD]` durch das DB-Passwort ersetzen |
| `ANTHROPIC_API_KEY` | https://console.anthropic.com/settings/keys |

Danach: GitHub → *Actions* → *Supabase Deploy* → *Run workflow* (bzw. läuft automatisch beim nächsten Merge).

Die Migration legt die Vault-Einträge (Projekt-URL + zufälliges Worker-Secret) selbst an und stellt **alle bestehenden Inhalte** in die Warteschlange. Optionale Function-Secrets: `TRANSLATION_MODEL` (Standard `claude-haiku-5-5`, günstigstes Modell; für höhere Qualität z. B. `claude-sonnet-5-5`), `TRANSLATION_EFFORT` (`low`/`medium`/`high`, Standard `medium`).

<details><summary>Manuell ohne GitHub Actions</summary>

```bash
supabase secrets set --project-ref vdcdibvclaulqxfjyzpq ANTHROPIC_API_KEY=sk-ant-...
supabase functions deploy process-translation-jobs --project-ref vdcdibvclaulqxfjyzpq --no-verify-jwt
supabase functions deploy send-push-notification --project-ref vdcdibvclaulqxfjyzpq --no-verify-jwt
```

Dann den Inhalt von `supabase/migrations/20261102000000_translation_system_v2.sql` im SQL-Editor ausführen (nicht `supabase db push` – ältere Migrationen im Ordner sind nicht in der Migrations-Historie).
</details>

### Betrieb

```sql
-- Fortschritt
select * from public.translation_queue_status;

-- Fehlgeschlagene Jobs erneut versuchen (z. B. nach API-Key-Wechsel)
select public.retry_failed_translations();

-- Alles erneut prüfen (nur Geänderte/Fehlende werden übersetzt)
select public.enqueue_translation_backfill();

-- Übersetzung manuell korrigieren und gegen Überschreiben schützen
update public.content_translations
set value = '...', status = 'manual'
where content_id = '<uuid>' and language = 'en' and field_name = 'title';
```

**Neue Sprache hinzufügen:** in `translation_targets` einfügen (`insert into translation_targets values ('fr', true)`), `select public.enqueue_translation_backfill();` ausführen und die Sprache in `AppLanguage` + UI-Übersetzungen ergänzen.

---

## 2. UI-Texte

- `app_translations.dart`: Basis-Maps je Sprache, Zugriff per `context.tr('key')` bzw. `context.tr('key', {'param': 'x'})`.
- `supplement_translations.dart`: ergänzte/neue Keys, je Key **alle** Sprachen.
- `he_translations.dart`: Hebräisch (RTL).
- `string_translator.dart`: Zuordnung deutscher Literale (`translate('…')`) zu Keys.

`test/localization_test.dart` prüft bei jedem `flutter test`, dass jeder in `lib/` verwendete Key in **jeder** Sprache existiert, jedes `translate('…')`-Literal gemappt ist und Platzhalter wie `{day}` in allen Sprachen identisch sind.

Neue UI-Texte: Key in `supplement_translations.dart` mit allen 7 Sprachen anlegen und `context.tr('key')` verwenden – keine zusammengesetzten Satzfragmente, sondern Platzhalter.
