import 'package:drift/drift.dart';

/// User-editable settings, as a key/value store.
///
/// A table rather than a column-per-setting: settings arrive one at a time
/// across milestones, and a new key should not cost a schema version. Values
/// are stored as text and parsed by `SettingsRepository`, which owns the
/// typing — the database deliberately knows nothing about what a key means.
///
/// Only keys the user can actually change belong here. Anything derived, or
/// constant for the life of the app, stays in Dart.
class Preferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
