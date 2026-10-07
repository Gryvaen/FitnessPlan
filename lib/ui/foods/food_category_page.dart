import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../ink/ink_icon.dart';
import '../widgets/food_name_link.dart';
import 'food_category_art.dart';

const _pageSize = 80;

class FoodCategoryPage extends ConsumerStatefulWidget {
  const FoodCategoryPage({super.key, required this.category});

  final String category;

  @override
  ConsumerState<FoodCategoryPage> createState() => _FoodCategoryPageState();
}

class _FoodCategoryPageState extends ConsumerState<FoodCategoryPage> {
  final _items = <FoodItem>[];
  var _loading = true;
  var _loadingMore = false;
  var _hasMore = true;
  var _loadGeneration = 0;
  Object? _error;

  Future<bool> _confirmDelete(FoodItem food) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteCustomFood),
        content: Text(l10n.deleteCustomFoodBody),
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
    if (confirmed != true || !mounted) return false;
    try {
      await ref.read(foodRepositoryProvider).deleteCustom(food.id);
      if (mounted) await _load(reset: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    // The refreshed list owns removal, so Dismissible never removes a stale row.
    return false;
  }

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
    final generation = reset ? ++_loadGeneration : _loadGeneration;
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _items.clear();
        _hasMore = true;
      });
    } else {
      if (!_hasMore || _loadingMore) return;
      setState(() => _loadingMore = true);
    }

    try {
      await ref.read(foodsSeedProvider.future);
      final page = await ref
          .read(foodRepositoryProvider)
          .byCategory(
            widget.category,
            limit: _pageSize,
            offset: reset ? 0 : _items.length,
          );
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _items.addAll(page);
        _hasMore = page.length >= _pageSize;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _error = e;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(foodCatalogChangesProvider, (previous, next) {
      if (previous == null || !previous.hasValue || !next.hasValue) return;
      if (previous.value == next.value) return;
      _load(reset: true);
    });
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            FoodCategoryAvatar(category: widget.category, size: 30),
            const SizedBox(width: 10),
            Text(widget.category.localizedCategory(l10n)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.loadFailed('$_error')),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => _load(reset: true),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            )
          : _items.isEmpty
          ? Center(child: Text(l10n.categoryEmpty, style: theme.textTheme.meta))
          : NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.pixels > n.metrics.maxScrollExtent - 240) {
                  _load(reset: false);
                }
                return false;
              },
              child: ListView.separated(
                itemCount: _items.length + (_hasMore ? 1 : 0),
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  if (i >= _items.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  final f = _items[i];
                  final tile = ListTile(
                    key: ValueKey(f.id),
                    title: FoodNameLink(
                      name: f.displayName(context),
                      foodId: f.id,
                      carbG: f.carbPer100,
                      proteinG: f.proteinPer100,
                      fatG: f.fatPer100,
                      style: theme.textTheme.bodyLarge,
                    ),
                    subtitle: Text(
                      '${f.kcalPer100.round()} kcal / 100g',
                      style: theme.textTheme.meta,
                    ),
                    trailing: InkIcon(
                      InkGlyph.chevronRight,
                      color: foodUtilityIconColor(context),
                    ),
                    onTap: () => openFoodDetail(context, f.id),
                  );
                  if (!f.isCustom) return tile;
                  return Dismissible(
                    key: ValueKey('category-food-${f.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      color: theme.colorScheme.error,
                      child: const InkIcon(
                        InkGlyph.delete,
                        color: Colors.white,
                      ),
                    ),
                    confirmDismiss: (_) => _confirmDelete(f),
                    child: tile,
                  );
                },
              ),
            ),
    );
  }
}
