import '../db.dart';

/// 「经验之谈」：一份带编号的全文（「1. …」「2. …」，条目之间空一行），
/// 存在 `app_meta` 的一个键里。不分日期，任何时候都能改。
class ExperienceRepository {
  ExperienceRepository(this._db);

  static const key = 'experience_notes';

  final AppDatabase _db;

  Future<String> load() async {
    final row = await (_db.select(
      _db.appMeta,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value ?? '';
  }

  /// Saves the trimmed text; empty text removes the entry.
  Future<void> save(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      await clear();
      return;
    }
    await _db
        .into(_db.appMeta)
        .insertOnConflictUpdate(
          AppMetaCompanion.insert(key: key, value: trimmed),
        );
  }

  /// Removes only this entry; other `app_meta` flags stay.
  Future<void> clear() =>
      (_db.delete(_db.appMeta)..where((t) => t.key.equals(key))).go();
}
