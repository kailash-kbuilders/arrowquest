import '../models/arrow.dart';
import '../models/level.dart';

class _Snapshot {
  _Snapshot({required this.arrows, required this.moves, required this.won});

  final List<Arrow> arrows;
  final int moves;
  final bool won;
}

/// Pure-Dart rules engine for Quiver. No Flutter imports, so the whole game can
/// be reasoned about — and unit tested — without a UI.
///
/// Rules
/// -----
/// * Tap an arrow and it slides in its own direction.
/// * It stops when the next cell holds another arrow, or slides clean off the
///   board when it reaches the edge.
/// * A tap does nothing if the very next cell is occupied — the arrow is jammed.
/// * Clear every arrow to win.
class QuiverEngine {
  QuiverEngine(this.level) {
    _load();
  }

  final Level level;

  late List<Arrow> _arrows;
  int moves = 0;
  bool won = false;

  final List<_Snapshot> _history = <_Snapshot>[];
  static const int _maxHistory = 150;

  void _load() {
    var id = 0;
    _arrows = level.arrows
        .map((s) => Arrow(id: id++, row: s.row, col: s.col, dir: s.dir))
        .toList();
  }

  // ---- Queries -----------------------------------------------------------

  int get rows => level.rows;
  int get cols => level.cols;
  int get arrowsLeft => _arrows.length;
  bool get isOver => won;
  bool get canUndo => _history.isNotEmpty;

  /// A snapshot copy, safe for the UI to read.
  List<Arrow> get arrows => List<Arrow>.unmodifiable(_arrows);

  bool inside(int r, int c) => r >= 0 && r < rows && c >= 0 && c < cols;

  Arrow? arrowAt(int r, int c) {
    for (final a in _arrows) {
      if (a.row == r && a.col == c) return a;
    }
    return null;
  }

  /// Whether tapping this arrow would do anything at all.
  bool canMove(int r, int c) {
    final a = arrowAt(r, c);
    if (a == null || won) return false;
    final nr = a.row + a.dir.dr;
    final nc = a.col + a.dir.dc;
    if (!inside(nr, nc)) return true; // already at the edge, it flies off
    return arrowAt(nr, nc) == null; // room for at least one step
  }

  /// Position of some arrow that can currently move, or null.
  List<int>? hint() {
    for (final a in _arrows) {
      if (canMove(a.row, a.col)) return <int>[a.row, a.col];
    }
    return null;
  }

  // ---- Actions -----------------------------------------------------------

  bool tap(int r, int c) {
    if (won) return false;
    final a = arrowAt(r, c);
    if (a == null || !canMove(r, c)) return false;

    _pushHistory();
    final dr = a.dir.dr;
    final dc = a.dir.dc;
    var cr = a.row;
    var cc = a.col;

    while (true) {
      final nr = cr + dr;
      final nc = cc + dc;
      if (!inside(nr, nc)) {
        _arrows.remove(a); // slides off the board
        break;
      }
      if (arrowAt(nr, nc) != null) {
        a.row = cr; // stops short, blocked
        a.col = cc;
        break;
      }
      cr = nr;
      cc = nc;
    }

    moves++;
    _evaluate();
    return true;
  }

  bool undo() {
    if (_history.isEmpty) return false;
    final s = _history.removeLast();
    _arrows = s.arrows.map((a) => a.copy()).toList();
    moves = s.moves;
    won = s.won;
    return true;
  }

  void restart() {
    _history.clear();
    _load();
    moves = 0;
    won = false;
  }

  void _pushHistory() {
    _history.add(_Snapshot(
      arrows: _arrows.map((a) => a.copy()).toList(),
      moves: moves,
      won: won,
    ));
    if (_history.length > _maxHistory) _history.removeAt(0);
  }

  void _evaluate() {
    won = _arrows.isEmpty;
  }
}
