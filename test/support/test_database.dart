import 'package:drift/native.dart';
import 'package:fitness_tracker/data/db/app_database.dart';
import 'package:fitness_tracker/data/models/training_enums.dart';
import 'package:fitness_tracker/data/repositories/workout_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// An in-memory database, seeded exactly as the real one is.
///
/// Registered for teardown, so tests never leak a connection.
AppDatabase openTestDatabase() {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}

WorkoutRepository workoutRepositoryFor(AppDatabase db) =>
    WorkoutRepository(db.workoutDao, db.planDao);

/// The seeded plan day id behind [key].
Future<int> planDayIdFor(AppDatabase db, PlanDayKey key) async {
  final day = await db.planDao.dayByKey(key);
  return day!.id;
}

/// The first exercise the seed prescribes, for tests that just need one.
Future<int> anyExerciseId(AppDatabase db) async {
  final exercises = await db.planDao.allExercises();
  return exercises.first.id;
}

Future<List<Workout>> allWorkouts(AppDatabase db) =>
    db.select(db.workouts).get();

Future<List<SetLog>> allSets(AppDatabase db) => db.select(db.setLogs).get();
