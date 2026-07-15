import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import 'core_providers.dart';

final profileProvider =
    NotifierProvider<ProfileNotifier, UserProfile?>(ProfileNotifier.new);

class ProfileNotifier extends Notifier<UserProfile?> {
  @override
  UserProfile? build() {
    // Always hydrate from prefs so new fields get defaulted / migrated.
    return ref.read(profileRepositoryProvider).load();
  }

  Future<UserProfile> save({
    required Sex sex,
    required int age,
    required double heightCm,
    required double weightKg,
    required ActivityLevel activity,
    required FitnessGoal goal,
    double? targetWeightKg,
    double? weeklyLossKg,
    int? calorieAdjustment,
  }) async {
    final existing = state;
    final profile = await ref.read(profileRepositoryProvider).saveFromInputs(
          sex: sex,
          age: age,
          heightCm: heightCm,
          weightKg: weightKg,
          activity: activity,
          goal: goal,
          targetWeightKg: targetWeightKg,
          weeklyLossKg: weeklyLossKg,
          calorieAdjustment:
              calorieAdjustment ?? existing?.calorieAdjustment ?? 0,
        );
    state = profile;
    return profile;
  }

  Future<UserProfile?> applyLatestWeight(double weightKg) async {
    final current = state;
    if (current == null) return null;
    final profile = await ref
        .read(profileRepositoryProvider)
        .recalculateForWeight(current, weightKg);
    state = profile;
    return profile;
  }

  Future<UserProfile?> applyPlateauCalorieCut({int kcal = 100}) async {
    final current = state;
    if (current == null) return null;
    final profile = await ref
        .read(profileRepositoryProvider)
        .applyCalorieAdjustment(current, kcal);
    state = profile;
    return profile;
  }

  void reload() {
    state = ref.read(profileRepositoryProvider).load();
  }

  Future<void> clear() async {
    await ref.read(profileRepositoryProvider).clear();
    state = null;
  }
}
