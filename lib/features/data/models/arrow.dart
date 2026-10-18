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
/// [cells] is an ordered path — index 0 is the head, the cell the arrow points
/// from. Because the path is a straight line, the tail is simply the last cell.
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

  /// Every cell this arrow occupies.
  Iterable<Cell> get body => cells;

  int get length => cells.length;

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
/// The head is at ([row], [col]); the body extends `length` cells in the
/// direction *opposite* to [dir], so [dir] always points outward from the head.
class ArrowSpec {
  const ArrowSpec({
    required this.row,
    required this.col,
    required this.dir,
    required this.length,
  });

  final int row;
  final int col;
  final Dir dir;
  final int length;

  /// Expands this spec into its ordered list of cells (head first).
  List<Cell> resolveCells() {
    final int dr = dir.dr;
    final int dc = dir.dc;
    return List<Cell>.generate(
      length,
      (int i) => Cell(row - i * dr, col - i * dc),
      growable: false,
    );
  }

  /// Parses a spec, throwing [FormatException] on malformed input.
  factory ArrowSpec.fromJson(Map<String, dynamic> json) {
    final Object? r = json['r'];
    final Object? c = json['c'];
    final Object? d = json['d'];
    final Object? len = json['len'];
    if (r is! num || c is! num || d is! String) {
      throw const FormatException('arrow needs numeric r/c and a string d');
    }
    final int length = len is num ? len.toInt() : 1;
    if (length < 1) {
      throw const FormatException('arrow length must be >= 1');
    }
    return ArrowSpec(
      row: r.toInt(),
      col: c.toInt(),
      dir: DirX.fromKey(d),
      length: length,
    );
  }
}
