# 业务模块与不变量

这份文档讲各个业务模块的规则，以及代码里必须守住的不变量。改业务逻辑之前看。文中的数值都以代码为准；如果和代码不一致，以代码为准并修正本文。

## 必须守住的不变量

这些规则大多有测试守着，违反了会让测试失败；但也有一些只能靠人记住。

1. **只能编辑今天的记录。** 饮食、体重、饮水、笔记、训练这些仓库在写入前都会调用 `CalendarDay.ensureEditableDay`，对其他日期直接抛 `StateError('只能编辑今天的记录')`。历史日期在界面上是只读的。手动覆盖饮食目标同样只能针对今天。
2. **饮食策略计划是不可变的版本。** 不要原地修改计划。`createPlan` 会生成一个新版本并取代当前生效的版本，`effectiveFrom` 不能早于今天。停止一个还没开始生效的计划时，会恢复被它取代的那个版本。
3. **每日目标快照只写今天。** `targetForDay` 会把今天的目标存成 `DailyNutritionTarget` 快照；过去的快照永远不改，未来的日期永远不存。过去某天如果没有快照，就按当时生效的计划或档案实时算出来。手动覆盖的目标在重新计算时会保留。
4. **快照判等要完整。** `_upsertSnapshot` 在值没变时跳过写入，这样 `watchTargetForDay` 才不会因为自己写表而被反复触发、陷入循环。给快照新增字段时，**一定要同时更新 `_sameTarget` 的比较**。
5. **碳循环按天数计算，不按星期几。** 「今天是循环的第几天」只能通过 `resolveCycleDay`（`lib/domain/cycle_history.dart`）计算，依据是历史快照里的锚点和暂停日。不要另写一套推算。
6. **日期标记的 `updatedAt` 不能在编辑时更新。** 标记只有在当天或之前做出，才会暂停循环（`restDayCountsTowardProgression`），判断依据就是这个时间戳。`DayMarkerRepository` 编辑标记或切换类型时都保留原来的 `updatedAt`。
7. **减脂目标本身没有热量缺口。** `CalorieCalculator` 对减脂目标给出的就是 TDEE（和维持一样），缺口只来自生效中的饮食策略。离开减脂目标时会自动停止策略，并冻结修仙进度。
8. **修仙进度按热量计算，不按体重。** 见下文「修仙境界」。
9. **路由刷新只看档案从无到有、从有到无。** 见 [architecture.md](architecture.md#路由)。
10. **`todayMealsProvider` 和 `todayIntakeProvider` 跟随的是选中的日期**，不一定是今天。

## 档案与热量计算

- 档案存在 prefs 的 `user_profile`（JSON），由 `ProfileRepository` 读写。
- `CalorieCalculator`（`lib/domain/calorie_calculator.dart`）：先用 Mifflin-St Jeor 公式算 BMR，乘以活动系数得到 TDEE，再按目标给出摄入：维持 = TDEE，减脂 = TDEE（缺口由策略提供），增肌 = TDEE × 1.1；最后分配三大营养素。
- 平台期修正：`calorieAdjustment` 最多 300 kcal。
- 平台期检测（`lib/domain/plateau.dart`）：最近 7 次体重记录的变化不超过 0.3 kg，就判定为平台期，在今日页给出提示。
- **「新标准」标记**：`UserProfile.calorieStandardSince`。只有策略发生结构性变化（`isStructuralChange`）或切换目标时才会重新打这个标记；碳循环只调整排期（周期长度、高/中/低顺序）不算结构性变化。在此之前的日期显示为「旧标准估算」。

## 饮食策略

代码：`lib/domain/diet_strategy.dart`（规则和计划器，纯 Dart）、`lib/domain/diet_plan.dart`（版本和每日目标）、`lib/data/repositories/diet_strategy_repository.dart`（持久化）、`lib/providers/diet_strategy_providers.dart`、`lib/ui/strategy/`。

- 只对**成年人且目标为减脂**开放（`strategy_eligibility.dart`）。
- 三种策略（`DietStrategyKind`）：
  - `balanced`：均衡，每天相同；
  - `carbCycle`：碳循环，高/中/低碳日按周期轮换；
  - `carbTaper`：碳水递减，按阶段逐步降低碳水。
- 数值规则都集中在 `StrategyRules`：

| 规则 | 值 |
|---|---|
| 热量缺口 | TDEE 的 10%–20%，默认 15% |
| 蛋白质 / 脂肪 | 默认 2.0 g/kg / 0.8 g/kg |
| 碳水下限 | 130 g |
| 低能量提醒 | 低于 1200 kcal |
| 碳循环周期 | 3 / 4 / 5 天，默认 4 天 |
| 碳水递减 | 每档 25 g 碳水（100 kcal），观察期 14 天 |

- **每日目标的唯一出口**是 `dailyTargetProvider`（按天的 family），背后是 `DietStrategyRepository.targetForDay`，来源（`TargetSource`）可能是策略、档案或手动覆盖。
- 策略配置页每次保存都会生成一个新版本；只有结构性变化才会重新打「新标准」标记（见上文）。
- 体重变化达到 3%，或档案和计划不一致时，会提示重新评估策略（`strategy_review_providers.dart`）。

### 碳循环

- 循环是一个由 H/M/L 组成、长度 3–5 天的序列（`CarbCycleSchedule`），**按天数推进，和星期几无关**。
- 修改计划后，循环会**接着已执行的天数继续**，不会回到第一天：新版本记录 `cycle_start_index`，每天的快照记录当天的 `cycle_index` 和是否暂停（`cycle_paused`）。
- 标记暂停：放纵日、休息日、冲碳日都可以打开「碳循环顺延一天」。打开后，只要标记在当天或之前做出，循环就暂停一天，预览里该行按标记类型显示。暂停开关只影响今天及以后，过去的日期已锁定。
- 冲碳日：当天目标用高碳日的蛋白和脂肪，碳水按标记里设定的 g/kg 计算，范围从计划的高碳日实际值（扣除中碳日补偿后）到 7.0（`CarbCyclePlan.carbLoadDay`）。目标的 `reason` 写成 `carbLoad:<g/kg>`，`dayType` 记为高碳日。多出的热量不在其他日子补回。
- v33 迁移会为老用户推断历史的循环位置，见 [database.md](database.md#迁移)。

## 日期标记（放纵日 / 休息日 / 冲碳日）

- `lib/domain/day_marker.dart`、`lib/data/repositories/day_marker_repository.dart`。在今日页的月历上长按日期即可标记。
- 每个标记日可以分别设置：步数是否计入修行、饮食热量是否计入修行。放纵日计入饮食时，按 TDEE − 摄入计算；不计入时，可以设置一个固定扣减值（也可以不扣）。
- 三种标记都可以暂停碳循环，规则见上文。冲碳日只能在碳循环计划下、给今天及以后的日期标记；它有真实目标，所以月历上照常判绿/红，放纵日和休息日则不判定。
- 一天只能有一个标记（`day_markers` 以 `date` 为主键），三种类型互斥。

## 修仙境界

代码：`lib/domain/cultivation.dart`、`lib/domain/cut_cultivation.dart`、`lib/data/repositories/cultivation_repository.dart`、`lib/providers/cultivation_providers.dart`、`lib/ui/profile/cultivation_*`。

- **7700 kcal ≈ 1 kg 道行。** 境界：练气 0–3 kg、筑基 3–10、结丹 10–20、元婴 20–40、化神 40+，每个境界九层。
- 每天的热量贡献 = 步数 × 0.04 + 饮食贡献（TDEE − 摄入）+ 日期标记的调整。
  - 饮食贡献：当天至少记录了**两类餐次**才计入，否则记为 0。
  - 步数：只有步数同步状态是 `connected` 时才计入，否则记为 0。
- 进度存在 prefs 的账本里（`cut_cultivation_state`）：已冻结的热量，加上若干「减脂分段」（最多一个进行中）。切换离开减脂目标时，当前分段的热量会被结算并冻结；回到减脂时开启新分段。所以进度不会因为切换目标而丢失。
- 增肌和维持目标的境界玩法还没有做，只有入口。
- `cultivationKgLostFromLogs`（按体重计算）和 `kCheatMealCultivationPenaltyKcal` 只有测试在用，实际的放纵日扣减取自标记设置。

## 步数

代码：`lib/data/services/steps_sync_service.dart`、`lib/data/services/android_step_sensor.dart`、`lib/providers/step_providers.dart`，原生部分见 [android-native.md](android-native.md)。

- 来源：Health Connect（Android）或 HealthKit（iOS），通过 health 插件读取；Android 上再读一份原生计步传感器的数据，**当天取两者中较大的值**。
- 同步时机：启动、回到前台（`MainShell`），同步最近 14 天。
- 「今天」以实时读数为准，**包括 0**：以前保留数据库里的旧值，会让午夜之后的今天看起来像昨天。
- **例外**：导入备份的当天（prefs 的 `steps_imported_on_day`），以数据库里恢复出来的步数为下限，因为那些步数是在另一台设备上计的，本机传感器从来没有数到。
- 状态 `StepsSyncStatus`：`connected`（成功，读到的数大于 0）、`empty`（成功但今天读到 0，界面显示「0 步」）、`denied`、`failed`、`unsupported`。只有 `failed` 显示「未同步」。
- 后台计步服务首次运行时自动开启（Android），用户手动关闭后不再自动开启（记录在 `step_service_user_choice_set`）。

## 提醒

代码：`lib/data/repositories/reminders_repository.dart`、`lib/providers/workout_reminder_providers.dart`、`lib/ui/tools/workout_reminder_notifications.dart`、`lib/ui/tools/reminders_hub_page.dart`，原生部分见 [android-native.md](android-native.md)。

- 四类提醒：训练、喝水、饮食、称重。每类在列表里单独设置时间和星期几；响铃或振动、铃声四类共用，自定义标题和正文按类型分开，这些都在右上角齿轮的「提醒设置」弹窗里设置。默认振动；通知内容点某一类后在底部弹窗里编辑。
  - 响铃和铃声在存储上仍然是每类各存一份（`reminder_<kind>_alertMode` / `soundUri` / `soundTitle`），保存时 `setAlertModeAll` / `setSoundAll` 会同时写四份，所以原生排期和通知渠道 id 都没有变。老用户各类的设置可能不一样，由 `RemindersRepository._unifyAlertSettings` 统一一次（标记 `reminder_alert_unified_v1`）：取第一个已开启的提醒，都没开时取训练提醒。
- 保存设置后，`syncSchedule()` 会重新排期（尽力而为）；应用每次启动后也会同步一次。
- Android 上提醒由原生代码排期：每个提醒触发后自己排下一周，所以即使用户很久不打开应用，提醒也会继续；开机后会自动恢复。
- 提醒中心右上角的齿轮（`reminders-settings`）打开「提醒设置」弹窗，版式和休息计时器的提醒设置一致：列出权限问题（通知、精确闹钟、锁屏全屏、后台限制、排程失败），可以逐项处理；没有问题时显示「提醒所需权限均已开启」。有问题时齿轮上显示警告色小点。页面上不显示状态行，也不显示已安排的提醒数量。

## 休息计时器

代码：`lib/ui/tools/rest_timer_page.dart`、`lib/ui/tools/rest_timer_notifications.dart`，原生部分见 [android-native.md](android-native.md)。

- 计时的截止时间保存在 prefs（`rest_timer_deadline_ms`），离开页面或杀掉应用后再回来，仍能恢复。
- 提醒方式（右上角齿轮）默认「仅振动」。
- **默认振动只对新安装生效**：`lib/data/services/alert_defaults.dart` 的 `pinLegacyAlertDefaults` 在 `main()` 里执行一次（标记 `alert_default_vibrate_v1`）。已有 `user_profile` 的老安装，如果没手动选过，会被写回原来的默认值（提醒 `ring`、计时器 `ringAndVibrate`），所以升级后听到的方式不变。
- 开始计时时，Android 用 `setAlarmClock` 排一个闹钟，并在通知栏显示系统绘制的倒计时。
- **ColorOS 等系统会冻结后台应用、扣住它的闹钟**，导致计时结束后要等切回应用才响。应用的应对办法：
  - 在这类机型上，提醒设置里会显示「后台可能不准时」，引导用户打开「允许应用后台行为」；
  - 闹钟晚到超过 5 秒时，会把延迟记下来，回到应用后提示用户，并重新显示上面的提示。
  - 详见 [android-native.md](android-native.md#coloros-的后台冻结)。

## 备份与导入

代码：`lib/data/repositories/data_backup_repository.dart`，界面在 `lib/ui/profile/profile_page.dart`。

- **导出**：先执行 `PRAGMA wal_checkpoint(FULL)`，再读取整个数据库文件和全部 prefs，在 isolate 里编码成 JSON（`formatVersion: 1`）并 gzip 压缩，文件名为 `FitnessPlan_backup_<时间>.json.gz`。保存用 `FilePicker.saveFile`（SAF 路径无法用 `dart:io` 写入），分享则先写临时文件再调用系统分享。
- **导入**：
  1. 解压，兼容旧的未压缩 JSON；
  2. 关闭数据库，写入临时文件，删除旧库及其 `-wal`、`-shm`，再把临时文件改名替换；
  3. 清空 prefs，并逐项恢复；
  4. 记录导入日（供步数同步使用）。
- 导入完成后，**调用方必须刷新这些 provider**：invalidate `databaseProvider`、`themeProvider`、`localeProvider`、`remindersProvider`，重新加载档案和修仙账本，invalidate `cultivationHistoryProvider`，并调用提醒的 `syncSchedule()`。即使导入失败，也要 invalidate `databaseProvider`，让应用恢复到可用状态。现有的写法见 `profile_page.dart` 的 `_doImportData`。
- 导入文件选择器用的是 `FileType.any`：按 MIME 过滤会让 `.json.gz` 变成灰色无法选择。
- 已知不足：没有拦截来自更新版本应用的备份；会把另一台设备的下载会话一起恢复。见 [known-issues.md](known-issues.md)。

## 应用内更新

代码：`lib/data/repositories/app_update_repository.dart`、`lib/providers/app_update_providers.dart`、`lib/ui/profile/update_available_dialog.dart`。发布这一侧的流程见 [release.md](release.md)。

1. **拉取**：同时请求 Gitee（`Gryvaen/FitnessPlan`）和 GitHub（`Gryvaen/FitnessPlan`）的发布列表，**每边只要最新 `kReleasePageSize`（5）个、不翻页**，每边超时 15 秒。每个 GitHub 发布的 JSON 约 15 KB，大陆网络下拉全部历史会超时。一边失败不影响另一边，两边都失败才报错。
   - **GitHub 的文件一律走 REST 资源接口**（`api.github.com/repos/…/releases/assets/<id>`，请求头 `Accept: application/octet-stream`），不用 `github.com` 的下载链接：大陆网络下 `github.com` 时常连不上，`api.github.com` 稳定。清单、测速和 DownloadManager（`ApkDownloader.kt` 加同样的请求头）都这样做。
   - **Gitee 的发布 API 常被它的防火墙按 IP 限流（403）**，但直接下载链接不受影响。Gitee 一边拿不到结果、GitHub 有结果时，就从 `gitee.com/<仓库>/releases/download/<tag>/update-manifest.json` 直接读清单，按 `…/download/<tag>/<文件名>` 拼出 Gitee 下载地址；超过 `kGiteeMaxAssetBytes`（100 MB）的文件不拼（Gitee 上没有）。
2. **校验**：
   - 跳过草稿和预发布版本；tag 必须是 `vX.Y.Z`，下载地址必须是 https。
   - 发布里有 `update-manifest.json` 时，读取清单，逐个核对其中文件的名称、大小和 SHA-256。清单里列了、但这个下载源上没有的文件，直接跳过（Gitee 因此可以不放超过 100 MB 的通用包）。
   - 没有清单的发布，只接受 GitHub 上版本低于 `kFirstManifestVersion`（2.6.1）的，用 GitHub 自带的 digest 校验；Gitee 上没有清单的发布一律丢弃。
3. **选择安装包**：按已安装版本的构建号判断 ABI 通道：1xxx → `armeabi-v7a`，2xxx → `arm64-v8a`，4xxx → `x86_64`。分包用户必须留在同一通道，否则 Android 会把新版本当成降级，拒绝安装。**通用包用户（构建号小于 1000）改下本机 ABI 的分包**（`currentApkAbi()`，来自 `dart:ffi` 的 `Abi.current()`）：分包的 versionCode 更大，属于正常升级，体积更小，而且 Gitee 上只有分包。没有对应分包时才退回通用包。同一版本在两个源上的文件合并为多个候选下载地址；两边的大小或哈希不一致时直接报错。
4. **检查时机**：启动和回到前台时静默检查（只更新「我的」上的红点）；用户也可以在「我的」里手动检查。缓存的红点版本一旦不比已安装版本新，就在检查前直接清掉，不等网络。
5. **下载**：按用户选择的下载源（自动 / Gitee / GitHub），或者给每个源测速（请求 256 KiB）后排序，速度相同时优先 Gitee。通过原生 DownloadManager 下载，下载会话存在 prefs 里，进程被杀后可以续上。30 秒没有任何进度（或 60 秒卡住）就切换到下一个源。**GitHub 下载开始 15 秒（`kSlowDownloadWindow`）后平均速度低于 150 KiB/s，且还有 Gitee 可用时，切到 Gitee**，GitHub 放回队尾作为后备；每次下载最多这样切一次。256 KiB 的测速样本太小，经常判断不准，主要靠这条兜底。下载进度只显示在「我的」右上角下载图标的圆圈上。
   - Gitee 下载按 IP 做令牌桶限速：开头约 1.3 MB 很快，短时间内下多了会掉到几十 KB/s。真机反复测试时会遇到，不是代码问题。
6. **安装**：原生层校验文件大小和 SHA-256，不通过就换源重下，**绝不安装未经校验的文件**；通过后调用系统安装器。这里的哈希只校验文件完整性，不能代替 Android 的 APK 签名校验。
   - **后台完成**：Android 10 起，后台应用调起安装器会被系统静默拦截（`startActivity` 不报错）。因此 `_finishDownload` 判断不在前台（`appUpdateIsForegroundProvider`）时不调安装器，只写 `app_update_install_on_resume`。用户可以点原生广播发的「点击安装」通知（App 在前台时广播不发这条通知）；也可以直接回到 App，由 `MainShell` 在启动和每次回前台时调用 `onAppResumed(本机版本)` 打开安装器。用户点「下载安装」时会申请通知权限；拒绝也不影响回前台自动弹出。
   - **已下载未安装**：校验通过的包记在 `app_update_ready_apk`（版本、downloadId、asset），DownloadManager 的记录和文件都保留。用户在安装界面取消后，再点右上角按钮（tooltip 显示「安装 vX」），会跳过联网检查，`installReady()` 重新校验后直接安装；`downloadAndInstall` 遇到 sha256 相同的包也直接安装。文件丢失或校验不过时，就丢弃这条记录，回到正常的下载流程。
   - **清理**：本机版本已不低于已下载的版本（说明装上了），或者要下载另一个包时，`cancelDownload` 会删掉旧包和它的记录。
