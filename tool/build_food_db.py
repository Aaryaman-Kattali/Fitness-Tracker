#!/usr/bin/env python3
"""Build assets/db/food.sqlite from the INDB, IFCT and USDA sources.

Run once on Windows:

    py tool/build_food_db.py --indb-recipes recipes.csv --indb-items items.csv

It prints a validation report and STOPS. Nothing is written until --write is
passed, and --write refuses to run while any error-level check is failing.
That ordering is the point of the script: a food database is logged against
for months before anybody notices a bad row, so the report is the product and
the file is an afterthought.

Standard library only, deliberately. The sources ship as .xlsx and reading
those would mean openpyxl; exporting a sheet to CSV is one step in Excel and
costs this repo no dependency at all. .xlsx input is refused with that
instruction rather than half-supported.

WHAT IS NOT HERE, and is not hidden:

* The real INDB column names. The repository documents the variable names for
  the ICMR-NIN IFCT sheet exactly (see IFCT_COLUMNS) and does NOT document
  them for INDB.xlsx, recipes.xlsx or recipes_servingsize.xlsx. Those are
  guessed nowhere: unrecognised headers abort with the headers actually found
  and the aliases tried, so the mapping is corrected in one place, once.
* A list of USDA FDC IDs. Step 3 wants "~200 common generics" and inventing
  200 identifiers would produce a file that looks authoritative and is not.
  Pass --usda-ids with a real list; without it the step reports as skipped.
"""

from __future__ import annotations

import argparse
import csv
import io
import json
import math
import os
import re
import sqlite3
import sys
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass, field
from pathlib import Path

# ---------------------------------------------------------------------------
# Source columns
# ---------------------------------------------------------------------------

# Verified: the INDB repository's README names these exactly, as the variable
# names its Stata code requires. Anything below that is NOT from the README is
# marked as a guess and behaves like one.
IFCT_COLUMNS = {
    "food_code",
    "food_name",
    "energy_kcal",
    "carb_g",
    "protein_g",
    "fat_g",
    "freesugar_g",
    "fibre_g",
    "sfa_mg",
    "sodium_mg",
}

# Candidate header spellings per logical field, tried in order, compared after
# normalisation. The INDB repository still does not document these, but the
# file is now in the repo and its 82 headers were read directly — the spellings
# below are what INDB.csv actually carries, not guesses. If none match, the run
# aborts and prints what it saw; it never falls back to a positional guess.
COLUMN_ALIASES: dict[str, tuple[str, ...]] = {
    "code": ("food_code", "recipe_code", "code", "id"),
    "name": ("food_name", "recipe_name", "name", "dish_name"),
    "kcal": ("energy_kcal", "energy_kcal_100g", "kcal", "energy"),
    "protein": ("protein_g", "protein", "protein_g_100g"),
    "carbs": ("carb_g", "carbohydrate_g", "carbs", "carb"),
    "fat": ("fat_g", "fat", "total_fat_g"),
    "fibre": ("fibre_g", "fiber_g", "fibre", "fiber"),
    "sugar": ("freesugar_g", "sugar_g", "sugars_g", "free_sugar_g"),
    "satfat": ("sfa_mg", "satfat_mg", "saturated_fat_mg"),
    "sodium": ("sodium_mg", "na_mg", "sodium"),
    "serving_g": ("servingsize_g", "serving_size_g", "serving_g", "serving"),
    # Verified present in INDB.csv (columns 43-82): the same nutrients again,
    # per serving rather than per 100 g. See serving_grams below.
    "serving_unit": ("servings_unit", "serving_unit", "unit"),
    "serving_kcal": ("unit_serving_energy_kcal", "serving_energy_kcal"),
    "serving_carbs": ("unit_serving_carb_g", "serving_carb_g"),
    "serving_protein": ("unit_serving_protein_g", "serving_protein_g"),
    "serving_fat": ("unit_serving_fat_g", "serving_fat_g"),
}

REQUIRED_FIELDS = ("name", "kcal", "protein", "carbs", "fat")

# ---------------------------------------------------------------------------
# Household servings — ARCHITECTURE.md section 5, verbatim
# ---------------------------------------------------------------------------

