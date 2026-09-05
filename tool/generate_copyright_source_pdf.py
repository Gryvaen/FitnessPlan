#!/usr/bin/env python3
"""Generate source-code identification PDF for software copyright registration."""

from __future__ import annotations

import re
from pathlib import Path

from reportlab.lib.pagesizes import A4
from reportlab.lib.units import cm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.cidfonts import UnicodeCIDFont
from reportlab.pdfgen import canvas

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "lib"
OUT_DIR = ROOT / "docs" / "copyright"

SOFTWARE_NAME = "健身饮食管理助手软件V1.0"
LINES_PER_PAGE = 50
PAGES_EACH_SIDE = 30
TOTAL_LINES_EACH_SIDE = LINES_PER_PAGE * PAGES_EACH_SIDE

EXCLUDED_SUFFIXES = (
    "db.g.dart",
)
EXCLUDED_PREFIXES = (
    str(LIB / "l10n" / "app_localizations"),
)

FONT_NAME = "STSong-Light"
FONT_SIZE = 9
LINE_HEIGHT = 11.5
LEFT_MARGIN = 2 * cm
TOP_MARGIN = 2.8 * cm
BOTTOM_MARGIN = 2 * cm
HEADER_HEIGHT = 0.8 * cm


def is_excluded(path: Path) -> bool:
    rel = path.as_posix()
    if any(rel.endswith(suffix) for suffix in EXCLUDED_SUFFIXES):
        return True
    return any(rel.startswith(prefix) for prefix in EXCLUDED_PREFIXES)


def is_effective_line(line: str) -> bool:
    stripped = line.rstrip("\n").strip()
    if not stripped:
        return False
    if stripped.startswith("//"):
        return False
    # Block comments on a single line.
    if stripped.startswith("/*") and stripped.endswith("*/"):
        return False
    return True


