import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/food_repository.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/providers/app_providers.dart';
import 'package:diet/ui/meals/log_meal_page.dart';
import 'package:diet/ui/theme/app_theme.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('back from grams editor returns to the food list', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final foodId = await db
        .into(db.foodItems)
        .insert(
          FoodItemsCompanion.insert(
            name: '测试鸡胸肉',
            category: '禽肉',
            kcalPer100: 110,
            proteinPer100: 23,
            carbPer100: 0,
            fatPer100: 2,
          ),
        );
    await db
        .into(db.mealEntries)
        .insert(
          MealEntriesCompanion.insert(
            date: DateTime.now(),
            mealType: 'lunch',
            foodId: foodId,
            foodName: '测试鸡胸肉',
            grams: 120,
            calories: 132,
            proteinG: 27.6,
            carbG: 0,
            fatG: 2.4,
          ),
        );
    await FoodRepository(db).toggleFavorite(foodId);

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
        foodsSeedProvider.overrideWith((ref) async {}),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.ofId(AppThemeId.fresh),
          locale: const Locale('zh'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(builder: (_) => const LogMealPage()),
                  ),
                  child: const Text('打开记一笔'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开记一笔'));
    await tester.pumpAndSettle();
    final recent = find.byKey(ValueKey('recent-$foodId'));
    final favorite = find.byKey(ValueKey('fav-$foodId'));
    expect(recent, findsOneWidget);
    expect(favorite, findsOneWidget);
    await tester.tap(find.descendant(of: recent, matching: find.text('测试鸡胸肉')));
    await tester.pumpAndSettle();

    expect(find.text('克数'), findsOneWidget);
    expect(find.text('更改'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: favorite, matching: find.text('测试鸡胸肉')),
    );
    await tester.pumpAndSettle();

    expect(find.text('克数'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    final foodTile = find.ancestor(
      of: find.descendant(of: recent, matching: find.text('测试鸡胸肉')),
      matching: find.byType(ListTile),
    );
    final tileRect = tester.getRect(foodTile);
    await tester.tapAt(Offset(tileRect.right - 12, tileRect.center.dy));
    await tester.pumpAndSettle();

    expect(find.text('克数'), findsOneWidget);
    expect(find.text('更改'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.drag(recent, const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text('确定将 测试鸡胸肉 移出最近记录？再次记录后会重新出现。'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    await tester.drag(favorite, const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text('确定取消收藏「测试鸡胸肉」？'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(find.textContaining('记一笔'), findsOneWidget);
    expect(find.text('测试鸡胸肉'), findsWidgets);
    expect(find.text('打开记一笔'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('打开记一笔'), findsOneWidget);
  });
}