# Matched against a food's normalised name by substring. Order matters: the
# first pattern that matches wins, so the more specific rows come first.
#
# Nobody weighs 150 g of dal, and gram-only entry is the single biggest reason
# food logging gets abandoned. A food that is eaten daily and has no serving
# row is a real defect, which is why UNSERVED_STAPLES below is an error-level
# check rather than a note.
SERVING_RULES: tuple[tuple[str, str, float, bool], ...] = (
    # (name substring, label, grams, is_default)
    ("chapati", "1 medium chapati", 35.0, True),
    ("chapati", "1 large chapati", 50.0, False),
    ("paratha", "1 roti-sized paratha", 60.0, True),
    ("idli", "1 idli", 40.0, True),
    ("dosa", "1 medium dosa", 85.0, True),
    ("curd", "1 katori curd", 120.0, True),
    ("milk", "1 glass milk (250 ml)", 250.0, True),
    ("egg", "1 large egg", 50.0, True),
    ("dal", "1 katori dal (cooked)", 150.0, True),
    ("rice", "1 katori rice (cooked)", 150.0, True),
    ("sabzi", "1 katori sabzi", 100.0, True),
)

# Foods that must end up with at least one serving row. Not a style
# preference: these are the daily ones, and a gram-only row for any of them is
# the failure mode section 5 exists to prevent.
UNSERVED_STAPLES = ("chapati", "rice", "dal", "curd", "milk", "idli")

# The katori is the unit that varies most between households, so every katori
# row is stored at this reference size and scaled at read time by the
# calibration setting (ARCHITECTURE.md section 5, requirement M3-2).
KATORI_REFERENCE_G = 150.0

# INDB never says 'katori'. It says 'bowl' (269 rows), 'small bowl' (15) and
# 'curry bowl' (7) — the word does not appear once in any of the three source
# files. M3-7: these units emit two rows, the katori one for M3-2 to calibrate
# and the source's own word for provenance.
KATORI_UNITS = {
    "bowl": "1 katori",
    "curry bowl": "1 katori",
    "small bowl": "1 small katori",
}

# The per-serving columns are rounded independently of the per-100 g ones, so
# the four macros disagree slightly about the serving weight. Under this they
# are averaged; over it the row is reported rather than averaged into a
# plausible-looking wrong number.
#
# DERIVED FROM THE MEASURED DISTRIBUTION, NOT AGREED IN ADVANCE. Same standing
# as accelerationNoiseMps2 = 0.035: defensible from the data, and dangerous
# only if a later reader assumes it was principled. What was measured on
# INDB.csv, 31 Aug 2026: 932 rows yield a serving weight, 880 of them agree
# across kcal/carb/protein/fat/sodium to within 1%, and the spread has a long
# thin tail rather than a second cluster — so there is no natural cut point in
# the data and 10% is a judgement about which end of the tail to keep.
#
# It drops exactly these 10 rows, all drinks and chutneys, where the serving
# is small or the dilution large enough that rounding dominates:
#
#   Iced tea (30%) · Fruit Punch with squashes (24%) · Tamarind chutney (20%)
#   Saunth chutney with ginger (18%) · Raw mango drink / Aam panna (14%)
#   Lemonade (14%) · Saunth chutney with tamarind (13%) · Mintade (13%)
#   Fruit Punch with fresh juices (10%) · Summer cooler (10%)
#
# Measured sensitivity: at 0.35 all ten come back (945 served), at 0.10 ten go
# (935), at 0.05 fifteen go (930). The ten are named so that changing this
# number is a decision about known rows rather than about an abstraction.
SERVING_AGREEMENT_TOLERANCE = 0.10

# ---------------------------------------------------------------------------
# Validation thresholds
# ---------------------------------------------------------------------------

# Atwater: 4 kcal/g protein, 4 kcal/g carbohydrate, 9 kcal/g fat.
KCAL_PER_G_PROTEIN = 4.0
KCAL_PER_G_CARB = 4.0
KCAL_PER_G_FAT = 9.0

# How far the reconstructed energy may sit from the stated energy.
#
# THE CHECK THAT MATTERS. A single unit misparse — kJ read as kcal, or a
# per-serving figure read as per-100 g — produces a food that reads 900 kcal
# per 100 g, and it will be logged once and never questioned. Reconstructing
# the energy from the macros catches it because the two have to be wrong
# together to agree.
#
# 15% is wide on purpose. Fibre carries about 2 kcal/g and most tables count
# it inside carbohydrate, so a high-fibre food reconstructs high by a few per
# cent with nothing wrong; polyols and rounding add more. A tight band would
# fill the report with correct foods and train everyone to skim it.
MACRO_RECONCILIATION_TOLERANCE = 0.15

# Below this, a percentage difference is noise: 4 kcal reconstructed against a
# stated 2 kcal is a 100% error on a cup of black tea.
MACRO_RECONCILIATION_MIN_KCAL = 20.0

# Nothing edible is denser in energy than pure fat, which is 900.
MAX_KCAL_PER_100G = 900.0

# 100 g of a food cannot contain more than 100 g of anything.
MAX_G_PER_100G = 100.0

USDA_ENDPOINT = "https://api.nal.usda.gov/fdc/v1/food/"

