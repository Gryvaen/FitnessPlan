import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../../domain/calendar_day.dart';
import '../db.dart';

/// A single-file local backup ready to save or share.
class BackupPayload {
  const BackupPayload({required this.fileName, required this.bytes});

  final String fileName;
  final Uint8List bytes;
}

typedef _BackupEncodeInput = ({
  Uint8List dbBytes,
  Map<String, Object?> prefs,
  String exportedAt,
});

/// Top-level (not a method) so it can run via [compute] on a background
/// isolate — base64/JSON-encoding the whole DB blocks the caller otherwise,
/// growing with the DB's size over years of use. Gzipped on top: the
/// dominant content is `databaseBase64`, and base64-of-SQLite compresses
/// well (SQLite pages have a lot of redundancy, and base64 itself doesn't
/// hide that from a byte-oriented compressor).
Uint8List _encodeBackup(_BackupEncodeInput input) {
  final encoded = utf8.encode(
    jsonEncode({
      'formatVersion': DataBackupRepository.formatVersion,
      'exportedAt': input.exportedAt,
      'prefs': input.prefs,
      'databaseBase64': base64Encode(input.dbBytes),
    }),
  );
  return Uint8List.fromList(gzip.encode(encoded));
}

/// The backup's database was written by a newer app build (its schema
/// version is ahead of this one), so it can't be migrated here.
class BackupTooNewException implements Exception {
  const BackupTooNewException(this.backupVersion, this.appVersion);

  final int backupVersion;
  final int appVersion;

  @override
  String toString() =>
      'BackupTooNewException(backup: $backupVersion, app: $appVersion)';
}

/// SQLite's header magic; `PRAGMA user_version` sits big-endian at byte 60.
const _sqliteMagic = 'SQLite format 3\u0000';

/// Rejects anything that isn't a SQLite file, and databases from a newer
/// schema, before the live database is touched.
void _checkBackupDatabase(Uint8List dbBytes) {
  if (dbBytes.length < 100 ||
      String.fromCharCodes(dbBytes, 0, _sqliteMagic.length) != _sqliteMagic) {
    throw const FormatException('invalid_backup');
  }
  final userVersion = ByteData.sublistView(dbBytes, 60, 64).getUint32(0);
  if (userVersion > AppDatabase.currentSchemaVersion) {
    throw BackupTooNewException(userVersion, AppDatabase.currentSchemaVersion);
  }
}

typedef _DecodedBackup = ({Uint8List dbBytes, Map<String, dynamic> prefsMap});

/// Top-level so it can run via [compute]; same rationale as [_encodeBackup].
_DecodedBackup _decodeBackup(Uint8List bytes) {
  List<int> jsonBytes;
  try {
    jsonBytes = gzip.decode(bytes);
  } catch (_) {
    // Backups written before gzip support are plain JSON bytes — the gzip
    // magic header check above fails immediately (JSON always starts with
    // `{`, never the gzip signature), so this fallback is unambiguous.
    jsonBytes = bytes;
  }
  final root = jsonDecode(utf8.decode(jsonBytes));
  if (root is! Map) {
    throw const FormatException('invalid_backup');
  }
  final map = Map<String, dynamic>.from(root);
  final version = map['formatVersion'];
  if (version != DataBackupRepository.formatVersion) {
    throw const FormatException('unsupported_backup_version');
  }
  final dbB64 = map['databaseBase64'];
  final prefsRaw = map['prefs'];
  if (dbB64 is! String || prefsRaw is! Map) {
    throw const FormatException('invalid_backup');
  }
  return (
    dbBytes: base64Decode(dbB64),
    prefsMap: Map<String, dynamic>.from(prefsRaw),
  );
}

/// Builds / restores a local backup: SQLite DB (base64) + SharedPreferences JSON.
class DataBackupRepository {
  DataBackupRepository(this._db, this._prefs);

  final AppDatabase _db;
  final SharedPreferences _prefs;

  static const formatVersion = 1;
  static const dbFileName = 'fitness_plan.sqlite';

  /// Local day (ISO date) of the last import. Step sync must not lower that
  /// day's restored total, since this device's sensor never counted it.
  static const importedOnDayKey = 'steps_imported_on_day';

  /// Prefs that describe this device rather than the user's data: an
  /// in-flight update download, a running rest timer, background-permission
  /// acknowledgements. They are left out of a backup and keep this device's
  /// values on import — restoring another phone's download id made the
  /// updater chase a download that doesn't exist here.
  static bool isDeviceLocalPrefKey(String key) =>
      key.startsWith('app_update_') || _deviceLocalPrefKeys.contains(key);

  static const _deviceLocalPrefKeys = {
    'rest_timer_deadline_ms',
    'rest_timer_paused_seconds',
    'rest_timer_finished',
    'rest_timer_background_ack',
    'oem_background_ack',
    'reminder_missed_warned_until',
    'step_service_user_choice_set',
  };

