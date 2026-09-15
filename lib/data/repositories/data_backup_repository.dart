import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
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
  /// Closes the open database connection first. Caller must invalidate
  /// [databaseProvider] (and reload prefs-backed notifiers) afterwards.
  Future<void> importFromBytes(Uint8List bytes) async {
    final decoded = await compute(_decodeBackup, bytes);
    final dbBytes = decoded.dbBytes;
    final prefsMap = decoded.prefsMap;

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