# ---------------------------------------------------------------------------
# Model
# ---------------------------------------------------------------------------


@dataclass
class Food:
    """One row of Foods, in the units the schema stores."""

    name: str
    source: str
    is_recipe: bool
    kcal100: float
    protein100: float
    carbs100: float
    fat100: float
    fibre100: float = 0.0
    sugar100: float | None = None
    satfat100: float | None = None
    sodium100: float | None = None
    serving_g: float | None = None
    serving_unit: str = ""  # the source's own word, "" when it published none
    quarantined: bool = False
    origin: str = ""  # file and line, for the report only

    @property
    def normalised_name(self) -> str:
        return normalise(self.name)


@dataclass
class Problem:
    check: str
    food: str
    detail: str
    origin: str


@dataclass
class Report:
    """What the run found. Printed whether or not anything is written."""

    errors: list[Problem] = field(default_factory=list)
    warnings: list[Problem] = field(default_factory=list)
    # M3-8. Neither an error nor a warning: the row is written and flagged,
    # and the flag is what contains it, so these do not hold the gate shut.
    quarantined: list[Problem] = field(default_factory=list)
    unserved: list[Problem] = field(default_factory=list)
    counts: dict[str, int] = field(default_factory=dict)
    skipped: list[str] = field(default_factory=list)

    @property
    def ok(self) -> bool:
        return not self.errors


def normalise(name: str) -> str:
    """Casefold, strip punctuation, collapse whitespace.

    Used for deduplication and for serving matching. Deliberately dumb: a
    stemmer or a fuzzy match would merge 'dal fry' with 'dal makhani', which
    are different foods with different fat contents.
    """
    return re.sub(r"[^a-z0-9]+", " ", name.casefold()).strip()


# ---------------------------------------------------------------------------
# Step 1 and 2 — parse INDB / IFCT
# ---------------------------------------------------------------------------


def resolve_columns(headers: list[str], path: Path) -> dict[str, str]:
    """Map logical field names onto this file's actual headers.

    Aborts on an unmapped required field rather than guessing. The INDB sheets
    do not publish their column names, so the aliases above are a starting
    point and this message is how they get corrected.
    """
    lookup = {normalise(h).replace(" ", "_"): h for h in headers}
    resolved: dict[str, str] = {}
    for field_name, aliases in COLUMN_ALIASES.items():
        for alias in aliases:
            if alias in lookup:
                resolved[field_name] = lookup[alias]
                break

    missing = [f for f in REQUIRED_FIELDS if f not in resolved]
    if missing:
        raise SystemExit(
            f"\n{path}: cannot map {', '.join(missing)}.\n"
            f"  headers found: {', '.join(headers)}\n"
            f"  aliases tried: "
            + "; ".join(f"{f}={'/'.join(COLUMN_ALIASES[f])}" for f in missing)
            + "\n\nAdd the real spelling to COLUMN_ALIASES in this script. "
            "The mapping is not guessed positionally on purpose: a food "
            "database with protein and carbohydrate swapped still looks "
            "entirely plausible.\n"
        )
    return resolved


def number(raw: str | None) -> float | None:
    """A cell as a float, or None when it says nothing.

    Blank, '-', 'NA' and 'trace' all mean 'not measured' in these tables and
    must not become 0.0 — a zero is a measurement, and it drags every average
    computed over the column.
    """
    if raw is None:
        return None
    text = raw.strip()
    if text == "" or text.lower() in {"na", "n/a", "-", "--", "nd", "trace"}:
        return None
    try:
        return float(text.replace(",", ""))
    except ValueError:
        return None


def read_text(path: Path) -> str:
    """Decode a source CSV.

    The INDB export is cp1252, not UTF-8: 'eclair' carries a 0xe9 and three
    milkshake rows carry 0xa0 non-breaking spaces. UTF-8 is tried first so a
    correctly encoded source is never mojibaked by the lossy fallback.
    """
    data = path.read_bytes()
    try:
        return data.decode("utf-8-sig")
    except UnicodeDecodeError:
        return data.decode("cp1252")


def serving_grams(values: dict[str, float | None]) -> tuple[float, float] | None:
    """The serving weight INDB implies, and how much its columns disagree.

    The file carries every nutrient twice — per 100 g and per serving — so the
    ratio of the two IS the serving weight. No unit table, no name match, no
    fuzzy join: the source already did the arithmetic and this recovers it.

    Returns (grams, spread) where spread is the relative range across the four
    macros, or None when no pair is usable. Averaging four rounded ratios is
    the point: any single one carries the rounding of two cells.
    """
    ratios = [
        100.0 * values[f"serving_{key}"] / values[key]
        for key in ("kcal", "carbs", "protein", "fat")
        if values.get(key) and values.get(f"serving_{key}")
    ]
    if not ratios:
        return None
    mean = sum(ratios) / len(ratios)
    if mean <= 0:
        return None
    return mean, (max(ratios) - min(ratios)) / mean


