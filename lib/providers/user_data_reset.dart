import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/misc.dart'
    show ProviderListenable, ProviderOrFamily;

import '../data/repositories/data_backup_repository.dart';
import '../data/repositories/goal_history_repository.dart';
import '../data/repositories/goal_schedule_repository.dart';
import 'core_providers.dart';
import 'cultivation_providers.dart';
import 'meal_providers.dart';
import 'goal_history_providers.dart';
import 'goal_schedule_providers.dart';
import 'locale_providers.dart';
import 'profile_providers.dart';
import 'step_providers.dart';
import 'theme_providers.dart';
import 'workout_reminder_providers.dart';

/// `ref.read` of a widget or a [ProviderContainer].
typedef ProviderReader = T Function<T>(ProviderListenable<T> provider);

/// 清空数据: removes everything the user recorded or created, as if starting
/// fresh. App settings (theme, language, reminders, permission choices) stay.
Future<void> clearUserData(ProviderReader read) async {
  // Every table in one transaction: a failure part-way rolls the whole
  // clear back instead of leaving half the data behind. Prefs are only
  // touched once the database part has succeeded.
  await read(databaseProvider).transaction(() async {
    await read(mealRepositoryProvider).clearAll();
    await read(weightRepositoryProvider).clearAll();
    await read(workoutRepositoryProvider).clearAll();
    await read(noteRepositoryProvider).clearAll();
    await read(experienceRepositoryProvider).clear();
    await read(foodRepositoryProvider).clearFavorites();
    await read(foodRepositoryProvider).clearHiddenRecentFoods();
    await read(mealPresetRepositoryProvider).clearAll();
    await read(waterRepositoryProvider).clearAll();
    await read(dietStrategyRepositoryProvider).clearAll();
    await read(dayMarkerRepositoryProvider).clearAll();
    await read(stepRepositoryProvider).clearAll();
    // Meals and presets that referenced custom foods are gone by now.
    await read(foodRepositoryProvider).clearCustomFoods();
  });
  await Future.wait([
    read(formMemoryRepositoryProvider).clear(),
    read(calculatorHistoryRepositoryProvider).clear(),
    read(waterGoalProvider.notifier).clearGoal(),
    // Left behind by the removed strategy-review prompts.
    read(sharedPreferencesProvider).remove('strategy_review_dismissal_v1'),
    read(sharedPreferencesProvider).remove('strategy_profile_review_v1'),
    read(
      sharedPreferencesProvider,
    ).remove(DataBackupRepository.importedOnDayKey),
    read(sharedPreferencesProvider).remove(GoalScheduleRepository.key),
    read(sharedPreferencesProvider).remove(GoalHistoryRepository.key),
    read(maintainCultivationRepositoryProvider).clear(),
  ]);
  await read(profileProvider.notifier).clear();
  reloadPrefsBackedState(read);
}

/// After a backup import replaced the database file and the prefs: open a
/// fresh connection, drop every cached copy of the old data and reschedule
/// reminders from the imported settings, so each screen shows the imported
/// data right away instead of after a restart.
Future<void> refreshAfterImport({
  required ProviderReader read,
  required void Function(ProviderOrFamily provider) invalidate,
}) async {
  invalidate(databaseProvider);
  invalidate(themeProvider);
  invalidate(localeProvider);
  invalidate(remindersProvider);
  // Profile, 境界 ledgers, booked goal switch and goal stretches all live in
  // prefs; drop the pre-import copies.
  reloadPrefsBackedState(read);
  invalidate(cultivationHistoryProvider);
  // Best-effort, as when a reminder is edited: the data is already in place,
  // and a platform without notifications must not report the import failed.
  try {
    await read(remindersProvider.notifier).syncSchedule();
  } catch (e) {
    debugPrint('reminder sync after import failed: $e');
  }
}

/// After prefs were wiped (清空数据) or replaced wholesale (backup import):
/// reload every notifier that keeps its own copy of a prefs value, so none
/// acts on the old one — e.g. a booked goal switch applied to an imported
/// profile. Goal periods go last: their backfill reads the profile and the
/// cut rounds.
void reloadPrefsBackedState(ProviderReader read) {
  read(profileProvider.notifier).reload();
  read(cutCultivationStateProvider.notifier).reload();
  read(maintainCultivationStateProvider.notifier).reload();
  read(pendingGoalSwitchProvider.notifier).reload();
  read(goalPeriodsProvider.notifier).reload();
}
