/// The four directions an arrow can face. Pure Dart — no Flutter imports — so
/// the whole rules engine can be reasoned about and unit tested without a UI.
enum Dir { up, down, left, right }

extension DirX on Dir {
  /// Row delta for this direction.
  int get dr => switch (this) {
        Dir.up => -1,
        Dir.down => 1,
        _ => 0,
      };

  /// Column delta for this direction.
  int get dc => switch (this) {
        Dir.left => -1,
        Dir.right => 1,
        _ => 0,
      };

  /// Single-letter key used in the level pack.
  String get key => switch (this) {
        Dir.up => 'U',
        Dir.down => 'D',
        Dir.left => 'L',
        Dir.right => 'R',
      };

  /// Parses a level-pack key, defaulting to [Dir.up] for unknown input.
  static Dir fromKey(String key) {
    switch (key.toUpperCase()) {
      case 'U':
        return Dir.up;
      case 'D':
        return Dir.down;
      case 'L':
        return Dir.left;
      case 'R':
        return Dir.right;
      default:
        return Dir.up;
    }
  }
}

/// An immutable grid coordinate.
class Cell {
  const Cell(this.r, this.c);

  final int r;
  final int c;

  Cell step(Dir dir) => Cell(r + dir.dr, c + dir.dc);

  @override
  bool operator ==(Object other) =>
      other is Cell && other.r == r && other.c == c;

  @override
  int get hashCode => Object.hash(r, c);

  @override
  String toString() => '($r,$c)';
}

/// Lifecycle of a single arrow, used to keep input, collision state and the
/// rendered state in step.
enum ArrowState { idle, selected, blocked, escaping, removed }

/// A live arrow on the board.
///
/// [cells] is the arrow's path, head first — index 0 is the cell the arrow
/// points from, the last cell is the tail. The path may bend: it is a connected
/// run of grid cells, not necessarily a straight line.
class Arrow {
  Arrow({
    required this.id,
    required this.cells,
    required this.dir,
    this.state = ArrowState.idle,
  });

  final int id;
  final List<Cell> cells;
  final Dir dir;
  ArrowState state;

  /// The leading cell — the one the exit ray starts from.
  Cell get head => cells.first;

  /// The trailing cell.
  Cell get tail => cells.last;

  int get length => cells.length;

  /// The order the arrow travels in when it escapes: tail first, head last.
  List<Cell> get travelPath => cells.reversed.toList(growable: false);

  Arrow copyWith({ArrowState? state}) => Arrow(
        id: id,
        cells: cells,
        dir: dir,
        state: state ?? this.state,
      );

  @override
  String toString() =>
      'Arrow#$id${cells.map((Cell c) => c.toString()).join()} ${dir.key}';
}

/// The immutable placement of an arrow as described by a level file.
///
/// [cells] is the path, head first, and [dir] is the direction the head points.
class ArrowSpec {
  const ArrowSpec({required this.cells, required this.dir});

  final List<Cell> cells;
  final Dir dir;

  /// The arrow's path, head first.
  List<Cell> resolveCells() => cells;

  /// Parses a spec, throwing [FormatException] on malformed input.
  factory ArrowSpec.fromJson(Map<String, dynamic> json) {
    final Object? rawCells = json['cells'];
    final Object? d = json['d'];
    if (rawCells is! List || rawCells.isEmpty || d is! String) {
      throw const FormatException('arrow needs a non-empty cells list and a d');
    }
    final List<Cell> cells = <Cell>[];
    for (final Object? entry in rawCells) {
      if (entry is! List || entry.length < 2) {
        throw const FormatException('arrow cell must be [r, c]');
      }
      final Object? r = entry[0];
      final Object? c = entry[1];
      if (r is! num || c is! num) {
        throw const FormatException('arrow cell coordinates must be numeric');
      }
      cells.add(Cell(r.toInt(), c.toInt()));
    }
    return ArrowSpec(cells: cells, dir: DirX.fromKey(d));
  }
}
