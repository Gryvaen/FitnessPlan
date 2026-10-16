# 测试

这份文档讲测试怎么组织、常见的写法，以及各种运行命令和 CI 的覆盖范围。写测试之前看。

## 概览

- Dart 测试：`test/` 下 60 多个文件，全部平铺在一个目录里，没有公共的辅助文件。每个测试文件自己搭建所需的环境。
- Android 原生测试：`android/app/src/test/`，见 [android-native.md](android-native.md#原生单元测试)。
- 发版脚本测试：`tool/release/test_publish_release.py`，见 [tools.md](tools.md#test_publish_releasepy发布脚本的测试)。

## 命令

| 场景 | 命令 |
|---|---|
| 全部 Dart 测试 | `flutter test` |
| 单个文件 | `flutter test test/food_seed_sync_test.dart` |
| 单个用例 | `flutter test test/xxx_test.dart --plain-name "用例名"` |
| 排除某个 tag | `flutter test --exclude-tags=copyright` |
| 生成软著截图 | `./tool/copyright/generate_copyright_screenshots.sh` |
| 生成设计预览截图 | `./tool/docs/generate_implementation_preview.sh` |
| 发版脚本测试 | `python3 -m unittest discover -s tool/release -p 'test_*.py'` |
| 原生测试 | `cd android && JAVA_HOME=<JDK 21 路径> ./gradlew :app:testDebugUnitTest` |

## 测试分组

| 类别 | 代表文件 |
|---|---|
| 纯领域逻辑 | `calorie_calculator_test.dart`、`diet_strategy_test.dart`、`calendar_day_test.dart`、`body_metrics_test.dart`、`cultivation_progress_kcal_test.dart`、`goal_quotes_test.dart` |
| 仓库与数据库（含迁移） | `diet_strategy_repository_test.dart`、`cycle_continuity_test.dart`、`cycle_real_timeline_test.dart`、`day_marker_repository_test.dart`、`workout_repository_test.dart`、`food_repository_test.dart`、`food_seed_sync_test.dart`、`data_backup_repository_test.dart`、`step_repository_test.dart` |
| 修仙 | `cut_cultivation_test.dart`、`cultivation_cheat_day_test.dart`、`daily_experience_test.dart`、`cultivation_hero_card_test.dart` |
| 应用内更新 | `app_update_repository_test.dart`、`app_update_multi_source_test.dart`、`app_update_providers_test.dart`、`update_available_dialog_test.dart` |
| 提醒与计时器（模拟平台通道） | `reminder_permissions_test.dart`、`reminder_restrictions_widget_test.dart`、`reminder_content_widget_test.dart`、`reminder_custom_content_test.dart`、`rest_timer_page_test.dart` |
| 页面与交互 | `today_page_widget_test.dart`、`strategy_pages_widget_test.dart`、`log_meal_page_widget_test.dart`、`train_records_tab_widget_test.dart`、`swipe_tab_view_test.dart`、`folded_notes_test.dart`、`search_field_focus_test.dart` 等 |
| 图标与资源审查 | `ink_icon_assets_test.dart`（每个图标都有可解码的浅色和深色 PNG）、`home_flow_ink_icon_audit_test.dart`、`profile_tools_ink_icon_audit_test.dart`（扫描 `lib/ui` 源码，禁止使用 Material 的 `Icons.*`） |
| 多语言 | `food_category_l10n_test.dart`、`food_item_l10n_test.dart`、`append_yesterday_l10n_test.dart` |
| 截图生成（默认跳过） | `copyright_screenshots_test.dart`、`implementation_preview_test.dart` |

## 常见写法

### 数据库

```dart
final db = AppDatabase.forTesting(NativeDatabase.memory());
addTearDown(db.close);
final repo = DietStrategyRepository(db);
```

迁移测试要用临时文件，而不是内存库，写法见 [database.md](database.md#迁移测试的写法)。

### SharedPreferences

```dart
SharedPreferences.setMockInitialValues({'reminder_workout_enabled': true});
final prefs = await SharedPreferences.getInstance();
```

### Riverpod

```dart
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(db),
    ],
    child: const MaterialApp(home: SomePage()),
  ),
);
```

`sharedPreferencesProvider` 不覆盖会直接抛异常。需要让某个仓库或 notifier 失败时，可以写一个私有的假实现来覆盖（参考 `_FailingFoodRepository`、`_FakeAppUpdateRepository`）。

### 平台通道

```dart
final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
const alarm = MethodChannel('fitness_plan/rest_timer_alarm');
messenger.setMockMethodCallHandler(alarm, (call) async {
  if (call.method == 'canScheduleExactAlarms') return true;
  return null;
});
addTearDown(() => messenger.setMockMethodCallHandler(alarm, null));
```

参考 `test/rest_timer_page_test.dart`，它同时模拟了计时器、提醒、权限和通知插件四个通道。用 `variant: TargetPlatformVariant.only(TargetPlatform.android)` 让测试走 Android 分支。

### 多语言

需要中文界面时，给 `MaterialApp` 传 `locale: Locale('zh')` 和 `AppLocalizations.localizationsDelegates`。断言文案时，优先用 `AppLocalizations.of(context)` 取 key，而不是把中文字符串写死在测试里。

### 文件系统（path_provider）

参考 `test/data_backup_repository_test.dart` 里的 `_FakePathProvider`（配合 `MockPlatformInterfaceMixin` 使用）。`path_provider_platform_interface` 和 `plugin_platform_interface` 两个开发依赖就是为它准备的。

## tag 与截图测试

`dart_test.yaml` 定义了两个 tag：`copyright` 和 `implementation_preview`。两者都设置了 `skip`，所以平时的 `flutter test`（包括 CI）不会运行它们。要运行，就加上 `--run-skipped`，最好直接用上表中的两个生成脚本。

这两组测试的输出都是生成的截图，不是用来比对的基线：`docs/copyright/` 被 git 忽略，`design-handoff/` 也不在仓库里。

## CI

`.github/workflows/ci.yml`：推送到 `main` / `master`，以及每个 Pull Request 都会触发。

1. 使用 stable 频道最新版本的 Flutter（**没有固定版本号**）
2. `flutter pub get`
3. `flutter analyze --no-fatal-infos`
4. `flutter test`

**CI 不做的事**：不构建 APK，不跑原生测试和 Python 测试，不检查生成的代码是否是最新的。改了这些部分，提交前请在本地跑一遍对应的测试。
