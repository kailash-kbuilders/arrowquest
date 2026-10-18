import '../../data/models/arrow.dart';
import '../../data/models/level.dart';

/// What happened when a cell was tapped.
enum MoveResult {
  /// The arrow escaped the board.
  escaped,

  /// Another arrow was in the exit ray — the move was refused and a heart lost.
  blocked,

  /// The last heart was just lost — the level has to start over.
  failed,

  /// Nothing to do (empty cell, or the level is already over).
  ignored,
}

/// The outcome of a tap, carrying the arrow involved so the view can animate it.
class MoveOutcome {
  const MoveOutcome(this.result, [this.arrow]);

  final MoveResult result;
  final Arrow? arrow;
}

class _Snapshot {
  _Snapshot({
    required this.arrows,
    required this.occupancy,
    required this.moves,
    required this.mistakes,
    required this.hearts,
    required this.won,
  });

  final List<Arrow> arrows;
  final Map<Cell, int> occupancy;
  final int moves;
  final int mistakes;
  final int hearts;
  final bool won;
}

/// Pure-Dart rules engine. No Flutter imports, so the whole game can be
/// reasoned about — and unit tested — without a UI.
///
/// Rules
/// -----
/// * Each arrow is a bent path of connected cells with a head at one end.
/// * Tap an arrow: the straight exit ray is scanned from its head to the edge.
/// * Ray clear of every other arrow -> the whole arrow slides along its own path
///   and off the board.
/// * Ray blocked -> the move is refused, the arrow does not move, and one of the
///   three hearts is lost. Lose all three and the level restarts.
/// * Clear every arrow to win.
class ArrowQuestEngine {
  ArrowQuestEngine(this.level) {
    _reset();
  }

  /// Hearts a level starts with.
  static const int maxHearts = 3;

  final Level level;

  final List<Arrow> _arrows = <Arrow>[];
  final Map<Cell, int> _occupancy = <Cell, int>{};
  final List<_Snapshot> _history = <_Snapshot>[];

  static const int _maxHistory = 400;

  int moves = 0;
  int mistakes = 0;
  int hearts = maxHearts;
  bool won = false;

  // ---- Queries -----------------------------------------------------------

  int get rows => level.rows;
  int get cols => level.cols;
  int get arrowsLeft => _arrows.length;
  int get totalArrows => level.arrows.length;
  int get cleared => totalArrows - arrowsLeft;
  bool get isOver => won;
  bool get canUndo => _history.isNotEmpty;
  bool get outOfHearts => hearts <= 0;

  /// A read-only view of the board.
  List<Arrow> get arrows => List<Arrow>.unmodifiable(_arrows);

  bool inside(int r, int c) => r >= 0 && r < rows && c >= 0 && c < cols;

