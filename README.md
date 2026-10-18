# ArrowQuest: Escape Puzzle

A relaxed, offline logic puzzle for Android (built to scale to iOS and tablets).

Each level is a board of arrows. Tap an arrow and it shoots out in the direction
it points — **if** the straight path from its head to the edge is clear. If any
other arrow is in the way, the move is refused and the arrow stays put. Clear
every arrow to finish the level.

100 hand-curated levels, ten chapters, no timers by default and no randomness:
a level is a fixed little machine, and the whole skill is reading it.

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

The rules live in `lib/features/gameplay/logic/engine.dart` — pure Dart, no
Flutter imports — so the game logic is unit tested independently of the UI.
`lib/features/gameplay/logic/solver.dart` is a second, independent solvability
checker used to verify the level pack.

Test coverage includes: all four direction vectors, clear/blocked exit
detection, collision on actual arrow cells (not bounding boxes), escape, undo,
restart, the win condition, hint selection, duplicate-input prevention, level
unlocking, save/load, malformed-save recovery, malformed level rejection, and
structural + solvability checks across all 100 shipped levels.

## Levels

`assets/levels/levels.json` holds all 100 levels. They are **not** hand-written.
`tools/gen_levels.py` builds each one backwards from the solved state — an arrow
is only placed if its own exit ray is clear of the arrows that would still be
present when it is removed, which makes the reverse of the placement order a
guaranteed solution. Each finished level is then replayed through an independent
forward simulator and the greedy solver in `solver.dart` before it is accepted.

```bash
python3 tools/gen_levels.py
```

| Levels | Board | Chapter |
| --- | --- | --- |
| 1–10 | 5×5 – 7×7 | First Steps |
| 11–20 | 7×7 – 8×8 | Getting Blocked |
| 21–30 | 8×8 – 9×9 | Crossings |
| 31–40 | 9×9 – 10×10 | Tangled |
| 41–50 | 10×10 | Long Chains |
| 51–60 | 10×10 – 11×11 | Dense |
| 61–70 | 11×11 – 12×12 | Maze |
| 71–80 | 12×12 | Complex |
| 81–90 | 13×13 | Advanced |
| 91–100 | 13×13 – 14×14 | Expert |

## Stars

Deliberately transparent, and never punishing you for taking your time:

| Stars | Rule |
| --- | --- |
| ★ | Clear the level |
| ★★ | …and make at most two rejected attempts |
| ★★★ | …and never use a hint |

Time is never part of the score. The optional timer lives behind
**Settings → Challenge mode** and is off by default.

## Android / iOS project folders

`android/` and `ios/` are intentionally **not** committed — a partial Gradle or
Xcode project is worse than none. The CI workflow generates `android/` from a
throwaway `flutter create` project and copies only that folder in.

To work on the native projects locally:

```bash
flutter create . --platforms=android,ios
```

## Building the APK

`.github/workflows/build-apk.yml` builds the release APK on every push, pull
request and manual run, and uploads it as the `release-apk` artifact.

- **From CI:** open the repo's **Actions** tab → the latest *Build APK* run →
  **Artifacts** → download `release-apk`.
- **As a proper release:** run the workflow manually
  (*Actions → Build APK → Run workflow*), or push a `v*` tag. The APK is then
  attached to a GitHub Release.

Locally:

```bash
flutter build apk --release --no-shrink
# -> build/app/outputs/flutter-apk/app-release.apk
```

The workflow runs `dart format` (applied, then verified), `flutter analyze`
(failing only on real analyzer errors, not style infos) and `flutter test`
before building, so a broken build is caught early rather than shipped.

## Storage

Everything is local: level unlocks, stars, best results, statistics and
settings live in `shared_preferences`. There is no account, no backend, no ads
and no network permission. Missing, malformed or outdated save data falls back
to defaults instead of breaking the game.

## Project layout

```
lib/
  main.dart                     entry point
  app.dart                      root widget / theming
  core/
    constants/                  app-wide constants
    theme/                      palette + Material 3 themes
    storage/                    progress + settings persistence
    services/                   audio & haptics
  features/
    data/
      models/                   Dir, Arrow, ArrowSpec, Level
      levels/                   level pack loader
    gameplay/
      logic/                    rules engine + solvability solver
      rendering/                CustomPainter board
      widgets/                  board view + action bar
    home/                       splash + menu
    levels/                     level map + level complete
    settings/                   settings screen
    statistics/                 statistics screen
```
