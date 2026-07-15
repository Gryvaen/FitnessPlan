import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/models.dart';
import '../db.dart';
import 'profile_repository.dart';

const kBackupFormatVersion = 1;

class BackupBundle {
  const BackupBundle({
    required this.version,
    required this.exportedAt,
    this.profile,
    required this.meals,
    required this.weights,
    required this.favoriteFoodIds,
  });

  final int version;
  final DateTime exportedAt;
  final Map<String, dynamic>? profile;
  final List<Map<String, dynamic>> meals;
  final List<Map<String, dynamic>> weights;
  final List<int> favoriteFoodIds;

  factory BackupBundle.fromJson(Map<String, dynamic> json) {
    return BackupBundle(
      version: json['version'] as int? ?? 1,
      exportedAt: DateTime.tryParse(json['exportedAt'] as String? ?? '') ??
          DateTime.now(),
      profile: json['profile'] as Map<String, dynamic>?,
      meals: (json['meals'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>(),
      weights: (json['weights'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>(),
      favoriteFoodIds: (json['favoriteFoodIds'] as List<dynamic>? ?? const [])
          .map((e) => (e as num).toInt())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'exportedAt': exportedAt.toIso8601String(),
        'profile': profile,
        'meals': meals,
        'weights': weights,
        'favoriteFoodIds': favoriteFoodIds,
      };
}

class BackupRepository {
  BackupRepository(this._db, this._profile);

  final AppDatabase _db;
  final ProfileRepository _profile;

  Future<BackupBundle> buildBundle() async {
    final meals = await _db.select(_db.mealEntries).get();
    final weights = await _db.select(_db.weightLogs).get();
    final favorites = await _db.select(_db.favoriteFoods).get();
    final profile = _profile.load();

    return BackupBundle(
      version: kBackupFormatVersion,
      exportedAt: DateTime.now().toUtc(),
      profile: profile?.toJson(),
      meals: [
        for (final m in meals)
          {
            'date': m.date.toIso8601String(),
            'mealType': m.mealType,
            'foodId': m.foodId,
            'foodName': m.foodName,
            'grams': m.grams,
            'calories': m.calories,
            'proteinG': m.proteinG,
            'carbG': m.carbG,
            'fatG': m.fatG,
          },
      ],
      weights: [
        for (final w in weights)
          {
            'date': w.date.toIso8601String(),
            'weightKg': w.weightKg,
            'bodyFatPct': w.bodyFatPct,
            'exerciseMinutes': w.exerciseMinutes,
          },
      ],
      favoriteFoodIds: [for (final f in favorites) f.foodId],
    );
  }

  Future<File> exportToFile() async {
    final bundle = await buildBundle();
    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('.', '');
    final file = File(p.join(dir.path, 'fitness_plan_backup_$stamp.json'));
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(bundle.toJson()),
    );
    return file;
  }

  Future<void> importFromJson(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('备份文件格式无效');
    }
    final bundle = BackupBundle.fromJson(decoded);
    if (bundle.version > kBackupFormatVersion) {
      throw FormatException('不支持的备份版本 ${bundle.version}');
    }

    await _db.transaction(() async {
      await _db.delete(_db.mealEntries).go();
      await _db.delete(_db.weightLogs).go();
      await _db.delete(_db.favoriteFoods).go();

      for (final m in bundle.meals) {
        await _db.into(_db.mealEntries).insert(
              MealEntriesCompanion.insert(
                date: DateTime.parse(m['date'] as String),
                mealType: m['mealType'] as String,
                foodId: (m['foodId'] as num).toInt(),
                foodName: m['foodName'] as String,
                grams: (m['grams'] as num).toDouble(),
                calories: (m['calories'] as num).toDouble(),
                proteinG: (m['proteinG'] as num).toDouble(),
                carbG: (m['carbG'] as num).toDouble(),
                fatG: (m['fatG'] as num).toDouble(),
              ),
            );
      }

      for (final w in bundle.weights) {
        await _db.into(_db.weightLogs).insert(
              WeightLogsCompanion.insert(
                date: DateTime.parse(w['date'] as String),
                weightKg: (w['weightKg'] as num).toDouble(),
                bodyFatPct: Value(
                  (w['bodyFatPct'] as num?)?.toDouble(),
                ),
                exerciseMinutes: Value(
                  (w['exerciseMinutes'] as num?)?.toInt(),
                ),
              ),
            );
      }

      final now = DateTime.now();
      for (final id in bundle.favoriteFoodIds) {
        final exists = await (_db.select(_db.foodItems)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        if (exists == null) continue;
        await _db.into(_db.favoriteFoods).insertOnConflictUpdate(
              FavoriteFoodsCompanion.insert(
                foodId: Value(id),
                createdAt: now,
              ),
            );
      }
    });

    if (bundle.profile != null) {
      try {
        final profile = UserProfile.fromJson(bundle.profile!);
        await _profile.save(profile);
      } catch (_) {
        await _profile.clear();
      }
    } else {
      await _profile.clear();
    }
  }

  Future<void> clearUserData({required bool includeProfile}) async {
    await _db.transaction(() async {
      await _db.delete(_db.mealEntries).go();
      await _db.delete(_db.weightLogs).go();
      await _db.delete(_db.favoriteFoods).go();
    });
    if (includeProfile) {
      await _profile.clear();
    }
  }
}
