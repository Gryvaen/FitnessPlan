#!/usr/bin/env python3
"""Build the editable copyright user-manual DOCX (same content as the PDF)."""

from __future__ import annotations

from datetime import datetime

from copyright_meta import (
    FULL_NAME,
    OUT_DIR,
    SOFTWARE_NAME,
    VERSION,
    Applicant,
    parse_applicant,
)
from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_LINE_SPACING
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor
from manual_content import BODY, SHOTS, TOC, image_aspect, prepared_image

OUTPUT = OUT_DIR / f"{FULL_NAME}-说明书.docx"
IMAGE_WIDTH = Cm(8.5)
IMAGE_MAX_HEIGHT = Cm(17)


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
        style.font.color.rgb = RGBColor(0, 0, 0)
        style.paragraph_format.space_before = Pt(12)
        style.paragraph_format.space_after = Pt(6)
        style.paragraph_format.line_spacing_rule = WD_LINE_SPACING.EXACTLY
        style.paragraph_format.line_spacing = Pt(22)

    for section in doc.sections:
        section.top_margin = Cm(2.54)
        section.bottom_margin = Cm(2.54)
        section.left_margin = Cm(3.17)
        section.right_margin = Cm(3.17)


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
    title_run = center.add_run(FULL_NAME)
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


def center_line(doc: Document, text: str, *, size: float = 12, bold: bool = False) -> None:
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = p.add_run(text)
    run.bold = bold
    run.font.size = Pt(size)
    _east_asia(run, "宋体")


def add_cover_page(doc: Document, applicant: Applicant) -> None:
    for _ in range(6):
        doc.add_paragraph()
    center_line(doc, SOFTWARE_NAME, size=26, bold=True)
    center_line(doc, "用户操作手册", size=18, bold=True)
    doc.add_paragraph()
    center_line(doc, f"软件名称：{SOFTWARE_NAME}")
    center_line(doc, f"版本号：{VERSION}")
    center_line(doc, f"著作权人：{applicant.holder}")
    if applicant.completed:
        center_line(doc, f"开发完成日期：{applicant.completed}")
    center_line(doc, "运行平台：Android 8.0 及以上")


def add_toc_page(doc: Document) -> None:
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = p.add_run("目  录")
    run.bold = True
    run.font.size = Pt(16)
    _east_asia(run, "黑体")
    doc.add_paragraph()
    for item in TOC:
        line = doc.add_paragraph(item, style="Normal")
        line.paragraph_format.left_indent = Cm(1)
    doc.add_page_break()


def add_image(doc: Document, key: str) -> None:
    path = prepared_image(key)
    width = IMAGE_WIDTH
    if image_aspect(path) * width > IMAGE_MAX_HEIGHT:
        width = int(IMAGE_MAX_HEIGHT / image_aspect(path))
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.line_spacing_rule = WD_LINE_SPACING.SINGLE
    p.paragraph_format.keep_with_next = True
    p.add_run().add_picture(str(path), width=width)
    cap = doc.add_paragraph()
    cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = cap.add_run(SHOTS[key].caption)
    run.font.size = Pt(10.5)
    _east_asia(run, "宋体")


def build_body(doc: Document) -> None:
    for kind, *rest in BODY:
        if kind == "h1":
            doc.add_paragraph(rest[0], style="Heading 1")
        elif kind == "h2":
            doc.add_paragraph(rest[0], style="Heading 2")
        elif kind == "p":
            para = doc.add_paragraph(rest[0], style="Normal")
            para.paragraph_format.first_line_indent = Pt(24)
        elif kind == "ul":
            for item in rest[0]:
                doc.add_paragraph(item, style="List Bullet")
        elif kind == "img":
            add_image(doc, rest[0])
        elif kind == "break":
            doc.add_page_break()
        elif kind == "end":
            doc.add_paragraph()
            p = doc.add_paragraph(rest[0])
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        else:
            raise ValueError(kind)


def set_core_properties(doc: Document, applicant: Applicant) -> None:
    now = datetime.now()
    props = doc.core_properties
    props.title = f"{FULL_NAME} 用户操作手册"
    props.subject = FULL_NAME
    props.author = applicant.holder
    props.last_modified_by = applicant.holder
    props.comments = ""
    props.created = now
    props.modified = now


def build() -> None:
    applicant = parse_applicant(__doc__.splitlines()[0])
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    doc = Document()
    setup_document_styles(doc)

    # One section: every page, cover included, carries the header and page number.
    setup_body_header_footer(doc.sections[0])
    add_cover_page(doc, applicant)
    doc.add_page_break()
    add_toc_page(doc)
    build_body(doc)

    set_core_properties(doc, applicant)
    doc.save(OUTPUT)
    print(f"Wrote {OUTPUT}")


if __name__ == "__main__":
    build()
