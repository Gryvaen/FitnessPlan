# Android 模拟器

本文说明在 Linux 开发环境下如何选择合适的 Android 模拟器，以及如何运行 / 打开 FitnessPlan 应用。

## 一、一键启动（直接复制）

本机日常推荐使用 **Pixel_9_API_36_Play**（x86_64 + Google Play）。

先确保 PATH（当前终端执行一次即可）：

```bash
export PATH="$HOME/development/flutter/bin:$HOME/Android/Sdk/emulator:$HOME/Android/Sdk/platform-tools:$PATH"
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
```

启动模拟器（任选一种）：

```bash
# 推荐：带 Google Play 的 Pixel 9
emulator -avd Pixel_9_API_36_Play &

# 备选：Pixel 8 API 35
# emulator -avd Pixel_8_API_35 &
```

等模拟器开机后，运行应用：

```bash
cd /path/to/FitnessPlan
flutter pub get
flutter run
```

### 只调开屏 UI（循环预览，不进首页）

```bash
flutter run --dart-define=LOADING_LAB=true
```

启动后停在开屏第一帧（进度 0%），和正式冷启动解开原生开屏后画出的第一帧一致。点播放再往后走。

底部面板：

- 滑条：拖动定格到任意进度（0–100%）
- 暂停 / 播放：定格当前帧或从第一帧继续播
- 循环开关 / 从头重播

改 Dart 布局用热重载 `r`；改 shader / 图片资源用热重启 `R`（不必退出进程）。

或用 Flutter 启动模拟器：

```bash
flutter emulators --launch Pixel_9_API_36_Play
```

查看已有模拟器：

```bash
emulator -list-avds
# 当前本机：
#   Pixel_8_API_35
#   Pixel_9_API_36_Play
```

## 二、怎么选择合适的模拟器

在项目目录执行：

```bash
flutter devices
```

常见设备类型：

| 设备 | 适合场景 |
|------|----------|
| `sdk gphone64 x86 64` / 其他 emulator | 日常调试 Android UI（Linux 主机应选 **x86_64**） |
| 真机（USB 调试已开启） | 更接近真实体验 |
| `linux` | 本机桌面调试，可不使用模拟器 |

### 模拟器选型建议

- 架构：本机是 x86 / x86_64 → 选择 **x86_64** AVD（不要选 arm64，会很慢）
- 系统：API 33–36 均可；带 Google Play 的镜像更方便安装扩展
- 内存：建议至少为模拟器分配 2GB RAM
- 若安装已下载的 APK 到模拟器，请使用 README 中的 `*-android-x86_64.apk`

### 创建与启动 AVD

方式一：Android Studio → Device Manager → Create Device。

方式二：命令行：

```bash
emulator -list-avds          # 查看已有模拟器名称
emulator -avd <名字> &       # 启动指定模拟器
```

## 三、怎么打开软件

### 方式 A：开发模式运行（推荐）

1. 先启动模拟器（或连接真机），然后执行：

```bash
cd /path/to/FitnessPlan
flutter pub get
flutter run                  # 仅一台设备时自动选择
```

2. 多台设备时指定设备：

```bash
flutter devices
flutter run -d emulator-5554   # 使用 devices 列表中的 id
flutter run -d linux           # 不使用模拟器，运行桌面版
```

### 方式 B：安装已打包的 APK（模拟器）

请使用 x86_64 架构的 APK：

```bash
adb install dist/FitnessPlan-*-android-x86_64.apk
```

## 四、与模拟器交互

窗口右侧工具栏：返回、主页、最近任务、旋转、音量、截图。下面这些命令做同一类事，适合脚本和把图存进仓库。

先看连上了哪台。多台设备时，把后面的命令加上 `-s emulator-5554`（序列号以 `adb devices` 为准）。

```bash
adb devices
```

截当前屏幕到本机：

```bash
adb exec-out screencap -p > screenshot.png
```

录屏。默认最长约 3 分钟，在终端按 Ctrl+C 结束，再拉回本机：

```bash
adb shell screenrecord /sdcard/demo.mp4
adb pull /sdcard/demo.mp4
```

覆盖安装、卸载、打开本应用（包名 `com.fitnessplan.fitness_plan`）：

```bash
adb install -r dist/FitnessPlan-*-android-x86_64.apk
adb uninstall com.fitnessplan.fitness_plan
adb shell am start -n com.fitnessplan.fitness_plan/.MainActivity
```

按键与触控。坐标是屏幕像素，左上角为原点：

```bash
adb shell input keyevent KEYCODE_BACK
adb shell input keyevent KEYCODE_HOME
adb shell input keyevent KEYCODE_POWER
adb shell input keyevent KEYCODE_APP_SWITCH
adb shell input tap 540 1200
adb shell input swipe 540 1600 540 600 300
```

看日志，关掉模拟器：

```bash
adb logcat
adb emu kill
```

`flutter run` 还附着在这个终端时：`r` 热重载，`R` 热重启，`q` 退出。

## 五、环境变量（可选）

若本机未把 Flutter / Android SDK 写入 PATH，可参考（按实际安装路径调整）：

```bash
export PATH="$HOME/development/flutter/bin:$HOME/Android/Sdk/emulator:$HOME/Android/Sdk/platform-tools:$PATH"
export JAVA_HOME="$HOME/development/jdk-21"
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
```

## 六、常见问题

若 `flutter run` 已连上模拟器但编译失败，需先修复代码错误后再重新运行。确认 `flutter devices` 能看到目标设备后，再执行 `flutter run`。
