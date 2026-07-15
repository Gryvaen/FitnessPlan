import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db.dart';
import 'core_providers.dart';

final foodsSeedProvider = FutureProvider<void>((ref) async {
  await ref.watch(foodRepositoryProvider).syncSeedFromAsset();
});

final favoriteFoodsProvider = StreamProvider<List<FoodItem>>((ref) {
  return ref.watch(foodRepositoryProvider).watchFavorites();
});

final foodFavoriteProvider =
    FutureProvider.autoDispose.family<bool, int>((ref, foodId) async {
  return ref.watch(foodRepositoryProvider).isFavorite(foodId);
});
