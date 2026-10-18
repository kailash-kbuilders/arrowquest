PRODUCT REQUIREMENTS DOCUMENT (PRD)

ArrowQuest: Escape Puzzle

1. Product Overview

Build a complete, polished, production-ready Flutter puzzle game named ArrowQuest: Escape Puzzle.

Platform: Android first, with a responsive architecture suitable for iOS and tablets.

Framework: Flutter + Dart
Design: Material 3 with a custom premium puzzle-game interface
Game engine: Flutter CustomPainter, AnimationController, GestureDetector and native Flutter widgets
Gameplay: Offline-first, no mandatory login, no backend required.

The game must be fully playable. Do not deliver a static UI mockup, incomplete prototype, placeholder screens or buttons that do nothing.

2. Core Gameplay

The player sees a grid containing multiple arrows pointing in different directions.

Objective: Remove every arrow from the board by selecting arrows in a valid order.

Rules:

1. Each arrow has a direction: up, down, left or right.
2. Each arrow occupies a path made of connected grid cells.
3. When tapped, check the straight exit ray extending from its arrowhead in its facing direction.
4. If the exit ray is unobstructed by any remaining arrow cells, the selected arrow escapes beyond the board boundary.
5. Animate the entire arrow moving smoothly along its path and disappearing.
6. If another arrow blocks the exit ray, the move is rejected and a short, clear visual feedback animation is played.
7. Successfully removed arrows never return unless the player uses Undo.
8. The level is completed when every arrow has escaped.
9. Every level must be solvable. Never generate a deadlocked or impossible puzzle.
10. The game must never depend on random guessing to pass a level.

Use the arrow's actual occupied cells for collision checks, not merely its bounding rectangle.

3. Game Physics and Movement

This is a 2D grid-based logic game, not a rigid-body physics simulation.

Implement deterministic, grid-aware movement.

Arrow representation

Each arrow contains:

- Unique ID
- Ordered list of grid-cell coordinates
- Direction vector
- Head coordinate
- Visual color
- Current state: idle, selected, blocked, escaping or removed

Direction vectors:

- Up: (0, -1)
- Down: (0, 1)
- Left: (-1, 0)
- Right: (1, 0)

Collision detection

When a player selects an arrow:

- Identify its head cell and direction.
- Scan cells ahead of the head until reaching the board boundary.
- Ignore the selected arrow's own occupied cells.
- Check the occupied cells of all other active arrows.
- If any other arrow occupies the exit ray, reject the move.
- Otherwise, mark the arrow as escaping and remove it from collision occupancy at a deterministic point in the animation lifecycle.

Prevent double taps from starting duplicate escape animations.

Animation requirements

- Valid escape: approximately 250–450 ms.
- Blocked feedback: approximately 120–200 ms.
- Level completion: approximately 500–800 ms.
- Use smooth ease-out animation curves.
- Animate arrows beyond the visible board boundary before removing them.
- Keep input, collision state and rendered state synchronized.
- Avoid unnecessary widget rebuilds for every arrow on large boards.
- Support reduced-motion preferences.

Do not use a third-party physics engine for simple grid logic.

4. Mandatory 100 Levels

Create exactly 100 playable, curated level configurations for the initial release.

Difficulty progression:

- Levels 1–10: Tutorial and simple paths.
- Levels 11–20: Basic blockers and move ordering.
- Levels 21–35: Interconnected arrow paths.
- Levels 36–50: Medium-sized boards and longer dependency chains.
- Levels 51–65: Dense layouts requiring planning.
- Levels 66–80: Large, complex arrow arrangements.
- Levels 81–90: Advanced multi-step puzzles.
- Levels 91–100: Expert challenges and a special final level.

Suggested board sizes:

- Levels 1–10: 5×5 to 7×7.
- Levels 11–30: 7×7 to 9×9.
- Levels 31–60: 9×9 to 11×11.
- Levels 61–100: 11×11 to 14×14.

These are design targets, not rigid requirements. Adjust dimensions to maintain readability on small screens.

Level generation and validation

Prefer authored level data for the 100 initial levels.

Create a validation utility that:

1. Loads each level configuration.
2. Validates arrow coordinates and directions.
3. Rejects overlapping arrow cells.
4. Simulates legal escapes.
5. Uses a reverse-removal construction or a bounded solver to verify solvability.
6. Rejects malformed or impossible configurations.
7. Confirms the board can reach a state with zero remaining arrows.

