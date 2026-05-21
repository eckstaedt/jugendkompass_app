## Ziel

Wenn `editions.published_at` erreicht ist, soll genau eine Push-Benachrichtigung pro Ausgabe versendet werden — mit beim Anlegen definiertem Titel/Inhalt, automatisch in alle App-Sprachen übersetzt.

## Datenbank (Migration)

Spalten zur Tabelle `editions` hinzufügen:
- `notification_title text` — Push-Titel (deutsch)
- `notification_body text` — Push-Text (deutsch)
- `notification_sent_at timestamptz` — Zeitpunkt des Versands (NULL = noch nicht gesendet); verhindert Doppelversand

Cron-Job (über `pg_cron` + `pg_net`, alle 1 Minute) ruft eine neue Edge Function `dispatch-edition-pushes` auf.

## Übersetzungen

Wiederverwendung der bestehenden `content_translations`-Tabelle und `translate-content`-Edge-Function. Map für `edition` wird erweitert:
- Neben `title`/`body` werden `notification_title` und `notification_body` als zusätzliche Felder übersetzt.
- Trigger `notify_translate_content` läuft beim Anlegen/Update ohnehin schon → die Push-Texte sind in EN/ES/RU/PL verfügbar, sobald die Ausgabe veröffentlicht ist.

## Edge Functions

**Neu: `dispatch-edition-pushes`** (vom Cron-Job angestoßen)
- Sucht: `editions` mit `published_at <= now()` AND `notification_sent_at IS NULL` AND `notification_title IS NOT NULL`.
- Für jede Ausgabe: setzt zuerst `notification_sent_at = now()` (vor dem Senden, damit Cron-Retries nicht doppelt senden), dann Versand pro Device-Token in dessen Sprache mit Übersetzung aus `content_translations` (Fallback: Originaltext).
- Toggle: `content_notifications`.

**Bestehend: `send-push-notification`** bleibt unverändert für die anderen Tabellen. Edition-Push läuft nicht mehr beim INSERT-Trigger, sondern über den Cron-Dispatcher (sonst würde beim Anlegen — vor dem Release-Datum — sofort gesendet).

## Frontend (`/dashboard/posts/ausgaben`)

Im Formular „Neue Ausgabe" und im Edit-Dialog zwei neue Eingabefelder:
- „Push-Titel" (Input)
- „Push-Text" (Textarea)

Optional anzeigen: Status „Push gesendet am …" wenn `notification_sent_at` gesetzt ist.

Hook `use-editions.ts` um `notification_title` / `notification_body` erweitern (Create + Update).

## Ablauf-Diagramm

```text
Admin legt Ausgabe an
  └─ editions row (published_at in Zukunft, notification_title/body gesetzt)
       └─ translate-content (Trigger) übersetzt title/body/notif_title/notif_body
                                                                     │
Cron (jede Minute)                                                   │
  └─ dispatch-edition-pushes ──── findet Ausgabe mit                ▼
                                  published_at <= now()
                                  AND notification_sent_at IS NULL
       ├─ setzt notification_sent_at = now()
       └─ für jeden Device-Token: FCM in passender Sprache
```

## Manuell vom Nutzer einzurichten

Nach Approval wird über die DB-Insert-Tools (nicht Migration) der Cron-Job mit deinem Service-Role-Key registriert — das passiert automatisch in der Implementierungsphase.

## Hinweise

- Ich lasse `release_date` weg (gibt es nicht mehr) und nutze nur `published_at`.
- Wenn `notification_title` leer ist → keine Push (Ausgabe wird trotzdem regulär veröffentlicht).
- Cron-Granularität: 1 Minute (Standard-`pg_cron`-Minimum).
