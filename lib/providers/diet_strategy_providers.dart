import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/diet_strategy_repository.dart';
import '../domain/calendar_day.dart';
import '../domain/diet_plan.dart';
import 'core_providers.dart';
import 'meal_providers.dart';
import 'profile_providers.dart';

/// Mutations that may re-stamp the profile's "new standard" marker.
final dietStrategyActionsProvider = Provider<DietStrategyActions>(
  (ref) => DietStrategyActions(ref),
);

class DietStrategyActions {
  DietStrategyActions(this._ref);

  final Ref _ref;

  /// Creates [draft] as the new active version, re-stamping the "new
  /// standard" marker to its effective date when it's a structural change
  /// (see `DietStrategyRepository.isStructuralChange`).
  Future<DietStrategyPlan> applyPlan(DietStrategyPlanDraft draft) async {
    final repo = _ref.read(dietStrategyRepositoryProvider);
    final old = await repo.activePlan();
    final created = await repo.createPlan(draft);
    if (DietStrategyRepository.isStructuralChange(old, draft)) {
      await _ref
          .read(profileProvider.notifier)
          .markStandardChanged(draft.effectiveFrom);
    }
    return created;
  }

  /// Stops the active version, re-stamping the marker when today's standard
  /// actually changes (see `DietStrategyRepository.stopActivePlan`).
  Future<void> cancelPlan({String reason = 'stopped'}) async {
    final restamp = await _ref
        .read(dietStrategyRepositoryProvider)
        .stopActivePlan(reason: reason);
    if (restamp != null) {
      await _ref.read(profileProvider.notifier).markStandardChanged(restamp);
    }
  }
}

/// Currently active strategy version (may start in the future).
final activeDietPlanProvider = StreamProvider<DietStrategyPlan?>((ref) {
  return ref.watch(dietStrategyRepositoryProvider).watchActivePlan();
});

/// All versions, oldest first.
final dietPlansProvider = StreamProvider<List<DietStrategyPlan>>((ref) {
  return ref.watch(dietStrategyRepositoryProvider).watchPlans();
});

/// Single source of truth for the target of a local calendar day.
///
/// `autoDispose` (matching the sibling `mealsForDayProvider`/
/// `dayWorkoutProvider` families) so browsing many days — Today's prev/next
/// arrows go back a full year, and the cultivation history screen watches
/// 14 of these at once — doesn't pin a live DB stream subscription open per
/// day ever viewed for the rest of the app's process lifetime.
final dailyTargetProvider = StreamProvider.autoDispose
    .family<DailyNutritionTarget?, DateTime>((ref, day) {
      final profile = ref.watch(profileProvider);
      return ref
          .watch(dietStrategyRepositoryProvider)
          .watchTargetForDay(CalendarDay.dayOnly(day), profile);
    });

/// Target for the day selected on the Today page.
final selectedDayTargetProvider = Provider<AsyncValue<DailyNutritionTarget?>>(
  (ref) => ref.watch(dailyTargetProvider(ref.watch(selectedDayProvider))),
);

/// Today's target (for pages that only deal with today).
final todayTargetProvider = Provider<AsyncValue<DailyNutritionTarget?>>(
  (ref) => ref.watch(dailyTargetProvider(CalendarDay.todayLocal())),
);

/// null = the user has not confirmed anything for that day.
final dayDietCompleteProvider = StreamProvider.family<bool?, DateTime>((
  ref,
  day,
) {
  return ref
      .watch(dietStrategyRepositoryProvider)
      .watchDayComplete(CalendarDay.dayOnly(day));
});
