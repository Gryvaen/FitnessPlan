import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import 'core_providers.dart';
import 'cultivation_providers.dart';

final profileProvider = NotifierProvider<ProfileNotifier, UserProfile?>(
  ProfileNotifier.new,
);

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
    int? calorieAdjustment,
  }) async {
    final existing = state;
    final oldGoal = existing?.goal;
    final profile = await ref
        .read(profileRepositoryProvider)
        .saveFromInputs(
          sex: sex,
          age: age,
          heightCm: heightCm,
          weightKg: weightKg,
          activity: activity,
          goal: goal,
          targetWeightKg: targetWeightKg,
          calorieAdjustment:
              calorieAdjustment ?? existing?.calorieAdjustment ?? 0,
        );
    state = profile;
    if (goal != FitnessGoal.cut) {
      // Fat-loss strategies only apply while cutting; maintain / bulk fall
      // back to the profile target from today on (history is kept). The
      // goal switch above already re-stamped the standard, so the returned
      // day (if any) is redundant here but harmless to apply again.
      final restamp = await ref
          .read(dietStrategyRepositoryProvider)
          .stopActivePlan(reason: 'goalChanged:${goal.name}');
      if (restamp != null) await markStandardChanged(restamp);
    }
    await _syncCultivationForGoalSwitch(from: oldGoal, to: goal);
    return profile;
  }

  /// Freeze cut cultivation when leaving cut; open a new stretch when
  /// entering cut so progress continues from the banked total.
  Future<void> _syncCultivationForGoalSwitch({
    required FitnessGoal? from,
    required FitnessGoal to,
  }) async {
    if (from == to) return;
    final ledger = ref.read(cutCultivationStateProvider.notifier);

    if (from == FitnessGoal.cut && to != FitnessGoal.cut) {
      // Await a fresh history build while the open segment still exists.
      ref.invalidate(cultivationHistoryProvider);
      final sections = await ref.read(cultivationHistoryProvider.future);
      final openKcal = sections
          .where((s) => s.isCurrent)
          .fold<double>(0, (sum, s) => sum + s.totalKcal);
      await ledger.freezeLeavingCut(openKcal);
      ref.invalidate(cultivationHistoryProvider);
      return;
    }

    if (to == FitnessGoal.cut) {
      await ledger.resumeEnteringCut(
        preferredStart: state?.calorieStandardSince,
      );
      ref.invalidate(cultivationHistoryProvider);
    }
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

  void reload() {
    state = ref.read(profileRepositoryProvider).load();
  }

  /// Re-stamps the "new standard" marker; see `ProfileRepository.markStandardChanged`.
  Future<void> markStandardChanged(DateTime since) async {
    final profile = await ref
        .read(profileRepositoryProvider)
        .markStandardChanged(since);
    if (profile != null) state = profile;
  }

  Future<void> clear() async {
    await ref.read(profileRepositoryProvider).clear();
    await ref.read(cultivationRepositoryProvider).clear();
    ref.read(cutCultivationStateProvider.notifier).reload();
    state = null;
  }
}
