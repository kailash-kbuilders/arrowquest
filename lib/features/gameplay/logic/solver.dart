import '../../data/models/arrow.dart';
import '../../data/models/level.dart';

/// A small, independent solvability checker.
///
/// This exists so a level's solvability can be verified *without* trusting the
/// generator that produced it. Removing an arrow only ever frees cells, so the
/// property "an arrow's ray is clear" is monotone: a greedy sweep that removes
/// every currently-clear arrow is complete. If the greedy sweep empties the
/// board, a solution exists; if it stalls, none does.
class LevelSolver {
  LevelSolver._();

  /// Whether every arrow can be cleared.
  static bool isSolvable(Level level) => solve(level) != null;

  /// A full clearing order (arrow heads), or null if the level cannot be solved.
  static List<Cell>? solve(Level level) {
    final List<_Placed> remaining = <_Placed>[];
    final Set<Cell> seen = <Cell>{};
    var id = 0;
    for (final ArrowSpec spec in level.arrows) {
      final List<Cell> cells = spec.resolveCells();
      for (final Cell cell in cells) {
        if (!_inside(cell, level)) return null;
        if (!seen.add(cell)) return null; // overlapping arrows
      }
      remaining.add(_Placed(id++, cells, spec.dir));
    }

    final List<Cell> order = <Cell>[];
    var progressed = true;
    while (progressed && remaining.isNotEmpty) {
      progressed = false;
      for (final _Placed candidate in List<_Placed>.of(remaining)) {
        if (!_blocked(candidate, remaining, level)) {
          order.add(candidate.cells.first);
          remaining.remove(candidate);
          progressed = true;
        }
      }
    }
    return remaining.isEmpty ? order : null;
  }

  static bool _inside(Cell cell, Level level) =>
      cell.r >= 0 && cell.r < level.rows && cell.c >= 0 && cell.c < level.cols;

  static bool _blocked(_Placed arrow, List<_Placed> remaining, Level level) {
    var r = arrow.cells.first.r + arrow.dir.dr;
    var c = arrow.cells.first.c + arrow.dir.dc;
    while (r >= 0 && r < level.rows && c >= 0 && c < level.cols) {
      final Cell probe = Cell(r, c);
      for (final _Placed other in remaining) {
        if (identical(other, arrow)) continue;
        if (other.cells.contains(probe)) return true;
      }
      r += arrow.dir.dr;
      c += arrow.dir.dc;
    }
    return false;
  }
}

class _Placed {
  const _Placed(this.id, this.cells, this.dir);

  final int id;
  final List<Cell> cells;
  final Dir dir;
}
