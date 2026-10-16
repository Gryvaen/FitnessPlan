#!/usr/bin/env python3
"""Build the copyright user-manual PDF with embedded screenshots."""

from __future__ import annotations

from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.cidfonts import UnicodeCIDFont
from reportlab.platypus import (
    Image,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
)

ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "docs" / "copyright"
SCREEN_DIR = OUT_DIR / "screenshots"
OUTPUT = OUT_DIR / "健身饮食管理助手软件V1.0-说明书.pdf"
SOFTWARE_NAME = "健身饮食管理助手软件V1.0"
FONT = "STSong-Light"


def styles():
    pdfmetrics.registerFont(UnicodeCIDFont(FONT))
    base = getSampleStyleSheet()
    return {
        "title": ParagraphStyle(
            "title",
            fontName=FONT,
            fontSize=22,
            leading=28,
            alignment=TA_CENTER,
            spaceAfter=12,
        ),
        "subtitle": ParagraphStyle(
            "subtitle",
            fontName=FONT,
            fontSize=12,
            leading=18,
            alignment=TA_CENTER,
            textColor=colors.grey,
            spaceAfter=24,
        ),
        "h1": ParagraphStyle(
            "h1",
            fontName=FONT,
            fontSize=16,
            leading=22,
            spaceBefore=18,
            spaceAfter=10,
        ),
        "h2": ParagraphStyle(
            "h2",
            fontName=FONT,
            fontSize=13,
            leading=18,
            spaceBefore=12,
            spaceAfter=6,
        ),
        "body": ParagraphStyle(
            "body",
            fontName=FONT,
            fontSize=11,
            leading=18,
            alignment=TA_JUSTIFY,
            spaceAfter=8,
        ),
        "caption": ParagraphStyle(
            "caption",
            fontName=FONT,
            fontSize=10,
            leading=14,
            alignment=TA_CENTER,
            textColor=colors.darkgrey,
            spaceAfter=14,
        ),
    }


def shot(name: str, caption: str, st: dict) -> list:
    path = SCREEN_DIR / name
    flow: list = []
    if path.exists():
        img = Image(str(path), width=10 * cm, height=18 * cm)
        flow.extend([img, Paragraph(caption, st["caption"])])
    else:
        flow.append(Paragraph(f"[缺少截图: {name}] {caption}", st["body"]))
    return flow


