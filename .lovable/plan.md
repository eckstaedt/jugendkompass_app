
# Polls für anonyme Nutzer (Backend-only)

Die normalen Anwender stimmen über die **native Flutter-App** ab, nicht über dieses Admin-Dashboard. Daher sind in diesem Repo nur **Backend-/DB-Änderungen** nötig — keine UI-Anpassungen für anonyme User.

Identifier auf beiden Plattformen: **Supabase Anonymous Auth**. Die Flutter-App ruft `signInAnonymously()` auf und bekommt eine persistente `auth.uid()` (löst sowohl Web als auch Native sauber).

## 1. Supabase Anonymous Auth aktivieren

Einmaliger manueller Schritt im Supabase Dashboard: Auth → Providers → **Anonymous Sign-ins** aktivieren. Link liefere ich nach Plan-Bestätigung. Die Flutter-App muss dann `signInAnonymously()` aufrufen — das ist Arbeit im Flutter-Repo, nicht hier.

## 2. Datenbank-Migration

- **Daten zurücksetzen**:
  - Alle Zeilen aus `poll_votes` löschen.
  - `poll_options.votes` auf 0 setzen.
- **`poll_votes` Struktur**:
  - Unique-Constraint `(poll_id, user_id)` → ermöglicht Upsert / "Stimme ändern".
  - `user_id` auf `NOT NULL` setzen.
- **RLS auf `poll_votes`** neu:
  - SELECT: `auth.uid() = user_id` (eigene Stimme sichtbar).
  - INSERT: `auth.uid() = user_id` — greift sowohl für eingeloggte Admins als auch für anonyme Flutter-User.
  - UPDATE: `auth.uid() = user_id` (Stimme ändern).
- **Vote-Counting via Trigger** auf `poll_votes` (`SECURITY DEFINER`):
  - INSERT → +1 auf `option_id`.
  - UPDATE → -1 auf alter, +1 auf neuer `option_id`.
  - DELETE → -1 (für Konsistenz, auch wenn aktuell kein DELETE-Pfad).
- RPC `increment_poll_votes` wird obsolet (kann bleiben, nicht mehr verwendet).

## 3. Admin-Dashboard (dieses Repo)

- Keine UI-Änderung nötig.
- **Auth-Flow nicht anfassen**: `AuthContext` bleibt unverändert, da Admins sich weiterhin nur per Email/Passwort einloggen.
- `useVote`-Hook in `use-polls.ts` ist hier ungenutzt für anonyme Flows — kann optional auf `upsert` umgestellt werden, ist aber kein Muss (Flutter-App implementiert das eigenständig).

## 4. Memory-Update

Nach Build-Modus speichere ich in der Project Memory, dass es eine separate **native Flutter-App** für Endnutzer gibt, damit künftige Änderungen das berücksichtigen.

## Manueller Schritt für dich

1. Anonymous Sign-ins im Supabase Dashboard aktivieren.
2. In der Flutter-App `supabase.auth.signInAnonymously()` beim Start aufrufen.