def read_foods(path: Path, source: str, is_recipe: bool, report: Report) -> list[Food]:
    if path.suffix.lower() in {".xlsx", ".xls"}:
        raise SystemExit(
            f"\n{path}: export this sheet to CSV first.\n"
            "Reading .xlsx would mean adding openpyxl, and 'Save As -> CSV' "
            "costs this repo no dependency at all.\n"
        )

    with io.StringIO(read_text(path), newline="") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames is None:
            raise SystemExit(f"\n{path}: no header row.\n")
        columns = resolve_columns(list(reader.fieldnames), path)

        foods: list[Food] = []
        for line, row in enumerate(reader, start=2):
            origin = f"{path.name}:{line}"
            name = (row.get(columns["name"]) or "").strip()
            if not name:
                report.warnings.append(
                    Problem("unnamed row", "", "no name; row skipped", origin)
                )
                continue

            values = {
                key: number(row.get(columns[key]))
                for key in COLUMN_ALIASES
                if key in columns
            }
            missing = [k for k in REQUIRED_FIELDS[1:] if values.get(k) is None]
            if missing:
                report.errors.append(
                    Problem(
                        "unparsable macros",
                        name,
                        f"{', '.join(missing)} missing or non-numeric",
                        origin,
                    )
                )
                continue

            # M3-6. An explicit serving column wins if the file has one; the
            # INDB sheets do not, and the per-serving columns are the source.
            derived = serving_grams(values)
            serving = values.get("serving_g")
            if serving is None and derived is not None:
                grams, spread = derived
                if spread > SERVING_AGREEMENT_TOLERANCE:
                    report.warnings.append(
                        Problem(
                            "serving columns disagree",
                            name,
                            f"the macros imply {grams:.0f} g per serving but "
                            f"spread {spread * 100:.0f}%; serving dropped",
                            origin,
                        )
                    )
                else:
                    serving = grams

            foods.append(
                Food(
                    name=name,
                    source=source,
                    is_recipe=is_recipe,
                    kcal100=values["kcal"],
                    protein100=values["protein"],
                    carbs100=values["carbs"],
                    fat100=values["fat"],
                    fibre100=values.get("fibre") or 0.0,
                    sugar100=values.get("sugar"),
                    # The IFCT reports saturated fat and sodium in mg; the
                    # schema stores them per 100 g in the same unit the source
                    # used, so nothing is converted here and the column name
                    # carries the unit.
                    satfat100=values.get("satfat"),
                    sodium100=values.get("sodium"),
                    serving_g=serving,
                    serving_unit=(
                        row.get(columns.get("serving_unit", "")) or ""
                    ).strip(),
                    origin=origin,
                )
            )
    return foods


# ---------------------------------------------------------------------------
# Step 3 — USDA generics
# ---------------------------------------------------------------------------

# FoodData Central nutrient numbers. These are stable identifiers in the USDA
# schema, not names, which is why they are matched on rather than the label.
USDA_NUTRIENTS = {
    "kcal": "208",
    "protein": "203",
    "carbs": "205",
    "fat": "204",
    "fibre": "291",
    "sugar": "269",
    "satfat": "606",
    "sodium": "307",
}


def fetch_usda(ids: list[str], api_key: str, report: Report) -> list[Food]:
    """One request per FDC ID. Small lists only; this is a one-off build."""
    foods: list[Food] = []
    for fdc_id in ids:
        url = (
            USDA_ENDPOINT
            + urllib.parse.quote(fdc_id)
            + "?"
            + urllib.parse.urlencode({"api_key": api_key})
        )
        try:
            with urllib.request.urlopen(url, timeout=30) as response:
                payload = json.load(response)
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as error:
            report.errors.append(
                Problem("usda fetch", fdc_id, str(error), "FoodData Central")
            )
            continue

        by_number: dict[str, float] = {}
        for entry in payload.get("foodNutrients", []):
            nutrient = entry.get("nutrient") or {}
            key = str(nutrient.get("number", ""))
            if entry.get("amount") is not None:
                by_number[key] = float(entry["amount"])

        values = {
            name: by_number.get(num) for name, num in USDA_NUTRIENTS.items()
        }
        missing = [k for k in REQUIRED_FIELDS[1:] if values.get(k) is None]
        if missing:
            report.errors.append(
                Problem(
                    "usda fetch",
                    payload.get("description", fdc_id),
                    f"{', '.join(missing)} absent from the response",
                    f"FDC {fdc_id}",
                )
            )
            continue

        foods.append(
            Food(
                name=payload.get("description", "").strip(),
                source="USDA",
                is_recipe=False,
                kcal100=values["kcal"],
                protein100=values["protein"],
                carbs100=values["carbs"],
                fat100=values["fat"],
                fibre100=values.get("fibre") or 0.0,
                sugar100=values.get("sugar"),
                satfat100=values.get("satfat"),
                sodium100=values.get("sodium"),
                origin=f"FDC {fdc_id}",
            )
        )
    return foods


