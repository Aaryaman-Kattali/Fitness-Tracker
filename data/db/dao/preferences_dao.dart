import 'package:drift/drift.dart';
import 'package:fitness_tracker/data/db/app_database.dart';
import 'package:fitness_tracker/data/db/tables/settings_tables.dart';

part 'preferences_dao.g.dart';

/// Raw key/value access to [Preferences]. Typing lives one layer up.
@DriftAccessor(tables: [Preferences])
class PreferencesDao extends DatabaseAccessor<AppDatabase>
    with _$PreferencesDaoMixin {
  PreferencesDao(super.attachedDatabase);

  Future<String?> read(String key) async {
    final row = await (select(
      preferences,
    )..where((p) => p.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  /// Emits on every change to [key], starting with its current value.
  Stream<String?> watch(String key) => (select(
    preferences,
  )..where((p) => p.key.equals(key))).watchSingleOrNull().map((r) => r?.value);

  Future<void> write(String key, String value) => into(preferences).insert(
    PreferencesCompanion.insert(key: key, value: value),
    mode: InsertMode.insertOrReplace,
  );
}
