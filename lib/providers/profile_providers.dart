import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/calendar_day.dart';
import '../domain/models.dart';
import 'core_providers.dart';
import 'cultivation_providers.dart';
import 'goal_schedule_providers.dart';

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
    DateTime? effectiveFrom,
    double? maintainProteinPerKg,
    double? maintainFatPerKg,
  }) async {
    final existing = state;
    final oldGoal = existing?.goal;
    final leavingCut = oldGoal == FitnessGoal.cut && goal != FitnessGoal.cut;
    // A booked switch carried out on/after its day: the old goal ran through
    // the day before [effectiveFrom], the new one starts on it.
    final from = effectiveFrom == null
        ? null
        : CalendarDay.dayOnly(effectiveFrom);
    final lastOldDay = from == null ? null : CalendarDay.addDays(from, -1);
    final openKcal = leavingCut && existing != null
        ? await openCultivationKcalBeforeGoalSwitch(
            ref,
            existing,
            through: lastOldDay,
          )
        : null;
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
          maintainProteinPerKg: maintainProteinPerKg,
          maintainFatPerKg: maintainFatPerKg,
        );
    state = profile;
    if (goal != FitnessGoal.cut) {
      // Fat-loss strategies only apply while cutting; maintain / bulk fall
      // back to the profile target from today on (history is kept). The
      // goal switch above already re-stamped the standard, so the returned
      // day (if any) is redundant here but harmless to apply again.
      final restamp = await ref
          .read(dietStrategyRepositoryProvider)
          .stopActivePlan(reason: 'goalChanged:${goal.name}', endOn: from);
      if (restamp != null) await markStandardChanged(restamp);
    }
    await _syncCultivationForGoalSwitch(
      from: oldGoal,
      to: goal,
      openKcal: openKcal,
      frozenEndDay: lastOldDay,
    );
    if (oldGoal != goal) {
      // An explicit switch replaces any booked one.
      await ref.read(pendingGoalSwitchProvider.notifier).clear();
      if (from != null) await markStandardChanged(from);
    }
    return state ?? profile;
  }

  /// Freeze cut cultivation when leaving cut; open a new stretch when
  /// entering cut so progress continues from the banked total.
  ///
  /// The 修行 history needs no invalidate here: it watches both the ledger
  /// and this profile, so it rebuilds on its own. Invalidating it from this
  /// notifier is also a Riverpod (debug) CircularDependencyError while the
  /// history is being listened to.
  Future<void> _syncCultivationForGoalSwitch({
    required FitnessGoal? from,
    required FitnessGoal to,
    double? openKcal,
    DateTime? frozenEndDay,
  }) async {
    if (from == to) return;
    final ledger = ref.read(cutCultivationStateProvider.notifier);

    if (from == FitnessGoal.cut && to != FitnessGoal.cut) {
      await ledger.freezeLeavingCut(openKcal ?? 0, endDay: frozenEndDay);
      return;
    }

    if (to == FitnessGoal.cut) {
      await ledger.resumeEnteringCut(
        preferredStart: state?.calorieStandardSince,
      );
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

/// Whether a profile edit changes anything nutrition targets derive from.
bool profileAffectsNutrition(UserProfile old, UserProfile next) =>
    old.sex != next.sex ||
    old.age != next.age ||
    old.heightCm != next.heightCm ||
    old.weightKg != next.weightKg ||
    old.activity != next.activity;
