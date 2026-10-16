<div align="center">
<a id="top"></a>

<img src="./assets/branding/fitness-plan-logo.png" width="88" alt="Fitness Plan 图标">

<img src="./assets/branding/readme-banner.svg" width="560" alt="Fitness Plan">

<p>
  <strong>Your offline fitness & nutrition companion.</strong><br>
  本地记录饮食、训练与身体数据。减脂时，把热量缺口变成修仙境界。
</p>

<p>
  <a href="https://github.com/Gryvaen/FitnessPlan/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/Gryvaen/FitnessPlan/ci.yml?branch=main&style=flat-square&label=CI" alt="CI"></a>
  <a href="https://github.com/Gryvaen/FitnessPlan/releases"><img src="https://img.shields.io/github/v/release/Gryvaen/FitnessPlan?include_prereleases&style=flat-square&color=0F6E6B" alt="Release"></a>
  <img src="https://img.shields.io/badge/platform-Android-0F6E6B?style=flat-square&logo=android&logoColor=white" alt="Platform: Android">
  <img src="https://img.shields.io/badge/Flutter-Dart%20%5E3.12.2-0F6E6B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Personal%20Free%20%2F%20Commercial%20Paid-0F6E6B?style=flat-square" alt="License"></a>
</p>

<p>
  <a href="#功能">功能</a> ·
  <a href="#修仙境界">修仙境界</a> ·
  <a href="#下载安装">下载</a> ·
  <a href="#从源码运行">从源码运行</a> ·
  <a href="#开发">开发</a>
  &nbsp;|&nbsp;
  <b>中文</b> · <a href="./README_EN.md">English</a>
</p>

<table>
  <tr>
    <td align="center"><img src="./design/display/today.png" width="150" alt="今日：剩余热量、营养素、饮水与训练"><br><sub><b>今日</b></sub></td>
    <td align="center"><img src="./design/display/food.png" width="150" alt="食材分类"><br><sub><b>食材</b></sub></td>
    <td align="center"><img src="./design/display/exercise.png" width="150" alt="动作库"><br><sub><b>训练</b></sub></td>
    <td align="center"><img src="./design/display/body.png" width="150" alt="体重曲线"><br><sub><b>身体</b></sub></td>
    <td align="center"><img src="./design/display/me.png" width="150" alt="我的：修仙境界、档案与工具"><br><sub><b>我的</b></sub></td>
  </tr>
</table>

</div>

## 为什么是 Fitness Plan

健身记录应该留在你自己的设备上。

它按身体数据算出每天的热量和营养素，用一份本地食材库记账，并把体重和训练一起留下。没有账号，也没有云端。

## 功能

<table>
  <tr>
    <td width="50%" valign="top">
      <h3>🍚 饮食</h3>
      Mifflin–St Jeor 算出基础代谢、每日消耗，以及蛋白质、碳水和脂肪。内置 637 条中国大陆常见食材，18 个分类，每 100 克 10 项营养素。记一笔，当天剩余配额就减下去，饮水也记在同一天。
    </td>
    <td width="50%" valign="top">
      <h3>🏋️ 训练</h3>
      动作库、训练计划、组数和次数。今天练什么、做了几组，都写在本机。
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <h3>📈 身体</h3>
      体重曲线、体脂百分比，以及最近几次体重几乎不动时的平台期提示。步数来自 Health Connect / HealthKit；安卓没有权限时，回退到手机传感器。
    </td>
    <td width="50%" valign="top">
      <h3>☯️ 修仙</h3>
      减脂时，累计的热量缺口会变成境界，而不只是一行越来越小的数字。
    </td>
  </tr>
</table>

## 修仙境界

减脂不该只剩下表格。

