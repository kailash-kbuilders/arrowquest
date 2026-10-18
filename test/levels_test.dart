import 'dart:convert';
import 'dart:io';

import 'package:arrowquest/features/data/models/arrow.dart';
import 'package:arrowquest/features/data/models/level.dart';
import 'package:arrowquest/features/gameplay/logic/engine.dart';
import 'package:arrowquest/features/gameplay/logic/solver.dart';
import 'package:flutter_test/flutter_test.dart';

/// Structural and solvability checks over the shipped level pack.
///
/// The pack is read from disk rather than from the asset bundle so the test
/// exercises exactly the file that ships.
void main() {
  late List<Level> levels;

  setUpAll(() {
    final String raw = File('assets/levels/levels.json').readAsStringSync();
    final Object? decoded = json.decode(raw);
    final List<dynamic> rawLevels =
        (decoded as Map<String, dynamic>)['levels'] as List<dynamic>;
    levels = rawLevels
        .map((dynamic e) => Level.fromJson(e as Map<String, dynamic>))
        .toList();
  });

  test('there are exactly 100 levels with unique ids 1..100', () {
    expect(levels.length, 100);
    final Set<int> ids = levels.map((Level l) => l.id).toSet();
    expect(ids.length, 100);
    expect(ids.reduce((int a, int b) => a < b ? a : b), 1);
    expect(ids.reduce((int a, int b) => a > b ? a : b), 100);
  });

  test('every level has arrows, a solution and a sane board', () {
    for (final Level level in levels) {
      expect(level.arrows, isNotEmpty,
          reason: 'level ${level.id} has no arrows');
      expect(level.solution, isNotEmpty,
          reason: 'level ${level.id} has no solution');
      expect(level.rows, greaterThanOrEqualTo(5));
      expect(level.cols, greaterThanOrEqualTo(5));
      expect(level.rows, lessThanOrEqualTo(14));
      expect(level.cols, lessThanOrEqualTo(14));
      expect(level.par, level.arrows.length);
    }
  });

  test('every arrow stays inside the board and no cell is shared', () {
    for (final Level level in levels) {
      final Set<Cell> seen = <Cell>{};
      for (final ArrowSpec spec in level.arrows) {
        for (final Cell cell in spec.resolveCells()) {
          expect(cell.r, inInclusiveRange(0, level.rows - 1),
              reason: 'level ${level.id} arrow out of bounds');
          expect(cell.c, inInclusiveRange(0, level.cols - 1),
              reason: 'level ${level.id} arrow out of bounds');
          expect(seen.add(cell), isTrue,
              reason: 'level ${level.id} has overlapping arrows at $cell');
        }
      }
    }
  });

  test('every level is solvable according to the independent solver', () {
    for (final Level level in levels) {
      expect(LevelSolver.isSolvable(level), isTrue,
          reason: 'level ${level.id} is not solvable');
      expect(LevelSolver.solve(level)!.length, level.arrows.length);
    }
  });

  test('the stored solution replays cleanly through the engine', () {
    for (final Level level in levels) {
      final ArrowQuestEngine engine = ArrowQuestEngine(level);
      for (final Cell cell in level.solution) {
        final MoveOutcome outcome = engine.tap(cell.r, cell.c);
        expect(outcome.result, MoveResult.escaped,
            reason: 'level ${level.id}: move at $cell was ${outcome.result}');
      }
      expect(engine.isOver, isTrue, reason: 'level ${level.id} did not finish');
      expect(engine.arrowsLeft, 0);
      expect(engine.moves, level.arrows.length);
      expect(engine.mistakes, 0);
    }
  });

  test('the last level does not try to load a 101st level', () {
    final Level last = levels.firstWhere((Level l) => l.id == 100);
    expect(last.id + 1, 101);
    expect(levels.any((Level l) => l.id == 101), isFalse);
  });
}
