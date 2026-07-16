import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db.dart';
import '../domain/calendar_day.dart';
import '../domain/models.dart';
import 'core_providers.dart';

final selectedDayProvider = NotifierProvider<SelectedDayNotifier, DateTime>(
  SelectedDayNotifier.new,
);

class SelectedDayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => CalendarDay.todayLocal();

  void setDay(DateTime day) {
    state = CalendarDay.dayOnly(day);
  }

  void goToToday() {
    state = CalendarDay.todayLocal();
  }

  /// Shift by [delta] days, clamped to [earliest]..today (local calendar).
  void shiftDay(int delta, {DateTime? earliest}) {
    final today = CalendarDay.todayLocal();
    final min = earliest ?? DateTime(today.year - 1, today.month, today.day);
    var next = state.add(Duration(days: delta));
    next = CalendarDay.dayOnly(next);
    if (next.isBefore(min)) next = min;
    if (next.isAfter(today)) next = today;
    state = next;
  }
}

final todayMealsProvider = StreamProvider<List<MealEntry>>((ref) {
  final day = ref.watch(selectedDayProvider);
  return ref.watch(mealRepositoryProvider).watchForDay(day);
});

final todayIntakeProvider = Provider<MacroIntake>((ref) {
  final meals = ref.watch(todayMealsProvider).value ?? const [];
  return meals.fold<MacroIntake>(
    const MacroIntake(),
    (sum, e) =>
        sum +
        MacroIntake(
          calories: e.calories,
          proteinG: e.proteinG,
          carbG: e.carbG,
          fatG: e.fatG,
          alcoholG: e.alcoholG,
        ),
  );
});

final waterMlProvider = StreamProvider<int>((ref) {
  final day = ref.watch(selectedDayProvider);
  return ref.watch(waterRepositoryProvider).watchMlForDay(day);
});

final waterGoalProvider = NotifierProvider<WaterGoalNotifier, int>(
  WaterGoalNotifier.new,
);

class WaterGoalNotifier extends Notifier<int> {
  @override
  int build() => ref.watch(waterRepositoryProvider).getGoalMl();

  Future<void> setGoal(int ml) async {
    await ref.read(waterRepositoryProvider).setGoalMl(ml);
    state = ref.read(waterRepositoryProvider).getGoalMl();
  }

  Future<void> clearGoal() async {
    await ref.read(waterRepositoryProvider).clearGoalMl();
    state = ref.read(waterRepositoryProvider).getGoalMl();
  }
}

final mealPresetsProvider = FutureProvider.autoDispose<List<MealPreset>>((ref) {
  return ref.watch(mealPresetRepositoryProvider).listPresets();
});
