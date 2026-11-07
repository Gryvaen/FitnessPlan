#!/usr/bin/env python3
"""Build the copyright user-manual PDF (the file uploaded to the registration system).

Every page (cover included) carries the header ``FULL_NAME`` plus a running page
number, matching the R11 application form.
"""

from __future__ import annotations

from copyright_meta import (
    FULL_NAME,
    OUT_DIR,
    SANS_FONT,
    SOFTWARE_NAME,
    VERSION,
    parse_applicant,
    register_fonts,
)
from manual_content import BODY, SHOTS, TOC, image_aspect, prepared_image
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import (
    Image,
    KeepTogether,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
)

OUTPUT = OUT_DIR / f"{FULL_NAME}-说明书.pdf"
FONT = SANS_FONT
MAX_IMG_W = 8.5 * cm
MAX_IMG_H = 17 * cm


def styles() -> dict[str, ParagraphStyle]:
    register_fonts()

    def style(name: str, **kw) -> ParagraphStyle:
        return ParagraphStyle(name, fontName=FONT, wordWrap="CJK", **kw)

    return {
        "title": style("title", fontSize=26, leading=34, alignment=TA_CENTER, spaceAfter=14),
        "subtitle": style("subtitle", fontSize=18, leading=26, alignment=TA_CENTER, spaceAfter=40),
        "meta": style("meta", fontSize=12, leading=24, alignment=TA_CENTER),
        "toc_title": style("toc_title", fontSize=16, leading=22, alignment=TA_CENTER, spaceAfter=16),
        "toc": style("toc", fontSize=12, leading=24, leftIndent=1 * cm),
        "h1": style("h1", fontSize=16, leading=22, spaceBefore=6, spaceAfter=10),
        "h2": style("h2", fontSize=13, leading=18, spaceBefore=10, spaceAfter=6),
        "body": style("body", fontSize=11, leading=19, alignment=TA_JUSTIFY, spaceAfter=8, firstLineIndent=22),
        "bullet": style("bullet", bulletFontName=FONT, fontSize=11, leading=19, leftIndent=18, bulletIndent=6, spaceAfter=2),
        "caption": style(
            "caption", fontSize=10, leading=14, alignment=TA_CENTER, textColor=colors.darkgrey, spaceAfter=14
        ),
    }


def draw_header(canvas, doc) -> None:
    width, height = A4
    canvas.saveState()
    canvas.setFont(FONT, 9)
    y = height - 1.3 * cm
    canvas.drawCentredString(width / 2, y, FULL_NAME)
    canvas.drawRightString(width - doc.rightMargin, y, f"第 {doc.page} 页")
    canvas.setLineWidth(0.5)
    canvas.line(doc.leftMargin, y - 0.25 * cm, width - doc.rightMargin, y - 0.25 * cm)
    canvas.restoreState()


def image_flow(key: str, st: dict) -> list:
    path = prepared_image(key)
    ratio = image_aspect(path)
    w = MAX_IMG_W
    h = w * ratio
    if h > MAX_IMG_H:
        h = MAX_IMG_H
        w = h / ratio
    return [KeepTogether([Spacer(1, 0.3 * cm), Image(str(path), width=w, height=h),
                          Paragraph(SHOTS[key].caption, st["caption"])])]


def build() -> None:
    applicant = parse_applicant(__doc__.splitlines()[0])
    st = styles()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    doc = SimpleDocTemplate(
        str(OUTPUT),
        pagesize=A4,
        leftMargin=2.5 * cm,
        rightMargin=2.5 * cm,
        topMargin=2.3 * cm,
        bottomMargin=2 * cm,
        title=f"{FULL_NAME} 用户操作手册",
        author=applicant.holder,
        subject=FULL_NAME,
        creator=FULL_NAME,
    )

    story: list = [
        Spacer(1, 5 * cm),
        Paragraph(SOFTWARE_NAME, st["title"]),
        Paragraph("用户操作手册", st["subtitle"]),
        Paragraph(f"软件名称：{SOFTWARE_NAME}", st["meta"]),
        Paragraph(f"版本号：{VERSION}", st["meta"]),
        Paragraph(f"著作权人：{applicant.holder}", st["meta"]),
        *(
            [Paragraph(f"开发完成日期：{applicant.completed}", st["meta"])]
            if applicant.completed
            else []
        ),
        Paragraph("运行平台：Android 8.0 及以上", st["meta"]),
        PageBreak(),
        Paragraph("目  录", st["toc_title"]),
        *[Paragraph(item, st["toc"]) for item in TOC],
        PageBreak(),
    ]

    for kind, *rest in BODY:
        if kind == "h1":
            story.append(Paragraph(rest[0], st["h1"]))
        elif kind == "h2":
            story.append(Paragraph(rest[0], st["h2"]))
        elif kind == "p":
            story.append(Paragraph(rest[0], st["body"]))
        elif kind == "ul":
            story.extend(Paragraph(item, st["bullet"], bulletText="•") for item in rest[0])
        elif kind == "img":
            story.extend(image_flow(rest[0], st))
        elif kind == "break":
            story.append(PageBreak())
        elif kind == "end":
            story.extend([Spacer(1, 1 * cm), Paragraph(rest[0], st["caption"])])
        else:
            raise ValueError(kind)

    doc.build(story, onFirstPage=draw_header, onLaterPages=draw_header)
    print(f"Wrote {OUTPUT}")


if __name__ == "__main__":
    build()
