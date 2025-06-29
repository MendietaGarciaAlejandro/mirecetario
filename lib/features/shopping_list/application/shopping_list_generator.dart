import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mirecetario/core/database/database.dart';
import 'package:mirecetario/features/recipes/presentation/recipes_screen.dart';
import 'package:mirecetario/features/meal_planner/application/meal_planner_provider.dart';

final generateShoppingListProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  // Obtener el menú de la semana actual
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 6));
  final meals = await db.getMealPlan(weekStart, weekEnd);
  // Obtener recetas únicas
  final recipeIds = meals.map((m) => m.recipeId).toSet().toList();
  final recipes = <Recipe>[];
  for (final id in recipeIds) {
    recipes.add(await db.getRecipe(id));
  }
  // Limpiar la lista de la compra actual
  await db.delete(db.shoppingList).go();

  // Agrupar ingredientes
  final Map<String, Map<String, double>> grouped = {};
  for (final recipe in recipes) {
    // ingredients es un JSON string: [{"item": "Tomate", "quantity": 2, "unit": "ud"}, ...]
    final List<dynamic> ingredientsList = jsonDecode(recipe.ingredients);
    for (final ing in ingredientsList) {
      final item = (ing['item'] ?? '').toString().trim();
      final unit = (ing['unit'] ?? '').toString().trim();
      final quantity = (ing['quantity'] is num) ? (ing['quantity'] as num).toDouble() : 1.0;
      if (item.isEmpty) continue;
      grouped[item] ??= {};
      grouped[item]![unit] = (grouped[item]![unit] ?? 0) + quantity;
    }
  }
  // Insertar ingredientes agrupados
  for (final item in grouped.keys) {
    for (final unit in grouped[item]!.keys) {
      final quantity = grouped[item]![unit]!;
      await db.addToShoppingList(ShoppingListCompanion(
        item: Value(item),
        quantity: Value(quantity),
        unit: Value(unit),
      ));
    }
  }
});
