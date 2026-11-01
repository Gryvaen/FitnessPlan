import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import '../data/repositories/data_backup_repository.dart';
import 'core_providers.dart';
import 'meal_providers.dart';
import 'profile_providers.dart';
import 'step_providers.dart';
import 'strategy_review_providers.dart';

/// `ref.read` of a widget or a [ProviderContainer].
typedef ProviderReader = T Function<T>(ProviderListenable<T> provider);

/// 清空数据: removes everything the user recorded or created, as if starting
/// fresh. App settings (theme, language, reminders, permission choices) stay.
Future<void> clearUserData(ProviderReader read) async {
  await Future.wait([
    read(mealRepositoryProvider).clearAll(),
    read(weightRepositoryProvider).clearAll(),
    read(workoutRepositoryProvider).clearAll(),
    read(noteRepositoryProvider).clearAll(),
    read(foodRepositoryProvider).clearFavorites(),
    read(foodRepositoryProvider).clearHiddenRecentFoods(),
    read(formMemoryRepositoryProvider).clear(),
    read(mealPresetRepositoryProvider).clearAll(),
    read(waterRepositoryProvider).clearAll(),
    read(dietStrategyRepositoryProvider).clearAll(),
    read(dayMarkerRepositoryProvider).clearAll(),
    read(stepRepositoryProvider).clearAll(),
    read(calculatorHistoryRepositoryProvider).clear(),
    read(waterGoalProvider.notifier).clearGoal(),
    read(profileStrategyReviewProvider.notifier).clear(),
    read(strategyReviewDismissalProvider.notifier).clear(),
    read(
      sharedPreferencesProvider,
    ).remove(DataBackupRepository.importedOnDayKey),
  ]);
  // Meals and presets that referenced custom foods are gone by now.
  await read(foodRepositoryProvider).clearCustomFoods();
  await read(profileProvider.notifier).clear();
}
