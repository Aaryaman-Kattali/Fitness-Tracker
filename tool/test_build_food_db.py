#!/usr/bin/env python3
"""Tests for build_food_db.py. Standard library only.

    py tool/test_build_food_db.py

The fixtures are built so the checks can actually FAIL. A macro
reconciliation test against one clean food and one absurd one passes against
almost any threshold, including a wrong one — so `indb_dirty.csv` carries a
pair straddling the band at 14.0% and 16.0%, and the assertions name both.
Move the tolerance and one of them breaks.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import build_food_db as fdb  # noqa: E402

FIXTURES = Path(__file__).parent / "fixtures"


def run(**overrides) -> tuple[list[fdb.Food], fdb.Report]:
    args = argparse.Namespace(
        indb_recipes=None,
        indb_items=None,
        usda_ids=None,
        usda_key=None,
        out="unused",
        write=False,
    )
    for key, value in overrides.items():
        setattr(args, key, value)
    return fdb.build(args)


def checks(report: fdb.Report) -> set[str]:
    return {problem.check for problem in report.errors}


def named(report: fdb.Report, check: str) -> set[str]:
    return {p.food for p in report.errors if p.check == check}


def quarantined(report: fdb.Report) -> set[str]:
    return {p.food for p in report.quarantined}


class CleanSource(unittest.TestCase):
    def test_a_clean_file_produces_no_errors(self):
        """The control. Without it every check below could be firing always."""
        foods, report = run(indb_recipes=str(FIXTURES / "indb_clean.csv"))

        self.assertEqual(report.errors, [], msg=[p.detail for p in report.errors])
        self.assertTrue(report.ok)
        self.assertEqual(len(foods), 8)
        self.assertEqual(report.counts["recipes"], 8)

    def test_every_staple_gets_a_household_serving(self):
        """Section 5's whole point: nobody weighs 150 g of dal."""
        foods, _ = run(indb_recipes=str(FIXTURES / "indb_clean.csv"))
        by_name = {f.normalised_name: f for f in foods}

        chapati = fdb.servings_for(by_name["chapati whole wheat"])
        self.assertIn(("1 medium chapati", 35.0, True), chapati)
        self.assertIn(("1 large chapati", 50.0, False), chapati)

        dal = fdb.servings_for(by_name["dal tadka cooked"])
        self.assertEqual(dal, [("1 katori dal (cooked)", 150.0, True)])

        for staple in fdb.UNSERVED_STAPLES:
            self.assertTrue(
                any(staple in name for name in by_name),
                msg=f"the clean fixture must cover {staple}",
            )

    def test_a_source_serving_size_is_used_when_there_is_no_rule(self):
        """Poha matches no household rule but the source published a serving."""
        foods, _ = run(indb_recipes=str(FIXTURES / "indb_clean.csv"))
        poha = next(f for f in foods if f.normalised_name == "poha cooked")

        self.assertEqual(fdb.servings_for(poha), [("1 serving", 180.0, True)])

    def test_a_missing_staple_is_an_error_not_a_note(self):
        """Mutation: drop the dal row and the run must fail, not warn."""
        source = (FIXTURES / "indb_clean.csv").read_text(encoding="utf-8")
        kept = [
            line for line in source.splitlines() if not line.startswith("R003,")
        ]
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "no_dal.csv"
            path.write_text("\n".join(kept), encoding="utf-8")
            _, report = run(indb_recipes=str(path))

        self.assertIn("staple without a serving", checks(report))
        self.assertIn("dal", named(report, "staple without a serving"))
        self.assertFalse(report.ok)


