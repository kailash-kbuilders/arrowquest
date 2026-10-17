import '../models/emitter.dart';
import '../models/level.dart';

/// Immutable snapshot used by undo.
class _Snapshot {
  _Snapshot({
    required this.board,
    required this.rail,
    required this.buffer,
    required this.switchTokens,
    required this.direction,
    required this.won,
    required this.lost,
    required this.moves,
  });

  final List<List<String?>> board;
  final List<Emitter> rail;
  final List<Emitter?> buffer;
  final int switchTokens;
  final int direction;
  final bool won;
  final bool lost;
  final int moves;
}

/// Pure-Dart rules engine for Hue Rush. No Flutter imports, so the whole game
/// can be reasoned about (and unit tested) without a UI.
///
/// Rules
/// -----
/// * The **front** emitter of the rail is the only actionable one.
/// * **Fire** clears one tile of the emitter's colour and spends one ammo.
///   When ammo hits 0 the emitter leaves the rail.
/// * **Park** moves the front emitter into the buffer (it is wasted). Parking
///   is always available, and is the only move when the front emitter cannot
///   fire because its colour is no longer on the board.
/// * **Switch** reverses the rail, changing which emitter is at the front, and
///   costs a switch token.
/// * The buffer starts with 5 slots. Filling it ends the level.
/// * **Win** when the board is fully cleared. **Lose** when the buffer is full
///   with no reachable fireable emitter, or when the rail empties with tiles
///   still on the board.
class GameEngine {
  GameEngine(this.level) {
    board = level.tiles.map((row) => List<String?>.from(row)).toList();
    rail = level.emitters.map((e) => e.copy()).toList();
    buffer = List<Emitter?>.filled(level.bufferSize, null);
    switchTokens = level.switchTokens;
  }

  final Level level;

  late List<List<String?>> board;
  late List<Emitter> rail;
  late List<Emitter?> buffer;
  late int switchTokens;

  /// +1 means the rail flows forward, -1 means it has been switched.
  int direction = 1;

  bool won = false;
  bool lost = false;
  int moves = 0;

  final List<_Snapshot> _history = <_Snapshot>[];
  static const int _maxHistory = 80;

  // ---- Queries -----------------------------------------------------------

  bool get isOver => won || lost;
  Emitter? get front => rail.isEmpty ? null : rail.first;
  bool get bufferFull => !buffer.contains(null);
  int get bufferUsed => buffer.where((e) => e != null).length;

  int get tilesLeft => board.fold<int>(
        0,
        (sum, row) => sum + row.where((c) => c != null).length,
      );

  bool colorOnBoard(String color) {
    for (final row in board) {
      for (final cell in row) {
        if (cell == color) return true;
      }
    }
    return false;
  }

  bool get canFire {
    final f = front;
    return f != null && colorOnBoard(f.color);
  }

  /// Position of the first tile (row-major) of [color], or null.
  List<int>? firstTile(String color) {
    for (var r = 0; r < board.length; r++) {
      for (var c = 0; c < board[r].length; c++) {
        if (board[r][c] == color) return <int>[r, c];
      }
    }
    return null;
  }

  // ---- Actions -----------------------------------------------------------

  void _pushHistory() {
    _history.add(_Snapshot(
      board: board.map((row) => List<String?>.from(row)).toList(),
      rail: rail.map((e) => e.copy()).toList(),
      buffer: buffer.map((e) => e == null ? null : e.copy()).toList(),
      switchTokens: switchTokens,
      direction: direction,
      won: won,
      lost: lost,
      moves: moves,
    ));
    if (_history.length > _maxHistory) _history.removeAt(0);
  }

  /// Clears one tile of the front emitter's colour.
  bool fire() {
    if (isOver) return false;
    final f = front;
    if (f == null || !colorOnBoard(f.color)) return false;

    _pushHistory();
    final pos = firstTile(f.color)!;
    board[pos[0]][pos[1]] = null;
    f.ammo -= 1;
    moves++;
    if (f.ammo <= 0) {
      rail.removeAt(0);
    }
    _evaluate();
    return true;
  }

  /// Parks the front emitter into the buffer.
  bool park() {
    if (isOver) return false;
    final f = front;
    if (f == null) return false;
    if (bufferFull) {
      lost = true;
      return true;
    }
    _pushHistory();
    buffer[buffer.indexOf(null)] = f;
    rail.removeAt(0);
    moves++;
    _evaluate();
    return true;
  }

  /// Reverses the rail order.
  bool switchDirection() {
    if (isOver) return false;
    if (switchTokens <= 0 || rail.length < 2) return false;

    _pushHistory();
    switchTokens--;
    direction = -direction;
    final reversed = rail.reversed.toList();
    rail
      ..clear()
      ..addAll(reversed);
    moves++;
    _evaluate();
    return true;
  }

  bool undo() {
    if (_history.isEmpty) return false;
    final s = _history.removeLast();
    board = s.board.map((row) => List<String?>.from(row)).toList();
    rail = s.rail.map((e) => e.copy()).toList();
    buffer = s.buffer.map((e) => e == null ? null : e.copy()).toList();
    switchTokens = s.switchTokens;
    direction = s.direction;
    won = s.won;
    lost = s.lost;
    moves = s.moves;
    return true;
  }

  // ---- Booster grants (wired to rewarded ads / IAP) ----------------------

  void grantSwitchToken() {
    if (isOver) return;
    _pushHistory();
    switchTokens++;
  }

  void grantBufferSlot() {
    if (isOver) return;
    _pushHistory();
    buffer.add(null);
  }

  /// Revive after a loss: open one extra buffer slot and carry on.
  void revive() {
    if (!lost) return;
    _pushHistory();
    buffer.add(null);
    lost = false;
    _evaluate();
  }

  /// Returns a tile to highlight as the next good move, or null.
  List<int>? hintTile() {
    final f = front;
    if (f == null) return null;
    if (colorOnBoard(f.color)) return firstTile(f.color);
    return null;
  }

  // ---- Win / lose --------------------------------------------------------

  void _evaluate() {
    if (tilesLeft == 0) {
      won = true;
      lost = false;
      return;
    }
    if (rail.isEmpty) {
      lost = true;
      return;
    }
    final f = front;
    if (bufferFull && f != null && !colorOnBoard(f.color) && switchTokens <= 0) {
      lost = true;
    }
  }
}
