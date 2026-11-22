import 'package:drift/drift.dart';

/// A recorded run.
///
/// Re-added in schema v7 after being dropped in v6, when GPS was cut from
/// scope and then put back. The shape is v1's, with one rule applied
/// throughout: a column whose producing feature is not built yet is
/// **nullable**, never zero-filled. The precedent is `SetLogs.weightKg` —
/// zero is a value something downstream will average, whereas null is the
/// honest record that nothing measured it.
@TableIndex(name: 'idx_runs_started_at', columns: {#startedAt})
class Runs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startedAt => dateTime()();

  /// Null while the run is still being recorded, exactly as `Workouts.endedAt`
  /// is null for a session in progress.
  DateTimeColumn get endedAt => dateTime().nullable()();

  RealColumn get distanceM => real()();
  IntColumn get movingS => integer()();
  IntColumn get elapsedS => integer()();

  /// Null until A6. GPS altitude is ±10–15 m and the A32 has no barometer, so
  /// climb is not computed from it — raw altitude is kept per point in
  /// [RunPoints] and nothing is derived from it yet.
  RealColumn get elevGainM => real().nullable()();

  RealColumn get avgPaceSPerKm => real()();

  /// Encoded polyline, for fast list rendering without loading every point.
  /// Null until A2 draws a map; the points are the source of truth regardless.
  TextColumn get polyline => text().nullable()();

  /// Heart rate lands in A7, over BLE. These two columns exist ahead of that
  /// feature deliberately: a nullable column added during this migration costs
  /// four lines, while adding it later costs a schema v8 and ~1,500
  /// permanently unrecoverable generated lines in `test/generated/`. Recorded
  /// as requirement A1-3 so an audit does not read them as speculation.
  IntColumn get avgHrBpm => integer().nullable()();
  IntColumn get maxHrBpm => integer().nullable()();

  TextColumn get notes => text().nullable()();
}

/// The full GPS track behind a run, as accepted and smoothed by the pipeline.
@TableIndex(name: 'idx_run_points_run', columns: {#runId})
class RunPoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get runId =>
      integer().references(Runs, #id, onDelete: KeyAction.cascade)();
  RealColumn get lat => real()();
  RealColumn get lon => real()();

  /// Raw GPS altitude, stored and not used. Nullable because a horizontal-only
  /// fix genuinely carries no altitude.
  RealColumn get elevM => real().nullable()();

  DateTimeColumn get timestamp => dateTime()();

  /// Both nullable for the same reason: a real fix can arrive without a
  /// reported accuracy or a Doppler speed, and inventing a zero would claim
  /// perfect precision and a dead stop.
  RealColumn get accuracyM => real().nullable()();
  RealColumn get speedMps => real().nullable()();
}

/// Daily step and active-calorie totals from Health Connect.
class DailySteps extends Table {
  DateTimeColumn get date => dateTime()();
  IntColumn get steps => integer()();
  RealColumn get activeKcal => real()();
  TextColumn get source => text()();

  @override
  Set<Column<Object>> get primaryKey => {date};
}

/// Per-kilometre splits of a run.
///
/// The last split of a run is normally short, so [isPartial] marks it rather
/// than leaving a 500 m kilometre to be inferred from the numbers.
class Splits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get runId =>
      integer().references(Runs, #id, onDelete: KeyAction.cascade)();
  IntColumn get km => integer()();
  IntColumn get durationS => integer()();

  /// Metres this split actually covers — 1000 for a whole one, less for the
  /// remainder at the end.
  RealColumn get distanceM => real()();
  BoolColumn get isPartial => boolean().withDefault(const Constant(false))();

  /// Null until A6, for the same reason as `Runs.elevGainM`.
  RealColumn get elevDeltaM => real().nullable()();
}
