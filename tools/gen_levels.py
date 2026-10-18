#!/usr/bin/env python3
"""Generate the ArrowQuest level pack (100 levels).

Mechanic
--------
Each arrow is a *bent path* of connected cells with a head at one end and a
facing direction. Tapping an arrow scans the straight exit ray from its head to
the board edge:

  * ray clear of every other arrow -> the whole arrow slides along its own path
    and off the board;
  * ray blocked by another arrow   -> the move is refused and the arrow stays.

Clear every arrow to finish.

Why generated levels can never be unsolvable
--------------------------------------------
A level is built backwards from the solved state. Arrows are placed one at a
time in reverse removal order; when an arrow is placed, the arrows already on
the board are exactly the ones still present when it is removed in the forward
game. So a single check — "this arrow's exit ray is clear of the arrows already
placed, and clear of its own body" — guarantees the reverse of the placement
order is a valid solution.

Every finished level is replayed through an independent forward simulator and a
monotone greedy solver before it is accepted.
"""
import json
import os
import random

DIRS = {"U": (-1, 0), "D": (1, 0), "L": (0, -1), "R": (0, 1)}

OUT = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "assets", "levels", "levels.json",
)


def ray(head, d, rows, cols):
    dr, dc = DIRS[d]
    out = []
    r, c = head[0] + dr, head[1] + dc
    while 0 <= r < rows and 0 <= c < cols:
        out.append((r, c))
        r += dr
        c += dc
    return out


def neighbors(cell, rows, cols):
    r, c = cell
    out = []
    for dr, dc in DIRS.values():
        nr, nc = r + dr, c + dc
        if 0 <= nr < rows and 0 <= nc < cols:
            out.append((nr, nc))
    return out


def build_arrow(occupied, rows, cols, min_len, max_len, rng, tries=40):
    """Return (path, dir) with head first, or None."""
    for _ in range(tries):
        head = (rng.randrange(rows), rng.randrange(cols))
        if head in occupied:
            continue
        d = rng.choice(list(DIRS))
        rc = ray(head, d, rows, cols)
        if any(cell in occupied for cell in rc):
            continue
        forbidden = set(rc)
        forbidden.add(head)

        path = [head]
        last = None
        target = rng.randint(min_len, max_len)
        while len(path) < target:
            cur = path[-1]
            cands = [
                n for n in neighbors(cur, rows, cols)
                if n not in occupied and n not in forbidden and n not in path
            ]
            if not cands:
                break
            # Bias towards carrying straight on, so arrows read as clean lines
            # with the occasional corner rather than scribbles.
            straight = []
            if last is not None:
                back = (2 * cur[0] - last[0], 2 * cur[1] - last[1])
                straight = [n for n in cands if n == back]
            if straight and rng.random() < 0.62:
                nxt = straight[0]
            else:
                nxt = rng.choice(cands)
            last = cur
            path.append(nxt)

        if len(path) < min_len:
            continue
        return path, d
    return None


def simulate(arrows, solution, rows, cols):
    """Replay the recorded solution. True iff the board ends empty."""
    occupied = {}
    for a in arrows:
        for cell in a["cells"]:
            occupied[tuple(cell)] = True

    for (r, c) in solution:
        found = None
        for a in arrows:
            if tuple(a["cells"][0]) == (r, c):
                found = a
                break
        if found is None:
            return False
        head = tuple(found["cells"][0])
        if any(tuple(cell) not in occupied for cell in found["cells"]):
            return False
        if any(cell in occupied for cell in ray(head, found["d"], rows, cols)):
            return False
        for cell in found["cells"]:
            occupied.pop(tuple(cell), None)
    return not occupied


def greedy_solvable(arrows, rows, cols):
    remaining = list(arrows)
    changed = True
    while changed:
        changed = False
        occupied = set()
        for a in remaining:
            for cell in a["cells"]:
                occupied.add(tuple(cell))
        keep = []
        for a in remaining:
            head = tuple(a["cells"][0])
            if any(cell in occupied for cell in ray(head, a["d"], rows, cols)):
                keep.append(a)
            else:
                changed = True
        remaining = keep
    return not remaining


def validate(arrows, rows, cols):
    seen = set()
    for a in arrows:
        if a["d"] not in DIRS:
            return False
        cells = [tuple(c) for c in a["cells"]]
        if len(cells) < 1:
            return False
        for i, cell in enumerate(cells):
            if not (0 <= cell[0] < rows and 0 <= cell[1] < cols):
                return False
            if cell in seen:
                return False
            seen.add(cell)
            if i:
                prev = cells[i - 1]
                if abs(prev[0] - cell[0]) + abs(prev[1] - cell[1]) != 1:
                    return False
        # the body must not sit in its own exit ray
        if set(ray(cells[0], a["d"], rows, cols)) & set(cells):
            return False
    return True


def blocked_count(arrows, rows, cols):
    occupied = set()
    for a in arrows:
        for cell in a["cells"]:
            occupied.add(tuple(cell))
    n = 0
    for a in arrows:
        head = tuple(a["cells"][0])
        if any(cell in occupied for cell in ray(head, a["d"], rows, cols)):
            n += 1
    return n


def params(i):
    """Board size, arrow count and path length for level i (progressive)."""
    t = (i - 1) / 99.0  # 0.0 .. 1.0

    size = int(round(7 + t * 9))          # 7 -> 16
    size = max(7, min(16, size))

    # Arrow count rises steadily; the generator stops early if the board
    # saturates, so these are targets rather than guarantees.
    target = int(round(9 + t * 46))       # 9 -> 55

    min_len = 3 if i > 6 else 2
    max_len = int(round(4 + t * 5))       # 4 -> 9

    return size, size, target, min_len, max_len


def difficulty(i):
    if i <= 35:
        return "Easy"
    if i <= 70:
        return "Medium"
    return "Hard"


def main():
    rng = random.Random(20261018)
    levels = []

    for i in range(1, 101):
        rows, cols, target, min_len, max_len = params(i)

        arrows = []
        occupied = set()
        solution = []

        for _ in range(target):
            got = build_arrow(occupied, rows, cols, min_len, max_len, rng)
            if got is None:
                continue
            path, d = got
            arrows.append({"d": d, "cells": [list(c) for c in path]})
            occupied.update(path)
            solution.append(list(path[0]))

        # The forward clearing order is the reverse of the placement order.
        solution.reverse()
        arrows.reverse()

        if len(arrows) < 4:
            raise SystemExit(f"level {i} built only {len(arrows)} arrows")

        assert validate(arrows, rows, cols), f"level {i} is malformed"
        assert simulate(arrows, solution, rows, cols), f"level {i} failed replay"
        assert greedy_solvable(arrows, rows, cols), f"level {i} is unsolvable"

        avg_len = sum(len(a["cells"]) for a in arrows) / len(arrows)
        levels.append({
            "id": i,
            "rows": rows,
            "cols": cols,
            "difficulty": difficulty(i),
            "par": len(arrows),
            "solution": solution,
            "arrows": arrows,
        })
        print(
            f"L{i:>3} {rows:>2}x{cols:<2} {difficulty(i):<6} "
            f"arrows={len(arrows):>3} blocked={blocked_count(arrows, rows, cols):>3} "
            f"avgLen={avg_len:>4.1f} cells={sum(len(a['cells']) for a in arrows):>4}"
        )

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w") as fh:
        json.dump({"levels": levels}, fh, separators=(",", ":"))
    print(f"\nwrote {len(levels)} levels -> {OUT}")


if __name__ == "__main__":
    main()
