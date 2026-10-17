# Branding

The Hue Rush mark is a **switchback ribbon**: it flows right, turns, and doubles
back — which is the game's core verb, flipping the rail's direction. It grows
out of a rounded tile (the emitter chip) and its colour sweeps top-to-bottom
through three of the game's own hues.

Everything is axis-aligned geometry, one stroke weight, round joins, and a
single restrained three-stop gradient — deliberately designed rather than a
rainbow mesh.

## Files

| Path | What it is |
| --- | --- |
| `android/mipmap-<density>/ic_launcher.png` | legacy launcher icon |
| `android/mipmap-<density>/ic_launcher_foreground.png` | adaptive icon foreground (inside the 66% safe zone) |
| `android/ic_launcher.xml` | adaptive-icon descriptor |
| `android/ic_launcher_background.xml` | gradient adaptive background |
| `../assets/branding/logo.png` | the mark shown on the home screen |
| `generate.py` | the vector source — regenerates every file above |

## How the icons reach the build

`android/` is generated fresh on every CI run, so these files are **not**
committed into it. The `Install launcher icons` step in
`.github/workflows/build-apk.yml` copies them into
`android/app/src/main/res/` right before the APK is built.

## Regenerating

```bash
pip install cairosvg
python branding/generate.py
```

The script writes `assets/branding/logo.png` and the `android/` icon set in
place.
