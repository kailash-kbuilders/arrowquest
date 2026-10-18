import 'arrow.dart';

/// How hard a level is, derived from its position in the run.
enum Difficulty { easy, medium, hard }

extension DifficultyX on Difficulty {
  String get label => switch (this) {
        Difficulty.easy => 'Easy',
        Difficulty.medium => 'Medium',
        Difficulty.hard => 'Hard',
      };

  static Difficulty fromLabel(String label) {
    switch (label.toLowerCase()) {
      case 'medium':
        return Difficulty.medium;
      case 'hard':
        return Difficulty.hard;
      default:
        return Difficulty.easy;
    }
  }

  /// Used for the level-number grid and the level header.
  static Difficulty forLevel(int id) {
    if (id <= 35) return Difficulty.easy;
    if (id <= 70) return Difficulty.medium;
    return Difficulty.hard;
  }
}

/// One puzzle level. Immutable — the mutable play state lives in the engine.
class Level {
  const Level({
    required this.id,
    required this.rows,
    required this.cols,
    required this.difficulty,
    required this.par,
    required this.arrows,
    required this.solution,
  });

  final int id;
  final int rows;
  final int cols;
  final Difficulty difficulty;

  /// Number of moves in the reference solution (one move per arrow).
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
        if (entry is List && entry.length >= 2) {
          final Object? r = entry[0];
          final Object? c = entry[1];
          if (r is num && c is num) {
            solution.add(Cell(r.toInt(), c.toInt()));
          }
        }
      }
    }

    final Object? rawDifficulty = json['difficulty'];
    return Level(
      id: id.toInt(),
      rows: rows.toInt(),
      cols: cols.toInt(),
      difficulty: rawDifficulty is String
          ? DifficultyX.fromLabel(rawDifficulty)
          : DifficultyX.forLevel(id.toInt()),
      par: json['par'] is num ? (json['par'] as num).toInt() : arrows.length,
      arrows: arrows
          .whereType<Map<String, dynamic>>()
          .map(ArrowSpec.fromJson)
          .toList(growable: false),
      solution: solution,
    );
  }
}
