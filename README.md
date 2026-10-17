# Quiver

An arrow-clearing puzzle. Tap an arrow and it slides out in the direction it
points — unless another arrow is in the way, in which case it stops right
there. Clear every arrow to finish the level.

100 levels, five chapters, no timers and no randomness: a level is a fixed
little machine and the whole skill is reading it.

- **Product requirements:** [`docs/PRD.md`](docs/PRD.md)
- **Branding:** [`branding/README.md`](branding/README.md)

## Run locally

```bash
flutter pub get
flutter run
```

## Tests

```bash
flutter test
```

The rules live in `lib/engine/quiver_engine.dart` — pure Dart, no Flutter
imports — so the game logic is unit tested independently of the UI.

## Levels

`assets/levels/levels.json` holds all 100 levels. They are **not** hand-written.
`tools/gen_levels.py` builds each one backwards from the solved state and then
replays the resulting solution through an independent forward simulator, so a
level cannot ship unless it is provably solvable.

```bash
python3 tools/gen_levels.py
```

## Android / iOS project folders

`android/` and `ios/` are not committed. The GitHub Actions workflow generates
`android/` when it builds the APK. For iOS or the desktop platforms locally:

```bash
flutter create . --platforms=ios,windows,macos,linux
```

iOS builds need macOS with Xcode.

## Build the APK

Push to `main`, or run the **Build APK** workflow from the Actions tab. The
release APK is attached to the run, and a manual run or a `v*` tag also
publishes it to a GitHub Release.