# ---------------------------------------------------------------------------
# Step 4 — deduplicate
# ---------------------------------------------------------------------------


def deduplicate(foods: list[Food], report: Report) -> list[Food]:
    """One row per normalised name. INDB wins any Indian item.

    Order of preference is INDB, then USDA, then anything else — the pipeline
    exists to make Indian food loggable, and a USDA 'rice, white, cooked' is
    not a better answer than the INDB row for the same dish.
    """
    rank = {"INDB": 0, "USDA": 1}
    kept: dict[str, Food] = {}
    for food in foods:
        key = food.normalised_name
        existing = kept.get(key)
        if existing is None:
            kept[key] = food
            continue
        if rank.get(food.source, 9) < rank.get(existing.source, 9):
            kept[key] = food
            loser, winner = existing, food
        else:
            loser, winner = food, existing
        report.warnings.append(
            Problem(
                "duplicate name",
                winner.name,
                f"kept {winner.source}, dropped {loser.source} ({loser.origin})",
                winner.origin,
            )
        )
    return list(kept.values())


# ---------------------------------------------------------------------------
# Step 5 — household servings
# ---------------------------------------------------------------------------


def servings_for(food: Food) -> list[tuple[str, float, bool]]:
    """Every serving row this food should carry, most specific rule first."""
    name = food.normalised_name
    rows = [
        (label, grams, is_default)
        for pattern, label, grams, is_default in SERVING_RULES
        if pattern in name
    ]
    if rows:
        return rows
    if not food.serving_g:
        return []

    # M3-7. A bowl is a katori, but the source has never used that word, so
    # both rows are emitted: the katori row is the one M3-2 calibrates, the
    # bowl row is what INDB actually said.
    unit = normalise(food.serving_unit)
    if unit in KATORI_UNITS:
        return [
            (KATORI_UNITS[unit], food.serving_g, True),
            (f"1 {food.serving_unit}", food.serving_g, False),
        ]
    if unit:
        return [(f"1 {food.serving_unit}", food.serving_g, True)]
    # No unit published, so the weight is all the source gave us.
    return [("1 serving", food.serving_g, True)]


# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------


def reconstructed_kcal(food: Food) -> float:
    return (
        food.protein100 * KCAL_PER_G_PROTEIN
        + food.carbs100 * KCAL_PER_G_CARB
        + food.fat100 * KCAL_PER_G_FAT
    )


def macro_discrepancy(food: Food) -> float | None:
    """How far the stated energy sits from the macros, as a fraction.

    None when the food is too low-energy for the ratio to mean anything.
    """
    if food.kcal100 < MACRO_RECONCILIATION_MIN_KCAL:
        return None
    return abs(reconstructed_kcal(food) - food.kcal100) / food.kcal100


def fails_reconciliation(food: Food) -> bool:
    """The M3-4 predicate, in one place.

    Every caller — validation, quarantine, the tests, any analysis of the
    failing set — asks this rather than re-deriving it from the constants. Two
    implementations of the same threshold is two sources of truth, and they
    drift silently: an ad-hoc pass at 25% with no energy floor counted 35 rows
    where this counts 38, and neither number was wrong about its own rule.
    """
    discrepancy = macro_discrepancy(food)
    return discrepancy is not None and discrepancy > MACRO_RECONCILIATION_TOLERANCE


