import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../ink/ink_icon.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
import '../widgets/food_name_link.dart';

enum FoodCollection { favorites, presets }

class FoodCollectionPage extends ConsumerWidget {
  const FoodCollectionPage({super.key, required this.collection});

  final FoodCollection collection;

  Future<void> _removeFavorite(
    BuildContext context,
    WidgetRef ref,
    FoodItem food,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.removeFavorite),
        content: Text(l10n.confirmRemoveFavorite(food.displayName(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(foodRepositoryProvider).toggleFavorite(food.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _deletePreset(
    BuildContext context,
    WidgetRef ref,
    MealPreset preset,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.confirmDeletePlan(preset.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(mealPresetRepositoryProvider).deletePreset(preset.id);
      ref.invalidate(mealPresetsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Widget _deleteBackground(BuildContext context) => Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 16),
    color: Theme.of(context).colorScheme.error,
    child: const InkIcon(InkGlyph.delete, color: Colors.white),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final favorites = collection == FoodCollection.favorites;
    return Scaffold(
      appBar: AppBar(title: Text(favorites ? l10n.favorites : l10n.presetsTab)),
      body: favorites
          ? ref
                .watch(favoriteFoodsProvider)
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) =>
                      Center(child: Text(l10n.loadFailed('$error'))),
                  data: (foods) => foods.isEmpty
                      ? SportEmptyState(title: l10n.noFavorites)
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.listPage,
                            0,
                            AppSpacing.listPage,
                            listBottomInset(context, hasFab: false),
                          ),
                          itemCount: foods.length,
                          itemBuilder: (context, index) {
                            final food = foods[index];
                            return Dismissible(
                              key: ValueKey('favorite-food-${food.id}'),
                              direction: DismissDirection.endToStart,
                              background: _deleteBackground(context),
                              confirmDismiss: (_) async {
                                await _removeFavorite(context, ref, food);
                                return false;
                              },
                              child: SportListTile(
                                contentPadding: EdgeInsets.zero,
                                title: FoodNameLink(
                                  name: food.displayName(context),
                                  foodId: food.id,
                                  carbG: food.carbPer100,
                                  proteinG: food.proteinPer100,
                                  fatG: food.fatPer100,
                                  onTap: () => openFoodDetail(context, food.id),
                                ),
                                subtitle: Text(
                                  food.category.localizedCategory(l10n),
                                ),
                                trailing: IconButton(
                                  tooltip: l10n.removeFavorite,
                                  icon: const InkIcon(InkGlyph.star),
                                  onPressed: () =>
                                      _removeFavorite(context, ref, food),
                                ),
                                onTap: () => openFoodDetail(context, food.id),
                              ),
                            );
                          },
                        ),
                )
          : ref
                .watch(mealPresetsProvider)
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) =>
                      Center(child: Text(l10n.loadFailed('$error'))),
                  data: (presets) => presets.isEmpty
                      ? SportEmptyState(title: l10n.noPresets)
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.listPage,
                            0,
                            AppSpacing.listPage,
                            listBottomInset(context, hasFab: false),
                          ),
                          itemCount: presets.length,
                          itemBuilder: (context, index) {
                            final preset = presets[index];
                            return Dismissible(
                              key: ValueKey('foods-preset-${preset.id}'),
                              direction: DismissDirection.endToStart,
                              background: _deleteBackground(context),
                              confirmDismiss: (_) async {
                                await _deletePreset(context, ref, preset);
                                return false;
                              },
                              child: SportListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const InkIcon(InkGlyph.restaurant),
                                title: Text(preset.name),
                                onTap: () =>
                                    context.push('/meal-preset/${preset.id}'),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
