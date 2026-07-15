# 健身饮食 / Fitness Plan

[English ↓](#english)
[![Donate / 赞助](https://img.shields.io/badge/Donate-支付宝-1677FF?style=flat&logo=alipay&logoColor=white)](docs/donate.md)

纯本地 Flutter 健身饮食助手：按身体数据计算每日热量与三大营养素，内置常见食材库，支持饮食记账与体重记录。

## 功能

- 录入性别、年龄、身高、体重、活动量与目标（减脂 / 维持 / 增肌）
- Mifflin–St Jeor 算法：BMR → TDEE → 每日热量与碳水 / 蛋白质 / 脂肪
- 约三千八百余条中文名食材营养数据（每 100g）
- 记一笔饮食，自动扣减当日剩余配额
- 按日查看历史饮食与配额（含缺口日历选择）；支持历史日补记
- 体重记录与折线图；减脂平台期提示
- 食材收藏与最近吃过
- 全部数据本地保存，无需登录、无云端

## 技术栈

- **Flutter** + Material Design
- **Riverpod** — 状态管理
- **go_router** — 导航
- **Drift (SQLite)** — 本地数据库
- **fl_chart** — 体重曲线
- **SharedPreferences** — 用户配置

## 要求

- [Flutter](https://docs.flutter.dev/get-started/install) SDK（建议与 `pubspec.yaml` 中的 Dart SDK 约束一致）
- 可选：Android 模拟器 / 真机，或 Linux / macOS / Windows / Web 桌面目标

## 快速开始

```bash
git clone https://github.com/<your-username>/FitnessPlan.git
cd FitnessPlan
flutter pub get
flutter run                 # 自动选择已连接设备
flutter run -d linux        # Linux 桌面调试
flutter build apk --debug   # 打安卓包
flutter test
```

修改 Drift 表结构后需重新生成：

```bash
dart run build_runner build
```

### 食材种子

内置约三千八百余条中文名食材，来源合并见 `tool/build_food_seed.py`（CFCT / Sanotsu / Open Food Facts；最终种子仅含名称带汉字的条目）。

改了 `assets/food_seed.json` 后，需同步提高 [`lib/data/repositories/food_repository.dart`](lib/data/repositories/food_repository.dart) 中的 `kFoodSeedVersion`，否则已安装设备不会重新同步。

重新构建种子（可选）：

```bash
python3 tool/build_food_seed.py
```

### 环境变量示例（可选）

若本机未把 Flutter / Android SDK 写入 PATH，可参考：

```bash
export PATH="$HOME/development/flutter/bin:$HOME/Android/Sdk/emulator:$HOME/Android/Sdk/platform-tools:$PATH"
export JAVA_HOME="$HOME/development/jdk-21"   # 安卓构建用
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
```

请按自己的安装路径调整。

## 项目结构

```
lib/
  domain/          # 热量算法与领域模型
  data/            # Drift DB、仓库
  providers/       # Riverpod providers
  ui/              # 页面与组件
    today/         # 今日配额
    meals/         # 饮食记录
    foods/         # 食材库
    weight/        # 体重
    profile/       # 个人资料
    onboarding/    # 首次引导
assets/
  food_seed.json   # 食材种子数据
test/              # 单元与组件测试
```

## 下载 / GitHub Release

Android APK 可从仓库的 [Releases](../../releases) 下载（仓库发布后生效）。

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

签名配置见 `android/key.properties.example`；`key.properties` 与 `*.jks` 已在 `.gitignore` 中忽略。

### 关于 iOS

当前环境是 **Linux，无法在本机构建 iOS / IPA**（需要 macOS + Xcode）。  
即便打出 IPA，要在别人的 iPhone 上安装通常还需要：

- Apple Developer 账号（年费）做签名，或
- 通过 TestFlight / App Store 分发

因此 GitHub Release 目前以 **Android APK** 为主；有 Mac 时可在本机执行：

```bash
flutter build ipa --release
# 产物：build/ios/ipa/*.ipa（需配置签名）
```

## 赞助 / Donate

如果这个项目对你有帮助，欢迎 [支付宝赞助](docs/donate.md)。

## 许可证

本项目采用 [MIT License](LICENSE)。

---

<a id="english"></a>

# English

[← 中文](#健身饮食--fitness-plan)
[![Donate](https://img.shields.io/badge/Donate-Alipay-1677FF?style=flat&logo=alipay&logoColor=white)](docs/donate.md)

A fully offline Flutter fitness & nutrition app. It calculates daily calorie and macro targets from your body stats, ships with a built-in food database, and lets you log meals and weight — all stored on device.

## Features

- Enter sex, age, height, weight, activity level, and goal (cut / maintain / bulk)
- Mifflin–St Jeor: BMR → TDEE → daily calories and carbs / protein / fat
- ~3800+ Chinese-named foods with nutrition data (per 100g)
- Log meals and automatically deduct from today’s remaining budget
- Browse past days’ meals and budgets (with a deficit date picker); backfill past days
- Weight logs with a line chart; plateau hints when cutting
- Food favorites & recently eaten
- Fully local storage — no accounts, no cloud

## Tech Stack

- **Flutter** + Material Design
- **Riverpod** — state management
- **go_router** — navigation
- **Drift (SQLite)** — local database
- **fl_chart** — weight charts
- **SharedPreferences** — profile settings

## Requirements

- [Flutter](https://docs.flutter.dev/get-started/install) SDK (match the Dart SDK constraint in `pubspec.yaml`)
- Optional: Android emulator / device, or Linux / macOS / Windows / Web targets

## Quick Start

```bash
git clone https://github.com/<your-username>/FitnessPlan.git
cd FitnessPlan
flutter pub get
flutter run                 # pick a connected device
flutter run -d linux        # Linux desktop
flutter build apk --debug   # Android APK
flutter test
```

After changing Drift schemas, regenerate code:

```bash
dart run build_runner build
```

### Food seed

The bundled library has ~3800+ Chinese-named foods. Rebuild pipeline: `tool/build_food_seed.py` (Han names only).

After changing `assets/food_seed.json`, bump `kFoodSeedVersion` in
`lib/data/repositories/food_repository.dart` so existing installs re-sync.

### Example PATH setup (optional)

```bash
export PATH="$HOME/development/flutter/bin:$HOME/Android/Sdk/emulator:$HOME/Android/Sdk/platform-tools:$PATH"
export JAVA_HOME="$HOME/development/jdk-21"   # for Android builds
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
```

Adjust paths to match your machine.

## Project Structure

```
lib/
  domain/          # calorie math & domain models
  data/            # database & repositories
  providers/       # Riverpod providers
  ui/              # screens & widgets
    today/         # today’s budget
    meals/         # meal logging
    foods/         # food library
    weight/        # weight
    profile/       # profile
    onboarding/    # onboarding
assets/
  food_seed.json   # food seed data
test/              # unit & widget tests
```

## Downloads / GitHub Release

Get Android APKs from [Releases](../../releases) once the repo is published.

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

See `android/key.properties.example`. Do not commit `key.properties` or `*.jks`.

### iOS

**iOS / IPA cannot be built on Linux** — you need macOS + Xcode. Distributing an IPA usually also requires an Apple Developer account (TestFlight / App Store / Ad Hoc signing). GitHub Releases for this project focus on **Android APKs**. On a Mac:

```bash
flutter build ipa --release
# output: build/ios/ipa/*.ipa (signing required)
```

## Donate

If this project helps you, please [donate via Alipay](docs/donate.md).

## License

Released under the [MIT License](LICENSE).

