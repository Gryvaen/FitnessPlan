# 已知问题与待办

这份文档汇总在整理维护者文档时（2026-10-16）发现的问题，这些问题都还没有修。想找活干、或者遇到怪现象时看。修好一条，就把它从这里删掉。

优先级：**高** = 会导致数据丢失或无法发版；**中** = 用户能感知到的缺陷；**低** = 代码质量或文档问题。

## 发版与构建

| 优先级 | 问题 | 影响 | 建议 |
|---|---|---|---|
| 高 | 发布用的签名是维护机的 `~/.android/debug.keystore` | 这个文件丢失、或换一台机器构建，新包就无法覆盖安装；debug 密钥的安全性也很弱 | 立即离线备份这个 keystore。更换签名密钥需要用户卸载重装，只能结合「先导出备份」的引导一起做 |
| 中 | CI 没有固定 Flutter 版本（只写了 `channel: stable`） | Flutter 新版本发布后，CI 可能突然失败，而且和本地结果不一致 | 在 `ci.yml` 里固定 `flutter-version`，和本地开发环境保持一致 |
| 中 | CI 不跑原生测试、不跑发版脚本的 Python 测试，也不检查生成的代码是否最新 | 这几部分的回归只能靠本地发现 | 在 CI 里加上 `python3 -m unittest`；可选加上 Gradle 单元测试，以及 `build_runner` / `gen-l10n` 之后 `git diff --exit-code` 的检查 |
| 低 | 软著 Word 版脚本读取的 `docs/display/*.jpg` 目录不存在 | 生成的文档里出现「图片缺失」占位 | 改为读取 `design/display/*.png`，或者改用 golden 截图 |
| 低 | `design-handoff/` 不在仓库里，也没有被 git 忽略 | 运行 `tool/docs/generate_implementation_preview.sh` 后会多出一堆未跟踪文件 | 在 `.gitignore` 里加上 `/design-handoff/` |
| 低 | 软著脚本的 Python 依赖没有 requirements 文件 | 换机器后要自己猜该装哪些包 | 加 `tool/copyright/requirements.txt` |

## 数据

| 优先级 | 问题 | 影响 | 建议 |
|---|---|---|---|
| 中 | 导入备份时没有检查备份数据库的版本（`user_version`）是否比当前的 33 更新 | 导入更新版本应用导出的备份时，迁移一步都不会执行，可能缺列或数据错乱 | 导入前读取备份里的 `user_version`，比当前版本新就拒绝导入，并提示用户先升级应用 |
| 中 | 备份会把 prefs 原样恢复，包括另一台设备的下载会话（`app_update_pending_download_id` 等） | 导入后，应用可能去查询一个本机并不存在的下载任务 | 导入时跳过 `app_update_*` 这类设备相关的键 |
| 中 | 「清空数据」没有清掉步数、自定义食材及其份量、提醒、主题、语言、计算器历史、饮水目标 | 用户以为清空了，其实还留有数据 | 补全 `profile_page.dart` 里的 `_doClearData` |
| 中 | 种子同步按名称 upsert | 新种子里如果出现和用户自建食材同名的条目，会覆盖那条自定义食材 | 同步时跳过 `isCustom = true` 的同名行，或者给种子条目改名 |
| 低 | 导入日步数下限的修复（`steps_imported_on_day`）没有测试 | 以后改步数同步时容易被无意中改坏 | 在 `test/` 里补一个 `StepsSyncService` 的测试 |
| 低 | `tool/food_seed/build_food_seed.py` 依赖的 `data2026.csv` 已经删除，而且它的输出缺少 `name_en` 等字段 | 管线已经无法直接复现现在的种子文件 | 要么更新脚本，让它保留手工字段；要么在脚本开头注明它已废弃 |

## Android 原生

| 优先级 | 问题 | 影响 | 建议 |
|---|---|---|---|
| 中 | `res/values-zh/strings.xml` 缺少 `workout_reminder_channel`、`workout_reminder_channel_description`、`workout_reminder_default_title`、`workout_reminder_default_body` | 中文系统上，提醒的降级通知和默认文案显示成英文 | 补上这 4 个中文字符串 |
| 低 | 午夜计步接收器（`StepCounterBridge.kt` 里的 `StepCounterMidnightReceiver`）不响应 `TIME_SET` 和 `TIMEZONE_CHANGED` | 改时间或跨时区之后，午夜快照的时间可能不对，直到下一次开机 | 和 `ReminderBootReceiver` 一样，加上这两个 action |
| 低 | `workout_reminder` 通道的 `manufacturer` 方法没有任何调用方 | 死代码 | 删除，或者真正用起来 |
| 低 | `WorkoutReminderScheduler` 的注释说每类提醒有「100 个槽位」，实际只取消 32 个，Dart 侧只用 7 个 | 注释误导读者 | 修正注释 |
| — | ColorOS 冻结后台应用并扣住闹钟 | 系统行为，应用无法绕过，只能引导用户手动设置 | 已经做了引导和延迟检测，见 [android-native.md](android-native.md#coloros-的后台冻结) |

## 代码结构

| 优先级 | 问题 | 建议 |
|---|---|---|
| 低 | 分层违规：`theme_repository.dart` 引用了 `ui/theme`；`workout_repository.dart` 和 `form_memory_repository.dart` 引用了 `l10n`；`theme_providers.dart`、`workout_reminder_providers.dart` 引用了 `ui` | 把 `AppThemeId`、`kExerciseCategoryOrder` 下沉到 domain，把两个通知封装移到 `data/services` |
| 低 | 平台通知代码放在 `lib/ui/tools/`（`rest_timer_notifications.dart`、`workout_reminder_notifications.dart`） | 同上，移到 `data/services` |
| 低 | `DietStrategyRepository` 直接 `new` 了一个 `DayMarkerRepository`，没有通过 provider 注入 | 改为通过构造函数注入 |
| 低 | 死代码：`lib/features/loading/`（旧启动动画）、`ink_icon.dart` 里的 `_InkIconPainter`（约 600 行）、`seedBuiltinExercises()`、只有测试在用的 `cultivationKgLostFromLogs` 和 `kCheatMealCultivationPenaltyKcal` | 删除，同时删除对应的测试 |
| 低 | 已废弃的列 `carb_amplitude_g`、`exclude_contributions` 仍在表定义里 | 可以在某次迁移里删除；新代码不要再读写它们 |
| 低 | 约 56 处仓库层的错误信息硬编码为中文（如 `'只能编辑今天的记录'`），更新下载的进度文字也没有本地化 | 英文界面下会直接显示中文。可以改成错误码，在 UI 层再翻译 |
| 低 | GitHub API 请求的 User-Agent 固定为 `FitnessPlan/0.0.0`（`AppUpdateRepository` 的 provider 没有传入版本号） | 传入 `package_info_plus` 拿到的版本号 |

## 过时的注释与文档

- 主题相关的注释还写着「四个主题」「清新绿」「主题页」，实际只有两套主题，在「我的」页顶部切换。
- `tables.dart` 里 `Exercises.category` 的注释列出的是 v12 之前的分类 key。
- `ink_icon.dart` 的文档注释说「不需要维护位图资源」，实际用的就是位图。
- `diet_strategy.dart` 开头引用了 `design-handoff/fat-loss-strategy.md`，这个文件不在仓库里，而且碳循环的实现已经和它不一样了。
