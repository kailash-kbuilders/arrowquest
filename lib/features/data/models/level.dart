import 'arrow.dart';

/// One puzzle level. Immutable — the mutable play state lives in the engine.
class Level {
  const Level({
    required this.id,
    required this.chapter,
    required this.rows,
    required this.cols,
    required this.par,
    required this.arrows,
    required this.solution,
  });

  final int id;
  final String chapter;
  final int rows;
  final int cols;

  /// Number of moves in the generated reference solution.
  final int par;

  final List<ArrowSpec> arrows;

  /// A known-good clearing order (arrow heads), used for hints and testing.
  final List<Cell> solution;

  /// Parses a level, throwing [FormatException] on malformed input.
  factory Level.fromJson(Map<String, dynamic> json) {
    final Object? id = json['id'];
    final Object? rows = json['rows'];
    final Object? cols = json['cols'];
    final Object? arrows = json['arrows'];
    if (id is! num || rows is! num || cols is! num || arrows is! List) {
      throw const FormatException(
          'level needs numeric id/rows/cols and arrows');
    }
    if (rows.toInt() < 1 || cols.toInt() < 1) {
      throw const FormatException('level board must be at least 1x1');
    }
    final List<Cell> solution = <Cell>[];
    final Object? rawSolution = json['solution'];
    if (rawSolution is List) {
      for (final Object? entry in rawSolution) {
        if (entry is Map) {
          final Object? r = entry['r'];
          final Object? c = entry['c'];
          if (r is num && c is num) {
            solution.add(Cell(r.toInt(), c.toInt()));
          }
        }
      }
    }
    return Level(
      id: id.toInt(),
      chapter: json['chapter'] is String ? json['chapter'] as String : 'Levels',
      rows: rows.toInt(),
      cols: cols.toInt(),
      par: json['par'] is num ? (json['par'] as num).toInt() : arrows.length,
      arrows: arrows
          .whereType<Map<String, dynamic>>()
          .map(ArrowSpec.fromJson)
          .toList(growable: false),
      solution: solution,
    );
  }
}