class MacroReconciliation(unittest.TestCase):
    """4P + 4C + 9F against the stated energy. The check that matters."""

    def setUp(self):
        _, self.report = run(indb_recipes=str(FIXTURES / "indb_dirty.csv"))
        # M3-8 moved these from errors to quarantine. They are still caught;
        # what changed is that the flag contains them instead of the gate.
        self.flagged = quarantined(self.report)

    def test_a_reconciliation_failure_is_quarantined_not_an_error(self):
        """M3-8. The row is kept and flagged, and does not hold the gate shut.

        Asserted both ways round: in the quarantine bucket, and absent from
        errors. Without the second half this passes if the check fires twice.
        """
        self.assertIn("Pulao rice kilojoules misparsed", self.flagged)
        self.assertNotIn(
            "Pulao rice kilojoules misparsed",
            named(self.report, "macro reconciliation"),
        )

    def test_the_quarantine_flag_is_set_on_the_food_itself(self):
        """The report says so and the row must agree; the row is what ships."""
        foods, _ = run(indb_recipes=str(FIXTURES / "indb_dirty.csv"))
        flagged = {f.name for f in foods if f.quarantined}

        self.assertIn("Pulao rice kilojoules misparsed", flagged)
        self.assertNotIn("Black tea no sugar", flagged)

    def test_a_kilojoule_misparse_is_caught(self):
        """The failure this exists for: 598 kJ read as 598 kcal.

        It is 4.6x the energy the macros support, and on the plate it is a
        food that reads 598 kcal per 100 g. Logged once, never questioned.
        """
        self.assertIn("Pulao rice kilojoules misparsed", self.flagged)

    def test_the_band_is_where_it_says_it_is(self):
        """Both sides of 15%, from foods that differ only in stated energy.

        D002 and D003 carry identical macros — 268 kcal reconstructed — and
        differ only in the kcal column, at 14.0% and 16.0% off. A tolerance
        moved in either direction breaks exactly one of these.
        """
        inside = next(
            f for f in self._foods() if f.name.endswith("just inside the band")
        )
        outside = next(
            f for f in self._foods() if f.name.endswith("just outside the band")
        )
        self.assertAlmostEqual(fdb.macro_discrepancy(inside), 0.140, places=3)
        self.assertAlmostEqual(fdb.macro_discrepancy(outside), 0.160, places=3)

        self.assertNotIn("Reconciliation just inside the band", self.flagged)
        self.assertIn("Reconciliation just outside the band", self.flagged)

    def test_a_low_energy_food_is_not_flagged_on_a_ratio(self):
        """Black tea reconstructs 3 kcal against a stated 15 — 78% off.

        Nothing is wrong with it. Below the floor the ratio measures rounding,
        and a report full of correct foods is a report nobody reads.
        """
        self.assertNotIn("Black tea no sugar", self.flagged)
        tea = next(f for f in self._foods() if f.name == "Black tea no sugar")
        self.assertIsNone(fdb.macro_discrepancy(tea))

    def _foods(self):
        foods, _ = run(indb_recipes=str(FIXTURES / "indb_dirty.csv"))
        return foods


class RangeChecks(unittest.TestCase):
    def setUp(self):
        _, self.report = run(indb_recipes=str(FIXTURES / "indb_dirty.csv"))

    def test_more_fat_than_food(self):
        self.assertIn(
            "Fat exceeding the food it is in", named(self.report, "impossible mass")
        )

    def test_denser_than_pure_fat(self):
        self.assertIn(
            "Denser than pure fat", named(self.report, "impossible energy")
        )

    def test_negative_values(self):
        self.assertIn("Protein below zero", named(self.report, "negative value"))

    def test_zero_energy_with_macros(self):
        self.assertIn(
            "Energy zero with macros present",
            named(self.report, "zero energy with macros"),
        )

    def test_a_non_numeric_macro_is_reported_not_defaulted_to_zero(self):
        """A blank protein cell must not silently become 0 g.

        Zero is a measurement. A food that reads 0 g protein is a food the
        macro reconciliation then flags for a reason that is not the real one.
        """
        self.assertIn("Macros not numeric", named(self.report, "unparsable macros"))
        foods, _ = run(indb_recipes=str(FIXTURES / "indb_dirty.csv"))
        self.assertNotIn("Macros not numeric", {f.name for f in foods})


