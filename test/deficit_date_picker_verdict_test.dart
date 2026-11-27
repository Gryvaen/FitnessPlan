import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/day_marker_repository.dart';
import 'package:diet/data/repositories/meal_repository.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/domain/cut_cultivation.dart';
import 'package:diet/domain/diet_plan.dart';
import 'package:diet/domain/goal_period.dart';
import 'package:diet/domain/models.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/ui/theme/app_theme.dart';
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
    Brightness brightness = Brightness.light,
    double textScale = 1,
    Set<DateTime> strategyChangeDays = const {},
    DateTime? cheatDay,
  }) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final markerRepository = DayMarkerRepository(db);
    if (cheatDay != null) {
      await tester.runAsync(() => markerRepository.setCheatMeal(cheatDay));
    }
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: AppTheme.ofId(
          brightness == Brightness.dark
              ? AppThemeId.graphite
              : AppThemeId.fresh,
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
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
                markerRepository: markerRepository,
                loadTargets: (_, _) async => {
                  day: _target(day, legacy: legacy, reason: reason),
                },
                loadStrategyForDay: (_) async => null,
                calorieStandardSince: standardSince,
                cutSegments: segments,
                goalPeriods: goalPeriods,
                strategyChangeDays: strategyChangeDays,
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

  group('goal periods have boundary brackets', () {
    Finder dayCell(DateTime date) => find.byKey(
      ValueKey('deficitDay-${date.year}-${date.month}-${date.day}'),
    );

    Finder bracket(DateTime date, String key) =>
        find.descendant(of: dayCell(date), matching: find.byKey(ValueKey(key)));

    Finder startBracket(DateTime date) => bracket(date, 'goalPeriodStart');
    Finder endBracket(DateTime date) => bracket(date, 'goalPeriodEnd');

    testWidgets('an open period has a start bracket only', (tester) async {
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
      expect(startBracket(day), findsOneWidget);
      expect(endBracket(day), findsNothing);
      expect(
        find.descendant(
          of: startBracket(day),
          matching: find.byType(CustomPaint),
        ),
        paints..path(color: const Color(0xFF2C6D63), strokeWidth: 1.5),
      );
      // One merged 目标时段 legend replaces the cut-round one.
      expect(find.byKey(const ValueKey('goalPeriodLegend')), findsOneWidget);
      expect(find.text('Goal periods'), findsOneWidget);
      expect(find.text('Cut round'), findsNothing);
      for (final goal in FitnessGoal.values) {
        final legend = find.byKey(ValueKey('goalPeriodLegend-${goal.name}'));
        expect(
          find.descendant(of: legend, matching: find.byType(CustomPaint)),
          findsNWidgets(2),
        );
      }
    });

    testWidgets('a cross-month goal ends only on the recorded end date', (
      tester,
    ) async {
      await pumpAndReadCellColor(
        tester,
        segments: const [],
        goalPeriods: [
          GoalPeriod(
            goal: FitnessGoal.cut,
            start: DateTime(day.year, day.month - 1, 1),
            end: day,
          ),
          GoalPeriod(
            goal: FitnessGoal.bulk,
            start: CalendarDay.addDays(day, 1),
          ),
        ],
      );
      expect(endBracket(day), findsOneWidget);
      expect(startBracket(day), findsNothing);
      expect(startBracket(DateTime(day.year, day.month, 1)), findsNothing);
      expect(
        find.byKey(const ValueKey('goalPeriodLegend-cut')),
        findsOneWidget,
      );
    });

    for (final brightness in Brightness.values) {
      testWidgets('compact brackets frame only the date in $brightness', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 800);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final switchesGoal = brightness == Brightness.dark;
        final adjacent = CalendarDay.addDays(day, day.day == 1 ? 1 : -1);
        final empty = DateTime(day.year, day.month, day.day <= 2 ? 4 : 1);
        final color = await pumpAndReadCellColor(
          tester,
          segments: const [],
          brightness: brightness,
          textScale: 2,
          intake: 12600,
          cheatDay: adjacent,
          strategyChangeDays: {day},
          goalPeriods: [
            if (switchesGoal) ...[
              GoalPeriod(
                goal: FitnessGoal.cut,
                start: DateTime(day.year, day.month - 1, 1),
                end: day,
              ),
              GoalPeriod(goal: FitnessGoal.bulk, start: day),
            ] else
              GoalPeriod(goal: FitnessGoal.cut, start: day, end: day),
            GoalPeriod(goal: FitnessGoal.maintain, start: adjacent),
          ],
        );

        final start = tester.getRect(startBracket(day));
        final end = tester.getRect(endBracket(day));
        final calories = find.descendant(
          of: dayCell(day),
          matching: find.text('-10600'),
        );
        final flag = tester.getRect(
          find.descendant(
            of: dayCell(day),
            matching: find.byKey(const ValueKey('strategyChangeFlag')),
          ),
        );
        final number = tester.getRect(
          find.descendant(of: dayCell(day), matching: find.text('${day.day}')),
        );
        final caption = tester.getRect(calories);
        expect(start.right, lessThanOrEqualTo(number.left));
        expect(end.left, greaterThanOrEqualTo(number.right));
        expect(start.overlaps(flag), isFalse);
        expect(start.center.dy, closeTo(number.center.dy, 0.01));
        expect(start.bottom, lessThanOrEqualTo(caption.top));
        expect(isRed(color), isTrue);
        final single = startBracket(adjacent);
        expect(single, findsOneWidget);
        expect(endBracket(adjacent), findsNothing);
        expect(startBracket(empty), findsNothing);
        expect(endBracket(empty), findsNothing);

        final dateOffset =
            number.center.dy - tester.getTopLeft(dayCell(day)).dy;
        for (final date in [day, adjacent, empty]) {
          final cell = tester.getRect(dayCell(date));
          final dateNumber = tester.getRect(
            find.descendant(
              of: dayCell(date),
              matching: find.text('${date.day}'),
            ),
          );
          expect(dateNumber.center.dx, closeTo(cell.center.dx, .01));
          expect(dateNumber.center.dy - cell.top, closeTo(dateOffset, .01));
          expect(cell.height, greaterThanOrEqualTo(44));
        }

        final marker = tester.getRect(
          find.descendant(of: dayCell(adjacent), matching: find.text('Cheat')),
        );
        expect(marker.top, greaterThan(tester.getBottomLeft(single).dy));
        expect(marker.width, greaterThan(16));
        final startColor = switchesGoal
            ? const Color(0xFFE0A087)
            : const Color(0xFF3C5D89);
        final endColor = switchesGoal
            ? const Color(0xFFA9BDE2)
            : const Color(0xFF3C5D89);
        expect(
          find.descendant(
            of: startBracket(day),
            matching: find.byType(CustomPaint),
          ),
          paints..path(
            color: startColor,
            strokeWidth: 1.5,
            style: PaintingStyle.stroke,
          ),
        );
        expect(
          find.descendant(
            of: endBracket(day),
            matching: find.byType(CustomPaint),
          ),
          paints..path(
            color: endColor,
            strokeWidth: 1.5,
            style: PaintingStyle.stroke,
          ),
        );
        expect(
          find.bySemanticsLabel(RegExp('Cut, Period ends')),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(
            RegExp(switchesGoal ? 'Bulk, Period starts' : 'Cut, Period starts'),
          ),
          findsOneWidget,
        );

        await tester.ensureVisible(dayCell(adjacent));
        await tester.tap(dayCell(adjacent));
        await tester.pumpAndSettle();
        final material = find
            .descendant(of: dayCell(day), matching: find.byType(Material))
            .first;
        expect(tester.widget<Material>(material).color, isNot(color));

        await tester.ensureVisible(startBracket(day));
        await tester.tapAt(tester.getCenter(startBracket(day)));
        await tester.pumpAndSettle();
        expect(tester.widget<Material>(material).color, color);
      });
    }

    testWidgets('without recorded periods the old start line stays', (
      tester,
    ) async {
      await pumpAndReadCellColor(
        tester,
        segments: [CutCultivationSegment(start: day)],
      );
      expect(startBracket(day), findsNothing);
      expect(endBracket(day), findsNothing);
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

  group('a finished maintain stretch before a later switch back to cut', () {
    // Maintain [day−1, day+1], then cut again from [standardSince], which the
    // switch stamps as the new calorie standard.
    final periods = [
      GoalPeriod(
        goal: FitnessGoal.maintain,
        start: CalendarDay.addDays(day, -1),
        end: CalendarDay.addDays(day, 1),
      ),
      GoalPeriod(goal: FitnessGoal.cut, start: standardSince),
    ];
    final laterRound = [CutCultivationSegment(start: standardSince)];

    testWidgets('keeps its band verdict inside the recorded stretch', (
      tester,
    ) async {
      final color = await pumpAndReadCellColor(
        tester,
        segments: laterRound,
        intake: 2000,
        reason: 'maintain',
        goalPeriods: periods,
      );
      expect(isGreen(color), isTrue);
    });

    testWidgets('a recorded stretch alone lifts the cut-off', (tester) async {
      final color = await pumpAndReadCellColor(
        tester,
        segments: laterRound,
        goalPeriods: periods,
      );
      expect(isGreen(color), isTrue);
    });

    testWidgets('the maintain tag alone lifts the cut-off', (tester) async {
      final color = await pumpAndReadCellColor(
        tester,
        segments: laterRound,
        intake: 2500,
        reason: 'maintain',
      );
      expect(isRed(color), isTrue);
    });
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
