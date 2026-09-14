import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db.dart';

/// A single-file local backup ready to save or share.
class BackupPayload {
  const BackupPayload({required this.fileName, required this.bytes});

  final String fileName;
  final Uint8List bytes;
}

/// Builds / restores a local backup: SQLite DB (base64) + SharedPreferences JSON.
class DataBackupRepository {
  DataBackupRepository(this._db, this._prefs);

  final AppDatabase _db;
  final SharedPreferences _prefs;

  static const formatVersion = 1;
  static const dbFileName = 'fitness_plan.sqlite';

  String _stamp() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${n.year}${two(n.month)}${two(n.day)}_'
        '${two(n.hour)}${two(n.minute)}${two(n.second)}';
  }

  /// Checkpoint the live DB, then encode DB + prefs into one JSON payload.
  Future<BackupPayload> buildBackup() async {
    await _db.customStatement('PRAGMA wal_checkpoint(FULL)');

    final docs = await getApplicationDocumentsDirectory();
    final sourceDb = File(p.join(docs.path, dbFileName));
    final dbBytes = await sourceDb.exists()
        ? await sourceDb.readAsBytes()
        : Uint8List(0);

    final prefs = <String, Object?>{};
    for (final key in _prefs.getKeys()) {
      prefs[key] = _prefs.get(key);
    }

    final encoded = utf8.encode(
      jsonEncode({
        'formatVersion': formatVersion,
        'exportedAt': DateTime.now().toIso8601String(),
        'prefs': prefs,
        'databaseBase64': base64Encode(dbBytes),
      }),
    );

    return BackupPayload(
      fileName: 'FitnessPlan_backup_${_stamp()}.json',
      bytes: Uint8List.fromList(encoded),
    );
  }

  /// Writes the backup into the app temp directory for system share sheets.
  Future<File> writeBackupToTemp() async {
    final payload = await buildBackup();
    final tmp = await getTemporaryDirectory();
    final file = File(p.join(tmp.path, payload.fileName));
    await file.writeAsBytes(payload.bytes, flush: true);
    return file;
  }

  /// Replaces the on-disk DB and SharedPreferences with [bytes].
  ///
  /// Closes the open database connection first. Caller must invalidate
  /// [databaseProvider] (and reload prefs-backed notifiers) afterwards.
  Future<void> importFromBytes(Uint8List bytes) async {
    final root = jsonDecode(utf8.decode(bytes));
    if (root is! Map) {
      throw const FormatException('invalid_backup');
    }
    final map = Map<String, dynamic>.from(root);
    final version = map['formatVersion'];
    if (version != formatVersion) {
      throw const FormatException('unsupported_backup_version');
    }
    final dbB64 = map['databaseBase64'];
    final prefsRaw = map['prefs'];
    if (dbB64 is! String || prefsRaw is! Map) {
      throw const FormatException('invalid_backup');
    }
    final dbBytes = base64Decode(dbB64);
    final prefsMap = Map<String, dynamic>.from(prefsRaw);

    await _db.close();

    final docs = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docs.path, dbFileName);
    final staging = File('$dbPath.importing');
    await staging.writeAsBytes(dbBytes, flush: true);

    for (final suffix in ['', '-wal', '-shm']) {
      final side = File('$dbPath$suffix');
      if (await side.exists()) await side.delete();
    }
    await staging.rename(dbPath);

    await _prefs.clear();
    for (final entry in prefsMap.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value == null) continue;
      if (value is bool) {
        await _prefs.setBool(key, value);
      } else if (value is int) {
        await _prefs.setInt(key, value);
      } else if (value is double) {
        await _prefs.setDouble(key, value);
      } else if (value is String) {
        await _prefs.setString(key, value);
      } else if (value is List) {
        await _prefs.setStringList(
          key,
          value.map((e) => e.toString()).toList(),
        );
      }
    }
  }
}
