import 'package:diet/domain/maintain_balance.dart';
import 'package:diet/domain/models.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/providers/app_providers.dart';
import 'package:diet/ui/profile/balance_scale.dart';
import 'package:diet/ui/profile/cultivation_page.dart';
import 'package:diet/ui/profile/profile_page.dart';
import 'package:diet/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MaintainProfile extends ProfileNotifier {
  @override
  UserProfile? build() => const UserProfile(
    sex: Sex.male,
    age: 30,
    heightCm: 175,
    weightKg: 75,
    activity: ActivityLevel.moderate,
    goal: FitnessGoal.maintain,
    tdee: 2400,
    targets: MacroTargets(calories: 2400, proteinG: 120, carbG: 280, fatG: 80),
  );
}

const _balance = MaintainBalance(
  leftKcal: 1200,
  rightKcal: 2000,
  balancedDays: 9,
  weighedDays: 14,
);

late SharedPreferences _prefs;

Widget _app(Widget home) => ProviderScope(
  overrides: [
    sharedPreferencesProvider.overrideWithValue(_prefs),
    profileProvider.overrideWith(_MaintainProfile.new),
    maintainHistoryProvider.overrideWith((ref) async => const []),
    maintainBalanceProvider.overrideWithValue(_balance),
    mindProgressProvider.overrideWithValue(computeMindProgress(9)),
    maintainTodayEntryProvider.overrideWithValue(null),
  ],
  child: MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('zh'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  testWidgets('maintain goal shows the balance scale and mind state', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(const CultivationPage()));
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.byKey(const ValueKey('maintain-balance-scale')),
      findsOneWidget,
    );
    final scale = tester.widget<BalanceScale>(find.byType(BalanceScale));
    expect(scale.tiltRadians, greaterThan(0)); // surplus side heavier
    expect(scale.leftValue, '−1,200');
    expect(scale.rightValue, '+2,000');
    expect(find.text('净 +800 kcal · ≈+0.1 kg'), findsOneWidget);
    expect(find.text('心定 · 2层'), findsOneWidget);
    expect(find.textContaining('今日尚未上秤'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile hero card shows mind state with a scale thumbnail', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _app(
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(20),
            child: CultivationHeroCard(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.byKey(const ValueKey('cultivation-balance-thumb')),
      findsOneWidget,
    );
    expect(find.text('心定 · 2层'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
