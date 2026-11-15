import 'dart:async';
import 'dart:convert';

import 'package:diet/data/db.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/domain/models.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/providers/app_providers.dart';
import 'package:diet/ui/records/body_records_tab.dart';
import 'package:diet/ui/widgets/form_options.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

UserProfile _profile() => UserProfile(
  sex: Sex.male,
  age: 30,
  heightCm: 175,
  weightKg: 75,
  activity: ActivityLevel.moderate,
  goal: FitnessGoal.cut,
  targets: const MacroTargets(
    calories: 2000,
    proteinG: 150,
    carbG: 215,
    fatG: 60,
  ),
  bmr: 1700,
  tdee: 2400,
  dailyDeficit: 400,
  calorieStandardSince: DateTime(2026, 1, 1),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;
  final today = CalendarDay.todayLocal();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'user_profile': jsonEncode(_profile().toJson()),
    });
    final prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> insertWeight(DateTime day, double kg) => db
      .into(db.weightLogs)
      .insert(
        WeightLogsCompanion.insert(
          date: CalendarDay.dayOnly(day),
          weightKg: kg,
        ),
      );

  group('weighInSkewedByCheatDay', () {
    test('covers the 放纵日 and the 3 days after it', () async {
      final markers = container.read(dayMarkerRepositoryProvider);
      final cheat = CalendarDay.addDays(today, -3);
      await markers.setCheatMeal(cheat);
      for (var back = 0; back <= 3; back++) {
        expect(
          await weighInSkewedByCheatDay(
            markers,
            CalendarDay.addDays(cheat, back),
          ),
          isTrue,
          reason: '放纵日 + $back',
        );
      }
      expect(
        await weighInSkewedByCheatDay(markers, CalendarDay.addDays(cheat, 4)),
        isFalse,
      );
      expect(
        await weighInSkewedByCheatDay(markers, CalendarDay.addDays(cheat, -1)),
        isFalse,
      );
    });

    test('other day markers do not skew a weigh-in', () async {
      final markers = container.read(dayMarkerRepositoryProvider);
      await markers.setRestDay(CalendarDay.addDays(today, -1));
      expect(await weighInSkewedByCheatDay(markers, today), isFalse);
    });
  });

  test('latestProfileWeighIn skips weigh-ins inside a 放纵日 window', () async {
    final weights = container.read(weightRepositoryProvider);
    final markers = container.read(dayMarkerRepositoryProvider);
    expect(await latestProfileWeighIn(weights, markers), isNull);

    await insertWeight(CalendarDay.addDays(today, -6), 74);
    await insertWeight(CalendarDay.addDays(today, -2), 76);
    await insertWeight(today, 75.5);
    await markers.setCheatMeal(CalendarDay.addDays(today, -2));
    expect((await latestProfileWeighIn(weights, markers))!.weightKg, 74);

    await db.delete(db.weightLogs).go();
    await insertWeight(today, 75.5);
    expect(await latestProfileWeighIn(weights, markers), isNull);
  });

  Future<BodyRecordsTabState> pumpBodyTab(WidgetTester tester) async {
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
          locale: const Locale('zh'),
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
    return tester.state<BodyRecordsTabState>(find.byType(BodyRecordsTab));
  }

  Future<void> logWeight(WidgetTester tester, double kg) async {
    final state = await pumpBodyTab(tester);
    unawaited(state.addWeight());
    await tester.pumpAndSettle();
    tester
        .widget<AppDropdown<double>>(find.byType(AppDropdown<double>).first)
        .onChanged(kg);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();
  }

  testWidgets('weight logged after a 放纵日 is kept but leaves the profile', (
    tester,
  ) async {
    await container
        .read(dayMarkerRepositoryProvider)
        .setCheatMeal(CalendarDay.addDays(today, -1));
    await logWeight(tester, 72);

    final log = await container.read(weightRepositoryProvider).latest();
    expect(log!.weightKg, 72);
    expect(container.read(profileProvider)!.weightKg, 75);
    expect(find.text('放纵日后 3 天内的体重只记录，不更新档案'), findsOneWidget);
  });

  testWidgets('weight logged outside a 放纵日 window updates the profile', (
    tester,
  ) async {
    await container
        .read(dayMarkerRepositoryProvider)
        .setCheatMeal(CalendarDay.addDays(today, -4));
    await logWeight(tester, 72);

    expect(container.read(profileProvider)!.weightKg, 72);
    expect(find.text('放纵日后 3 天内的体重只记录，不更新档案'), findsNothing);
  });
}
