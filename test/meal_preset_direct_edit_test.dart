import 'package:diet/data/db.dart';
import 'package:diet/data/repositories/meal_preset_repository.dart';
import 'package:diet/data/repositories/meal_repository.dart';
import 'package:diet/domain/models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Future<int> _food(AppDatabase db, String name) => db
    .into(db.foodItems)
    .insert(
      FoodItemsCompanion.insert(
        name: name,
        category: '谷物',
        kcalPer100: 100,
        proteinPer100: 5,
        carbPer100: 10,
        fatPer100: 2,
      ),
    );

Future<int> _preset(AppDatabase db, String name) => db
    .into(db.mealPresets)
    .insert(MealPresetsCompanion.insert(name: name, createdAt: DateTime.now()));

void main() {
  test('direct edits preserve preset and item identities', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = MealPresetRepository(db, MealRepository(db));
    final presetId = await _preset(db, '早餐');
    final foodId = await _food(db, '燕麦');
    final itemId = await repo.addItem(
      presetId: presetId,
      foodId: foodId,
      grams: 100,
      mealType: MealType.breakfast,
    );
    await repo.renamePreset(presetId, '  新早餐  ');
    await repo.updateItem(
      presetId: presetId,
      itemId: itemId,
      grams: 175,
      mealType: MealType.lunch,
    );
    expect((await repo.presetById(presetId))!.name, '新早餐');
    final item = (await repo.itemsFor(presetId)).single;
    expect(item.id, itemId);
    expect(item.grams, 175);
    expect(item.mealType, 'lunch');
  });

  test(
    'whole-meal deletion affects only its meal and can leave empty preset',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = MealPresetRepository(db, MealRepository(db));
      final presetId = await _preset(db, '套餐');
      final otherPresetId = await _preset(db, '其他套餐');
      final foodId = await _food(db, '燕麦');
      await repo.addItem(
        presetId: presetId,
        foodId: foodId,
        grams: 100,
        mealType: MealType.breakfast,
      );
      await repo.addItem(
        presetId: presetId,
        foodId: foodId,
        grams: 150,
        mealType: MealType.lunch,
      );
      await repo.addItem(
        presetId: presetId,
        foodId: foodId,
        grams: 200,
        mealType: MealType.lunch,
      );
      await repo.addItem(
        presetId: otherPresetId,
        foodId: foodId,
        grams: 50,
        mealType: MealType.lunch,
      );
      expect(
        await repo.deleteMealType(presetId: presetId, mealType: MealType.lunch),
        2,
      );
      final remaining = (await repo.itemsFor(presetId)).single;
      expect(remaining.mealType, 'breakfast');
      expect(await repo.itemsFor(otherPresetId), hasLength(1));
      await repo.deleteItem(presetId: presetId, itemId: remaining.id);
      expect(await repo.itemsFor(presetId), isEmpty);
      expect((await repo.presetById(presetId))!.id, presetId);
      await repo.addItem(
        presetId: presetId,
        foodId: foodId,
        grams: 120,
        mealType: MealType.dinner,
      );
      expect((await repo.itemsFor(presetId)).single.mealType, 'dinner');
    },
  );

  test('invalid direct edits do not change another preset', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = MealPresetRepository(db, MealRepository(db));
    final first = await _preset(db, '第一份');
    final second = await _preset(db, '第二份');
    final foodId = await _food(db, '燕麦');
    final itemId = await repo.addItem(
      presetId: second,
      foodId: foodId,
      grams: 100,
      mealType: MealType.breakfast,
    );
    await expectLater(repo.renamePreset(first, ' 第二份 '), throwsStateError);
    await expectLater(repo.renamePreset(first, '  '), throwsArgumentError);
    await expectLater(
      repo.updateItem(
        presetId: first,
        itemId: itemId,
        grams: 50,
        mealType: MealType.lunch,
      ),
      throwsStateError,
    );
    await expectLater(
      repo.deleteItem(presetId: first, itemId: itemId),
      throwsStateError,
    );
    expect((await repo.presetById(first))!.name, '第一份');
    expect((await repo.itemsFor(second)).single.id, itemId);
  });
}
