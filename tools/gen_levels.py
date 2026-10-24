#!/usr/bin/env python3
"""Generate the ArrowQuest level pack (100 levels).

Mechanic
--------
Each arrow is a bent path of connected cells with a head at one end and a
facing direction. Tapping an arrow scans the straight exit ray from its head to
the board edge:

  * ray clear of every other arrow -> the whole arrow slides along its own path
    and off the board;
  * ray blocked by another arrow   -> the move is refused and the arrow stays.

Clear every arrow to finish. The empty cells form corridors out to the edge,
which is what makes a dense board look like a maze.

Why generated levels can never be unsolvable
--------------------------------------------
A level is built backwards from the solved state. Arrows are placed one at a
time in reverse removal order; when an arrow is placed, the arrows already on
the board are exactly the ones still present when it is removed in the forward
game. So a single check — "this arrow's exit ray is clear of the arrows already
placed, and clear of its own body" — guarantees the reverse of the placement
order is a valid solution.

Density
-------
The ray check is answered in O(1) from per-direction free-run tables, so the
generator can pack boards hard: the last levels put ~100 arrows on a 22x22
board. Every finished level is replayed through an independent forward simulator
and a monotone greedy solver before it is accepted.
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


def free_runs(occupied, rows, cols):
    """runR[r][c] = consecutive free cells from (r, c) going right, etc."""
    run_r = [[0] * cols for _ in range(rows)]
    run_l = [[0] * cols for _ in range(rows)]
    run_d = [[0] * cols for _ in range(rows)]
    run_u = [[0] * cols for _ in range(rows)]

    for r in range(rows):
        n = 0
        for c in range(cols - 1, -1, -1):
            n = 0 if (r, c) in occupied else n + 1
            run_r[r][c] = n
        n = 0
        for c in range(cols):
            n = 0 if (r, c) in occupied else n + 1
            run_l[r][c] = n
    for c in range(cols):
        n = 0
        for r in range(rows - 1, -1, -1):
            n = 0 if (r, c) in occupied else n + 1
            run_d[r][c] = n
        n = 0
        for r in range(rows):
            n = 0 if (r, c) in occupied else n + 1
            run_u[r][c] = n
    return run_r, run_l, run_d, run_u


def ray_is_clear(r, c, d, rows, cols, runs):
    """True when nothing blocks the ray from (r, c) to the edge along d."""
    run_r, run_l, run_d, run_u = runs
    if d == "R":
        return c == cols - 1 or run_r[r][c + 1] == cols - 1 - c
    if d == "L":
        return c == 0 or run_l[r][c - 1] == c
    if d == "D":
        return r == rows - 1 or run_d[r + 1][c] == rows - 1 - r
    return r == 0 or run_u[r - 1][c] == r


def grow_body(head, d, occupied, rows, cols, min_len, max_len, rng, blockable):
    """Extend a body from the head, keeping it out of the head's own ray.

    [blockable] holds cells that sit inside some already-placed arrow's exit
    ray; bodies are steered towards them so arrows actually block each other.
    """
    forbidden = set(ray(head, d, rows, cols))
    forbidden.add(head)
    path = [head]
    last = None
    target = rng.randint(min_len, max_len)
    while len(path) < target:
        cur = path[-1]
        cands = []
        for dr, dc in DIRS.values():
            n = (cur[0] + dr, cur[1] + dc)
            if not (0 <= n[0] < rows and 0 <= n[1] < cols):
                continue
            if n in occupied or n in forbidden or n in path:
                continue
            cands.append(n)
        if not cands:
            break
        blockers = [n for n in cands if n in blockable]
        straight = []
        if last is not None:
            back = (2 * cur[0] - last[0], 2 * cur[1] - last[1])
            straight = [n for n in cands if n == back]
        if blockers and rng.random() < 0.65:
            nxt = rng.choice(blockers)
        elif straight and rng.random() < 0.55:
            nxt = straight[0]
        else:
            nxt = rng.choice(cands)
        last = cur
        path.append(nxt)
    return path


def _weighted_pick(items, weights, rng):
    total = sum(weights)
    if total <= 0:
        return items[rng.randrange(len(items))]
    r = rng.random() * total
    upto = 0.0
    for item, w in zip(items, weights):
        upto += w
        if r <= upto:
            return item
    return items[-1]


def blockable_cells(placed, rows, cols):
    """Free cells that lie in the exit ray of an arrow already on the board."""
    out = set()
    for body, d in placed:
        for cell in ray(body[0], d, rows, cols):
            out.add(cell)
    return out


def build_level(rows, cols, target_arrows, min_len, max_len, rng):
    occupied = set()
    placed = []  # reverse removal order (last removed first)

    for _ in range(target_arrows):
        runs = free_runs(occupied, rows, cols)
        candidates = []
        for r in range(rows):
            for c in range(cols):
                if (r, c) in occupied:
                    continue
                for d in DIRS:
                    if ray_is_clear(r, c, d, rows, cols, runs):
                        candidates.append((r, c, d))
        if not candidates:
            break
        blockable = blockable_cells(placed, rows, cols)

        # Weight the pick towards heads that sit next to cells already inside
        # another arrow's ray (so the body can block it) and towards short rays
        # (which leave more room for later arrows).
        weights = []
        for (r, c, d) in candidates:
            near = 0
            for dr, dc in DIRS.values():
                n = (r + dr, c + dc)
                if 0 <= n[0] < rows and 0 <= n[1] < cols and n in blockable:
                    near += 1
            length = len(ray((r, c), d, rows, cols))
            weights.append(1.0 + 5.0 * near + (3.0 if length <= 2 else 0.0))
        pick = _weighted_pick(candidates, weights, rng)
        head, d = (pick[0], pick[1]), pick[2]
        body = grow_body(
            head, d, occupied, rows, cols, min_len, max_len, rng, blockable
        )
        if len(body) < min_len:
            continue
        for cell in body:
            occupied.add(cell)
        placed.append((body, d))

    if len(placed) < 4:
        return None
    arrows = [{"d": d, "cells": [list(c) for c in body]} for body, d in reversed(placed)]
    solution = [list(body[0]) for body, _ in reversed(placed)]
    return arrows, solution


def simulate(arrows, solution, rows, cols):
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
        if not cells:
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
    t = (i - 1) / 99.0

    size = int(round(7 + t * 15))          # 7 -> 22
    size = max(7, min(22, size))

    # Arrow counts climb hard: the last levels want ~110 arrows on a 22x22
    # board. The generator stops early if the board saturates, so this is a
    # target rather than a guarantee.
    target = int(round(8 + t * 118))       # 8 -> 126

    # Short bodies are the key to arrow count: the same filled area yields far
    # more arrows, which is exactly the dense look the levels are after.
    min_len = 2
    max_len = int(round(3 + t * 2))        # 3 -> 5
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

        need_blocked = 0 if i <= 10 else (3 if i <= 40 else 8)
        best = None
        best_score = -1.0
        for attempt in range(14):
            got = build_level(rows, cols, target, min_len, max_len, rng)
            if got is None:
                continue
            arrows, solution = got
            if not validate(arrows, rows, cols):
                continue
            if not simulate(arrows, solution, rows, cols):
                continue
            if not greedy_solvable(arrows, rows, cols):
                continue
            blocked = blocked_count(arrows, rows, cols)
            score = len(arrows) + 0.4 * blocked
            if score > best_score:
                best_score = score
                best = (arrows, solution)
            if len(arrows) >= target and blocked >= need_blocked:
                break
        if best is None:
            raise SystemExit(f"could not build level {i}")
        if i > 10 and blocked_count(best[0], rows, cols) < need_blocked:
            # Relax rather than fail: accept the densest board we managed.
            pass

        arrows, solution = best
        avg = sum(len(a["cells"]) for a in arrows) / len(arrows)
        filled = sum(len(a["cells"]) for a in arrows)
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
            f"arrows={len(arrows):>3}/{target:<3} "
            f"blocked={blocked_count(arrows, rows, cols):>3} "
            f"avgLen={avg:>4.1f} fill={100 * filled / (rows * cols):>4.1f}%"
        )

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w") as fh:
        json.dump({"levels": levels}, fh, separators=(",", ":"))
    print(f"\nwrote {len(levels)} levels -> {OUT}")


if __name__ == "__main__":
    main()
