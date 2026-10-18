# Branding

The ArrowQuest mark is one chunky arrow flying out of a faint grid of board cells —
the game in a single glance. Two flat colours, one restrained background
gradient, rounded joins throughout. Deliberately designed rather than an AI
gradient mesh.

## Files

| Path | What it is |
| --- | --- |
| `android/mipmap-<density>/ic_launcher.png` | legacy launcher icon |
| `android/mipmap-<density>/ic_launcher_round.png` | round launcher icon |
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
