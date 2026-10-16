import 'package:diet/domain/diet_strategy.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/ui/strategy/carb_cycle_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('preview keeps carb types and shifts only selected rest days', (
    tester,
  ) async {
    final start = DateTime(2026, 10, 13);
    final rest = DateTime(2026, 10, 14);
    final plan = CarbCyclePlanner.compute(
      referenceWeightKg: 75,
      rates: CarbCycleRates.defaults(),
      schedule: CarbCycleSchedule.tryParse('HMLL')!,
    );

    CarbCycleSchedule? edited;
    Future<void> show(List<DateTime> paused, {int offset = 0}) =>
        tester.pumpWidget(
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
              body: CarbCycleView(
                plan: plan,
                cycleStart: start,
                cycleStartIndex: offset,
                onScheduleChanged: (s) => edited = s,
                windowStart: start,
                restDayDates: paused,
              ),
            ),
          ),
        );

    await show([]);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('cycleDay-1')),
        matching: find.text('Mid-carb day'),
      ),
      findsOneWidget,
    );
    expect(find.text('Rest day'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('cycleDay-2')),
        matching: find.text('Low-carb day'),
      ),
      findsOneWidget,
    );

    // A paused rest day stands on its own; the next day takes its slot.
    await show([rest]);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('cycleDay-1')),
        matching: find.text('Rest day'),
      ),
      findsOneWidget,
    );
    expect(find.text('Mid-carb day'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('cycleDay-2')),
        matching: find.text('Mid-carb day'),
      ),
      findsOneWidget,
    );
    await show([], offset: 2);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('cycleDay-0')),
        matching: find.text('Low-carb day'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('cycleDay-2')),
        matching: find.text('High-carb day'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('cycleDay-0')));
    expect(edited!.code, plan.schedule.cycleDayType(2).code);
    await show([start], offset: 2);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('cycleDay-0')),
        matching: find.text('Rest day'),
      ),
      findsOneWidget,
    );
    edited = null;
    await tester.tap(find.byKey(const ValueKey('cycleDay-0')));
    expect(edited, isNull); // A paused day edits no schedule slot.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('cycleDay-1')),
        matching: find.text('Low-carb day'),
      ),
      findsOneWidget,
    );
  });
}
