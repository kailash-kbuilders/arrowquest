# Quiver — Product Requirements Document

**Game:** Quiver
**Genre:** Grid logic puzzle (hybridcasual)
**Platforms:** Android + iOS, one Flutter codebase
**Owner:** The American Pulse
**Version:** 1.0 · 17 Oct 2026

> Note: "Quiver" is a working title. Run a trademark and store-name check before
> launch — the same caution the previous title carried.

---

## 1. Vision

**One-liner:** "Tap an arrow and it flies out in the direction it points — unless
something is in the way."

Quiver is a grid puzzle you understand in three seconds and then think about for
thirty. Every arrow wants to leave the board. Some can, some are jammed behind
another arrow, and clearing the wrong one first can box you in. There is no
timer, no lives and no randomness: a level is a fixed little machine, and the
whole skill is reading it.

**Business goal:** a calm, high-retention puzzle with a large hand-tuned level
pack, cheap to produce because levels are generated and machine-verified, and
easy to extend chapter by chapter.

---

## 2. Audience

- Puzzle players who want a quiet brain-break in portrait, one-handed.
- Fans of arrow / block / traffic-clearing puzzles — a large, proven audience.
- Sessions of 60–120 seconds; a level is meant to be finished in one sitting.

---

## 3. Core loop

1. A grid of arrows appears. Each arrow points up, down, left or right.
2. Tap an arrow. It slides in its own direction.
3. It stops the moment the next cell holds another arrow — or slides clean off
   the board if it reaches the edge first.
4. An arrow with another arrow directly in front of it cannot move at all.
5. Clear every arrow to finish the level. Next level unlocks.

---

## 4. Mechanics

### 4.1 The board
A square grid, 4×4 early, 8×8 late. Cells are empty or hold exactly one arrow.
Arrows are coloured by the direction they point — up, down, left, right — which
is what makes a dense board readable at a glance.

### 4.2 The slide
One tap resolves a whole slide, not a single step. This is what keeps the game
snappy: the tap count per level stays close to the arrow count, so a 26-arrow
level is roughly 30 taps, not 200.

### 4.3 Blocking (the whole puzzle)
An arrow is *jammed* when its very next cell is occupied. Jams are what make a
level a puzzle rather than a chore: you must move the blocker out of the way
first, and moving a blocker is itself a slide that can jam something else.

### 4.4 Failure
There is no fail screen and no move limit. A board can be played into a dead
end, but Undo and Restart are always one tap away, and every shipped level is
provably solvable (see §5.2), so a level is never lost — only unsolved.

### 4.5 Hint
The Hint button pulses one arrow that can currently move. It reveals a legal
move, not the solution, so it helps a stuck player without solving the level for
them.

---

## 5. Level design

### 5.1 Content
100 levels at launch, in five chapters of twenty:

| Chapter | Levels | Board | Feel |
| --- | --- | --- | --- |
| First Flight | 1–20 | 4×4 → 5×5 | teach the slide, then the jam |
| Sidewinder | 21–40 | 5×5 → 6×6 | longer chains of blockers |
| Crossfire | 41–60 | 6×6 | arrows whose paths cross |
| Knotwork | 61–80 | 7×7 | dense, several ways to go wrong |
| Overdrive | 81–100 | 8×8 | 20+ arrows, most of them jammed |

The curve is real, not cosmetic: level 1 is four free arrows on a 4×4; level 100
is 26 arrows on an 8×8 with 11 of them jammed and a 39-move solution.

### 5.2 Solvability is guaranteed, not hoped for
Levels are built **backwards from the solved state** (see `tools/gen_levels.py`).
Starting from an empty board, the generator repeatedly *undoes* a move:

- **un-exit** — place a new arrow on a cell whose ray to the edge is empty.
  Forward, that arrow slides straight off the board.
- **un-slide** — take an arrow that is currently blocked and push it back along
  its own line. Forward, it slides back and stops where it was.

Placement is biased towards cells that block an existing arrow, which is what
creates difficulty. Each undo step appends its forward move to a solution, and
that solution is then **replayed through an independent forward simulator**
before the level is accepted. Nothing ships unless the replay clears the board.
This is why the pack has no dead levels and no hand-verification step.

### 5.3 Difficulty metric
`score = board area × 0.9 + arrows × 4 + jammed arrows × 7 + solution length × 0.5`

Used to keep the pack monotonic — later levels always score higher.

---

## 6. UX and screens

`Splash → Home → Level map → Gameplay`

- **Home** — mark, title, PLAY, How to play, Settings.
- **Level map** — five chapter sections, five-across level grid, locked /
  available / cleared states, progress unlocked one level at a time.
- **Gameplay** — MOVES · ARROWS · BEST across the top, board in the middle,
  Undo · Restart · Hint underneath.
- **Win** — moves used, best score, then Next or back to the map.
- **Settings** — sound, haptics, levels cleared, privacy note.

Onboarding is the first six levels: no blocking at all, so the slide teaches
itself.

---

## 7. Art and audio

- **Art:** flat, bold, high-contrast. One colour per direction; a dark board so
  the arrows do the talking. The mark is a single chunky arrow flying out of a
  faint grid of cells.
- **Feedback:** slide animates with an ease-out curve; a cleared arrow leaves
  the board.
- **Audio / haptics:** light tick on a slide, soft click on a clear, a dull thud
  on a jammed tap. (Wired to the Settings toggles; sounds are a later pass.)

---

## 8. Tech

- Flutter, single codebase, Android + iOS.
- `shared_preferences` for progress and best-move scores. No account, no
  network, nothing leaves the device.
- Levels are JSON (`assets/levels/levels.json`), generated and verified offline
  by `tools/gen_levels.py`.
- Rules live in a pure-Dart `QuiverEngine` with no Flutter imports, so the game
  logic is unit tested independently of the UI.
- Target: 60 fps on mid-range Android, sub-2s cold start.

---

## 9. Monetization

Deliberately **off in this build**. The plan, for later:

- Rewarded video: reveal a fuller solution, or skip a level.
- Interstitial: every few levels, capped, never straight after a rewarded ad.
- One clean "remove ads" purchase.

The AdMob integration was built and then removed: it was the prime suspect for a
launch crash on device, and a game that opens beats a game with ads. It returns
once the cause is settled, with a Play Services availability check and a
rewarded-only start.

---

## 10. Milestones

- **M0 — playable core (done):** engine, board, 100 verified levels, level map,
  progress, branding.
- **M1 — feel:** sound, haptics, clear animations, first-run polish.
- **M2 — meta:** daily puzzle, chapter-end celebrations, a solver-backed hint.
- **M3 — monetization:** ads back on, tuned, with analytics on the level funnel.
- **M4 — content:** chapters 6+, new obstacles (one-way cells, fixed blocks).

---

## 11. Risks

- **Shallow read:** dense boards can feel like "tap whatever moves". Mitigation:
  the generator deliberately creates jams, and late levels have 10+ jammed
  arrows, so reading the board is the puzzle.
- **Too easy to brute force:** Undo makes trial-and-error cheap. Mitigation: BEST
  move score per level gives a reason to play it properly.
- **Genre saturation:** arrow puzzles are crowded. Mitigation: the clean
  slide-off-the-edge verb and a distinct visual identity; no clone keywords.
- **Content cost:** solved — levels are generated and machine-verified.

---

## 12. Open questions

- Does Undo make late levels too forgiving? Playtest with and without.
- Is one Hint enough, or does a stuck player want a full solution reveal?
- Chapter theme pass — should boards get per-chapter skins?
- Final name and trademark clearance.
