import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mirecetario/core/database/database.dart';
import 'package:mirecetario/features/recipes/presentation/recipes_screen.dart';

final mealPlannerProvider = FutureProvider.family<List<MealPlanData>, DateTime>((ref, weekStart) async {
  final db = ref.watch(appDatabaseProvider);
  final weekEnd = weekStart.add(const Duration(days: 6));
  return db.getMealPlan(weekStart, weekEnd);
});

final addMealToPlanProvider = FutureProvider.family<void, MealPlanCompanion>((ref, meal) async {
  final db = ref.watch(appDatabaseProvider);
  await db.addToMealPlan(meal);
});

final removeMealFromPlanProvider = FutureProvider.family<void, int>((ref, mealId) async {
  final db = ref.watch(appDatabaseProvider);
  await db.removeMealPlan(mealId);
});
