#!/usr/bin/env python3
"""Build the copyright user-manual DOCX (standard 软著 format)."""

from __future__ import annotations

from pathlib import Path

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_LINE_SPACING
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "docs" / "copyright"
DISPLAY_DIR = ROOT / "docs" / "display"
OUTPUT = OUT_DIR / "健身饮食管理助手软件V1.0-说明书.docx"
SOFTWARE_NAME = "健身饮食管理助手软件V1.0"
IMAGE_WIDTH = Cm(10.5)


def _east_asia(run, font_name: str) -> None:
    run.font.name = font_name
    r_pr = run._element.get_or_add_rPr()
    r_fonts = OxmlElement("w:rFonts")
    r_fonts.set(qn("w:ascii"), font_name)
    r_fonts.set(qn("w:hAnsi"), font_name)
    r_fonts.set(qn("w:eastAsia"), font_name)
    r_pr.append(r_fonts)


def _add_field(paragraph, instruction: str) -> None:
    run = paragraph.add_run()
    r = run._element

    fld_begin = OxmlElement("w:fldChar")
    fld_begin.set(qn("w:fldCharType"), "begin")

    instr_text = OxmlElement("w:instrText")
    instr_text.set(qn("xml:space"), "preserve")
    instr_text.text = instruction

    fld_sep = OxmlElement("w:fldChar")
    fld_sep.set(qn("w:fldCharType"), "separate")

    fld_end = OxmlElement("w:fldChar")
    fld_end.set(qn("w:fldCharType"), "end")

    r.append(fld_begin)
    r.append(instr_text)
    r.append(fld_sep)
    r.append(fld_end)


def setup_document_styles(doc: Document) -> None:
    normal = doc.styles["Normal"]
    normal.font.name = "宋体"
    normal.font.size = Pt(12)
    normal.paragraph_format.line_spacing_rule = WD_LINE_SPACING.EXACTLY
    normal.paragraph_format.line_spacing = Pt(22)

    for style_name, font, size in (
        ("Heading 1", "黑体", 16),
        ("Heading 2", "黑体", 14),
    ):
        style = doc.styles[style_name]
        style.font.name = font
        style.font.size = Pt(size)
        style.paragraph_format.space_before = Pt(12)
        style.paragraph_format.space_after = Pt(6)
        style.paragraph_format.line_spacing_rule = WD_LINE_SPACING.EXACTLY
        style.paragraph_format.line_spacing = Pt(22)

    for section in doc.sections:
        section.top_margin = Cm(2.54)
        section.bottom_margin = Cm(2.54)
        section.left_margin = Cm(3.17)
        section.right_margin = Cm(3.17)


def enable_update_fields_on_open(doc: Document) -> None:
    settings = doc.settings.element
    update_fields = OxmlElement("w:updateFields")
    update_fields.set(qn("w:val"), "true")
    settings.append(update_fields)


def setup_body_header_footer(section) -> None:
    section.different_first_page_header_footer = False
    header = section.header
    header.is_linked_to_previous = False
    footer = section.footer
    footer.is_linked_to_previous = False

    # Clear default header paragraph content by reusing it in a table layout.
    hp = header.paragraphs[0]
    hp.clear()

    table = header.add_table(rows=1, cols=3, width=Cm(16))
    table.autofit = False
    cols = table.columns
    cols[0].width = Cm(4)
    cols[1].width = Cm(8)
    cols[2].width = Cm(4)

    left = table.cell(0, 0).paragraphs[0]
    left.alignment = WD_ALIGN_PARAGRAPH.LEFT

    center = table.cell(0, 1).paragraphs[0]
    center.alignment = WD_ALIGN_PARAGRAPH.CENTER
    title_run = center.add_run(SOFTWARE_NAME)
    title_run.font.size = Pt(10.5)
    _east_asia(title_run, "宋体")

    right = table.cell(0, 2).paragraphs[0]
    right.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    _add_field(right, "PAGE")

    if hp._element.getparent() is not None and not hp.text:
        hp._element.getparent().remove(hp._element)

    sect_pr = section._sectPr
    pg_num = OxmlElement("w:pgNumType")
    pg_num.set(qn("w:start"), "1")
    sect_pr.append(pg_num)


def add_cover_page(doc: Document) -> None:
    for _ in range(6):
        doc.add_paragraph()

    def center_line(text: str, *, size: int = 12, bold: bool = False) -> None:
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        run = p.add_run(text)
        run.bold = bold
        run.font.size = Pt(size)
        _east_asia(run, "宋体")

    center_line(SOFTWARE_NAME, size=22, bold=True)
    center_line("用户操作手册", size=18, bold=True)
    doc.add_paragraph()
    center_line("版本号：V1.0")
    center_line("著作权人：Gryvaen（个人）")
    center_line("开发完成日期：2026年8月")
    center_line("运行环境：Android 8.0 及以上")


def add_toc_page(doc: Document) -> None:
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = p.add_run("目  录")
    run.bold = True
    run.font.size = Pt(16)
    _east_asia(run, "黑体")

    doc.add_paragraph()
    toc_p = doc.add_paragraph()
    _add_field(toc_p, r'TOC \o "1-2" \h \z \u')
    doc.add_page_break()


