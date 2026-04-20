

## Auswirkungen auf die Flutter-App durch Mehrsprachigkeit

Da die Flutter-App aktuell direkt aus den bestehenden Tabellen liest (posts, impulses, verse_of_the_day, messages, polls, videos, editions, categories), gibt es zwei mögliche Strategien. Empfehlung: **Strategie A (Backward-Compatible)** — die App muss minimal oder gar nicht angepasst werden.

### Strategie A — Backward-Compatible (empfohlen)

**Prinzip:** Bestehende Tabellen/Spalten bleiben unverändert (= Originalsprache DE). Übersetzungen liegen separat in `content_translations`. Die Flutter-App funktioniert ohne Änderung weiter und zeigt DE.

**Was die App tun muss, um EN auszuliefern:**

1. **Neue View `content_translated`** (DB-seitig bereitgestellt):
   - Liefert pro Tabelle dieselben Spalten wie bisher, aber Felder werden via `coalesce(translation.value, original)` ersetzt.
   - Parameter: gewünschte Sprache (z.B. via RPC oder Query-Param).
   
2. **Empfohlene API-Variante: RPC-Funktionen pro Inhaltstyp**, z.B.:
   ```text
   get_posts_localized(lang text)        → returns SETOF posts-shape
   get_impulses_localized(lang text)
   get_verse_of_day_localized(lang text)
   get_messages_localized(lang text)
   get_polls_localized(lang text)        (inkl. options)
   get_videos_localized(lang text)
   get_editions_localized(lang text)
   ```
   - Antwortstruktur **identisch zu den heutigen Tabellen** → Flutter-Modelle bleiben gleich.
   - Fallback `coalesce(t.value, original)` → kein leerer Text bei fehlender Übersetzung.

3. **Was die Flutter-App ändern muss:**
   - Geräte-/User-Sprache erkennen (`Platform.localeName` oder bestehender Locale-Provider).
   - Statt `from('posts').select()` → `rpc('get_posts_localized', { lang: 'en' })`.
   - Wenn `lang == 'de'` → optional weiter direkt aus Tabelle lesen (gleiches Ergebnis).
   - **Keine Änderung** an Modellen, Cache, Push-Notifications nötig.

4. **Push-Notifications** (`notify_new_content`-Trigger):
   - Aktuell wird nur DE versendet. Zur Zwei-Sprachen-Auslieferung: Edge-Function `send-push-notification` erweitern → liest `content_translations` und sendet pro Token in passender Sprache (basierend auf `device_tokens` → neue Spalte `language text default 'de'` hinzufügen, App setzt diese beim Token-Registrieren).

### Strategie B — Breaking (nicht empfohlen)

Übersetzungen direkt in bestehende Tabellen (Spalten `title_en` etc.) → Flutter-Modelle und Queries müssten überall angepasst werden + erzwingt App-Update für alle User.

### Konkrete Änderungen auf Server-Seite (für Strategie A)

| Bereich | Änderung |
|---|---|
| `content_translations` | neue Tabelle (wie im vorherigen Plan beschrieben) |
| RPC-Funktionen | 7 `get_*_localized(lang)` Funktionen mit `coalesce`-Fallback |
| `device_tokens` | neue Spalte `language text default 'de'` |
| Edge Function `send-push-notification` | wählt Übersetzung anhand Token-Sprache |
| `content_feed` View | optional zusätzlich `content_feed_localized(lang)` |

### Konkrete Änderungen auf Flutter-Seite

1. Locale-Erkennung + manueller Sprachumschalter in App-Settings.
2. Repository-Layer: alle `from('<table>').select()` → `rpc('get_<table>_localized', { lang })`.
3. Beim FCM-Token-Registrieren: aktuelle Sprache mitschicken → in `device_tokens.language` speichern; bei Sprachwechsel updaten.
4. Keine UI-Änderung sonst nötig (App-eigene Texte separat via z.B. `flutter_localizations`/`intl` — nicht Teil dieses Plans).

### Migrationsablauf (kompatibel)

```text
Phase 1: Server  → content_translations + RPCs deployen   → App läuft unverändert weiter
Phase 2: Backfill → bestehende Inhalte automatisch nach EN übersetzen
Phase 3: Admin-UI → Status-Badges + manueller "Neu übersetzen"-Button
Phase 4: Flutter → Update mit RPC-Calls + Locale-Switcher veröffentlichen
Phase 5: Push   → device_tokens.language + Edge Function update
```

In jeder Phase bleibt die produktive App lauffähig — keine Breaking Changes.

