import 'package:arrowquest/features/data/models/arrow.dart';
import 'package:arrowquest/features/data/models/level.dart';
import 'package:arrowquest/features/gameplay/logic/engine.dart';
import 'package:flutter_test/flutter_test.dart';

Level _level({
  required List<ArrowSpec> arrows,
  int rows = 8,
  int cols = 8,
  List<Cell> solution = const <Cell>[],
}) {
  return Level(
    id: 1,
    rows: rows,
    cols: cols,
    difficulty: Difficulty.easy,
    par: arrows.length,
    arrows: arrows,
    solution: solution,
  );
}

ArrowSpec _spec(List<List<int>> cells, Dir d) => ArrowSpec(
      cells: cells.map((List<int> c) => Cell(c[0], c[1])).toList(),
      dir: d,
    );

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
    test('a clear ray reaches the edge', () {
      final engine = ArrowQuestEngine(
        _level(arrows: <ArrowSpec>[
          _spec(<List<int>>[
            <int>[2, 0]
          ], Dir.right)
        ]),
      );
      final Arrow a = engine.arrows.single;
      expect(engine.exitRay(a), <Cell>[
        const Cell(2, 1),
        const Cell(2, 2),
        const Cell(2, 3),
        const Cell(2, 4),
        const Cell(2, 5),
        const Cell(2, 6),
        const Cell(2, 7),
      ]);
      expect(engine.canEscape(a), isTrue);
    });

    test('an arrow on the edge has an empty ray and escapes', () {
      final engine = ArrowQuestEngine(
        _level(arrows: <ArrowSpec>[
          _spec(<List<int>>[
            <int>[2, 7]
          ], Dir.right)
        ]),
      );
      expect(engine.exitRay(engine.arrows.single), isEmpty);
      expect(engine.canEscape(engine.arrows.single), isTrue);
    });
  });

  group('paths', () {
    test('a bent path keeps its head and tail', () {
      final Arrow arrow = Arrow(
        id: 0,
        cells: const <Cell>[Cell(1, 1), Cell(1, 2), Cell(2, 2)],
        dir: Dir.up,
      );
      expect(arrow.head, const Cell(1, 1));
      expect(arrow.tail, const Cell(2, 2));
      expect(arrow.length, 3);
      expect(arrow.travelPath, <Cell>[
        const Cell(2, 2),
        const Cell(1, 2),
        const Cell(1, 1),
      ]);
    });
  });

  group('collision', () {
    test('another arrow in the ray blocks the move', () {
      final engine = ArrowQuestEngine(
        _level(arrows: <ArrowSpec>[
          _spec(<List<int>>[
            <int>[0, 0]
          ], Dir.right),
          _spec(<List<int>>[
            <int>[0, 3]
          ], Dir.up),
        ]),
      );
      final Arrow a = engine.arrowAt(0, 0)!;
      expect(engine.blockerFor(a), isNotNull);
      expect(engine.canEscape(a), isFalse);
    });

    test('an arrow beside the ray does not block', () {
      final engine = ArrowQuestEngine(
        _level(arrows: <ArrowSpec>[
          _spec(<List<int>>[
            <int>[0, 0]
          ], Dir.right),
          _spec(<List<int>>[
            <int>[3, 3]
          ], Dir.up),
        ]),
      );
      expect(engine.canEscape(engine.arrowAt(0, 0)!), isTrue);
    });

    test('a body cell — not just the head — blocks the ray', () {
      // The bent arrow occupies (2,2), (1,2) and (0,2); only (2,2) is in the
      // horizontal arrow's ray, and that is a body cell.
      final engine = ArrowQuestEngine(
        _level(arrows: <ArrowSpec>[
          _spec(<List<int>>[
            <int>[2, 0]
          ], Dir.right),
          _spec(<List<int>>[
            <int>[2, 2],
            <int>[1, 2],
            <int>[0, 2],
          ], Dir.up),
        ]),
      );
      final Arrow horizontal = engine.arrowAt(2, 0)!;
      expect(engine.blockerFor(horizontal), isNotNull);
    });
  });

  group('escape', () {
    test('a clear arrow escapes and frees its cells', () {
      final engine = ArrowQuestEngine(
        _level(arrows: <ArrowSpec>[
          _spec(<List<int>>[
            <int>[2, 0],
            <int>[2, 1],
          ], Dir.up),
          _spec(<List<int>>[
            <int>[5, 5]
          ], Dir.up),
        ]),
      );
      final MoveOutcome outcome = engine.tap(2, 0);
      expect(outcome.result, MoveResult.escaped);
      expect(outcome.arrow, isNotNull);
      expect(engine.arrowsLeft, 1);
      expect(engine.arrowAt(2, 0), isNull);
      expect(engine.arrowAt(2, 1), isNull);
      expect(engine.moves, 1);
      expect(engine.hearts, ArrowQuestEngine.maxHearts);
    });

    test('a blocked tap changes nothing and costs a heart', () {
      final engine = ArrowQuestEngine(
        _level(arrows: <ArrowSpec>[
          _spec(<List<int>>[
            <int>[0, 0]
          ], Dir.right),
          _spec(<List<int>>[
            <int>[0, 3]
          ], Dir.up),
        ]),
      );
      final MoveOutcome outcome = engine.tap(0, 0);
      expect(outcome.result, MoveResult.blocked);
      expect(engine.arrowsLeft, 2);
      expect(engine.moves, 0);
      expect(engine.mistakes, 1);
      expect(engine.hearts, 2);
    });

    test('three refused moves empty the hearts and fail the level', () {
      final engine = ArrowQuestEngine(
        _level(arrows: <ArrowSpec>[
          _spec(<List<int>>[
            <int>[0, 0]
          ], Dir.right),
          _spec(<List<int>>[
            <int>[0, 3]
          ], Dir.up),
        ]),
      );
      expect(engine.tap(0, 0).result, MoveResult.blocked);
      expect(engine.tap(0, 0).result, MoveResult.blocked);
      expect(engine.tap(0, 0).result, MoveResult.failed);
      expect(engine.hearts, 0);
      expect(engine.outOfHearts, isTrue);
    });

    test('tapping an empty cell is ignored', () {
      final engine = ArrowQuestEngine(
        _level(arrows: <ArrowSpec>[
          _spec(<List<int>>[
            <int>[2, 0]
          ], Dir.right)
        ]),
      );
      expect(engine.tap(7, 7).result, MoveResult.ignored);
      expect(engine.moves, 0);
      expect(engine.hearts, ArrowQuestEngine.maxHearts);
    });

    test('double tap cannot start a duplicate escape', () {
      final engine = ArrowQuestEngine(
        _level(arrows: <ArrowSpec>[
          _spec(<List<int>>[
            <int>[2, 0]
          ], Dir.right),
          _spec(<List<int>>[
            <int>[7, 7]
          ], Dir.up),
        ]),
      );
      expect(engine.tap(2, 0).result, MoveResult.escaped);
      expect(engine.tap(2, 0).result, MoveResult.ignored);
      expect(engine.moves, 1);
      expect(engine.arrowsLeft, 1);
    });
  });

  group('win', () {
    test('clearing the last arrow wins', () {
      final engine = ArrowQuestEngine(
        _level(arrows: <ArrowSpec>[
          _spec(<List<int>>[
            <int>[0, 0]
          ], Dir.down),
          _spec(<List<int>>[
            <int>[1, 3]
          ], Dir.up),
        ]),
      );
      expect(engine.tap(0, 0).result, MoveResult.escaped);
      expect(engine.isOver, isFalse);
      expect(engine.tap(1, 3).result, MoveResult.escaped);
      expect(engine.isOver, isTrue);
      expect(engine.arrowsLeft, 0);
    });

    test('taps after the win are ignored', () {
      final engine = ArrowQuestEngine(
        _level(arrows: <ArrowSpec>[
          _spec(<List<int>>[
            <int>[0, 0]
          ], Dir.down)
        ]),
      );
      engine.tap(0, 0);
      expect(engine.isOver, isTrue);
      expect(engine.tap(0, 0).result, MoveResult.ignored);
      expect(engine.moves, 1);
    });
  });

  group('undo and restart', () {
    test('undo restores the previous move and the heart', () {
      final engine = ArrowQuestEngine(
        _level(arrows: <ArrowSpec>[
          _spec(<List<int>>[
            <int>[2, 0]
          ], Dir.right),
          _spec(<List<int>>[
            <int>[7, 7]
          ], Dir.up),
        ]),
      );
      engine.tap(2, 0);
      expect(engine.arrowsLeft, 1);
      expect(engine.canUndo, isTrue);
      expect(engine.undo(), isTrue);
      expect(engine.arrowsLeft, 2);
      expect(engine.arrowAt(2, 0), isNotNull);
      expect(engine.moves, 0);
    });

    test('undo on a fresh level is a no-op', () {
      final engine = ArrowQuestEngine(
        _level(arrows: <ArrowSpec>[
          _spec(<List<int>>[
            <int>[2, 0]
          ], Dir.right)
        ]),
      );
      expect(engine.canUndo, isFalse);
      expect(engine.undo(), isFalse);
    });

    test('restart restores the exact initial state, hearts included', () {
      final engine = ArrowQuestEngine(
        _level(arrows: <ArrowSpec>[
          _spec(<List<int>>[
            <int>[2, 0]
          ], Dir.right),
          _spec(<List<int>>[
            <int>[0, 3]
          ], Dir.right),
          _spec(<List<int>>[
            <int>[7, 0]
          ], Dir.right),
        ]),
      );
      engine.tap(2, 0);
      engine.tap(0, 3);
      engine.restart();
      expect(engine.arrowsLeft, 3);
      expect(engine.moves, 0);
      expect(engine.mistakes, 0);
      expect(engine.hearts, ArrowQuestEngine.maxHearts);
      expect(engine.canUndo, isFalse);
      expect(engine.isOver, isFalse);
    });
  });

  group('hint', () {
    test('never suggests a blocked arrow', () {
      final engine = ArrowQuestEngine(
        _level(arrows: <ArrowSpec>[
          _spec(<List<int>>[
            <int>[0, 0]
          ], Dir.right), // blocked by the arrow at (0,3)
          _spec(<List<int>>[
            <int>[0, 3]
          ], Dir.up), // clear
        ]),
      );
      final Cell? hint = engine.hint();
      expect(hint, isNotNull);
      final Arrow suggested = engine.arrowAt(hint!.r, hint.c)!;
      expect(engine.canEscape(suggested), isTrue);
    });

    test('follows the reference solution order', () {
      // The reference order says (0,3) first, then (0,0).
      final engine = ArrowQuestEngine(
        _level(
          arrows: <ArrowSpec>[
            _spec(<List<int>>[
              <int>[0, 0]
            ], Dir.right),
            _spec(<List<int>>[
              <int>[0, 3]
            ], Dir.up),
          ],
          solution: const <Cell>[Cell(0, 3), Cell(0, 0)],
        ),
      );
      expect(engine.hint(), const Cell(0, 3));
      engine.tap(0, 3);
      expect(engine.hint(), const Cell(0, 0));
    });

    test('stays correct even if the player clears out of order', () {
      final engine = ArrowQuestEngine(
        _level(
          arrows: <ArrowSpec>[
            _spec(<List<int>>[
              <int>[0, 0]
            ], Dir.right),
            _spec(<List<int>>[
              <int>[0, 3]
            ], Dir.up),
            _spec(<List<int>>[
              <int>[4, 4]
            ], Dir.up),
          ],
          solution: const <Cell>[Cell(0, 3), Cell(0, 0), Cell(4, 4)],
        ),
      );
      // Player ignores the reference order and clears the free arrow first.
      expect(engine.tap(4, 4).result, MoveResult.escaped);
      final Cell? hint = engine.hint();
      expect(hint, const Cell(0, 3));
      expect(engine.canEscape(engine.arrowAt(hint!.r, hint.c)!), isTrue);
    });

    test('a solved level has no hint', () {
      final engine = ArrowQuestEngine(
        _level(arrows: <ArrowSpec>[
          _spec(<List<int>>[
            <int>[0, 0]
          ], Dir.down)
        ]),
      );
      engine.tap(0, 0);
      expect(engine.hint(), isNull);
    });
  });

  group('malformed input', () {
    test('ArrowSpec rejects a missing cells list', () {
      expect(
        () => ArrowSpec.fromJson(<String, dynamic>{'d': 'U'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('ArrowSpec rejects a malformed cell', () {
      expect(
        () => ArrowSpec.fromJson(<String, dynamic>{
          'd': 'U',
          'cells': <dynamic>[
            <dynamic>[0]
          ],
        }),
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