  Arrow? arrowAt(int r, int c) {
    final int? id = _occupancy[Cell(r, c)];
    if (id == null) return null;
    for (final Arrow a in _arrows) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// The cells strictly ahead of the head, out to the board edge.
  List<Cell> exitRay(Arrow arrow) {
    final List<Cell> out = <Cell>[];
    var r = arrow.head.r + arrow.dir.dr;
    var c = arrow.head.c + arrow.dir.dc;
    while (inside(r, c)) {
      out.add(Cell(r, c));
      r += arrow.dir.dr;
      c += arrow.dir.dc;
    }
    return out;
  }

  /// The first arrow sitting in [arrow]'s exit ray, or null if the ray is clear.
  ///
  /// Uses each arrow's *actual occupied cells*, never a bounding box.
  Arrow? blockerFor(Arrow arrow) {
    for (final Cell cell in exitRay(arrow)) {
      final int? id = _occupancy[cell];
      if (id != null && id != arrow.id) {
        for (final Arrow a in _arrows) {
          if (a.id == id) return a;
        }
      }
    }
    return null;
  }

  /// Whether tapping this arrow right now would clear it.
  bool canEscape(Arrow arrow) => !won && blockerFor(arrow) == null;

  /// A cell whose arrow can legally escape.
  ///
  /// The reference solution is consulted first, and it is always right: a move
  /// only ever *frees* cells, so the first arrow still on the board that appears
  /// in the reference order is guaranteed to have a clear exit ray — whatever
  /// order the player has cleared things in.
  Cell? hint() {
    if (won) return null;

    for (final Cell cell in level.solution) {
      final Arrow? a = arrowAt(cell.r, cell.c);
      if (a != null && blockerFor(a) == null) return a.head;
    }

    // Defensive fallback: any escapable arrow, preferring one that frees more.
    Cell? best;
    var bestScore = -1;
    for (final Arrow a in _arrows) {
      if (blockerFor(a) != null) continue;
      final int score = _unlockScore(a);
      if (score > bestScore) {
        bestScore = score;
        best = a.head;
      }
    }
    return best;
  }

  /// How many currently-blocked arrows this one is the blocker for.
  int _unlockScore(Arrow arrow) {
    var score = 0;
    for (final Arrow other in _arrows) {
      if (other.id == arrow.id) continue;
      final Arrow? blocker = blockerFor(other);
      if (blocker != null && blocker.id == arrow.id) score++;
    }
    return score;
  }

  // ---- Actions -----------------------------------------------------------

  MoveOutcome tap(int r, int c) {
    if (won) return const MoveOutcome(MoveResult.ignored);
    final Arrow? arrow = arrowAt(r, c);
    if (arrow == null) return const MoveOutcome(MoveResult.ignored);

    if (blockerFor(arrow) != null) {
      mistakes++;
      hearts = hearts > 0 ? hearts - 1 : 0;
      final Arrow blocked = arrow.copyWith(state: ArrowState.blocked);
      if (hearts == 0) return MoveOutcome(MoveResult.failed, blocked);
      return MoveOutcome(MoveResult.blocked, blocked);
    }

    _pushHistory();

    // Detach the arrow immediately so the collision state is correct from the
    // very first frame of the escape animation, and a second tap on the same
    // cell cannot start a duplicate animation.
    final Arrow escaping = Arrow(
      id: arrow.id,
      cells: List<Cell>.of(arrow.cells),
      dir: arrow.dir,
      state: ArrowState.escaping,
    );
    for (final Cell cell in arrow.cells) {
      _occupancy.remove(cell);
    }
    _arrows.removeWhere((Arrow a) => a.id == arrow.id);
    moves++;
    won = _arrows.isEmpty;
    return MoveOutcome(MoveResult.escaped, escaping);
  }

  bool undo() {
    if (_history.isEmpty) return false;
    final _Snapshot s = _history.removeLast();
    _arrows
      ..clear()
      ..addAll(s.arrows.map(
        (Arrow a) => Arrow(id: a.id, cells: a.cells, dir: a.dir),
      ));
    _occupancy
      ..clear()
      ..addAll(s.occupancy);
    moves = s.moves;
    mistakes = s.mistakes;
    hearts = s.hearts;
    won = s.won;
    return true;
  }

  /// Puts the level back to its exact starting state, hearts included.
  void restart() => _reset();

  // ---- Internals ---------------------------------------------------------

  void _reset() {
    _arrows.clear();
    _occupancy.clear();
    _history.clear();
    var id = 0;
    for (final ArrowSpec spec in level.arrows) {
      final Arrow arrow = Arrow(
        id: id++,
        cells: spec.resolveCells(),
        dir: spec.dir,
      );
      _arrows.add(arrow);
      for (final Cell cell in arrow.cells) {
        _occupancy[cell] = arrow.id;
      }
    }
    moves = 0;
    mistakes = 0;
    hearts = maxHearts;
    won = false;
  }

  void _pushHistory() {
    _history.add(_Snapshot(
      arrows: _arrows
          .map((Arrow a) => Arrow(id: a.id, cells: a.cells, dir: a.dir))
          .toList(growable: false),
      occupancy: Map<Cell, int>.of(_occupancy),
      moves: moves,
      mistakes: mistakes,
      hearts: hearts,
      won: won,
    ));
    if (_history.length > _maxHistory) _history.removeAt(0);
  }
}
