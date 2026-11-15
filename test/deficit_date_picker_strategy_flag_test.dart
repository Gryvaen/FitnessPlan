import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/day_marker_repository.dart';
import 'package:diet/data/repositories/meal_repository.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/domain/cut_cultivation.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/ui/today/deficit_date_picker.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _flag = ValueKey('strategyChangeFlag');

Finder _cell(DateTime d) =>
    find.byKey(ValueKey('deficitDay-${d.year}-${d.month}-${d.day}'));

Finder _flagIn(DateTime d) =>
    find.descendant(of: _cell(d), matching: find.byKey(_flag));

void main() {
  final today = CalendarDay.todayLocal();
  final day = CalendarDay.addDays(today, -3);
  // Another day in the same visible month.
  final other = CalendarDay.addDays(day, day.day == 1 ? 1 : -1);

  Future<void> pumpPicker(
    WidgetTester tester, {
    Set<DateTime> changes = const {},
    List<CutCultivationSegment> segments = const [],
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
                mealRepository: MealRepository(db),
                markerRepository: DayMarkerRepository(db),
                loadTargets: (_, _) async => {},
                loadStrategyForDay: (_) async => null,
                cutSegments: segments,
                strategyChangeDays: changes,
              ),
              child: const Text('Open calendar'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open calendar'));
    await tester.pumpAndSettle();
  }

  bool hasLeftBar(WidgetTester tester, DateTime d) => tester
      .widgetList<DecoratedBox>(
        find.descendant(of: _cell(d), matching: find.byType(DecoratedBox)),
      )
      .any((b) {
        final deco = b.decoration;
        return deco is BoxDecoration &&
            deco.border is Border &&
            (deco.border! as Border).left.width == 2;
      });

  testWidgets('only the change day carries the corner flag', (tester) async {
    await pumpPicker(tester, changes: {day});
    expect(_flagIn(day), findsOneWidget);
    expect(_flagIn(other), findsNothing);
    expect(find.text('Strategy change'), findsOneWidget);
    expect(
      find.text('Corner flag = new strategy version starts'),
      findsOneWidget,
    );
  });

  testWidgets('no changes: no flag and no legend', (tester) async {
    await pumpPicker(tester);
    expect(find.byKey(_flag), findsNothing);
    expect(find.text('Strategy change'), findsNothing);
  });

  testWidgets('flag and cut-round start line coexist on one day', (
    tester,
  ) async {
    await pumpPicker(
      tester,
      changes: {day},
      segments: [CutCultivationSegment(start: day)],
    );
    expect(_flagIn(day), findsOneWidget);
    expect(hasLeftBar(tester, day), isTrue);
    expect(hasLeftBar(tester, other), isFalse);
  });

  testWidgets('time-of-day on passed dates is normalized', (tester) async {
    await pumpPicker(
      tester,
      changes: {DateTime(day.year, day.month, day.day, 15, 20)},
    );
    expect(_flagIn(day), findsOneWidget);
  });
}
