#!/usr/bin/env python3
"""Render the ArrowQuest brand mark into every asset the project needs.

Design
------
A chunky arrow path — the game in one glance: a rounded elbow run of cells with
a bright head, sitting on a faint board grid over a deep navy gradient. Two flat
accents (electric blue + violet), rounded joins throughout.

Outputs (relative to the Flutter project root):
  assets/branding/logo.png
  branding/android/mipmap-<density>/ic_launcher.png
  branding/android/mipmap-<density>/ic_launcher_round.png
  branding/android/mipmap-<density>/ic_launcher_foreground.png
  branding/android/ic_launcher.xml
  branding/android/ic_launcher_background.xml
"""
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

BG_TOP = (27, 35, 64)
BG_BOT = (11, 14, 22)
GRID = (58, 70, 108)
BLUE = (61, 123, 255)
BLUE_HI = (120, 165, 255)
VIOLET = (139, 92, 246)
WHITE = (244, 246, 252)

DENSITIES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}

# Normalised arrow path (tail -> head), plus the head tip.
PATH = [
    (0.26, 0.72),
    (0.26, 0.46),
    (0.48, 0.46),
    (0.48, 0.30),
    (0.66, 0.30),
]
TIP = (0.80, 0.30)


def gradient(size):
    img = Image.new("RGB", (1, size))
    d = ImageDraw.Draw(img)
    for y in range(size):
        t = y / max(1, size - 1)
        d.point(
            (0, y),
            fill=tuple(
                round(BG_TOP[i] + (BG_BOT[i] - BG_TOP[i]) * t) for i in range(3)
            ),
        )
    return img.resize((size, size), Image.BILINEAR)


def rounded_mask(size, radius, circle=False):
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    if circle:
        d.ellipse((0, 0, size - 1, size - 1), fill=255)
    else:
        d.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=255)
    return mask


def draw_grid(draw, size, inset, cell, alpha):
    """Faint board cells behind the mark."""
    for r in range(3):
        for c in range(3):
            x = inset + c * cell
            y = inset + r * cell
            draw.rounded_rectangle(
                (x, y, x + cell * 0.86, y + cell * 0.86),
                radius=cell * 0.22,
                outline=(GRID[0], GRID[1], GRID[2], alpha),
                width=max(1, int(size * 0.006)),
            )


def draw_mark(img, size, scale=1.0, offset=(0.0, 0.0), alpha=255):
    """Draw the arrow path onto img at the given size."""
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    def pt(p):
        cx = (p[0] - 0.5) * scale + 0.5 + offset[0]
        cy = (p[1] - 0.5) * scale + 0.5 + offset[1]
        return (cx * size, cy * size)

    pts = [pt(p) for p in PATH]
    width = max(2, int(size * 0.085 * scale))

    # faint grid
    cell = size * 0.30
    inset = (size - cell * 3) / 2 + size * 0.06
    draw_grid(d, size, inset, cell, 70)

    # body
    d.line(pts, fill=BLUE + (alpha,), width=width, joint="curve")
    for p in (pts[0], pts[-1]):
        d.ellipse(
            (p[0] - width / 2, p[1] - width / 2, p[0] + width / 2, p[1] + width / 2),
            fill=BLUE + (alpha,),
        )

    # highlight along the first run, so the path reads as a tube
    inner = width * 0.32
    d.line(pts, fill=BLUE_HI + (int(alpha * 0.55),), width=int(inner), joint="curve")

    # motion trail behind the tail — a small original flourish
    tail = pt(PATH[0])
    nxt = pt(PATH[1])
    tdx, tdy = tail[0] - nxt[0], tail[1] - nxt[1]
    tlen = max(1.0, (tdx * tdx + tdy * tdy) ** 0.5)
    tux, tuy = tdx / tlen, tdy / tlen
    for step, radius in ((0.22, 0.30), (0.40, 0.20), (0.56, 0.13)):
        cx = tail[0] + tux * width * step * 2.2
        cy = tail[1] + tuy * width * step * 2.2
        r = width * radius
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=BLUE + (int(alpha * 0.65),))

    # head: the same notched dart the in-game arrows use
    tip = pt(TIP)
    base = pt(PATH[-1])
    dx = tip[0] - base[0]
    dy = tip[1] - base[1]
    length = max(1.0, (dx * dx + dy * dy) ** 0.5)
    ux, uy = dx / length, dy / length
    px, py = -uy, ux
    half = width * 0.85
    back = length * 0.82
    notch = length * 0.46
    d.polygon(
        [
            (tip[0] + ux * width * 0.45, tip[1] + uy * width * 0.45),
            (tip[0] - ux * back + px * half, tip[1] - uy * back + py * half),
            (tip[0] - ux * notch, tip[1] - uy * notch),
            (tip[0] - ux * back - px * half, tip[1] - uy * back - py * half),
        ],
        fill=WHITE + (alpha,),
    )

    img.alpha_composite(layer)


def icon(size, circle=False, foreground=False):
    if foreground:
        # Adaptive-icon foreground: transparent, mark kept inside the safe zone.
        img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        draw_mark(img, size, scale=0.62)
        return img

    img = gradient(size).convert("RGBA")
    # violet wash in the top-left corner for depth
    wash = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    wd = ImageDraw.Draw(wash)
    wd.ellipse(
        (-size * 0.35, -size * 0.45, size * 0.85, size * 0.75),
        fill=VIOLET + (46,),
    )
    img.alpha_composite(wash)

    draw_mark(img, size)
    img.putalpha(rounded_mask(size, int(size * 0.24), circle=circle))
    return img


ADAPTIVE = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
"""

BACKGROUND = """<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="rectangle">
    <gradient
        android:angle="270"
        android:startColor="#1B2340"
        android:endColor="#0B0E16"
        android:type="linear" />
</shape>
"""


def main():
    logo_path = os.path.join(ROOT, "assets", "branding", "logo.png")
    os.makedirs(os.path.dirname(logo_path), exist_ok=True)
    icon(512).save(logo_path)
    print("wrote", logo_path)

    android = os.path.join(ROOT, "branding", "android")
    for name, base in DENSITIES.items():
        folder = os.path.join(android, f"mipmap-{name}")
        os.makedirs(folder, exist_ok=True)
        icon(base).save(os.path.join(folder, "ic_launcher.png"))
        icon(base, circle=True).save(os.path.join(folder, "ic_launcher_round.png"))
        icon(int(base * 1.5), foreground=True).save(
            os.path.join(folder, "ic_launcher_foreground.png")
        )
        print("wrote", folder)

    with open(os.path.join(android, "ic_launcher.xml"), "w") as fh:
        fh.write(ADAPTIVE)
    with open(os.path.join(android, "ic_launcher_background.xml"), "w") as fh:
        fh.write(BACKGROUND)
    print("wrote adaptive icon descriptors")


if __name__ == "__main__":
    main()