<div align="center">
<table>
  <tr>
    <td align="center"><img src="./assets/cultivation/lianqi_1.jpg" width="100" alt="练气"><br><b>练气</b></td>
    <td align="center">→</td>
    <td align="center"><img src="./assets/cultivation/zhuji_1.jpg" width="100" alt="筑基"><br><b>筑基</b></td>
    <td align="center">→</td>
    <td align="center"><img src="./assets/cultivation/jiedan_1.jpg" width="100" alt="结丹"><br><b>结丹</b></td>
    <td align="center">→</td>
    <td align="center"><img src="./assets/cultivation/yuanying_1.jpg" width="100" alt="元婴"><br><b>元婴</b></td>
    <td align="center">→</td>
    <td align="center"><img src="./assets/cultivation/huashen.jpg" width="100" alt="化神"><br><b>化神</b></td>
  </tr>
</table>

<b>7,700 kcal → 1 kg</b>
</div>

这套境界只在减脂目标下完整可用。增肌和维持能打开入口，里面仍是占位。

日历中可标记放纵日或休息日；新标记正常计入步数和饮食修行贡献，放纵日可选择扣减 kcal。旧标记在重新编辑前保留原有修行规则。休息日可逐日选择是否延后碳循环。

> [!NOTE]
> 均衡、碳水循环和碳水递减会按日给出目标。这些数字是给一般健康成年人的自助估算，不是临床处方。

## 数据留在本地

<div align="center">
<table>
  <tr>
    <td align="center">🔐<br><b>不登录</b></td>
    <td align="center">📴<br><b>不上云</b></td>
    <td align="center">🚫<br><b>不追踪</b></td>
    <td align="center">💾<br><b>Drift → SQLite</b></td>
  </tr>
</table>
</div>

饮食、体重、训练和偏好都在这台设备上，可以导出，也可以再导入。训练、饮水、饮食和称重可以各自提醒。界面有中文和英文，以及浅色、石墨灰两套主题。

## 下载安装

