"""Turn the ChatGPT-drawn balance-scale parts into app assets.

Usage (from the repo root):
    python3 -I tool/libra_assets.py

Input:  design/goal/Maintain/libra/*.png  (ink on a pure-white ground)
Output: assets/cultivation/maintain/       (transparent PNGs + bg JPEG)

Each part is cropped around its anchor so the Dart side only needs a few
fractions; they are printed at the end — copy them into
lib/ui/profile/balance_scale.dart if the art ever changes.
"""

import os

import numpy as np
from PIL import Image

SRC = 'design/goal/Maintain/libra'
DST = 'assets/cultivation/maintain'
MAX_SIDE = 1200

# Anchors measured on the source images (pixels).
BEAM_PIVOT = (768.0, 509.0)
BEAM_RING_L = (182.0, 532.5)
BEAM_RING_R = (1357.5, 530.0)
PAN_HOOK = (511.5, 68.0)
PAN_RIM_Y = 815.0
BASE_TIP = (511.0, 264.0)


def white_to_alpha(img: Image.Image) -> Image.Image:
    rgb = np.asarray(img.convert('RGB')).astype(np.float64)
    a = (255.0 - rgb.min(axis=2)) / 255.0
    a[a < 0.03] = 0.0
    safe = np.where(a > 0, a, 1.0)[..., None]
    col = (rgb - 255.0 * (1.0 - a[..., None])) / safe
    col = np.clip(col, 0, 255)
    out = np.dstack([col, a * 255.0]).round().astype(np.uint8)
    return Image.fromarray(out, 'RGBA')


def fit(img: Image.Image) -> Image.Image:
    w, h = img.size
    k = min(1.0, MAX_SIDE / max(w, h))
    if k < 1.0:
        img = img.resize((round(w * k), round(h * k)), Image.LANCZOS)
    return img


def content_box(img: Image.Image):
    a = np.asarray(img)[..., 3]
    ys, xs = np.nonzero(a > 8)
    return xs.min(), ys.min(), xs.max(), ys.max()


def save(img: Image.Image, name: str):
    img = fit(img)
    img.save(os.path.join(DST, name), optimize=True)
    return img.size


def main():
    os.makedirs(DST, exist_ok=True)
    report = {}

    # Beam: crop symmetric about the pivot so the pivot is the exact centre.
    beam = white_to_alpha(Image.open(f'{SRC}/scale_beam.png'))
    px, py = BEAM_PIVOT
    half_w, half_h = 620, 60
    box = (px - half_w, py - half_h, px + half_w, py + half_h)
    w, h = save(beam.crop(tuple(round(v) for v in box)), 'beam.png')
    bw, bh = 2 * half_w, 2 * half_h
    report['beam'] = dict(
        aspect=bw / bh,
        ringL=((BEAM_RING_L[0] - box[0]) / bw, (BEAM_RING_L[1] - box[1]) / bh),
        ringR=((BEAM_RING_R[0] - box[0]) / bw, (BEAM_RING_R[1] - box[1]) / bh),
        size=(w, h),
    )

    # Pan: hook ring horizontally centred.
    pan = white_to_alpha(Image.open(f'{SRC}/scale_pan.png'))
    x0, y0, x1, y1 = content_box(pan)
    hx, hy = PAN_HOOK
    half = max(hx - x0, x1 - hx) + 8
    box = (hx - half, y0 - 6, hx + half, y1 + 8)
    box = tuple(round(v) for v in box)
    w, h = save(pan.crop(box), 'pan.png')
    pw, ph = box[2] - box[0], box[3] - box[1]
    report['pan'] = dict(
        aspect=pw / ph,
        hook=((hx - box[0]) / pw, (hy - box[1]) / ph),
        rimY=(PAN_RIM_Y - box[1]) / ph,
        size=(w, h),
    )

    # Base: post centred, tip near the top.
    base = white_to_alpha(Image.open(f'{SRC}/scale_base.png'))
    x0, y0, x1, y1 = content_box(base)
    tx, ty = BASE_TIP
    half = max(tx - x0, x1 - tx) + 10
    box = tuple(round(v) for v in (tx - half, ty - 6, tx + half, y1 + 10))
    w, h = save(base.crop(box), 'base.png')
    sw, sh = box[2] - box[0], box[3] - box[1]
    report['base'] = dict(
        aspect=sw / sh,
        tip=((tx - box[0]) / sw, (ty - box[1]) / sh),
        size=(w, h),
    )

    # Orbs + seal: centred square around the content.
    for src, name in [
        ('orb_moon.png', 'moon.png'),
        ('orb_sun.png', 'sun.png'),
        ('seal_heng.png', 'seal.png'),
    ]:
        img = white_to_alpha(Image.open(f'{SRC}/{src}'))
        x0, y0, x1, y1 = content_box(img)
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        half = max(x1 - x0, y1 - y0) / 2 * 1.04
        box = tuple(round(v) for v in (cx - half, cy - half, cx + half, cy + half))
        img = img.crop(box).resize((512, 512), Image.LANCZOS)
        report[name] = dict(size=save(img, name))

    bg = Image.open(f'{SRC}/bg.png').convert('RGB')
    bg.save(os.path.join(DST, 'maintain_bg.jpg'), quality=88, optimize=True)
    px = np.asarray(bg).astype(int)
    report['bg'] = dict(paper='#%02X%02X%02X' % tuple(px[-40:, :].reshape(-1, 3).mean(0).round().astype(int)))

    for k, v in report.items():
        print(k, {kk: (tuple(round(x, 4) for x in vv) if isinstance(vv, tuple) else (round(vv, 4) if isinstance(vv, float) else vv)) for kk, vv in v.items()})


if __name__ == '__main__':
    main()
