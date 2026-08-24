# Bible Reading Plan Notification Edge Function

Sendet täglich um 06:30 Uhr (lokale Gerätezeit) eine motivierende Erinnerung
für den "Bibel in 365 Tagen" Leseplan — aber **nur** an Geräte, die den Plan
über den "Bibelleseplan starten 🚀" Button auch tatsächlich gestartet haben
(`bible_plan_started = true` in `device_tokens`).

Ein Tap auf die Push-Nachricht öffnet die App direkt im Bibelleseplan, auf der
aktuellen Tages-Seite (via `contentType: "bible_plan"` im Data-Payload).

## Setup

### 1. Migration anwenden

```bash
supabase db push
```

Fügt `user_name` und `bible_plan_started` zur `device_tokens` Tabelle hinzu
(siehe `supabase/migrations/20260824000000_add_bible_plan_fields_to_device_tokens.sql`).

### 2. Deploye die Function

```bash
supabase functions deploy send-bible-plan-notification
```

### 3. Setze die erforderlichen Secrets

Im Supabase Dashboard → Edge Functions → send-bible-plan-notification → Secrets:

- `FCM_PRIVATE_KEY` = <Private Key aus dem Firebase Service Account JSON>

### 4. Erstelle einen Cron-Job

Die Function muss **stündlich um Minute 30** ausgeführt werden, damit sie
Geräte in unterschiedlichen Zeitzonen erreicht, sobald es dort 06:30 Uhr ist.

```sql
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;

SELECT cron.schedule(
  'send-bible-plan-notifications',
  '30 * * * *', -- jede Stunde zur Minute 30
  $$
  SELECT net.http_post(
    url := 'https://vdcdibvclaulqxfjyzpq.supabase.co/functions/v1/send-bible-plan-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer <DEIN_SERVICE_ROLE_KEY>'
    ),
    body := '{}'::jsonb
  );
  $$
);
```

## Wie es funktioniert

1. Holt alle Geräte mit `bible_plan_started = true` und gesetztem `fcm_token`.
2. Filtert auf Geräte, deren lokale Uhrzeit (basierend auf `timezone`,
   Standard `Europe/Berlin`) aktuell **6 Uhr** ist.
3. Wählt für jedes Gerät zufällig eine von 50 motivierenden deutschen
   Nachrichten aus ("Dein Bibelleseplan" als Titel). Ist ein `user_name`
   gespeichert, wird eine von 20 personalisierten Vorlagen mit Namen
   verwendet, sonst eine von 30 generischen.
4. Sendet die Push via FCM mit `data: { contentType: "bible_plan" }`, damit
   `DeepLinkService` beim Antippen direkt zum Bibelleseplan (aktueller Tag)
   navigiert.

## Testen

```bash
curl -X POST \
  'https://vdcdibvclaulqxfjyzpq.supabase.co/functions/v1/send-bible-plan-notification' \
  -H 'Authorization: Bearer <DEIN_SERVICE_ROLE_KEY>' \
  -H 'Content-Type: application/json'
```
