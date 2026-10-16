# 代码地图

这份文档逐个文件说明 `lib/` 和 Android 原生代码各自负责什么，找代码时查。分层原则见 [architecture.md](architecture.md)。生成的文件（`*.g.dart`、`app_localizations_*.dart`）只在相应位置提一句。

## lib/ 根目录

| 文件 | 作用 |
|---|---|
| `main.dart` | 入口：读取 prefs、初始化通知、`ProviderScope`、启动动画与 `FitnessApp` 的叠放（见 [architecture.md](architecture.md#启动流程)） |
| `app.dart` | `routerProvider`（全部路由）和 `FitnessApp`（`MaterialApp.router`、主题、语言、启动后的提醒同步） |

## lib/data

| 文件 | 作用 |
|---|---|
| `db.dart` | `AppDatabase`：数据库文件位置、`schemaVersion`、全部迁移步骤（`onUpgrade`）、日期索引 |
| `tables.dart` | 22 张 Drift 表的定义 |
| `db.g.dart` | Drift 生成的代码，不要手改，用 build_runner 重新生成 |
| `cycle_alignment_migration.dart` | v33 迁移时执行一次的数据修复：根据历史快照推断碳循环位置 |

### lib/data/repositories

| 文件 | 作用 |
|---|---|
| `app_update_repository.dart` | 从 GitHub/Gitee 拉取发布列表、校验更新清单、按 ABI 选择安装包、给下载源测速排序、调用原生 DownloadManager；`AppUpdateLogic` 是其中可单独测试的纯逻辑 |
| `calculator_history_repository.dart` | 计算器历史（prefs，最多 50 条） |
| `cultivation_repository.dart` | 修仙账本 `CutCultivationState`（prefs）：冻结、开启、确保存在一个进行中的分段 |
| `data_backup_repository.dart` | 备份导出（数据库 + prefs，gzip 压缩的 JSON）与导入；记录导入日，供步数同步使用 |
| `day_marker_repository.dart` | 放纵日/休息日标记及其设置；给碳循环提供暂停日期 |
| `diet_strategy_repository.dart` | 饮食策略的不可变版本、每日目标快照、手动覆盖、当日饮食完成确认；`targetForDay` 是每日目标的唯一来源 |
| `food_repository.dart` | 种子同步、搜索（拆分做法词、同义词）、分类、最近使用与隐藏、自定义食材、份量、收藏 |
| `form_memory_repository.dart` | 记住表单上次填写的值（餐次、克数、体脂、运动时长等） |
| `meal_preset_repository.dart` | 常用组合（套餐）：增删改、由已有记录生成、应用到某天、清理已不存在的食材 |
| `meal_repository.dart` | 饮食记录：增删改、在餐次间移动、复制某天、摄入汇总、历史 |
| `note_repository.dart` | 每日笔记（一天一条） |
| `profile_repository.dart` | 用户档案（prefs 里的 JSON）；保存时调用 `CalorieCalculator` 重新计算目标 |
| `reminders_repository.dart` | 四类提醒（训练、喝水、饮食、称重）的设置，存在 prefs 的 `reminder_<种类>_<字段>` 下；兼容旧的 `workout_reminder_*` 键 |
| `step_repository.dart` | 每日步数（`StepLogs` 表） |
| `theme_repository.dart` | 当前主题 id（prefs 的 `app_theme_id`） |
| `water_repository.dart` | 饮水量（只能记今天）和饮水目标（默认 2000 ml） |
| `weight_repository.dart` | 体重、体脂、运动时长记录 |
| `workout_repository.dart` | 训练相关的全部数据：动作库、训练计划、每日训练（一天可以有多个）、组记录、完成状态（约 1700 行） |

### lib/data/services

| 文件 | 作用 |
|---|---|
| `android_step_sensor.dart` | 封装 `fitness_plan/step_counter` 通道：读取原生计步传感器、后台计步服务开关、打开 Health Connect 设置 |
| `steps_sync_service.dart` | 合并 Health Connect/HealthKit 和传感器的步数并写入数据库；防止同时重复同步；导入备份当天以已存步数为下限 |

## lib/domain

全部是纯 Dart，可以直接写单元测试。

| 文件 | 作用 |
|---|---|
| `body_metrics.dart` | BMI、体脂、FFMI 及其分级（工具箱用） |
| `calculator_engine.dart` | 计算器页面背后的状态机 |
| `calendar_day.dart` | 本地日期处理（`dayOnly`、`todayLocal`）；`ensureEditableDay` 在编辑非今天的数据时抛异常 |
| `calorie_calculator.dart` | BMR（Mifflin-St Jeor）→ TDEE → 目标热量 → 三大营养素；平台期修正 |
| `cultivation.dart` | 修仙境界：7700 kcal ≈ 1 kg 道行，五个境界各九层；步数折算热量（每步 0.04 kcal） |
| `cut_cultivation.dart` | 修仙账本的数据结构：已冻结热量加上若干「减脂分段」 |
| `cycle_history.dart` | `resolveCycleDay`：碳循环「今天是第几天」的唯一解析器；`inferCycleHistory`（v33 修复用） |
| `day_marker.dart` | 放纵日/休息日类型与设置；判断休息日是否暂停循环 |
| `deficit.dart` | 实际热量缺口、饮食对修仙的贡献（TDEE − 摄入） |
| `diet_plan.dart` | 饮食策略版本 `DietStrategyPlan`、每日目标 `DailyNutritionTarget`、目标来源 |
| `diet_strategy.dart` | 策略规则与计划器：均衡、碳循环、碳水递减；`StrategyRules` 里集中了所有数值规则 |
| `energy_units.dart` | kcal ↔ kJ |
| `goal_quotes.dart` | 每个目标 100 条中英文激励语，按日期轮换 |
| `models.dart` | 基础枚举和值类型：性别、活动水平、目标、餐次、`UserProfile`、`MacroTargets` |
| `plateau.dart` | 平台期检测（最近 7 次体重变化小于 0.3 kg） |
| `strategy_eligibility.dart` | 能否使用自助饮食策略（档案有效、已成年、目标为减脂） |

## lib/providers

UI 统一 import `app_providers.dart`（汇总导出）。

| 文件 | 主要 provider |
|---|---|
| `core_providers.dart` | `sharedPreferencesProvider`（必须在 `main` 里覆盖）、`databaseProvider`、各仓库的 provider |
| `profile_providers.dart` | `profileProvider`：保存档案时统一处理切换目标的连带操作（结算修仙热量、停止策略、开启或冻结修仙分段） |
| `diet_strategy_providers.dart` | `dietStrategyActionsProvider`（应用/取消计划）、`activeDietPlanProvider`、`dailyTargetProvider`（按天的 family，每日目标的唯一出口）、`todayTargetProvider`、`selectedDayTargetProvider` |
| `strategy_review_providers.dart` | 体重变化 ≥ 3% 或档案与计划不一致时，提示重新评估策略 |
| `cultivation_providers.dart` | 修仙进度、今日热量贡献、历史分段 |
| `day_marker_providers.dart` | 某天的标记、标记设置、休息日列表 |
| `meal_providers.dart` | `selectedDayProvider`（今日页当前选中的日期）、当天饮食与摄入、饮水、套餐、饮食历史 |
| `food_providers.dart` | `foodsSeedProvider`（种子同步）、收藏、食材目录变化、按 id 查询食材 |
| `step_providers.dart` | 步数同步服务、同步状态、后台计步开关（首次运行自动开启）、当天与历史步数 |
| `workout_providers.dart` | 动作库、训练计划、当天训练、训练历史 |
| `workout_reminder_providers.dart` | `remindersProvider`：保存提醒设置，并尽力重新排期 |
| `app_update_providers.dart` | `appUpdateProvider`：检查更新、下载、切换下载源、安装 |
| `note_providers.dart` / `weight_providers.dart` / `theme_providers.dart` / `locale_providers.dart` | 笔记、体重记录、主题、语言 |
| `app_providers.dart` | 汇总导出 |

## lib/ui

### shell — 外框

| 文件 | 作用 |
|---|---|
| `main_shell.dart` | 底部悬浮导航（四个 ink 图标）；回到前台时同步步数并静默检查更新 |
| `swipe_tab_view.dart` | 页内的标签切换器，滑到边缘时把手势交给外层 |
| `swipeable_branch_container.dart` | 用 `PageView` 承载四个标签页 |

### today — 今日

| 文件 | 作用 |
|---|---|
| `today_page.dart` | 今日页：热量环、三大营养素、饮水、步数、各餐摘要、平台期提示、激励语、日期切换；也包含步数详情弹窗 |
| `today_summary_widgets.dart` | `CalorieRing`、`MacroColumn`、`WaterCupControl` |
| `today_workout_card.dart` | 当天训练清单和记组 |
| `deficit_date_picker.dart` | 月历，显示每天的实际热量缺口；长按标记放纵日/休息日 |
| `today_section_header.dart` | 分区标题 |

### foods — 食材

| 文件 | 作用 |
|---|---|
| `foods_page.dart` | 食材主页：搜索、最近与收藏、分类、历史标签 |
| `food_detail_page.dart` | 食材详情，可以从这里直接记录 |
| `custom_food_edit_page.dart` | 新建/编辑自定义食材 |
| `food_category_page.dart` | 某个分类下的食材列表 |
| `food_collection_page.dart` | 收藏或套餐列表 |
| `food_history_tab.dart` | 饮食历史 |
| `food_category_art.dart` | 分类头像 `FoodCategoryAvatar` |

### meals — 记录饮食

| 文件 | 作用 |
|---|---|
| `log_meal_page.dart` | 「记一笔」：搜索食材并填写克数 |
| `daily_meals_page.dart` | 某天的全部饮食（以底部弹层呈现）；历史日期只读 |
| `meal_detail_page.dart` | 单条饮食记录的详情与编辑 |
| `meal_preset_detail_page.dart` / `preset_food_add_page.dart` | 套餐详情、往套餐里加食材 |

### records — 记录

| 文件 | 作用 |
|---|---|
| `records_page.dart` | 三个分段：身体、训练、笔记 |
| `body_records_tab.dart` | 体重和体脂图表（7 天 / 30 天 / 全部） |
| `train_records_tab.dart` | 训练：计划、动作库、历史 |
| `plan_edit_page.dart`、`exercise_picker.dart`、`exercise_form_dialog.dart`、`log_set_sheet.dart` | 编辑训练计划、选择动作、编辑动作、记一组 |
| `notes_records_tab.dart`、`note_edit_page.dart` | 笔记列表与编辑 |

### profile — 我的

| 文件 | 作用 |
|---|---|
| `profile_page.dart` | 档案摘要、主题与语言切换、检查更新、清空/导出/导入数据、修仙卡片 |
| `profile_edit_page.dart` | 编辑档案（身高、体重、目标等） |
| `cultivation_page.dart` | 修仙主页和目标页 |
| `cultivation_goal_picker_page.dart` | 三卷轴目标选择 |
| `cultivation_history_page.dart` | 修仙历史 |
| `realm_guide_page.dart` | 境界说明 |
| `cultivation_labels.dart` | 境界文案、颜色、配图路径 |
| `update_available_dialog.dart` | 新版本弹窗（更新说明、下载源选择） |

### strategy — 营养目标与饮食策略

| 文件 | 作用 |
|---|---|
| `nutrition_targets_page.dart` | 营养目标页；只有「减脂」完整实现，增肌和维持是占位 |
| `strategy_picker_page.dart` / `strategy_configure_page.dart` | 选择策略、配置参数（每次保存都生成一个新版本） |
| `taper_review_page.dart` | 碳水递减的阶段复盘 |
| `carb_cycle_view.dart` | 碳循环的周期表 |
| `strategy_fold_section.dart` | 可折叠的分区组件（也被更新弹窗复用） |
| `strategy_labels.dart` | 策略相关的文案扩展 |

### tools — 工具箱、提醒、计时器

| 文件 | 作用 |
|---|---|
| `tools_hub_page.dart` | 工具箱入口 |
| `body_fat_page.dart`、`body_metrics_page.dart`、`calculator_page.dart`、`energy_unit_convert_page.dart`、`food_convert_page.dart` | 各个小工具 |
| `rest_timer_page.dart` | 休息计时器 |
| `rest_timer_notifications.dart` | 计时器的平台封装（Android 走 `fitness_plan/rest_timer_alarm` 原生通道，其他平台走 flutter_local_notifications） |
| `reminders_hub_page.dart` | 提醒中心：四类提醒的设置和权限状态 |
| `workout_reminder_notifications.dart` | 提醒的平台封装（`fitness_plan/workout_reminder` 通道）；也负责厂商后台设置的检测和跳转 |
| `reminder_status_labels.dart` | 提醒与权限相关的文案（内联中英文的旧写法） |
| `restriction_issue_row.dart` | 权限问题行组件（标题、可折叠说明、操作按钮），提醒中心和计时器共用 |

### 其他

| 目录 / 文件 | 作用 |
|---|---|
| `onboarding/onboarding_page.dart` | 首次建档向导 |
| `loading/discipline_freedom_loading_page.dart` | 启动动画（当前使用的） |
| `loading/loading_lab_page.dart` | 启动动画调试页（`LOADING_LAB=true`） |
| `theme/app_theme.dart` | 主题、颜色、间距、圆角、`AppThemeVisuals` |
| `theme/sport_chrome.dart` | 通用页面外框和组件 |
| `theme/macro_color.dart` | 根据主要营养素选颜色 |
| `ink/ink_icon.dart` | ink 图标体系（`InkGlyph`、`InkIcon` 等）；文件里的 `_InkIconPainter` 是没有用到的旧代码 |
| `ink/ink_icon_gallery.dart` | 图标总览页，仅测试使用 |
| `widgets/calorie_breakdown.dart` | 热量构成的展示组件 |
| `widgets/folded_notes.dart` | 默认折叠的说明组 `FoldedNotes` |
| `widgets/food_name_link.dart` | 可点击的食材名，以及 `foodDetailLocation()` |
| `widgets/form_options.dart` | 表单下拉/滚轮选择器、重量单位 |
| `widgets/search_field_focus.dart` | 搜索框的焦点控制：防止返回时键盘自动弹出、收起键盘后失去焦点 |

## lib/l10n

| 文件 | 作用 |
|---|---|
| `app_en.arb` / `app_zh.arb` | 文案源文件（英文是模板），各约 1000 个 key |
| `app_localizations.dart`、`app_localizations_en.dart`、`app_localizations_zh.dart` | 生成的代码，用 `flutter gen-l10n` 重新生成 |
| `app_localizations_ext.dart` | 手写：`context.l10n`、枚举文案、日期格式 `AppDates`、食材和动作分类的翻译、`kExerciseCategoryOrder` |

## lib/features/loading

旧的剑客启动动画（`swordsman_*.dart`、`ink_particle_painter.dart`、`loading_config.dart`）。应用里已经不再引用，只剩 `test/swordsman_loading_test.dart` 在用。

## Android 原生代码

目录：`android/app/src/main/kotlin/com/fitnessplan/fitness_plan/`。详细设计见 [android-native.md](android-native.md)。

| 文件 | 作用 |
|---|---|
| `MainActivity.kt` | 注册 4 个 MethodChannel；处理铃声选择的返回结果；每次启动时按需重启后台计步服务 |
| `RestTimerAlarmScheduler.kt` | 休息计时器：`setAlarmClock` 排期、通知栏倒计时、记录闹钟延迟 |
| `RestTimerAlarmReceiver.kt` | 闹钟到点后启动响铃服务，失败时发降级通知 |
| `RestTimerAlarmService.kt` | 前台服务：循环振动和播放铃声 |
| `RestTimerAlarmStopReceiver.kt` | 通知上的「关闭」按钮 |
| `RestTimerFallbackNotification.kt` | 前台服务起不来时的降级通知（由通知渠道自带声音和振动） |
| `WorkoutReminderScheduler.kt` | 四类每日提醒的排期；每次触发后自动排下一周；开机后恢复 |
| `WorkoutReminderReceiver.kt` | 提醒到点：先排下一次，再启动响铃服务或发普通通知 |
| `ReminderAlarmService.kt` | 提醒的响铃前台服务（10 分钟后自动停止） |
| `ReminderAlarmActivity.kt` | 锁屏上的闹钟页面（提醒和计时器共用） |
| `ReminderBootReceiver.kt` | 开机、应用更新、改时间、改时区、精确闹钟权限变化后，恢复提醒排期 |
| `DeviceReliability.kt` | 识别会限制后台的厂商、跳转到对应的设置页（含 ColorOS 的特殊处理） |
| `StepCounterBridge.kt` | 把传感器的累计步数换算成每天的步数；午夜快照；也包含 `StepCounterMidnightReceiver` |
| `StepCounterService.kt` | 可选的后台计步前台服务 |
| `ApkDownloader.kt` | 通过系统 DownloadManager 下载更新包 |
| `ApkDownloadCompleteReceiver.kt` | 下载完成后校验并发出「安装」通知 |
| `ApkIntegrity.kt` | 校验文件大小和 SHA-256（有单元测试） |
