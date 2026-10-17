import 'emitter.dart';

/// One puzzle level. Immutable — the mutable play state lives in GameEngine.
class Level {
  const Level({
    required this.id,
    required this.name,
    required this.chapter,
    required this.rows,
    required this.cols,
    required this.tiles,
    required this.emitters,
    required this.switchTokens,
    required this.bufferSize,
  });

  final int id;
  final String name;
  final String chapter;
  final int rows;
  final int cols;

  /// rows x cols grid; null means an empty cell.
  final List<List<String?>> tiles;

  final List<Emitter> emitters;
  final int switchTokens;
  final int bufferSize;

  factory Level.fromJson(Map<String, dynamic> json) {
    final rawTiles = (json['tiles'] as List).cast<String>();
    final tiles = rawTiles
        .map((row) => row.split('').map<String?>((ch) => ch == '.' ? null : ch).toList())
        .toList();
    final emitters = (json['emitters'] as List)
        .map((e) => Emitter.fromJson(e as Map<String, dynamic>))
        .toList();

    return Level(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      chapter: (json['chapter'] as String?) ?? 'Rain',
      rows: (json['rows'] as num).toInt(),
      cols: (json['cols'] as num).toInt(),
      tiles: tiles,
      emitters: emitters,
      switchTokens: (json['switchTokens'] as num?)?.toInt() ?? 1,
      bufferSize: (json['bufferSize'] as num?)?.toInt() ?? 5,
    );
  }

  /// Total tiles still to be cleared when the level starts.
  int get tileCount => tiles.fold<int>(
        0,
        (sum, row) => sum + row.where((c) => c != null).length,
      );
}
