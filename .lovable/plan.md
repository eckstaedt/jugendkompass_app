

## Backfill-Lauf: Alle Inhalte nach Englisch übersetzen

Ich rufe die Edge Function `translate-backfill` mit `target_languages: ['en']` auf und zeige am Ende die Erfolgsstatistik (gesamt / erfolgreich / fehlgeschlagen + Fehlerdetails).

### Ablauf

1. Vorab DB-Check: Anzahl Einträge pro `content_type` (`post`, `impulse`, `verse`, `message`, `poll`, `video`) aus `public.content` zählen → grobe Schätzung der Übersetzungsanfragen.
2. `supabase--curl_edge_functions` auf `translate-backfill` mit Body:
   ```json
   { "target_languages": ["en"], "force": false, "delay_ms": 400 }
   ```
   `force: false` → bereits übersetzte und unveränderte Felder werden übersprungen (idempotent, billiger).
3. Ergebnis-JSON parsen und als Tabelle zeigen: total / success / failed + bis zu 10 Fehlerbeispiele.
4. Zusätzlich nachzählen, wie viele Zeilen jetzt in `content_translations` mit `language='en'` existieren.

### Erwartete Kosten

Die Übersetzung läuft über das **Lovable AI Gateway** mit `google/gemini-3-flash-preview` — eines der günstigsten verfügbaren Modelle.

| Posten | Wert |
|---|---|
| Modell | `google/gemini-3-flash-preview` |
| Aufrufe pro Inhalt | 1 Request pro übersetzbarem Feld (z.B. Post = 2: title + body; Verse = 2; Poll = 1 + n Optionen) |
| Token pro Request | je nach Feldlänge (Posts mit HTML-Body am teuersten) |
| Bereits inkludiert | **$1 freies AI-Guthaben pro Monat** je Workspace (bis Anfang 2026) |
| Faustregel Flash-Preview | sehr günstig — typischer Backfill von wenigen hundert Inhalten bleibt meist im Free-Kontingent |

Eine exakte Vorhersage ist ohne Token-Schätzung nicht möglich. Nach dem Lauf melde ich:
- Anzahl tatsächlich übersetzter Felder (übersprungene werden nicht abgerechnet),
- ob das Free-AI-Balance gereicht hat (sonst wären 402-Fehler in `details` zu sehen).

Falls Kosten ein harter Constraint sind: Backfill kann auf einzelne `content_types` begrenzt werden (z.B. erst nur `verse` + `impulse`, dann der Rest) — sag Bescheid, dann passe ich den Aufruf an.

### Rate-Limit-Schutz

`delay_ms: 400` zwischen den Requests vermeidet 429er. Bei großen Mengen kann das mehrere Minuten dauern; die Edge Function läuft synchron bis fertig.

### Technische Hinweise

- Die Funktion `translate-backfill` existiert bereits und ist als `verify_jwt = false` konfiguriert.
- HTML-Inhalte (Posts, Impulse) durchlaufen die Tag-Count-Validierung in `translate-content` — bei Mismatch wird ein strikter Retry ausgeführt.
- Kein Schemawechsel notwendig.