  String _stamp() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${n.year}${two(n.month)}${two(n.day)}_'
        '${two(n.hour)}${two(n.minute)}${two(n.second)}';
  }

  /// Snapshot the live DB, then encode DB + prefs into one JSON payload.
  Future<BackupPayload> buildBackup() async {
    // A consistent copy through SQLite itself, rather than reading the live
    // file while a background write (e.g. step sync) may be half-done.
    final tmpDir = await getTemporaryDirectory();
    final snapshot = File(
      p.join(tmpDir.path, 'backup_${DateTime.now().microsecondsSinceEpoch}.db'),
    );
    Uint8List dbBytes;
    try {
      if (await snapshot.exists()) await snapshot.delete();
      await _db.customStatement('VACUUM INTO ?', [snapshot.path]);
      dbBytes = await snapshot.readAsBytes();
    } finally {
      if (await snapshot.exists()) await snapshot.delete();
    }

    final prefs = <String, Object?>{};
    for (final key in _prefs.getKeys()) {
      if (isDeviceLocalPrefKey(key)) continue;
      prefs[key] = _prefs.get(key);
    }

    final bytes = await compute(_encodeBackup, (
      dbBytes: dbBytes,
      prefs: prefs,
      exportedAt: DateTime.now().toIso8601String(),
    ));

    return BackupPayload(
      fileName: 'FitnessPlan_backup_${_stamp()}.json.gz',
      bytes: bytes,
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
  /// The restored DB is written to a staging file and checked
  /// (`PRAGMA integrity_check`) before the live one is touched; a rejected
  /// backup throws [FormatException] and leaves the live data as it was. The
  /// live DB is moved aside rather than deleted until the swap succeeds.
  /// Device-local prefs ([isDeviceLocalPrefKey]) keep this device's values.
  ///
  /// Closes the open database connection first. Caller must invalidate
  /// [databaseProvider] (and reload prefs-backed notifiers) afterwards.
  Future<void> importFromBytes(Uint8List bytes) async {
    final decoded = await compute(_decodeBackup, bytes);
    final dbBytes = decoded.dbBytes;
    final prefsMap = decoded.prefsMap;
    _checkBackupDatabase(dbBytes);

    final docs = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docs.path, dbFileName);
    final staging = File('$dbPath.importing');
    await staging.writeAsBytes(dbBytes, flush: true);
    try {
      _checkIntegrity(staging.path);
    } catch (_) {
      if (await staging.exists()) await staging.delete();
      rethrow;
    }

    await _db.close();

    const sides = ['', '-wal', '-shm', '-journal'];
    final moved = <String>[];
    try {
      for (final suffix in sides) {
        final side = File('$dbPath$suffix');
        if (await side.exists()) {
          await side.rename('$dbPath$suffix.bak');
          moved.add(suffix);
        }
      }
      await staging.rename(dbPath);
    } catch (_) {
      // Put the live DB back exactly as it was.
      for (final suffix in moved) {
        final current = File('$dbPath$suffix');
        if (await current.exists()) await current.delete();
        await File('$dbPath$suffix.bak').rename('$dbPath$suffix');
      }
      if (await staging.exists()) await staging.delete();
      rethrow;
    }
    for (final suffix in moved) {
      final bak = File('$dbPath$suffix.bak');
      if (await bak.exists()) await bak.delete();
    }

    // Everything to write is decided first, so the window between removing
    // the old values and writing the restored ones is as short as possible.
    final restore = <String, Object>{
      for (final entry in prefsMap.entries)
        if (entry.value != null && !isDeviceLocalPrefKey(entry.key))
          entry.key: entry.value as Object,
    };
    for (final key in _prefs.getKeys().toList()) {
      if (!isDeviceLocalPrefKey(key)) await _prefs.remove(key);
    }
    for (final MapEntry(:key, :value) in restore.entries) {
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
    await _prefs.setString(
      importedOnDayKey,
      CalendarDay.todayLocal().toIso8601String(),
    );
  }

  /// Opens the restored file read-only and requires SQLite's own integrity
  /// check to pass: a truncated or corrupted backup can keep a valid header.
  static void _checkIntegrity(String path) {
    sqlite.Database? db;
    try {
      db = sqlite.sqlite3.open(path, mode: sqlite.OpenMode.readOnly);
      final rows = db.select('PRAGMA integrity_check');
      final ok = rows.length == 1 && '${rows.first.values.first}' == 'ok';
      if (!ok) throw const FormatException('invalid_backup');
    } on sqlite.SqliteException {
      throw const FormatException('invalid_backup');
    } finally {
      db?.close();
    }
  }
}
