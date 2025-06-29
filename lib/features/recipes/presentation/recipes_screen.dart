import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mirecetario/gen_l10n/app_localizations.dart';
import 'package:mirecetario/core/database/database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';

final recipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.getAllRecipes();
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  // Aquí puedes usar LazyDatabase y path_provider para multiplataforma
  return AppDatabase(NativeDatabase.memory()); // Cambia por persistente en producción
});

class RecipesScreen extends ConsumerWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.recipes),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: AppLocalizations.of(context)!.addRecipe,
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddRecipeScreen()),
              );
              if (result == true) {
                ref.invalidate(recipesProvider);
              }
            },
          ),
        ],
      ),
      body: ref.watch(recipesProvider).when(
        data: (recipes) => _RecipeList(recipes: recipes),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _RecipeList extends ConsumerWidget {
  final List<Recipe> recipes;
  const _RecipeList({required this.recipes});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (recipes.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.myRecipes));
    }
    return ListView.separated(
      itemCount: recipes.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return Dismissible(
          key: ValueKey(recipe.id),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(AppLocalizations.of(context)!.deleteRecipe),
                content: Text(AppLocalizations.of(context)!.confirmDelete),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(AppLocalizations.of(context)!.delete),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) async {
            final db = ref.read(appDatabaseProvider);
            await db.deleteRecipe(recipe.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.deleteRecipe)),
            );
            ref.invalidate(recipesProvider);
          },
          child: ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: Text(recipe.name),
            subtitle: Text(recipe.category),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecipeDetailScreen(recipe: recipe),
                ),
              );
              if (result == true) {
                ref.invalidate(recipesProvider);
              }
            },
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddRecipeScreen(editRecipe: recipe),
                  ),
                );
                if (result == true) {
                  ref.invalidate(recipesProvider);
                }
              },
            ),
          ),
        );
      },
    );
  }
}

class AddRecipeScreen extends ConsumerStatefulWidget {
  final Recipe? editRecipe;
  const AddRecipeScreen({super.key, this.editRecipe});

  @override
  ConsumerState<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends ConsumerState<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  late String name;
  late String category;
  late String description;
  late String ingredients;
  late String instructions;

  @override
  void initState() {
    super.initState();
    name = widget.editRecipe?.name ?? '';
    category = widget.editRecipe?.category ?? '';
    description = widget.editRecipe?.description ?? '';
    ingredients = widget.editRecipe?.ingredients ?? '';
    instructions = widget.editRecipe?.instructions ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(widget.editRecipe == null ? l10n.addRecipe : l10n.editRecipe)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: name,
                decoration: InputDecoration(labelText: l10n.recipes),
                onSaved: (v) => name = v ?? '',
                validator: (v) => v == null || v.isEmpty ? l10n.recipes : null,
              ),
              TextFormField(
                initialValue: category,
                decoration: InputDecoration(labelText: l10n.category),
                onSaved: (v) => category = v ?? '',
              ),
              TextFormField(
                initialValue: description,
                decoration: InputDecoration(labelText: l10n.description),
                onSaved: (v) => description = v ?? '',
              ),
              TextFormField(
                initialValue: ingredients,
                decoration: InputDecoration(labelText: l10n.ingredients),
                onSaved: (v) => ingredients = v ?? '',
              ),
              TextFormField(
                initialValue: instructions,
                decoration: InputDecoration(labelText: l10n.instructions),
                onSaved: (v) => instructions = v ?? '',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final db = ref.read(appDatabaseProvider);
                    if (widget.editRecipe == null) {
                      await db.addRecipe(RecipesCompanion(
                        name: Value(name),
                        category: Value(category),
                        description: Value(description),
                        ingredients: Value(ingredients),
                        instructions: Value(instructions),
                        servings: Value(1),
                        cookingTime: Value(0),
                      ));
                    } else {
                      await db.update(db.recipes).replace(
                        widget.editRecipe!.copyWith(
                          name: name,
                          category: category,
                          description: description,
                          ingredients: ingredients,
                          instructions: instructions,
                        ),
                      );
                    }
                    if (context.mounted) Navigator.pop(context, true);
                  }
                },
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecipeDetailScreen extends ConsumerWidget {
  final Recipe recipe;
  const RecipeDetailScreen({required this.recipe, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddRecipeScreen(editRecipe: recipe),
                ),
              );
              if (result == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.deleteRecipe),
                  content: Text(l10n.confirmDelete),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(l10n.delete),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                final db = ref.read(appDatabaseProvider);
                await db.deleteRecipe(recipe.id);
                if (context.mounted) Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('${l10n.category}: ${recipe.category}'),
            const SizedBox(height: 8),
            Text('${l10n.description}: ${recipe.description}'),
            const SizedBox(height: 8),
            Text('${l10n.ingredients}: ${recipe.ingredients}'),
            const SizedBox(height: 8),
            Text('${l10n.instructions}: ${recipe.instructions}'),
          ],
        ),
      ),
    );
  }
}
