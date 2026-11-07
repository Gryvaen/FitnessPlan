"""Shared identity for the software-copyright (软著) materials.

The name and version MUST match the R11 application form exactly — the
reviewer compares the page header of every uploaded PDF against it.
The copyright holder (and optional completion date) are passed on the command
line so the applicant's real name never lands in this (public) repository.
"""

from __future__ import annotations

import argparse
import os
import re
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "docs" / "copyright"

# 申请表「软件全称」与「版本号」，原样照抄（含大小写）。
SOFTWARE_NAME = "FITNESSPLAN"
VERSION = "V1.0.0"
# 页眉、封面标题与文件名统一使用「全称 + 版本号」。
FULL_NAME = f"{SOFTWARE_NAME}{VERSION}"


@dataclass(frozen=True)
class Applicant:
    holder: str
    completed: str | None


def parse_applicant(description: str) -> Applicant:
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument(
        "--holder",
        required=True,
        help="著作权人，须与申请表/身份证姓名一致（不写入仓库）",
    )
    parser.add_argument(
        "--completed",
        help="可选：开发完成日期（YYYY-MM-DD），须与申请表一致；省略则封面不写日期",
    )
    args = parser.parse_args()
    holder = args.holder.strip()
    if not holder:
        parser.error("--holder 不能为空")
    if args.completed is None:
        return Applicant(holder=holder, completed=None)
    match = re.fullmatch(r"(\d{4})-(\d{1,2})-(\d{1,2})", args.completed.strip())
    if not match:
        parser.error("--completed 需为 YYYY-MM-DD 格式")
    year, month, day = (int(part) for part in match.groups())
    return Applicant(holder=holder, completed=f"{year}年{month}月{day}日")


# Fonts are embedded into the PDFs. The built-in CID font STSong-Light is not
# embedded, so viewers substitute it and mangle Latin spacing in the header
# (e.g. "FIT NESSPLANV 1.0.0"). Override the TTC path with COPYRIGHT_FONT_TTC.
FONT_TTC = Path(
    os.environ.get("COPYRIGHT_FONT_TTC", "/usr/share/fonts/sarasa-gothic/Sarasa-Regular.ttc")
)
SANS_FONT = "SarasaGothicSC"
MONO_FONT = "SarasaMonoSC"
_SUBFONT_INDEX = {SANS_FONT: 1, MONO_FONT: 13}


def register_fonts() -> None:
    from reportlab.pdfbase import pdfmetrics
    from reportlab.pdfbase.ttfonts import TTFont

    if not FONT_TTC.exists():
        raise SystemExit(
            f"找不到字体 {FONT_TTC}：请安装更纱黑体（Sarasa Gothic），或用 COPYRIGHT_FONT_TTC 指定路径"
        )
    for name, index in _SUBFONT_INDEX.items():
        if name not in pdfmetrics.getRegisteredFontNames():
            pdfmetrics.registerFont(TTFont(name, str(FONT_TTC), subfontIndex=index))
