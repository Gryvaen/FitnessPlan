import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/calendar_day.dart';
import '../domain/diet_plan.dart';
import 'core_providers.dart';
import 'meal_providers.dart';
import 'profile_providers.dart';

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
