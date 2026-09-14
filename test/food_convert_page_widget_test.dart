import 'package:diet/data/db.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/providers/app_providers.dart';
import 'package:diet/ui/theme/app_theme.dart';
import 'package:diet/ui/tools/food_convert_page.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

late AppDatabase _db;
late ProviderContainer _container;

Future<void> _setUp() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  _db = AppDatabase.forTesting(NativeDatabase.memory());
  _container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(_db),
    ],
  );
  // A food with a rich macro profile (protein + carb + fat + a couple of
  // micronutrients) and a common serving, so the result card and the
  // food-specific portion chips both have something to render.
  final chickenId = await _db
      .into(_db.foodItems)
      .insert(
        FoodItemsCompanion.insert(
          name: 'Chicken rice bowl',
          category: '主食',
          kcalPer100: 220,
          proteinPer100: 12,
          carbPer100: 28,
          fatPer100: 6,
          fiberPer100: const Value(1.2),
          sodiumMgPer100: const Value(180),
        ),
      );
  await _db
      .into(_db.foodServings)
      .insert(
        FoodServingsCompanion.insert(
          foodId: chickenId,
          label: '1 bowl',
          grams: 350,
        ),
      );
  // A second, unrelated food to prove multiple entries sum correctly.
  await _db
      .into(_db.foodItems)
      .insert(
        FoodItemsCompanion.insert(
          name: 'Steamed egg',
          category: '蛋类',
          kcalPer100: 140,
          proteinPer100: 13,
          carbPer100: 1,
          fatPer100: 10,
        ),
      );
}

Widget _app({AppThemeId themeId = AppThemeId.fresh}) {
  return UncontrolledProviderScope(
    container: _container,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.ofId(themeId),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const FoodConvertPage(),
    ),
  );
}

void _expectNoLayoutErrors(WidgetTester tester) {
  final error = tester.takeException();
  expect(error, isNull, reason: 'layout error: $error');
}

/// Searches with [query] (a strict substring of [name], so it never collides
/// with the result row's own text), taps Add on the [name] result, and confirms
/// the portion sheet so the food lands on the running list.
Future<void> _addFood(WidgetTester tester, String query, String name) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pumpAndSettle();
  _expectNoLayoutErrors(tester);
  expect(find.text(name), findsOneWidget);
  await tester.tap(find.byTooltip('Add'));
  await tester.pumpAndSettle();
  _expectNoLayoutErrors(tester);
  // Selecting a food opens the portion sheet; confirm the default 100 g.
  expect(find.widgetWithText(FilledButton, 'Done'), findsOneWidget);
  await tester.tap(find.widgetWithText(FilledButton, 'Done'));
  await tester.pumpAndSettle();
  _expectNoLayoutErrors(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_setUp);
  tearDown(() async {
    _container.dispose();
    await _db.close();
  });

  Future<void> pump(WidgetTester tester, {AppThemeId themeId = AppThemeId.fresh}) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(themeId: themeId));
    await tester.pumpAndSettle();
    _expectNoLayoutErrors(tester);
  }

  testWidgets(
    'adding two foods sums their totals; the search field stays free to add more',
    (tester) async {
      await pump(tester);

      await _addFood(tester, 'Chicken', 'Chicken rice bowl');
      // Search field cleared itself; the entry now shows on the running list.
      expect(find.widgetWithText(TextField, 'Chicken'), findsNothing);
      expect(find.text('Added (1)'), findsOneWidget);
      expect(find.textContaining('100 g · 220 kcal'), findsOneWidget);
      expect(find.text('220'), findsOneWidget); // total == the one entry

      await _addFood(tester, 'Steamed', 'Steamed egg');
      expect(find.text('Added (2)'), findsOneWidget);
      expect(find.textContaining('100 g · 140 kcal'), findsOneWidget);
      // Combined total: 220 + 140 = 360 kcal.
      expect(find.text('360'), findsOneWidget);
      expect(find.text('Result'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping an entry opens the portion sheet; common servings update it',
    (tester) async {
      await pump(tester);
      await _addFood(tester, 'Chicken', 'Chicken rice bowl');

      await tester.tap(find.textContaining('100 g · 220 kcal'));
      await tester.pumpAndSettle();
      _expectNoLayoutErrors(tester);

      // Food-specific serving chip from FoodServings; no generic quick chips.
      expect(find.text('50 g'), findsNothing);
      await tester.tap(find.textContaining('1 bowl'));
      await tester.pumpAndSettle();
      expect(find.text('770 kcal · 350 g'), findsOneWidget); // 220 * 3.5

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      _expectNoLayoutErrors(tester);
      expect(find.textContaining('350 g · 770 kcal'), findsOneWidget);
      expect(find.text('770'), findsOneWidget); // total updates too
    },
  );

  testWidgets('removing via the sheet and via swipe both work', (
    tester,
  ) async {
    await pump(tester);
    await _addFood(tester, 'Chicken', 'Chicken rice bowl');
    await _addFood(tester, 'Steamed', 'Steamed egg');
    expect(find.text('Added (2)'), findsOneWidget);

    // Swipe left removes without opening the sheet.
    await tester.drag(
      find.textContaining('100 g · 140 kcal'),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    _expectNoLayoutErrors(tester);
    expect(find.text('Added (1)'), findsOneWidget);

    // The sheet's own "Remove" button also removes the entry.
    await tester.tap(find.textContaining('100 g · 220 kcal'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Remove'));
    await tester.pumpAndSettle();
    _expectNoLayoutErrors(tester);
    expect(find.textContaining('Added ('), findsNothing);
    expect(find.textContaining('Search or pick a favorite'), findsOneWidget);
  });

  testWidgets('picking a food unfocuses search so the keyboard stays down', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'Chicken');
    await tester.pumpAndSettle();
    final searchFocus =
        tester.widget<TextField>(find.byType(TextField)).focusNode!;
    expect(searchFocus.hasFocus, isTrue);

    await tester.tap(find.byTooltip('Add'));
    await tester.pumpAndSettle();
    // Portion sheet is up; the search field must no longer hold focus.
    expect(searchFocus.hasFocus, isFalse);

    // Closing the sheet must not restore focus to the search field.
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();
    expect(searchFocus.hasFocus, isFalse);
  });

  testWidgets('"Clear all" empties the list in one tap', (tester) async {
    await pump(tester);
    await _addFood(tester, 'Chicken', 'Chicken rice bowl');
    await _addFood(tester, 'Steamed', 'Steamed egg');

    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();
    _expectNoLayoutErrors(tester);
    expect(find.textContaining('Added ('), findsNothing);
  });

  testWidgets('favoriting from a search result works without adding it', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'Chicken');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Favorites'));
    await tester.pumpAndSettle();
    _expectNoLayoutErrors(tester);
    // Toggling favorite must not have added it to the running list.
    expect(find.textContaining('Added ('), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('Chicken rice bowl'), findsOneWidget); // now in favorites
  });

  testWidgets('renders without overflow in a dark theme too', (tester) async {
    await pump(tester, themeId: AppThemeId.graphite);
    await _addFood(tester, 'Chicken', 'Chicken rice bowl');
    await _addFood(tester, 'Steamed', 'Steamed egg');
    _expectNoLayoutErrors(tester);
    expect(find.text('Result'), findsOneWidget);
  });
}
