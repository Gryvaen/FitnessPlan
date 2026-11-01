import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/food_repository.dart';
import 'package:diet/data/repositories/meal_repository.dart';
import 'package:diet/domain/models.dart';
import 'package:diet/domain/temporary_food_draft.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/providers/core_providers.dart';
import 'package:diet/ui/meals/daily_meals_page.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

enum _Lunch { mixed, temporaryOnly, caloriesOnly }

Future<void> _seed(AppDatabase db, _Lunch lunch) async {
  final today = DateTime.now();
  final meals = MealRepository(db);
  if (lunch == _Lunch.mixed) {
    final foods = FoodRepository(db);
    final id = await foods.createCustom(
      name: '米饭测试',
      kcalPer100: 116,
      proteinPer100: 2.6,
      carbPer100: 25.9,
      fatPer100: 0.3,
    );
    final rice = (await foods.byId(id))!;
    await meals.add(
      date: today,
      mealType: MealType.lunch,
      food: rice,
      grams: 150,
    );
  }
  final caloriesOnly = lunch == _Lunch.caloriesOnly;
  await meals.addTemporary(
    date: today,
    mealType: MealType.lunch,
    draft: TemporaryFoodDraft(
      name: '同事的蛋糕',
      input: caloriesOnly
          ? TemporaryFoodInput.caloriesOnly
          : TemporaryFoodInput.per100g,
      nutrition: caloriesOnly
          ? const MacroIntake(calories: 300)
          : const MacroIntake(calories: 350, carbG: 50, fatG: 15, proteinG: 5),
    ),
    grams: caloriesOnly ? 0 : 80,
  );
}

Future<void> _openDay(WidgetTester tester, AppDatabase db) async {
  final container = ProviderContainer(
    overrides: [databaseProvider.overrideWithValue(db)],
  );
  addTearDown(container.dispose);
  final today = DateTime.now();
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, _) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => context.push(dailyMealsPath(today)),
              child: const Text('Open records'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/day-meals',
        pageBuilder: (_, state) => DailyMealsSheetPage(
          key: state.pageKey,
          date: DateTime.parse(state.uri.queryParameters['date']!),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.binding.setSurfaceSize(const Size(412, 915));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: const Locale('zh'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open records'));
  await tester.pumpAndSettle();
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final lunch in _Lunch.values) {
    testWidgets('save lunch as preset: ${lunch.name}', (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await tester.runAsync(() => _seed(db, lunch));
      await _openDay(tester, db);
      await _settle(tester);

      final menu = find.byTooltip('更多');
      if (lunch != _Lunch.mixed) {
        // Nothing savable: the meal's menu must not offer 存为套餐.
        if (menu.evaluate().isNotEmpty) {
          await tester.tap(menu.first);
          await tester.pumpAndSettle();
        }
        expect(find.text('存为套餐'), findsNothing);
        expect(tester.takeException(), isNull);
        return;
      }

      await tester.tap(menu.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('存为套餐'));
      await _settle(tester);
      expect(tester.takeException(), isNull);
      await tester.enterText(
        find.byKey(const ValueKey('save-preset-name-input')),
        '午餐测试',
      );
      await tester.tap(find.widgetWithText(FilledButton, '保存'));
      await _settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Invalid argument'), findsNothing);
      expect(find.textContaining('Bad state'), findsNothing);
      // Shown inside the sheet, not on the page hidden underneath it.
      final sheetScaffold = find
          .ancestor(
            of: find.byType(DailyMealsPage),
            matching: find.byType(Scaffold),
          )
          .first;
      expect(
        find.descendant(
          of: sheetScaffold,
          matching: find.text('套餐已保存，已跳过 1 项临时食物'),
        ),
        findsOneWidget,
      );
      final items = await tester.runAsync(
        () => db.select(db.mealPresetItems).get(),
      );
      expect(items!.map((i) => i.foodName), ['米饭测试']);
    });
  }
}
