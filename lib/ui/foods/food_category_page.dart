import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';

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
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
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
      final page = await ref.read(foodRepositoryProvider).byCategory(
            widget.category,
            limit: _pageSize,
            offset: reset ? 0 : _items.length,
          );
      if (!mounted) return;
      setState(() {
        _items.addAll(page);
        _hasMore = page.length >= _pageSize;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(widget.category.localizedCategory(l10n))),
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
                  ? Center(
                      child: Text(l10n.categoryEmpty, style: theme.textTheme.meta),
                    )
                  : NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n.metrics.pixels >
                            n.metrics.maxScrollExtent - 240) {
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          }
                          final f = _items[i];
                          return ListTile(
                            key: ValueKey(f.id),
                            title:
                                Text(f.name, style: theme.textTheme.bodyLarge),
                            subtitle: Text(
                              '${f.kcalPer100.round()} kcal / 100g',
                              style: theme.textTheme.meta,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/foods/${f.id}'),
                          );
                        },
                      ),
                    ),
    );
  }
}
