import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db.dart';
import 'core_providers.dart';

final foodsSeedProvider = FutureProvider<void>((ref) async {
  await ref.watch(foodRepositoryProvider).syncSeedFromAsset();
});

final favoriteFoodsProvider = StreamProvider<List<FoodItem>>((ref) {
  return ref.watch(foodRepositoryProvider).watchFavorites();
});

/// Bumps whenever the food catalog changes, so cached lists reload names.
final foodCatalogChangesProvider = StreamProvider<int>((ref) {
  return ref.watch(foodRepositoryProvider).watchChanges();
});

/// Recently logged foods (live): follows meals, hidden entries and catalog.
final recentFoodsProvider = StreamProvider<List<FoodItem>>((ref) async* {
  await ref.watch(foodsSeedProvider.future);
  yield* ref.watch(foodRepositoryProvider).watchRecentFoods();
});

final foodByIdProvider = StreamProvider.autoDispose.family<FoodItem?, int>((
  ref,
  id,
) {
  return ref.watch(foodRepositoryProvider).watchById(id);
});

/// Derived from [favoriteFoodsProvider] so every star follows toggles made
/// anywhere, without opening a DB stream per list row.
final foodFavoriteProvider = Provider.autoDispose.family<AsyncValue<bool>, int>(
  (ref, foodId) => ref
      .watch(favoriteFoodsProvider)
      .whenData((foods) => foods.any((f) => f.id == foodId)),
);
