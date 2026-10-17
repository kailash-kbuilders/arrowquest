import 'arrow.dart';

/// One puzzle level. Immutable — the mutable play state lives in QuiverEngine.
class Level {
  const Level({
    required this.id,
    required this.chapter,
    required this.rows,
    required this.cols,
    required this.par,
    required this.arrows,
  });

  final int id;
  final String chapter;
  final int rows;
  final int cols;

  /// Solution length found by the generator — a useful yardstick, not a target.
  final int par;

  final List<ArrowSpec> arrows;

  factory Level.fromJson(Map<String, dynamic> json) => Level(
        id: (json['id'] as num).toInt(),
        chapter: (json['chapter'] as String?) ?? 'First Flight',
        rows: (json['rows'] as num).toInt(),
        cols: (json['cols'] as num).toInt(),
        par: (json['par'] as num?)?.toInt() ?? 0,
        arrows: (json['arrows'] as List)
            .map((e) => ArrowSpec.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
