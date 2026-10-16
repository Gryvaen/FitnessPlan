# 开发环境与日常命令

这份文档讲怎样把开发环境搭起来，以及日常开发要用到的命令。第一天看。模拟器的详细用法见 [docs/android-emulator.md](../android-emulator.md)。

## 工具链

| 工具 | 版本 / 位置 | 说明 |
|---|---|---|
| Flutter | 3.47.x stable（本机为 3.47.7） | `pubspec.lock` 要求 `flutter >=3.44.0`。仓库没有 `.fvm` 之类的版本锁定文件；CI 使用最新的 stable，也没有固定版本。 |
| Dart | `^3.12.2` | 见 `pubspec.yaml` 的 `environment.sdk` |
| JDK | **21** | Gradle 9.1 在 JDK 27 上会在 jlink 步骤失败。系统默认 Java 如果比 21 新，就要显式指定 `JAVA_HOME`，见下文。 |
| Android SDK | `~/Android/Sdk` | compile/target SDK 跟随 Flutter（目前为 36），`minSdk = 26`（health 插件要求） |
| AGP / Kotlin / Gradle | 9.0.1 / 2.3.20 / 9.1.0 | 见 `android/settings.gradle.kts`、`android/gradle/wrapper/gradle-wrapper.properties` |
| Python 3 | 系统自带即可 | 发版和食材种子脚本只用标准库；软著脚本需要 `tool/.venv`，见 [tools.md](tools.md) |
| gh | 已登录 | 只有发版时需要 |

`android/local.properties`（已被 git 忽略）记录本机的 Flutter SDK 路径，由 Flutter 自动生成。

### 关于 JDK

```bash
# 只在跑 Gradle 时临时指定，不影响系统默认 Java。
# 把路径换成你机器上任意 JDK 21；原维护机上是 ~/development/jdk-21，
# 系统包里的 /usr/lib/jvm/java-21-openjdk 也可以。
cd android && JAVA_HOME=~/development/jdk-21 ./gradlew :app:testDebugUnitTest
```

`flutter build` 和 `flutter run` 使用 Flutter 自己配置的 JDK（`flutter doctor -v` 里显示的 Java binary），通常不用另外指定。`tool/release/build_test_apk.sh` 在 `JAVA_HOME` 未设置时，会自动使用 `/usr/lib/jvm/java-21-openjdk`。

## 第一次运行

```bash
flutter pub get        # 同时会按 l10n.yaml 生成多语言代码
flutter analyze
flutter test
flutter run            # 默认连到第一台设备；用 flutter devices 查看设备列表
```

第一次启动会把 `assets/food_seed.json` 同步进数据库（约 670 种食材），所以首屏的加载动画会稍长一些。

## 日常命令

| 场景 | 命令 |
|---|---|
| 静态分析 | `flutter analyze`（CI 和发版脚本用的是 `--no-fatal-infos`） |
| 全部测试 | `flutter test` |
| 单个测试文件 | `flutter test test/food_seed_sync_test.dart` |
| 按名称跑单个用例 | `flutter test test/xxx_test.dart --plain-name "用例名"` |
| 格式化 | `dart format lib test` |
| 改了 Drift 表之后 | `dart run build_runner build --delete-conflicting-outputs`，见 [database.md](database.md) |
| 改了 ARB 文案之后 | `flutter gen-l10n`（`flutter pub get` 和构建时也会自动生成） |
| 调试启动动画 | `flutter run --dart-define=LOADING_LAB=true` |
| 打一个测试用 APK | `./tool/release/build_test_apk.sh`，见 [tools.md](tools.md) |
| 原生单元测试 | `cd android && JAVA_HOME=<JDK 21 路径> ./gradlew :app:testDebugUnitTest` |
| 发版脚本的测试 | `python3 -m unittest discover -s tool/release -p 'test_*.py'` |

生成的代码都提交进仓库：`lib/data/db.g.dart` 和 `lib/l10n/app_localizations*.dart`（`app_localizations_ext.dart` 是手写的，不是生成文件）。改了源文件之后记得重新生成并一起提交，因为 CI 不检查生成文件是否最新。

## 真机调试

开发者自己的测试机是一加 PHM110（ColorOS 15 / Android 15），通过 USB 连接。

- **覆盖安装时要保留数据**：手机上装的是正式签名包，debug 包签名不同，无法覆盖安装。正确做法：
  ```bash
  flutter build apk --release        # 需要 android/key.properties，见 release.md
  adb install -r build/app/outputs/flutter-apk/app-release.apk
  ```
  `-r` 表示保留数据覆盖安装。**不要卸载重装**，那样会清空用户数据。签名不一致时，`adb install -r` 会直接失败，不会破坏原有数据。
- **常用 adb**：
  ```bash
  adb shell monkey -p com.fitnessplan.fitness_plan -c android.intent.category.LAUNCHER 1   # 启动应用
  adb exec-out screencap -p > shot.png                                                   # 截图
  adb logcat | grep -E "RestTimerAlarm|ReminderSettings|StepCounter"                     # 看原生层日志
  adb shell dumpsys alarm | grep -A3 fitness_plan                                        # 查看已排期的闹钟
  ```
- **后台闹钟不准时**：先排查 ColorOS 的后台冻结，方法见 [android-native.md](android-native.md#coloros-的后台冻结)。

## 编辑器

- 仓库根目录的 `analysis_options.yaml` 只引入了 `flutter_lints`，没有自定义规则。
- `build/`、`dist/`、`android/` 等平台目录都在 analyzer 的排除列表里。
