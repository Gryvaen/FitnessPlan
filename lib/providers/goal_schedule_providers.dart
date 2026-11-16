import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/goal_schedule_repository.dart';
import '../domain/calendar_day.dart';
import 'core_providers.dart';
import 'diet_strategy_providers.dart';
import 'profile_providers.dart';

final goalScheduleRepositoryProvider = Provider<GoalScheduleRepository>((ref) {
  return GoalScheduleRepository(ref.watch(sharedPreferencesProvider));
});

/// The booked goal switch, if any (see [applyDueGoalSwitch]).
final pendingGoalSwitchProvider =
    NotifierProvider<PendingGoalSwitchNotifier, PendingGoalSwitch?>(
      PendingGoalSwitchNotifier.new,
    );

class PendingGoalSwitchNotifier extends Notifier<PendingGoalSwitch?> {
  @override
  PendingGoalSwitch? build() => ref.read(goalScheduleRepositoryProvider).load();

  Future<void> schedule(PendingGoalSwitch pending) async {
    await ref.read(goalScheduleRepositoryProvider).save(pending);
    state = pending;
  }

  void reload() {
    state = ref.read(goalScheduleRepositoryProvider).load();
  }

  Future<void> clear() async {
    if (state == null) return;
    await ref.read(goalScheduleRepositoryProvider).clear();
    state = null;
  }
}

/// Carries out a booked goal switch once its day has come: the same switch
/// as the profile editor's, dated to the booked day even when the app is
/// opened days later (the cut strategy ends that day, the cut round closes
/// the day before, and the new standard starts that day). Run on launch and
/// on resume. Returns whether a switch happened.
Future<bool> applyDueGoalSwitch(Ref ref, {DateTime? today}) async {
  final pending = ref.read(pendingGoalSwitchProvider);
  if (pending == null) return false;
  final day = CalendarDay.todayLocal(today);
  if (pending.from.isAfter(day)) return false;
  await ref.read(pendingGoalSwitchProvider.notifier).clear();
  final p = ref.read(profileProvider);
  if (p == null || p.goal == pending.goal) return false;
  await ref
      .read(profileProvider.notifier)
      .save(
        sex: p.sex,
        age: p.age,
        heightCm: p.heightCm,
        weightKg: p.weightKg,
        activity: p.activity,
        goal: pending.goal,
        calorieAdjustment: p.calorieAdjustment,
        effectiveFrom: pending.from,
        maintainProteinPerKg: pending.proteinPerKg,
        maintainFatPerKg: pending.fatPerKg,
      );
  ref.invalidate(todayTargetProvider);
  return true;
}

/// Widget-side entry for [applyDueGoalSwitch].
final applyDueGoalSwitchProvider =
    Provider<Future<bool> Function({DateTime? today})>(
      (ref) =>
          ({DateTime? today}) => applyDueGoalSwitch(ref, today: today),
    );
