import 'package:diet/data/db.dart';
import 'package:diet/domain/models.dart';
import 'package:diet/ui/widgets/form_options.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/providers/app_providers.dart';
import 'package:diet/ui/foods/custom_food_edit_page.dart';
import 'package:diet/ui/ink/ink_icon.dart';
import 'package:diet/ui/meals/meal_detail_page.dart';
import 'package:diet/ui/theme/app_theme.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder field(String label) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.labelText == label,
);
final toggle = find.byKey(const ValueKey('temporary-food-toggle'));
Finder get kcal => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.labelText?.contains('kcal') == true,
);

Future<void> openForm(
  WidgetTester tester,
  AppDatabase db, {
  bool dark = false,
  bool preset = false,
  int? foodId,
  bool fromRecord = true,
  bool fromMeal = true,
  MealType? mealType = MealType.lunch,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/create'),
            child: const Text('打开'),
          ),
        ),
      ),
      GoRoute(
        path: '/create',
        builder: (context, state) => CustomFoodEditPage(
          openDetailOnCreate: fromRecord,
          fromMeal: fromMeal,
          initialMealType: mealType,
          returnFoodIdOnCreate: preset,
          foodId: foodId,
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: dark ? AppTheme.ofId(AppThemeId.graphite) : AppTheme.light,
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
      ),
    ),
  );
  await tester.tap(find.text('打开'));
  await tester.pumpAndSettle();
}

Future<void> reveal(WidgetTester tester, Finder target) async {
  tester.testTextInput.hide();
  await tester.scrollUntilVisible(
    target,
    200,
    scrollable: find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'three modes preserve independent drafts and save weighted food, dark=$dark',
      (tester) async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        tester.view.physicalSize = const Size(360, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await openForm(tester, db, dark: dark);
        expect(find.text('添加自定义食物'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) => w is InkIcon && w.glyph == InkGlyph.foodSaved,
          ),
          findsOneWidget,
        );
        await tester.enterText(field('名称'), '外卖');
        await tester.enterText(kcal, '100');
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(find.text('记录临时食物'), findsOneWidget);
        expect(tester.widget<TextField>(kcal).controller!.text, isEmpty);
        expect(
          tester.widget<TextField>(field('摄入重量（g）')).controller!.text,
          isEmpty,
        );
        expect(field('糖 (g，可选)'), findsNothing);
        await tester.enterText(kcal, '200');
        await reveal(tester, find.text('加入饮食记录'));
        await tester.tap(find.text('加入饮食记录'));
        await tester.pumpAndSettle();
        expect(find.text('请输入大于 0 的有效重量'), findsOneWidget);
        expect(
          await tester.runAsync(() => db.select(db.mealEntries).get()),
          isEmpty,
        );
        await tester.scrollUntilVisible(
          field('摄入重量（g）'),
          -200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.enterText(field('摄入重量（g）'), '150');
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(find.text('记录临时热量'), findsOneWidget);
        expect(tester.widget<TextField>(kcal).controller!.text, isEmpty);
        expect(field('摄入重量（g）'), findsNothing);
        await tester.enterText(kcal, '500');
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(find.text('添加自定义食物'), findsOneWidget);
        expect(tester.widget<TextField>(kcal).controller!.text, '100');
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(kcal).controller!.text, '200');
        expect(
          tester.widget<TextField>(field('摄入重量（g）')).controller!.text,
          '150',
        );
        await reveal(tester, find.text('加入饮食记录'));
        expect(find.text('本次摄入'), findsNothing);
        expect(find.text('300 kcal'), findsNothing);
        expect(find.byType(AppDropdown<MealType>), findsNothing);
        await tester.tap(find.text('加入饮食记录'));
        await tester.tap(find.text('加入饮食记录'));
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
        final entries = await tester.runAsync(
          () => db.select(db.mealEntries).get(),
        );
        expect(entries, hasLength(1));
        expect(entries!.single.calories, 300);
        expect(entries.single.grams, 150);
        expect(entries.single.mealType, MealType.lunch.name);
        expect(entries.single.caloriesOnly, isFalse);
        expect(find.text('打开'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('calorie mode saves without grams and edits total calories', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await openForm(tester, db);
    await tester.enterText(field('名称'), '一次热量');
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(field('摄入重量（g）'), findsNothing);
    expect(
      find.byKey(const ValueKey('optional-nutrition-toggle')),
      findsNothing,
    );
    await tester.enterText(kcal, '500');
    await reveal(tester, find.text('加入饮食记录'));
    await tester.tap(find.text('加入饮食记录'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    final entries = await tester.runAsync(
      () => db.select(db.mealEntries).get(),
    );
    expect(entries, hasLength(1));
    final entry = entries!.single;
    expect(entry.caloriesOnly, isTrue);
    expect(entry.calories, 500);
    expect(entry.grams, 0);
    await tester.pumpWidget(
      ProviderScope(
        key: const ValueKey('detail-scope'),
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: MealDetailPage(entryId: entry.id),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('/ 100g'), findsNothing);
    expect(find.text('克数'), findsNothing);
    final calories = find.byType(TextFormField);
    await tester.enterText(calories, '650');
    await reveal(tester, find.text('保存'));
    await tester.tap(find.text('保存'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    final updated = await tester.runAsync(
      () => (db.select(
        db.mealEntries,
      )..where((t) => t.id.equals(entry.id))).getSingle(),
    );
    expect(updated!.calories, 650);
    expect(updated.grams, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  for (final scenario in [
    (fromRecord: false, fromMeal: true, mealType: MealType.lunch),
    (fromRecord: true, fromMeal: true, mealType: null),
    (fromRecord: true, fromMeal: false, mealType: MealType.lunch),
  ]) {
    testWidgets('no temporary modes outside specified meal flow: $scenario', (
      tester,
    ) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await openForm(
        tester,
        db,
        fromRecord: scenario.fromRecord,
        fromMeal: scenario.fromMeal,
        mealType: scenario.mealType,
      );
      expect(toggle, findsNothing);
      expect(find.text('加入饮食记录'), findsNothing);
      expect(find.text('保存'), findsOneWidget);
    });
  }

  for (final mealType in MealType.values) {
    testWidgets('calorie record inherits ${mealType.name}', (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await openForm(tester, db, mealType: mealType);
      await tester.enterText(field('名称'), '餐次热量');
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.byType(AppDropdown<MealType>), findsNothing);
      expect(find.text('本次摄入'), findsNothing);
      await tester.enterText(kcal, '500');
      await reveal(tester, find.text('加入饮食记录'));
      await tester.tap(find.text('加入饮食记录'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      final entries = await tester.runAsync(
        () => db.select(db.mealEntries).get(),
      );
      expect(entries, hasLength(1));
      expect(entries!.single.mealType, mealType.name);
      expect(entries.single.calories, 500);
      expect(entries.single.caloriesOnly, isTrue);
      expect(find.text('打开'), findsOneWidget);
    });
  }

  for (final edit in [false, true]) {
    testWidgets('mode entry hidden in edit=$edit preset=${!edit}', (
      tester,
    ) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await tester.runAsync(() => db.select(db.foodItems).get());
      await openForm(tester, db, preset: !edit, foodId: edit ? 999 : null);
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pumpAndSettle();
      expect(toggle, findsNothing);
    });
  }
}
