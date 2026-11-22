// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_dao.dart';

// ignore_for_file: type=lint
mixin _$PlanDaoMixin on DatabaseAccessor<AppDatabase> {
  $PlanDaysTable get planDays => attachedDatabase.planDays;
  $ExercisesTable get exercises => attachedDatabase.exercises;
  $PlanItemsTable get planItems => attachedDatabase.planItems;
  PlanDaoManager get managers => PlanDaoManager(this);
}

class PlanDaoManager {
  final _$PlanDaoMixin _db;
  PlanDaoManager(this._db);
  $$PlanDaysTableTableManager get planDays =>
      $$PlanDaysTableTableManager(_db.attachedDatabase, _db.planDays);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db.attachedDatabase, _db.exercises);
  $$PlanItemsTableTableManager get planItems =>
      $$PlanItemsTableTableManager(_db.attachedDatabase, _db.planItems);
}