def validate(foods: list[Food], report: Report) -> None:
    for food in foods:
        macros = {
            "protein": food.protein100,
            "carbs": food.carbs100,
            "fat": food.fat100,
            "fibre": food.fibre100,
        }

        for label, value in {"kcal": food.kcal100, **macros}.items():
            if value < 0:
                report.errors.append(
                    Problem("negative value", food.name, f"{label}={value}", food.origin)
                )

        if food.kcal100 > MAX_KCAL_PER_100G:
            report.errors.append(
                Problem(
                    "impossible energy",
                    food.name,
                    f"{food.kcal100:.0f} kcal/100 g exceeds pure fat "
                    f"({MAX_KCAL_PER_100G:.0f})",
                    food.origin,
                )
            )

        for label, value in macros.items():
            if value > MAX_G_PER_100G:
                report.errors.append(
                    Problem(
                        "impossible mass",
                        food.name,
                        f"{value:.1f} g of {label} in 100 g of food",
                        food.origin,
                    )
                )

        if food.kcal100 == 0 and any(v > 0 for v in macros.values()):
            report.errors.append(
                Problem(
                    "zero energy with macros",
                    food.name,
                    "kcal is 0 but the macros are not",
                    food.origin,
                )
            )

        # The important one. M3-8: quarantined rather than blocking, because
        # no transformation explains these rows and a gate that can never be
        # satisfied means the database is never written at all.
        if fails_reconciliation(food):
            food.quarantined = True
            discrepancy = macro_discrepancy(food) or 0.0
            report.quarantined.append(
                Problem(
                    "macro reconciliation",
                    food.name,
                    f"stated {food.kcal100:.0f} kcal, macros give "
                    f"{reconstructed_kcal(food):.0f} "
                    f"({discrepancy * 100:.0f}% off): "
                    f"P{food.protein100:g} C{food.carbs100:g} F{food.fat100:g}",
                    food.origin,
                )
            )

    served = {
        food.normalised_name for food in foods if servings_for(food)
    }
    for staple in UNSERVED_STAPLES:
        if not any(staple in name for name in served):
            report.errors.append(
                Problem(
                    "staple without a serving",
                    staple,
                    "no food matching this has a household serving row; "
                    "gram-only entry is what section 5 exists to prevent",
                    "ARCHITECTURE.md section 5",
                )
            )

    # M3-6 coverage. A food with no serving row is gram-only entry, which is
    # the failure section 5 exists to prevent, so the ones left over are named
    # rather than left as a number to be taken on trust.
    unserved = [f for f in foods if not servings_for(f)]
    for food in unserved:
        report.unserved.append(
            Problem(
                "no household serving",
                food.name,
                "gram-only entry; no usable per-serving figure. Rows whose "
                "per-serving columns disagreed are under WARNINGS",
                food.origin,
            )
        )

    report.counts = {
        "foods": len(foods),
        "recipes": sum(1 for f in foods if f.is_recipe),
        "items": sum(1 for f in foods if not f.is_recipe),
        "servings": sum(len(servings_for(f)) for f in foods),
        "with a serving": len(foods) - len(unserved),
        "without a serving": len(unserved),
        "quarantined": sum(1 for f in foods if f.quarantined),
    }
    for source in sorted({f.source for f in foods}):
        report.counts[f"source {source}"] = sum(
            1 for f in foods if f.source == source
        )


# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------


def print_report(report: Report) -> None:
    out = sys.stdout.write
    out("\nFOOD DATABASE VALIDATION\n")

    out("\nCOUNTS\n")
    for label, value in report.counts.items():
        out(f"  {label:<22}{value:>7}\n")

    if report.skipped:
        out("\nSKIPPED\n")
        for line in report.skipped:
            out(f"  {line}\n")

    for title, problems in (
        ("ERRORS — nothing is written while any of these stand", report.errors),
        (
            "QUARANTINED — written, flagged, and excluded from search",
            report.quarantined,
        ),
        ("NO HOUSEHOLD SERVING — gram-only entry", report.unserved),
        ("WARNINGS — read them, then decide", report.warnings),
    ):
        out(f"\n{title}\n")
        if not problems:
            out("  none\n")
            continue
        by_check: dict[str, list[Problem]] = {}
        for problem in problems:
            by_check.setdefault(problem.check, []).append(problem)
        for check, group in sorted(by_check.items()):
            out(f"  {check} ({len(group)})\n")
            for problem in group[:_MAX_LISTED]:
                out(f"    {problem.food or '—'}  [{problem.origin}]\n")
                out(f"      {problem.detail}\n")
            if len(group) > _MAX_LISTED:
                out(f"    ... and {len(group) - _MAX_LISTED} more\n")

    out("\n")
    out("PASS — safe to write\n" if report.ok else "FAIL — fix the errors above\n")
    out("\n")


# Long enough to see a pattern, short enough that the report stays read.
_MAX_LISTED = 15


# ---------------------------------------------------------------------------
# Steps 6 and 7 — write, index, vacuum
# ---------------------------------------------------------------------------


