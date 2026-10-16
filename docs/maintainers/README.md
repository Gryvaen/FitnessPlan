# 维护者文档

这组文档写给接手 FitnessPlan 的开发者：你熟悉 Flutter，但还不了解这个项目。功能介绍、下载安装和从源码运行，请看仓库根目录的 [README](../../README.md)；这里讲的是怎么改代码、怎么测、怎么发版，以及哪些地方容易踩坑。

## 文档列表

| 文档 | 讲什么 | 什么时候看 |
|---|---|---|
| [setup.md](setup.md) | 开发环境、工具链版本、日常命令、代码生成、真机调试 | 第一天 |
| [architecture.md](architecture.md) | 分层、启动流程、路由、状态管理、主题、多语言 | 第一天 |
| [code-map.md](code-map.md) | `lib/` 和 Android 原生代码的逐文件说明 | 找代码时查 |
| [features.md](features.md) | 业务模块的规则与不变量：饮食策略、碳循环、修仙、步数、提醒、备份、更新 | 改业务逻辑之前 |
| [database.md](database.md) | Drift 表、迁移、食材种子数据 | 改表或改种子数据之前 |
| [android-native.md](android-native.md) | Kotlin 原生层：平台通道、权限、通知、后台可靠性、构建与签名 | 改提醒、计时器、步数、更新下载之前 |
| [testing.md](testing.md) | 测试的组织、写法和命令，以及 CI 的覆盖范围 | 写测试之前 |
| [tools.md](tools.md) | `tool/` 下每个脚本的用途和用法 | 要跑脚本时 |
| [release.md](release.md) | 发版流程、一键脚本、失败后怎么续上 | 发版前 |
| [repo-layout.md](repo-layout.md) | 顶层目录、资源文件、哪些目录不能提交 | 找文件时查 |
| [known-issues.md](known-issues.md) | 已知问题和待办 | 想找活干、或者遇到怪现象时 |

## 新人上手路线

1. 按 [setup.md](setup.md) 装好环境，运行下面四条命令，确认都能通过：
   ```bash
   flutter pub get
   flutter analyze
   flutter test
   flutter run            # 连真机或模拟器
   ```
2. 读 [architecture.md](architecture.md)，再结合 [code-map.md](code-map.md) 在编辑器里把 `lib/main.dart` → `lib/app.dart` → `lib/ui/today/today_page.dart` 走一遍。
3. 动业务逻辑之前，先读 [features.md](features.md) 里的「不变量」小节。像「只能编辑今天的记录」「策略计划不可变」这类规则，是测试守着的，违反了会让测试失败。
4. 第一次发版前，读 [release.md](release.md)。

## 约定

- 提交信息用英文 Conventional Commits（`feat:`、`fix:`、`chore:` 等），可以附中文说明。由 Claude 生成的提交在末尾加 `Co-Authored-By: Claude ...`。
- 新增界面文案一律写进 ARB 文件（见 [architecture.md](architecture.md#多语言)），不要在代码里硬编码中文。
- 提交前至少跑一遍 `flutter analyze` 和 `flutter test`；改了 `tool/release/` 下的脚本，再跑 Python 测试（见 [testing.md](testing.md)）。
