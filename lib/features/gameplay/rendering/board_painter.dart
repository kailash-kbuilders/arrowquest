import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../data/models/arrow.dart';

/// Colour for a direction, from the active palette.
Color dirColor(AppPalette palette, Dir dir) {
  switch (dir) {
    case Dir.up:
      return palette.dirUp;
    case Dir.down:
      return palette.dirDown;
    case Dir.left:
      return palette.dirLeft;
    case Dir.right:
      return palette.dirRight;
  }
}

/// Geometry for a board of [rows] x [cols] laid out inside [size].
class BoardGeometry {
  const BoardGeometry._({
    required this.cell,
    required this.originX,
    required this.originY,
    required this.rows,
    required this.cols,
  });

  final double cell;
  final double originX;
  final double originY;
  final int rows;
  final int cols;

  factory BoardGeometry.fit(Size size, int rows, int cols) {
    final double cell = math.min(size.width / cols, size.height / rows);
    return BoardGeometry._(
      cell: cell,
      originX: (size.width - cell * cols) / 2,
      originY: (size.height - cell * rows) / 2,
      rows: rows,
      cols: cols,
    );
  }

  Offset center(Cell c) =>
      Offset(originX + (c.c + 0.5) * cell, originY + (c.r + 0.5) * cell);

  /// The grid cell under a local position, or null if outside the board.
  Cell? cellAt(Offset local) {
    final int c = ((local.dx - originX) / cell).floor();
    final int r = ((local.dy - originY) / cell).floor();
    if (r < 0 || r >= rows || c < 0 || c >= cols) return null;
    return Cell(r, c);
  }
}

/// Paints the grid and every arrow, plus the transient escape, blocked and
/// hint effects.
class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.rows,
    required this.cols,
    required this.arrows,
    required this.palette,
    this.ghost,
    this.ghostT = 0,
    this.blockedArrow,
    this.blockedT = 0,
    this.hintHead,
    this.hintT = 0,
  });

  final int rows;
  final int cols;
  final List<Arrow> arrows;
  final AppPalette palette;

  /// An arrow that has just escaped, drawn sliding off the board.
  final Arrow? ghost;
  final double ghostT;

  /// An arrow whose move was rejected, drawn shaking in place.
  final Arrow? blockedArrow;
  final double blockedT;

  /// Head cell of a suggested arrow.
  final Cell? hintHead;
  final double hintT;

  @override
  void paint(Canvas canvas, Size size) {
    final BoardGeometry geo = BoardGeometry.fit(size, rows, cols);
    final double cell = geo.cell;

    // Board plate.
    final Rect boardRect = Rect.fromLTWH(
      geo.originX,
      geo.originY,
      cell * cols,
      cell * rows,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect, Radius.circular(cell * 0.30)),
      Paint()..color = palette.panel,
    );

    // Empty cells.
    final Paint gridPaint = Paint()..color = palette.panelHi;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final Rect rect = Rect.fromLTWH(
          geo.originX + c * cell,
          geo.originY + r * cell,
          cell,
          cell,
        ).deflate(cell * 0.06);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.18)),
          gridPaint,
        );
      }
    }

    // Hint pulse, drawn beneath the arrow so it reads as a halo.
    final Cell? hint = hintHead;
    if (hint != null) {
      for (final Arrow a in arrows) {
        if (a.head == hint) {
          _drawHint(canvas, geo, a);
          break;
        }
      }
    }

    // Live arrows.
    for (final Arrow a in arrows) {
      _drawArrow(canvas, geo, a, opacity: 1, offset: Offset.zero);
    }

    // Blocked feedback.
    final Arrow? blocked = blockedArrow;
    if (blocked != null) {
      final double shake =
          math.sin(blockedT * math.pi * 3) * cell * 0.16 * (1 - blockedT);
      final Offset perp =
          Offset(-blocked.dir.dr.toDouble(), blocked.dir.dc.toDouble());
      _drawArrow(canvas, geo, blocked, opacity: 1, offset: perp * shake);
    }

    // Escape animation.
    final Arrow? escaping = ghost;
    if (escaping != null) {
      final double raw = ghostT < 0 ? 0 : (ghostT > 1 ? 1 : ghostT);
      final double eased = Curves.easeOutCubic.transform(raw);
      final double distance = (rows + cols + 3) * cell;
      final Offset dir =
          Offset(escaping.dir.dc.toDouble(), escaping.dir.dr.toDouble());
      _drawArrow(
        canvas,
        geo,
        escaping,
        opacity: math.max(0.0, math.min(1.0, 1 - eased)),
        offset: dir * (distance * eased),
      );
    }
  }

  void _drawHint(Canvas canvas, BoardGeometry geo, Arrow arrow) {
    final double cell = geo.cell;
    final Rect rect = _unionRect(geo, arrow).inflate(cell * 0.06);
    final double pulse = 0.35 + 0.45 * (1 - (hintT - 0.5).abs() * 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.28)),
      Paint()
        ..color = palette.primary.withAlpha((255 * pulse).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.09,
    );
  }

  Rect _unionRect(BoardGeometry geo, Arrow arrow) {
    var minR = arrow.cells.first.r;
    var maxR = arrow.cells.first.r;
    var minC = arrow.cells.first.c;
    var maxC = arrow.cells.first.c;
    for (final Cell c in arrow.cells) {
      minR = math.min(minR, c.r);
      maxR = math.max(maxR, c.r);
      minC = math.min(minC, c.c);
      maxC = math.max(maxC, c.c);
    }
    return Rect.fromLTWH(
      geo.originX + minC * geo.cell,
      geo.originY + minR * geo.cell,
      (maxC - minC + 1) * geo.cell,
      (maxR - minR + 1) * geo.cell,
    );
  }

  void _drawArrow(
    Canvas canvas,
    BoardGeometry geo,
    Arrow arrow, {
    required double opacity,
    required Offset offset,
  }) {
    final double cell = geo.cell;
    final Color base = dirColor(palette, arrow.dir);
    final int alpha = math.min(255, math.max(0, (255 * opacity).round()));
    final Color body = base.withAlpha(alpha);
    final Color tip = Color.lerp(base, Colors.white, 0.55)!.withAlpha(alpha);

    // Body: one rounded bar spanning the arrow's cells.
    final Rect rect = _unionRect(geo, arrow).deflate(cell * 0.13).shift(offset);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.24)),
      Paint()..color = body,
    );

    // Head: a triangle pointing in the arrow's direction.
    final Offset center = geo.center(arrow.head) + offset;
    final Offset dir = Offset(arrow.dir.dc.toDouble(), arrow.dir.dr.toDouble());
    final Offset perp = Offset(-dir.dy, dir.dx);
    final Offset tipPoint = center + dir * (cell * 0.46);
    final Offset baseCenter = center - dir * (cell * 0.06);
    final double halfWidth = cell * 0.30;
    final Path path = Path()
      ..moveTo(tipPoint.dx, tipPoint.dy)
      ..lineTo(baseCenter.dx + perp.dx * halfWidth,
          baseCenter.dy + perp.dy * halfWidth)
      ..lineTo(baseCenter.dx - perp.dx * halfWidth,
          baseCenter.dy - perp.dy * halfWidth)
      ..close();
    canvas.drawPath(path, Paint()..color = tip);
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) {
    return old.rows != rows ||
        old.cols != cols ||
        old.arrows != arrows ||
        old.ghost != ghost ||
        old.ghostT != ghostT ||
        old.blockedArrow != blockedArrow ||
        old.blockedT != blockedT ||
        old.hintHead != hintHead ||
        old.hintT != hintT ||
        old.palette != palette;
  }
}
