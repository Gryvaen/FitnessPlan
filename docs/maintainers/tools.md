# 工具脚本（tool/）

这份文档逐个说明 `tool/` 下的脚本：用途、前置条件、怎么运行、产出什么。要跑脚本时看。发版的完整流程另见 [release.md](release.md)。

所有命令都在仓库根目录执行。

| 目录 | 内容 |
|---|---|
| `tool/release/` | 构建、签名、发布 |
| `tool/copyright/` | 软件著作权（软著）申请材料的生成 |
| `tool/docs/` | README 横幅图、设计交付截图 |
| `tool/food_seed/` | 食材种子数据的原始构建管线（已过时，见下文） |

## Python 环境

- `tool/release/` 和 `tool/food_seed/` 只用 Python 标准库，直接用系统的 `python3` 运行。
- `tool/copyright/` 需要第三方库，使用本地虚拟环境 `tool/.venv/`（不提交；仓库也没有 requirements 文件）。重建方法：
  ```bash
  python3 -m venv tool/.venv
  tool/.venv/bin/pip install python-docx reportlab
  ```
- `tool/docs/generate_readme_banner.py` 需要 `art` 库：`pip install art`。

## tool/release/

### release.sh：一键发版

```bash
tool/release/release.sh --setup                          # 只需一次：保存 Gitee 令牌
tool/release/release.sh 2.6.2 --notes-file notes.md      # 每次发版
```

完整说明见 [release.md](release.md)。可选参数：`--rebuild`（强制重新构建）、`-h`。

### build_release_apk.sh：构建正式包

```bash
./tool/release/build_release_apk.sh
```

