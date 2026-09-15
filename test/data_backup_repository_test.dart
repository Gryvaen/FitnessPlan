import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/data_backup_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Points `getApplicationDocumentsDirectory()`/`getTemporaryDirectory()` at
/// real temp-directory paths so [DataBackupRepository] — which does real
/// file IO (checkpoint, read, close+replace+rename) — can be exercised
/// end-to-end without a device/emulator.
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

void main() {
  late Directory root;
  late File dbFile;
  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('fp_backup_test_');
    final docsDir = Directory(p.join(root.path, 'docs'))..createSync();
    Directory(p.join(root.path, 'cache')).createSync();
    PathProviderPlatform.instance = _FakePathProvider(
      docsDir.path,
      p.join(root.path, 'cache'),
    );

    dbFile = File(p.join(docsDir.path, DataBackupRepository.dbFileName));
    db = AppDatabase.forTesting(NativeDatabase(dbFile));

    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    try {
      await db.close();
    } catch (_) {
      // Already closed by importFromBytes in some tests.
    }
    await root.delete(recursive: true);
  });

  test('buildBackup output is gzip-compressed', () async {
    final repo = DataBackupRepository(db, prefs);
    final payload = await repo.buildBackup();

    expect(payload.fileName, endsWith('.json.gz'));
    // gzip magic header — confirms this isn't plain JSON (which would
    // start with '{', 0x7B).
    expect(payload.bytes.length, greaterThan(2));
    expect(payload.bytes[0], 0x1f);
    expect(payload.bytes[1], 0x8b);
  });

  test('export then import round-trips DB rows and SharedPreferences', () async {
    await db
        .into(db.weightLogs)
        .insert(
          WeightLogsCompanion.insert(date: DateTime(2026, 1, 1), weightKg: 70.5),
        );
    await prefs.setString('theme_id', 'forest');

    final repo = DataBackupRepository(db, prefs);
    final payload = await repo.buildBackup();

    // Mutate state after the backup so a successful import is observable.
    await db
        .into(db.weightLogs)
        .insert(
          WeightLogsCompanion.insert(date: DateTime(2026, 2, 2), weightKg: 999),
        );
    await prefs.setString('theme_id', 'graphite');

    await repo.importFromBytes(payload.bytes);

    final restored = AppDatabase.forTesting(NativeDatabase(dbFile));
    addTearDown(restored.close);
    final rows = await restored.select(restored.weightLogs).get();
    expect(rows, hasLength(1));
    expect(rows.single.weightKg, 70.5);
    expect(prefs.getString('theme_id'), 'forest');
  });

  test(
    'a legacy (pre-gzip) plain-JSON backup still imports correctly',
    () async {
      await db
          .into(db.weightLogs)
          .insert(
            WeightLogsCompanion.insert(
              date: DateTime(2026, 3, 3),
              weightKg: 55.5,
            ),
          );
      await prefs.setString('theme_id', 'sunrise');

      final repo = DataBackupRepository(db, prefs);
      final compressed = await repo.buildBackup();
      // Simulate a backup exported before gzip support: same JSON content,
      // just not gzip-wrapped — exercises importFromBytes' fallback branch.
      final legacyBytes = Uint8List.fromList(gzip.decode(compressed.bytes));
      expect(utf8.decode(legacyBytes).startsWith('{'), isTrue);

      await db
          .into(db.weightLogs)
          .insert(
            WeightLogsCompanion.insert(date: DateTime(2026, 4, 4), weightKg: 1),
          );
      await prefs.setString('theme_id', 'midnight');

      await repo.importFromBytes(legacyBytes);

      final restored = AppDatabase.forTesting(NativeDatabase(dbFile));
      addTearDown(restored.close);
      final rows = await restored.select(restored.weightLogs).get();
      expect(rows, hasLength(1));
      expect(rows.single.weightKg, 55.5);
      expect(prefs.getString('theme_id'), 'sunrise');
    },
  );

  test('garbage bytes are rejected as invalid, not silently accepted', () async {
    final repo = DataBackupRepository(db, prefs);
    await expectLater(
      repo.importFromBytes(Uint8List.fromList(utf8.encode('not a backup'))),
      throwsA(isA<FormatException>()),
    );
  });
}
