import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mirecetario/gen_l10n/app_localizations.dart';
import 'package:mirecetario/features/meal_planner/application/meal_planner_provider.dart';
import 'package:mirecetario/features/recipes/presentation/recipes_screen.dart';
import 'package:mirecetario/core/database/database.dart';
import 'package:drift/drift.dart' show Value;

class MealPlannerScreen extends ConsumerStatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  ConsumerState<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends ConsumerState<MealPlannerScreen> {
  late DateTime weekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    weekStart = now.subtract(Duration(days: now.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mealPlanAsync = ref.watch(mealPlannerProvider(weekStart));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mealPlanner),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                weekStart = weekStart.subtract(const Duration(days: 7));
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                weekStart = weekStart.add(const Duration(days: 7));
              });
            },
          ),
        ],
      ),
      body: mealPlanAsync.when(
        data: (meals) => _MealPlannerBody(
          weekStart: weekStart,
          meals: meals,
          onAddMeal: (date, mealType) async {
            final recipe = await showDialog<Recipe>(
              context: context,
              builder: (ctx) => _RecipePickerDialog(),
            );
            if (recipe != null) {
              await ref.read(addMealToPlanProvider(MealPlanCompanion(
                date: Value(date),
                mealType: Value(mealType),
                recipeId: Value(recipe.id),
              )).future);
              ref.invalidate(mealPlannerProvider(weekStart));
            }
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _MealPlannerBody extends ConsumerWidget {
  final DateTime weekStart;
  final List<MealPlanData> meals;
  final Future<void> Function(DateTime, String) onAddMeal;
  const _MealPlannerBody({required this.weekStart, required this.meals, required this.onAddMeal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesProvider);
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final mealTypes = ['Desayuno', 'Comida', 'Cena'];
    return recipesAsync.when(
      data: (recipes) => ListView.builder(
        itemCount: days.length,
        itemBuilder: (context, dayIdx) {
          final date = days[dayIdx];
          final dayMeals = meals.where((m) => m.date.year == date.year && m.date.month == date.month && m.date.day == date.day).toList();
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ExpansionTile(
              title: Text('${date.day}/${date.month}/${date.year}'),
              children: mealTypes.map((type) {
                final meal = dayMeals.where((m) => m.mealType == type).toList();
                final hasMeal = meal.isNotEmpty;
                String recipeName = '-';
                if (hasMeal) {
                  final recipe = recipes.where((r) => r.id == meal.first.recipeId).toList();
                  recipeName = recipe.isNotEmpty ? recipe.first.name : 'Receta eliminada';
                }
                return ListTile(
                  title: Text(type),
                  subtitle: Text(recipeName),
                  trailing: IconButton(
                    icon: Icon(hasMeal ? Icons.edit : Icons.add),
                    onPressed: () => onAddMeal(date, type),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _RecipePickerDialog extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesProvider);
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.recipes),
      content: recipesAsync.when(
        data: (recipes) => SizedBox(
          width: 300,
          height: 300,
          child: ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return ListTile(
                title: Text(recipe.name),
                onTap: () => Navigator.of(context).pop(recipe),
              );
            },
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
      ],
    );
  }
}
