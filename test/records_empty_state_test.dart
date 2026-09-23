import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/step_repository.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/providers/core_providers.dart';
import 'package:diet/providers/step_providers.dart';
import 'package:diet/providers/workout_providers.dart';
import 'package:diet/ui/ink/ink_icon.dart';
import 'package:diet/ui/records/body_records_tab.dart';
import 'package:diet/ui/records/notes_records_tab.dart';
import 'package:diet/ui/records/train_records_tab.dart';
import 'package:diet/ui/theme/sport_chrome.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
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

  Future<void> pump(WidgetTester tester, Widget child) async {
    final router = GoRouter(
      initialLocation: '/records',
      routes: [
        GoRoute(
          path: '/records',
          builder: (_, _) => Scaffold(body: child),
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
  }

  void expectStampedIcon({required InkGlyph glyph, required String seal}) {
    final stamped = find.byKey(ValueKey('stamped-empty-icon-$seal'));
    expect(stamped, findsOneWidget);
    final icon = testerWidget<InkIcon>(
      find.descendant(of: stamped, matching: find.byType(InkIcon)),
    );
    expect(icon.glyph, glyph);
    expect(icon.size, 52);
    final inkSeal = testerWidget<InkSeal>(
      find.descendant(of: stamped, matching: find.byType(InkSeal)),
    );
    expect(inkSeal.character, seal);
    expect(inkSeal.size, 19);
  }

  testWidgets('body empty state uses the body stamped ink icon', (
    tester,
  ) async {
    await pump(tester, const BodyRecordsTab());

    expect(find.text('还没有记录，点加号添加'), findsOneWidget);
    expect(find.text('体重 (kg)'), findsNothing);
    final historyTop = tester.getTopLeft(find.text('每日记录')).dy;
    final addTop = tester.getTopLeft(find.byTooltip('记体重')).dy;
    expect(historyTop, lessThan(48));
    expect(addTop, lessThan(48));
    expectStampedIcon(glyph: InkGlyph.profile, seal: '身');
    expect(tester.takeException(), isNull);
  });

  testWidgets('body metrics use custom ink charts once logs exist', (
    tester,
  ) async {
    await db
        .into(db.weightLogs)
        .insert(
          WeightLogsCompanion.insert(
            date: DateTime.now(),
            weightKg: 70.5,
            bodyFatPct: const Value(18.2),
          ),
        );
    await pump(tester, const BodyRecordsTab());

    for (final title in ['体重 (kg)', '体脂率 (%)']) {
      final chart = find.byKey(ValueKey('ink-series-chart-$title'));
      expect(chart, findsOneWidget);
      expect(
        find.descendant(of: chart, matching: find.byType(CustomPaint)),
        findsOneWidget,
      );
    }
    expect(find.text('70.5 kg'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('training plan empty state uses the training stamped ink icon', (
    tester,
  ) async {
    await pump(tester, const TrainRecordsTab());

    expect(find.text('还没有计划，点加号新建'), findsOneWidget);
    expectStampedIcon(glyph: InkGlyph.training, seal: '炼');
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty exercise library uses the training stamped ink icon', (
    tester,
  ) async {
    await pump(tester, const TrainRecordsTab(initialTab: 1));

    expect(find.text('暂无动作'), findsOneWidget);
    expectStampedIcon(glyph: InkGlyph.training, seal: '炼');
    expect(tester.takeException(), isNull);
  });

  testWidgets('exercise search with no matches keeps the stamped empty state', (
    tester,
  ) async {
    await db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            name: '深蹲',
            unit: 'reps',
            category: const Value('legs'),
          ),
        );
    await pump(tester, const TrainRecordsTab(initialTab: 1));

    await tester.enterText(find.byType(TextField), '不存在的动作');
    await tester.pumpAndSettle();

    expect(find.text('暂无动作'), findsOneWidget);
    expectStampedIcon(glyph: InkGlyph.training, seal: '炼');
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty all-workout history uses the training stamped ink icon', (
    tester,
  ) async {
    final today = CalendarDay.todayLocal();
    final steps = StepRepository(db);
    await steps.setStepsForDay(today, 4000);
    await steps.setStepsForDay(today.subtract(const Duration(days: 13)), 6000);
    final subscriptions = [
      container.listen(recentStepsProvider, (_, _) {}),
      container.listen(allStepsProvider, (_, _) {}),
      container.listen(workoutHistoryProvider, (_, _) {}),
      container.listen(allWorkoutHistoryProvider, (_, _) {}),
    ];
    addTearDown(() {
      for (final subscription in subscriptions) {
        subscription.close();
      }
    });
    await Future.wait([
      container.read(recentStepsProvider.future),
      container.read(allStepsProvider.future),
      container.read(workoutHistoryProvider.future),
      container.read(allWorkoutHistoryProvider.future),
    ]);
    await pump(tester, const TrainRecordsTab(initialTab: 2));

    final scopeTabs = tester
        .widgetList<SportTabs<int>>(find.byType(SportTabs<int>))
        .firstWhere((tabs) => tabs.items.values.contains('全部'));
    scopeTabs.onSelected(1);
    await tester.pumpAndSettle();

    expect(find.text('暂无组次记录'), findsOneWidget);
    expectStampedIcon(glyph: InkGlyph.training, seal: '炼');
    expect(tester.takeException(), isNull);
  });

  testWidgets('notes empty state uses the note stamped ink icon', (
    tester,
  ) async {
    await pump(tester, const NotesRecordsTab());

    expect(find.text('记录今天的训练感受、睡眠或饮食偏差'), findsOneWidget);
    expectStampedIcon(glyph: InkGlyph.edit, seal: '记');
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared stamped icon keeps the Today empty-state dimensions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StampedInkEmptyIcon(glyph: InkGlyph.mealEmpty, seal: '食'),
        ),
      ),
    );

    expectStampedIcon(glyph: InkGlyph.mealEmpty, seal: '食');
  });
}

T testerWidget<T extends Widget>(Finder finder) {
  final widgets = finder.evaluate();
  expect(widgets, hasLength(1));
  return widgets.single.widget as T;
}
