#!/usr/bin/env python3
"""Render the Hue Rush brand mark into every asset the project needs.

Outputs (relative to the Flutter project root):
  assets/branding/logo.png                     -> shown on the home screen
  branding/android/mipmap-<density>/ic_launcher.png
  branding/android/mipmap-<density>/ic_launcher_foreground.png
  branding/android/ic_launcher_background.xml  -> gradient adaptive background
  branding/android/ic_launcher.xml             -> adaptive-icon descriptor

The android/* files live outside assets/ on purpose: they are build inputs the
CI workflow copies into the generated android/ folder, not app-bundled assets.
"""
import os

import cairosvg

W = 1024
BG_TOP = "#2A1D5E"
BG_BOT = "#0C0C14"
C1 = "#9A6BFF"
C2 = "#E93D82"
C3 = "#FF8A3D"

RIBBON = "M300 372 H700 V652 H340"
STROKE = 120
DX, DY = 16, -29

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# density -> (legacy icon px, adaptive foreground px)   [48dp / 108dp baselines]
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
    <radialGradient id="hl" gradientUnits="userSpaceOnUse" cx="380" cy="300" r="640">
      <stop offset="0" stop-color="#9A8BFF" stop-opacity="0.40"/>
      <stop offset="1" stop-color="#9A8BFF" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="rib" gradientUnits="userSpaceOnUse" x1="0" y1="300" x2="0" y2="740">
      <stop offset="0" stop-color="{C1}"/>
      <stop offset="0.52" stop-color="{C2}"/>
      <stop offset="1" stop-color="{C3}"/>
    </linearGradient>
  </defs>"""


def _inner(halo=0.16) -> str:
    return f"""
    <path d="{RIBBON}" fill="none" stroke="#7C6CFF" stroke-width="176"
          stroke-linecap="round" stroke-linejoin="round" opacity="{halo}"/>
    <path d="{RIBBON}" fill="none" stroke="{C2}" stroke-width="146"
          stroke-linecap="round" stroke-linejoin="round" opacity="{halo * 0.9:.3f}"/>
    <rect x="234" y="306" width="132" height="132" rx="36" fill="url(#rib)"/>
    <path d="{RIBBON}" fill="none" stroke="url(#rib)" stroke-width="{STROKE}"
          stroke-linecap="round" stroke-linejoin="round"/>
    <path d="M232 652 L392 528 L352 652 L392 776 Z" fill="url(#rib)"/>"""


def mark(scale: float, halo=0.16) -> str:
    return (f'<g transform="translate({DX} {DY}) translate(512 512) '
            f'scale({scale}) translate(-512 -512)">{_inner(halo)}</g>')


def svg_icon(halo=0.20) -> str:
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{W}" viewBox="0 0 {W} {W}">
{defs()}
  <rect x="0" y="0" width="{W}" height="{W}" rx="228" fill="url(#bg)"/>
  <rect x="0" y="0" width="{W}" height="{W}" rx="228" fill="url(#hl)"/>
  {mark(0.84, halo)}
</svg>"""


def svg_mark(halo=0.14) -> str:
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{W}" viewBox="0 0 {W} {W}">
{defs()}
  {mark(0.84, halo)}
</svg>"""


def svg_adaptive_fg(halo=0.16) -> str:
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{W}" viewBox="0 0 {W} {W}">
{defs()}
  {mark(0.60, halo)}
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
    icon_svg = svg_icon()
    fg_svg = svg_adaptive_fg()
    mark_svg = svg_mark()

    # In-app logo (home screen).
    render(mark_svg, f"{ROOT}/assets/branding/logo.png", 512)

    # Launcher icons.
    for density, (icon_px, fg_px) in DENSITIES.items():
        base = f"{ROOT}/branding/android/mipmap-{density}"
        render(icon_svg, f"{base}/ic_launcher.png", icon_px)
        render(icon_svg, f"{base}/ic_launcher_round.png", icon_px)
        render(fg_svg, f"{base}/ic_launcher_foreground.png", fg_px)
        print(f"  mipmap-{density}: icon {icon_px}px, foreground {fg_px}px")

    with open(f"{ROOT}/branding/android/ic_launcher.xml", "w") as fh:
        fh.write(ADAPTIVE_XML)
    with open(f"{ROOT}/branding/android/ic_launcher_background.xml", "w") as fh:
        fh.write(BACKGROUND_XML)

    print("done: logo.png + launcher icons + adaptive icon xml")


if __name__ == "__main__":
    main()