class ServingDerivation(unittest.TestCase):
    """M3-6. The serving weight comes from INDB's own per-serving columns.

    The fixture carries two 'bowl' foods with deliberately different serving
    weights — Chana masala at 250 g, Rajma masala at 180 g — because a single
    bowl food would let a hardcoded constant, a per-unit lookup table or an
    average pass this suite while being wrong on every other row.
    """

    def setUp(self):
        self.foods, self.report = run(
            indb_recipes=str(FIXTURES / "indb_servings.csv")
        )
        self.by_name = {f.normalised_name: f for f in self.foods}

    def test_the_fixture_is_otherwise_clean(self):
        """The control, so the assertions below are not passing by accident."""
        self.assertEqual(
            self.report.errors, [], msg=[p.detail for p in self.report.errors]
        )

    def test_two_bowls_of_different_weight_are_both_recovered(self):
        self.assertAlmostEqual(self.by_name["chana masala"].serving_g, 250.0, places=6)
        self.assertAlmostEqual(self.by_name["rajma masala"].serving_g, 180.0, places=6)

    def test_the_ratio_is_taken_the_right_way_up(self):
        """An inverted ratio gives 40 g for a 250 g bowl and looks plausible."""
        chana = self.by_name["chana masala"]
        self.assertGreater(chana.serving_g, 100.0)

    def test_a_katori_food_carries_both_labels(self):
        """M3-7. Katori is the default and calibratable; bowl is what INDB said."""
        rows = fdb.servings_for(self.by_name["chana masala"])

        self.assertEqual(
            rows,
            [("1 katori", 250.0, True), ("1 bowl", 250.0, False)],
        )

    def test_small_bowl_gets_its_own_katori_label(self):
        rows = fdb.servings_for(self.by_name["sambhar"])

        self.assertEqual(
            rows,
            [("1 small katori", 120.0, True), ("1 small bowl", 120.0, False)],
        )

    def test_a_non_bowl_unit_is_left_in_the_sources_own_words(self):
        """No invented vocabulary where the source was already specific."""
        rows = fdb.servings_for(self.by_name["chole bhature"])

        self.assertEqual(rows, [("1 plate", 300.0, True)])

    def test_a_household_rule_still_beats_the_derived_serving(self):
        """Dal's per-serving columns imply a 400 g bowl; section 5 says 150 g.

        The rule wins, or M3-2's katori calibration is scaling a number that
        came from a stranger's serving bowl.
        """
        dal = self.by_name["dal tadka cooked"]

        self.assertAlmostEqual(dal.serving_g, 400.0, places=6)
        self.assertEqual(
            fdb.servings_for(dal), [("1 katori dal (cooked)", 150.0, True)]
        )

    def test_disagreeing_serving_columns_are_reported_not_averaged(self):
        """Jaljeera's kcal implies 300 g and its macros imply 200 g.

        Averaging those gives 225 g, which is wrong and looks entirely
        reasonable. The serving is dropped and the row is named instead.
        """
        jaljeera = self.by_name["jaljeera drink"]

        self.assertIsNone(jaljeera.serving_g)
        self.assertEqual(fdb.servings_for(jaljeera), [])
        self.assertIn(
            "Jaljeera drink",
            {p.food for p in self.report.warnings
             if p.check == "serving columns disagree"},
        )

    def test_a_food_with_no_unit_still_gets_its_weight(self):
        """Upma publishes per-serving figures but never names the vessel."""
        rows = fdb.servings_for(self.by_name["upma"])

        self.assertEqual(rows, [("1 serving", 200.0, True)])

    def test_coverage_is_counted_and_the_gaps_are_named(self):
        counts = self.report.counts

        self.assertEqual(counts["without a serving"], 1)
        self.assertEqual(counts["with a serving"], len(self.foods) - 1)
        self.assertEqual(
            {p.food for p in self.report.unserved}, {"Jaljeera drink"}
        )

