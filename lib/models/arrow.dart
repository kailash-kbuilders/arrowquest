import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The four directions an arrow can point.
enum Dir { up, down, left, right }

extension DirX on Dir {
  int get dr => switch (this) {
        Dir.up => -1,
        Dir.down => 1,
        _ => 0,
      };

  int get dc => switch (this) {
        Dir.left => -1,
        Dir.right => 1,
        _ => 0,
      };

  Color get color => switch (this) {
        Dir.up => AppColors.dirUp,
        Dir.down => AppColors.dirDown,
        Dir.left => AppColors.dirLeft,
        Dir.right => AppColors.dirRight,
      };

  IconData get icon => switch (this) {
        Dir.up => Icons.arrow_upward,
        Dir.down => Icons.arrow_downward,
        Dir.left => Icons.arrow_back,
        Dir.right => Icons.arrow_forward,
      };

  /// Single-letter key used in level files.
  String get key => switch (this) {
        Dir.up => 'U',
        Dir.down => 'D',
        Dir.left => 'L',
        Dir.right => 'R',
      };

  static Dir fromKey(String key) => switch (key) {
        'U' => Dir.up,
        'D' => Dir.down,
        'L' => Dir.left,
        'R' => Dir.right,
        _ => Dir.up,
      };
}

/// A live arrow on the board. Position is mutable; direction is fixed.
class Arrow {
  Arrow({required this.id, required this.row, required this.col, required this.dir});

  final int id;
  int row;
  int col;
  final Dir dir;

  Arrow copy() => Arrow(id: id, row: row, col: col, dir: dir);

  @override
  String toString() => 'Arrow#$id($row,$col ${dir.key})';
}

/// The immutable placement of an arrow as described by a level file.
class ArrowSpec {
  const ArrowSpec({required this.row, required this.col, required this.dir});

  final int row;
  final int col;
  final Dir dir;

  factory ArrowSpec.fromJson(Map<String, dynamic> json) => ArrowSpec(
        row: (json['r'] as num).toInt(),
        col: (json['c'] as num).toInt(),
        dir: DirX.fromKey(json['d'] as String),
      );
}
