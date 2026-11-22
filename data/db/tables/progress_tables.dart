import 'package:drift/drift.dart';

/// Body measurements, including the broad jump the plan tracks every 4 weeks.
///
/// Weight and waist are tracked weekly per the training plan, so this table
/// survived the scope cut that removed run recording and progress photos.
/// DAO arrives in M6.
class Measurements extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  RealColumn get weightKg => real().nullable()();
  RealColumn get waistCm => real().nullable()();
  RealColumn get chestCm => real().nullable()();
  RealColumn get armCm => real().nullable()();
  RealColumn get thighCm => real().nullable()();
  RealColumn get hipCm => real().nullable()();
  RealColumn get neckCm => real().nullable()();
  RealColumn get broadJumpCm => real().nullable()();
}