Each level must have a valid solution sequence. Store a known solution for testing and optional hints.

Do not claim that levels are tested unless automated tests actually validate them.

5. Screens and UI

A. Splash Screen

- Original ArrowQuest logo.
- Animated arrow motif.
- Dark navy background with subtle blue-purple gradient.
- Short loading transition.
- No artificial loading delay.

B. Home Screen

Premium, modern layout containing:

- ArrowQuest title and logo.
- Large Continue button.
- Play Levels button.
- Daily Puzzle button.
- Statistics button.
- Settings button.
- Current level and total progress.
- Subtle background grid and animated arrow decorations.

All buttons must navigate to functional screens.

C. Level Selection

- Display levels 1–100 in a scrollable grid or winding level path.
- Show completed, unlocked and locked states.
- Show earned stars on completed levels.
- Unlock the next level after completion.
- Allow replaying previously unlocked levels.
- Persist level unlocks and completion progress.
- Clearly indicate the current level.

D. Gameplay Screen

Top bar:

- Back button.
- Level number.
- Restart button.
- Settings or pause button.

Information row:

- Progress counter, such as 12/30 arrows cleared.
- Optional level timer only in a separately enabled challenge mode.
- Hint and Undo controls.

Main board:

- Centered responsive square grid.
- Rounded arrow bodies with clearly visible heads.
- Original, high-contrast color palette.
- Subtle board background and cell spacing.
- Smooth arrow escape animation.
- Support large boards through zoom and pan.
- Prevent board gestures from interfering with unrelated UI controls.

Bottom area:

- Hint button.
- Undo button.
- Restart action.
- Optional help button.

Keep the board as the main visual focus. Do not overcrowd the screen with banners or unnecessary panels.

E. Level Complete Screen

Show:

- Animated completion effect.
- Level number.
- Arrows cleared.
- Time taken, when applicable.
- Up to three earned stars.
- Replay button.
- Next Level button.
- Home button.

The Next Level button must load the next unlocked level correctly.

F. Settings Screen

Functional options:

- Sound on/off.
- Music on/off if music is implemented.
- Vibration on/off.
- Reduced motion on/off.
- Theme selection.
- Reset progress with confirmation.
- About and version information.

6. Hint, Undo and Restart

Hint:

- Highlight an arrow that can legally escape.
- Prefer a valid move that unlocks more arrows.
- Use the stored solution when necessary.
- Never highlight an impossible move as the answer.

Undo:

- Restore the most recent successful move.
- Restore the arrow to its original coordinates and active state.
- Reverse associated progress counters correctly.
- Do not allow undo during an incompatible animation state.

Restart:

- Restore the exact initial state of the current level.
- Reset level-specific counters and temporary effects.
- Ask for confirmation only when useful.

Hints may initially be unlimited in the offline prototype. If a hint currency system is implemented, make the rules transparent and avoid paywalls that prevent puzzle completion.

7. Stars and Progress

Award zero to three stars based on a transparent scoring system.

Possible criteria:

- Complete the level.
- Minimize incorrect attempts.
- Use fewer hints.

Do not punish players unfairly for taking their time. If a timer is enabled, keep it separate from the default relaxed mode.

Track:

- Highest unlocked level.
- Levels completed.
- Total arrows removed.
- Total play time.
- Total hints used.
- Total mistakes.
- Best result per level.
- Total stars earned.

Save progress locally on the device.

8. Visual Design System

Create a polished original visual identity.

Default theme:

- Background: deep navy.
- Panels: slightly lighter navy.
- Primary accent: electric blue.
- Secondary accent: violet.
- Success: mint green.
- Error: soft coral.
- Text: high-contrast white and muted blue-gray.

Provide an optional light theme.

UI requirements:

- Material 3 foundations with custom styling.
- Rounded cards and buttons.
- Consistent typography and spacing.
- Responsive layouts for small Android phones, tablets and larger screens.
- Respect device safe areas and system navigation bars.
- Minimum comfortable touch targets of approximately 48 logical pixels.
- Avoid overflow, clipped text and tiny arrows.
- Avoid excessive gradients, blur effects and expensive shadows.

Use CustomPainter for the board where appropriate. Keep arrow paths and grid coordinates independent from screen pixel dimensions.

9. Audio and Haptics

Provide optional lightweight sound effects:

- Button tap.
- Successful escape.
- Blocked arrow.
- Level completion.

Use vibration only when supported and enabled.

The game must work when sound or vibration is unavailable.

