# Übersetzungs-Panel (Jugendkompass)

Statische Web-App (kein Build-Schritt) zur Überwachung und Steuerung der automatischen Übersetzungen.

- **Übersicht**: Live-Status (Polling alle 5 s) der Queue `translation_jobs`, Abdeckung je Inhaltskategorie und Sprache
- **Claude-Guthaben**: erkennt „credit balance too low“, Link zum Aufladen, danach alle fehlgeschlagenen Jobs neu starten
- **Jobs**: filtern, Fehler ansehen, einzelne Einträge neu übersetzen (nur Geändertes / komplett neu)
- **Bearbeiten**: Übersetzungen manuell eintragen – pro Beitrag, pro Sprache, pro Feld (deutsches Original daneben, HTML-Vorschau, RTL für Hebräisch). Gespeicherte Felder bekommen `status = 'manual'` und werden vom Worker nie überschrieben; „Automatisch“ hebt das wieder auf und reiht eine neue Claude-Übersetzung ein. Wird das deutsche Original später geändert, markiert der Editor die manuelle Übersetzung zur Prüfung. Benötigt Migration `20261110120000_translation_manual_edit.sql`.
- **Logs**: jeder Statuswechsel (`translation_events`) + Antworten der Edge Function `process-translation-jobs`
- **Audios**: alle Audios mit Status je Sprache. Englisch erzeugt die KI-Stimme automatisch (freies Modell Kokoro, GitHub-Workflow „English Audio (AI voice)“ alle 15 Min.). Kennzahlen, laufende Jobs, Filter (ohne Englisch / wartend / in Arbeit / fehlgeschlagen / übersprungen / fertig), Suche mit mehreren Wörtern (umlaut-unabhängig), Original und jede Sprachversion anhören, KI-Version neu erzeugen, fehlgeschlagene neu starten, eigene Aufnahmen je Sprache hochladen (werden nie von der KI überschrieben). Job-Status in `audio_tts_jobs` (Migration `20261110170000_audio_tts_jobs.sql` auf main).

Login: Supabase-Auth, nur Benutzer mit `public.users.role = 'admin'`. Alle Aktionen laufen über `SECURITY DEFINER`-RPCs (`tp_*`) mit Admin-Prüfung – siehe `supabase/migrations/20261104120000_translation_panel.sql`.

## Deploy

Vercel, Root Directory `translation-panel`, Framework „Other“, kein Build-Command.
Konfiguration in `config.js` (Supabase-URL + öffentlicher anon key).

## Lokal

```bash
npx serve translation-panel
```
