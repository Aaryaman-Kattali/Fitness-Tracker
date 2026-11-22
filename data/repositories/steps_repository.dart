import 'package:drift/drift.dart' show Value;
import 'package:fitness_tracker/data/db/app_database.dart';
import 'package:fitness_tracker/data/db/dao/steps_dao.dart';
import 'package:fitness_tracker/data/models/health_models.dart';
import 'package:fitness_tracker/data/repositories/health_repository.dart';

/// How a sync attempt ended.
///
/// The UI needs to tell "there is nothing for today yet" apart from "we were
/// not allowed to look", so a sync reports why it produced nothing rather
/// than just how many rows it wrote.
enum StepsSyncOutcome {
  /// Read succeeded and today's row was written.
  synced,

  /// Read succeeded, but the platform has nothing for the day yet.
  noData,

  /// Permission is not granted, or was revoked since the last sync.
  permissionDenied,

  /// No Health Connect provider to read from.
  unavailable,
}

/// Owns everything about step and active-energy totals.
///
/// Reads from a [HealthRepository] and stores into `DailySteps` through
/// [StepsDao]. The stored rows are the source of truth for the UI, so the ring
/// still renders the last known total when a sync fails or permission goes
/// away.
class StepsRepository {
  const StepsRepository({
    required HealthRepository health,
    required StepsDao dao,
  }) : _health = health,
       _dao = dao;

  final HealthRepository _health;
  final StepsDao _dao;

  Future<HealthAvailability> availability() => _health.availability();

  Future<HealthPermissionStatus> permissionStatus() =>
      _health.permissionStatus();

  /// The stored totals for [date], or null when nothing has been recorded.
  Future<DailyActivity?> forDate(DateTime date) async =>
      _toActivity(await _dao.forDate(date));

  /// Emits the stored totals for [date] and every later change to them.
  Stream<DailyActivity?> watchDate(DateTime date) =>
      _dao.watchDate(date).map(_toActivity);

  /// Shows the Health Connect permission sheet and reports the outcome.
  Future<HealthPermissionStatus> requestPermissions() =>
      _health.requestPermissions();

  /// Pulls today's totals and stores them.
  ///
  /// Safe to call on every resume and every pull-to-refresh: the write is an
  /// upsert keyed on the date, so re-syncing a day replaces its row instead
  /// of adding another.
  ///
  /// Re-checks permission first rather than trusting an earlier answer —
  /// Health Connect grants can be revoked from outside the app at any time,
  /// and this is the only place that would notice.
  Future<StepsSyncOutcome> syncToday({required DateTime today}) async {
    if (!(await _health.availability()).canRead) {
      return StepsSyncOutcome.unavailable;
    }
    if (await _health.permissionStatus() != HealthPermissionStatus.granted) {
      return StepsSyncOutcome.permissionDenied;
    }

    final totals = await _health.dailyTotals(from: today, to: today);
    if (totals.isEmpty) return StepsSyncOutcome.noData;

    await _store(totals);
    return StepsSyncOutcome.synced;
  }

  Future<void> _store(List<DailyActivity> totals) {
    if (totals.isEmpty) return Future<void>.value();
    return _dao.upsertAll(
      totals.map(
        (activity) => DailyStepsCompanion(
          date: Value(StepsDao.dayKey(activity.date)),
          steps: Value(activity.steps),
          activeKcal: Value(activity.activeKcal),
          source: Value(activity.source),
        ),
      ),
    );
  }

  static DailyActivity? _toActivity(DailyStep? row) => row == null
      ? null
      : DailyActivity(
          date: row.date,
          steps: row.steps,
          activeKcal: row.activeKcal,
          source: row.source,
        );
}
