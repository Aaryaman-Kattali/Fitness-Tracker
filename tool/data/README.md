# Food database source data

Inputs to `tool/build_food_db.py`. Committed deliberately, despite being
600 KB of third-party CSV: a pipeline whose input has vanished is not
reproducible, which is the same failure as the overwritten walk-1 capture
(REQUIREMENTS C-7-1). With these files present the entire asset rebuilds in
one command:

```powershell
py tool/build_food_db.py --indb-recipes tool/data/raw/INDB.csv --write
```

`assets/db/food.sqlite` is **not** committed. It is generated, and it is
generated from what is in this directory.

---

## What is here

| File | Rows | Provides |
|---|---|---|
| `raw/INDB.csv` | 1,014 | Cooked Indian dishes. 82 columns: per-100 g nutrients, then the same nutrients again per serving, plus `servings_unit`. |
| `raw/recipes_servingsize.csv` | 1,014 | `no_of_servings`, `size_of_servings`, `servings_unit`. **Not wired in** — no gram column, and its `servings_unit` is identical to INDB.csv's on all 1,014 rows. |
| `raw/Units.csv` | 345 | Ingredient unit conversions ("1 tbsp cumin = 2.1 g"). **Not wired in** — see NOTES.md. |

Serving weights come from `INDB.csv`'s own `unit_serving_*` columns
(REQUIREMENTS M3-6), not from the other two files.

## Source

- **Indian Nutrient Databank (INDB)**
- `github.com/lindsayjaacks/Indian-Nutrient-Databank-INDB`, also distributed
  via `anuvaad.org.in` — as recorded in `ARCHITECTURE.md` §8, whose n=1,014
  matches the row count parsed here exactly.
- **Retrieved:** 31 August 2026 (file creation timestamps, 11:16–11:18).

> **Formal citation not yet filled in.** The upstream repository's own
> preferred citation has not been read, and inventing an academic reference
> that looks authoritative and is wrong is precisely the failure M3-5 exists
> to prevent. Copy the citation from the upstream README and replace this
> block.

## Encoding

`INDB.csv` is **cp1252, not UTF-8** — seven non-ASCII bytes in the whole file:
one `0xe9` (the é in "éclair") and six `0xa0` non-breaking spaces across three
milkshake rows. The pipeline tries UTF-8 first and falls back, so a
re-exported UTF-8 file will also work and will not be mojibaked.

## What is NOT here

- **IFCT 2017 and IFCT 2004** (Indian Food Composition Tables, ICMR-NIN) are
  **not included**. They are not openly redistributable and must be requested
  from ICMR-NIN directly. The pipeline's `--indb-items` flag is where they
  would go; without it that step reports as skipped rather than silently
  producing a database missing every raw ingredient.
- **Recipe ingredients.** No file here lists ingredients per dish. This is why
  the 38 quarantined rows (M3-8) could not be cross-checked against their
  tempering oil — exporting `recipes.xlsx` from upstream would settle it.
- **USDA FDC generics.** Fetched live via `--usda-ids` with an API key; no ID
  list is built into the script, by M3-5.

## Known data defects

38 of the 1,014 rows fail macro reconciliation and are quarantined rather than
dropped or corrected — kept in `foods`, excluded from the FTS index so they
cannot be searched or logged. Four candidate explanations were tested and none
fits; see REQUIREMENTS M3-8 for the numbers. They are source defects, not
pipeline defects, and they are upstream's to fix.
