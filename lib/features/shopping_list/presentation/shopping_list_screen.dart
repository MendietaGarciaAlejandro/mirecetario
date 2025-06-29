import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mirecetario/gen_l10n/app_localizations.dart';
import 'package:mirecetario/core/database/database.dart';
import 'package:mirecetario/features/recipes/presentation/recipes_screen.dart';
import 'package:mirecetario/features/shopping_list/application/shopping_list_generator.dart';
import 'package:drift/drift.dart' show Value;

final shoppingListProvider = FutureProvider<List<ShoppingListData>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.getShoppingList();
});

class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shoppingList),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.addToShoppingList,
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (ctx) => const _AddShoppingItemDialog(),
              );
              ref.invalidate(shoppingListProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Generar desde menú semanal',
            onPressed: () async {
              await ref.read(generateShoppingListProvider.future);
              ref.invalidate(shoppingListProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lista generada desde el menú semanal')),
                );
              }
            },
          ),
        ],
      ),
      body: ref.watch(shoppingListProvider).when(
        data: (items) => _ShoppingListBody(items: items),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ShoppingListBody extends ConsumerWidget {
  final List<ShoppingListData> items;
  const _ShoppingListBody({required this.items, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.shoppingList));
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final item = items[index];
        return CheckboxListTile(
          value: item.checked,
          onChanged: (checked) async {
            final db = ref.read(appDatabaseProvider);
            await db.updateShoppingListItem(item.copyWith(checked: checked ?? false));
            ref.invalidate(shoppingListProvider);
          },
          title: Text(item.item),
          subtitle: Text('${item.quantity} ${item.unit}'),
          secondary: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final db = ref.read(appDatabaseProvider);
              await db.removeFromShoppingList(item.id);
              ref.invalidate(shoppingListProvider);
            },
          ),
        );
      },
    );
  }
}

class _AddShoppingItemDialog extends ConsumerStatefulWidget {
  const _AddShoppingItemDialog({super.key});

  @override
  ConsumerState<_AddShoppingItemDialog> createState() => _AddShoppingItemDialogState();
}

class _AddShoppingItemDialogState extends ConsumerState<_AddShoppingItemDialog> {
  final _formKey = GlobalKey<FormState>();
  String item = '';
  double quantity = 1;
  String unit = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.addToShoppingList),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: InputDecoration(labelText: l10n.ingredients),
              onSaved: (v) => item = v ?? '',
              validator: (v) => v == null || v.isEmpty ? l10n.ingredients : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Cantidad'),
              keyboardType: TextInputType.number,
              onSaved: (v) => quantity = double.tryParse(v ?? '1') ?? 1,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Unidad'),
              onSaved: (v) => unit = v ?? '',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              final db = ref.read(appDatabaseProvider);
              await db.addToShoppingList(ShoppingListCompanion(
                item: Value(item),
                quantity: Value(quantity),
                unit: Value(unit),
              ));
              if (context.mounted) Navigator.of(context).pop();
            }
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
