import 'package:diet/data/db.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/providers/core_providers.dart';
import 'package:diet/ui/today/today_workout_card.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

late AppDatabase _db;
late ProviderContainer _container;

Future<void> _setUp() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  _db = AppDatabase.forTesting(NativeDatabase.memory());
  _container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(_db),
    ],
  );
  final bench = await _db
      .into(_db.exercises)
      .insertReturning(
        ExercisesCompanion.insert(
          name: '杠铃卧推',
          unit: 'reps',
          category: const Value('chest'),
        ),
      );
  final squat = await _db
      .into(_db.exercises)
      .insertReturning(
        ExercisesCompanion.insert(
          name: '深蹲',
          unit: 'reps',
          category: const Value('legs'),
        ),
      );
  final upperId = await _db
      .into(_db.workoutPlans)
      .insert(
        WorkoutPlansCompanion.insert(name: '上肢', createdAt: DateTime.now()),
      );
  await _db
      .into(_db.workoutPlanItems)
      .insert(
        WorkoutPlanItemsCompanion.insert(
          planId: upperId,
          exerciseId: bench.id,
          exerciseName: bench.name,
          targetSets: 3,
          targetReps: 12,
        ),
      );
  final legsId = await _db
      .into(_db.workoutPlans)
      .insert(
        WorkoutPlansCompanion.insert(name: '腿部', createdAt: DateTime.now()),
      );
  await _db
      .into(_db.workoutPlanItems)
      .insert(
        WorkoutPlanItemsCompanion.insert(
          planId: legsId,
          exerciseId: squat.id,
          exerciseName: squat.name,
          targetSets: 4,
          targetReps: 8,
        ),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_setUp);
  tearDown(() async {
    _container.dispose();
    await _db.close();
  });

  testWidgets('today workout plus groups plans under exercise categories', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: _container,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('zh'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TodayWorkoutCard(
              day: CalendarDay.todayLocal(),
              sectionPrefix: '今日',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('添加今日训练'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('today-plan-category-filter')),
      findsNothing,
    );

    final chest = tester.getTopLeft(find.text('胸')).dy;
    final upper = tester.getTopLeft(find.text('上肢')).dy;
    final legs = tester.getTopLeft(find.text('腿')).dy;
    final lower = tester.getTopLeft(find.text('腿部')).dy;
    expect(chest, lessThan(upper));
    expect(upper, lessThan(legs));
    expect(legs, lessThan(lower));
  });
}
