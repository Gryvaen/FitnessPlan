# Android 原生层

这份文档讲 Kotlin 原生代码：平台通道、Manifest 权限、通知、后台可靠性设计、构建与签名，以及原生测试。改提醒、休息计时器、后台计步、更新下载之前看。每个文件的一句话说明见 [code-map.md](code-map.md#android-原生代码)。

代码目录：`android/app/src/main/kotlin/com/fitnessplan/fitness_plan/`，共 17 个文件。

## 为什么要写原生代码

Flutter 的通知插件只能「到点发一条通知」，做不到持续响铃，在国产系统上也很容易被拦截。所以 Android 上的提醒和休息计时器都由原生代码负责排期：用 `setAlarmClock` 设闹钟，到点后启动前台服务，循环播放铃声和振动，并在锁屏上显示一个闹钟页面。iOS 仍然走 flutter_local_notifications。

## 平台通道

全部是 MethodChannel，统一在 `MainActivity.configureFlutterEngine` 里注册。项目里没有 EventChannel。

| 通道 | 原生方法 | Dart 调用方 |
|---|---|---|
| `fitness_plan/rest_timer_alarm` | `schedule`（截止时间、标题、正文、关闭按钮文字、是否响铃、是否振动、倒计时标题；响铃和振动都关时报错）、`cancel`、`takeLastDelayMs`、`canScheduleExactAlarms` | `lib/ui/tools/rest_timer_notifications.dart` |
| `fitness_plan/workout_reminder` | `scheduleAll`（返回成功和失败的数量）、`cancelAll`、`alarmStatus`、`scheduleStatus`、`isAggressiveOem`、`isBackgroundRestricted`、`manufacturer`、`isIgnoringBatteryOptimizations`、`requestIgnoreBatteryOptimizations`、`openAutoStartSettings`（返回 `oem`/`battery`/`appDetails`/`colorOsAppDetails`）、`pickRingtone` | `lib/ui/tools/workout_reminder_notifications.dart` |
| `fitness_plan/step_counter` | `setStepService`、`isStepServiceEnabled`（由 MainActivity 处理）；`readTodaySteps`、`readRecentSteps`、`isAvailable`、`openHealthConnectSettings`、`diagnostics`（交给 `StepCounterBridge.handle`） | `lib/data/services/android_step_sensor.dart` |
| `fitness_plan/apk_downloader` | `enqueue`（地址、文件名、大小、sha256）、`verify`、`query`、`cancel`、`dismissInstallNotification`（Dart 已打开安装器时收掉 73001 通知） | `lib/data/repositories/app_update_repository.dart` |

Dart 侧在调用前都会先判断平台；非 Android 平台不会调用这些通道。测试里用 `setMockMethodCallHandler` 模拟它们，见 [testing.md](testing.md)。

**新增一个通道方法的步骤**：在 `MainActivity` 对应通道的 `when` 里加分支 → 在 Dart 封装类里加方法（用 try/catch 兜底，捕获 `MissingPluginException`）→ 在相关测试的 mock handler 里加上这个方法。

## Manifest

文件：`android/app/src/main/AndroidManifest.xml`。

### 权限

| 权限 | 用途 |
|---|---|
| `INTERNET`、`ACCESS_NETWORK_STATE` | 检查更新、下载更新包、判断是否在等待网络 |
| `REQUEST_INSTALL_PACKAGES` | 安装下载好的更新 |
| `RECEIVE_BOOT_COMPLETED` | 开机后恢复提醒排期、午夜计步 |
| `VIBRATE`、`WAKE_LOCK` | 响铃服务（`MediaPlayer` 持有部分唤醒锁） |
| `POST_NOTIFICATIONS` | 所有通知（Android 13+） |
| `SCHEDULE_EXACT_ALARM` | `setAlarmClock` / 精确闹钟（Android 12+）；没有授权时退回非精确闹钟 |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | 申请电池优化豁免的系统对话框 |
| `USE_FULL_SCREEN_INTENT` | 锁屏闹钟页；Android 14+ 用 `canUseFullScreenIntent()` 检查是否可用 |
| `FOREGROUND_SERVICE`、`FOREGROUND_SERVICE_SPECIAL_USE` | 两个响铃服务 |
| `FOREGROUND_SERVICE_HEALTH`、`ACTIVITY_RECOGNITION` | 后台计步服务和计步传感器 |
| `health.READ_STEPS`、`health.READ_HEALTH_DATA_HISTORY`、`health.READ_HEALTH_DATA_IN_BACKGROUND` | 通过 Health Connect 读取步数 |

### 组件

- **Activity**：`MainActivity`（启动入口；同时响应 Health Connect 的权限说明请求）；`ViewPermissionUsageActivity` 别名（Android 14+ Health Connect 要求的隐私说明入口）；`ReminderAlarmActivity`（锁屏闹钟页，不导出）。
- **前台服务**：`ReminderAlarmService` 和 `RestTimerAlarmService`（`specialUse` 类型）；`StepCounterService`（`health` 类型）。
- **广播接收器**（都不导出）：计时器的到点和关闭、提醒到点、下载完成、开机恢复（`ReminderBootReceiver` 响应开机、快速开机、应用更新、改时间、改时区、精确闹钟权限变化）、午夜计步。
- `<queries>` 里声明了 Health Connect 相关的包和 action。

## 通知 ID 与渠道

| ID / 请求码 | 用途 | 所在代码 |
|---|---|---|
| 71001 | 休息计时器闹钟的请求码；Dart 侧的通知 id | `RestTimerAlarmScheduler`、`rest_timer_notifications.dart` |
| 71002 | 计时器响铃服务的通知 | `RestTimerAlarmService` |
| 71003 | 计时器的降级通知 | `RestTimerFallbackNotification` |
| 71004 | 计时器的通知栏倒计时 | `RestTimerAlarmScheduler` |
| 71011 | 午夜计步快照闹钟的请求码 | `StepCounterBridge` |
| 71021 | 后台计步服务的通知 | `StepCounterService` |
| 72001 / 72101 / 72201 / 72301 + 序号 | 训练 / 喝水 / 饮食 / 称重提醒；Dart 用 `idBase + 0..6` | `reminders_repository.dart` 的 `ReminderKind.idBase`、`WorkoutReminderScheduler` |
| 72401 | 提醒响铃服务的通知 | `ReminderAlarmService` |
| 73001 | 「更新已下载」通知；`MainActivity` 处于 resumed 时（`ApkDownloadCompleteReceiver.appVisible`）不发，由 Dart 直接打开安装器 | `ApkDownloadCompleteReceiver` |
| 4271 | 铃声选择器的 Activity 请求码 | `MainActivity` |

主要的通知渠道：`rest_timer_countdown_v1`（低重要性、静音）、`rest_timer_native_alarm_v1`、`rest_timer_fallback_alarm_v2_{both,ring,vibrate}`、`daily_reminder_alarm_service_v1`、`step_counter_service_v1`、`app_update_v1`。

**渠道创建之后，声音和重要性就改不了了**，所以渠道 id 都带版本后缀。要改渠道的声音或重要性，就把后缀加 1，新建一个渠道。

## 后台可靠性设计

- **精确闹钟**：计时器和提醒都用 `AlarmManager.setAlarmClock`。这是最高优先级的闹钟，不受 Doze 限制，状态栏会显示闹钟图标。没有精确闹钟权限时，提醒退回 `setAndAllowWhileIdle`；计时器只在抛出 `SecurityException` 时才退回。午夜计步快照用的是 `setExactAndAllowWhileIdle`。
- **前台服务负责响铃**：单靠通知渠道无法持续响铃，所以由前台服务循环播放铃声和振动。服务起不来时（例如后台启动前台服务被系统限制），改发一条由渠道自带声音和振动的降级通知。
- **提醒自我续期**：提醒设置存在原生的 SharedPreferences（`reminder_alarms`）里。每次触发时，先把这个时段的下一周排好，再响铃。所以即使 Flutter 端从来不打开，提醒也会一直持续。开机后由 `ReminderBootReceiver` 恢复，并补发开机前 60 分钟内错过的提醒。
- **休息计时器不在开机后恢复**，它是一次性的。
- **后台计步**：`StepCounterService` 是 `START_STICKY` 的前台服务，让进程和传感器跨过午夜也保持存活。`StepCounterBridge` 把传感器自开机以来的累计步数换算成每天的步数，并在午夜存一个快照，作为第二天的基线。小米设备优先读取 MIUI 自己的步数 provider。

### 厂商后台限制

`DeviceReliability.kt`：
- `isAggressiveOem()`：按品牌或厂商名识别 oppo、oneplus、realme、xiaomi、redmi、poco、huawei、honor、vivo、iqoo、meizu、letv、lenovo；LineageOS 除外。
- `openAutoStartSettings()` 按顺序尝试打开以下页面：
  1. 各厂商的自启动或后台管理页（硬编码的组件名）；
  2. AOSP 的应用耗电详情页（**ColorOS 上跳过**）；
  3. 应用详情页。
- ColorOS 上最终落到应用详情页时，返回 `colorOsAppDetails`，并弹出 Toast「请点「耗电管理」，打开「允许应用后台行为」」。
- `launchFirstAvailable` 把「如何启动页面」作为参数传入，所以可以写单元测试。

### ColorOS 的后台冻结

2026-10-16 在一加 PHM110（ColorOS 15 / Android 15）上用 adb 实测确认：

- 应用离开前台约 5 秒后，ColorOS 的 Hans 会冻结进程，并通过 `OplusAlarmAdjustment proxyAlarmsByUid` 扣住它的闹钟，**包括 `setAlarmClock`**。闹钟要等应用回到前台才会放行（偶尔也会因为蓝牙扫描之类的事件被提前放行）。
- 前台服务在运行、应用在电池优化白名单里，都**挡不住**这种冻结。需要用户手动打开**两个**开关（2026-10-18 实测）：
  - 应用详情 → 耗电管理 → 「允许应用后台行为」；
  - 设置 → 应用 → 自启动 → 打开本应用（`com.oplus.battery/com.oplus.startupapp.view.StartupAppListActivity`）。这个页面需要 `oplus.permission.OPLUS_COMPONENT_SAFE` 权限，第三方应用跳不过去，只能在文案里写清路径。
  只开「允许应用后台行为」时，进程被杀后闹钟照样被拦。两个都开了，进程被杀后系统会立刻重新拉起后台计步服务，提醒能准时响（实测延迟不到 0.1 秒，划掉后台也一样）。
- ColorOS 15 的包名已经改成 `com.oplus.*`，旧的 `com.coloros.safecenter` 页面不存在了；「耗电管理」页（`com.oplus.battery/...PowerControlActivity`）没有对第三方应用导出，无法直接打开。所以应用详情页是能跳到的最近位置。
- 应用这边的应对：计时器的通知栏倒计时由 SystemUI 绘制，应用被冻结时也能显示剩余时间；闹钟晚到超过 5 秒会被记录下来（`RestTimerAlarmReceiver` → prefs `rest_timer_alarm` / `last_delay_ms`），回到应用时提示用户去设置。

2026-10-18 在同一台手机上补充实测（未开「允许自启动」）：

- App 进程不在时，闹钟到点会被 `OplusAppStartupManager` 拦下。**三种唤醒方式都不行**：
  - 广播（现行做法）：`prevent start ... by broadcast`；
  - `PendingIntent.getForegroundService`：`isAllowStartFromStartService: prevent start`；
  - `PendingIntent.getActivity`：`Background activity launch blocked`。即使加上 Android 14 的 `setPendingIntentCreatorBackgroundActivityStartMode` 也一样。
- 被拦的广播有时会在用户下次打开 App 时补送（提醒晚响），有时直接丢失。
- 后台计步服务（前台服务）在运行时，进程在最近任务里被划掉也活着，提醒能准时响。不过同一天里也观察到过划掉后进程被杀的情况，不能依赖。
- 应用的应对：`WorkoutReminderScheduler` 记录漏发和晚发（`missed_triggers`），打开 App 时弹 SnackBar，提醒设置页显示「提醒被系统拦截」，引导用户打开自启动。
- **测试时不要用 `am force-stop`**：它会清掉应用的全部闹钟。要模拟进程被杀，用 `adb shell run-as com.fitnessplan.fitness_plan kill -9 <pid>`。

**排查「提醒或计时器不准时」的方法**：

```bash
adb logcat -c
# 复现问题：开始计时 → 切到别的应用 → 等它到点
adb logcat -d -v time | grep -E "OplusAlarmAdjustment|RestTimerAlarm" | grep -E "10536|fitness"
adb shell dumpsys alarm | grep -A3 fitness_plan
```

如果看到 `proxyAlarmsByUid(), uid=<应用 uid>` 之后很久才出现 `unproxyAlarmsByUid`，就是系统冻结导致的，改排期代码没有用。应用的 uid 可以用 `adb shell dumpsys package com.fitnessplan.fitness_plan | grep userId` 查到（维护机上是 10536）。

## 锁屏闹钟页与 Flutter 资源的隐性耦合

`ReminderAlarmActivity` 直接读取 Flutter 的资源和设置：
- 主题：`FlutterSharedPreferences` 里的 `flutter.app_theme_id`；`graphite`、`night`、`midnight`、`aurora` 视为深色。
- 字体：`flutter_assets/assets/fonts/LXGWWenKaiLite-Medium.ttf`。
- 图标：`flutter_assets/assets/ink/icons/{light,dark}/{training,water,food,weight,timer}-v1.png`。

改这些资源的路径或主题 id 时，要同步修改这个 Activity。否则原生页面不会报错，只会悄悄退回默认字体和应用图标。

## 构建配置

文件：`android/app/build.gradle.kts`、`android/settings.gradle.kts`、`android/gradle.properties`。

- `applicationId` / `namespace`：`com.fitnessplan.fitness_plan`；`minSdk = 26`；compile 和 target SDK 由 Flutter 决定（目前为 36）。
- Java / Kotlin 目标版本 17，开启 core library desugaring 和 multidex。
- 依赖仓库优先使用阿里云镜像，然后才是 `google()` 和 `mavenCentral()`。
- 构建产物输出到仓库根目录的 `build/`。
- `versionCode` 和 `versionName` 来自 `pubspec.yaml` 的 `version: X.Y.Z+N`。
- **ABI 版本号**：按 ABI 拆分构建时，Flutter 会把 `versionCode` 改成 `ABI × 1000 + N`，其中 armeabi-v7a = 1，arm64-v8a = 2，x86_64 = 4。通用包没有前缀。应用内更新靠这个前缀判断用户装的是哪个包，见 [features.md](features.md#应用内更新)。
- R8：没有自定义的 `proguard-rules.pro`；Flutter 的 Gradle 插件默认对 release 开启代码压缩和资源压缩。Dart 代码另外用 `--obfuscate` 混淆，符号表保存在 `dist/symbols/`，用于还原崩溃堆栈。

### 签名

- 存在 `android/key.properties` 时，release 构建用它签名；**不存在时会悄悄改用 debug 签名**（方便本地 `flutter run --release`）。
- `key.properties` 和 `*.jks` / `*.keystore` 都被 git 忽略。模板是 `android/key.properties.example`，可以用 `tool/release/create_release_keystore.sh` 生成新的签名文件。
- **重要**：目前维护机上的 `key.properties` 指向 `~/.android/debug.keystore`（别名 `androiddebugkey`）。也就是说，已发布的 APK 实际上是用这台机器的 Android debug 密钥签名的。这个文件一旦丢失，或者换一台机器构建，新包都无法覆盖安装到现有用户的设备上。**务必备份这个 keystore。** 详见 [release.md](release.md#签名) 和 [known-issues.md](known-issues.md)。

## 资源文件

- 字符串：`res/values/strings.xml`（英文）和 `res/values-zh/strings.xml`（中文），包括应用名、通知渠道名、闹钟文字、ColorOS 提示等。新增字符串时两边都要加。（目前中文缺 4 个 `workout_reminder_*`，见 [known-issues.md](known-issues.md)。）
- 启动页和主题：`res/values*/styles.xml`、`res/drawable*/launch_background.xml`、`res/drawable-anydpi-v31/splash_adaptive_icon.xml`。
- 图标：`res/mipmap-*`。

## 原生单元测试

- 位置：`android/app/src/test/kotlin/com/fitnessplan/fitness_plan/`，包括 `ApkIntegrityTest.kt`、`DeviceReliabilityTest.kt`。都是纯 JVM 测试，只覆盖不依赖 Android 框架的逻辑。
- 运行（需要 JDK 21，见 [setup.md](setup.md#关于-jdk)）：
  ```bash
  cd android && JAVA_HOME=<JDK 21 路径> ./gradlew :app:testDebugUnitTest
  ```
  结果在 `build/app/test-results/testDebugUnitTest/`。
- CI 不跑这些测试，改原生代码后请在本地跑一遍。