- **前置条件**：`android/key.properties` 和它指向的 keystore（见 [release.md](release.md#签名)）；`flutter pub get` 已经执行过。
- **执行步骤**：`flutter analyze --no-fatal-infos` → `flutter test --exclude-tags=copyright` → 预下载 sqlite3 原生库 → 按 ABI 拆分构建 → 构建通用包 → 生成清单。构建都加了 `--obfuscate --split-debug-info=dist/symbols`。
- **产出**（在 `dist/`，已被 git 忽略）：
  - `FitnessPlan-<版本>-android.apk`（通用包）、`-android-arm64-v8a.apk`、`-android-armeabi-v7a.apk`、`-android-x86_64.apk`
  - `update-manifest.json`、`SHA256SUMS`
  - `symbols/`（还原崩溃堆栈用，要保留）

### build_test_apk.sh：快速测试包

```bash
./tool/release/build_test_apk.sh              # 只打 arm64-v8a，体积小，适合大多数手机
./tool/release/build_test_apk.sh --universal  # 通用包
```

- 跳过分析、测试和混淆，只求快。
- 有 `key.properties` 时用正式签名，否则用 debug 签名。注意：debug 签名的包不能覆盖安装到正式包上。
- 未设置 `JAVA_HOME` 时，会自动使用 `/usr/lib/jvm/java-21-openjdk`。
- 产出：`dist/FitnessPlan-<版本>-<短提交号>[-dirty]-test-android[-arm64-v8a].apk`。

### create_release_keystore.sh：生成签名密钥

```bash
./tool/release/create_release_keystore.sh
```

- 需要 JDK 的 `keytool`。只问一次密码，同时用作 store 和 key 的密码。
- 生成 `android/upload-keystore.jks`（RSA 2048、有效期 10000 天、别名 `fitnessplan`）和 `android/key.properties`，权限都是 600。
- 两个文件已经存在时会中止。
- ⚠️ **对已经发布的应用，不要用它换密钥。** 换了密钥的新包无法覆盖安装到老用户的设备上。现有的签名情况见 [release.md](release.md#签名)。

### prefetch_sqlite3_android_libs.sh：预下载 sqlite3 原生库

不能单独运行，由两个构建脚本 `source` 后调用。

- 为什么需要它：`package:sqlite3` 用 Dart 的 HttpClient 下载预编译的 `.so` 文件，在部分网络环境下会 TLS 握手失败，而 curl 通常没问题。
- 做了什么：从 `pubspec.lock` 读出 sqlite3 的版本，用 curl 把各 ABI 的 `libsqlite3.so` 下载到 `tool/release/sqlite3_mirror/`（已被 git 忽略），校验 sha256 后放进 `.dart_tool/hooks_runner/` 的缓存目录。
- 需要 curl、sha256sum、awk；第一次运行需要联网。

### release_manifest.py：生成更新清单

```bash
python3 tool/release/release_manifest.py --dist dist --version 2.6.2
```

由 `build_release_apk.sh` 自动调用。它要求 `dist/` 里恰好有该版本的四个 APK 且都不为空，然后生成：
- `update-manifest.json`：`{schemaVersion: 1, version, assets: [{name, size, sha256}]}`，内容是确定性的，同样的输入总是得到同样的文件；
- `SHA256SUMS`。

### publish_release.py：发布到 GitHub 和 Gitee

```bash
GITHUB_TOKEN="$(gh auth token)" GITEE_TOKEN="$(<~/.config/fitnessplan/gitee_token)" \
  python3 tool/release/publish_release.py --tag v2.6.2 --notes-file dist/release-notes-v2.6.2.md
```

只上传已经构建好的产物，不会重新构建。一般由 `release.sh` 调用，单独使用的场景见 [release.md](release.md#单独使用发布脚本)。

- 参数：`--tag`、`--notes-file`（必填）；`--dist`（默认 `dist`）、`--github-repo`、`--gitee-repo`、`--github-target`、`--gitee-target`（两个目标分支默认都是 `main`）。
- 行为要点：
  - 上传前校验本地产物：tag 和清单版本一致、四个 APK 齐全、大小和哈希与 `SHA256SUMS` 一致。
  - 创建发布前，用 `git ls-remote` 确认远端的 tag（或目标分支头）就是本地 tag 指向的提交。
  - 已存在且内容相同的文件跳过；同名但内容不同、或者发布说明不同时，停止并报错，**绝不覆盖**。
  - 清单最后上传。
  - Gitee 单个附件上限 100 MB，超过的文件（通用包）在 Gitee 上跳过，并打印提示。
  - 最后从公开地址把每个文件下载下来校验。两边加起来要下载约 600 MB，所以一次运行需要好几分钟。
  - 令牌不会打印出来。任何一边失败，退出码都是 1；直接用原命令重跑即可。

### test_publish_release.py：发布脚本的测试

```bash
python3 -m unittest discover -s tool/release -p 'test_*.py'
```

13 个离线测试，不需要网络和令牌。改了 `publish_release.py` 或 `release_manifest.py` 后必须跑。

## tool/copyright/：软著材料

所有产物都输出到 `docs/copyright/`，这个目录被 git 忽略。申请步骤说明在 `docs/copyright/申请步骤.md`（同样只在本地）。

| 脚本 | 作用 | 产出 |
|---|---|---|
| `generate_copyright_screenshots.sh` | 用 golden 测试生成 12 张界面截图（`test/copyright_screenshots_test.dart`） | `docs/copyright/screenshots/*.png` |
| `generate_copyright_manual_pdf.sh` | 用 reportlab 生成说明书 PDF，嵌入上面的 12 张截图 | `docs/copyright/健身饮食管理助手软件V1.0-说明书.pdf` |
| `generate_copyright_manual_docx.sh` | 用 python-docx 生成说明书 Word 版 | `docs/copyright/健身饮食管理助手软件V1.0-说明书.docx` |
| `generate_copyright_source_pdf.py` | 源代码材料：`lib/` 下有效代码行的前 30 页和后 30 页，每页 50 行，跳过生成文件、空行和注释 | `docs/copyright/健身饮食管理助手软件V1.0-源代码.pdf` |

```bash
./tool/copyright/generate_copyright_screenshots.sh
./tool/copyright/generate_copyright_manual_pdf.sh
tool/.venv/bin/python tool/copyright/generate_copyright_source_pdf.py
```

注意：Word 版脚本读取的 `docs/display/*.jpg` 目录并不存在，生成的文档里会出现「图片缺失」占位，见 [known-issues.md](known-issues.md)。

## tool/docs/

| 脚本 | 作用 |
|---|---|
| `generate_readme_banner.py` | 用 `art` 库的 ASCII 字体把「Fitness Plan」画成 SVG，带渐变和深色模式变体，输出到 `assets/branding/readme-banner.svg`（README 顶部的横幅）。运行：`python3 tool/docs/generate_readme_banner.py` |
| `generate_implementation_preview.sh` | 用 golden 测试（`test/implementation_preview_test.dart`）截取中英文核心页面和各个主题，输出到 `design-handoff/implementation-preview/`，用于设计交付。这个目录没有被 git 忽略，生成后注意不要误提交 |

## tool/food_seed/

最初用来生成 `assets/food_seed.json` 的管线。**现在的种子文件已经改为手工维护**，这个脚本的输出缺少 `name_en` 和多项微量营养素，直接运行会覆盖掉手工内容，还会让 `test/food_seed_sync_test.dart` 失败。修改种子数据请按 [database.md](database.md#修改种子数据的步骤) 的步骤直接编辑 JSON。

保留这个脚本，是为了以后需要批量导入新数据源时参考。它的数据来源：
1. `tool/food_seed/data2026.csv`：中国食物成分数据（cn-food-mcp，MIT 许可）。**必需，但已在提交 `1859110` 中删除**，需要时从该提交之前的历史里恢复：`git show 1859110^:tool/data2026.csv > tool/food_seed/data2026.csv`。
2. `tool/food_seed/sanotsu_json/`：Sanotsu 对《中国食物成分表》第 6 版的 OCR 结果，共 75 个 JSON 文件（已提交）。
3. Open Food Facts（ODbL 许可）：默认下载约 1.2 GB 的完整数据转储，筛选出中文名称的商品。下载文件和缓存都被 git 忽略。

```bash
python3 tool/food_seed/build_food_seed.py --offline   # 只用 CSV、Sanotsu 和已有的缓存，不联网
python3 tool/food_seed/build_food_seed.py             # 下载 OFF 数据转储（约 1.2 GB）
python3 tool/food_seed/download_resumable.py <url> -o <文件> -c 8   # 多连接断点续传下载，被上面的脚本调用
```

名称冲突时的优先级：Open Food Facts < Sanotsu < CSV。
