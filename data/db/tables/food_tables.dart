import 'package:drift/drift.dart';

/// Where a food record came from.
enum FoodSource { indb, usda, off, user }

/// Which meal a log entry belongs to.
enum Meal { breakfast, lunch, snack, dinner }

/// Nutrition facts per 100 g.
///
/// Defined now so the schema is stable; the DAO and the food pipeline arrive
/// in M3.
class Foods extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get nameLocal => text().nullable()();
  TextColumn get brand => text().nullable()();
  TextColumn get source => textEnum<FoodSource>()();
  TextColumn get barcode => text().nullable()();
  BoolColumn get isRecipe => boolean().withDefault(const Constant(false))();
  RealColumn get kcal100 => real()();
  RealColumn get protein100 => real()();
  RealColumn get carbs100 => real()();
  RealColumn get fat100 => real()();
  RealColumn get fibre100 => real()();
  RealColumn get sugar100 => real().nullable()();
  RealColumn get satFat100 => real().nullable()();
  RealColumn get sodium100 => real().nullable()();
}

/// Household serving sizes ("1 katori", "1 medium roti").
class Servings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get foodId =>
      integer().references(Foods, #id, onDelete: KeyAction.cascade)();
  TextColumn get label => text()();
  RealColumn get grams => real()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
}

/// Ingredients of a recipe food.
class RecipeItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get recipeFoodId =>
      integer().references(Foods, #id, onDelete: KeyAction.cascade)();
  IntColumn get ingredientFoodId => integer().references(Foods, #id)();
  RealColumn get grams => real()();
}

/// A logged food entry.
@TableIndex(name: 'idx_food_logs_date', columns: {#date})
class FoodLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get meal => textEnum<Meal>()();
  IntColumn get foodId => integer().references(Foods, #id)();
  RealColumn get grams => real()();
  DateTimeColumn get loggedAt => dateTime()();
}