def build() -> None:
    st = styles()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    doc = SimpleDocTemplate(
        str(OUTPUT),
        pagesize=A4,
        leftMargin=2.2 * cm,
        rightMargin=2.2 * cm,
        topMargin=2 * cm,
        bottomMargin=2 * cm,
        title=SOFTWARE_NAME,
    )

    story: list = [
        Spacer(1, 3 * cm),
        Paragraph(SOFTWARE_NAME, st["title"]),
        Paragraph("用户操作手册", st["title"]),
        Spacer(1, 0.5 * cm),
        Paragraph("版本号：V1.0", st["subtitle"]),
        Paragraph("著作权人：Gryvaen（个人）", st["subtitle"]),
        Paragraph("开发完成日期：2026年8月", st["subtitle"]),
        Paragraph("运行平台：Android 8.0 及以上", st["subtitle"]),
        PageBreak(),
        Paragraph("目录", st["h1"]),
        Paragraph(
            "1. 软件概述 · 2. 运行环境 · 3. 系统架构 · 4. 首次引导 · "
            "5. 今日配额 · 6. 食材库 · 7. 饮食记账 · 8. 训练记录 · "
            "9. 体重管理 · 10. 工具箱 · 11. 个人设置 · 12. 数据与隐私",
            st["body"],
        ),
        PageBreak(),
        Paragraph("1. 软件概述", st["h1"]),
        Paragraph(
            "健身饮食管理助手软件 V1.0 是一款面向健身与减脂人群的纯本地饮食与训练管理应用。"
            "用户无需注册账号，个人资料、饮食记录、训练记录与体重数据均保存在设备本地，"
            "注重隐私与离线可用性。软件根据用户身体数据，采用 Mifflin-St Jeor 公式计算"
            "每日热量与三大营养素配额，内置约三千八百余条中文食材营养数据，支持饮食记账、"
            "训练计划、组次记录、体重曲线与多种辅助工具。",
            st["body"],
        ),
        Paragraph(
            "主要特点：纯本地存储、科学热量计算、丰富食材库、一体化记录、开源组件合规使用。",
            st["body"],
        ),
        PageBreak(),
        Paragraph("2. 运行环境与安装", st["h1"]),
        Paragraph(
            "硬件要求：Android 8.0 及以上，建议 50 MB 以上可用存储空间。"
            "网络非必须，仅在检查更新时需要。安装步骤：获取 APK → 允许未知来源 → 点击安装 → 首次启动进入引导。",
            st["body"],
        ),
        *shot("01-onboarding.png", "图 2-1 首次启动引导界面", st),
        PageBreak(),
        Paragraph("3. 系统架构", st["h1"]),
        Paragraph(
            "软件采用分层架构：用户界面层（UI）负责页面展示；Riverpod 状态层管理应用状态；"
            "Repository 数据仓库层封装业务逻辑；Drift/SQLite 本地数据库存储食材、饮食、体重、"
            "训练与笔记等数据；SharedPreferences 保存用户配置。",
            st["body"],
        ),
        Paragraph(
            "数据流：用户操作 → UI 触发 Provider → Repository 读写数据库 → 界面刷新展示。",
            st["body"],
        ),
        PageBreak(),
        Paragraph("4. 首次引导", st["h1"]),
        Paragraph(
            "首次安装后录入性别、年龄、身高、体重、活动量与健身目标（减脂/维持/增肌）。"
            "减脂模式可设置目标体重与减重节奏。确认后系统生成每日热量与营养素配额并进入主界面。",
            st["body"],
        ),
        PageBreak(),
        Paragraph("5. 今日配额", st["h1"]),
        Paragraph(
            "「今日」页展示当日热量与营养素完成情况、缺口日历、饮水记录、步数同步与训练摘要。"
            "用户可切换日期查看历史或补记。",
            st["body"],
        ),
        *shot("02-today.png", "图 5-1 今日配额首页", st),
        PageBreak(),
        Paragraph("6. 食材库", st["h1"]),
        Paragraph(
            "食材模块支持分类浏览、关键词搜索、收藏、最近食用与自定义食材。"
            "详情页展示每 100 克热量及三大营养素。",
            st["body"],
        ),
        *shot("03-foods.png", "图 6-1 食材库列表", st),
        *shot("04-food-detail.png", "图 6-2 食材浏览与详情", st),
        PageBreak(),
        Paragraph("7. 饮食记账", st["h1"]),
        Paragraph(
            "用户选择食材并输入食用份量后保存，系统自动扣减当日剩余配额。"
            "支持查看单条记录详情与删除，可通过日历补记历史饮食。",
            st["body"],
        ),
        *shot("05-log-meal.png", "图 7-1 饮食记账", st),
        *shot("06-meal-detail.png", "图 7-2 饮食记录与历史", st),
        PageBreak(),
        Paragraph("8. 训练记录", st["h1"]),
        Paragraph(
            "训练模块提供计划编辑、按日训练安排、组次记录与组间休息计时。"
            "休息结束可通过本地通知提醒开始下一组。",
            st["body"],
        ),
        *shot("07-train-records.png", "图 8-1 训练记录", st),
        *shot("08-rest-timer.png", "图 8-2 休息计时器", st),
        PageBreak(),
        Paragraph("9. 体重管理", st["h1"]),
        Paragraph(
            "身体记录子页支持按日录入体重并以折线图展示趋势。减脂模式下可识别平台期并提示调整热量。",
            st["body"],
        ),
        *shot("09-body-records.png", "图 9-1 体重记录与趋势", st),
        PageBreak(),
        Paragraph("10. 工具箱", st["h1"]),
        Paragraph(
            "工具箱包含热量计算器、体脂估算、身体指标、食材换算与提醒设置等辅助功能。",
            st["body"],
        ),
        *shot("10-tools.png", "图 10-1 工具箱", st),
        *shot("11-calculator.png", "图 10-2 热量计算器", st),
        PageBreak(),
        Paragraph("11. 个人设置", st["h1"]),
        Paragraph(
            "「我的」页展示每日配额摘要，可编辑档案、切换主题、查看计算方式、检查更新或清除本地数据。",
            st["body"],
        ),
        *shot("12-profile.png", "图 11-1 个人设置页", st),
        PageBreak(),
        Paragraph("12. 数据存储与隐私", st["h1"]),
        Paragraph(
            "所有业务数据存储于应用私有目录 SQLite 数据库，配置使用 SharedPreferences。"
            "不上传个人身体或饮食数据至远程服务器。清除数据将删除本地记录且不可恢复。",
            st["body"],
        ),
        Paragraph("附录：开源组件", st["h2"]),
        Paragraph(
            "本软件使用 Flutter、Riverpod、Drift、fl_chart 等开源组件，"
            "食材数据合并自公开营养数据集。完整列表见同目录《开源组件说明.md》。",
            st["body"],
        ),
        Spacer(1, 1 * cm),
        Paragraph(f"—— 文档结束 · {SOFTWARE_NAME} ——", st["caption"]),
    ]

    doc.build(story)
    print(f"Wrote {OUTPUT}")


if __name__ == "__main__":
    build()