def read_effective_lines(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8")
    lines: list[str] = []
    for raw in text.splitlines():
        display = raw.rstrip()
        if is_effective_line(display):
            lines.append(display)
    return lines


def sorted_glob(directory: Path, pattern: str = "*.dart") -> list[Path]:
    return sorted(directory.glob(pattern))


def front_file_order() -> list[Path]:
    files: list[Path] = [
        LIB / "main.dart",
        LIB / "app.dart",
    ]
    files.extend(sorted_glob(LIB / "domain"))
    files.extend([LIB / "data" / "db.dart", LIB / "data" / "tables.dart"])
    files.extend(sorted_glob(LIB / "data" / "repositories"))
    files.extend(sorted_glob(LIB / "data" / "services"))
    files.extend(sorted_glob(LIB / "providers"))
    files.extend(sorted_glob(LIB / "ui" / "shell"))
    files.extend(sorted_glob(LIB / "ui" / "onboarding"))
    files.extend(sorted_glob(LIB / "ui" / "today"))
    files.extend(sorted_glob(LIB / "ui" / "meals"))
    files.extend(sorted_glob(LIB / "ui" / "foods"))
    return [path for path in files if path.exists() and not is_excluded(path)]


def back_file_order() -> list[Path]:
    ui_files = [
        path
        for path in LIB.rglob("*.dart")
        if "lib/ui/" in path.as_posix()
        and not is_excluded(path)
    ]
    ui_files.sort(key=lambda path: path.stat().st_size, reverse=True)

    provider_files = sorted_glob(LIB / "providers")
    domain_files = sorted_glob(LIB / "domain")

    files: list[Path] = []
    for path in ui_files:
        if path not in files:
            files.append(path)
    for path in reversed(provider_files):
        if path not in files:
            files.append(path)
    for path in reversed(domain_files):
        if path not in files:
            files.append(path)
    return files


def collect_lines(files: list[Path]) -> list[str]:
    lines: list[str] = []
    for path in files:
        chunk = read_effective_lines(path)
        if not chunk:
            continue
        rel = path.relative_to(ROOT).as_posix()
        lines.append(f"// ----- {rel} -----")
        lines.extend(chunk)
    return lines


def take_last_lines(files: list[Path], count: int) -> list[str]:
    chunks: list[tuple[Path, list[str]]] = []
    for path in files:
        chunk = read_effective_lines(path)
        if chunk:
            chunks.append((path, chunk))

    selected: list[str] = []
    for path, chunk in reversed(chunks):
        rel = path.relative_to(ROOT).as_posix()
        block = [f"// ----- {rel} -----", *chunk]
        if len(selected) + len(block) <= count:
            selected = block + selected
        else:
            need = count - len(selected)
            if need > 1:
                partial = block[-(need - 1) :]
                selected = [f"// ----- {rel} -----", *partial] + selected
            break
    return selected[:count]


def take_first_lines(all_lines: list[str], count: int) -> list[str]:
    return all_lines[:count]


def truncate_line(line: str, max_chars: int = 108) -> str:
    if len(line) <= max_chars:
        return line
    return line[: max_chars - 3] + "..."


def draw_page(
    pdf: canvas.Canvas,
    page_number: int,
    lines: list[str],
    *,
    section_label: str,
) -> None:
    width, height = A4
    pdf.setFont(FONT_NAME, FONT_SIZE)

    header = f"{SOFTWARE_NAME}    {section_label}    第 {page_number} 页"
    pdf.drawString(LEFT_MARGIN, height - 1.5 * cm, header)

    y = height - TOP_MARGIN
    usable_height = height - TOP_MARGIN - BOTTOM_MARGIN
    max_lines = int(usable_height // LINE_HEIGHT)
    assert max_lines >= LINES_PER_PAGE

    for line in lines[:LINES_PER_PAGE]:
        pdf.drawString(LEFT_MARGIN, y, truncate_line(line))
        y -= LINE_HEIGHT

    pdf.showPage()


def build_pdf(output_path: Path) -> None:
    front_files = front_file_order()
    back_files = back_file_order()

    all_front = collect_lines(front_files)
    if len(all_front) < TOTAL_LINES_EACH_SIDE:
        raise RuntimeError(
            f"Not enough front source lines: {len(all_front)} < {TOTAL_LINES_EACH_SIDE}"
        )

    front_lines = take_first_lines(all_front, TOTAL_LINES_EACH_SIDE)
    back_lines = take_last_lines(back_files, TOTAL_LINES_EACH_SIDE)

    if len(back_lines) < TOTAL_LINES_EACH_SIDE:
        raise RuntimeError(
            f"Not enough back source lines: {len(back_lines)} < {TOTAL_LINES_EACH_SIDE}"
        )

    pdfmetrics.registerFont(UnicodeCIDFont(FONT_NAME))
    output_path.parent.mkdir(parents=True, exist_ok=True)

    pdf = canvas.Canvas(str(output_path), pagesize=A4)
    page_no = 1
    for page_index in range(PAGES_EACH_SIDE):
        start = page_index * LINES_PER_PAGE
        chunk = front_lines[start : start + LINES_PER_PAGE]
        draw_page(
            pdf,
            page_no,
            chunk,
            section_label="源程序前30页",
        )
        page_no += 1

    for page_index in range(PAGES_EACH_SIDE):
        start = page_index * LINES_PER_PAGE
        chunk = back_lines[start : start + LINES_PER_PAGE]
        draw_page(
            pdf,
            page_no,
            chunk,
            section_label="源程序后30页",
        )
        page_no += 1

    pdf.save()
    print(f"Wrote {output_path}")
    print(f"Front files: {len(front_files)}, back files: {len(back_files)}")
    print(f"Pages: {PAGES_EACH_SIDE * 2}, lines/page: {LINES_PER_PAGE}")


def main() -> None:
    output = OUT_DIR / f"{SOFTWARE_NAME}-源代码.pdf"
    build_pdf(output)


if __name__ == "__main__":
    main()
