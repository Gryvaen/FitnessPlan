import 'dart:convert';
import 'dart:io';

import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/data_backup_repository.dart';
import 'package:diet/domain/calendar_day.dart';
import 'package:diet/domain/cut_cultivation.dart';
import 'package:diet/domain/maintain_balance.dart';
import 'package:diet/domain/models.dart';
import 'package:diet/providers/app_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this._docsPath, this._tempPath);

  final String _docsPath;
  final String _tempPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => _docsPath;

  @override
  Future<String?> getTemporaryPath() async => _tempPath;
}

UserProfile _profile(FitnessGoal goal) => UserProfile(
  sex: Sex.male,
  age: 30,
  heightCm: 175,
  weightKg: 75,
  activity: ActivityLevel.moderate,
  goal: goal,
  targets: const MacroTargets(
    calories: 2400,
    proteinG: 150,
    carbG: 300,
    fatG: 67,
  ),
  tdee: 2400,
  calorieStandardSince: DateTime(2026, 1, 1),
);

const _maintainKey = 'maintain_cultivation_state';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final today = CalendarDay.todayLocal();
  final maintainSince = CalendarDay.addDays(today, -20);

  late Directory root;
  late SharedPreferences prefs;
  late ProviderContainer container;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('fp_import_refresh_');
    final docs = Directory(p.join(root.path, 'docs'))..createSync();
    final cache = Directory(p.join(root.path, 'cache'))..createSync();
    PathProviderPlatform.instance = _FakePathProvider(docs.path, cache.path);
    final dbPath = p.join(docs.path, DataBackupRepository.dbFileName);

    // The backup's side: on 维持 since [maintainSince].
    SharedPreferences.setMockInitialValues({
      'user_profile': jsonEncode(_profile(FitnessGoal.maintain).toJson()),
      _maintainKey: jsonEncode(
        MaintainCultivationState(
          segments: [CutCultivationSegment(start: maintainSince)],
          goalPeriodsImported: true,
        ).toJson(),
      ),
    });
    prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        // Same file as the app's connection, reopened after each invalidate.
        databaseProvider.overrideWith((ref) {
          final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
          ref.onDispose(() {
            try {
              db.close();
            } catch (_) {}
          });
          return db;
        }),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    try {
      await root.delete(recursive: true);
    } catch (_) {}
  });

  test('every screen sees the imported data right away', () async {
    await container
        .read(weightRepositoryProvider)
        .add(date: today, weightKg: 70);
    final backup = await container
        .read(dataBackupRepositoryProvider)
        .buildBackup();

    // This phone before the import: on 减脂, another weight, no 维持 ledger.
    await container
        .read(weightRepositoryProvider)
        .add(date: today, weightKg: 80);
    await prefs.setString(
      'user_profile',
      jsonEncode(_profile(FitnessGoal.cut).toJson()),
    );
    await prefs.remove(_maintainKey);
    reloadPrefsBackedState(container.read);

    // Screens that are open while importing.
    final weights = container.listen(weightLogsProvider, (_, _) {});
    container.listen(maintainHistoryProvider, (_, _) {});
    container.listen(maintainBalanceProvider, (_, _) {});
    await container.read(weightLogsProvider.future);
    expect(weights.read().value!.single.weightKg, 80);
    expect(container.read(maintainCultivationStateProvider).segments, isEmpty);

    await container
        .read(dataBackupRepositoryProvider)
        .importFromBytes(backup.bytes);
    await refreshAfterImport(
      read: container.read,
      invalidate: container.invalidate,
    );

    expect(container.read(profileProvider)!.goal, FitnessGoal.maintain);
    expect(
      (await container.read(weightLogsProvider.future)).single.weightKg,
      70,
    );
    final ledger = container.read(maintainCultivationStateProvider);
    expect(ledger.segments.single.start, maintainSince);

    // The 维持 page rebuilt on the imported profile: it must not open a new
    // stretch over the stale ledger and save that over the imported one.
    final sections = await container.read(maintainHistoryProvider.future);
    expect(sections.single.segment.start, maintainSince);
    final saved = MaintainCultivationState.fromJson(
      jsonDecode(prefs.getString(_maintainKey)!) as Map<String, dynamic>,
    );
    expect(saved.segments.single.start, maintainSince);
  });

  test('清空数据 also drops the 维持 ledger', () async {
    expect(
      container.read(maintainCultivationStateProvider).segments,
      hasLength(1),
    );
    await clearUserData(container.read);
    expect(prefs.getString(_maintainKey), isNull);
    expect(container.read(maintainCultivationStateProvider).segments, isEmpty);
  });
}
