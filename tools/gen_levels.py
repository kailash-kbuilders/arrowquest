#!/usr/bin/env python3
"""Generate the Quiver level pack.

Mechanic
--------
A grid of arrows. Tap an arrow and it slides in its own direction until it
reaches the edge — then it flies off the board — or until it is blocked by
another arrow, in which case it stops there. Clear every arrow.

How levels are built (and why they can never be unsolvable)
----------------------------------------------------------
Levels are constructed *backwards from the solved state*. Start from an empty
board and repeatedly undo a move:

  * un-exit   — put a new arrow on a cell whose ray to the edge is empty.
                Forward, that arrow slides straight off the board.
  * un-slide  — take an arrow that is currently blocked and push it back along
                its own line. Forward, it slides back and stops where it was.

Placement is biased towards cells that block an existing arrow, which is what
makes a level hard. Every undo step appends its forward move to the solution,
and that solution is replayed through an independent forward simulator before a
level is accepted. Nothing ships unless the replay clears the board.
"""
import json
import os
import random
from collections import deque

DIRS = {"U": (-1, 0), "D": (1, 0), "L": (0, -1), "R": (0, 1)}

CHAPTERS = ["First Flight", "Sidewinder", "Crossfire", "Knotwork", "Overdrive"]
OUT = "/scratch/work/quiver/assets/levels/levels.json"


class Board:
    def __init__(self, rows, cols):
        self.rows = rows
        self.cols = cols
        self.g = [[None] * cols for _ in range(rows)]

    def inside(self, r, c):
        return 0 <= r < self.rows and 0 <= c < self.cols

    def arrows(self):
        return [(r, c, self.g[r][c])
                for r in range(self.rows) for c in range(self.cols)
                if self.g[r][c] is not None]

    def copy(self):
        b = Board(self.rows, self.cols)
        b.g = [row[:] for row in self.g]
        return b


def ray_length(board, r, c, d):
    """Empty cells between (r, c) and the edge along d, or None if blocked."""
    dr, dc = DIRS[d]
    n = 0
    nr, nc = r + dr, c + dc
    while board.inside(nr, nc):
        if board.g[nr][nc] is not None:
            return None
        n += 1
        nr, nc = nr + dr, nc + dc
    return n


def blocks_existing(board, r, c):
    """Would an arrow at (r, c) sit in some other arrow's forward cell?"""
    for d, (dr, dc) in DIRS.items():
        pr, pc = r - dr, c - dc
        if board.inside(pr, pc) and board.g[pr][pc] == d:
            return True
    return False


def un_exit(board, rng, p_block=0.0):
    plain, blocking = [], []
    for r in range(board.rows):
        for c in range(board.cols):
            if board.g[r][c] is not None:
                continue
            for d in DIRS:
                n = ray_length(board, r, c, d)
                if n is None:
                    continue
                entry = (n, r, c, d)
                (blocking if blocks_existing(board, r, c) else plain).append(entry)

    pool = plain
    if blocking and rng.random() < p_block:
        pool = blocking
    if not pool:
        pool = plain or blocking
    if not pool:
        return None

    pool.sort(key=lambda t: -t[0])
    top = pool[: max(1, len(pool) // 3)]
    n, r, c, d = rng.choice(top)
    board.g[r][c] = d
    return (r, c)


def un_slide(board, rng):
    cands = []
    for (r, c, d) in board.arrows():
        dr, dc = DIRS[d]
        nr, nc = r + dr, c + dc
        if not board.inside(nr, nc) or board.g[nr][nc] is None:
            continue                       # must currently be blocked
        k = 1
        while True:
            ar, ac = r - k * dr, c - k * dc
            if not board.inside(ar, ac) or board.g[ar][ac] is not None:
                break
            cands.append((r, c, d, ar, ac, k))
            k += 1
    if not cands:
        return None
    r, c, d, ar, ac, k = rng.choice(cands)
    board.g[r][c] = None
    board.g[ar][ac] = d
    return (ar, ac)


def simulate(board, moves):
    """Replay the recorded solution. True iff the board ends empty."""
    b = board.copy()
    for (r, c) in moves:
        d = b.g[r][c]
        if d is None:
            return False
        dr, dc = DIRS[d]
        cr, cc = r, c
        while True:
            nr, nc = cr + dr, cc + dc
            if not b.inside(nr, nc):
                b.g[r][c] = None                 # slides off the board
                break
            if b.g[nr][nc] is not None:
                if (cr, cc) != (r, c):           # stops short
                    b.g[r][c] = None
                    b.g[cr][cc] = d
                break
            cr, cc = nr, nc
    return all(b.g[r][c] is None for r in range(b.rows) for c in range(b.cols))


def movable(board, r, c):
    dr, dc = DIRS[board.g[r][c]]
    nr, nc = r + dr, c + dc
    return (not board.inside(nr, nc)) or board.g[nr][nc] is None


def count_blocked(board):
    return sum(0 if movable(board, r, c) else 1 for (r, c, _) in board.arrows())


def metric(board, moves):
    return round(board.rows * board.cols * 0.9
                 + len(board.arrows()) * 4
                 + count_blocked(board) * 7
                 + len(moves) * 0.5)


def build(rows, cols, target_arrows, slide_steps, p_block, rng):
    board = Board(rows, cols)
    moves = deque()
    for _ in range(target_arrows):
        res = un_exit(board, rng, p_block)
        if res is None:
            break
        moves.appendleft(res)
    attempts = 0
    placed = 0
    while placed < slide_steps and attempts < slide_steps * 6:
        attempts += 1
        res = un_slide(board, rng)
        if res is None:
            continue
        moves.appendleft(res)
        placed += 1
    if len(board.arrows()) < 3:
        return None
    if not simulate(board, list(moves)):
        return None
    return board, list(moves)


def targets(i):
    ch = (i - 1) // 20
    frac = ((i - 1) % 20) / 19.0
    size = 4 + ch
    arrows = [4, 7, 10, 14, 18][ch] + round(frac * [4, 5, 6, 7, 8][ch])
    slides = round(frac * arrows * [0.6, 1.0, 1.3, 1.6, 1.9][ch])
    p_block = 0.0 if i <= 6 else min(0.85, 0.25 + 0.6 * (i / 100.0))
    return size, arrows, slides, p_block


def main():
    rng = random.Random(20261017)
    levels = []
    for i in range(1, 101):
        size, arrows, slides, p_block = targets(i)
        chosen = None
        for _ in range(80):
            got = build(size, size, arrows, slides, p_block, rng)
            if got is None:
                continue
            board, moves = got
            blocked = count_blocked(board)
            if i > 6 and blocked < 2:
                continue
            chosen = (board, moves)
            break
        if chosen is None:
            size, arrows, slides, p_block = targets(i)
            chosen = build(size, size, max(3, arrows - 3), max(0, slides - 3), p_block, rng)
        board, moves = chosen
        assert simulate(board, moves), f"level {i} failed verification"
        levels.append({
            "id": i,
            "chapter": CHAPTERS[(i - 1) // 20],
            "rows": board.rows,
            "cols": board.cols,
            "par": len(moves),
            "arrows": [{"r": r, "c": c, "d": d} for (r, c, d) in board.arrows()],
        })
        print(f"L{i:>3} {board.rows}x{board.cols} arrows={len(board.arrows()):>2} "
              f"blocked={count_blocked(board):>2} sol={len(moves):>2} "
              f"score={metric(board, moves):>3}")

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w") as fh:
        json.dump({"levels": levels}, fh, indent=1)
    print(f"\nwrote {len(levels)} levels -> {OUT}")


if __name__ == "__main__":
    main()
