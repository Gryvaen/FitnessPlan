import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/food_repository.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/providers/app_providers.dart';
import 'package:diet/ui/meals/log_meal_page.dart';
import 'package:diet/ui/theme/app_theme.dart';
import 'package:drift/drift.dart' show Value;
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

  testWidgets('recent and favorites list red, then blue, then yellow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    // Logged and favorited protein → carb → fat, so the newest (fat) would
    // come first without the colour sort.
    final ids = <int>[];
    for (final (name, p, c, f) in [
      ('测试鸡胸肉', 23.0, 0.0, 2.0),
      ('测试米饭', 2.6, 26.0, 0.3),
      ('测试花生油', 0.0, 0.0, 99.0),
    ]) {
      final id = await db
          .into(db.foodItems)
          .insert(
            FoodItemsCompanion.insert(
              name: name,
              category: '其他',
              kcalPer100: 100,
              proteinPer100: p,
              carbPer100: c,
              fatPer100: f,
            ),
          );
      await db
          .into(db.mealEntries)
          .insert(
            MealEntriesCompanion.insert(
              date: DateTime.now(),
              mealType: 'lunch',
              foodId: id,
              foodName: name,
              grams: 100,
              calories: 100,
              proteinG: p,
              carbG: c,
              fatG: f,
            ),
          );
      await db
          .into(db.favoriteFoods)
          .insert(
            FavoriteFoodsCompanion.insert(
              foodId: Value(id),
              createdAt: DateTime(2026, 1, 1).add(Duration(hours: ids.length)),
            ),
          );
      ids.add(id);
    }
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
          home: const LogMealPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final prefix in ['fav', 'recent']) {
      final ys = [
        for (final id in ids)
          tester.getTopLeft(find.byKey(ValueKey('$prefix-$id'))).dy,
      ];
      expect(ys[0] < ys[1] && ys[1] < ys[2], isTrue, reason: '$prefix $ys');
    }
  });

  testWidgets('search rests as an icon, opens on tap and clear folds it', (
    tester,
  ) async {
    await _openLogMeal(tester);
    final open = find.byKey(const ValueKey('log-meal-search-open'));
    final search = find.byKey(const ValueKey('log-meal-search'));
    bool focused() => tester.widget<TextField>(search).focusNode!.hasFocus;

    expect(open, findsOneWidget);
    expect(tester.getSize(open).width, lessThan(60));
    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(open, findsNothing);
    expect(focused(), isFalse);

    await tester.tap(search);
    await tester.pumpAndSettle();
    await tester.enterText(search, '鸡胸');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('search-food-1')), findsOneWidget);

    await tester.tap(
      find.descendant(of: search, matching: find.byType(IconButton)),
    );
    await tester.pumpAndSettle();
    expect(open, findsOneWidget);
    expect(tester.widget<TextField>(search).controller!.text, isEmpty);
  });

  testWidgets('grams editor shows nutrition result with macro columns', (
    tester,
  ) async {
    final foodId = await _openLogMeal(tester);
    await tester.tap(
      find.descendant(
        of: find.byKey(ValueKey('recent-$foodId')),
        matching: find.text('测试鸡胸肉'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('营养结果'), findsOneWidget);
    // Last logged 120 g → 132 kcal, 27.6 g protein, 2.4 g fat.
    expect(find.text('132'), findsOneWidget);
    expect(find.text('kcal · 120 g'), findsOneWidget);
    expect(find.text('蛋白质'), findsOneWidget);
    expect(find.text('27.6 g'), findsOneWidget);
    expect(find.text('碳水'), findsOneWidget);
    expect(find.text('脂肪'), findsOneWidget);
    expect(find.text('2.4 g'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

/// Opens 记一笔 over a home page with one food (id 1) that is both recent
/// (last logged 120 g) and a favorite. Returns the food id.
Future<int> _openLogMeal(WidgetTester tester) async {
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
  return foodId;
}
