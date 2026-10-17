import 'package:flutter/material.dart';

import '../engine/quiver_engine.dart';
import '../models/arrow.dart';
import '../theme/app_colors.dart';

/// The board. Arrows are laid out with [AnimatedPositioned] keyed by arrow id,
/// so a slide animates for free when the model changes.
class BoardView extends StatelessWidget {
  const BoardView({
    super.key,
    required this.engine,
    required this.onTap,
    this.hint,
  });

  final QuiverEngine engine;
  final void Function(int row, int col) onTap;

  /// Optional [row, col] to pulse as a suggested move.
  final List<int>? hint;

  List<Widget> _gridCells(double cell) {
    final cells = <Widget>[];
    for (var r = 0; r < engine.rows; r++) {
      for (var c = 0; c < engine.cols; c++) {
        cells.add(Positioned(
          left: c * cell,
          top: r * cell,
          width: cell,
          height: cell,
          child: Padding(
            padding: EdgeInsets.all(cell * 0.05),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(cell * 0.18),
              ),
            ),
          ),
        ));
      }
    }
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: engine.cols / engine.rows,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final cell = constraints.maxWidth / engine.cols;
            final h = hint;

            return Stack(
              children: <Widget>[
                ..._gridCells(cell),
                for (final a in engine.arrows)
                  AnimatedPositioned(
                    key: ValueKey<int>(a.id),
                    duration: const Duration(milliseconds: 170),
                    curve: Curves.easeOutCubic,
                    left: a.col * cell,
                    top: a.row * cell,
                    width: cell,
                    height: cell,
                    child: _ArrowTile(
                      arrow: a,
                      cell: cell,
                      highlighted: h != null &&
                          h.length == 2 &&
                          h[0] == a.row &&
                          h[1] == a.col,
                      onTap: () => onTap(a.row, a.col),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ArrowTile extends StatelessWidget {
  const _ArrowTile({
    required this.arrow,
    required this.cell,
    required this.highlighted,
    required this.onTap,
  });

  final Arrow arrow;
  final double cell;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = arrow.dir.color;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.all(cell * 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(cell * 0.18),
            border: highlighted
                ? Border.all(color: Colors.white, width: 2.5)
                : null,
            boxShadow: <BoxShadow>[
              BoxShadow(color: color.withAlpha(110), blurRadius: cell * 0.14),
            ],
          ),
          child: Icon(arrow.dir.icon, color: Colors.white, size: cell * 0.48),
        ),
      ),
    );
  }
}
