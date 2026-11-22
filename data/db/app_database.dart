import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:fitness_tracker/data/db/dao/plan_dao.dart';
import 'package:fitness_tracker/data/db/dao/preferences_dao.dart';
import 'package:fitness_tracker/data/db/dao/run_dao.dart';
import 'package:fitness_tracker/data/db/dao/steps_dao.dart';
import 'package:fitness_tracker/data/db/dao/workout_dao.dart';
import 'package:fitness_tracker/data/db/seed/seed_runner.dart';
import 'package:fitness_tracker/data/db/tables/activity_tables.dart';
import 'package:fitness_tracker/data/db/tables/food_tables.dart';
import 'package:fitness_tracker/data/db/tables/progress_tables.dart';
import 'package:fitness_tracker/data/db/tables/settings_tables.dart';
import 'package:fitness_tracker/data/db/tables/training_tables.dart';
// Used by the generated part file: drift emits enum converters into
// app_database.g.dart, which resolves types against this library's imports.
import 'package:fitness_tracker/data/models/training_enums.dart';

part 'app_database.g.dart';

/// The single drift database.
///
/// The FOOD tables are declared ahead of their feature because M3 is next.
/// [Measurements] likewise: weight and waist are tracked weekly. The run and
/// photo tables were declared the same way and dropped in v6 once their
/// milestones were cut — declaring a table years ahead of its DAO turned out
/// to cost four migrations and several thousand generated lines, not save them.
/// The run tables came back in v7 when GPS returned to scope; `photos` did not.
@DriftDatabase(
  tables: [
    // TRAINING
    Exercises,
    PlanDays,
    PlanItems,
    Workouts,
    SetLogs,
    WarmupChecks,
    // FOOD — no DAO until M3
    Foods,
    Servings,
    RecipeItems,
    FoodLogs,
    // ACTIVITY
    DailySteps,
    // ACTIVITY — GPS
    Runs,
    RunPoints,
    Splits,
    // PROGRESS — no DAO until M6
    Measurements,
    // SETTINGS
    Preferences,
  ],
  include: {'foods_fts.drift'},
  daos: [PlanDao, WorkoutDao, StepsDao, PreferencesDao, RunDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'fitness_tracker'));

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Steps are append-only: each `if` block is the migration into that
      // version and is never edited once it has run on a real database.
      if (from < 2) {
        // v2 timestamps each set so a workout left open can be closed out at
        // its last set. Added nullable because SQLite cannot backfill a NOT
        // NULL column; the UPDATE then gives every existing row the best
        // approximation available, its workout's start time.
        await m.addColumn(setLogs, setLogs.loggedAt);
        await customStatement(
          'UPDATE set_logs SET logged_at = (SELECT started_at FROM workouts '
          'WHERE workouts.id = set_logs.workout_id) '
          'WHERE logged_at IS NULL',
        );
      }
      if (from < 3) {
        // v3 makes warm-up checklists tickable, per workout.
        await m.createTable(warmupChecks);
      }
      if (from < 4) {
        // Repairs v3: `createTable` writes the table only — a table's
        // `@TableIndex` is a separate schema entity that `createAll` picks up
        // but `createTable` does not. Databases that upgraded into v3 got the
        // table without `idx_warmup_checks_workout`, while databases created
        // fresh at v3 got both, and neither can be told apart by version
        // alone. Hence `IF NOT EXISTS` and a raw statement: drift's own
        // `createIndex` emits a bare `CREATE INDEX` that would throw on the
        // fresh-install half of that split.
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_warmup_checks_workout '
          'ON warmup_checks (workout_id)',
        );
      }
      if (from < 5) {
        // v5 gives M4 somewhere to keep the step goal and the
        // backfill-already-ran marker. `daily_steps` itself needs no
        // migration — it has been in the schema since v1.
        await m.createTable(preferences);
      }
      if (from < 6) {
        // GPS run recording and progress photos were cut from scope, so the
        // tables declared for them in v1 are dropped rather than carried
        // forever. They never had a DAO, so nothing ever wrote a row to them
        // and there is no data to lose. `measurements` stays — weight and
        // waist are still tracked weekly.
        //
        // Children before parents: run_points and splits both reference runs.
        for (final table in ['run_points', 'splits', 'runs', 'photos']) {
          await customStatement('DROP TABLE IF EXISTS $table');
        }
      }
      if (from < 7) {
        // GPS run recording is back in scope, so the three tables v6 dropped
        // return. Not a revert: the v6 step above stays exactly as it ran on
        // real devices, and these tables come back in a slightly different
        // shape — nullable wherever the feature that fills the column is not
        // built yet, plus the two heart-rate columns A7 will need.
        //
        // Parents before children, the mirror of the v6 drop order.
        await m.createTable(runs);
        await m.createTable(runPoints);
        await m.createTable(splits);

        // `createTable` writes the table and NOT its `@TableIndex` entries —
        // the same trap that shipped a real bug in v3 and had to be repaired
        // in v4. Creating them explicitly here is the whole lesson of that
        // repair. `IF NOT EXISTS` because a database dropped through v6 and a
        // database that never had these tables both arrive at this line.
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_runs_started_at '
          'ON runs (started_at)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_run_points_run '
          'ON run_points (run_id)',
        );
      }
    },
    beforeOpen: (details) async {
      // Drift disables foreign keys by default; the plan graph relies on them.
      await customStatement('PRAGMA foreign_keys = ON');
      await seedTrainingDataIfEmpty(this);
    },
  );
}