从 [GitHub Releases](https://github.com/Gryvaen/FitnessPlan/releases) 或 [Gitee Releases](https://gitee.com/Gryvaen/FitnessPlan/releases) 下载 APK，大陆网络可优先尝试 Gitee。大多数真机用 `FitnessPlan-*-android-arm64-v8a.apk`。

旧版若无法访问 GitHub，请手动下载安装支持双源更新的版本；以后可在更新弹窗选择自动、Gitee 或 GitHub。

下载沿用 Android 系统服务，退出 App 后继续；自动换源在 App 运行或恢复后执行。前台安装与后台安装通知均须通过大小和 SHA-256 校验。摘要用于检查文件一致性，不代替 Android 的 APK 签名验证。

## 从源码运行

需要与 `pubspec.yaml` 里 Dart SDK `^3.12.2` 匹配的 [Flutter](https://docs.flutter.dev/get-started/install)。

```bash
git clone https://github.com/Gryvaen/FitnessPlan.git
cd FitnessPlan
flutter pub get
flutter run
```

第一次打开，填写性别、年龄、身高、体重、活动量，以及目标：减脂、维持或增肌。

## 架构

热量、减脂策略、平台期和修仙进度在 `lib/domain/`，不依赖 Flutter。页面经 Riverpod 读写仓库，仓库再落到数据库或系统能力。

```mermaid
flowchart LR
  UI["lib/ui<br/>今日 · 食材 · 记录 · 我的"] --> P["lib/providers"]
  UI --> D["lib/domain<br/>热量 · 策略 · 境界"]
  P --> D
  P --> R["lib/data<br/>repositories"]
  R --> DB[("Drift / SQLite")]
  R --> N["步数 · 本地通知 · 应用更新"]
```

安卓会在启动和回到前台时静默查看 GitHub Release。桌面和 Web 没有健康存储，步数会标成不支持。

## 技术栈

| 组件 | 版本 | 用途 |
| --- | --- | --- |
| Flutter / Dart | `^3.12.2` | 跨平台 UI；正文字体是霞鹜文楷与思源黑体 |
| flutter_riverpod | `^3.3.2` | 状态管理 |
| go_router | `^17.3.0` | 路由 |
| drift | `^2.34.2` | 本地 SQLite |
| health | `^13.3.1` | 步数 |
| flutter_local_notifications | `^22.0.1` | 本地提醒 |
| fl_chart | `^1.2.0` | 体重图表 |

底部导航和大部分页面使用 `assets/ink/` 里的水墨图标。

## 项目结构

```text
FitnessPlan/
├── lib/
│   ├── domain/          # 热量、策略、境界
│   ├── data/            # Drift、仓库、步数与提醒
│   ├── providers/
│   ├── ui/              # 今日、食材、记录、我的
│   └── l10n/
├── assets/
│   ├── food_seed.json   # 637 条食材
│   ├── branding/
│   ├── cultivation/     # 境界原画
│   └── ink/
├── test/
├── tool/                # 发布脚本
└── android/ ios/ linux/ macos/ windows/ web/
```

## 开发

改表结构之后：

```bash
dart run build_runner build
```

改 [lib/l10n/app_zh.arb](lib/l10n/app_zh.arb) 或模板 [lib/l10n/app_en.arb](lib/l10n/app_en.arb) 之后执行 `flutter gen-l10n`。`flutter pub get` 也会生成。

改 [assets/food_seed.json](assets/food_seed.json) 后，把 [lib/data/repositories/food_repository.dart](lib/data/repositories/food_repository.dart) 里的 `kFoodSeedVersion` 加一（当前 `13`），已安装的设备才会重新同步。

提交前：

```bash
flutter analyze --no-fatal-infos
flutter test
```

### 构建

正式 Android 包（需签名，不要提交 `key.properties` 或 `*.jks`）：

```bash
./tool/release/build_release_apk.sh
```

示例见 [android/key.properties.example](android/key.properties.example)。iOS 需要 macOS 与 Xcode：

```bash
flutter build ipa --release
```

当前 Release 只有 Android APK。Linux 模拟器见 [docs/android-emulator.md](docs/android-emulator.md)。

### 发布（维护者）

<details>
<summary>双源发布到 GitHub 与 Gitee</summary>

<br>

本地发布（Python 3，无额外依赖）：

```bash
./tool/release/build_release_apk.sh
# 在本地环境中配置 GITHUB_TOKEN、GITEE_TOKEN，勿写入仓库或命令历史。
python3 tool/release/publish_release.py --tag vX.Y.Z --notes-file /path/to/release-notes.md
```

构建脚本生成四种 APK、`SHA256SUMS` 和 `update-manifest.json`。发布脚本上传同一批文件到两边，最后上传清单；验证公开下载内容后报告结果。部分失败可用原命令重试，一致附件跳过，同名不同内容停止，禁止自动覆盖。从 2.6.1 起每个版本都必须带清单；2.6.0 及更早的版本没有清单，仅从 GitHub 获取，并用 GitHub 提供的附件大小与 SHA-256 校验。

默认目标为 GitHub `Gryvaen/FitnessPlan`（main）和 Gitee `Gryvaen/FitnessPlan`（master）；可用 `--github-repo`、`--gitee-repo`、`--github-target`、`--gitee-target` 显式覆盖。发布前核对目标仓库和分支；脚本不负责同步源代码，目标提交须已存在。

</details>

## 路线图

- [x] 减脂修仙：练气 → 筑基 → 结丹 → 元婴 → 化神
- [x] 本地饮食、训练、身体记录，以及 Android Release
- [ ] 增肌、维持的境界玩法（入口在，内容仍是占位）

## 贡献

与 CI 相同：`flutter analyze --no-fatal-infos` 和 `flutter test`。CI 配置在 [`.github/workflows/ci.yml`](.github/workflows/ci.yml)，风格见 [analysis_options.yaml](analysis_options.yaml)。

## 赞助

如果这个项目有用，可以 [用支付宝赞助](docs/donate.md)。

## 许可证

个人、教育和其它非商业用途免费。商业使用需要另行授权，请通过 GitHub Issues 联系。详见 [LICENSE](LICENSE)。

<div align="center">
<br>
<sub>Made with Flutter · <a href="#top">回到顶部 ↑</a></sub>
</div>