# Transcribed from drift_schemas/drift_schema_v7.json — the generated schema,
# not the Dart getters, so the column names, order, nullability and CHECK
# constraints are drift's own rather than an inference from
# lib/data/db/tables/food_tables.dart. The two must not drift apart:
# test_the_schema_matches_drift asserts this against that JSON.
#
# foods_fts is copied from lib/data/db/foods_fts.drift, which declares a plain
# fts5 table — NOT contentless. The `content=''` this script used before was a
# real divergence: a contentless table cannot return its own column values,
# so the documented join would have behaved differently in the app than here.
#
# NOT PRESENT, deliberately: no `quarantined` column. Drift has none, and this
# file must match it exactly. See build_food_db's report and NOTES.md.
SCHEMA = """
CREATE TABLE foods (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  name_local TEXT NULL,
  brand TEXT NULL,
  source TEXT NOT NULL,
  barcode TEXT NULL,
  is_recipe INTEGER NOT NULL DEFAULT 0 CHECK ("is_recipe" IN (0, 1)),
  kcal100 REAL NOT NULL,
  protein100 REAL NOT NULL,
  carbs100 REAL NOT NULL,
  fat100 REAL NOT NULL,
  fibre100 REAL NOT NULL,
  sugar100 REAL NULL,
  sat_fat100 REAL NULL,
  sodium100 REAL NULL
);
CREATE TABLE servings (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  food_id INTEGER NOT NULL REFERENCES foods (id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  grams REAL NOT NULL,
  is_default INTEGER NOT NULL DEFAULT 0 CHECK ("is_default" IN (0, 1))
);
CREATE VIRTUAL TABLE foods_fts USING fts5 (
  name,
  name_local,
  brand
);
"""

# `source` is textEnum<FoodSource>() in drift, which stores the Dart enum's
# .name via EnumNameConverter. Writing "INDB" here would make every row
# unreadable by the app: the converter looks up FoodSource.values by name and
# finds nothing. The pipeline's own labels are upper case, so they are mapped
# here rather than renamed everywhere — the report reads better as INDB.
FOOD_SOURCE_ENUM = {"INDB": "indb", "USDA": "usda"}


def enum_source(source: str) -> str:
    """The FoodSource enum name drift expects, or a loud failure.

    Not a .lower() call: FoodSource is a closed set of four, and a source this
    map has never seen must stop the write rather than produce rows the app
    silently cannot decode.
    """
    try:
        return FOOD_SOURCE_ENUM[source]
    except KeyError:
        raise SystemExit(
            f"\n{source!r} has no FoodSource enum member.\n"
            f"  known: {', '.join(sorted(FOOD_SOURCE_ENUM))}\n"
            f"  FoodSource declares: indb, usda, off, user\n\n"
            "Add the mapping to FOOD_SOURCE_ENUM, or add the enum value to "
            "lib/data/db/tables/food_tables.dart first. A row whose source "
            "does not match an enum name throws when the app reads it.\n"
        ) from None


def write_database(foods: list[Food], path: Path) -> None:
    """Only ever reached after the report passes and --write is given."""
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        path.unlink()

    connection = sqlite3.connect(path)
    try:
        connection.executescript(SCHEMA)
        for food in foods:
            cursor = connection.execute(
                "INSERT INTO foods (name, source, is_recipe, kcal100, "
                "protein100, carbs100, fat100, fibre100, sugar100, "
                "sat_fat100, sodium100) VALUES (?,?,?,?,?,?,?,?,?,?,?)",
                (
                    food.name,
                    enum_source(food.source),
                    int(food.is_recipe),
                    food.kcal100,
                    food.protein100,
                    food.carbs100,
                    food.fat100,
                    food.fibre100,
                    food.sugar100,
                    food.satfat100,
                    food.sodium100,
                ),
            )
            food_id = cursor.lastrowid
            connection.executemany(
                "INSERT INTO servings (food_id, label, grams, is_default) "
                "VALUES (?,?,?,?)",
                [
                    (food_id, label, grams, int(is_default))
                    for label, grams, is_default in servings_for(food)
                ],
            )
            # M3-8: the row exists, but nothing can find it by searching.
            if not food.quarantined:
                connection.execute(
                    "INSERT INTO foods_fts (rowid, name, name_local, brand) "
                    "VALUES (?,?,?,?)",
                    (food_id, food.name, None, None),
                )
        connection.commit()
        connection.execute("VACUUM")
    finally:
        connection.close()


# Terms chosen to probe tokenisation rather than to pass: 'roti' and 'paneer'
# are the ones most likely to be absent or spelled differently, 'bowl' should
# match nothing in a name column now that servings carry the vessel, and
# 'soup' is where the quarantined rows are, so it is the check that the FTS
# exclusion actually took.
SMOKE_TERMS = ("dal", "roti", "paneer", "chicken", "soup", "bowl")


