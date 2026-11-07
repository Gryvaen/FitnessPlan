"""Single source of the user-manual text, rendered by both the PDF and DOCX builders."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from copyright_meta import FULL_NAME, OUT_DIR, ROOT, SOFTWARE_NAME, VERSION
from PIL import Image as PILImage

DISPLAY_DIR = ROOT / "design" / "display"
PREPARED_DIR = OUT_DIR / ".build"


@dataclass(frozen=True)
class Shot:
    filename: str
    caption: str
    # (left, top, right, bottom) in source pixels; drops the app version string,
    # which would contradict the registered version number.
    crop: tuple[int, int, int, int] | None = None


SHOTS = {
    "today": Shot("today.png", "图 5-1 今日页：当日热量进度、三大营养素与饮水、今日训练"),
    "foods": Shot("food.png", "图 6-1 食材库：搜索框与按分类浏览"),
    "train": Shot("exercise.png", "图 8-1 记录 → 训练：动作库列表"),
    "body": Shot("body.png", "图 9-1 记录 → 身体：体重折线图与每日记录"),
    "profile": Shot(
        "me.png",
        "图 11-1 「我的」页：档案、营养目标、提醒与工具箱入口",
        crop=(0, 290, 1080, 1580),
    ),
}


def prepared_image(key: str) -> Path:
    shot = SHOTS[key]
    src = DISPLAY_DIR / shot.filename
    if not src.exists():
        raise FileNotFoundError(f"缺少截图 {src}")
    if shot.crop is None:
        return src
    PREPARED_DIR.mkdir(parents=True, exist_ok=True)
    out = PREPARED_DIR / f"{key}.png"
    with PILImage.open(src) as img:
        img.crop(shot.crop).save(out)
    return out


def image_aspect(path: Path) -> float:
    with PILImage.open(path) as img:
        return img.height / img.width


# Blocks: ("h1", text) ("h2", text) ("p", text) ("ul", [items]) ("img", key) ("break",)
BODY: list[tuple] = [
    ("h1", "1. 软件概述"),
    (
        "p",
        f"{SOFTWARE_NAME}（版本号 {VERSION}）是一款面向健身与减脂人群的纯本地饮食与训练管理 Android 应用。"
        "本文档介绍软件的运行环境、系统架构、主要功能与操作流程。"
        "软件无需注册登录，所有业务数据保存在设备本地，核心功能可离线使用。",
    ),
    ("h2", "1.1 研发背景"),
    (
        "p",
        "健身人群对每日热量摄入与营养素配比的管理需求日益增长，而现有部分应用依赖云端账号、广告较多或功能臃肿。"
        "本软件面向有减脂、增肌或维持体重需求的用户，提供轻量、私密、离线可用的饮食与训练记录能力。",
    ),
    ("h2", "1.2 目标用户"),
    (
        "ul",
        [
            "需要管理每日热量与碳水化合物、蛋白质、脂肪三大营养素的健身爱好者；",
            "希望长期在本地记录饮食、体重与训练数据的用户；",
            "注重隐私、不希望将个人身体数据上传云端的用户。",
        ],
    ),
    ("h2", "1.3 主要特点"),
    (
        "ul",
        [
            "纯本地存储：无需注册登录，数据保存在设备本地数据库；",
            "科学热量计算：按 Mifflin-St Jeor 公式计算基础代谢与每日总消耗；",
            "内置食材库：六百余条常见中文食材的营养数据，支持自定义食材；",
            "一体化记录：今日热量、饮食记账、训练计划、体重曲线与辅助工具集中管理。",
        ],
    ),
    ("break",),
    ("h1", "2. 运行环境与安装"),
    ("h2", "2.1 运行环境"),
    (
        "ul",
        [
            "操作系统：Android 8.0（API 26）及以上；",
            "存储空间：建议 100 MB 以上可用空间；",
            "网络：非必须，仅检查更新时需要联网；",
            "权限：通知（休息计时与提醒，可选）、健康数据（步数，可选）。",
        ],
    ),
    ("h2", "2.2 安装步骤"),
    (
        "ul",
        [
            "获取本软件 Android 安装包（APK）；",
            "在手机设置中允许安装该来源的应用（视机型而定）；",
            "点击 APK 文件，按系统提示完成安装；",
            "首次启动进入引导页，按提示录入身体数据后即可使用。",
        ],
    ),
    ("break",),
    ("h1", "3. 系统架构"),
    (
        "p",
        "本软件采用 Flutter 框架开发，按分层架构组织：界面层（UI）负责页面展示与交互；"
        "状态层基于 Riverpod 管理应用状态；数据仓库层（Repository）封装业务逻辑；"
        "数据层使用 Drift 操作本地 SQLite 数据库，存储食材、饮食、体重、训练与便签等数据；"
        "用户配置通过 SharedPreferences 保存。",
    ),
    ("p", "数据流：用户操作 → 界面触发状态更新 → 数据仓库读写本地数据库 → 界面刷新展示。"),
    ("p", "底部导航包含四个主模块：今日、食材、记录、我的。"),
    ("break",),
    ("h1", "4. 首次引导"),
    (
        "ul",
        [
            "选择性别，输入年龄、身高（cm）与体重（kg）；",
            "选择日常活动量等级；",
            "选择健身目标：减脂、维持或增肌，减脂时可设置目标体重；",
            "确认后系统计算每日热量与三大营养素配额，进入主界面。",
        ],
    ),
    ("p", "引导信息保存在本地，之后可在「我的 → 我的档案」中修改。"),
    ("break",),
    ("h1", "5. 今日页"),
    (
        "p",
        "「今日」为软件首页，顶部可前后切换日期或打开日历选择日期。"
        "「今日热量」区域以环形进度展示已摄入比例，并显示剩余热量、已摄入与目标值；"
        "下方分别展示蛋白质、碳水、脂肪与饮水的完成进度。授权后可显示当日步数。"
        "「今日训练」区域列出当日训练项目及完成进度，点击条目可修改组数与次数，左滑可删除。",
    ),
    ("img", "today"),
    ("break",),
    ("h1", "6. 食材库"),
    (
        "p",
        "底部导航「食材」进入食材库，提供「最近」「分类」「历史」三个页签。"
        "可通过顶部搜索框按名称查找食材，或按乳类、坚果、水果、水产、畜肉等分类浏览。"
        "食材详情展示每 100 克的热量与三大营养素；用户也可以添加自定义食材。",
    ),
    ("img", "foods"),
    ("break",),
    ("h1", "7. 饮食记账"),
    (
        "ul",
        [
            "在今日页或食材详情中发起记录，选择早餐、午餐、晚餐或加餐；",
            "搜索或选择食材，输入食用份量（克）；",
            "保存后写入当日饮食记录，今日热量与营养素进度自动更新；",
            "切换到历史日期后，可查看并补记往日饮食。",
        ],
    ),
    ("break",),
    ("h1", "8. 训练记录"),
    (
        "p",
        "底部导航「记录」包含「身体」「训练」「便签」三个页签。"
        "「训练」页签下分为「计划」「动作库」「历史」：动作库维护常用训练动作及其部位，"
        "计划用于安排每日训练，历史可回看已完成的训练。训练时可记录组数与次数，"
        "组间休息计时结束后通过本地通知提醒。",
    ),
    ("img", "train"),
    ("break",),
    ("h1", "9. 体重管理"),
    (
        "p",
        "「记录 → 身体」页签展示当前体重及与上次记录的差值，可按 7 天、30 天或全部范围"
        "查看体重折线图，点击「+」录入当日体重；下方「每日记录」列出历史体重，可删除单条记录。",
    ),
    ("img", "body"),
    ("break",),
    ("h1", "10. 工具箱"),
    (
        "ul",
        [
            "体脂估算：根据身体围度等数据估算体脂率；",
            "身体指标：记录胸围、腰围等身体围度；",
            "食物换算：在不同单位与克数之间换算；",
            "休息计时：设置组间休息时长并在结束时提醒。",
        ],
    ),
    ("p", "工具箱入口位于「我的」页。"),
    ("break",),
    ("h1", "11. 个人设置"),
    (
        "p",
        "「我的」页集中提供个人相关设置：「我的档案」可修改性别、年龄、身高、体重与目标；"
        "「营养目标」展示并调整每日热量与营养素配额；「提醒」可设置训练、喝水、饮食与体重提醒；"
        "「工具箱」进入辅助工具。页面顶部还可切换界面语言与主题。",
    ),
    ("img", "profile"),
    ("break",),
    ("h1", "12. 数据存储与隐私"),
    (
        "ul",
        [
            "所有业务数据存储于应用私有目录下的 SQLite 数据库；",
            "用户配置使用 SharedPreferences 保存；",
            "不向任何远程服务器上传个人身体或饮食数据；",
            "清除数据会删除本地饮食、体重、训练与便签记录，且不可恢复。",
        ],
    ),
    ("break",),
    ("h1", "附录 A：功能流程"),
    ("h2", "A.1 饮食记录流程"),
    (
        "p",
        "启动应用 → 判断是否已建档（否：进入首次引导并生成配额）→ 进入今日页 → 记录饮食 → "
        "选择食材 → 输入克数 → 保存 → 更新当日剩余配额 → 可切换日期查看历史或补记。",
    ),
    ("h2", "A.2 热量计算流程"),
    (
        "p",
        "录入身体数据 → 按 Mifflin-St Jeor 公式计算 BMR → BMR × 活动系数 = TDEE → "
        "按目标（减脂/维持/增肌）调整热量 → 分配三大营养素克数。",
    ),
    ("h1", "附录 B：开源组件说明"),
    (
        "p",
        "本软件使用了 Flutter、Riverpod、Drift、fl_chart 等开源组件，"
        "食材营养数据整理自公开数据来源。上述组件均按其开源许可证使用。",
    ),
    ("end", f"—— 文档结束 · {FULL_NAME} ——"),
]

TOC = [text for kind, *rest in BODY if kind in ("h1",) for text in rest]
