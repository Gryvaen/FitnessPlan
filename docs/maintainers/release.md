# 发版

这份文档讲怎么发布新版本：一次性的准备工作、一键发版脚本、中途失败后怎么续上，以及 GitHub 和 Gitee 两边的特殊情况。发版前看。

发布的内容是 Android APK，同时发到两个地方：
- GitHub：`Gryvaen/FitnessPlan`（仓库的 `origin`）
- Gitee：`Gryvaen/FitnessPlan`（给中国大陆用户的下载源）

应用内更新会同时读取两边，见 [features.md](features.md#应用内更新)。

## 版本号

`pubspec.yaml` 里的 `version: X.Y.Z+N`：
- `X.Y.Z` 是版本名，也用在 tag（`vX.Y.Z`）、APK 文件名和更新清单里，必须是 `x.y.z` 的形式，不能带后缀。
- `N` 是构建号，即 Android 的 `versionCode`，每次发版加 1。按 ABI 拆分的包，实际的 `versionCode` 还会加上 ABI 前缀（见 [android-native.md](android-native.md#构建配置)）。

`release.sh` 会自动改版本号，你只需要给出新的 `X.Y.Z`。

## 一次性准备

1. **签名文件**：`android/key.properties` 和它指向的 keystore 必须在本机，见下文「签名」。
2. **GitHub**：安装 `gh` 并登录（`gh auth login`），账号要有仓库的推送权限。
3. **Gitee 令牌**：在 Gitee「设置 → 私人令牌」生成一个，勾选 `projects` 权限，然后运行：
   ```bash
   tool/release/release.sh --setup
   ```
   粘贴令牌后回车（输入时屏幕不显示任何内容）。脚本会先验证令牌，再保存到 `~/.config/fitnessplan/gitee_token`，文件权限为 600。也可以改用环境变量 `GITEE_TOKEN`。

## 每次发版

1. 写好发布说明，比如 `notes.md`。格式参考已有的发布（`## 更新`、`## 修复` 这类小标题加列表）。更新弹窗能渲染标题、列表、粗体和行内代码。
2. 确认当前在 `main` 分支，工作区干净，并且和远端同步（`git pull`）。
3. 运行：
   ```bash
   tool/release/release.sh 2.6.2 --notes-file notes.md
   ```

脚本会在上传前自动清理 Gitee 较旧版本的 APK，保留最近 3 个版本（包含本次版本）。旧发布页、源码压缩包及其他附件保留，GitHub 历史附件不受影响。清理失败会停止上传；重复执行只处理仍存在的旧 APK。

脚本依次执行：

| 步骤 | 内容 |
|---|---|
| 检查 | `gh` 已登录、有 Gitee 令牌、在 `main` 上、工作区干净、不落后于 `origin/main` |
| 保存说明 | 把说明复制到 `dist/release-notes-v2.6.2.md`。重跑时必须用完全相同的说明 |
| 改版本 | `pubspec.yaml` 改成 `2.6.2+(N+1)`，提交 `chore(release): 发布 2.6.2`，打附注 tag `v2.6.2` |
| 构建 | 运行 `tool/release/build_release_apk.sh`：分析、测试、构建四个 APK 和清单 |
| 推送 | 把 `main` 和 tag 推到 GitHub 和 Gitee。Gitee 默认走 SSH（`git@gitee.com:Gryvaen/FitnessPlan.git`，用 `~/.ssh/config` 里为 gitee.com 配的专用密钥），因为 Gitee 拒绝用这个账号的令牌做 HTTPS 推送；设置 `RELEASE_GITEE_URL` 为 https 地址时，仍按旧方式通过 `GIT_ASKPASS` 传令牌，令牌不会出现在 URL 里 |
| 发布 | 运行 `publish_release.py`，上传到两边并逐个校验 |

**测试或构建失败时，什么都不会推送出去。**

## 失败后怎么办

直接用同样的命令再跑一次：
- 版本号提交和 tag 已经在 HEAD 上时，跳过这一步；
- 同一个提交已经成功构建过（标记文件 `dist/.built-v2.6.2` 记录了提交号），就复用产物，不重新构建；需要重新构建时加 `--rebuild`；
- 推送和上传都可以重复执行，已经上传且内容相同的文件会跳过。

常见失败：

| 现象 | 原因与处理 |
|---|---|
| `github: FAILED (URLError)` | 网络问题，访问 `api.github.com` 偶尔超时。重跑即可 |
| `gitee: FAILED (API HTTP 400)` | 通常是某个文件超过了 Gitee 的 100 MB 上限。新版脚本会自动跳过超限文件；如果还是失败，按下面「单独使用发布脚本」的方法查看具体错误 |
| `not at the release commit` | 远端分支或 tag 指向的不是这次发布的提交（例如 Gitee 的 `main` 落后了）。先把 `main` 推上去再重跑 |
| `already exists with different text` | 改过发布说明。如果确实要改，就编辑 `dist/release-notes-vX.Y.Z.md`，或者删掉它；但已经发布出去的说明不能再改（脚本拒绝覆盖） |
| `working tree is not clean` | 先提交或暂存手上的改动 |

**不要对已经发布的版本用 `release.sh` 补发。** 如果构建标记丢了，脚本会重新构建，而重新构建出来的 APK 和已上传的不是同一个文件（哈希不同），会和已发布的文件冲突。补发时请用下面的方法，单独调用发布脚本。

## 单独使用发布脚本

```bash
GITHUB_TOKEN="$(gh auth token)" GITEE_TOKEN="$(<~/.config/fitnessplan/gitee_token)" \
  python3 tool/release/publish_release.py --tag v2.6.2 --notes-file dist/release-notes-v2.6.2.md
```

它只上传 `dist/` 里已有的产物，适合补发其中一边。每次运行都会把两边的所有文件下载一遍做校验，需要好几分钟。

排查 Gitee 的具体报错时，可以参考脚本里的 `Platform` 类，在 Python 里单独复现某一个请求。Gitee 的错误信息（JSON 里的 `message`）是中文的，很直观。注意 Gitee 的 GET 请求把令牌放在 URL 里，打印 URL 或异常信息之前要先打码。

## 两个平台的差异

| | GitHub | Gitee |
|---|---|---|
| 目标分支 | `main` | `main`（没有 `master`） |
| 发布流程 | 先建草稿、上传、校验，再公开 | 直接创建 |
| 查询不存在的发布 | 404 | 返回 HTTP 200，内容是 JSON `null` |
| 附件大小上限 | 2 GB | **100 MB**：通用包（约 116 MB）传不上去 |
| 认证 | `Authorization: Bearer` 请求头 | `access_token` 参数（GET 时放在 URL 里） |

Gitee 上缺少通用包没有关系：清单里仍然列着它，应用不会给它生成 Gitee 下载地址。安装了通用包的用户（构建号小于 1000，例如通过 adb 直接安装的）更新时会改下本机 ABI 的分包，分包两个源都有。详见 [features.md](features.md) 的「应用内更新」。

## 签名

- release 构建用 `android/key.properties` 签名；没有这个文件时，Gradle 会**悄悄改用 debug 签名**，构建出来的包无法覆盖安装到用户的设备上。`build_release_apk.sh` 会检查这个文件，缺失时直接报错退出。
- **现状**：已发布的 APK 实际上是用维护机上的 `~/.android/debug.keystore`（别名 `androiddebugkey`）签名的，`key.properties` 就指向它。
- **一定要备份这个 keystore。** 它一旦丢失，以后发布的任何版本都无法覆盖安装，用户只能卸载后重装，并因此丢失数据（除非他们事先导出了备份）。
- 换维护者或换电脑时，需要把这个 keystore 和 `key.properties` 一起安全地拷过去。不要提交进仓库。

## 发布后检查

- GitHub 和 Gitee 的发布页上各有一份发布，说明相同。文件：GitHub 6 个；Gitee 5 个（没有通用包），外加 Gitee 自动生成的源码压缩包。
- 两边的 `main` 和 tag 都指向发布提交：
  ```bash
  git ls-remote origin refs/heads/main refs/tags/v2.6.2
  git ls-remote https://gitee.com/Gryvaen/FitnessPlan.git refs/heads/main 'refs/tags/v2.6.2*'
  ```
- 在一台装着旧版本的手机上，到「我的 → 检查更新」，确认能看到新版本，并且能下载安装。
- 保留好 `dist/symbols/`，以后要用它还原崩溃堆栈。
