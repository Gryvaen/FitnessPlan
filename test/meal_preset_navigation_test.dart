import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/meal_repository.dart';
import 'package:diet/data/repositories/food_repository.dart';
import 'package:diet/data/repositories/meal_preset_repository.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/providers/app_providers.dart';
import 'package:diet/ui/foods/foods_page.dart';
import 'package:diet/ui/foods/food_collection_page.dart';
import 'package:diet/ui/foods/custom_food_edit_page.dart';
import 'package:diet/ui/foods/food_category_art.dart';
import 'package:diet/ui/foods/food_category_page.dart';
import 'package:diet/ui/foods/food_detail_page.dart';
import 'package:diet/ui/meals/log_meal_page.dart';
import 'package:diet/ui/meals/meal_preset_detail_page.dart';
import 'package:diet/ui/meals/preset_food_add_page.dart';
import 'package:diet/domain/models.dart';
import 'package:diet/ui/widgets/form_options.dart';
import 'package:diet/ui/theme/app_theme.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpPresetApp(
  WidgetTester tester, {
  required AppDatabase db,
  required String initialLocation,
  FoodRepository? foodRepository,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(db),
      if (foodRepository != null)
        foodRepositoryProvider.overrideWithValue(foodRepository),
      foodsSeedProvider.overrideWith((ref) async {}),
    ],
  );
  addTearDown(container.dispose);
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/foods',
        builder: (_, _) => const FoodsPage(),
        routes: [
          GoRoute(
            path: 'favorites',
            builder: (_, _) =>
                const FoodCollectionPage(collection: FoodCollection.favorites),
          ),
          GoRoute(
            path: 'presets',
            builder: (_, _) =>
                const FoodCollectionPage(collection: FoodCollection.presets),
          ),
          GoRoute(
            path: 'category',
            builder: (_, state) => FoodCategoryPage(
              category: state.uri.queryParameters['name'] ?? '',
            ),
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                FoodDetailPage(foodId: int.parse(state.pathParameters['id']!)),
          ),
        ],
      ),
      GoRoute(path: '/log-meal', builder: (_, _) => const LogMealPage()),
      GoRoute(
        path: '/custom-food',
        builder: (_, state) => CustomFoodEditPage(
          returnFoodIdOnCreate:
              state.uri.queryParameters['returnFoodId'] == '1',
        ),
      ),
      GoRoute(
        path: '/food-detail/:id',
        builder: (_, state) =>
            FoodDetailPage(foodId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/meal-preset/:id/add',
        builder: (_, state) =>
            PresetFoodAddPage(presetId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/meal-preset/:id',
        builder: (_, state) => MealPresetDetailPage(
          presetId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(path: '/today', builder: (_, _) => const Scaffold()),
      GoRoute(path: '/day-meals', builder: (_, _) => const Scaffold()),
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
}

class _FailingFoodRepository extends FoodRepository {
  _FailingFoodRepository(super.db);

  @override
  Future<void> deleteCustom(int id) async {
    throw StateError('删除失败');
  }
}

Future<int> seedPreset(AppDatabase db) async {
  final foodId = await db
      .into(db.foodItems)
      .insert(
        FoodItemsCompanion.insert(
          name: '测试燕麦',
          category: '谷物',
          kcalPer100: 380,
          proteinPer100: 12,
          carbPer100: 65,
          fatPer100: 7,
        ),
      );
  final presetId = await db
      .into(db.mealPresets)
      .insert(
        MealPresetsCompanion.insert(name: '测试套餐', createdAt: DateTime.now()),
      );
  await db
      .into(db.mealPresetItems)
      .insert(
        MealPresetItemsCompanion.insert(
          presetId: presetId,
          foodId: foodId,
          foodName: '测试燕麦',
          grams: 100,
          mealType: 'breakfast',
        ),
      );
  return presetId;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('log meal preset opens detail before adding any meal', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await seedPreset(db);
    await pumpPresetApp(tester, db: db, initialLocation: '/log-meal');
    await tester.tap(find.text('测试套餐'));
    await tester.pumpAndSettle();
    expect(find.byType(MealPresetDetailPage), findsOneWidget);
    expect(find.text('加入今天'), findsOneWidget);
    expect(find.text('测试燕麦'), findsOneWidget);
    expect(find.text('380'), findsOneWidget);
    expect(await MealRepository(db).forDay(DateTime.now()), isEmpty);
  });

  testWidgets('applying from detail shows counts and opens today records', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await seedPreset(db);
    await pumpPresetApp(tester, db: db, initialLocation: '/meal-preset/$id');
    await tester.tap(find.text('加入今天'));
    await tester.pumpAndSettle();
    expect(await MealRepository(db).forDay(DateTime.now()), hasLength(1));
    expect(find.byType(MealPresetDetailPage), findsNothing);
    expect(find.textContaining('已加入 1 项'), findsOneWidget);
  });

  testWidgets('missing food is pruned and empty preset can be edited', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await seedPreset(db);
    await db.delete(db.foodItems).go();
    await pumpPresetApp(tester, db: db, initialLocation: '/meal-preset/$id');
    expect(find.text('套餐中没有食材'), findsOneWidget);
    expect(
      (await MealPresetRepository(db, MealRepository(db)).itemsFor(id)),
      isEmpty,
    );
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '加入今天'),
    );
    expect(button.onPressed, isNull);
    expect(find.byTooltip('添加食材'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '添加食材'), findsNothing);
    await tester.tap(find.byTooltip('添加食材'));
    await tester.pumpAndSettle();
    expect(find.byType(PresetFoodAddPage), findsOneWidget);
  });

  testWidgets('apply feedback includes foods pruned from the preset', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await seedPreset(db);
    final missingId = await db
        .into(db.foodItems)
        .insert(
          FoodItemsCompanion.insert(
            name: '待删除食材',
            category: '其他',
            kcalPer100: 10,
            proteinPer100: 0,
            carbPer100: 0,
            fatPer100: 0,
          ),
        );
    await db
        .into(db.mealPresetItems)
        .insert(
          MealPresetItemsCompanion.insert(
            presetId: id,
            foodId: missingId,
            foodName: '待删除食材',
            grams: 50,
            mealType: 'lunch',
          ),
        );
    await (db.delete(db.foodItems)..where((t) => t.id.equals(missingId))).go();
    await pumpPresetApp(tester, db: db, initialLocation: '/meal-preset/$id');
    await tester.tap(find.text('加入今天'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 项缺失食材'), findsOneWidget);
    expect(await MealRepository(db).forDay(DateTime.now()), hasLength(1));
  });

  testWidgets('category preset entry stays visible and opens detail', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await pumpPresetApp(tester, db: db, initialLocation: '/foods');
    expect(find.byKey(const ValueKey('category-presets')), findsOneWidget);
    expect(find.byKey(const ValueKey('category-favorites')), findsOneWidget);
    final favorites = find.byKey(const ValueKey('category-favorites'));
    final presets = find.byKey(const ValueKey('category-presets'));
    expect(
      tester.getTopLeft(favorites).dy,
      lessThan(tester.getTopLeft(presets).dy),
    );
    expect(
      tester.getTopLeft(presets).dy,
      lessThan(tester.getTopLeft(find.text('自定义')).dy),
    );
    expect(
      find.descendant(of: favorites, matching: find.byType(FoodCategoryAvatar)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: presets, matching: find.byType(FoodCategoryAvatar)),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('category-presets')));
    await tester.pumpAndSettle();
    expect(find.text('还没有常用套餐'), findsOneWidget);
    await seedPreset(db);
    // The list provider is fetched when the page mounts; reopen to refresh it.
    await tester.pumpWidget(const SizedBox());
    await pumpPresetApp(tester, db: db, initialLocation: '/foods');
    expect(find.text('套餐'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('谷物')).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('category-favorites'))).dy,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('category-presets')));
    await tester.pumpAndSettle();
    expect(find.text('测试套餐'), findsOneWidget);
    await tester.tap(find.text('测试套餐'));
    await tester.pumpAndSettle();
    expect(find.byType(MealPresetDetailPage), findsOneWidget);
    expect(find.text('测试燕麦'), findsOneWidget);
    expect(await MealRepository(db).forDay(DateTime.now()), isEmpty);
  });

  testWidgets('preset detail edits the original preset', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await seedPreset(db);
    await pumpPresetApp(tester, db: db, initialLocation: '/meal-preset/$id');
    final itemId = (await MealPresetRepository(
      db,
      MealRepository(db),
    ).itemsFor(id)).single.id;
    expect(find.byTooltip('编辑'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('preset-name')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('preset-name-input')),
      '改名套餐',
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('preset-grams-$itemId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('preset-manual-toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('preset-manual-grams')),
      '200',
    );
    await tester.tap(find.text('保存').last);
    await tester.pumpAndSettle();
    expect(find.text('760'), findsOneWidget);
    final repo = MealPresetRepository(db, MealRepository(db));
    expect((await repo.presetById(id))!.name, '改名套餐');
    expect((await repo.itemsFor(id)).single.grams, 200);
    expect(find.text('加入今天'), findsOneWidget);
  });

  testWidgets(
    'preset detail adds and removes food without changing meal on grams edit',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final id = await seedPreset(db);
      await db
          .into(db.foodItems)
          .insert(
            FoodItemsCompanion.insert(
              name: '测试牛奶',
              category: '乳制品',
              kcalPer100: 60,
              proteinPer100: 3,
              carbPer100: 5,
              fatPer100: 3,
            ),
          );
      await pumpPresetApp(tester, db: db, initialLocation: '/meal-preset/$id');
      await tester.tap(find.byTooltip('添加食材'));
      await tester.pumpAndSettle();
      expect(find.byType(PresetFoodAddPage), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, '测试牛奶');
      await tester.pumpAndSettle();
      await tester.tap(find.text('测试牛奶').last);
      await tester.pumpAndSettle();
      final mealDropdown = tester.widget<AppDropdown<MealType>>(
        find.byType(AppDropdown<MealType>),
      );
      mealDropdown.onChanged(MealType.dinner);
      await tester.pumpAndSettle();
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      final repo = MealPresetRepository(db, MealRepository(db));
      final itemsAfterAdd = await repo.itemsFor(id);
      final milk = itemsAfterAdd.last;
      final oats = itemsAfterAdd.first;
      expect(await MealRepository(db).forDay(DateTime.now()), isEmpty);
      await tester.tap(find.byKey(ValueKey('preset-grams-${milk.id}')));
      await tester.pumpAndSettle();
      expect(find.text('餐别'), findsNothing);
      await tester.tap(find.text('保存').last);
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(ValueKey('preset-item-${oats.id}')),
        const Offset(-350, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除').last);
      await tester.pumpAndSettle();
      final items = await MealPresetRepository(
        db,
        MealRepository(db),
      ).itemsFor(id);
      expect(items, hasLength(1));
      expect(items.single.foodName, '测试牛奶');
      expect(items.single.mealType, 'dinner');
      expect(await MealRepository(db).forDay(DateTime.now()), isEmpty);
    },
  );

  testWidgets('category preset list can delete a preset', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await seedPreset(db);
    await pumpPresetApp(tester, db: db, initialLocation: '/foods');
    await tester.tap(find.byKey(const ValueKey('category-presets')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(ValueKey('foods-preset-$id')),
      const Offset(-350, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('确定删除「测试套餐」？'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(
      await MealPresetRepository(db, MealRepository(db)).presetById(id),
      isNotNull,
    );
    await tester.drag(
      find.byKey(ValueKey('foods-preset-$id')),
      const Offset(-350, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();
    expect(
      await MealPresetRepository(db, MealRepository(db)).presetById(id),
      isNull,
    );
    expect(find.text('还没有常用套餐'), findsOneWidget);
  });

  testWidgets('favorite category opens food detail and supports removal', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await seedPreset(db);
    final food = (await db.select(db.foodItems).get()).single;
    await FoodRepository(db).toggleFavorite(food.id);
    await pumpPresetApp(tester, db: db, initialLocation: '/foods');
    expect(find.byKey(const ValueKey('category-favorites')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('category-favorites')));
    await tester.pumpAndSettle();
    expect(find.text('测试燕麦'), findsOneWidget);
    await tester.tap(find.text('测试燕麦'));
    await tester.pumpAndSettle();
    expect(find.byType(FoodDetailPage), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(ValueKey('favorite-food-${food.id}')),
      const Offset(-350, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('测试燕麦'), findsOneWidget);
    await tester.drag(
      find.byKey(ValueKey('favorite-food-${food.id}')),
      const Offset(-350, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('移除').last);
    await tester.pumpAndSettle();
    expect(find.text('暂无收藏'), findsOneWidget);
  });

  testWidgets('category swipes delete only custom foods and update count', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await seedPreset(db);
    final builtIn = (await db.select(db.foodItems).get()).single;
    final customId = await db
        .into(db.foodItems)
        .insert(
          FoodItemsCompanion.insert(
            name: '自制燕麦',
            category: '谷物',
            kcalPer100: 350,
            proteinPer100: 10,
            carbPer100: 60,
            fatPer100: 6,
            isCustom: const Value(true),
          ),
        );
    await pumpPresetApp(tester, db: db, initialLocation: '/foods');
    await tester.tap(find.text('谷物'));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('category-food-$customId')), findsOneWidget);
    expect(find.byKey(ValueKey(builtIn.id)), findsOneWidget);
    await tester.drag(find.byKey(ValueKey(builtIn.id)), const Offset(-350, 0));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(await FoodRepository(db).byId(builtIn.id), isNotNull);
    await tester.drag(
      find.byKey(ValueKey('category-food-$customId')),
      const Offset(-350, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('删除自定义食材'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(await FoodRepository(db).byId(customId), isNotNull);
    await tester.drag(
      find.byKey(ValueKey('category-food-$customId')),
      const Offset(-350, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();
    expect(await FoodRepository(db).byId(customId), isNull);
    expect(find.text('自制燕麦'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(FoodCategoryPage),
        matching: find.byKey(ValueKey(builtIn.id)),
      ),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('1 种'), findsOneWidget);
  });

  testWidgets('failed category delete keeps the custom food', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final customId = await db
        .into(db.foodItems)
        .insert(
          FoodItemsCompanion.insert(
            name: '保留食材',
            category: '自定义',
            kcalPer100: 100,
            proteinPer100: 1,
            carbPer100: 2,
            fatPer100: 3,
            isCustom: const Value(true),
          ),
        );
    await pumpPresetApp(
      tester,
      db: db,
      initialLocation: '/foods/category?name=自定义',
      foodRepository: _FailingFoodRepository(db),
    );
    await tester.drag(
      find.byKey(ValueKey('category-food-$customId')),
      const Offset(-350, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('category-food-$customId')), findsOneWidget);
    expect(await FoodRepository(db).byId(customId), isNotNull);
    expect(find.textContaining('删除失败'), findsOneWidget);
  });

  testWidgets('cancel edit restores preset and invalid name blocks save', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await seedPreset(db);
    await db
        .into(db.mealPresets)
        .insert(
          MealPresetsCompanion.insert(name: '已有套餐', createdAt: DateTime.now()),
        );
    await pumpPresetApp(tester, db: db, initialLocation: '/meal-preset/$id');
    await tester.tap(find.byKey(const ValueKey('preset-name')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('preset-name-input')), '');
    await tester.tap(find.text('保存'));
    await tester.pump();
    expect(find.text('请输入套餐名称'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('preset-name-input')),
      '已有套餐',
    );
    await tester.tap(find.text('保存'));
    await tester.pump();
    expect(find.text('套餐名称已存在'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('preset-name-input')),
      '临时名称',
    );
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    final itemId = (await MealPresetRepository(
      db,
      MealRepository(db),
    ).itemsFor(id)).single.id;
    await tester.tap(find.byKey(ValueKey('preset-grams-$itemId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('preset-manual-toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('preset-manual-grams')),
      '250',
    );
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('加入今天'), findsOneWidget);
    final repo = MealPresetRepository(db, MealRepository(db));
    expect((await repo.presetById(id))!.name, '测试套餐');
    expect((await repo.itemsFor(id)).single.grams, 100);
  });

  testWidgets(
    'food search hides category shortcuts and clearing restores them',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await seedPreset(db);
      await pumpPresetApp(tester, db: db, initialLocation: '/foods');
      expect(find.byKey(const ValueKey('category-presets')), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '测试燕麦');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('category-presets')), findsNothing);
      expect(find.text('测试套餐'), findsNothing);
      await tester.enterText(find.byType(TextField).first, '');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('category-presets')), findsOneWidget);
    },
  );

  testWidgets(
    'preset food name opens detail and refreshes nutrition on return',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final id = await seedPreset(db);
      final foodId = (await db.select(db.foodItems).get()).single.id;
      await pumpPresetApp(tester, db: db, initialLocation: '/meal-preset/$id');
      final name = tester.widget<Text>(find.text('测试燕麦'));
      expect(name.style?.color, AppColors.carb);
      await tester.tap(find.text('测试燕麦'));
      await tester.pumpAndSettle();
      expect(find.byType(FoodDetailPage), findsOneWidget);
      await (db.update(db.foodItems)..where((t) => t.id.equals(foodId))).write(
        const FoodItemsCompanion(kcalPer100: Value(400)),
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('400'), findsOneWidget);
    },
  );

  testWidgets('preset wheel amount saves immediately', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await seedPreset(db);
    final repo = MealPresetRepository(db, MealRepository(db));
    final itemId = (await repo.itemsFor(id)).single.id;
    await pumpPresetApp(tester, db: db, initialLocation: '/meal-preset/$id');
    await tester.tap(find.byKey(ValueKey('preset-grams-$itemId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppDropdown<double>));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CupertinoPicker), const Offset(0, -40));
    await tester.pumpAndSettle();
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect((await repo.itemsFor(id)).single.grams, 105);
  });

  testWidgets('swiping the only food keeps an empty preset', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await seedPreset(db);
    final repo = MealPresetRepository(db, MealRepository(db));
    final itemId = (await repo.itemsFor(id)).single.id;
    await pumpPresetApp(tester, db: db, initialLocation: '/meal-preset/$id');
    await tester.drag(
      find.byKey(ValueKey('preset-item-$itemId')),
      const Offset(-350, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();
    expect(await repo.itemsFor(id), isEmpty);
    expect(await repo.presetById(id), isNotNull);
    expect(find.text('套餐中没有食材'), findsOneWidget);
    expect(find.byTooltip('添加食材'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '加入今天'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('swiping a meal section clears its foods', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await seedPreset(db);
    final repo = MealPresetRepository(db, MealRepository(db));
    await pumpPresetApp(tester, db: db, initialLocation: '/meal-preset/$id');
    await tester.drag(find.text('早餐'), const Offset(-350, 0));
    await tester.pumpAndSettle();
    expect(find.textContaining('早餐的全部食材'), findsOneWidget);
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();
    expect(await repo.itemsFor(id), isEmpty);
    expect(find.text('套餐中没有食材'), findsOneWidget);
  });

  testWidgets('preset picker offers favorites, recent, and common portions', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final presetId = await seedPreset(db);
    final oat = (await db.select(db.foodItems).get()).single;
    final milkId = await db
        .into(db.foodItems)
        .insert(
          FoodItemsCompanion.insert(
            name: '收藏牛奶',
            category: '乳制品',
            kcalPer100: 60,
            proteinPer100: 3,
            carbPer100: 5,
            fatPer100: 3,
          ),
        );
    await FoodRepository(db).toggleFavorite(milkId);
    await FoodRepository(
      db,
    ).addServing(foodId: milkId, label: '一杯', grams: 240);
    await db
        .into(db.mealEntries)
        .insert(
          MealEntriesCompanion.insert(
            date: DateTime(2025, 1, 1),
            mealType: 'breakfast',
            foodId: oat.id,
            foodName: oat.name,
            grams: 100,
            calories: 380,
            proteinG: 12,
            carbG: 65,
            fatG: 7,
          ),
        );
    await pumpPresetApp(
      tester,
      db: db,
      initialLocation: '/meal-preset/$presetId',
    );
    await tester.tap(find.byTooltip('添加食材'));
    await tester.pumpAndSettle();
    expect(find.text('收藏'), findsOneWidget);
    expect(find.text('最近吃过'), findsOneWidget);
    await tester.tap(find.text('收藏牛奶'));
    await tester.pumpAndSettle();
    expect(find.textContaining('一杯'), findsOneWidget);
    await tester.tap(find.textContaining('一杯'));
    await tester.pumpAndSettle();
    final mealDropdown = tester.widget<AppDropdown<MealType>>(
      find.byType(AppDropdown<MealType>),
    );
    mealDropdown.onChanged(MealType.lunch);
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    final items = await MealPresetRepository(
      db,
      MealRepository(db),
    ).itemsFor(presetId);
    expect(items.last.foodId, milkId);
    expect(items.last.grams, 240);
    expect(items.last.mealType, 'lunch');
    expect(await MealRepository(db).forDay(DateTime.now()), isEmpty);
  });

  testWidgets('custom food creation returns to preset picker without logging', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final presetId = await seedPreset(db);
    await pumpPresetApp(
      tester,
      db: db,
      initialLocation: '/meal-preset/$presetId',
    );
    await tester.tap(find.byTooltip('添加食材'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('添加自定义食材'));
    await tester.pumpAndSettle();
    expect(find.byType(CustomFoodEditPage), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '自制食材');
    await tester.enterText(find.byType(TextField).at(1), '100');
    await tester.tap(find.text('保存').last);
    await tester.pumpAndSettle();
    expect(find.byType(PresetFoodAddPage), findsOneWidget);
    expect(find.byKey(const ValueKey('preset-selected-food')), findsOneWidget);
    expect(await MealRepository(db).forDay(DateTime.now()), isEmpty);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    final items = await MealPresetRepository(
      db,
      MealRepository(db),
    ).itemsFor(presetId);
    expect(items.last.foodName, '自制食材');
    expect(await MealRepository(db).forDay(DateTime.now()), isEmpty);
  });

  testWidgets('each meal shows its own macros and updates after grams change', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final presetId = await seedPreset(db);
    final repo = MealPresetRepository(db, MealRepository(db));
    final oat = (await repo.itemsFor(presetId)).single;
    final milkId = await db
        .into(db.foodItems)
        .insert(
          FoodItemsCompanion.insert(
            name: '晚餐牛奶',
            category: '乳制品',
            kcalPer100: 60,
            proteinPer100: 3,
            carbPer100: 5,
            fatPer100: 3,
          ),
        );
    final milkItemId = await repo.addItem(
      presetId: presetId,
      foodId: milkId,
      grams: 100,
      mealType: MealType.dinner,
    );
    await pumpPresetApp(
      tester,
      db: db,
      initialLocation: '/meal-preset/$presetId',
    );
    final breakfast = find.byKey(
      const ValueKey('preset-meal-macros-breakfast'),
    );
    final dinner = find.byKey(const ValueKey('preset-meal-macros-dinner'));
    final breakfastHeaderDivider = find.byKey(
      const ValueKey('preset-meal-header-divider-breakfast'),
    );
    final dinnerHeaderDivider = find.byKey(
      const ValueKey('preset-meal-header-divider-dinner'),
    );
    final breakfastDivider = find.byKey(
      const ValueKey('preset-meal-divider-breakfast'),
    );
    final dinnerDivider = find.byKey(
      const ValueKey('preset-meal-divider-dinner'),
    );
    expect(breakfastDivider, findsOneWidget);
    expect(dinnerDivider, findsOneWidget);
    expect(breakfastHeaderDivider, findsOneWidget);
    expect(dinnerHeaderDivider, findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('preset-meal-breakfast')),
        matching: breakfastDivider,
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('preset-meal-dinner')),
        matching: dinnerDivider,
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(breakfastHeaderDivider).dy,
      lessThan(tester.getTopLeft(find.text('早餐')).dy),
    );
    expect(
      tester.getTopLeft(find.text('早餐')).dy,
      lessThan(tester.getTopLeft(breakfast).dy),
    );
    expect(
      tester.getTopLeft(breakfast).dy,
      lessThan(tester.getTopLeft(breakfastDivider).dy),
    );
    expect(
      tester.getTopLeft(breakfastDivider).dy,
      lessThan(
        tester.getTopLeft(find.byKey(ValueKey('preset-item-${oat.id}'))).dy,
      ),
    );
    expect(
      tester.getTopLeft(dinnerHeaderDivider).dy,
      lessThan(tester.getTopLeft(find.text('晚餐')).dy),
    );
    expect(
      tester.getTopLeft(find.text('晚餐')).dy,
      lessThan(tester.getTopLeft(dinner).dy),
    );
    expect(
      tester.getTopLeft(dinner).dy,
      lessThan(tester.getTopLeft(dinnerDivider).dy),
    );
    expect(
      tester.getTopLeft(dinnerDivider).dy,
      lessThan(
        tester.getTopLeft(find.byKey(ValueKey('preset-item-$milkItemId'))).dy,
      ),
    );
    expect(
      find.descendant(of: breakfast, matching: find.text('12.0 g')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: breakfast, matching: find.text('65.0 g')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dinner, matching: find.text('3.0 g')),
      findsNWidgets(2),
    );
    await tester.tap(find.byKey(ValueKey('preset-grams-${oat.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('preset-manual-toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('preset-manual-grams')),
      '200',
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: breakfast, matching: find.text('24.0 g')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: breakfast, matching: find.text('130.0 g')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dinner, matching: find.text('3.0 g')),
      findsNWidgets(2),
    );
    await tester.drag(find.text('晚餐'), const Offset(-350, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();
    expect(dinner, findsNothing);
    expect(dinnerDivider, findsNothing);
    expect(dinnerHeaderDivider, findsNothing);
    expect(
      find.descendant(of: breakfast, matching: find.text('24.0 g')),
      findsOneWidget,
    );
  });
}
