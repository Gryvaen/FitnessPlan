import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/day_marker_repository.dart';
import 'package:diet/data/repositories/meal_repository.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/domain/cut_cultivation.dart';
import 'package:diet/domain/diet_plan.dart';
import 'package:diet/domain/goal_period.dart';
import 'package:diet/domain/models.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/ui/today/deficit_date_picker.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _okGreen = Color(0xFF2A9D8F);
const _badRed = Color(0xFFE76F51);

class _FixedMeals extends MealRepository {
  _FixedMeals(super.db, this.totals);

  final Map<DateTime, double> totals;

  @override
  Future<Map<DateTime, double>> calorieTotalsBetween(
    DateTime start,
    DateTime end,
  ) async => totals;
}

DailyNutritionTarget _target(
  DateTime day, {
  bool legacy = false,
  String? reason,
}) => DailyNutritionTarget(
  date: day,
  calories: 2000,
  proteinG: 150,
  carbG: 200,
  fatG: 60,
  source: TargetSource.profile,
  estimatedTdee: 2500,
  isSnapshot: !legacy,
  isLegacyEstimate: legacy,
  reason: reason,
);

void main() {
  final today = CalendarDay.todayLocal();
  // The logged day under test; also the initial selection so its month is
  // the one shown.
  final day = CalendarDay.addDays(today, -3);
  final standardSince = CalendarDay.addDays(today, -1);

  Future<Color?> pumpAndReadCellColor(
    WidgetTester tester, {
    required List<CutCultivationSegment> segments,
    bool legacy = false,
    double intake = 1500,
    String? reason,
    List<GoalPeriod> goalPeriods = const [],
  }) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
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
                firstDate: CalendarDay.addDays(today, -30),
                lastDate: today,
                plannedDeficit: 0,
                mealRepository: _FixedMeals(db, {day: intake}),
                markerRepository: DayMarkerRepository(db),
                loadTargets: (_, _) async => {
                  day: _target(day, legacy: legacy, reason: reason),
                },
                loadStrategyForDay: (_) async => null,
                calorieStandardSince: standardSince,
                cutSegments: segments,
                goalPeriods: goalPeriods,
              ),
              child: const Text('Open calendar'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open calendar'));
    await tester.pumpAndSettle();
    final cell = find.byKey(
      ValueKey('deficitDay-${day.year}-${day.month}-${day.day}'),
    );
    expect(cell, findsOneWidget);
    final material = tester.widget<Material>(
      find.descendant(of: cell, matching: find.byType(Material)).first,
    );
    return material.color;
  }

  bool isGreen(Color? c) => c != null && c.withValues(alpha: 1) == _okGreen;
  bool isRed(Color? c) => c != null && c.withValues(alpha: 1) == _badRed;

  group('maintain days use the ±10% band', () {
    final round = [
      CutCultivationSegment(start: CalendarDay.addDays(today, -10)),
    ];

    testWidgets('eating far too little is a miss', (tester) async {
      final color = await pumpAndReadCellColor(
        tester,
        segments: round,
        intake: 1500,
        reason: 'maintain',
      );
      expect(isRed(color), isTrue);
      expect(find.text('Maintenance days'), findsOneWidget);
    });

    for (final intake in [1900.0, 2150.0]) {
      testWidgets('inside the band is met ($intake kcal)', (tester) async {
        final color = await pumpAndReadCellColor(
          tester,
          segments: round,
          intake: intake,
          reason: 'maintain',
        );
        expect(isGreen(color), isTrue);
      });
    }

    testWidgets('above the band is a miss', (tester) async {
      final color = await pumpAndReadCellColor(
        tester,
        segments: round,
        intake: 2300,
        reason: 'maintain',
      );
      expect(isRed(color), isTrue);
    });
  });

  group('bulk days run from the target up to +10%', () {
    for (final (intake, met) in [
      (1800.0, false), // short of the surplus
      (2100.0, true),
      (2400.0, false), // past the band
    ]) {
      testWidgets('$intake kcal is ${met ? 'met' : 'a miss'}', (tester) async {
        // A round keeps the day past the new-standard cut-off, as above.
        final color = await pumpAndReadCellColor(
          tester,
          segments: [
            CutCultivationSegment(start: CalendarDay.addDays(today, -10)),
          ],
          intake: intake,
          reason: 'bulk',
        );
        expect(met ? isGreen(color) : isRed(color), isTrue);
        expect(find.text('Bulk days'), findsOneWidget);
      });
    }
  });

  group('goal periods are bracketed', () {
    String bracketKey(DateTime d, {FitnessGoal? start, FitnessGoal? end}) =>
        'goalBracket-${d.year}-${d.month}-${d.day}'
        '-${start?.name ?? ''}-${end?.name ?? ''}';

    testWidgets('a new goal opens with 「[」 in its colour', (tester) async {
      await pumpAndReadCellColor(
        tester,
        segments: [
          CutCultivationSegment(
            start: CalendarDay.addDays(day, -6),
            end: CalendarDay.addDays(day, -1),
          ),
        ],
        goalPeriods: [
          GoalPeriod(
            goal: FitnessGoal.cut,
            start: CalendarDay.addDays(day, -6),
            end: CalendarDay.addDays(day, -1),
          ),
          GoalPeriod(goal: FitnessGoal.maintain, start: day),
        ],
      );
      expect(
        find.byKey(ValueKey(bracketKey(day, start: FitnessGoal.maintain))),
        findsOneWidget,
      );
      // One merged 目标时段 legend replaces the cut-round one.
      expect(find.byKey(const ValueKey('goalPeriodLegend')), findsOneWidget);
      expect(find.text('Goal periods'), findsOneWidget);
      expect(find.text('Cut round'), findsNothing);
      expect(
        find.byKey(const ValueKey('goalPeriodLegend-maintain')),
        findsOneWidget,
      );
    });

    testWidgets('a finished goal closes with 「]」', (tester) async {
      await pumpAndReadCellColor(
        tester,
        segments: const [],
        goalPeriods: [
          GoalPeriod(
            goal: FitnessGoal.cut,
            start: CalendarDay.addDays(day, -6),
            end: day,
          ),
          GoalPeriod(
            goal: FitnessGoal.bulk,
            start: CalendarDay.addDays(day, 1),
          ),
        ],
      );
      expect(
        find.byKey(ValueKey(bracketKey(day, end: FitnessGoal.cut))),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('goalPeriodLegend-cut')),
        findsOneWidget,
      );
    });

    testWidgets('without recorded periods the old start line stays', (
      tester,
    ) async {
      await pumpAndReadCellColor(
        tester,
        segments: [CutCultivationSegment(start: day)],
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && '${w.key}'.contains('goalBracket-'),
        ),
        findsNothing,
      );
      expect(find.text('Cut round'), findsOneWidget);
    });
  });

  testWidgets('a day inside the cut round keeps its verdict after a '
      'later standard change', (tester) async {
    final color = await pumpAndReadCellColor(
      tester,
      segments: [CutCultivationSegment(start: CalendarDay.addDays(today, -10))],
    );
    expect(isGreen(color), isTrue);
    expect(find.text('Cut round'), findsOneWidget);
    expect(find.text('Standard change'), findsNothing);
  });

  testWidgets('outside any cut round the standard cut-off still applies', (
    tester,
  ) async {
    final color = await pumpAndReadCellColor(tester, segments: const []);
    expect(isGreen(color), isFalse);
    expect(find.text('Standard change'), findsOneWidget);
  });

  testWidgets('a closed earlier round does not cover days after it ended', (
    tester,
  ) async {
    final color = await pumpAndReadCellColor(
      tester,
      segments: [
        CutCultivationSegment(
          start: CalendarDay.addDays(today, -20),
          end: CalendarDay.addDays(today, -15),
        ),
      ],
    );
    expect(isGreen(color), isFalse);
  });

  testWidgets('legacy estimates stay neutral even inside the round', (
    tester,
  ) async {
    final color = await pumpAndReadCellColor(
      tester,
      segments: [CutCultivationSegment(start: CalendarDay.addDays(today, -10))],
      legacy: true,
    );
    expect(isGreen(color), isFalse);
  });
}
