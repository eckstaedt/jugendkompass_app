# Vers des Tages – automatische Planung

Der Vers des Tages ist für **10 Jahre im Voraus** in `verse_of_the_day`
eingetragen und wird jede Nacht automatisch fortgeschrieben (pg_cron-Job
`verse-schedule-maintenance`, 02:17 UTC → `maintain_verse_schedule()`), d. h.
es sind immer mindestens 10 Jahre geplant.

## Regeln

* Nur Verse, die **vor 2026** schon einmal Vers des Tages waren
  (Tabelle `verse_pool`, 821 Verse, Schlachter 2000, ohne Übersetzungsangabe).
* Derselbe Vers – verglichen über **Referenz** (auch überlappende Stellen wie
  „Psalm 37,4“ / „Psalm 37,4-5“) **und Text** – kommt
  * höchstens **einmal pro Kalenderjahr** und
  * mit mindestens **365 Tagen Abstand** dran.
  Geprüft wird gegen *alle* Einträge, auch manuell angelegte/geänderte.
* Unter den erlaubten Versen wird der am längsten nicht verwendete gewählt
  (mit etwas Zufall) – im Schnitt kommt ein Vers alle ~2,5 Jahre wieder.

## Bearbeiten

Im Admin-Bereich unter „Vers des Tages“ erscheinen die geplanten Tage und
können wie bisher bearbeitet werden. Regelverstöße zeigt die View
`verse_schedule_conflicts`, eine Prüfung für einen Vers
`select * from check_verse_conflicts('<vers>', '<referenz>', '<datum>');`.
Wird im Admin ein eigenes Bild hochgeladen, wird es automatisch als manuell
markiert und nie überschrieben. Einen Vers aus der künftigen Planung nehmen:
`update verse_pool set is_active = false where reference = '…';`
(bereits geplante Tage bleiben, neue Tage nutzen ihn nicht mehr).

Neue Verse für den Pool: `insert into verse_pool (verse, reference) values ('…', '…');`

## Bilder

`tool/verse_images` + Workflow `.github/workflows/verse-images.yml` erzeugen
täglich die Bilder für die nächsten 45 Tage: echtes Naturfoto (261 von Hand
geprüfte Fotos, nur Natur – keine Menschen, Tiere, Gebäude, Straßen),
jeden Tag anderes Layout, andere Schriftart (dieselben wie im
vers-des-tages-designer), andere Farben. Manuell hochgeladene Bilder werden nie
überschrieben; wird Text/Referenz geändert, wird ein automatisches Bild neu
erzeugt.

Vorschau lokal: `node generate.mjs --preview out/ --input verses.json --from 2026-11-04 --days 14`

## Neu erzeugen der Migration

```bash
# verses.json = Export aller verse_of_the_day-Zeilen (JSON-Array)
python3 build_pool.py verses.json pool.json
python3 build_migration.py pool.json ../../supabase/migrations/20261103120000_verse_of_the_day_schedule.sql
python3 verify_schedule.py dump.tsv   # unabhängige Prüfung eines Plans
```