Do not allow missing audio assets to crash the application.

10. Local Storage and Offline Mode

All core gameplay must work without an internet connection.

Persist:

- Level completion and unlocks.
- Star scores.
- Current level.
- Settings.
- Statistics.

Save unfinished level state if practical.

Use a reliable, lightweight local-storage solution compatible with the project's actual Dart SDK. Handle missing, malformed or outdated save data safely.

A fresh installation must launch correctly with default progress.

Do not require Firebase, an account, network permission or a remote server for the core game.

11. Flutter Architecture

Use a maintainable feature-based structure, for example:

lib/
main.dart
app.dart
core/
constants/
theme/
storage/
features/
home/
levels/
gameplay/
models/
logic/
rendering/
widgets/
settings/
statistics/
data/
levels/
repositories/

Keep these concerns separate:

- Puzzle rules and collision detection.
- Level definitions and validation.
- Animation and rendering.
- UI state.
- Persistent storage.

Use immutable models where practical and predictable state transitions.

Avoid unnecessary dependencies. Prefer built-in Flutter and Dart APIs when they are sufficient.

12. Error Prevention Requirements

The agent must:

- Inspect the installed Flutter and Dart versions before selecting dependency versions.
- Select dependency versions compatible with the actual SDK.
- Never use packages requiring a newer Dart SDK than the build environment provides.
- Generate every referenced Dart file and asset.
- Avoid missing imports, undefined methods and incomplete constructors.
- Use null-safe Dart code.
- Provide valid MaterialApp configuration and a working main() entry point.
- Avoid deprecated APIs when a compatible alternative exists.
- Include fallback handling for corrupted local saves.
- Ensure no buttons or gestures cause duplicate state updates.
- Ensure every level has valid, unique arrow IDs.
- Ensure level 100 completes without loading a nonexistent level 101.
- Ensure reset progress works correctly.
- Keep the game functional on first launch with no network.

Do not suppress real compilation errors merely to obtain a successful build.

13. Automated Testing

Write unit tests for:

- All four direction vectors.
- Clear exit detection.
- Blocked exit detection.
- Collision detection using actual arrow cells.
- Successful escape.
- Undo and restart.
- Win condition.
- Level unlocking.
- Save/load behavior.
- Malformed level rejection.
- All 100 levels' structural validity and solvability.
- Boundary conditions and duplicate input prevention.

Add widget tests for:

- Home screen navigation.
- Level selection.
- Starting a level.
- Hint and Undo buttons.
- Level completion and Next Level navigation.
- Settings persistence.

Add a smoke test that launches the app and verifies that the home screen renders without exceptions.

14. GitHub Actions APK Workflow

Create:

.github/workflows/build-apk.yml

Workflow requirements:

- Trigger on push, pull request and manual dispatch.
- Use a stable Ubuntu runner.
- Install a compatible stable Flutter SDK.
- Run flutter --version.
- Run flutter pub get.
- Run dart format --output=none --set-exit-if-changed .
- Run flutter analyze.
- Run flutter test.
- Build the release APK using flutter build apk --release.
- Upload the generated APK as a GitHub Actions artifact.
- Use clear step names and fail the workflow when required checks fail.

Use a pinned Flutter version compatible with the project's minimum SDK requirements. Do not rely on unverified system defaults.

Artifact path:
build/app/outputs/flutter-apk/app-release.apk

Document how to download the APK from the successful workflow run.

15. Definition of Done

The project is complete only when:

- The Flutter app compiles successfully.
- All 100 levels are present and playable.
- Every level has a verified solution.
- Arrow movement and collision logic work correctly.
- The home screen, level map, gameplay and completion screens are functional.
- Local progress survives an app restart.
- Undo, Hint and Restart behave correctly.
- No missing asset or undefined method errors remain.
- Automated tests pass.
- Flutter analysis has no errors.
- A release APK can be generated locally or by GitHub Actions.

16. Required Deliverables

Return:

1. Complete Flutter source code.
2. All 100 level definitions.
3. Every required asset or a working procedural replacement.
4. All automated tests.
5. GitHub Actions APK workflow.
6. README with setup and build instructions.
7. A clear list of completed features.
8. Actual test and build results.

Do not return only a PRD summary, screenshots, pseudocode or partial files.

First inspect the available environment, then implement the complete project. Run dependency resolution, formatting, static analysis, tests and the release build where the environment permits. Fix actual errors before declaring the project complete.