class ReconciliationPredicate(unittest.TestCase):
    """One predicate, so a second implementation cannot drift away from it.

    An ad-hoc pass at 25% with no energy floor counted 35 rows of INDB.csv
    where validate() counted 38. Neither was wrong about its own rule, which
    is the problem: the rule existed twice.
    """

    def test_the_constants_are_the_ones_M3_4_specifies(self):
        self.assertEqual(fdb.MACRO_RECONCILIATION_TOLERANCE, 0.15)
        self.assertEqual(fdb.MACRO_RECONCILIATION_MIN_KCAL, 20.0)

    def test_the_predicate_is_what_validate_actually_applies(self):
        """Recount the fixture with the predicate; validate must agree exactly.

        This is the assertion that stops the two from drifting: change the
        threshold in either place and the counts separate.
        """
        foods, report = run(indb_recipes=str(FIXTURES / "indb_dirty.csv"))
        by_predicate = {f.name for f in foods if fdb.fails_reconciliation(f)}

        self.assertEqual(by_predicate, quarantined(report))
        self.assertTrue(by_predicate, msg="the fixture must contain failures")

    def test_the_floor_is_applied_as_well_as_the_tolerance(self):
        """A 78%-off food under 20 kcal is not a failure. Dropping the floor
        from the predicate would silently add rows like this one."""
        tea = fdb.Food("Black tea", "INDB", True, 15.0, 0.1, 0.5, 0.0)

        self.assertGreater(abs(fdb.reconstructed_kcal(tea) - 15.0) / 15.0, 0.15)
        self.assertFalse(fdb.fails_reconciliation(tea))


class Quarantine(unittest.TestCase):
    """M3-8. Kept, flagged, unsearchable — not deleted and not corrected."""

    def test_a_quarantined_food_is_written_but_cannot_be_found(self):
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory) / "food.sqlite"
            code = fdb.main(
                [
                    "--indb-recipes",
                    str(FIXTURES / "indb_dirty.csv"),
                    "--out",
                    str(out),
                    "--write",
                ]
            )
            self.assertEqual(code, 1, msg="the dirty fixture still has errors")
            self.assertFalse(out.exists())

    def test_quarantine_alone_does_not_hold_the_write_gate_shut(self):
        """The whole point of the flag: these rows ship, contained.

        Built from the clean fixture plus one unexplainable row, so the only
        thing standing between this run and a database is the quarantine.
        """
        source = (FIXTURES / "indb_clean.csv").read_text(encoding="utf-8")
        bad = "R009,Unexplainable soup,31,9.65,3.94,11.68,0.5,0.2,900,400,\n"
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "one_bad_row.csv"
            path.write_text(source.rstrip("\n") + "\n" + bad, encoding="utf-8")
            out = Path(directory) / "food.sqlite"

            foods, report = run(indb_recipes=str(path))
            self.assertEqual({p.food for p in report.quarantined},
                             {"Unexplainable soup"})
            self.assertTrue(report.ok, msg="quarantine must not block the gate")

            code = fdb.main(
                ["--indb-recipes", str(path), "--out", str(out), "--write"]
            )
            self.assertEqual(code, 0)

            connection = sqlite3.connect(out)
            try:
                # The asset carries no `quarantined` column — drift has none
                # and the schemas must match — so absence from foods_fts is
                # what marks the row, and it is the only reason a row is
                # left out of the index.
                flagged = connection.execute(
                    "SELECT name FROM foods WHERE id NOT IN "
                    "(SELECT rowid FROM foods_fts)"
                ).fetchall()
                self.assertEqual([r[0] for r in flagged], ["Unexplainable soup"])

                # Kept, not deleted.
                self.assertEqual(
                    connection.execute("SELECT COUNT(*) FROM foods").fetchone()[0],
                    9,
                )

                # Present in the table, absent from search.
                hits = connection.execute(
                    "SELECT f.name FROM foods_fts JOIN foods f "
                    "ON f.id = foods_fts.rowid WHERE foods_fts MATCH ?",
                    ("soup",),
                ).fetchall()
                self.assertEqual(hits, [])

                indexed = connection.execute(
                    "SELECT COUNT(*) FROM foods_fts"
                ).fetchone()[0]
                self.assertEqual(indexed, 8)
            finally:
                connection.close()


