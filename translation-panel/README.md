# Übersetzungs-Panel (Jugendkompass)

Statische Web-App (kein Build-Schritt) zur Überwachung und Steuerung der automatischen Übersetzungen.

- **Übersicht**: Live-Status (Polling alle 5 s) der Queue `translation_jobs`, Abdeckung je Inhaltskategorie und Sprache
- **Claude-Guthaben**: erkennt „credit balance too low“, Link zum Aufladen, danach alle fehlgeschlagenen Jobs neu starten
- **Jobs**: filtern, Fehler ansehen, einzelne Einträge neu übersetzen (nur Geändertes / komplett neu)
- **Logs**: jeder Statuswechsel (`translation_events`) + Antworten der Edge Function `process-translation-jobs`
- **Audios**: übersetzte Audio-Datei je Sprache zu einem Original-Audio hochladen (`audio_translations`, Bucket `audios/translations/…`). Die App spielt bei eingestellter Sprache automatisch die passende Datei (`ContentLocalizer.localizeAudioUrls`), sonst das deutsche Original.

Login: Supabase-Auth, nur Benutzer mit `public.users.role = 'admin'`. Alle Aktionen laufen über `SECURITY DEFINER`-RPCs (`tp_*`) mit Admin-Prüfung – siehe `supabase/migrations/20261104120000_translation_panel.sql`.

## Deploy

Vercel, Root Directory `translation-panel`, Framework „Other“, kein Build-Command.
Konfiguration in `config.js` (Supabase-URL + öffentlicher anon key).

## Lokal

```bash
npx serve translation-panel
```
