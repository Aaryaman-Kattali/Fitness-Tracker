// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkoutDaoMixin on DatabaseAccessor<AppDatabase> {
  $PlanDaysTable get planDays => attachedDatabase.planDays;
  $WorkoutsTable get workouts => attachedDatabase.workouts;
  $ExercisesTable get exercises => attachedDatabase.exercises;
  $SetLogsTable get setLogs => attachedDatabase.setLogs;
  $PlanItemsTable get planItems => attachedDatabase.planItems;
  $WarmupChecksTable get warmupChecks => attachedDatabase.warmupChecks;
  WorkoutDaoManager get managers => WorkoutDaoManager(this);
}

class WorkoutDaoManager {
  final _$WorkoutDaoMixin _db;
  WorkoutDaoManager(this._db);
  $$PlanDaysTableTableManager get planDays =>
      $$PlanDaysTableTableManager(_db.attachedDatabase, _db.planDays);
  $$WorkoutsTableTableManager get workouts =>
      $$WorkoutsTableTableManager(_db.attachedDatabase, _db.workouts);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db.attachedDatabase, _db.exercises);
  $$SetLogsTableTableManager get setLogs =>
      $$SetLogsTableTableManager(_db.attachedDatabase, _db.setLogs);
  $$PlanItemsTableTableManager get planItems =>
      $$PlanItemsTableTableManager(_db.attachedDatabase, _db.planItems);
  $$WarmupChecksTableTableManager get warmupChecks =>
      $$WarmupChecksTableTableManager(_db.attachedDatabase, _db.warmupChecks);
}
