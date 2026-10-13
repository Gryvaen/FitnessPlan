import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/day_marker_repository.dart';
import 'package:diet/data/repositories/meal_repository.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/ui/theme/app_theme.dart';
import 'package:diet/ui/today/deficit_date_picker.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final themeId in AppThemeId.values) {
    testWidgets('marker options stay flat in ${themeId.name} theme', (
      tester,
    ) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final today = CalendarDay.todayLocal();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.ofId(themeId),
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDeficitDatePicker(
                  context: context,
                  initialDate: today,
                  firstDate: today,
                  lastDate: today,
                  plannedDeficit: 0,
                  mealRepository: MealRepository(db),
                  markerRepository: DayMarkerRepository(db),
                  loadTargets: (_, _) async => {},
                ),
                child: const Text('Open calendar'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open calendar'));
      await tester.pumpAndSettle();
      await tester.longPress(
        find.byKey(
          ValueKey('deficitDay-${today.year}-${today.month}-${today.day}'),
        ),
      );
      await tester.pumpAndSettle();
      final rest = find.byKey(const ValueKey('marker-option-restDay'));
      final cheat = find.byKey(const ValueKey('marker-option-cheatMeal'));
      expect(
        find.descendant(of: rest, matching: find.byType(Material)),
        findsNothing,
      );
      expect(
        find.descendant(of: cheat, matching: find.byType(Material)),
        findsNothing,
      );
      await tester.tap(rest);
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.text('Rest day')).style?.color,
        AppTheme.visualsFor(themeId).accent,
      );
      expect(find.text('Delay carb cycle by one day'), findsOneWidget);
      await tester.tap(cheat);
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.text('Cheat day')).style?.color,
        AppTheme.visualsFor(themeId).accent,
      );
      expect(find.text('1000'), findsOneWidget);
    });
  }

  testWidgets('calendar marker sheet saves, prefills and cancels settings', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DayMarkerRepository(db);
    final today = CalendarDay.todayLocal();
    final dayKey = ValueKey(
      'deficitDay-${today.year}-${today.month}-${today.day}',
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDeficitDatePicker(
                context: context,
                initialDate: today,
                firstDate: today,
                lastDate: today,
                plannedDeficit: 0,
                mealRepository: MealRepository(db),
                markerRepository: repo,
                loadTargets: (_, _) async => {},
              ),
              child: const Text('Open calendar'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open calendar'));
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(dayKey));
    await tester.pumpAndSettle();
    expect(find.text('Rest day'), findsOneWidget);
    expect(find.text('Cheat day'), findsOneWidget);
    expect(find.text('Delay carb cycle by one day'), findsNothing);
    expect(find.text('Deduct cultivation'), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('marker-option-cheatMeal')));
    await tester.pumpAndSettle();
    expect(find.text('1000'), findsOneWidget);
    expect((await repo.settingsForDay(today)), isNull);
    await tester.tap(find.byKey(const ValueKey('marker-option-restDay')));
    await tester.pumpAndSettle();
    expect(find.text('Delay carb cycle by one day'), findsOneWidget);
    expect(find.text('Deduct cultivation'), findsNothing);
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();
    expect((await repo.settingsForDay(today))!.pauseCarbCycle, isFalse);

    await tester.longPress(find.byKey(dayKey));
    await tester.pumpAndSettle();
    expect(find.text('Cycle unchanged'), findsOneWidget);
    expect(find.text('Delay carb cycle by one day'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('marker-option-restDay')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delay carb cycle by one day'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();
    expect((await repo.settingsForDay(today))!.pauseCarbCycle, isTrue);

    await tester.longPress(find.byKey(dayKey));
    await tester.pumpAndSettle();
    expect(find.text('Cycle delayed one day'), findsOneWidget);
    expect(find.text('Delay carb cycle by one day'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('marker-option-cheatMeal')));
    await tester.pumpAndSettle();
    expect(find.text('1000'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '650');
    await tester.pump();
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();
    expect((await repo.settingsForDay(today))!.penaltyKcal, -650);

    await tester.longPress(find.byKey(dayKey));
    await tester.pumpAndSettle();
    expect(find.text('Deduct 650 kcal'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byKey(const ValueKey('marker-option-cheatMeal')));
    await tester.pumpAndSettle();
    expect(find.text('650'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '0');
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed,
      isNull,
    );
    await tester.enterText(find.byType(TextField), '650');
    await tester.pump();
    await tester.tap(find.text('Deduct cultivation'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();
    final disabled = (await repo.settingsForDay(today))!;
    expect(disabled.penaltyKcal, 0);
    expect(disabled.cheatPenaltyKcal, 650);

    await tester.longPress(find.byKey(dayKey));
    await tester.pumpAndSettle();
    expect(find.text('No cultivation deduction'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('marker-option-cheatMeal')));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Deduct cultivation'));
    await tester.pumpAndSettle();
    expect(find.text('650'), findsOneWidget);
    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();
    expect((await repo.settingsForDay(today))!.penaltyKcal, 0);

    await tester.longPress(find.byKey(dayKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear marker'));
    await tester.pumpAndSettle();
    expect(await repo.settingsForDay(today), isNull);
  });

  testWidgets('backfilled rest day cannot delay the carb cycle', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DayMarkerRepository(db);
    final today = CalendarDay.todayLocal();
    final yesterday = today.subtract(const Duration(days: 1));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDeficitDatePicker(
                context: context,
                initialDate: yesterday,
                firstDate: yesterday,
                lastDate: today,
                plannedDeficit: 0,
                mealRepository: MealRepository(db),
                markerRepository: repo,
                loadTargets: (_, _) async => {},
              ),
              child: const Text('Open calendar'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open calendar'));
    await tester.pumpAndSettle();
    await tester.longPress(
      find.byKey(
        ValueKey(
          'deficitDay-${yesterday.year}-${yesterday.month}-${yesterday.day}',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Marking a past day will not change later carb-cycle days.'),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('marker-option-restDay')));
    await tester.pumpAndSettle();
    expect(
      find.text('Marking a past day will not change later carb-cycle days.'),
      findsOneWidget,
    );
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
      isNull,
    );
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();
    expect((await repo.settingsForDay(yesterday))!.pauseCarbCycle, isFalse);
  });
}
