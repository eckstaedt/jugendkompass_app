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

### Einmalige Einrichtung

1. Migration anwenden (`supabase/migrations/20261102000000_translation_system_v2.sql`):

   ```bash
   supabase db push
   ```

   Die Migration entfernt den alten Gemini-Cronjob und alte Trigger, legt Queue/Trigger/Cron an und **stellt automatisch alle bestehenden Inhalte in die Warteschlange**.

2. Secrets setzen (Worker-Secret frei wählen, z. B. `openssl rand -hex 32`):

   ```bash
   supabase secrets set ANTHROPIC_API_KEY=sk-ant-... TRANSLATION_WORKER_SECRET=<geheim>
   ```

   Optional: `TRANSLATION_MODEL` (Standard `claude-opus-5-5`), `TRANSLATION_EFFORT` (`low`/`medium`/`high`, Standard `medium`).

3. Worker deployen (eigene Authentifizierung über das Secret):

   ```bash
   supabase functions deploy process-translation-jobs --no-verify-jwt
   supabase functions deploy send-push-notification
   ```

4. Im SQL-Editor die Vault-Einträge anlegen, damit die Datenbank den Worker aufrufen kann:

   ```sql
   select vault.create_secret('https://vdcdibvclaulqxfjyzpq.supabase.co', 'translation_project_url');
   select vault.create_secret('<gleiches TRANSLATION_WORKER_SECRET>', 'translation_worker_secret');
   ```

5. Backfill anstoßen (oder einfach 2 Minuten auf den Cron warten):

   ```sql
   select public.kick_translation_worker();
   ```

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
