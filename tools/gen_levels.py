#!/usr/bin/env python3
"""Generate the ArrowQuest level pack (100 levels).

Mechanic (see docs/PRD.md)
--------------------------
The board holds arrows. Each arrow is a straight path of connected cells with a
head at its leading end and a facing direction. Tapping an arrow checks the
straight exit ray that runs from its head to the board edge:

  * ray clear of every other arrow  -> the whole arrow escapes off the board;
  * ray blocked by another arrow    -> the move is rejected (the arrow does not
    move at all).

Clear every arrow to finish.

Why generated levels can never be unsolvable
--------------------------------------------
A level is built *backwards from the solved state*. We place arrows one at a
time in reverse removal order. When an arrow is placed, the arrows already on
the board are exactly the ones that would still be present when it is removed
in the forward game — so we only have to insist that its own exit ray is clear
of them. That single check guarantees the reverse of the placement order is a
valid forward solution.

Each finished level is then replayed through an independent forward simulator
(and a monotone greedy solver) before it is accepted; nothing ships unless the
replay clears the board.
"""
import json
import os
import random

DIRS = {"U": (-1, 0), "D": (1, 0), "L": (0, -1), "R": (0, 1)}

CHAPTERS = [
    "First Steps", "Getting Blocked", "Crossings", "Tangled", "Long Chains",
    "Dense", "Maze", "Complex", "Advanced", "Expert",
]

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                   "assets", "levels", "levels.json")


def cells(r, c, d, length):
    dr, dc = DIRS[d]
    return [(r - i * dr, c - i * dc) for i in range(length)]


def ray(r, c, d, rows, cols):
    dr, dc = DIRS[d]
    out = []
    nr, nc = r + dr, c + dc
    while 0 <= nr < rows and 0 <= nc < cols:
        out.append((nr, nc))
        nr += dr
        nc += dc
    return out


