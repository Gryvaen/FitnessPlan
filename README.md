# 健身饮食 (Fitness Plan)

纯本地 Flutter App：按身体数据计算每日热量与三大营养素，内置常见食材库，支持饮食记账与体重记录。

## 功能

- 录入性别/年龄/身高/体重、活动量与目标（减脂/维持/增肌）
- Mifflin-St Jeor 算法计算 BMR → TDEE → 每日热量与碳/蛋/脂
- 100+ 常见食材营养数据（每 100g）
- 记一笔饮食，自动扣减今日剩余配额
- 体重记录与折线图
- 数据全部保存在手机本地，无需登录

## 环境

建议将 Flutter / Android SDK 加入 PATH：

```bash
export PATH="$HOME/development/flutter/bin:$HOME/Android/Sdk/emulator:$HOME/Android/Sdk/platform-tools:$PATH"
export JAVA_HOME="$HOME/development/jdk-21"   # 安卓构建用
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
```

## 安卓模拟器

本机已配置虚拟机：

| 名称 | 系统 | 说明 |
|------|------|------|
| `Pixel_9_API_36_Play` | Android 16 / API 36 | **推荐**：带 Google Play，可从商店更新 YouTube |
| `Pixel_8_API_35` | Android 15 / API 35 | 仅 Google APIs，无 Play 商店 |

> 想用最新 YouTube，请用带 `Play` 的那台；首次开机后打开 **Play 商店**登录 Google 账号，搜索 YouTube 安装/更新。

### 启动模拟器（推荐：带 Play 商店）

```bash
emulator -avd Pixel_9_API_36_Play &
```

或冷启动（跳过快照，启动更稳）：

```bash
emulator -avd Pixel_9_API_36_Play -no-snapshot-load &
```

旧版（无 Play）：

```bash
emulator -avd Pixel_8_API_35 &
```

也可用：

```bash
flutter emulators --launch Pixel_9_API_36_Play
```

等待开机完成（约几十秒到一两分钟），确认：

```bash
adb devices
# 应看到 emulator-5554   device
```

### 在模拟器上运行 App

```bash
cd ~/projs/FitnessPlan
flutter run -d emulator-5554
```

若只有一台设备/模拟器在线，也可直接：

```bash
flutter run
```

热重载按 `r`，退出按 `q`。

### 关闭模拟器

在模拟器窗口点关闭，或：

```bash
adb -s emulator-5554 emu kill
```

## 运行

```bash
cd ~/projs/FitnessPlan
flutter pub get
flutter run                 # 自动选已连接设备/模拟器
flutter run -d linux        # Linux 桌面调试
flutter build apk --debug   # 打安卓包
flutter test
```

修改 Drift 表结构后需重新生成：

```bash
dart run build_runner build
```
