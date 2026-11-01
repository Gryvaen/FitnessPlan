import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/data_backup_repository.dart';
import 'package:diet/domain/calculator_engine.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/providers/app_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'app_theme_id': 'graphite',
      'app_locale': 'en',
      'strategy_review_dismissal_v1': '{"planKey":"1:1:0","weightKg":70}',
      'strategy_profile_review_v1': '{}',
      DataBackupRepository.importedOnDayKey: '2026-10-31T00:00:00.000',
    });
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('clears user data and keeps app settings', () async {
    final foods = container.read(foodRepositoryProvider);
    final seedId = await db
        .into(db.foodItems)
        .insert(
          FoodItemsCompanion.insert(
            name: '米饭',
            category: '谷物',
            kcalPer100: 116,
            proteinPer100: 2.6,
            carbPer100: 25.9,
            fatPer100: 0.3,
          ),
        );
    final customId = await foods.createCustom(
      name: '我的燕麦杯',
      kcalPer100: 300,
      proteinPer100: 10,
      carbPer100: 50,
      fatPer100: 5,
    );
    await foods.addServing(foodId: seedId, label: '一碗', grams: 150);
    await foods.addServing(foodId: customId, label: '一杯', grams: 80);
    await foods.toggleFavorite(seedId);
    await foods.toggleFavorite(customId);
    await container
        .read(stepRepositoryProvider)
        .setStepsForDay(CalendarDay.todayLocal(), 8000);
    await container.read(waterGoalProvider.notifier).setGoal(2500);
    await container
        .read(calculatorHistoryRepositoryProvider)
        .add(
          CalcHistoryEntry(expression: '1+1', result: '2', at: DateTime(2026)),
        );

    await clearUserData(container.read);

    final remaining = await db.select(db.foodItems).get();
    expect(remaining.map((f) => f.id), [seedId]);
    expect(await db.select(db.foodServings).get(), isEmpty);
    expect(await db.select(db.favoriteFoods).get(), isEmpty);
    expect(await db.select(db.stepLogs).get(), isEmpty);
    expect(container.read(waterRepositoryProvider).getGoalMlOrNull(), isNull);
    expect(container.read(calculatorHistoryRepositoryProvider).load(), isEmpty);
    expect(container.read(strategyReviewDismissalProvider), isNull);
    expect(container.read(profileStrategyReviewProvider), isNull);
    expect(prefs.getString('strategy_review_dismissal_v1'), isNull);
    expect(prefs.getString('strategy_profile_review_v1'), isNull);
    expect(prefs.getString(DataBackupRepository.importedOnDayKey), isNull);

    expect(prefs.getString('app_theme_id'), 'graphite');
    expect(prefs.getString('app_locale'), 'en');
  });
}
