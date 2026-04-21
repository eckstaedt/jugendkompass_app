# Daily Verse Notification Edge Function

Diese Edge Function sendet täglich Vers-des-Tages-Benachrichtigungen an alle registrierten Geräte basierend auf ihrer konfigurierten `notification_hour`.

## Setup

### 1. Deploye die Function

```bash
supabase functions deploy send-daily-verse-notification
```

### 2. Setze die erforderlichen Secrets

Im Supabase Dashboard → Edge Functions → send-daily-verse-notification → Secrets:

- `FCM_PROJECT_ID` = "jugendkompass-46aa7"
- `FCM_SERVICE_ACCOUNT_KEY` = <ganzer JSON-Inhalt des Firebase Service Account Keys>

### 3. Erstelle einen Cron-Job

Die Function muss **stündlich** ausgeführt werden, damit sie Geräte mit unterschiedlichen `notification_hour` Einstellungen erreichen kann.

#### Option A: Supabase Cron Extension (empfohlen)

```sql
-- Installiere pg_cron Extension
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;

-- Erstelle Cron-Job (läuft jede Stunde)
SELECT cron.schedule(
  'send-daily-verse-notifications',
  '0 * * * *', -- jede volle Stunde
  $$
  SELECT net.http_post(
    url := 'https://vdcdibvclaulqxfjyzpq.supabase.co/functions/v1/send-daily-verse-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer <DEIN_SERVICE_ROLE_KEY>'
    ),
    body := '{}'::jsonb
  );
  $$
);
```

#### Option B: Externes Cron Service (z.B. cron-job.org)

Erstelle einen Job, der jede Stunde diese URL aufruft:

```
POST https://vdcdibvclaulqxfjyzpq.supabase.co/functions/v1/send-daily-verse-notification
Authorization: Bearer <DEIN_SERVICE_ROLE_KEY>
```

## Wie es funktioniert

1. Die Function wird **jede Stunde** ausgeführt
2. Sie prüft die aktuelle UTC-Stunde
3. Sie holt alle Geräte, die:
   - `verse_notifications = true` haben
   - Einen `fcm_token` registriert haben
   - `notification_hour` gleich der aktuellen Stunde haben
4. Sie holt den heutigen Vers aus `verse_of_the_day`
5. Sie gruppiert Geräte nach Sprache und sendet lokalisierte Benachrichtigungen

## Hinweis zu Zeitzonen

⚠️ **Wichtig**: Die aktuelle Implementierung geht davon aus, dass alle Geräte in der gleichen Zeitzone sind (UTC).

Für eine produktionsreife Lösung müsste die `device_tokens` Tabelle um ein `timezone` Feld erweitert werden, oder die `notification_hour` müsste als UTC-Zeit gespeichert werden.

## Testen

Du kannst die Function manuell testen:

```bash
curl -X POST \
  'https://vdcdibvclaulqxfjyzpq.supabase.co/functions/v1/send-daily-verse-notification' \
  -H 'Authorization: Bearer <DEIN_SERVICE_ROLE_KEY>' \
  -H 'Content-Type: application/json'
```
