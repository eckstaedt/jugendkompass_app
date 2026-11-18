"""Build the de-duplicated verse pool from historic verse_of_the_day rows.

Usage:
    python3 build_pool.py verses.json pool.json

`verses.json` is a dump of all verse_of_the_day rows (see README.md).
Only rows dated BEFORE 2026-01-01 become pool candidates. Rows that refer to
the same passage (overlapping reference) or carry the same text are merged
into a single pool entry, so the scheduler can never pick "the same verse"
twice by accident.
"""

from __future__ import annotations

import json
import re
import sys
from collections import defaultdict

from verse_refs import clean_verse, parse_ref, text_key

POOL_CUTOFF = "2026-01-01"
_OLD_SPELLING = re.compile(r"ß(t|te|ten)?\b|daß|muß")


class UnionFind:
    def __init__(self, n: int):
        self.parent = list(range(n))

    def find(self, i: int) -> int:
        while self.parent[i] != i:
            self.parent[i] = self.parent[self.parent[i]]
            i = self.parent[i]
        return i

    def union(self, a: int, b: int) -> None:
        ra, rb = self.find(a), self.find(b)
        if ra != rb:
            self.parent[max(ra, rb)] = min(ra, rb)


def build(rows: list[dict]) -> tuple[list[dict], list[dict]]:
    candidates = []
    rejected = []
    for row in rows:
        if row["date"] >= POOL_CUTOFF:
            continue
        ref = parse_ref(row["reference"])
        text = clean_verse(row["verse"])
        if ref is None or len(text) < 15:
            rejected.append({"date": row["date"], "reference": row["reference"], "verse": row["verse"][:80]})
            continue
        candidates.append({"row": row, "ref": ref, "text": text, "key": text_key(text)})

    uf = UnionFind(len(candidates))
    by_key: dict[str, int] = {}
    by_chapter: dict[tuple[str, int], list[int]] = defaultdict(list)
    for i, c in enumerate(candidates):
        if c["key"] in by_key:
            uf.union(i, by_key[c["key"]])
        else:
            by_key[c["key"]] = i
        chapter = (c["ref"].book, c["ref"].chapter)
        for j in by_chapter[chapter]:
            if c["ref"].overlaps(candidates[j]["ref"]):
                uf.union(i, j)
        by_chapter[chapter].append(i)

    clusters: dict[int, list[dict]] = defaultdict(list)
    for i, c in enumerate(candidates):
        clusters[uf.find(i)].append(c)

    pool = []
    for members in clusters.values():
        # Prefer modern spelling, then the most recent historic version.
        best = sorted(members, key=lambda c: c["row"]["date"], reverse=True)
        best.sort(key=lambda c: bool(_OLD_SPELLING.search(c["row"]["verse"])))
        chosen = best[0]
        pool.append(
            {
                "reference": chosen["ref"].display,
                "verse": chosen["text"],
                "source_verse_id": chosen["row"]["id"],
                "source_content_id": chosen["row"]["content_id"],
                "historic_dates": sorted(m["row"]["date"] for m in members),
                "variants": sorted({m["ref"].display for m in members}),
                "raw_refs": sorted({m["row"]["reference"] for m in members}),
                "_members": members,
            }
        )
    pool.sort(key=lambda p: p["historic_dates"][0])

    # Map EVERY existing row (also 2026+) to its pool entry: overlapping
    # reference or identical text -> same verse.
    row_to_pool: dict[str, int] = {}
    for idx, entry in enumerate(pool):
        for m in entry.pop("_members"):
            row_to_pool[m["row"]["id"]] = idx
    for row in rows:
        if row["id"] in row_to_pool:
            continue
        ref = parse_ref(row["reference"])
        key = text_key(row["verse"])
        for idx, entry in enumerate(pool):
            if key == text_key(entry["verse"]) or (
                ref and any(ref.overlaps(r) for r in (parse_ref(v) for v in entry["variants"]) if r)
            ):
                row_to_pool[row["id"]] = idx
                break
    return pool, rejected, row_to_pool


def main() -> None:
    rows = json.load(open(sys.argv[1], encoding="utf-8"))
    pool, rejected, row_to_pool = build(rows)
    json.dump({"pool": pool, "row_to_pool": row_to_pool},
              open(sys.argv[2], "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print(f"pool entries: {len(pool)}  (rejected rows: {len(rejected)})  mapped rows: {len(row_to_pool)}/{len(rows)}")
    for r in rejected:
        print("  rejected:", r)


if __name__ == "__main__":
    main()
