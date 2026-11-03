"""Render the Supabase migration (schema + seeded verse pool).

Usage:
    python3 build_migration.py pool.json ../../supabase/migrations/<file>.sql
"""

import json
import sys
from pathlib import Path


def q(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def main() -> None:
    data = json.load(open(sys.argv[1], encoding="utf-8"))
    pool, row_map = data["pool"], data["row_to_pool"]
    lines = []
    for chunk in range(0, len(pool), 200):
        values = ",\n".join(
            f"  ({i}, {q(p['verse'])}, {q(p['reference'])}, ARRAY[{', '.join(q(r) for r in p['raw_refs'])}]::text[])"
            for i, p in enumerate(pool[chunk:chunk + 200], start=chunk)
        )
        lines.append(f"INSERT INTO _pool_seed (idx, verse, reference, raw_refs) VALUES\n{values};\n")
    items = sorted(row_map.items())
    for chunk in range(0, len(items), 500):
        values = ",\n".join(f"  ({q(rid)}, {idx})" for rid, idx in items[chunk:chunk + 500])
        lines.append(f"INSERT INTO _row_map (row_id, idx) VALUES\n{values};\n")
    template = Path(__file__).with_name("migration_template.sql").read_text(encoding="utf-8")
    out = template.replace("-- @@DATA@@", "\n".join(lines))
    Path(sys.argv[2]).write_text(out, encoding="utf-8")
    print(f"wrote {sys.argv[2]}: {len(pool)} pool verses, {len(row_map)} linked rows")


if __name__ == "__main__":
    main()
