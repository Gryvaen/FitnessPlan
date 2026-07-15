import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitness_plan/data/db.dart';
import 'package:fitness_plan/data/repositories/backup_repository.dart';
import 'package:fitness_plan/data/repositories/profile_repository.dart';
import 'package:fitness_plan/domain/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProfileRepository profileRepo;
  late BackupRepository backup;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    profileRepo = ProfileRepository(prefs);
    backup = BackupRepository(db, profileRepo);
  });

  tearDown(() async {
    await db.close();
  });

  test('export and import round-trip meals and profile', () async {
    final profile = await profileRepo.saveFromInputs(
      sex: Sex.male,
      age: 25,
      heightCm: 180,
      weightKg: 75,
      activity: ActivityLevel.sedentary,
      goal: FitnessGoal.maintain,
    );
    await db.into(db.mealEntries).insert(
          MealEntriesCompanion.insert(
            date: DateTime(2026, 7, 1),
            mealType: MealType.lunch.name,
            foodId: 1,
            foodName: '米饭',
            grams: 100,
            calories: 116,
            proteinG: 2.6,
            carbG: 25,
            fatG: 0.3,
          ),
        );
    await db.into(db.weightLogs).insert(
          WeightLogsCompanion.insert(
            date: DateTime(2026, 7, 1),
            weightKg: 75,
          ),
        );

    final bundle = await backup.buildBundle();
    expect(bundle.profile?['age'], profile.age);
    expect(bundle.meals, hasLength(1));
    expect(bundle.weights, hasLength(1));

    await backup.clearUserData(includeProfile: true);
    expect(profileRepo.load(), isNull);
    expect(await db.select(db.mealEntries).get(), isEmpty);

    await backup.importFromJson(jsonEncode(bundle.toJson()));
    expect(profileRepo.load()?.age, 25);
    expect(await db.select(db.mealEntries).get(), hasLength(1));
    expect(await db.select(db.weightLogs).get(), hasLength(1));
  });
}
