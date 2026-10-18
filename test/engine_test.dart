import 'package:arrowquest/features/data/models/arrow.dart';
import 'package:arrowquest/features/data/models/level.dart';
import 'package:arrowquest/features/gameplay/logic/engine.dart';
import 'package:flutter_test/flutter_test.dart';

Level _level({
  required List<ArrowSpec> arrows,
  int rows = 6,
  int cols = 6,
  List<Cell> solution = const <Cell>[],
}) {
  return Level(
    id: 1,
    chapter: 'Test',
    rows: rows,
    cols: cols,
    par: arrows.length,
    arrows: arrows,
    solution: solution,
  );
}

ArrowSpec _spec(int r, int c, Dir d, [int len = 1]) =>
    ArrowSpec(row: r, col: c, dir: d, length: len);

void main() {
  group('direction vectors', () {
    test('up is (0, -1)', () {
      expect(Dir.up.dr, -1);
      expect(Dir.up.dc, 0);
    });
    test('down is (0, 1)', () {
      expect(Dir.down.dr, 1);
      expect(Dir.down.dc, 0);
    });
    test('left is (-1, 0)', () {
      expect(Dir.left.dr, 0);
      expect(Dir.left.dc, -1);
    });
    test('right is (1, 0)', () {
      expect(Dir.right.dr, 0);
      expect(Dir.right.dc, 1);
    });
    test('keys round-trip', () {
      for (final Dir d in Dir.values) {
        expect(DirX.fromKey(d.key), d);
      }
    });
  });

  group('exit ray', () {
    test('clear ray reaches the edge', () {
      final engine =
          ArrowQuestEngine(_level(arrows: <ArrowSpec>[_spec(2, 0, Dir.right)]));
      final Arrow a = engine.arrows.single;
      expect(engine.exitRay(a), <Cell>[
        const Cell(2, 1),
        const Cell(2, 2),
        const Cell(2, 3),
        const Cell(2, 4),
        const Cell(2, 5)
      ]);
      expect(engine.canEscape(a), isTrue);
    });

    test('an arrow on the edge has an empty ray and escapes', () {
      final engine =
          ArrowQuestEngine(_level(arrows: <ArrowSpec>[_spec(2, 5, Dir.right)]));
      expect(engine.exitRay(engine.arrows.single), isEmpty);
      expect(engine.canEscape(engine.arrows.single), isTrue);
    });
  });

  group('collision', () {
    test('another arrow in the ray blocks the move', () {
      final engine = ArrowQuestEngine(_level(arrows: <ArrowSpec>[
        _spec(0, 0, Dir.right),
        _spec(0, 3, Dir.up),
      ]));
      final Arrow a = engine.arrowAt(0, 0)!;
      expect(engine.blockerFor(a), isNotNull);
      expect(engine.canEscape(a), isFalse);
    });

    test('an arrow beside the ray does not block', () {
      final engine = ArrowQuestEngine(_level(arrows: <ArrowSpec>[
        _spec(0, 0, Dir.right),
        _spec(3, 3, Dir.up),
      ]));
      expect(engine.canEscape(engine.arrowAt(0, 0)!), isTrue);
    });

    test('a body cell — not just the head — blocks the ray', () {
      // The vertical arrow occupies (0,2), (1,2) and (2,2); only (2,2) is in
      // the horizontal arrow's ray, and that is a body cell.
      final engine = ArrowQuestEngine(_level(arrows: <ArrowSpec>[
        _spec(2, 0, Dir.right),
        _spec(2, 2, Dir.down, 3),
      ]));
      final Arrow horizontal = engine.arrowAt(2, 0)!;
      expect(engine.blockerFor(horizontal), isNotNull);
    });
  });

  group('escape', () {
    test('a clear arrow escapes and frees its cells', () {
      final engine = ArrowQuestEngine(_level(arrows: <ArrowSpec>[
        _spec(2, 0, Dir.right),
        _spec(4, 4, Dir.up),
      ]));
      final MoveOutcome outcome = engine.tap(2, 0);
      expect(outcome.result, MoveResult.escaped);
      expect(outcome.arrow, isNotNull);
      expect(engine.arrowsLeft, 1);
      expect(engine.arrowAt(2, 0), isNull);
      expect(engine.moves, 1);
    });

    test('a blocked tap changes nothing and counts a mistake', () {
      final engine = ArrowQuestEngine(_level(arrows: <ArrowSpec>[
        _spec(0, 0, Dir.right),
        _spec(0, 3, Dir.up),
      ]));
      final MoveOutcome outcome = engine.tap(0, 0);
      expect(outcome.result, MoveResult.blocked);
      expect(engine.arrowsLeft, 2);
      expect(engine.moves, 0);
      expect(engine.mistakes, 1);
    });

    test('tapping an empty cell is ignored', () {
      final engine =
          ArrowQuestEngine(_level(arrows: <ArrowSpec>[_spec(2, 0, Dir.right)]));
      expect(engine.tap(5, 5).result, MoveResult.ignored);
      expect(engine.moves, 0);
    });

    test('double tap cannot start a duplicate escape', () {
      final engine = ArrowQuestEngine(_level(arrows: <ArrowSpec>[
        _spec(2, 0, Dir.right),
        _spec(5, 5, Dir.up),
      ]));
      expect(engine.tap(2, 0).result, MoveResult.escaped);
      expect(engine.tap(2, 0).result, MoveResult.ignored);
      expect(engine.moves, 1);
      expect(engine.arrowsLeft, 1);
    });
  });

  group('win', () {
    test('clearing the last arrow wins', () {
      final engine = ArrowQuestEngine(_level(arrows: <ArrowSpec>[
        _spec(0, 0, Dir.down),
        _spec(1, 3, Dir.up),
      ]));
      expect(engine.tap(0, 0).result, MoveResult.escaped);
      expect(engine.isOver, isFalse);
      expect(engine.tap(1, 3).result, MoveResult.escaped);
      expect(engine.isOver, isTrue);
      expect(engine.arrowsLeft, 0);
    });

    test('taps after the win are ignored', () {
      final engine =
          ArrowQuestEngine(_level(arrows: <ArrowSpec>[_spec(0, 0, Dir.down)]));
      engine.tap(0, 0);
      expect(engine.isOver, isTrue);
      expect(engine.tap(0, 0).result, MoveResult.ignored);
      expect(engine.moves, 1);
    });
  });

  group('undo and restart', () {
    test('undo restores the previous move', () {
      final engine = ArrowQuestEngine(_level(arrows: <ArrowSpec>[
        _spec(2, 0, Dir.right),
        _spec(5, 5, Dir.up),
      ]));
      engine.tap(2, 0);
      expect(engine.arrowsLeft, 1);
      expect(engine.canUndo, isTrue);
      expect(engine.undo(), isTrue);
      expect(engine.arrowsLeft, 2);
      expect(engine.arrowAt(2, 0), isNotNull);
      expect(engine.moves, 0);
    });

    test('undo on a fresh level is a no-op', () {
      final engine =
          ArrowQuestEngine(_level(arrows: <ArrowSpec>[_spec(2, 0, Dir.right)]));
      expect(engine.canUndo, isFalse);
      expect(engine.undo(), isFalse);
    });

    test('restart restores the exact initial state', () {
      final engine = ArrowQuestEngine(_level(arrows: <ArrowSpec>[
        _spec(2, 0, Dir.right),
        _spec(4, 4, Dir.up),
        _spec(5, 0, Dir.right),
      ]));
      engine.tap(2, 0);
      engine.tap(5, 0);
      engine.restart();
      expect(engine.arrowsLeft, 3);
      expect(engine.moves, 0);
      expect(engine.mistakes, 0);
      expect(engine.canUndo, isFalse);
      expect(engine.isOver, isFalse);
    });
  });

  group('hint', () {
    test('never suggests a blocked arrow', () {
      final engine = ArrowQuestEngine(_level(arrows: <ArrowSpec>[
        _spec(0, 0, Dir.right), // blocked by the arrow at (0,3)
        _spec(0, 3, Dir.up), // clear
      ]));
      final Cell? hint = engine.hint();
      expect(hint, isNotNull);
      final Arrow suggested = engine.arrowAt(hint!.r, hint.c)!;
      expect(engine.canEscape(suggested), isTrue);
    });

    test('prefers the arrow that frees the most others', () {
      // The vertical arrow (head (4,3), pointing down) occupies (2,3), (3,3)
      // and (4,3), so it blocks both horizontal arrows. It is the only arrow
      // that frees two others, so it must be the suggestion.
      final engine = ArrowQuestEngine(_level(arrows: <ArrowSpec>[
        _spec(2, 0, Dir.right),
        _spec(4, 0, Dir.right),
        _spec(4, 3, Dir.down, 3),
        _spec(5, 5, Dir.up),
      ]));
      expect(engine.blockerFor(engine.arrowAt(2, 0)!), isNotNull);
      expect(engine.blockerFor(engine.arrowAt(4, 0)!), isNotNull);
      expect(engine.canEscape(engine.arrowAt(4, 3)!), isTrue);
      expect(engine.hint(), const Cell(4, 3));
    });

    test('a solved level has no hint', () {
      final engine =
          ArrowQuestEngine(_level(arrows: <ArrowSpec>[_spec(0, 0, Dir.down)]));
      engine.tap(0, 0);
      expect(engine.hint(), isNull);
    });
  });

  group('malformed input', () {
    test('ArrowSpec rejects non-numeric coordinates', () {
      expect(
        () => ArrowSpec.fromJson(<String, dynamic>{'r': 'x', 'c': 1, 'd': 'U'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('ArrowSpec rejects a zero length', () {
      expect(
        () => ArrowSpec.fromJson(
            <String, dynamic>{'r': 0, 'c': 0, 'd': 'U', 'len': 0}),
        throwsA(isA<FormatException>()),
      );
    });

    test('Level rejects a missing board size', () {
      expect(
        () => Level.fromJson(<String, dynamic>{'id': 1, 'arrows': <dynamic>[]}),
        throwsA(isA<FormatException>()),
      );
    });

    test('Level rejects a zero-sized board', () {
      expect(
        () => Level.fromJson(<String, dynamic>{
          'id': 1,
          'rows': 0,
          'cols': 5,
          'arrows': <dynamic>[],
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
