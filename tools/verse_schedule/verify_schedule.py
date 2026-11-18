"""Independent check of the planned verses (reads a TSV dump: id, date, reference, verse, auto).

Rule: the same passage (overlapping reference OR identical text) must not
appear twice in one calendar year and not within 364 days.
Only pairs where the LATER row is auto-planned are counted as violations.
"""
import sys
from collections import defaultdict
from datetime import date

from verse_refs import parse_ref, text_key

rows = []
for line in open(sys.argv[1], encoding="utf-8"):
    rid, d, ref, verse, auto = line.rstrip("\n").split("\t")
    rows.append((date.fromisoformat(d), ref, verse, auto == "t", parse_ref(ref), text_key(verse)))
rows.sort(key=lambda r: r[0])

by_text = defaultdict(list)
by_chapter = defaultdict(list)
violations = 0
checked = 0
for d, ref, verse, auto, pref, tk in rows:
    candidates = list(by_text[tk])
    if pref:
        candidates += [r for r in by_chapter[(pref.book, pref.chapter)] if r[4] and r[4].overlaps(pref)]
    if auto:
        checked += 1
        for od, oref, *_ in candidates:
            if (d - od).days <= 364 or od.year == d.year:
                violations += 1
                print(f"VIOLATION {od} {oref}  <->  {d} {ref}  ({(d - od).days} days)")
    row = (d, ref, verse, auto, pref, tk)
    by_text[tk].append(row)
    if pref:
        by_chapter[(pref.book, pref.chapter)].append(row)

auto_rows = [r for r in rows if r[3]]
print(f"auto rows checked: {checked}, violations: {violations}")
print("translation names in auto rows:",
      sum(1 for r in auto_rows if any(w in (r[1] + ' ' + r[2]).lower() for w in ('slt', 'schlachter', 'luther', 'elberfelder'))))
gaps = [(a[0], b[0]) for a, b in zip(auto_rows, auto_rows[1:]) if (b[0] - a[0]).days != 1]
print("gaps in auto plan:", gaps[:5])