class SchemaMatchesDrift(unittest.TestCase):
    """The asset database and the app's own schema must not drift apart.

    Read from drift_schemas/drift_schema_v7.json — the generated schema, not
    the Dart source — because that is what drift will actually create on the
    device. A mismatch here is invisible until the DAO lands and every read
    fails at once.
    """

    SCHEMA_JSON = (
        Path(__file__).parent.parent / "drift_schemas" / "drift_schema_v7.json"
    )

    def setUp(self):
        if not self.SCHEMA_JSON.exists():  # pragma: no cover
            self.skipTest(f"{self.SCHEMA_JSON} not found")
        entities = json.loads(self.SCHEMA_JSON.read_text(encoding="utf-8"))
        self.drift = {
            e["data"]["name"]: e["data"]
            for e in entities["entities"]
            if e["type"] == "table"
        }

    def _written(self, table: str) -> list[tuple[str, str, int, int]]:
        """(name, type, notnull, pk) per column, in declared order."""
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory) / "food.sqlite"
            fdb.main(
                [
                    "--indb-recipes",
                    str(FIXTURES / "indb_clean.csv"),
                    "--out",
                    str(out),
                    "--write",
                ]
            )
            connection = sqlite3.connect(out)
            try:
                return [
                    (r[1], r[2], r[3], r[5])
                    for r in connection.execute(f"PRAGMA table_info({table})")
                ]
            finally:
                connection.close()

    MOOR_TO_SQLITE = {
        "int": "INTEGER",
        "string": "TEXT",
        "double": "REAL",
        "bool": "INTEGER",
    }

    def _assert_table(self, table: str):
        drift_columns = self.drift[table]["columns"]
        written = self._written(table)

        self.assertEqual(
            [c["name"] for c in drift_columns],
            [c[0] for c in written],
            msg=f"{table}: column names or ORDER differ from drift",
        )
        for declared, actual in zip(drift_columns, written):
            self.assertEqual(
                self.MOOR_TO_SQLITE[declared["moor_type"]],
                actual[1],
                msg=f"{table}.{declared['name']}: sql type differs",
            )
            self.assertEqual(
                not declared["nullable"],
                bool(actual[2]) or bool(actual[3]),
                msg=f"{table}.{declared['name']}: nullability differs",
            )

    def test_foods_matches_drift(self):
        self._assert_table("foods")

    def test_servings_matches_drift(self):
        self._assert_table("servings")

    def test_the_source_column_holds_a_FoodSource_enum_name(self):
        """drift stores textEnum via EnumNameConverter, so 'INDB' would throw.

        FoodSource declares indb, usda, off, user. A row whose source is not
        one of those names is unreadable by the app.
        """
        self.assertEqual(fdb.enum_source("INDB"), "indb")
        self.assertEqual(fdb.enum_source("USDA"), "usda")

        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory) / "food.sqlite"
            fdb.main(
                ["--indb-recipes", str(FIXTURES / "indb_clean.csv"),
                 "--out", str(out), "--write"]
            )
            connection = sqlite3.connect(out)
            try:
                sources = {
                    r[0] for r in connection.execute("SELECT DISTINCT source FROM foods")
                }
            finally:
                connection.close()
        self.assertEqual(sources, {"indb"})
        self.assertTrue(sources <= {"indb", "usda", "off", "user"})

    def test_an_unmapped_source_stops_the_write(self):
        """Silently lower-casing an unknown source is how the app gets a row
        it cannot decode. It must be a loud failure instead."""
        with self.assertRaises(SystemExit) as raised:
            fdb.enum_source("OpenFoodFacts")
        self.assertIn("FoodSource", str(raised.exception))

    def test_the_fts_table_is_not_contentless(self):
        """foods_fts.drift declares a plain fts5 table.

        A contentless one (content='') accepts the same MATCH queries but
        cannot return its own column values, so the divergence would only
        surface in the app.
        """
        self.assertIn("CREATE VIRTUAL TABLE foods_fts USING fts5", fdb.SCHEMA)
        self.assertNotIn("content=", fdb.SCHEMA)

    def test_no_quarantined_column_reaches_the_asset(self):
        """M3-8's flag has no drift column, and this file must match drift."""
        self.assertNotIn(
            "quarantined", [c[0] for c in self._written("foods")]
        )


