import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/labels.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../features/auth/auth_controller.dart';
import '../../models/ingredient.dart';
import '../../router.dart';
import '../../widgets/async_view.dart';
import '../../widgets/cards.dart';
import 'ingredient_forms.dart';

/// Stock des ingrédients, alertes en premier ; achat et utilisation en un geste.
class IngredientsScreen extends ConsumerWidget {
  const IngredientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isOwner = ref.watch(authProvider).user?.isOwner ?? false;
    final ingredients = ref.watch(ingredientStockProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ingredientsTitle)),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: () async {
                if (await showIngredientSheet(context)) ref.invalidate(ingredientStockProvider);
              },
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.ingredientNew),
            )
          : null,
      body: AsyncView(
        value: ingredients,
        onRetry: () => ref.invalidate(ingredientStockProvider),
        builder: (ingredients) => RefreshIndicator(
          onRefresh: () => ref.refresh(ingredientStockProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: ingredients.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _IngredientTile(ingredient: ingredients[index]),
          ),
        ),
      ),
    );
  }
}

class _IngredientTile extends ConsumerWidget {
  const _IngredientTile({required this.ingredient});

  final Ingredient ingredient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final unit = l10n.unitLabel(ingredient.unit);
    final color = ingredient.lowStock ? AppColors.danger : AppColors.success;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await context.push(Routes.ingredient(ingredient.id));
          ref.invalidate(ingredientStockProvider);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(ingredient.lowStock ? Icons.warning_amber_rounded : Icons.inventory_2_rounded, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ingredient.name(context.lang), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  '${formatQuantity(ingredient.stock)} $unit',
                  style: TextStyle(fontSize: 17, color: color, fontWeight: FontWeight.w600),
                ),
                if (ingredient.lowStock) StatusChip(label: l10n.ingredientLow, color: AppColors.danger),
              ]),
            ),
            IconButton.filledTonal(
              iconSize: 28,
              tooltip: l10n.ingredientPurchase,
              icon: const Icon(Icons.add_shopping_cart_rounded),
              onPressed: () async {
                if (await showPurchaseSheet(context, ingredient)) ref.invalidate(ingredientStockProvider);
              },
            ),
            const SizedBox(width: 4),
            IconButton.filledTonal(
              iconSize: 28,
              tooltip: l10n.ingredientUsage,
              icon: const Icon(Icons.remove_circle_outline_rounded),
              onPressed: () async {
                if (await showUsageSheet(context, ingredient)) ref.invalidate(ingredientStockProvider);
              },
            ),
          ]),
        ),
      ),
    );
  }
}
