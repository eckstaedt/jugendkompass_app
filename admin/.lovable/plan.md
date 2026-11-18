## Ziel

Im Admin-Dashboard eine neue Seite hinzufügen, auf der Test-Device-Tokens verwaltet und manuell Test-Push-Benachrichtigungen ausgelöst werden können — um die FCM-Pipeline direkt im UI zu prüfen, ohne auf Cron oder echte Events zu warten.

## Datenbank (Migration)

Neue Tabelle `test_push_devices`:
- `id uuid PK`
- `label text NOT NULL` — sprechender Name (z. B. „iPhone Andi")
- `fcm_token text NOT NULL` — FCM-Token des Test-Geräts
- `platform text` — optional: ios/android
- `language text DEFAULT 'de'` — Sprache für Übersetzungs-Lookup
- `created_by uuid`, `created_at timestamptz DEFAULT now()`

RLS: nur Admins (`is_admin(auth.uid())`) können SELECT/INSERT/UPDATE/DELETE.

## Edge Function: `send-test-push` (neu)

Input (POST JSON):
- `device_ids: uuid[]` — Einträge aus `test_push_devices`
- `title: string`, `body: string`
- optional `data: Record<string,string>` für FCM-Datenfeld
- optional `language: string` — überschreibt das in der Tabelle gespeicherte

Ablauf:
1. JWT validieren → `is_admin` prüfen (sonst 403).
2. Tokens aus `test_push_devices` laden.
3. Pro Token: FCM v1 senden (gleiche `getFcmAccessToken`/`sendFcm`-Logik wie `dispatch-edition-pushes`, in eine kleine geteilte Hilfsfunktion innerhalb der Edge Function kopiert — Edge Functions teilen keinen Code).
4. Response: pro Device `{ id, label, ok, status, error? }` zurückgeben.

Keine DB-Schreibvorgänge in andere Tabellen, kein Cron.

## Frontend

Neue Seite `src/pages/dashboard/test-push/index.tsx`:

- **Geräte-Liste** (Tabelle): Label, Token (gekürzt), Sprache, Plattform, Aktionen (Bearbeiten/Löschen).
- **„Gerät hinzufügen"**-Dialog: Label, FCM-Token, Sprache (Select: de/en/es/ru/pl), Plattform.
- **„Test-Push senden"**-Panel:
  - Multi-Select der Geräte (mit „Alle auswählen")
  - Inputs: Push-Titel, Push-Text
  - Button „Senden" → ruft `send-test-push` via `supabase.functions.invoke`.
  - Ergebnis-Anzeige pro Gerät (✅/❌ + Fehler).

Sidebar (`src/components/layouts/Sidebar.tsx`): neuer Eintrag „Test Pushes" unter den bestehenden Tabs.

Hook `src/hooks/use-test-push-devices.ts`:
- `useTestPushDevices()` (list)
- `useCreateTestPushDevice()`, `useUpdateTestPushDevice()`, `useDeleteTestPushDevice()`
- `useSendTestPush()` (invoke der Edge Function)

## Hinweise

- Reine Admin-Funktionalität, deutsch beschriftet.
- Speichert nur FCM-Tokens, die der Admin selbst einträgt — keine automatische Übernahme aus `device_tokens` (bewusst, damit „Test"-Geräte sauber getrennt bleiben).
- `FCM_PROJECT_ID` und `FCM_SERVICE_ACCOUNT_KEY` sind bereits gesetzt — keine neuen Secrets nötig.
