# 健身饮食 / Fitness Plan

[![CI](https://github.com/Gryvaen/FitnessPlan/actions/workflows/ci.yml/badge.svg)](https://github.com/Gryvaen/FitnessPlan/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-Personal%20Free%20%2F%20Commercial%20Paid-blue)](LICENSE)
[![Release](https://img.shields.io/github/v/release/Gryvaen/FitnessPlan?include_prereleases)](../../releases)
[![Flutter](https://img.shields.io/badge/Flutter-Dart%20%5E3.12.2-02569B?logo=flutter&logoColor=white)](https://docs.flutter.dev/get-started/install)
[![Donate](https://img.shields.io/badge/Donate-支付宝-1677FF?style=flat&logo=alipay&logoColor=white)](docs/donate.md)

[English ↓](#english)

纯本地 Flutter 健身饮食助手：按身体数据计算每日热量与三大营养素，内置常见食材库，支持饮食记账与体重记录。全部数据保存在设备本地，无需登录、无云端。

## 目录

- [功能](#功能)
- [技术栈](#技术栈)
- [环境要求](#环境要求)
- [快速开始](#快速开始)
- [开发工作流](#开发工作流)
- [项目结构](#项目结构)
- [测试](#测试)
- [发布 / 下载](#发布--github-release)
- [贡献](#贡献)
- [赞助](#赞助--donate)
- [许可证](#许可证)

## 功能

- 录入性别、年龄、身高、体重、活动量与目标（减脂 / 维持 / 增肌）
- Mifflin–St Jeor 算法：BMR → TDEE → 每日热量与碳水 / 蛋白质 / 脂肪
- 减脂策略：循环碳水 / 碳水递减等策略配置，按日给出目标
- 584 条中国大陆常见食材营养数据（每 100g，含热量 / 蛋白质 / 碳水 / 脂肪 / 酒精 / 纤维 / 钠 / 糖 / 饱和脂肪 / 钙共 10 个字段），记一笔饮食自动扣减当日剩余配额
- 按日查看历史饮食与配额（含缺口日历选择）；支持历史日补记
- 体重记录与折线图；体脂率与身体围度；减脂平台期提示
- 训练记录：动作库、训练计划、组数 / 次数记录
- 每日步数（Health Connect / HealthKit，安卓无权限时回退到传感器计步，支持历史补齐）
- 随记
- 提醒：训练 / 饮水 / 饮食 / 称重，各自独立的提醒时间与重复星期
- 工具箱：体脂率、身体围度、计算器、千卡 / 千焦换算、食物单位换算、休息计时器
- 多套主题配色；中 / 英文界面
- App 内检查更新（GitHub Release）
- 全部数据本地保存，无需登录、无云端

## 技术栈

| 依赖 | 版本 | 用途 |
|------|------|------|
| Flutter | Dart SDK `^3.12.2` | 跨平台 UI 框架（Material Design） |
| flutter_riverpod | `^3.3.2` | 状态管理 |
| go_router | `^17.3.0` | 路由导航 |
| drift | `^2.34.2` | 本地数据库（SQLite） |
| fl_chart | `^1.2.0` | 体重曲线等图表 |
| shared_preferences | `^2.5.5` | 用户配置存储 |
| health | `^13.3.1` | Health Connect / HealthKit 步数同步 |
| flutter_local_notifications | `^22.0.1` | 本地提醒推送 |
| permission_handler | `^12.0.3` | 运行时权限 |
| package_info_plus / http / open_filex | 见 `pubspec.yaml` | App 内检查更新 / 下载 / 安装 |
| share_plus / file_picker | 见 `pubspec.yaml` | 分享与文件导入导出 |

开发依赖：`drift_dev ^2.34.0`（代码生成）、`build_runner ^2.15.1`、`flutter_lints ^6.0.0`（静态检查规则见 [analysis_options.yaml](analysis_options.yaml)）。

## 环境要求

- [Flutter](https://docs.flutter.dev/get-started/install) SDK（与 `pubspec.yaml` 中的 Dart SDK 约束 `^3.12.2` 保持一致）
- 可选：Android 模拟器 / 真机，或 Linux / macOS / Windows / Web 桌面目标
- Linux 模拟器与真机调试的详细步骤见 [docs/模拟器与运行说明.md](docs/模拟器与运行说明.md)

## 快速开始

```bash
git clone git@github.com:Gryvaen/FitnessPlan.git
cd FitnessPlan
flutter pub get
flutter run                 # 自动选择已连接设备
flutter run -d linux        # Linux 桌面调试
flutter build apk --debug   # 打安卓包
flutter analyze --no-fatal-infos
flutter test
```

### PATH 示例（可选）

```bash
export PATH="$HOME/development/flutter/bin:$HOME/Android/Sdk/emulator:$HOME/Android/Sdk/platform-tools:$PATH"
export JAVA_HOME="$HOME/development/jdk-21"   # 安卓构建用
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
```

## 开发工作流

**数据库（Drift）** — 修改 `lib/data` 下的表结构后需重新生成代码：

```bash
dart run build_runner build
```

**食材种子** — [assets/food_seed.json](assets/food_seed.json)：584 条中国大陆常见食材，AI 生成并校对，每条 10 个字段（热量 / 蛋白质 / 碳水 / 脂肪 / 酒精 / 纤维 / 钠 / 糖 / 饱和脂肪 / 钙，每 100g）。[tool/build_food_seed.py](tool/build_food_seed.py)（合并 CFCT / Sanotsu / Open Food Facts）已废弃，仅存历史参考。

改动后需同步提高 [lib/data/repositories/food_repository.dart](lib/data/repositories/food_repository.dart) 中的 `kFoodSeedVersion`（当前 `10`），否则已安装设备不会重新同步。

**多语言（l10n）** — 文案位于 [lib/l10n/app_zh.arb](lib/l10n/app_zh.arb)（中文）与 [lib/l10n/app_en.arb](lib/l10n/app_en.arb)（英文，作为模板文件），生成配置见 [l10n.yaml](l10n.yaml)。新增/修改文案后：

```bash
flutter gen-l10n   # 或执行 flutter pub get / flutter run 时会自动触发生成
```

## 项目结构

```
lib/
  domain/          # 热量算法与领域模型
  data/            # Drift DB、仓库、原生服务桥接（步数、提醒）
  providers/       # Riverpod providers
  features/        # 新的按功能划分结构（目前仅 loading/）
  l10n/            # 本地化 ARB 源文件与生成代码
  ui/              # 页面与组件
    today/         # 今日配额
    meals/         # 饮食记录
    foods/         # 食材库
    records/       # 体重 / 训练 / 随记
    strategy/      # 减脂策略
    tools/         # 工具箱、提醒设置
    theme/         # 主题与共享 UI 组件
    profile/       # 个人资料、我的
    onboarding/    # 首次引导
    shell/         # 应用外壳、底部导航等
    ink/           # 水墨风格图标与视觉资源
    loading/       # 加载 / 过渡页面
    widgets/       # 通用组件
assets/
  food_seed.json   # 食材种子数据
test/              # 单元、组件与截图（golden）测试
```

## 测试

```bash
flutter analyze --no-fatal-infos
flutter test
```

`test/` 覆盖领域算法单测、仓库 / provider 测试、widget 测试，以及守护关键页面视觉一致性的 `*_screenshots_test.dart` 截图（golden）测试。CI（[.github/workflows/ci.yml](.github/workflows/ci.yml)）在每次 push 到 `main`/`master` 及每个 PR 上运行相同检查。

## 发布 / GitHub Release

Android APK 可从仓库的 [Releases](../../releases) 下载。

| 文件 | 说明 |
|------|------|
| `FitnessPlan-*-android-arm64-v8a.apk` | **推荐**：绝大多数真机 |
| `FitnessPlan-*-android.apk` | 通用包（体积更大） |
| `FitnessPlan-*-android-armeabi-v7a.apk` | 较老的 32 位 ARM |
| `FitnessPlan-*-android-x86_64.apk` | 模拟器 / x86 设备 |

本机重新打包（需先配置正式签名）：

```bash
./tool/create_release_keystore.sh   # 首次：生成 upload-keystore.jks + key.properties
./tool/build_release_apk.sh         # analyze + test + 打 release APK → dist/
# 产物在 dist/
```

签名配置见 [android/key.properties.example](android/key.properties.example)；`key.properties` 与 `*.jks` 已在 `.gitignore` 中忽略。

### 关于 iOS

Linux 无法构建 iOS / IPA，需 macOS + Xcode，且分发通常还需 Apple Developer 账号（TestFlight / App Store）。因此 Release 目前只提供 Android APK。在 Mac 上可执行：

```bash
flutter build ipa --release
# 产物：build/ios/ipa/*.ipa（需配置签名）
```

## 贡献

提交 PR 前请本地跑通（与 CI 一致）：

```bash
flutter analyze --no-fatal-infos
flutter test
```

代码风格遵循 `flutter_lints`（[analysis_options.yaml](analysis_options.yaml)），无自定义规则。

## 赞助 / Donate

如果这个项目对你有帮助，欢迎 [支付宝赞助](docs/donate.md)。

## 许可证

个人 / 非商业使用免费；商业使用需另行付费授权，请通过 GitHub Issues 联系。
详见 [LICENSE](LICENSE)。

---

<a id="english"></a>

# English

[← 中文](#健身饮食--fitness-plan)

[![CI](https://github.com/Gryvaen/FitnessPlan/actions/workflows/ci.yml/badge.svg)](https://github.com/Gryvaen/FitnessPlan/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-Personal%20Free%20%2F%20Commercial%20Paid-blue)](LICENSE)
[![Release](https://img.shields.io/github/v/release/Gryvaen/FitnessPlan?include_prereleases)](../../releases)
[![Donate](https://img.shields.io/badge/Donate-Alipay-1677FF?style=flat&logo=alipay&logoColor=white)](docs/donate.md)

A fully offline Flutter fitness & nutrition app. It calculates daily calorie and macro targets from your body stats, ships with a built-in food database, and lets you log meals and weight — all stored on device, no accounts, no cloud.

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Development](#development)
- [Project Structure](#project-structure)
- [Testing](#testing)
- [Downloads / GitHub Release](#downloads--github-release)
- [Contributing](#contributing)
- [Donate](#donate)
- [License](#license)

## Features

- Enter sex, age, height, weight, activity level, and goal (cut / maintain / bulk)
- Mifflin–St Jeor: BMR → TDEE → daily calories and carbs / protein / fat
- Fat-loss strategies: carb cycling / carb tapering, with day-by-day targets
- 584 common Mainland China foods with nutrition data (per 100g, 10 fields: calories / protein / carbs / fat / alcohol / fiber / sodium / sugar / saturated fat / calcium); log a meal to auto-deduct from today's budget
- Browse past days' meals and budgets (with a deficit date picker); backfill past days
- Weight logs with a line chart; body fat % and body measurements; plateau hints when cutting
- Workout tracking: exercise library, training plans, set/rep logging
- Daily steps (Health Connect / HealthKit, falling back to the device sensor on Android when permission isn't granted), with history backfill
- Freeform notes
- Reminders: workout / water / meal / weigh-in, each with its own time and repeat days
- Toolbox: body fat, body measurements, calculator, kcal/kJ conversion, food unit conversion, rest timer
- Multiple color themes; Chinese / English UI
- In-app update check (GitHub Releases)
- Fully local storage — no accounts, no cloud

## Tech Stack

| Dependency | Version | Purpose |
|------|------|------|
| Flutter | Dart SDK `^3.12.2` | Cross-platform UI framework (Material Design) |
| flutter_riverpod | `^3.3.2` | State management |
| go_router | `^17.3.0` | Navigation |
| drift | `^2.34.2` | Local database (SQLite) |
| fl_chart | `^1.2.0` | Weight charts |
| shared_preferences | `^2.5.5` | Profile settings |
| health | `^13.3.1` | Health Connect / HealthKit step sync |
| flutter_local_notifications | `^22.0.1` | Local reminder notifications |
| permission_handler | `^12.0.3` | Runtime permissions |
| package_info_plus / http / open_filex | see `pubspec.yaml` | In-app update check / download / install |
| share_plus / file_picker | see `pubspec.yaml` | Sharing and file import/export |

Dev dependencies: `drift_dev ^2.34.0` (codegen), `build_runner ^2.15.1`, `flutter_lints ^6.0.0` (see [analysis_options.yaml](analysis_options.yaml)).

## Requirements

- [Flutter](https://docs.flutter.dev/get-started/install) SDK (match the Dart SDK constraint `^3.12.2` in `pubspec.yaml`)
- Optional: Android emulator / device, or Linux / macOS / Windows / Web targets
- For Linux emulator/device setup details, see [docs/模拟器与运行说明.md](docs/模拟器与运行说明.md) (Chinese)

## Quick Start

```bash
git clone git@github.com:Gryvaen/FitnessPlan.git
cd FitnessPlan
flutter pub get
flutter run                 # pick a connected device
flutter run -d linux        # Linux desktop
flutter build apk --debug   # Android APK
flutter analyze --no-fatal-infos
flutter test
```

### PATH setup (optional)

```bash
export PATH="$HOME/development/flutter/bin:$HOME/Android/Sdk/emulator:$HOME/Android/Sdk/platform-tools:$PATH"
export JAVA_HOME="$HOME/development/jdk-21"   # for Android builds
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
```

## Development

**Database (Drift)** — after changing table schemas under `lib/data`, regenerate code:

```bash
dart run build_runner build
```

**Food seed** — [assets/food_seed.json](assets/food_seed.json): 584 common Mainland China foods, AI-generated and reviewed, 10 fields per entry (calories / protein / carbs / fat / alcohol / fiber / sodium / sugar / saturated fat / calcium, per 100g). [tool/build_food_seed.py](tool/build_food_seed.py) (merges CFCT / Sanotsu / Open Food Facts) is deprecated, kept for historical reference only.

After changes, bump `kFoodSeedVersion` (currently `10`) in [lib/data/repositories/food_repository.dart](lib/data/repositories/food_repository.dart) so existing installs re-sync.

**Localization (l10n)** — strings live in [lib/l10n/app_zh.arb](lib/l10n/app_zh.arb) (Chinese) and [lib/l10n/app_en.arb](lib/l10n/app_en.arb) (English, the template file); generation is configured in [l10n.yaml](l10n.yaml). After editing strings:

```bash
flutter gen-l10n   # or it's triggered automatically by flutter pub get / flutter run
```

## Project Structure

```
lib/
  domain/          # calorie math & domain models
  data/            # database, repositories, native service bridges (steps, reminders)
  providers/       # Riverpod providers
  features/        # newer feature-first structure (currently just loading/)
  l10n/            # localization ARB sources & generated code
  ui/              # screens & widgets
    today/         # today's budget
    meals/         # meal logging
    foods/         # food library
    records/       # weight / workouts / notes
    strategy/      # fat-loss strategies
    tools/         # toolbox, reminder settings
    theme/         # theming & shared UI widgets
    profile/       # profile, "me" tab
    onboarding/    # onboarding
    shell/         # app shell, bottom navigation, etc.
    ink/           # ink-style icons and visual assets
    loading/       # loading / transition screens
    widgets/       # shared widgets
assets/
  food_seed.json   # food seed data
test/              # unit, widget, and screenshot (golden) tests
```

## Testing

```bash
flutter analyze --no-fatal-infos
flutter test
```

`test/` covers domain algorithm unit tests, repository/provider tests, widget tests, and `*_screenshots_test.dart` golden tests guarding key screens' visual consistency. CI ([.github/workflows/ci.yml](.github/workflows/ci.yml)) runs the same checks on every push to `main`/`master` and every PR.

## Downloads / GitHub Release

Get Android APKs from [Releases](../../releases).

| File | Notes |
|------|--------|
| `FitnessPlan-*-android-arm64-v8a.apk` | **Recommended** for most phones |
| `FitnessPlan-*-android.apk` | Universal (larger) |
| `FitnessPlan-*-android-armeabi-v7a.apk` | Older 32-bit ARM |
| `FitnessPlan-*-android-x86_64.apk` | Emulators / x86 |

Rebuild locally (release signing required):

```bash
./tool/create_release_keystore.sh   # first time
./tool/build_release_apk.sh         # analyze + test + release APKs → dist/
# outputs in dist/
```

See [android/key.properties.example](android/key.properties.example). Do not commit `key.properties` or `*.jks`.

### iOS

iOS / IPA can't be built on Linux — needs macOS + Xcode, and distribution usually needs an Apple Developer account (TestFlight / App Store). Releases here are Android-only for now. On a Mac:

```bash
flutter build ipa --release
# output: build/ios/ipa/*.ipa (signing required)
```

## Contributing

Before submitting a PR, run locally (matches CI):

```bash
flutter analyze --no-fatal-infos
flutter test
```

Code style follows `flutter_lints` ([analysis_options.yaml](analysis_options.yaml)), no custom rules.

## Donate

If this project helps you, please [donate via Alipay](docs/donate.md).

## License

Free for personal / non-commercial use. Commercial use requires a paid
license — contact via GitHub Issues. See [LICENSE](LICENSE) for details.
