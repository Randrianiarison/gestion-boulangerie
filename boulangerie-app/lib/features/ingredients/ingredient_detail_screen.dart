import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/labels.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../features/auth/auth_controller.dart';
import '../../widgets/async_view.dart';
import '../../widgets/cards.dart';
import '../../widgets/dialogs.dart';
import 'ingredient_forms.dart';

/// Fiche d'un ingrédient : stock, achats et utilisations récents.
class IngredientDetailScreen extends ConsumerWidget {
  const IngredientDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isOwner = ref.watch(authProvider).user?.isOwner ?? false;
    final ingredient = ref.watch(ingredientProvider(id));
    void refresh() => ref.invalidate(ingredientProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: Text(ingredient.value?.name(context.lang) ?? l10n.ingredientsTitle),
        actions: [
          if (isOwner && ingredient.value != null) ...[
            IconButton(
              tooltip: l10n.edit,
              icon: const Icon(Icons.edit_rounded),
              onPressed: () async {
                if (await showIngredientSheet(context, ingredient: ingredient.value)) refresh();
              },
            ),
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () async {
                final name = ingredient.value!.name(context.lang);
                if (!await confirmDialog(context, title: l10n.deleteConfirm(name), danger: true)) return;
                try {
                  await ref.read(bakeryApiProvider).deleteIngredient(id);
                  if (!context.mounted) return;
                  showSuccess(context, l10n.deleted);
                  Navigator.pop(context);
                } on Object catch (error) {
                  if (context.mounted) showError(context, error);
                }
              },
            ),
          ],
        ],
      ),
      body: AsyncView(
        value: ingredient,
        onRetry: refresh,
        builder: (ingredient) {
          final unit = l10n.unitLabel(ingredient.unit);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: (ingredient.lowStock ? AppColors.danger : AppColors.success).withValues(alpha: 0.12),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    Text(l10n.ingredientStock, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      '${formatQuantity(ingredient.stock)} $unit',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text('${l10n.ingredientThreshold} : ${formatQuantity(ingredient.alertThreshold)} $unit'),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      if (await showPurchaseSheet(context, ingredient)) refresh();
                    },
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: Text(l10n.ingredientPurchase),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      if (await showUsageSheet(context, ingredient)) refresh();
                    },
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    label: Text(l10n.ingredientUsage),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              SectionCard(
                title: l10n.purchases,
                icon: Icons.shopping_basket_rounded,
                child: ingredient.purchases.isEmpty
                    ? Text(l10n.noData)
                    : Column(children: [
                        for (final purchase in ingredient.purchases)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('${formatQuantity(purchase.quantity)} $unit · ${formatMoney(purchase.total)}'),
                            subtitle: Text([
                              context.dates.short(purchase.purchasedOn),
                              '${formatMoney(purchase.unitPrice)} / $unit',
                              ?purchase.supplier,
                            ].join(' · ')),
                          ),
                      ]),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: l10n.usages,
                icon: Icons.soup_kitchen_rounded,
                child: ingredient.usages.isEmpty
                    ? Text(l10n.noData)
                    : Column(children: [
                        for (final usage in ingredient.usages)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('${formatQuantity(usage.quantity)} $unit'),
                            subtitle: Text(context.dates.short(usage.usedOn)),
                          ),
                      ]),
              ),
            ],
          );
        },
      ),
    );
  }
}
