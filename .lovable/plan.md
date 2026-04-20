

## Sprachumschalter im Admin-Bereich

**Ziel:** Admins können in der Sidebar die Vorschau-Sprache umschalten (DE / EN). Beim Wechsel werden Listen und Detail-Ansichten in der gewählten Sprache angezeigt — über die bereits vorhandenen `get_*_localized(lang)` RPCs.

### Implementierung

1. **Globaler Locale-Context** (`src/contexts/PreviewLocaleContext.tsx`)
   - State `previewLang: 'de' | 'en'`, persistiert in `localStorage`
   - Hook `usePreviewLocale()` für Lese-/Schreibzugriff
   - Default: `'de'`
   - Provider in `App.tsx` mounten

2. **Sprachumschalter-UI** (in `Sidebar.tsx`)
   - Kompakter Toggle (DE/EN Pillen-Buttons) im Footer-Bereich neben Theme-Toggle
   - Im collapsed-Modus: globe-Icon mit aktueller Sprache als Badge
   - Beim Klick: `setPreviewLang('en'|'de')` → React-Query invalidiert betroffene Keys

3. **Daten-Hooks anpassen**, damit sie die gewählte Sprache nutzen:
   - `use-posts.ts` → bei `lang === 'en'` via `supabase.rpc('get_posts_localized', { lang })`, sonst direkter Tabellen-Query (bestehendes Verhalten)
   - `use-impulses.ts` → `get_impulses_localized`
   - `use-daily-verses.ts` → `get_verse_of_day_localized`
   - `use-messages.ts` → `get_messages_localized`
   - `use-videos.ts` → `get_videos_localized`
   - `use-polls.ts` → `get_polls_localized` + `get_poll_options_localized`
   - `use-content-feed.ts` → `get_content_feed_localized`
   - `useFetchPosts` (`src/hooks/posts/use-fetch-posts.ts`) → analog
   - Jeder `useQuery`-Key bekommt `lang` als Suffix → automatisches Refetch beim Sprachwechsel

4. **Visueller Hinweis**
   - Wenn `previewLang === 'en'`: dezenter Banner-Badge oben in `DashboardLayout` ("Vorschau: Englisch") → klar erkennbar, dass man Übersetzungen sieht
   - Edit-Dialoge bleiben **immer DE** (bearbeitet wird der Quelltext) → Hinweistext im Dialog, wenn EN-Vorschau aktiv ist

### Bewusst NICHT geändert

- **Admin-UI-Sprache** (Buttons, Labels, Menüs) bleibt deutsch — entspricht der gespeicherten Memory-Regel.
- **Edit-Forms** schreiben weiterhin in die Quelltabellen (DE). Nur die Vorschau in Listen/Tabellen/Detail-Ansichten wechselt.
- Bulk-Imports, Create-Dialoge, Stats-Seiten bleiben unverändert (nur DE-Eingabe sinnvoll).

### Aufwand-Indikator

~10 Dateien geändert, 1 neue Datei (Context). Reine Frontend-Arbeit, keine DB-Migration nötig.