def build_level(rows, cols, target_arrows, max_len, block_bias, rng):
    """Return (arrows, solution) or None.

    arrows   : list of (r, c, d, length) in board order
    solution : list of (r, c) heads, in the order they must be cleared
    """
    occupied = {}          # cell -> arrow index
    placed = []            # reverse removal order (last removed first)

    for _ in range(target_arrows):
        blocking, plain = [], []
        for r in range(rows):
            for c in range(cols):
                if (r, c) in occupied:
                    continue
                for d in DIRS:
                    for length in range(1, max_len + 1):
                        cs = cells(r, c, d, length)
                        if any(not (0 <= cr < rows and 0 <= cc < cols)
                               for cr, cc in cs):
                            break
                        if any(cell in occupied for cell in cs):
                            break
                        rc = ray(r, c, d, rows, cols)
                        if not rc:
                            continue
                        if any(cell in occupied for cell in rc):
                            continue

                        # Does this arrow sit in the exit ray of an arrow
                        # already on the board? That is what makes a level hard.
                        blocks = 0
                        for (orow, ocol, od, olen) in placed:
                            if any(cell in set(ray(orow, ocol, od, rows, cols))
                                   for cell in cs):
                                blocks += 1

                        entry = (len(rc), blocks, r, c, d, length)
                        (blocking if blocks else plain).append(entry)

        pool = plain
        if blocking and rng.random() < block_bias:
            pool = blocking
        if not pool:
            pool = blocking or plain
        if not pool:
            break

        pool.sort(key=lambda t: (-t[0], -t[1]))
        top = pool[: max(1, len(pool) // 3)]
        _, _, r, c, d, length = rng.choice(top)
        for cell in cells(r, c, d, length):
            occupied[cell] = len(placed)
        placed.append((r, c, d, length))

    if len(placed) < 3:
        return None

    arrows = list(reversed(placed))          # board / placement order
    solution = [(r, c) for (r, c, _d, _l) in reversed(placed)]
    return arrows, solution


def simulate(arrows, solution, rows, cols):
    """Replay the recorded solution. True iff the board ends empty."""
    occupied = set()
    for (r, c, d, length) in arrows:
        occupied.update(cells(r, c, d, length))

    for (r, c) in solution:
        d = None
        length = 0
        for (ar, ac, ad, al) in arrows:
            if (ar, ac) == (r, c):
                d, length = ad, al
                break
        if d is None:
            return False
        body = cells(r, c, d, length)
        if any(cell not in occupied for cell in body):
            return False
        if any(cell in occupied for cell in ray(r, c, d, rows, cols)):
            return False
        for cell in body:
            occupied.discard(cell)
    return not occupied


def greedy_solvable(arrows, rows, cols):
    """Independent monotone solver: repeatedly remove any clear arrow."""
    remaining = list(arrows)
    changed = True
    while changed:
        changed = False
        occupied = set()
        for (r, c, d, length) in remaining:
            occupied.update(cells(r, c, d, length))
        keep = []
        for a in remaining:
            r, c, d, length = a
            if any(cell in occupied for cell in ray(r, c, d, rows, cols)):
                keep.append(a)
            else:
                changed = True
        remaining = keep
    return not remaining


def validate(arrows, rows, cols):
    seen = set()
    for (r, c, d, length) in arrows:
        if d not in DIRS:
            return False
        if length < 1:
            return False
        for (cr, cc) in cells(r, c, d, length):
            if not (0 <= cr < rows and 0 <= cc < cols):
                return False
            if (cr, cc) in seen:
                return False
            seen.add((cr, cc))
    return True


def blocked_count(arrows, rows, cols):
    occupied = set()
    for (r, c, d, length) in arrows:
        occupied.update(cells(r, c, d, length))
    n = 0
    for (r, c, d, length) in arrows:
        if any(cell in occupied for cell in ray(r, c, d, rows, cols)):
            n += 1
    return n


def params(i):
    if i <= 10:
        lo, hi = 5, 7
    elif i <= 30:
        lo, hi = 7, 9
    elif i <= 60:
        lo, hi = 9, 11
    else:
        lo, hi = 11, 14
    span = hi - lo
    band_start = {5: 1, 7: 11, 9: 31, 11: 61}[lo]
    band_len = {5: 10, 7: 20, 9: 30, 11: 40}[lo]
    frac = (i - band_start) / max(1, band_len - 1)
    size = lo + round(frac * span)

    density = 0.24 + 0.22 * (i / 100.0)
    target = max(3, int(round(size * size * density)))

    if i <= 10:
        max_len, block_bias = 1, 0.0
    elif i <= 30:
        max_len, block_bias = 2, 0.35
    elif i <= 60:
        max_len, block_bias = 3, 0.55
    else:
        max_len, block_bias = 4, 0.7
    return size, size, target, max_len, block_bias


def main():
    rng = random.Random(20261018)
    levels = []
    for i in range(1, 101):
        rows, cols, target, max_len, block_bias = params(i)
        chosen = None
        for _ in range(120):
            got = build_level(rows, cols, target, max_len, block_bias, rng)
            if got is None:
                continue
            arrows, solution = got
            if not validate(arrows, rows, cols):
                continue
            if not simulate(arrows, solution, rows, cols):
                continue
            if not greedy_solvable(arrows, rows, cols):
                continue
            if i > 10 and blocked_count(arrows, rows, cols) < 2:
                continue
            chosen = (arrows, solution)
            break
        if chosen is None:
            for _ in range(200):
                got = build_level(rows, cols, max(3, target - 4), max_len,
                                  block_bias, rng)
                if got is None:
                    continue
                arrows, solution = got
                if validate(arrows, rows, cols) and \
                        simulate(arrows, solution, rows, cols) and \
                        greedy_solvable(arrows, rows, cols):
                    chosen = (arrows, solution)
                    break
        if chosen is None:
            raise SystemExit(f"could not build level {i}")
        arrows, solution = chosen
        assert simulate(arrows, solution, rows, cols), f"level {i} failed"
        assert greedy_solvable(arrows, rows, cols), f"level {i} unsolvable"

        levels.append({
            "id": i,
            "chapter": CHAPTERS[(i - 1) // 10],
            "rows": rows,
            "cols": cols,
            "par": len(solution),
            "solution": [{"r": r, "c": c} for (r, c) in solution],
            "arrows": [
                {"r": r, "c": c, "d": d, "len": length}
                for (r, c, d, length) in arrows
            ],
        })
        print(f"L{i:>3} {rows:>2}x{cols:<2} arrows={len(arrows):>3} "
              f"blocked={blocked_count(arrows, rows, cols):>3} "
              f"sol={len(solution):>3}")

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w") as fh:
        json.dump({"levels": levels}, fh, indent=1)
    print(f"\nwrote {len(levels)} levels -> {OUT}")


if __name__ == "__main__":
    main()
