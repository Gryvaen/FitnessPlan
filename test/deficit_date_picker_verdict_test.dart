import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/day_marker_repository.dart';
import 'package:diet/data/repositories/meal_repository.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/domain/cut_cultivation.dart';
import 'package:diet/domain/diet_plan.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/ui/today/deficit_date_picker.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _okGreen = Color(0xFF2A9D8F);

class _FixedMeals extends MealRepository {
  _FixedMeals(super.db, this.totals);

  final Map<DateTime, double> totals;

  @override
  Future<Map<DateTime, double>> calorieTotalsBetween(
    DateTime start,
    DateTime end,
  ) async => totals;
}

DailyNutritionTarget _target(DateTime day, {bool legacy = false}) =>
    DailyNutritionTarget(
      date: day,
      calories: 2000,
      proteinG: 150,
      carbG: 200,
      fatG: 60,
      source: TargetSource.profile,
      estimatedTdee: 2500,
      isSnapshot: !legacy,
      isLegacyEstimate: legacy,
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
                mealRepository: _FixedMeals(db, {day: 1500}),
                markerRepository: DayMarkerRepository(db),
                loadTargets: (_, _) async => {
                  day: _target(day, legacy: legacy),
                },
                loadStrategyForDay: (_) async => null,
                calorieStandardSince: standardSince,
                cutSegments: segments,
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
