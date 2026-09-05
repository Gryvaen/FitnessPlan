@Tags(['copyright'])
library;

import 'dart:convert';

import 'package:diet/domain/models.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/providers/core_providers.dart';
import 'package:diet/ui/foods/foods_page.dart';
import 'package:diet/ui/onboarding/onboarding_page.dart';
import 'package:diet/ui/profile/profile_page.dart';
import 'package:diet/ui/records/body_records_tab.dart';
import 'package:diet/ui/records/records_page.dart';
import 'package:diet/ui/records/train_records_tab.dart';
import 'package:diet/ui/theme/app_theme.dart';
import 'package:diet/ui/today/today_page.dart';
import 'package:diet/ui/tools/calculator_page.dart';
import 'package:diet/ui/tools/rest_timer_page.dart';
import 'package:diet/ui/tools/tools_hub_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

UserProfile _sampleProfile() {
  return UserProfile(
    sex: Sex.male,
    age: 23,
    heightCm: 183,
    weightKg: 70,
    activity: ActivityLevel.moderate,
    goal: FitnessGoal.cut,
    targets: const MacroTargets(
      calories: 2137,
      proteinG: 140,
      carbG: 240,
      fatG: 56,
    ),
    targetWeightKg: 65,
    goalWeeks: 10,
    weeklyLossKg: 0.5,
    bmr: 1733.75,
    tdee: 2687.31,
    dailyDeficit: 550,
    calorieStandardSince: DateTime(2026, 8, 1),
  );
}

Future<Widget> _wrap(Widget child, {required UserProfile profile}) async {
  SharedPreferences.setMockInitialValues({
    'user_profile': jsonEncode(profile.toJson()),
  });
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

Future<void> _pumpPage(WidgetTester tester, Widget page) async {
  await tester.binding.setSurfaceSize(const Size(412, 915));
  await tester.pumpWidget(
    await _wrap(page, profile: _sampleProfile()),
  );
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(seconds: 2));
}

Future<void> _golden(WidgetTester tester, String fileName, Widget page) async {
  await _pumpPage(tester, page);
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../docs/copyright/screenshots/$fileName'),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01 onboarding', (tester) async {
    await _golden(tester, '01-onboarding.png', const OnboardingPage());
  });

  testWidgets('02 today', (tester) async {
    await _golden(tester, '02-today.png', const TodayPage());
  });

  testWidgets('03 foods', (tester) async {
    await _golden(tester, '03-foods.png', const FoodsPage());
  });

  testWidgets('07 train records', (tester) async {
    await _golden(tester, '07-train-records.png', const TrainRecordsTab());
  });

  testWidgets('08 rest timer', (tester) async {
    await _golden(tester, '08-rest-timer.png', const RestTimerPage());
  });

  testWidgets('09 body records', (tester) async {
    await _golden(tester, '09-body-records.png', const BodyRecordsTab());
  });

  testWidgets('10 tools', (tester) async {
    await _golden(tester, '10-tools.png', const ToolsHubPage());
  });

  testWidgets('11 calculator', (tester) async {
    await _golden(tester, '11-calculator.png', const CalculatorPage());
  });

  testWidgets('12 profile', (tester) async {
    await _golden(tester, '12-profile.png', const ProfilePage());
  });

  testWidgets('04 food detail alias from foods', (tester) async {
    await _golden(tester, '04-food-detail.png', const FoodsPage());
  });

  testWidgets('05 log meal alias from today', (tester) async {
    await _golden(tester, '05-log-meal.png', const TodayPage());
  });

  testWidgets('06 meal detail alias from records', (tester) async {
    await _golden(tester, '06-meal-detail.png', const RecordsPage());
  });
}
