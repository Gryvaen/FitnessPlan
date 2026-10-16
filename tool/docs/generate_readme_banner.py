#!/usr/bin/env python3
"""Generate the colored README title banner from `art` ASCII lettering.

GitHub strips colors from Markdown, so the lettering is drawn as SVG shapes
(no fonts involved) and referenced from README via <img>.

Usage:
    pip install art
    python tool/docs/generate_readme_banner.py
"""

from pathlib import Path

from art import text2art

TEXT = "Fitness Plan"
FONT = "tarty1"  # ANSI-shadow style: █ blocks plus ╔═╗ shadow lines
OUTPUT = Path(__file__).resolve().parents[2] / "assets/branding/readme-banner.svg"

CELL_W = 10
CELL_H = 20
PAD = 12

# Box-drawing chars -> directions they connect (N, E, S, W).
BOX_DIRS = {
    "═": "EW", "║": "NS",
    "╔": "ES", "╗": "SW", "╚": "NE", "╝": "NW",
    "╠": "NES", "╣": "NSW", "╦": "ESW", "╩": "NEW", "╬": "NESW",
}


WORD_GAP = 4  # extra columns between words; the font's own space is too narrow


def render_word(word: str) -> list[str]:
    raw = text2art(word, font=FONT).replace("░", " ")
    lines = [line.rstrip() for line in raw.splitlines() if line.strip()]
    width = max(len(line) for line in lines)
    return [line.ljust(width) for line in lines]


def lettering_lines() -> list[str]:
    words = [render_word(word) for word in TEXT.split()]
    gap = " " * WORD_GAP
    return [gap.join(parts).rstrip() for parts in zip(*words)]


def build_svg(lines: list[str]) -> str:
    cols = max(len(line) for line in lines)
    width = cols * CELL_W + PAD * 2
    height = len(lines) * CELL_H + PAD * 2

    blocks: list[str] = []
    strokes: list[str] = []
    for row, line in enumerate(lines):
        y = PAD + row * CELL_H
        col = 0
        while col < len(line):
            if line[col] == "█":
                start = col
                while col < len(line) and line[col] == "█":
                    col += 1
                blocks.append(
                    f'<rect x="{PAD + start * CELL_W}" y="{y}" '
                    f'width="{(col - start) * CELL_W}" height="{CELL_H}"/>'
                )
                continue
            dirs = BOX_DIRS.get(line[col])
            if dirs:
                x = PAD + col * CELL_W
                cx, cy = x + CELL_W / 2, y + CELL_H / 2
                ends = {
                    "N": (cx, y), "S": (cx, y + CELL_H),
                    "E": (x + CELL_W, cy), "W": (x, cy),
                }
                for d in dirs:
                    ex, ey = ends[d]
                    strokes.append(f"M{cx:g} {cy:g}L{ex:g} {ey:g}")
            col += 1

    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img" aria-label="{TEXT}">
  <title>{TEXT}</title>
  <style>
    .s0 {{ stop-color: #0F6E6B; }}
    .s1 {{ stop-color: #2BB3A3; }}
    .s2 {{ stop-color: #E8B04B; }}
    .shadow {{ stroke: #0F6E6B; stroke-opacity: 0.45; }}
    @media (prefers-color-scheme: dark) {{
      .s0 {{ stop-color: #2BB3A3; }}
      .s1 {{ stop-color: #6FE0CF; }}
      .s2 {{ stop-color: #F5C96B; }}
      .shadow {{ stroke: #6FE0CF; stroke-opacity: 0.35; }}
    }}
  </style>
  <defs>
    <linearGradient id="fill" gradientUnits="userSpaceOnUse" x1="{PAD}" y1="0" x2="{width - PAD}" y2="0">
      <stop offset="0" class="s0"/>
      <stop offset="0.55" class="s1"/>
      <stop offset="1" class="s2"/>
    </linearGradient>
  </defs>
  <path class="shadow" fill="none" stroke-width="2" stroke-linecap="square" d="{"".join(strokes)}"/>
  <g fill="url(#fill)">
    {"".join(blocks)}
  </g>
</svg>
"""


def main() -> None:
    OUTPUT.write_text(build_svg(lettering_lines()), encoding="utf-8")
    print(f"Wrote {OUTPUT}")


if __name__ == "__main__":
    main()
