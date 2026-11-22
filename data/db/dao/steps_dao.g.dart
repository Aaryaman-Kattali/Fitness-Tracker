// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'steps_dao.dart';

// ignore_for_file: type=lint
mixin _$StepsDaoMixin on DatabaseAccessor<AppDatabase> {
  $DailyStepsTable get dailySteps => attachedDatabase.dailySteps;
  StepsDaoManager get managers => StepsDaoManager(this);
}

class StepsDaoManager {
  final _$StepsDaoMixin _db;
  StepsDaoManager(this._db);
  $$DailyStepsTableTableManager get dailySteps =>
      $$DailyStepsTableTableManager(_db.attachedDatabase, _db.dailySteps);
}
