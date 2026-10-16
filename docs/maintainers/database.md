# 数据库与种子数据

这份文档讲 Drift 数据库的结构、迁移怎么写和怎么测，以及内置食材库（种子数据）怎么更新。改表或改 `assets/food_seed.json` 之前看。

## 概览

- 文件：应用文档目录下的 `fitness_plan.sqlite`，用 `NativeDatabase.createInBackground` 在后台 isolate 打开。
- 代码：`lib/data/tables.dart`（表定义）、`lib/data/db.dart`（`AppDatabase`、迁移）、`lib/data/db.g.dart`（生成的代码，已提交）。
- **当前 `schemaVersion` = 33**（`lib/data/db.dart`）。
- 不是所有数据都在 SQLite 里：用户档案、修仙账本、提醒、主题等存在 SharedPreferences，见 [architecture.md](architecture.md#数据放在哪里)。

## 表

| 分组 | 表 | 说明 |
|---|---|---|
| 食材 | `FoodItems` | `name` 唯一；每 100 g 的营养数据；`nameEn`；`isCustom` 区分用户自建和种子数据 |
| | `FoodServings` | 食材的常用份量 |
| | `FavoriteFoods` | 收藏 |
| | `HiddenRecentFoods` | 从「最近」里隐藏的食材；记录隐藏时的 `hiddenAtEntryId`，之后再记录这个食材时会自动取消隐藏 |
| 日志 | `MealEntries` | 饮食记录；**冗余存储了 `foodName` 和营养数据**（食材改了也不影响历史） |
| | `MealPresets`、`MealPresetItems` | 套餐（同样冗余存储） |
| | `WeightLogs` | 体重、体脂、运动时长 |
| | `WaterLogs`、`StepLogs`、`DailyNotes` | 饮水、步数、每日笔记 |
| 训练 | `Exercises`、`WorkoutPlans`、`WorkoutPlanItems` | 动作库和训练计划 |
| | `DayWorkouts`、`DayWorkoutItems`、`WorkoutSetLogs` | 每日训练（一天可以有多个）和组记录 |
| 饮食策略 | `DietStrategyPlans`（行类型 `DietStrategyPlanRow`） | 策略的**不可变版本**；日期存成 `yyyy-MM-dd` 文本 |
| | `DailyNutritionTargets`（`DailyNutritionTargetRow`） | 每日目标快照，主键是 `date` 文本 |
| | `DayDietConfirmations` | 「当天饮食已记完」的确认 |
| | `DayMarkers`（`DayMarkerRow`） | 放纵日/休息日，主键是 `date` 文本 |
| 其他 | `AppMeta` | 键值对：种子版本 `food_seed_version`、一次性修复的标记等 |

表之间没有外键约束。删除种子里的食材后，旧的饮食记录仍然指向已不存在的 `foodId`，界面靠冗余的名称和营养数据照常显示；套餐则在使用时通过 `pruneMissingFoods` 清理。

## 迁移

全部写在 `db.dart` 的 `onUpgrade` 里，形式是一串 `if (from < N) { ... }`，从 v2 一直到 v33。

几条约定：
- **加列用 `_addColumnIfMissing`**。它先用 `PRAGMA table_info` 检查列是否已经存在，这样中途中断的升级可以安全地重跑，同一次升级里前面刚建好的表也不会因为重复加列而出错。
- 日期索引由 `_createDateIndices()` 统一创建，可以重复执行，`onCreate` 和 v24 升级都会调用它。
- 数据修复类的迁移，要用 `AppMeta` 里的标记保证只执行一次（参考 v33 的 `cycle_alignment_v33_repaired`）。
- 有些历史列已经废弃但没有删除：`carb_amplitude_g`（v23 起不再使用）、`exclude_contributions`（v31 起由 `include_steps` / `include_diet` 代替）。新代码不要再读写它们。

值得了解的几次迁移：

| 版本 | 内容 |
|---|---|
| v13 | 删除内置动作。`seedBuiltinExercises()` 现在是空函数 |
| v15 | 重建 `day_workouts`，去掉 `UNIQUE(date)`，从此一天可以有多个训练 |
| v23 | 碳循环改为「每公斤体重的倍数」模型；旧的碳循环计划不迁移 |
| v31 | 由旧的 `exclude_contributions` 推导出 `include_steps` 和 `include_diet` |
| v33 | 执行 `repairLegacyCycleAlignment()`（`lib/data/cycle_alignment_migration.dart`）：根据历史快照推断碳循环的位置；必要时以一个新的策略版本取代今天的计划 |

### 改表的完整步骤

1. 改 `lib/data/tables.dart`。
2. 在 `db.dart` 里把 `schemaVersion` 加 1，并在 `onUpgrade` 末尾追加 `if (from < 新版本) { ... }`。新表用 `m.createTable(...)`，新列用 `_addColumnIfMissing(...)`。
3. 重新生成代码：
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. 写一个升级测试，验证旧库升级后数据正确（写法见下）。
5. `flutter analyze && flutter test`，把 `db.g.dart` 一起提交。

另外两点：
- 导入备份时会整库替换，打开旧版本的备份时同样走 `onUpgrade`。目前**没有拦截比当前 schema 更新的备份**，见 [known-issues.md](known-issues.md)。
- 仓库没有使用 Drift 的 schema 快照（`drift_schemas/`），迁移只靠下面这种手写测试来验证。

### 迁移测试的写法

参考 `test/cycle_continuity_test.dart` 和 `test/cycle_real_timeline_test.dart`。思路是：先建一个当前版本的库文件，再把它改回旧结构、把版本号降回去，然后用 `AppDatabase` 重新打开，触发升级：

```dart
final seed = AppDatabase.forTesting(NativeDatabase(file));
// ……用当前版本的仓库写入测试数据……
await seed.close();

final old = NativeDatabase(file);
await old.ensureOpen(_V31User());          // 一个 schemaVersion 为 31 的 QueryExecutorUser
await old.runCustom('ALTER TABLE diet_strategy_plans DROP COLUMN cycle_start_index');
await old.runCustom('PRAGMA user_version = 31');
await old.close();

final upgraded = AppDatabase.forTesting(NativeDatabase(file));   // 这里会执行 onUpgrade
// ……断言升级后的数据……
```

普通的仓库测试直接用内存库：`AppDatabase.forTesting(NativeDatabase.memory())`。

## 食材种子数据

### 数据如何进入应用

- 文件：`assets/food_seed.json`，目前 668 条，18 个分类。
- 版本号：`lib/data/repositories/food_repository.dart` 里的 `kFoodSeedVersion`，**当前为 14**。
- 同步逻辑在 `FoodRepository.syncSeedFromAsset()`，由启动时的 `foodsSeedProvider` 触发：
  1. 如果 `AppMeta.food_seed_version` 已经大于等于 `kFoodSeedVersion`，直接跳过；
  2. 在 isolate 里解析 JSON；
  3. 按 `name` 批量 upsert，并强制 `isCustom = false`；
  4. 删除种子里已经没有的非自定义食材，连同它们的收藏、份量、隐藏记录（在一个事务里完成）；
  5. 写入新的版本号。

### 字段

```json
{
  "name": "猪肉(瘦)", "category": "畜肉",
  "kcal": 143, "protein": 20.2, "carb": 1.5, "fat": 6.2, "alcohol": 0,
  "fiber": 0, "sodium_mg": 57, "sugar": 0, "saturated_fat": 2.2, "calcium_mg": 6,
  "name_en": "Pork (Lean)"
}
```

营养数据都按每 100 g 计。`sodium` 和 `calcium` 也可以不带 `_mg` 后缀。`test/food_seed_sync_test.dart` 会检查种子文件，例如每条都要有非空的、只含拉丁字母的 `name_en`。

### 修改种子数据的步骤

1. 直接编辑 `assets/food_seed.json`。目前的种子已经是**手工维护**的：后来补充的做法变体（清炒、白灼、烟熏等）、英文名和微量营养素，都是手工加进去的。
2. 把 `kFoodSeedVersion` 加 1。不加的话，已安装的用户不会同步到新数据。
3. 跑 `flutter test test/food_seed_sync_test.dart test/food_repository_test.dart`。
4. 如果改了条目数，顺手更新 README 里的食材数量。

`tool/food_seed/build_food_seed.py` 是最初生成种子用的脚本，现在已经和种子文件的格式对不上，**不要直接用它覆盖** `assets/food_seed.json`，原因见 [tools.md](tools.md#toolfood_seed) 和 [known-issues.md](known-issues.md)。

### 风险

同步按名称 upsert。如果新版种子里加了一个和用户自建食材同名的条目，那条自定义食材会被覆盖，并被改成非自定义（`isCustom = false`）。新增种子条目前，最好先查一下这个名字会不会和常见的自建名称冲突。
