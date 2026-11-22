import 'package:drift/drift.dart';
import 'package:fitness_tracker/data/models/training_enums.dart';

/// A movement. Names are unique so seeding is idempotent.
class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get pattern => textEnum<MovementPattern>()();
  TextColumn get equipment => text()();
  BoolColumn get isUnilateral => boolean().withDefault(const Constant(false))();
}

/// One of the four Phase 1 sessions.
class PlanDays extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get dayKey => textEnum<PlanDayKey>().unique()();
  TextColumn get name => text()();
  IntColumn get orderIndex => integer()();
}

/// A prescribed row of a session.
///
/// [exerciseId] is null exactly for warm-up checklists, which prescribe work
/// but produce no set logs; their whole prescription lives in [notes]. The rep
/// range is additionally null for duration-based plyometrics, where the
/// seconds are in [notes].
class PlanItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planDayId =>
      integer().references(PlanDays, #id, onDelete: KeyAction.cascade)();
  IntColumn get exerciseId => integer().nullable().references(Exercises, #id)();
  TextColumn get block => textEnum<TrainingBlock>()();
  IntColumn get targetSets => integer().nullable()();
  IntColumn get repLow => integer().nullable()();
  IntColumn get repHigh => integer().nullable()();
  TextColumn get notes => text().nullable()();
}

/// A training session that actually happened.
class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get planDayId => integer().nullable().references(PlanDays, #id)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
}

/// A ticked-off line of a warm-up checklist.
///
/// A row's existence *is* the tick — unticking deletes it — which keeps the
/// table free of rows recording that nothing happened.
///
/// The key is (workoutId, planItemId, lineIndex) rather than just the plan
/// item: one warm-up item holds its whole prescription in `notes`, one line
/// per exercise, and each of those lines is a thing you tick. Keying on the
/// workout is what makes the ticks reset for each session instead of staying
/// checked from the last time this warm-up was prescribed.
@TableIndex(name: 'idx_warmup_checks_workout', columns: {#workoutId})
class WarmupChecks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId =>
      integer().references(Workouts, #id, onDelete: KeyAction.cascade)();
  IntColumn get planItemId =>
      integer().references(PlanItems, #id, onDelete: KeyAction.cascade)();

  /// Which line of the item's `notes` was ticked, counting non-blank lines
  /// from zero — the same order the checklist renders in.
  IntColumn get lineIndex => integer()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {workoutId, planItemId, lineIndex},
  ];
}

/// One recorded set.
///
/// [weightKg] is nullable: bodyweight, band and plyometric work carries no
/// load, and storing zero there would drag an estimated-1RM trend to the floor.
/// Null-weight exercises are excluded from 1RM charts and shown as a volume
/// trend instead.
///
/// On a unilateral exercise, one row is still one set, and [reps] counts reps
/// **per side**.
@TableIndex(name: 'idx_set_logs_workout', columns: {#workoutId})
@TableIndex(name: 'idx_set_logs_exercise', columns: {#exerciseId})
class SetLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId =>
      integer().references(Workouts, #id, onDelete: KeyAction.cascade)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get setIndex => integer()();
  RealColumn get weightKg => real().nullable()();
  IntColumn get reps => integer()();
  IntColumn get rir => integer().nullable()();
  BoolColumn get isWarmup => boolean().withDefault(const Constant(false))();

  /// Wall-clock time the set was recorded.
  ///
  /// Needed to close out a workout that was left open — the session really
  /// ended at its last set, not whenever the app next launched.
  ///
  /// Nullable only because it arrived in schema v2: `ALTER TABLE ADD COLUMN`
  /// cannot fill a NOT NULL column on existing rows, so the migration adds it
  /// nullable and backfills from the parent workout's `startedAt`. Every
  /// insert since v2 supplies it, so null never appears on new rows.
  DateTimeColumn get loggedAt => dateTime().nullable()();
}
