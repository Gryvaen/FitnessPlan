import 'package:diet/domain/diet_strategy.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/ui/strategy/carb_cycle_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('preview labels every rest day but shifts only selected ones', (
    tester,
  ) async {
    final start = DateTime(2026, 10, 13);
    final rest = DateTime(2026, 10, 14);
    final plan = CarbCyclePlanner.compute(
      referenceWeightKg: 75,
      rates: CarbCycleRates.defaults(),
      schedule: CarbCycleSchedule.tryParse('HMLL')!,
    );

    Future<void> show(List<DateTime> paused) => tester.pumpWidget(
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
            windowStart: start,
            restDayDates: paused,
            allRestDayDates: [rest],
          ),
        ),
      ),
    );

    await show([]);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('cycleDay-1')),
        matching: find.text('Rest day'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('cycleDay-2')),
        matching: find.text('${plan.integerDays()[2].energy.round()}'),
      ),
      findsOneWidget,
    );

    await show([rest]);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('cycleDay-2')),
        matching: find.text('${plan.integerDays()[1].energy.round()}'),
      ),
      findsOneWidget,
    );
  });
}
