import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../theme/app_colors.dart';

/// Renders the colour grid. Tiles are read straight from the engine, so any
/// change to the board is reflected on the next rebuild.
class BoardView extends StatelessWidget {
  const BoardView({super.key, required this.engine, this.hintTile});

  final GameEngine engine;

  /// Optional [row, col] to highlight as a suggested move.
  final List<int>? hintTile;

  @override
  Widget build(BuildContext context) {
    final board = engine.board;
    if (board.isEmpty || board.first.isEmpty) return const SizedBox.shrink();

    final rows = board.length;
    final cols = board.first.length;

    return Center(
      child: AspectRatio(
        aspectRatio: cols / rows,
        child: Column(
          children: <Widget>[
            for (var r = 0; r < rows; r++)
              Expanded(
                child: Row(
                  children: <Widget>[
                    for (var c = 0; c < cols; c++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: _Tile(
                            colorKey: board[r][c],
                            highlighted: hintTile != null &&
                                hintTile!.length == 2 &&
                                hintTile![0] == r &&
                                hintTile![1] == c,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.colorKey, required this.highlighted});

  final String? colorKey;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final key = colorKey;
    if (key == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    final color = AppColors.forKey(key);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: highlighted ? Border.all(color: Colors.white, width: 3) : null,
        boxShadow: <BoxShadow>[
          BoxShadow(color: color.withAlpha(120), blurRadius: 10),
        ],
      ),
    );
  }
}
