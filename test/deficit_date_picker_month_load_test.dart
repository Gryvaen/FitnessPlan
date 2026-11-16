import 'dart:async';

import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/day_marker_repository.dart';
import 'package:diet/data/repositories/meal_repository.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/domain/diet_plan.dart';
import 'package:diet/domain/diet_strategy.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/ui/ink/ink_icon.dart';
import 'package:diet/ui/today/deficit_date_picker.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a slower earlier month cannot overwrite the month on screen', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final today = CalendarDay.todayLocal();
    final thisMonth = DateTime(today.year, today.month);
    // Month loads finish only when the test says so, keyed by month start.
    final pending =
        <DateTime, Completer<Map<DateTime, DailyNutritionTarget>>>{};
    Future<Map<DateTime, DailyNutritionTarget>> loadTargets(
      DateTime start,
      DateTime _,
    ) {
      final month = DateTime(start.year, start.month);
      if (month == thisMonth) return Future.value({});
      return (pending[month] = Completer()).future;
    }

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
                firstDate: DateTime(today.year, today.month - 2, 1),
                lastDate: today,
                plannedDeficit: 0,
                mealRepository: MealRepository(db),
                markerRepository: DayMarkerRepository(db),
                loadTargets: loadTargets,
                loadStrategyForDay: (_) async => DietStrategyKind.balanced,
              ),
              child: const Text('Open calendar'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open calendar'));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);

    Future<void> goBack() async {
      await tester.tap(
        find.byWidgetPredicate(
          (w) =>
              w is IconButton &&
              w.icon is InkIcon &&
              (w.icon as InkIcon).glyph == InkGlyph.chevronLeft,
        ),
      );
      await tester.pump();
    }

    await goBack();
    await goBack();
    final oneBack = DateTime(today.year, today.month - 1);
    final twoBack = DateTime(today.year, today.month - 2);
    expect(pending.keys, containsAll([oneBack, twoBack]));

    // The month the user paged past answers first; the shown month is still
    // loading.
    pending[oneBack]!.complete({});
    await tester.pump();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pending[twoBack]!.complete({});
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
