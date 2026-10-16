# 仓库目录

这份文档说明仓库顶层每个目录放什么、哪些需要提交、哪些不能提交。找文件时查。`lib/` 里面的结构见 [code-map.md](code-map.md)。

## 顶层目录

| 目录 / 文件 | 内容 | 是否提交 |
|---|---|---|
| `lib/` | Dart 源代码 | ✅ |
| `test/` | Dart 测试，见 [testing.md](testing.md) | ✅ |
| `android/` | Android 工程与 Kotlin 原生代码，见 [android-native.md](android-native.md) | ✅（`key.properties`、`*.jks` 除外） |
| `ios/` | iOS 工程：Flutter 模板加上 HealthKit 配置（entitlements、`Info.plist` 里的使用说明） | ✅ |
| `macos/`、`linux/`、`windows/`、`web/` | Flutter 模板，基本没有改动 | ✅ |
| `assets/` | 应用内资源，见下文 | ✅ |
| `tool/` | 脚本，见 [tools.md](tools.md) | ✅（`.venv/`、下载缓存除外） |
| `docs/` | 文档 | ✅（`docs/copyright/` 除外） |
| `design/` | 设计素材（约 146 MB） | ✅ |
| `data/` | 本地的个人数据导出（备份文件） | ❌ 已被忽略，**属于个人数据，绝不能提交** |
| `dist/` | 发版产物：APK、清单、符号表、发布说明 | ❌ 已被忽略 |
| `build/` | 构建输出（Android 的构建目录也被重定向到这里） | ❌ 已被忽略 |
| `.github/` | CI（`workflows/ci.yml`）和赞助配置（`FUNDING.yml`） | ✅ |
| `pubspec.yaml` / `pubspec.lock` | 依赖与版本号 | ✅ |
| `l10n.yaml` | 多语言生成配置 | ✅ |
| `analysis_options.yaml` | lint 配置（只引入了 `flutter_lints`） | ✅ |
| `dart_test.yaml` | 测试 tag 配置 | ✅ |
| `README.md` / `README_EN.md` | 面向用户的项目介绍（中文 / 英文，结构相同） | ✅ |

## assets/

`pubspec.yaml` 里声明了以下资源：`food_seed.json`、`cultivation/`、`ink/`、`ink/icons/light/`、`ink/icons/dark/`、`splash/`，以及两个字体。

| 路径 | 内容 |
|---|---|
| `food_seed.json` | 内置食材库（668 条），见 [database.md](database.md#食材种子数据) |
| `cultivation/` | 修仙境界配图（`<境界>_<层>.jpg`）、目标页的背景和卷轴 |
| `ink/` | 水墨笔刷素材 |
| `ink/icons/light/`、`ink/icons/dark/` | ink 图标（各约 100 个，256px PNG），见 [architecture.md](architecture.md#ink-图标) |
| `ink/icons/source/` | 图标的 SVG 源文件（没有在 pubspec 里声明，不会打进应用） |
| `splash/` | 启动动画素材（png 和 webp） |
| `fonts/` | `LXGWWenKaiLite-Medium.ttf`（霞鹜文楷）、`NotoSansSC-Variable.ttf`，以及各自的 OFL 许可证 |
| `branding/` | Logo 和 README 横幅（`readme-banner.svg` 由 `tool/docs/generate_readme_banner.py` 生成） |

**注意**：Android 原生的锁屏闹钟页会直接读取 `fonts/LXGWWenKaiLite-Medium.ttf` 和 `ink/icons/{light,dark}/` 下的几个图标。改名或移动它们之前，先看 [android-native.md](android-native.md#锁屏闹钟页与-flutter-资源的隐性耦合)。

## design/

| 路径 | 内容 |
|---|---|
| `design/display/` | README 里的 5 张截图（今日、食材、训练、身体、我的） |
| `design/ink-ui/` | 今日页的设计稿（v2–v4） |
| `design/goal/{Cut,Maintain,Bulk}/` | 三个目标的背景、卷轴和文案 |
| `design/Quotation/*_Quotation.md` | 激励语的原始文本，对应 `lib/domain/goal_quotes.dart` |

代码和测试里还引用了一个 `design-handoff/` 目录（设计交付材料），但它不在仓库里，见 [known-issues.md](known-issues.md)。

## docs/

| 路径 | 内容 |
|---|---|
| `docs/maintainers/` | 本组维护者文档 |
| `docs/android-emulator.md` | Android 模拟器的配置与常用 adb 命令 |
| `docs/donate.md`、`docs/donate-alipay.jpg` | 赞助页面 |
| `docs/copyright/` | 软著申请材料（生成物和申请说明），已被忽略，只在维护机本地存在 |

## 被 git 忽略、但很重要的本地文件

| 文件 | 说明 |
|---|---|
| `android/key.properties` 及其指向的 keystore | 发版签名，丢失后无法再发可覆盖安装的新版本，见 [release.md](release.md#签名) |
| `~/.config/fitnessplan/gitee_token` | Gitee 发布令牌（不在仓库里） |
| `dist/symbols/` | 混淆符号表，用于还原崩溃堆栈 |
| `tool/.venv/` | 软著脚本用的 Python 虚拟环境 |
| `tool/food_seed/off_*` | Open Food Facts 的下载缓存（约 1.2 GB） |
