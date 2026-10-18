# ArrowQuest: Escape Puzzle

A relaxed, offline logic puzzle for Android (built to scale to iOS and tablets).

Every arrow is a little **path** of connected cells with a head at one end. Tap
an arrow and it slides along its own path and off the board — **if** the straight
run from its head to the edge is clear. If another arrow is in the way, the move
is refused, the arrow stays put, and you lose a heart. Lose all three and the
level starts again.

100 levels in one continuous run, no chapters: the boards get bigger, the paths
get longer and the tangles get worse as you go.

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

Coverage includes: all four direction vectors, clear/blocked exit detection,
collision on actual arrow cells (never bounding boxes), bent-path handling,
escape, undo, restart, hearts, the win condition, hint correctness (including
out-of-order play), duplicate-input prevention, level unlocking, the hint wallet,
the resume point, save/load, malformed-save recovery, malformed level rejection,
and structural + solvability checks across all 100 shipped levels.

## Levels

`assets/levels/levels.json` holds all 100 levels. They are **not** hand-written.
`tools/gen_levels.py` builds each one backwards from the solved state: an arrow
is only placed if its own exit ray is clear of the arrows that would still be
present when it is removed, and clear of its own body. That single check makes
the reverse of the placement order a guaranteed solution. Every finished level is
then replayed through an independent forward simulator and the greedy solver
before it is accepted.

```bash
python3 tools/gen_levels.py
```

| Levels | Board | Arrows | Difficulty |
| --- | --- | --- | --- |
| 1–15 | 7×7 – 8×8 | ~9–14 | Easy |
| 16–35 | 8×8 – 10×10 | ~14–17 | Easy |
| 36–70 | 10×10 – 13×13 | ~17–25 | Medium |
| 71–100 | 13×13 – 16×16 | ~25–41 | Hard |

Levels get steadily longer and denser; there are no chapters or categories.

## Hearts, hints and stars

- **Hearts:** three per attempt. A refused move costs one. Lose all three and the
  level restarts from the top.
- **Hints:** you start with 3. A hint always highlights an arrow that really can
  escape — it follows the level's reference solution, which stays valid however
  you have cleared things so far. When the wallet is empty you can earn one more
  by watching a rewarded ad.
- **Stars:** 1 for clearing the level, +1 for at most two refused attempts, +1
  for never using a hint. Time is never part of the score; the optional timer
  lives behind **Settings → Challenge mode** and is off by default.

Progress — unlocks, stars, statistics, the hint wallet and the level you were on
— is saved on the device, so closing the app never sends you back to level 1.

## Ads

The game ships with **Google's official test ad units**, so it shows demo ads and
builds without an AdMob account:

| Format | Where |
| --- | --- |
| Banner | Home, level map, level complete |
| Interstitial | When you tap *Next level* |
| Rewarded | Earn a hint from the play screen or the level complete screen |

Real unit ids are a one-line swap in `lib/core/services/ads_service.dart`, and the
AdMob app id is written into the manifest by the build workflow. Every ads call
is defensive — if the SDK is unavailable the game runs exactly as before.

## Android / iOS project folders

`android/` and `ios/` are intentionally **not** committed — a partial Gradle or
Xcode project is worse than none. The CI workflow generates `android/` from a
throwaway `flutter create` project, copies only that folder in, and then adds the
AdMob app id and the INTERNET permission.

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

Everything is local: level unlocks, stars, best results, statistics, the hint
wallet, the resume point and settings live in `shared_preferences`. There is no
account and no backend. Missing, malformed or outdated save data falls back to
defaults instead of breaking the game.

## Project layout

```
lib/
  main.dart                     entry point
  app.dart                      root widget / theming
  core/
    constants/                  app-wide constants
    theme/                      palette + Material 3 themes
    storage/                    progress + settings persistence
    services/                   ads, audio & haptics
  features/
    data/
      models/                   Dir, Arrow, ArrowSpec, Level, Difficulty
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
