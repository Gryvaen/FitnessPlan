import 'dart:convert';

import 'package:diet/data/db.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/domain/models.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/providers/app_providers.dart';
import 'package:diet/ui/records/body_records_tab.dart';
import 'package:diet/ui/theme/app_theme.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

UserProfile _profile(FitnessGoal goal) => UserProfile(
  sex: Sex.male,
  age: 30,
  heightCm: 175,
  weightKg: 76,
  activity: ActivityLevel.moderate,
  goal: goal,
  targets: const MacroTargets(
    calories: 2400,
    proteinG: 150,
    carbG: 300,
    fatG: 67,
  ),
  bmr: 1700,
  tdee: 2400,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final today = CalendarDay.todayLocal();

  /// Pumps 记录 → 身体 after a 1 kg gain and returns the change line's colour.
  Future<Color?> gainColor(WidgetTester tester, FitnessGoal goal) async {
    SharedPreferences.setMockInitialValues({
      'user_profile': jsonEncode(_profile(goal).toJson()),
    });
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    await tester.runAsync(() async {
      for (final (back, kg) in [(1, 75.0), (0, 76.0)]) {
        await db
            .into(db.weightLogs)
            .insert(
              WeightLogsCompanion.insert(
                date: CalendarDay.addDays(today, -back),
                weightKg: kg,
              ),
            );
      }
    });
    final router = GoRouter(
      initialLocation: '/records',
      routes: [
        GoRoute(
          path: '/records',
          builder: (_, _) => const Scaffold(body: BodyRecordsTab()),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final line = find.textContaining('+1.00 kg');
    expect(line, findsOneWidget);
    return tester.widget<Text>(line).style?.color;
  }

  testWidgets('a gain is a warning while cutting', (tester) async {
    expect(await gainColor(tester, FitnessGoal.cut), AppColors.warning);
  });

  testWidgets('a gain is good while bulking', (tester) async {
    expect(await gainColor(tester, FitnessGoal.bulk), AppColors.success);
  });

  testWidgets('maintenance stays neutral', (tester) async {
    final color = await gainColor(tester, FitnessGoal.maintain);
    expect(color, isNot(AppColors.warning));
    expect(color, isNot(AppColors.success));
  });
}
