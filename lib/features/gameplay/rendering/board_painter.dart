import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../data/models/arrow.dart';

/// Head colour for a direction, from the active palette.
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

double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

int _clampIndex(int i, int n) => i < 0 ? 0 : (i >= n ? n - 1 : i);

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
///
/// Arrow look: a thin, sharp-cornered path in near-black ink with a small solid
/// triangle at the head. The head is the only coloured part, so a dense board
/// still reads as a clean black maze while the direction is unmistakable.
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

  /// An arrow that has just escaped, drawn flowing along its own path and off
  /// the board.
  final Arrow? ghost;
  final double ghostT;

  /// An arrow whose move was refused, drawn shaking in place.
  final Arrow? blockedArrow;
  final double blockedT;

  /// Head cell of a suggested arrow.
  final Cell? hintHead;
  final double hintT;

  @override
  void paint(Canvas canvas, Size size) {
    final BoardGeometry geo = BoardGeometry.fit(size, rows, cols);
    final double cell = geo.cell;

    final Rect boardRect = Rect.fromLTWH(
      geo.originX,
      geo.originY,
      cell * cols,
      cell * rows,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect, Radius.circular(cell * 0.22)),
      Paint()..color = palette.board,
    );

    // A very faint cell tint: enough to help the eye follow the grid without
    // competing with the arrows.
    final Paint cellPaint = Paint()..color = palette.boardCell.withAlpha(55);
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final Rect rect = Rect.fromLTWH(
          geo.originX + c * cell,
          geo.originY + r * cell,
          cell,
          cell,
        ).deflate(cell * 0.10);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.14)),
          cellPaint,
        );
      }
    }

    // Hint halo, under the arrow.
    final Cell? hint = hintHead;
    if (hint != null) {
      for (final Arrow a in arrows) {
        if (a.head == hint) {
          _drawHint(canvas, geo, a);
          break;
        }
      }
    }

    for (final Arrow a in arrows) {
      _drawArrow(canvas, geo, a);
    }

    // Refused-move feedback.
    final Arrow? blocked = blockedArrow;
    if (blocked != null) {
      final double shake =
          math.sin(blockedT * math.pi * 3) * cell * 0.18 * (1 - blockedT);
      final Offset perp =
          Offset(-blocked.dir.dr.toDouble(), blocked.dir.dc.toDouble());
      _drawArrow(canvas, geo, blocked, offset: perp * shake);
    }

    // Escape: the arrow flows along its own path and out of the board.
    final Arrow? escaping = ghost;
    if (escaping != null) {
      final double eased = Curves.easeOutCubic.transform(_clamp01(ghostT));
      final List<Cell> extended = _extendedPath(escaping);
      final int onBoard = escaping.length + _rayLength(escaping);
      final double travel = (onBoard + escaping.length).toDouble();
      _drawArrow(
        canvas,
        geo,
        escaping,
        extended: extended,
        shift: eased * travel,
        opacity: 1 - _clamp01((ghostT - 0.55) / 0.45),
      );
    }
  }

  // ---- Path helpers ------------------------------------------------------

  int _rayLength(Arrow arrow) {
    var n = 0;
    var cur = arrow.head;
    while (true) {
      final Cell next = cur.step(arrow.dir);
      if (!_inBounds(next)) break;
      n++;
      cur = next;
    }
    return n;
  }

  bool _inBounds(Cell c) => c.r >= 0 && c.r < rows && c.c >= 0 && c.c < cols;

  /// Tail -> head, then the exit ray, then enough cells past the edge that the
  /// arrow can leave the board completely.
  List<Cell> _extendedPath(Arrow arrow) {
    final List<Cell> out = <Cell>[...arrow.travelPath];
    var cur = arrow.head;
    while (true) {
      final Cell next = cur.step(arrow.dir);
      if (!_inBounds(next)) break;
      out.add(next);
      cur = next;
    }
    final int extra = arrow.length * 2 + 2;
    for (var i = 0; i < extra; i++) {
      cur = cur.step(arrow.dir);
      out.add(cur);
    }
    return out;
  }

  Offset _pointAt(List<Cell> cells, double s, BoardGeometry geo) {
    final int n = cells.length;
    final int i = _clampIndex(s.floor(), n);
    final int j = _clampIndex(i + 1, n);
    final double frac = _clamp01(s - i);
    return Offset.lerp(geo.center(cells[i]), geo.center(cells[j]), frac)!;
  }

  List<Offset> _points(BoardGeometry geo, Arrow arrow) =>
      arrow.travelPath.map(geo.center).toList(growable: false);

  Path _polyline(List<Offset> points) {
    final Path path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    return path;
  }

  // ---- Drawing -----------------------------------------------------------

  void _drawHint(Canvas canvas, BoardGeometry geo, Arrow arrow) {
    final double pulse = 0.28 + 0.40 * (1 - (hintT - 0.5).abs() * 2);
    canvas.drawPath(
      _polyline(_points(geo, arrow)),
      Paint()
        ..color = palette.primary.withAlpha((255 * pulse).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = geo.cell * 0.46
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawArrow(
    Canvas canvas,
    BoardGeometry geo,
    Arrow arrow, {
    double opacity = 1,
    Offset offset = Offset.zero,
    List<Cell>? extended,
    double shift = 0,
  }) {
    final double cell = geo.cell;
    final int alpha = math.min(255, math.max(0, (255 * opacity).round()));
    final Color ink = palette.ink.withAlpha(alpha);
    // Exactly like the reference: the head is the same ink as the path.
    final Color head = ink;

    final List<Offset> points;
    if (extended == null) {
      points = _points(geo, arrow).map((Offset p) => p + offset).toList();
    } else {
      points = <Offset>[
        for (var j = 0; j < arrow.length; j++)
          _pointAt(extended, shift + j, geo) + offset,
      ];
    }

    // The path: thin, sharp corners, no rounding — the maze look.
    final double width = math.max(1.8, cell * 0.16);
    canvas.drawPath(
      _polyline(points),
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.butt
        ..strokeJoin = StrokeJoin.miter,
    );

    // The head: a small solid triangle, the only coloured part.
    final Offset headPoint = points.last;
    final Offset d = Offset(arrow.dir.dc.toDouble(), arrow.dir.dr.toDouble());
    final Offset perp = Offset(-d.dy, d.dx);
    final double half = math.max(2.0, cell * 0.20);
    final Offset tip = headPoint + d * (cell * 0.46);
    final Offset baseA = headPoint - d * (cell * 0.10) + perp * half;
    final Offset baseB = headPoint - d * (cell * 0.10) - perp * half;
    final Path triangle = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(baseA.dx, baseA.dy)
      ..lineTo(baseB.dx, baseB.dy)
      ..close();
    canvas.drawPath(triangle, Paint()..color = head);
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
