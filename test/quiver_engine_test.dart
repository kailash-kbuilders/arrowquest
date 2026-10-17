import 'package:flutter_test/flutter_test.dart';
import 'package:quiver/engine/quiver_engine.dart';
import 'package:quiver/models/arrow.dart';
import 'package:quiver/models/level.dart';

Level _level({required int rows, required int cols, required List<ArrowSpec> arrows}) =>
    Level(id: 1, chapter: 'Test', rows: rows, cols: cols, par: 0, arrows: arrows);

void main() {
  test('an arrow slides to the edge and leaves the board', () {
    final engine = QuiverEngine(_level(rows: 3, cols: 3, arrows: <ArrowSpec>[
      const ArrowSpec(row: 1, col: 0, dir: Dir.right),
    ]));
    expect(engine.tap(1, 0), isTrue);
    expect(engine.arrowsLeft, 0);
    expect(engine.won, isTrue);
  });

  test('an arrow stops when another arrow blocks it', () {
    final engine = QuiverEngine(_level(rows: 3, cols: 3, arrows: <ArrowSpec>[
      const ArrowSpec(row: 1, col: 0, dir: Dir.right),
      const ArrowSpec(row: 1, col: 2, dir: Dir.down),
    ]));
    engine.tap(1, 0);
    final moved = engine.arrowAt(1, 1);
    expect(moved, isNotNull);
    expect(moved!.dir, Dir.right);
    expect(engine.arrowAt(1, 0), isNull);
  });

  test('an arrow with something in front of it is jammed', () {
    final engine = QuiverEngine(_level(rows: 3, cols: 3, arrows: <ArrowSpec>[
      const ArrowSpec(row: 1, col: 0, dir: Dir.right),
      const ArrowSpec(row: 1, col: 1, dir: Dir.down),
    ]));
    expect(engine.canMove(1, 0), isFalse);
    expect(engine.tap(1, 0), isFalse);
    expect(engine.moves, 0);
  });

  test('undo restores the previous state', () {
    final engine = QuiverEngine(_level(rows: 3, cols: 3, arrows: <ArrowSpec>[
      const ArrowSpec(row: 1, col: 0, dir: Dir.right),
      const ArrowSpec(row: 1, col: 2, dir: Dir.down),
    ]));
    engine.tap(1, 0);
    expect(engine.arrowAt(1, 0), isNull);
    expect(engine.undo(), isTrue);
    expect(engine.arrowAt(1, 0), isNotNull);
    expect(engine.moves, 0);
  });

  test('restart clears the history', () {
    final engine = QuiverEngine(_level(rows: 3, cols: 3, arrows: <ArrowSpec>[
      const ArrowSpec(row: 1, col: 0, dir: Dir.right),
    ]));
    engine.tap(1, 0);
    engine.restart();
    expect(engine.arrowsLeft, 1);
    expect(engine.moves, 0);
    expect(engine.canUndo, isFalse);
    expect(engine.won, isFalse);
  });

  test('hint points at an arrow that can actually move', () {
    final engine = QuiverEngine(_level(rows: 3, cols: 3, arrows: <ArrowSpec>[
      const ArrowSpec(row: 1, col: 0, dir: Dir.right), // jammed
      const ArrowSpec(row: 1, col: 1, dir: Dir.down),  // free
    ]));
    final h = engine.hint();
    expect(h, isNotNull);
    expect(h![0], 1);
    expect(h[1], 1);
  });
}
