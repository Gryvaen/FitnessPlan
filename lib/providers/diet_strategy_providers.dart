import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/calendar_day.dart';
import '../domain/diet_plan.dart';
import '../domain/diet_strategy.dart';
import 'core_providers.dart';
import 'meal_providers.dart';
import 'profile_providers.dart';
import 'weight_providers.dart';

/// Currently active strategy version (may start in the future).
final activeDietPlanProvider = StreamProvider<DietStrategyPlan?>((ref) {
  return ref.watch(dietStrategyRepositoryProvider).watchActivePlan();
});

/// All versions, oldest first.
final dietPlansProvider = StreamProvider<List<DietStrategyPlan>>((ref) {
  return ref.watch(dietStrategyRepositoryProvider).watchPlans();
});

/// Single source of truth for the target of a local calendar day.
final dailyTargetProvider =
    StreamProvider.family<DailyNutritionTarget?, DateTime>((ref, day) {
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

/// Review state for an active carb-taper plan; null when not applicable.
final taperReviewProvider = FutureProvider<TaperReviewResult?>((ref) async {
  final plan = ref.watch(activeDietPlanProvider).value;
  if (plan == null || plan.kind != DietStrategyKind.carbTaper) return null;
  final today = CalendarDay.todayLocal();
  final logs = ref.watch(weightLogsProvider).value ?? const [];
  final weights = <DateTime, double>{};
  for (final log in logs) {
    // Same-day re-recording already collapses to one row per day.
    weights[CalendarDay.dayOnly(log.date)] = log.weightKg;
  }
  final repo = ref.watch(dietStrategyRepositoryProvider);
  final complete = await repo.completeDaysBetween(
    today.subtract(const Duration(days: StrategyRules.reviewWindowDays - 1)),
    today,
  );
  final next = CarbTaperPlanner.nextStage(plan.baseline, plan.taperStage);
  return TaperReviewer.evaluate(
    TaperReviewInput(
      today: today,
      observationStart: plan.observationStart ?? plan.effectiveFrom,
      requiredObservationDays: plan.observationDays,
      dailyWeights: weights,
      completeDietDays: complete,
    ),
    nextStageFeasible: next != null,
  );
});
