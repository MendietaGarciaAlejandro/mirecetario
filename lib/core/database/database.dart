import 'package:drift/drift.dart';

part 'database.g.dart';

class Recipes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get ingredients => text()(); // JSON string
  TextColumn get instructions => text()(); // JSON string
  IntColumn get servings => integer()();
  IntColumn get cookingTime => integer()(); // en minutos
  TextColumn get category => text()();
  TextColumn get imageUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class MealPlan extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get recipeId => integer().references(Recipes, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get mealType => text()(); // desayuno, almuerzo, cena
}

class ShoppingList extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get item => text()();
  RealColumn get quantity => real()();
  TextColumn get unit => text()();
  BoolColumn get checked => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [Recipes, MealPlan, ShoppingList])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  // Métodos básicos para Recipes
  Future<List<Recipe>> getAllRecipes() => select(recipes).get();
  Future<Recipe> getRecipe(int id) => (select(recipes)..where((r) => r.id.equals(id))).getSingle();
  Future<int> addRecipe(RecipesCompanion recipe) => into(recipes).insert(recipe);
  Future<bool> updateRecipe(Recipe recipe) => update(recipes).replace(recipe);
  Future<int> deleteRecipe(int id) => (delete(recipes)..where((r) => r.id.equals(id))).go();

  // Métodos para MealPlan
  Future<List<MealPlanData>> getMealPlan(DateTime start, DateTime end) =>
      (select(mealPlan)..where((m) => m.date.isBetweenValues(start, end))).get();
  Future<int> addToMealPlan(MealPlanCompanion meal) => into(mealPlan).insert(meal);
  Future<int> removeMealPlan(int id) => (delete(mealPlan)..where((m) => m.id.equals(id))).go();

  // Métodos para ShoppingList
  Future<List<ShoppingListData>> getShoppingList() => select(shoppingList).get();
  Future<int> addToShoppingList(ShoppingListCompanion item) => into(shoppingList).insert(item);
  Future<bool> updateShoppingListItem(ShoppingListData item) => update(shoppingList).replace(item);
  Future<int> removeFromShoppingList(int id) => (delete(shoppingList)..where((s) => s.id.equals(id))).go();
}
