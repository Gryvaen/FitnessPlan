import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/experience_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ExperienceRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ExperienceRepository(db);
  });

  tearDown(() => db.close());

  test('saves trimmed text and reads it back', () async {
    expect(await repo.load(), '');
    await repo.save('  1. 少吃夜宵\n\n2. 训练前吃香蕉 \n');
    expect(await repo.load(), '1. 少吃夜宵\n\n2. 训练前吃香蕉');
    await repo.save('1. 改过了');
    expect(await repo.load(), '1. 改过了');
  });

  test('empty text removes the entry', () async {
    await repo.save('1. 少吃夜宵');
    await repo.save('   ');
    expect(await repo.load(), '');
    final rows = await (db.select(
      db.appMeta,
    )..where((t) => t.key.equals(ExperienceRepository.key))).get();
    expect(rows, isEmpty);
  });

  test('clear keeps other app_meta flags', () async {
    await db
        .into(db.appMeta)
        .insert(AppMetaCompanion.insert(key: 'other_flag', value: '1'));
    await repo.save('1. 少吃夜宵');
    await repo.clear();
    expect(await repo.load(), '');
    final rest = await db.select(db.appMeta).get();
    expect(rest.map((r) => r.key), ['other_flag']);
  });
}