def add_section_for_body(doc: Document) -> None:
    section = doc.add_section(WD_SECTION.NEW_PAGE)
    setup_body_header_footer(section)


def add_heading(doc: Document, text: str, level: int = 1) -> None:
    style = "Heading 1" if level == 1 else "Heading 2"
    doc.add_paragraph(text, style=style)


def add_body(doc: Document, text: str) -> None:
    doc.add_paragraph(text, style="Normal")


def add_bullets(doc: Document, items: list[str]) -> None:
    for item in items:
        doc.add_paragraph(item, style="List Bullet")


def add_image(doc: Document, filename: str, caption: str) -> None:
    path = DISPLAY_DIR / filename
    if not path.exists():
        add_body(doc, f"[图片缺失: {filename}] {caption}")
        return
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.add_run().add_picture(str(path), width=IMAGE_WIDTH)
    cap = doc.add_paragraph()
    cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = cap.add_run(caption)
    run.font.size = Pt(10.5)
    _east_asia(run, "宋体")


def add_page_break(doc: Document) -> None:
    doc.add_page_break()


def build_body(doc: Document) -> None:
    add_heading(doc, "1. 软件概述", 1)
    add_body(
        doc,
        "本文档介绍健身饮食管理助手软件 V1.0 的安装环境、系统架构、主要功能与操作流程。"
        "软件为纯本地应用，无需联网登录即可使用核心功能。",
    )
    add_heading(doc, "1.1 研发背景", 2)
    add_body(
        doc,
        "随着大众健康意识提升，健身人群对每日热量摄入与营养素配比的管理需求日益增长。"
        "现有部分应用依赖云端账号、广告较多或功能臃肿。本软件面向有减脂、增肌或维持体重需求的用户，"
        "提供轻量、私密、离线可用的饮食与训练记录能力。",
    )
    add_heading(doc, "1.2 目标用户", 2)
    add_bullets(
        doc,
        [
            "需要精确管理每日热量与三大营养素（碳水、蛋白质、脂肪）的健身爱好者",
            "希望记录饮食、体重、训练数据并长期本地保存的用户",
            "注重隐私、不希望上传个人身体数据至云端的用户",
        ],
    )
    add_heading(doc, "1.3 主要特点", 2)
    add_bullets(
        doc,
        [
            "纯本地存储：无需注册登录，数据保存在设备本地",
            "科学热量计算：基于 Mifflin-St Jeor 公式计算 BMR/TDEE",
            "丰富食材库：内置约 3800+ 条中文食材营养数据",
            "一体化记录：整合今日配额、饮食记账、训练计划、体重曲线与工具箱",
            "开源组件合规：使用 Flutter 等开源框架，详见附录",
        ],
    )
    add_page_break(doc)

    add_heading(doc, "2. 运行环境与安装", 1)
    add_heading(doc, "2.1 硬件与系统要求", 2)
    add_bullets(
        doc,
        [
            "操作系统：Android 8.0（API 26）及以上",
            "存储空间：建议 50 MB 以上可用空间",
            "网络：非必须；仅检查更新时需要网络",
            "权限：通知（休息计时）、健康数据（步数，可选）",
        ],
    )
    add_heading(doc, "2.2 安装步骤", 2)
    add_bullets(
        doc,
        [
            "获取本软件 Android 安装包（APK）",
            "在手机上允许安装未知来源应用（视机型而定）",
            "点击 APK 文件，按提示完成安装",
            "首次启动将进入引导页，按提示录入身体数据即可使用",
        ],
    )
    add_image(doc, "Loading-page.jpg", "图 2-1 应用启动与加载界面")
    add_page_break(doc)

    add_heading(doc, "3. 系统架构", 1)
    add_body(
        doc,
        "本软件采用分层架构：用户界面层（UI）负责页面展示；Riverpod 状态层管理应用状态；"
        "Repository 数据仓库层封装业务逻辑；Drift/SQLite 本地数据库存储食材、饮食、体重、训练与笔记等数据；"
        "SharedPreferences 保存用户配置。",
    )
    add_body(doc, "数据流：用户操作 → UI 触发 Provider → Repository 读写数据库 → 界面刷新展示。")
    add_page_break(doc)

    add_heading(doc, "4. 首次引导", 1)
    add_bullets(
        doc,
        [
            "选择性别（男/女）",
            "输入年龄、身高（cm）、体重（kg）",
            "选择日常活动量等级（久坐至高强度）",
            "选择目标：减脂、维持或增肌；减脂时可设置目标体重",
            "确认后生成每日热量与营养素配额，进入主界面",
        ],
    )
    add_body(doc, "引导信息保存在本地，可随时在「我的 → 编辑档案」中修改。")
    add_page_break(doc)

    add_heading(doc, "5. 今日配额", 1)
    add_body(
        doc,
        "「今日」页为软件首页，展示当日热量与营养素配额完成情况，包括缺口日历、饮水记录、"
        "步数同步（需授权）与当日训练摘要。热量目标由 Mifflin-St Jeor 公式计算。",
    )
    add_image(doc, "today.jpg", "图 5-1 今日配额页：展示当日热量进度与营养素完成情况")
    add_page_break(doc)

    add_heading(doc, "6. 食材库", 1)
    add_body(
        doc,
        "底部导航「食材」进入食材库模块，支持分类浏览、关键词搜索、收藏、最近食用与自定义食材。"
        "食材详情页展示每 100 克热量及三大营养素。",
    )
    add_image(doc, "foods.jpg", "图 6-1 食材库：分类入口与搜索，可浏览内置营养数据")
    add_page_break(doc)

    add_heading(doc, "7. 饮食记账", 1)
    add_bullets(
        doc,
        [
            "从今日页或食材详情进入「记一笔」",
            "选择或搜索食材，输入食用份量（克）",
            "确认后写入当日饮食记录，自动扣减剩余配额",
            "通过缺口日历选择历史日期，可补记往日饮食",
        ],
    )
    add_body(doc, "（可在此章节补充饮食记账界面截图。）")
    add_page_break(doc)

    add_heading(doc, "8. 训练记录", 1)
    add_body(
        doc,
        "底部导航「记录」整合训练、身体数据与笔记三个子页签。支持创建训练计划、记录组次与重量，"
        "组间休息计时结束时通过本地通知提醒。",
    )
    add_body(doc, "（可在此章节补充训练记录与休息计时界面截图。）")
    add_page_break(doc)

    add_heading(doc, "9. 体重管理", 1)
    add_body(
        doc,
        "「记录 → 身体」子页签提供体重记录与趋势分析，支持按日录入体重并以折线图展示变化。"
        "减脂模式下可识别平台期并提示调整热量。",
    )
    add_image(doc, "body-records.jpg", "图 9-1 体重记录：折线图展示历史体重与趋势")
    add_page_break(doc)

    add_heading(doc, "10. 工具箱", 1)
    add_bullets(
        doc,
        [
            "热量计算器：独立计算 BMR/TDEE 与营养素分配",
            "体脂率估算：根据身体数据估算体脂",
            "身体指标：记录胸围、腰围等围度",
            "食材换算：不同单位与克数换算",
            "提醒中心：训练提醒与休息通知设置",
        ],
    )
    add_body(doc, "（可在此章节补充工具箱界面截图。）")
    add_page_break(doc)

    add_heading(doc, "11. 个人设置", 1)
    add_body(
        doc,
        "「我的」页提供档案摘要与设置入口，可编辑个人档案、切换主题、查看计算方式、"
        "检查应用更新（Android）或清除本地数据。",
    )
    add_image(doc, "profile.jpg", "图 11-1 个人设置页：展示每日配额摘要与档案入口")
    add_page_break(doc)

    add_heading(doc, "12. 数据存储与隐私", 1)
    add_bullets(
        doc,
        [
            "所有业务数据存储于应用私有目录下的 SQLite 数据库",
            "用户配置使用 SharedPreferences 保存",
            "不上传个人身体或饮食数据至任何远程服务器",
            "清除数据将删除本地饮食、体重、训练与笔记记录，不可恢复",
        ],
    )
    add_page_break(doc)

    add_heading(doc, "附录 A：功能流程图", 1)
    add_heading(doc, "A.1 饮食记录流程", 2)
    add_body(
        doc,
        "启动应用 → 是否已建档？ → 否 → 首次引导 → 生成配额 → 是 → 进入今日页 → "
        "记一笔 → 选择食材 → 输入克数 → 保存记录 → 更新当日剩余配额 → 可查看历史/补记",
    )
    add_heading(doc, "A.2 热量计算流程", 2)
    add_body(
        doc,
        "录入身体数据 → 计算 BMR (Mifflin-St Jeor) → BMR × 活动系数 = TDEE → "
        "按目标调整（减脂/维持/增肌）→ 分配三大营养素克数",
    )
    add_page_break(doc)

    add_heading(doc, "附录 B：开源组件说明", 1)
    add_body(
        doc,
        "本软件使用了 Flutter、Riverpod、Drift 等开源组件，以及合并自公开来源的食材营养数据。"
        "完整列表见同目录文件《开源组件说明.md》。",
    )
    doc.add_paragraph()
    p = doc.add_paragraph(f"—— 文档结束 · {SOFTWARE_NAME} ——")
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER


def build() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    doc = Document()
    setup_document_styles(doc)

    # Cover section: no header/footer content.
    section0 = doc.sections[0]
    section0.different_first_page_header_footer = True
    section0.header.is_linked_to_previous = False
    section0.footer.is_linked_to_previous = False

    add_cover_page(doc)

    # Section 1: TOC + body with header and page numbers.
    add_section_for_body(doc)
    add_toc_page(doc)
    build_body(doc)

    enable_update_fields_on_open(doc)
    doc.save(OUTPUT)
    print(f"Wrote {OUTPUT}")
    print("Open in Word/WPS and update the table of contents (right-click -> Update Field).")


if __name__ == "__main__":
    build()
