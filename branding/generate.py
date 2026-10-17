#!/usr/bin/env python3
"""Render the Quiver brand mark into every asset the project needs.

Design notes
------------
The mark is one chunky arrow, flying out of a faint grid of board cells — the
game in a single glance. Two flat colours, one restrained background gradient,
rounded joins throughout. Deliberately designed, not an AI gradient mesh.

Outputs (relative to the Flutter project root):
  assets/branding/logo.png
  branding/android/mipmap-<density>/ic_launcher.png
  branding/android/mipmap-<density>/ic_launcher_round.png
  branding/android/mipmap-<density>/ic_launcher_foreground.png
  branding/android/ic_launcher.xml
  branding/android/ic_launcher_background.xml
"""
import os

import cairosvg

W = 1024
BG_TOP = "#1B2340"
BG_BOT = "#0B0E16"
ARROW = "#FFB020"
ARROW_DEEP = "#E08A00"

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

DENSITIES = {
    "mdpi": (48, 108),
    "hdpi": (72, 162),
    "xhdpi": (96, 216),
    "xxhdpi": (144, 324),
    "xxxhdpi": (192, 432),
}


def defs() -> str:
    return f"""
  <defs>
    <linearGradient id="bg" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="0" y2="1024">
      <stop offset="0" stop-color="{BG_TOP}"/>
      <stop offset="1" stop-color="{BG_BOT}"/>
    </linearGradient>
    <radialGradient id="hl" gradientUnits="userSpaceOnUse" cx="360" cy="300" r="620">
      <stop offset="0" stop-color="#FFB020" stop-opacity="0.16"/>
      <stop offset="1" stop-color="#FFB020" stop-opacity="0"/>
    </radialGradient>
  </defs>"""


def grid_cells() -> str:
    """A faint hint of the board behind the arrow."""
    out = []
    size, gap = 96, 22
    span = 3 * size + 2 * gap
    start = (W - span) / 2
    for r in range(3):
        for c in range(3):
            x = start + c * (size + gap)
            y = start + r * (size + gap)
            out.append(
                f'<rect x="{x:.0f}" y="{y:.0f}" width="{size}" height="{size}" rx="26" '
                f'fill="none" stroke="#FFFFFF" stroke-opacity="0.06" stroke-width="3"/>'
            )
    return "\n    ".join(out)


def arrow(scale: float = 1.0, dx: float = 0.0, dy: float = 0.0) -> str:
    """A right-pointing arrow, rotated -45deg so it flies up and to the right."""
    return f"""
    <g transform="translate({dx} {dy}) translate(512 512) scale({scale}) translate(-512 -512) rotate(-45 512 512)">
      <path d="M300 512 H660" fill="none" stroke="{ARROW_DEEP}" stroke-width="150"
            stroke-linecap="round" opacity="0.35"/>
      <path d="M300 512 H650" fill="none" stroke="{ARROW}" stroke-width="118"
            stroke-linecap="round"/>
      <path d="M596 372 L790 512 L596 652 Z" fill="{ARROW}"/>
    </g>"""


def svg_icon() -> str:
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{W}" viewBox="0 0 {W} {W}">
{defs()}
  <rect x="0" y="0" width="{W}" height="{W}" rx="228" fill="url(#bg)"/>
  <rect x="0" y="0" width="{W}" height="{W}" rx="228" fill="url(#hl)"/>
  <g opacity="0.9">
    {grid_cells()}
  </g>
  {arrow(0.86, dx=-22, dy=22)}
</svg>"""


def svg_mark() -> str:
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{W}" viewBox="0 0 {W} {W}">
{defs()}
  {arrow(0.86, dx=-22, dy=22)}
</svg>"""


def svg_adaptive_fg() -> str:
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{W}" viewBox="0 0 {W} {W}">
{defs()}
  {arrow(0.60)}
</svg>"""


def render(svg: str, out: str, size: int) -> None:
    os.makedirs(os.path.dirname(out), exist_ok=True)
    cairosvg.svg2png(bytestring=svg.encode(), write_to=out,
                     output_width=size, output_height=size)


ADAPTIVE_XML = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
"""

BACKGROUND_XML = f"""<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="rectangle">
    <gradient
        android:startColor="{BG_TOP}"
        android:endColor="{BG_BOT}"
        android:angle="270" />
</shape>
"""


def main() -> None:
    render(svg_mark(), f"{ROOT}/assets/branding/logo.png", 512)
    for density, (icon_px, fg_px) in DENSITIES.items():
        base = f"{ROOT}/branding/android/mipmap-{density}"
        render(svg_icon(), f"{base}/ic_launcher.png", icon_px)
        render(svg_icon(), f"{base}/ic_launcher_round.png", icon_px)
        render(svg_adaptive_fg(), f"{base}/ic_launcher_foreground.png", fg_px)
        print(f"  mipmap-{density}: icon {icon_px}px, foreground {fg_px}px")
    with open(f"{ROOT}/branding/android/ic_launcher.xml", "w") as fh:
        fh.write(ADAPTIVE_XML)
    with open(f"{ROOT}/branding/android/ic_launcher_background.xml", "w") as fh:
        fh.write(BACKGROUND_XML)
    print("done: logo.png + launcher icons + adaptive icon xml")


if __name__ == "__main__":
    main()
