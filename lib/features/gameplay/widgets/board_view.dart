import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../data/models/arrow.dart';
import '../rendering/board_painter.dart';

/// The board surface: grid, arrows and transient effects.
///
/// It is deliberately stateless — all play state lives in the engine, and all
/// animation state lives in the screen — so the rendered board is always a pure
/// function of the model.
class BoardView extends StatelessWidget {
  const BoardView({
    super.key,
    required this.rows,
    required this.cols,
    required this.arrows,
    required this.onTapCell,
    this.ghost,
    this.ghostT = 0,
    this.blockedArrow,
    this.blockedT = 0,
    this.hintHead,
    this.hintT = 0,
    this.zoomable = true,
  });

  final int rows;
  final int cols;
  final List<Arrow> arrows;
  final void Function(int row, int col) onTapCell;

  final Arrow? ghost;
  final double ghostT;
  final Arrow? blockedArrow;
  final double blockedT;
  final Cell? hintHead;
  final double hintT;

  /// Large boards can be zoomed and panned.
  final bool zoomable;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    final Widget board = AspectRatio(
      aspectRatio: cols / rows,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Size size = Size(constraints.maxWidth, constraints.maxHeight);
          final BoardGeometry geo = BoardGeometry.fit(size, rows, cols);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (TapUpDetails details) {
              final Cell? cell = geo.cellAt(details.localPosition);
              if (cell != null) onTapCell(cell.r, cell.c);
            },
            child: CustomPaint(
              size: size,
              painter: BoardPainter(
                rows: rows,
                cols: cols,
                arrows: arrows,
                palette: palette,
                ghost: ghost,
                ghostT: ghostT,
                blockedArrow: blockedArrow,
                blockedT: blockedT,
                hintHead: hintHead,
                hintT: hintT,
              ),
            ),
          );
        },
      ),
    );

    if (!zoomable) return Center(child: board);

    return InteractiveViewer(
      minScale: 1,
      maxScale: 3,
      panEnabled: true,
      scaleEnabled: true,
      child: Center(child: board),
    );
  }
}
