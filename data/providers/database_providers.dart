import 'dart:async';

import 'package:fitness_tracker/data/db/app_database.dart';
import 'package:fitness_tracker/data/db/dao/plan_dao.dart';
import 'package:fitness_tracker/data/db/dao/steps_dao.dart';
import 'package:fitness_tracker/data/db/dao/workout_dao.dart';
import 'package:fitness_tracker/data/repositories/health_connect_repository.dart';
import 'package:fitness_tracker/data/repositories/health_repository.dart';
import 'package:fitness_tracker/data/repositories/plan_repository.dart';
import 'package:fitness_tracker/data/repositories/steps_repository.dart';
import 'package:fitness_tracker/data/repositories/workout_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_providers.g.dart';

/// The app's single database connection.
///
/// Overridden in tests with an in-memory executor.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(() => unawaited(db.close()));
  return db;
}

@Riverpod(keepAlive: true)
PlanDao planDao(Ref ref) => ref.watch(appDatabaseProvider).planDao;

@Riverpod(keepAlive: true)
WorkoutDao workoutDao(Ref ref) => ref.watch(appDatabaseProvider).workoutDao;

@Riverpod(keepAlive: true)
PlanRepository planRepository(Ref ref) =>
    PlanRepository(ref.watch(planDaoProvider));

@Riverpod(keepAlive: true)
WorkoutRepository workoutRepository(Ref ref) => WorkoutRepository(
  ref.watch(workoutDaoProvider),
  ref.watch(planDaoProvider),
);

@Riverpod(keepAlive: true)
StepsDao stepsDao(Ref ref) => ref.watch(appDatabaseProvider).stepsDao;

/// The platform-health boundary.
///
/// Overridden with a fake in tests — nothing below this provider is reachable
/// off a device, which is exactly why it is a provider and not a direct
/// construction inside [stepsRepository].
@Riverpod(keepAlive: true)
HealthRepository healthRepository(Ref ref) => HealthConnectRepository();

@Riverpod(keepAlive: true)
StepsRepository stepsRepository(Ref ref) => StepsRepository(
  health: ref.watch(healthRepositoryProvider),
  dao: ref.watch(stepsDaoProvider),
);