def describe_database(path: Path, foods: list[Food]) -> None:
    """What actually landed in the file. Printed after every --write.

    A row count the pipeline computed is not evidence about the database; it
    is evidence about the pipeline. These numbers come back out of the file.
    """
    out = sys.stdout.write
    connection = sqlite3.connect(path)
    try:
        out("\nWRITTEN\n")
        out(f"  {'path':<22}{str(path)}\n")
        out(f"  {'size':<22}{path.stat().st_size / 1024:>7.0f} KB\n")
        for table in ("foods", "servings", "foods_fts"):
            count = connection.execute(
                f"SELECT COUNT(*) FROM {table}"  # noqa: S608 - fixed literals
            ).fetchone()[0]
            out(f"  {table:<22}{count:>7}\n")

        quarantined_rows = sum(1 for f in foods if f.quarantined)
        indexed = connection.execute("SELECT COUNT(*) FROM foods_fts").fetchone()[0]
        total = connection.execute("SELECT COUNT(*) FROM foods").fetchone()[0]
        out(f"  {'not indexed':<22}{total - indexed:>7}")
        out(f"   (quarantined: {quarantined_rows})\n")

        out("\nSAMPLE — foods\n")
        for row in connection.execute(
            "SELECT id, name, source, is_recipe, kcal100, protein100, "
            "carbs100, fat100 FROM foods ORDER BY id LIMIT 10"
        ):
            out(
                f"  {row[0]:>4}  {row[1][:38]:<40} {row[2]:<5} "
                f"recipe={row[3]}  {row[4]:>6.1f} kcal  "
                f"P{row[5]:<5g} C{row[6]:<5g} F{row[7]:<5g}\n"
            )

        out("\nSAMPLE — servings\n")
        for row in connection.execute(
            "SELECT s.id, f.name, s.label, s.grams, s.is_default "
            "FROM servings s JOIN foods f ON f.id = s.food_id "
            "ORDER BY s.id LIMIT 10"
        ):
            out(
                f"  {row[0]:>4}  {row[1][:32]:<34} {row[2]:<22} "
                f"{row[3]:>6.1f} g  default={row[4]}\n"
            )

        out("\nINDEX SMOKE TEST — top 5 per term\n")
        for term in SMOKE_TERMS:
            rows = connection.execute(
                "SELECT f.name FROM foods_fts JOIN foods f "
                "ON f.id = foods_fts.rowid WHERE foods_fts MATCH ? "
                "ORDER BY rank LIMIT 5",
                (term,),
            ).fetchall()
            hits = connection.execute(
                "SELECT COUNT(*) FROM foods_fts WHERE foods_fts MATCH ?",
                (term,),
            ).fetchone()[0]
            out(f"  {term!r} — {hits} match{'' if hits == 1 else 'es'}\n")
            for row in rows:
                out(f"      {row[0]}\n")
            if not rows:
                out("      (nothing)\n")
    finally:
        connection.close()
    out("\n")


# ---------------------------------------------------------------------------


def build(args: argparse.Namespace) -> tuple[list[Food], Report]:
    report = Report()
    foods: list[Food] = []

    if args.indb_recipes:
        foods += read_foods(Path(args.indb_recipes), "INDB", True, report)
    else:
        report.skipped.append("INDB recipes: --indb-recipes not given")

    if args.indb_items:
        foods += read_foods(Path(args.indb_items), "INDB", False, report)
    else:
        report.skipped.append("INDB items: --indb-items not given")

    api_key = args.usda_key or os.environ.get("FDC_API_KEY")
    if args.usda_ids and api_key:
        with Path(args.usda_ids).open(encoding="utf-8-sig") as handle:
            ids = [line.strip() for line in handle if line.strip()]
        foods += fetch_usda(ids, api_key, report)
    elif args.usda_ids:
        report.skipped.append(
            "USDA: --usda-ids given but no key (--usda-key or FDC_API_KEY)"
        )
    else:
        report.skipped.append(
            "USDA generics: --usda-ids not given. No FDC ID list is built into "
            "this script; 200 invented identifiers would look authoritative "
            "and be wrong"
        )

    foods = deduplicate(foods, report)
    validate(foods, report)
    return foods, report


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--indb-recipes", help="INDB recipes, exported as CSV")
    parser.add_argument("--indb-items", help="INDB/IFCT raw items, as CSV")
    parser.add_argument("--usda-ids", help="file of FDC IDs, one per line")
    parser.add_argument("--usda-key", help="FoodData Central key; or FDC_API_KEY")
    parser.add_argument("--out", default="assets/db/food.sqlite")
    parser.add_argument(
        "--write",
        action="store_true",
        help="write the database. Refused while any error-level check fails.",
    )
    args = parser.parse_args(argv)

    foods, report = build(args)
    print_report(report)

    if not args.write:
        sys.stdout.write(
            f"Nothing written. Re-run with --write to produce {args.out}.\n\n"
        )
        return 0 if report.ok else 1

    if not report.ok:
        sys.stdout.write("Refusing to write: fix the errors above.\n\n")
        return 1

    write_database(foods, Path(args.out))
    describe_database(Path(args.out), foods)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
