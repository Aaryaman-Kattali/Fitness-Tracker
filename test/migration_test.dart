// drift exports its own `isNull`/`isNotNull` SQL expression builders, which
// collide with the matchers of the same name.
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:fitness_tracker/data/db/app_database.dart';
import 'package:fitness_tracker/data/models/training_enums.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/migrations/schema.dart';
import 'generated/migrations/schema_v1.dart' as v1;
import 'generated/migrations/schema_v2.dart' as v2;
import 'generated/migrations/schema_v4.dart' as v4;
import 'generated/migrations/schema_v5.dart' as v5;
import 'generated/migrations/schema_v6.dart' as v6;

/// Migrations run against databases that already hold a season of training,
/// not against empty ones. These tests build a realistic old database with
/// drift's generated per-version schemas, migrate it with the real
/// [AppDatabase], and check that the data is still there and still correct.
///
/// The generated schemas under `test/generated/migrations` come from
/// `drift_dev schema dump` run against each released version of the database
/// (v1 and v2 were dumped from their commits), so the starting point is the
/// schema that actually shipped rather than one written from memory.
void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('v1 to v7', () {
    test('every schema version can be migrated to the next', () async {
      // The cheap structural check, separate from the data ones below.
      for (final version in GeneratedHelper.versions) {
        final connection = await verifier.startAt(version);
        final db = AppDatabase(connection);
        await verifier.migrateAndValidate(db, 7);
        await db.close();
      }
    });

    test('preserves training data and backfills loggedAt', () async {
      final schema = await verifier.schemaAt(1);

      // ---- a realistic v1 database ----
      final oldDb = v1.DatabaseAtV1(schema.newConnection());

      await oldDb
          .into(oldDb.planDays)
          .insert(
            RawValuesInsertable({
              'id': const Variable<int>(1),
              'day_key': Variable<String>(PlanDayKey.lowerA.name),
              'name': const Variable<String>('Lower A — Quad/Glute + Plyo'),
              'order_index': const Variable<int>(0),
            }),
          );

      await oldDb
          .into(oldDb.exercises)
          .insert(
            RawValuesInsertable({
              'id': const Variable<int>(1),
              'name': const Variable<String>('Back Squat'),
              'pattern': Variable<String>(MovementPattern.squat.name),
              'equipment': const Variable<String>('barbell'),
              'is_unilateral': const Variable<int>(0),
            }),
          );

      await oldDb
          .into(oldDb.planItems)
          .insert(
            RawValuesInsertable({
              'id': const Variable<int>(1),
              'plan_day_id': const Variable<int>(1),
              'exercise_id': const Variable<int>(1),
              'block': Variable<String>(TrainingBlock.main.name),
              'target_sets': const Variable<int>(4),
              'rep_low': const Variable<int>(6),
              'rep_high': const Variable<int>(8),
            }),
          );

      // Two sessions with different start times: a backfill that is not
      // correlated per row would give both workouts' sets the same loggedAt.
      await oldDb
          .into(oldDb.workouts)
          .insert(
            RawValuesInsertable({
              'id': const Variable<int>(1),
              'date': Variable<int>(_epoch(_firstDate)),
              'plan_day_id': const Variable<int>(1),
              'started_at': Variable<int>(_epoch(_firstStartedAt)),
              'ended_at': Variable<int>(_epoch(_firstEndedAt)),
              'notes': const Variable<String>('Felt strong.'),
            }),
          );

      // Deliberately left unfinished, to prove a null ended_at survives.
      await oldDb
          .into(oldDb.workouts)
          .insert(
            RawValuesInsertable({
              'id': const Variable<int>(2),
              'date': Variable<int>(_epoch(_secondDate)),
              'plan_day_id': const Variable<int>(1),
              'started_at': Variable<int>(_epoch(_secondStartedAt)),
            }),
          );

      // A loaded working set, an unloaded one (weight_kg NULL is meaningful —
      // it is what keeps bodyweight work out of the 1RM trend), and a warm-up.
      await oldDb
          .into(oldDb.setLogs)
          .insert(
            const RawValuesInsertable({
              'id': Variable<int>(1),
              'workout_id': Variable<int>(1),
              'exercise_id': Variable<int>(1),
              'set_index': Variable<int>(1),
              'weight_kg': Variable<double>(60.5),
              'reps': Variable<int>(8),
              'rir': Variable<int>(2),
              'is_warmup': Variable<int>(0),
            }),
          );
      await oldDb
          .into(oldDb.setLogs)
          .insert(
            const RawValuesInsertable({
              'id': Variable<int>(2),
              'workout_id': Variable<int>(1),
              'exercise_id': Variable<int>(1),
              'set_index': Variable<int>(2),
              'weight_kg': Variable<double>(null),
              'reps': Variable<int>(12),
              'is_warmup': Variable<int>(1),
            }),
          );
      await oldDb
          .into(oldDb.setLogs)
          .insert(
            const RawValuesInsertable({
              'id': Variable<int>(3),
              'workout_id': Variable<int>(2),
              'exercise_id': Variable<int>(1),
              'set_index': Variable<int>(1),
              'weight_kg': Variable<double>(62.5),
              'reps': Variable<int>(6),
              'is_warmup': Variable<int>(0),
            }),
          );

      await oldDb.close();

      // ---- migrate with the real database ----
      final migrated = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(migrated, 7);
      await migrated.close();

      // ---- read it back through the real, typed API ----
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);

      final planDay = await db.planDao.dayByKey(PlanDayKey.lowerA);
      expect(planDay, isNotNull);
      expect(planDay!.name, 'Lower A — Quad/Glute + Plyo');
      expect(
        await db.select(db.planDays).get(),
        hasLength(1),
        reason: 'the seed must not run over a database that already has a plan',
      );

      final exercise = await db.planDao.exerciseById(1);
      expect(exercise!.name, 'Back Squat');
      expect(exercise.pattern, MovementPattern.squat);
      expect(exercise.isUnilateral, isFalse);

      final workouts = await db.select(db.workouts).get()
        ..sort((a, b) => a.id.compareTo(b.id));
      expect(workouts, hasLength(2));
      expect(workouts.first.startedAt, _firstStartedAt);
      expect(workouts.first.endedAt, _firstEndedAt);
      expect(workouts.first.notes, 'Felt strong.');
      expect(workouts.last.endedAt, isNull);

      final sets = await db.select(db.setLogs).get()
        ..sort((a, b) => a.id.compareTo(b.id));
      expect(sets, hasLength(3));

      expect(sets[0].weightKg, 60.5);
      expect(sets[0].reps, 8);
      expect(sets[0].rir, 2);
      expect(sets[0].isWarmup, isFalse);

      expect(
        sets[1].weightKg,
        isNull,
        reason: 'an unloaded set must not be zero-filled by the migration',
      );
      expect(sets[1].isWarmup, isTrue);
      expect(sets[1].rir, isNull);

      expect(sets[2].weightKg, 62.5);

      // The point of the v2 step: every pre-existing set is timestamped from
      // its own workout, so the two sessions do not collapse onto one time.
      expect(sets[0].loggedAt, _firstStartedAt);
      expect(sets[1].loggedAt, _firstStartedAt);
      expect(sets[2].loggedAt, _secondStartedAt);
    });
  });

  group('v2 to v7', () {
    test('keeps existing loggedAt values and adds warm-up checks', () async {
      final schema = await verifier.schemaAt(2);
      final oldDb = v2.DatabaseAtV2(schema.newConnection());

      await oldDb
          .into(oldDb.planDays)
          .insert(
            RawValuesInsertable({
              'id': const Variable<int>(1),
              'day_key': Variable<String>(PlanDayKey.upperB.name),
              'name': const Variable<String>('Upper B — Horizontal Focus'),
              'order_index': const Variable<int>(3),
            }),
          );

      await oldDb
          .into(oldDb.exercises)
          .insert(
            RawValuesInsertable({
              'id': const Variable<int>(1),
              'name': const Variable<String>('Bench Press'),
              'pattern': Variable<String>(MovementPattern.press.name),
              'equipment': const Variable<String>('barbell'),
              'is_unilateral': const Variable<int>(0),
            }),
          );

      await oldDb
          .into(oldDb.planItems)
          .insert(
            RawValuesInsertable({
              'id': const Variable<int>(1),
              'plan_day_id': const Variable<int>(1),
              'block': Variable<String>(TrainingBlock.warmup.name),
              'notes': const Variable<String>(
                'Band pull-aparts — 2 × 20\nDoorway pec stretch — 30 sec/side',
              ),
            }),
          );

      await oldDb
          .into(oldDb.workouts)
          .insert(
            RawValuesInsertable({
              'id': const Variable<int>(1),
              'date': Variable<int>(_epoch(_firstDate)),
              'plan_day_id': const Variable<int>(1),
              'started_at': Variable<int>(_epoch(_firstStartedAt)),
              'ended_at': Variable<int>(_epoch(_firstEndedAt)),
            }),
          );

      // A real per-set time, deliberately unlike the workout's startedAt: the
      // v3 step must not re-run the v2 backfill over rows that already have
      // a true timestamp.
      await oldDb
          .into(oldDb.setLogs)
          .insert(
            RawValuesInsertable({
              'id': const Variable<int>(1),
              'workout_id': const Variable<int>(1),
              'exercise_id': const Variable<int>(1),
              'set_index': const Variable<int>(1),
              'weight_kg': const Variable<double>(80),
              'reps': const Variable<int>(5),
              'is_warmup': const Variable<int>(0),
              'logged_at': Variable<int>(_epoch(_setLoggedAt)),
            }),
          );

      await oldDb.close();

      final migrated = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(migrated, 7);
      await migrated.close();

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);

      final set = (await db.select(db.setLogs).get()).single;
      expect(set.weightKg, 80);
      expect(
        set.loggedAt,
        _setLoggedAt,
        reason: 'a set that already had a real timestamp keeps it',
      );
      expect(set.loggedAt, isNot(_firstStartedAt));

      // The table v3 introduces is present and usable, with its cascade wired
      // to the workout it belongs to.
      await db.workoutDao.setWarmupCheck(
        workoutId: 1,
        planItemId: 1,
        lineIndex: 1,
        isChecked: true,
      );
      expect(await db.workoutDao.watchWarmupChecks(1).first, hasLength(1));

      await db.workoutDao.deleteWorkout(1);
      expect(await db.select(db.warmupChecks).get(), isEmpty);
    });
  });

  group('v3 to v4', () {
    // v3 shipped with `m.createTable(warmupChecks)`, which writes the table
    // but not its `@TableIndex` — so "a database at v3" means one of two
    // different schemas, and the repair has to land on both.
    test('creates the index a v3 upgrade left behind', () async {
      final schema = await verifier.schemaAt(2);
      final oldDb = v2.DatabaseAtV2(schema.newConnection());
      await oldDb.close();

      final migrated = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(migrated, 7);
      await migrated.close();

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      expect(await _indexNames(db), contains('idx_warmup_checks_workout'));
    });

    test('is a no-op on a v3 that was created fresh, index and all', () async {
      // `schemaAt(3)` builds v3 the way `onCreate` does, so the index is
      // already there. A bare CREATE INDEX would throw here.
      final schema = await verifier.schemaAt(3);

      final migrated = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(migrated, 7);
      await migrated.close();

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      expect(
        (await _indexNames(
          db,
        )).where((name) => name == 'idx_warmup_checks_workout'),
        hasLength(1),
      );
    });
  });

  group('v4 to v7', () {
    test('adds the settings store without disturbing daily_steps', () async {
      final schema = await verifier.schemaAt(4);
      final oldDb = v4.DatabaseAtV4(schema.newConnection());

      // daily_steps has existed since v1, so M4 stores into a table that may
      // already hold rows. They have to survive the version that finally
      // gives the feature somewhere to keep its settings.
      await oldDb
          .into(oldDb.dailySteps)
          .insert(
            RawValuesInsertable({
              'date': Variable<int>(_epoch(_firstDate)),
              'steps': const Variable<int>(9137),
              'active_kcal': const Variable<double>(412.5),
              'source': const Variable<String>('health_connect'),
            }),
          );

      await oldDb.close();

      final migrated = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(migrated, 7);
      await migrated.close();

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);

      final day = await db.stepsDao.forDate(_firstDate);
      expect(day, isNotNull);
      expect(day!.steps, 9137);
      expect(day.activeKcal, 412.5);

      // The settings store v5 adds is present, empty, and writable. Read back
      // through the DAO rather than a typed wrapper: the key/value table is
      // what the migration creates, and it outlives whatever reads it.
      expect(await db.preferencesDao.read('steps.target'), isNull);

      await db.preferencesDao.write('steps.target', '12000');
      expect(await db.preferencesDao.read('steps.target'), '12000');
    });
  });

  group('v5 to v7', () {
    test(
      'drops photos for good, and lands on v7 with the run tables back',
      () async {
        final schema = await verifier.schemaAt(5);
        final oldDb = v5.DatabaseAtV5(schema.newConnection());

        // A season of real data across every group that has to survive.
        await oldDb
            .into(oldDb.planDays)
            .insert(
              RawValuesInsertable({
                'id': const Variable<int>(1),
                'day_key': Variable<String>(PlanDayKey.lowerB.name),
                'name': const Variable<String>('Lower B — Hinge/Posterior'),
                'order_index': const Variable<int>(2),
              }),
            );
        await oldDb
            .into(oldDb.exercises)
            .insert(
              RawValuesInsertable({
                'id': const Variable<int>(1),
                'name': const Variable<String>('Smith machine RDL'),
                'pattern': Variable<String>(MovementPattern.hinge.name),
                'equipment': const Variable<String>('smith machine'),
                'is_unilateral': const Variable<int>(0),
              }),
            );
        await oldDb
            .into(oldDb.workouts)
            .insert(
              RawValuesInsertable({
                'id': const Variable<int>(1),
                'date': Variable<int>(_epoch(_firstDate)),
                'plan_day_id': const Variable<int>(1),
                'started_at': Variable<int>(_epoch(_firstStartedAt)),
                'ended_at': Variable<int>(_epoch(_firstEndedAt)),
              }),
            );
        await oldDb
            .into(oldDb.setLogs)
            .insert(
              RawValuesInsertable({
                'id': const Variable<int>(1),
                'workout_id': const Variable<int>(1),
                'exercise_id': const Variable<int>(1),
                'set_index': const Variable<int>(1),
                'weight_kg': const Variable<double>(72.5),
                'reps': const Variable<int>(9),
                'is_warmup': const Variable<int>(0),
                'logged_at': Variable<int>(_epoch(_setLoggedAt)),
              }),
            );
        await oldDb
            .into(oldDb.dailySteps)
            .insert(
              RawValuesInsertable({
                'date': Variable<int>(_epoch(_firstDate)),
                'steps': const Variable<int>(11402),
                'active_kcal': const Variable<double>(507.25),
                'source': const Variable<String>('health_connect'),
              }),
            );
        // The whole point of the exception: measurements is the one table of
        // the three unbuilt groups that was NOT cut, because weight and waist
        // are tracked weekly.
        await oldDb
            .into(oldDb.measurements)
            .insert(
              RawValuesInsertable({
                'id': const Variable<int>(1),
                'date': Variable<int>(_epoch(_firstDate)),
                'weight_kg': const Variable<double>(66.65),
                'waist_cm': const Variable<double>(78.5),
                'broad_jump_cm': const Variable<double>(212),
              }),
            );
        await oldDb
            .into(oldDb.preferences)
            .insert(
              const RawValuesInsertable({
                'key': Variable<String>('steps.target'),
                'value': Variable<String>('9000'),
              }),
            );

        // Rows in the doomed tables. Nothing in the app ever wrote one, but the
        // DROP has to cope with a populated table and with run_points/splits
        // still referencing runs.
        await oldDb
            .into(oldDb.runs)
            .insert(
              RawValuesInsertable({
                'id': const Variable<int>(1),
                'started_at': Variable<int>(_epoch(_firstStartedAt)),
                'ended_at': Variable<int>(_epoch(_firstEndedAt)),
                'distance_m': const Variable<double>(5120),
                'moving_s': const Variable<int>(1680),
                'elapsed_s': const Variable<int>(1725),
                'elev_gain_m': const Variable<double>(34),
                'avg_pace_s_per_km': const Variable<double>(328),
                'polyline': const Variable<String>('_p~iF~ps|U'),
              }),
            );
        await oldDb
            .into(oldDb.runPoints)
            .insert(
              RawValuesInsertable({
                'id': const Variable<int>(1),
                'run_id': const Variable<int>(1),
                'lat': const Variable<double>(12.97),
                'lon': const Variable<double>(77.59),
                'elev_m': const Variable<double>(920),
                'timestamp': Variable<int>(_epoch(_firstStartedAt)),
                'accuracy_m': const Variable<double>(4.5),
                'speed_mps': const Variable<double>(3.1),
              }),
            );
        await oldDb
            .into(oldDb.splits)
            .insert(
              const RawValuesInsertable({
                'id': Variable<int>(1),
                'run_id': Variable<int>(1),
                'km': Variable<int>(1),
                'duration_s': Variable<int>(322),
                'elev_delta_m': Variable<double>(6.5),
              }),
            );
        await oldDb
            .into(oldDb.photos)
            .insert(
              RawValuesInsertable({
                'id': const Variable<int>(1),
                'taken_at': Variable<int>(_epoch(_firstDate)),
                'pose': const Variable<String>('front'),
                'file_path': const Variable<String>('/data/photos/1.jpg'),
              }),
            );

        await oldDb.close();

        final migrated = AppDatabase(schema.newConnection());
        await verifier.migrateAndValidate(migrated, 7);
        await migrated.close();

        final db = AppDatabase(schema.newConnection());
        addTearDown(db.close);

        final tables = await _tableNames(db);
        expect(
          tables,
          isNot(contains('photos')),
          reason: 'progress photos stayed cut',
        );
        expect(
          tables,
          containsAll(<String>['runs', 'run_points', 'splits']),
          reason:
              'v6 dropped the run tables and v7 brings them back, so a '
              'database migrating across both ends up with them again',
        );
        expect(
          await db.select(db.runs).get(),
          isEmpty,
          reason: 'the v6 drop is not undone — the rows it destroyed are gone',
        );
        expect(
          tables,
          containsAll(<String>[
            'measurements',
            'daily_steps',
            'workouts',
            'set_logs',
            'exercises',
            'plan_days',
            'plan_items',
            'warmup_checks',
            'preferences',
            'foods',
          ]),
        );

        // Measurements survived the drop happening around it, values intact.
        final measurement = (await db.select(db.measurements).get()).single;
        expect(measurement.weightKg, 66.65);
        expect(measurement.waistCm, 78.5);
        expect(measurement.broadJumpCm, 212);
        expect(measurement.date, _firstDate);

        // Training data.
        final workout = (await db.select(db.workouts).get()).single;
        expect(workout.startedAt, _firstStartedAt);
        expect(workout.endedAt, _firstEndedAt);

        final set = (await db.select(db.setLogs).get()).single;
        expect(set.weightKg, 72.5);
        expect(set.reps, 9);
        expect(set.loggedAt, _setLoggedAt);

        final planDay = await db.planDao.dayByKey(PlanDayKey.lowerB);
        expect(planDay!.name, 'Lower B — Hinge/Posterior');
        expect(
          await db.select(db.planDays).get(),
          hasLength(1),
          reason:
              'the seed must not run over a database that already has a plan',
        );

        // Steps and settings.
        final day = await db.stepsDao.forDate(_firstDate);
        expect(day!.steps, 11402);
        expect(day.activeKcal, 507.25);
        expect(await db.preferencesDao.read('steps.target'), '9000');

        final indexes = await _indexNames(db);
        expect(
          indexes,
          containsAll(<String>[
            'idx_set_logs_workout',
            'idx_set_logs_exercise',
            'idx_warmup_checks_workout',
            // Re-created by v7, explicitly. `createTable` would have left these
            // out — the v3/v4 lesson.
            'idx_runs_started_at',
            'idx_run_points_run',
          ]),
        );
      },
    );
  });

  group('v6 to v7', () {
    test('re-adds the run tables and disturbs nothing else', () async {
      final schema = await verifier.schemaAt(6);
      final oldDb = v6.DatabaseAtV6(schema.newConnection());

      // Everything a real device holds at v6, so the assertion is that a
      // season of training survives a schema change made for another feature
      // entirely.
      await oldDb
          .into(oldDb.planDays)
          .insert(
            RawValuesInsertable({
              'id': const Variable<int>(1),
              'day_key': Variable<String>(PlanDayKey.upperA.name),
              'name': const Variable<String>('Upper A — Vertical Focus'),
              'order_index': const Variable<int>(1),
            }),
          );
      await oldDb
          .into(oldDb.exercises)
          .insert(
            RawValuesInsertable({
              'id': const Variable<int>(1),
              'name': const Variable<String>('Lat pulldown'),
              'pattern': Variable<String>(MovementPattern.pull.name),
              'equipment': const Variable<String>('cable'),
              'is_unilateral': const Variable<int>(0),
            }),
          );
      await oldDb
          .into(oldDb.workouts)
          .insert(
            RawValuesInsertable({
              'id': const Variable<int>(1),
              'date': Variable<int>(_epoch(_firstDate)),
              'plan_day_id': const Variable<int>(1),
              'started_at': Variable<int>(_epoch(_firstStartedAt)),
              'ended_at': Variable<int>(_epoch(_firstEndedAt)),
              'notes': const Variable<String>('Grip gave out.'),
            }),
          );
      // A loaded set and an unloaded one: the null weight is the value most
      // likely to be quietly zero-filled by a careless migration.
      await oldDb
          .into(oldDb.setLogs)
          .insert(
            RawValuesInsertable({
              'id': const Variable<int>(1),
              'workout_id': const Variable<int>(1),
              'exercise_id': const Variable<int>(1),
              'set_index': const Variable<int>(1),
              'weight_kg': const Variable<double>(47.5),
              'reps': const Variable<int>(10),
              'rir': const Variable<int>(1),
              'is_warmup': const Variable<int>(0),
              'logged_at': Variable<int>(_epoch(_setLoggedAt)),
            }),
          );
      await oldDb
          .into(oldDb.setLogs)
          .insert(
            RawValuesInsertable({
              'id': const Variable<int>(2),
              'workout_id': const Variable<int>(1),
              'exercise_id': const Variable<int>(1),
              'set_index': const Variable<int>(2),
              'weight_kg': const Variable<double>(null),
              'reps': const Variable<int>(15),
              'is_warmup': const Variable<int>(1),
              'logged_at': Variable<int>(_epoch(_setLoggedAt)),
            }),
          );
      await oldDb
          .into(oldDb.warmupChecks)
          .insert(
            const RawValuesInsertable({
              'id': Variable<int>(1),
              'workout_id': Variable<int>(1),
              'plan_item_id': Variable<int>(1),
              'line_index': Variable<int>(0),
            }),
          );
      await oldDb
          .into(oldDb.dailySteps)
          .insert(
            RawValuesInsertable({
              'date': Variable<int>(_epoch(_firstDate)),
              'steps': const Variable<int>(8241),
              'active_kcal': const Variable<double>(366.75),
              'source': const Variable<String>('health_connect'),
            }),
          );
      await oldDb
          .into(oldDb.measurements)
          .insert(
            RawValuesInsertable({
              'id': const Variable<int>(1),
              'date': Variable<int>(_epoch(_firstDate)),
              'weight_kg': const Variable<double>(67.4),
              'waist_cm': const Variable<double>(77.25),
              'broad_jump_cm': const Variable<double>(218),
            }),
          );
      await oldDb
          .into(oldDb.preferences)
          .insert(
            const RawValuesInsertable({
              'key': Variable<String>('steps.target'),
              'value': Variable<String>('8000'),
            }),
          );

      await oldDb.close();

      final migrated = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(migrated, 7);
      await migrated.close();

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);

      // ---- nothing that existed was disturbed ----
      final workout = (await db.select(db.workouts).get()).single;
      expect(workout.startedAt, _firstStartedAt);
      expect(workout.endedAt, _firstEndedAt);
      expect(workout.notes, 'Grip gave out.');

      final sets = await db.select(db.setLogs).get()
        ..sort((a, b) => a.id.compareTo(b.id));
      expect(sets, hasLength(2));
      expect(sets[0].weightKg, 47.5);
      expect(sets[0].reps, 10);
      expect(sets[0].rir, 1);
      expect(sets[0].loggedAt, _setLoggedAt);
      expect(
        sets[1].weightKg,
        isNull,
        reason: 'an unloaded set must not be zero-filled by the migration',
      );
      expect(sets[1].isWarmup, isTrue);

      expect(await db.workoutDao.watchWarmupChecks(1).first, hasLength(1));

      final planDay = await db.planDao.dayByKey(PlanDayKey.upperA);
      expect(planDay!.name, 'Upper A — Vertical Focus');
      expect(
        await db.select(db.planDays).get(),
        hasLength(1),
        reason: 'the seed must not run over a database that already has a plan',
      );

      final day = await db.stepsDao.forDate(_firstDate);
      expect(day!.steps, 8241);
      expect(day.activeKcal, 366.75);

      final measurement = (await db.select(db.measurements).get()).single;
      expect(measurement.weightKg, 67.4);
      expect(measurement.waistCm, 77.25);
      expect(measurement.broadJumpCm, 218);

      expect(await db.preferencesDao.read('steps.target'), '8000');

      // ---- and the run tables are back, usable, with their indexes ----
      expect(
        await _tableNames(db),
        containsAll(<String>['runs', 'run_points', 'splits']),
      );
      expect(
        await _indexNames(db),
        containsAll(<String>['idx_runs_started_at', 'idx_run_points_run']),
        reason:
            'createTable does not create @TableIndex entries — v7 issues '
            'the CREATE INDEX statements itself, which is the v3/v4 lesson',
      );

      // Writable end to end, including the columns that exist ahead of the
      // feature that fills them, and the cascade the child tables rely on.
      final runId = await db
          .into(db.runs)
          .insert(
            RunsCompanion.insert(
              startedAt: _firstStartedAt,
              distanceM: 5500,
              movingS: 1980,
              elapsedS: 2040,
              avgPaceSPerKm: 360,
            ),
          );
      await db
          .into(db.runPoints)
          .insert(
            RunPointsCompanion.insert(
              runId: runId,
              lat: 12.9716,
              lon: 77.5946,
              timestamp: _firstStartedAt,
            ),
          );
      await db
          .into(db.splits)
          .insert(
            SplitsCompanion.insert(
              runId: runId,
              km: 6,
              durationS: 180,
              distanceM: 500,
              isPartial: const Value(true),
            ),
          );

      final run = (await db.select(db.runs).get()).single;
      expect(run.endedAt, isNull, reason: 'a run in progress has no end');
      expect(
        run.elevGainM,
        isNull,
        reason: 'climb is not computed from GPS altitude — A6 fills this',
      );
      expect(run.polyline, isNull);
      expect(run.avgHrBpm, isNull, reason: 'A7 fills this over BLE');
      expect(run.maxHrBpm, isNull);

      final point = (await db.select(db.runPoints).get()).single;
      expect(
        point.elevM,
        isNull,
        reason:
            'a horizontal-only fix carries no altitude, and zero would be '
            'a lie about sea level',
      );
      expect(point.accuracyM, isNull);
      expect(point.speedMps, isNull);

      final split = (await db.select(db.splits).get()).single;
      expect(split.isPartial, isTrue);
      expect(split.distanceM, 500);

      await db.delete(db.runs).go();
      expect(
        await db.select(db.runPoints).get(),
        isEmpty,
        reason: 'run_points cascades with its run',
      );
      expect(await db.select(db.splits).get(), isEmpty);
    });
  });
}

/// The tables SQLite actually holds.
Future<List<String>> _tableNames(AppDatabase db) async {
  final rows = await db
      .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
      .get();
  return rows.map((row) => row.read<String>('name')).toList();
}

/// The indexes SQLite actually holds, as opposed to the ones drift declares.
Future<List<String>> _indexNames(AppDatabase db) async {
  final rows = await db
      .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
      .get();
  return rows.map((row) => row.read<String>('name')).toList();
}

final _firstDate = DateTime(2026, 8, 10);
final _firstStartedAt = DateTime(2026, 8, 10, 18, 12, 30);
final _firstEndedAt = DateTime(2026, 8, 10, 19, 21);
final _secondDate = DateTime(2026, 8, 13);
final _secondStartedAt = DateTime(2026, 8, 13, 7, 45);
final _setLoggedAt = DateTime(2026, 8, 10, 18, 40, 15);

/// Drift stores `DateTime` as whole seconds since the epoch by default, and
/// the generated per-version schemas expose those columns as plain ints.
int _epoch(DateTime value) => value.millisecondsSinceEpoch ~/ 1000;