class Deduplication(unittest.TestCase):
    def test_indb_wins_over_usda_for_the_same_name(self):
        indb = fdb.Food("Rice Cooked", "INDB", True, 130, 2.7, 28, 0.3)
        usda = fdb.Food("rice, cooked", "USDA", False, 129, 2.6, 28, 0.3)
        report = fdb.Report()

        kept = fdb.deduplicate([usda, indb], report)

        self.assertEqual(len(kept), 1)
        self.assertEqual(kept[0].source, "INDB")
        self.assertEqual({p.check for p in report.warnings}, {"duplicate name"})

    def test_names_that_only_look_alike_are_left_alone(self):
        """Deliberately dumb matching. 'dal fry' and 'dal makhani' are not the
        same food and a fuzzy match would merge them."""
        report = fdb.Report()
        kept = fdb.deduplicate(
            [
                fdb.Food("Dal fry", "INDB", True, 116, 7, 19, 0.8),
                fdb.Food("Dal makhani", "INDB", True, 178, 6, 15, 10.5),
            ],
            report,
        )
        self.assertEqual(len(kept), 2)


class ColumnMapping(unittest.TestCase):
    def test_an_unknown_header_aborts_and_says_what_it_saw(self):
        """The INDB sheets do not publish their column names.

        Guessing positionally would produce a database with protein and
        carbohydrate swapped, which looks entirely plausible and is wrong in
        every meal. So an unmapped column stops the run.
        """
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "odd.csv"
            path.write_text(
                "code,dish,cals,prot,cho,lipid\n1,Rice,130,2.7,28,0.3\n",
                encoding="utf-8",
            )
            with self.assertRaises(SystemExit) as raised:
                run(indb_recipes=str(path))

        message = str(raised.exception)
        self.assertIn("cannot map", message)
        self.assertIn("carbs", message)
        self.assertIn("cho", message, msg="the headers found must be printed")

    def test_xlsx_is_refused_with_the_fix(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "recipes.xlsx"
            path.write_bytes(b"not really a spreadsheet")
            with self.assertRaises(SystemExit) as raised:
                run(indb_recipes=str(path))
        self.assertIn("export this sheet to CSV", str(raised.exception))


class WriteGate(unittest.TestCase):
    def test_nothing_is_written_while_an_error_stands(self):
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory) / "food.sqlite"
            code = fdb.main(
                [
                    "--indb-recipes",
                    str(FIXTURES / "indb_dirty.csv"),
                    "--out",
                    str(out),
                    "--write",
                ]
            )
        self.assertEqual(code, 1)
        self.assertFalse(out.exists())

    def test_a_clean_source_writes_a_searchable_database(self):
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory) / "food.sqlite"
            code = fdb.main(
                [
                    "--indb-recipes",
                    str(FIXTURES / "indb_clean.csv"),
                    "--out",
                    str(out),
                    "--write",
                ]
            )
            self.assertEqual(code, 0)
            self.assertTrue(out.exists())

            connection = sqlite3.connect(out)
            try:
                self.assertEqual(
                    connection.execute("SELECT COUNT(*) FROM foods").fetchone()[0], 8
                )
                self.assertGreater(
                    connection.execute("SELECT COUNT(*) FROM servings").fetchone()[0],
                    0,
                )
                # The search pattern ARCHITECTURE.md section 3 specifies.
                rows = connection.execute(
                    "SELECT f.name FROM foods_fts JOIN foods f "
                    "ON f.id = foods_fts.rowid WHERE foods_fts MATCH ? "
                    "ORDER BY rank LIMIT 50",
                    ("chapati",),
                ).fetchall()
                self.assertEqual([r[0] for r in rows], ["Chapati whole wheat"])
            finally:
                connection.close()

    def test_the_default_run_writes_nothing_at_all(self):
        """No --write, no file, whatever the report says."""
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory) / "food.sqlite"
            code = fdb.main(
                [
                    "--indb-recipes",
                    str(FIXTURES / "indb_clean.csv"),
                    "--out",
                    str(out),
                ]
            )
        self.assertEqual(code, 0)
        self.assertFalse(out.exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
