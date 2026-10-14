import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/day_marker_repository.dart';
import 'package:diet/data/repositories/diet_strategy_repository.dart';
import 'package:diet/data/repositories/meal_repository.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/domain/diet_strategy.dart';
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
                  loadStrategyForDay: (_) async => DietStrategyKind.carbCycle,
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
                loadStrategyForDay: (_) async => DietStrategyKind.carbCycle,
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
                loadStrategyForDay: (_) async => DietStrategyKind.carbCycle,
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

  for (final kind in <DietStrategyKind?>[
    null,
    DietStrategyKind.balanced,
    DietStrategyKind.carbTaper,
  ]) {
    testWidgets(
      'rest-day cycle option is disabled for ${kind?.name ?? 'no plan'}',
      (tester) async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final strategyRepo = DietStrategyRepository(db);
        final markerRepo = DayMarkerRepository(db);
        final today = CalendarDay.todayLocal();
        if (kind != null) {
          await strategyRepo.createPlan(
            DietStrategyPlanDraft(
              kind: kind,
              effectiveFrom: today,
              referenceWeightKg: 75,
              estimatedTdee: 2400,
              baseEnergy: 2000,
            ),
          );
        }
        await _openMarkerSheet(tester, db, markerRepo, strategyRepo, today);
        await tester.tap(find.byKey(const ValueKey('marker-option-restDay')));
        await tester.pumpAndSettle();
        expect(
          tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
          isNull,
        );
        expect(find.text('No carb cycle applies on this day.'), findsOneWidget);
        await tester.tap(find.byType(FilledButton).last);
        await tester.pumpAndSettle();
        expect(
          (await markerRepo.settingsForDay(today))!.pauseCarbCycle,
          isFalse,
        );
        await tester.longPress(_dayFinder(today));
        await tester.pumpAndSettle();
        expect(find.text('Cycle unchanged'), findsNothing);
      },
    );
  }

  testWidgets('scheduled cycle is available only from its effective day', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final strategyRepo = DietStrategyRepository(db);
    final markerRepo = DayMarkerRepository(db);
    final today = CalendarDay.todayLocal();
    final tomorrow = today.add(const Duration(days: 1));
    await strategyRepo.createPlan(_cycleDraft(tomorrow));

    await _openMarkerSheet(tester, db, markerRepo, strategyRepo, today);
    await tester.tap(find.byKey(const ValueKey('marker-option-restDay')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
      isNull,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await _openMarkerSheet(tester, db, markerRepo, strategyRepo, tomorrow);
    await tester.tap(find.byKey(const ValueKey('marker-option-restDay')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
      isNotNull,
    );
    await tester.tap(find.text('Delay carb cycle by one day'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();
    expect((await markerRepo.settingsForDay(tomorrow))!.pauseCarbCycle, isTrue);
  });

  testWidgets(
    'stopped cycle keeps a historical saved delay editable and unchanged',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final strategyRepo = DietStrategyRepository(db);
      final markerRepo = DayMarkerRepository(db);
      final today = CalendarDay.todayLocal();
      final yesterday = today.subtract(const Duration(days: 1));
      await strategyRepo.createPlan(_cycleDraft(yesterday), now: yesterday);
      await markerRepo.setRestDay(
        yesterday,
        pauseCarbCycle: true,
        now: yesterday,
      );
      await strategyRepo.stopActivePlan(now: today);
      expect(
        (await strategyRepo.planCovering(yesterday))?.kind,
        DietStrategyKind.carbCycle,
      );
      expect(await strategyRepo.planCovering(today), isNull);

      await _openMarkerSheet(tester, db, markerRepo, strategyRepo, today);
      await tester.tap(find.byKey(const ValueKey('marker-option-restDay')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
        isNull,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await _openMarkerSheet(tester, db, markerRepo, strategyRepo, yesterday);
      expect(find.text('Cycle delayed one day'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('marker-option-restDay')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
        isNotNull,
      );
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();
      expect(
        (await markerRepo.settingsForDay(yesterday))!.pauseCarbCycle,
        isTrue,
      );
    },
  );

  testWidgets('saved delay is preserved when no cycle governs that day', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final strategyRepo = DietStrategyRepository(db);
    final markerRepo = DayMarkerRepository(db);
    final today = CalendarDay.todayLocal();
    await markerRepo.setRestDay(today, pauseCarbCycle: true);
    await _openMarkerSheet(tester, db, markerRepo, strategyRepo, today);
    expect(find.text('Cycle delayed one day'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('marker-option-restDay')));
    await tester.pumpAndSettle();
    final toggle = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(toggle.value, isTrue);
    expect(toggle.onChanged, isNull);
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();
    expect((await markerRepo.settingsForDay(today))!.pauseCarbCycle, isTrue);
  });
}

DietStrategyPlanDraft _cycleDraft(DateTime from) {
  final schedule = CarbCycleSchedule.tryParse('HMLL')!;
  final rates = CarbCycleRates.defaults();
  return DietStrategyPlanDraft(
    kind: DietStrategyKind.carbCycle,
    effectiveFrom: from,
    referenceWeightKg: 75,
    estimatedTdee: 2400,
    baseEnergy: CarbCyclePlanner.compute(
      referenceWeightKg: 75,
      rates: rates,
      schedule: schedule,
    ).cycleAverageEnergy,
    schedule: schedule,
    carbCycleRates: rates,
  );
}

Finder _dayFinder(DateTime day) =>
    find.byKey(ValueKey('deficitDay-${day.year}-${day.month}-${day.day}'));

Future<void> _openMarkerSheet(
  WidgetTester tester,
  AppDatabase db,
  DayMarkerRepository markerRepo,
  DietStrategyRepository strategyRepo,
  DateTime day,
) async {
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
              initialDate: day,
              firstDate: day,
              lastDate: day,
              plannedDeficit: 0,
              mealRepository: MealRepository(db),
              markerRepository: markerRepo,
              loadTargets: (_, _) async => {},
              loadStrategyForDay: (date) async =>
                  (await strategyRepo.planCovering(date))?.kind,
            ),
            child: const Text('Open calendar'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open calendar'));
  await tester.pumpAndSettle();
  await tester.longPress(_dayFinder(day));
  await tester.pumpAndSettle();
}
