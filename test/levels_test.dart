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
      expect(
        level.solution,
        isNotEmpty,
        reason: 'level ${level.id} has no solution',
      );
      expect(level.rows, greaterThanOrEqualTo(7));
      expect(level.cols, greaterThanOrEqualTo(7));
      expect(level.rows, lessThanOrEqualTo(16));
      expect(level.cols, lessThanOrEqualTo(16));
      expect(level.par, level.arrows.length);
      expect(
        level.solution.length,
        level.arrows.length,
        reason: 'level ${level.id} solution covers a different arrow count',
      );
    }
  });

  test('difficulty rises across the run and has no chapters', () {
    expect(levels.first.difficulty, Difficulty.easy);
    expect(levels.last.difficulty, Difficulty.hard);
    expect(DifficultyX.forLevel(1), Difficulty.easy);
    expect(DifficultyX.forLevel(100), Difficulty.hard);
  });

  test(
      'every arrow is a connected path inside the board, and no cell is shared',
      () {
    for (final Level level in levels) {
      final Set<Cell> seen = <Cell>{};
      for (final ArrowSpec spec in level.arrows) {
        final List<Cell> cells = spec.resolveCells();
        expect(cells, isNotEmpty);
        for (int i = 0; i < cells.length; i++) {
          final Cell cell = cells[i];
          expect(
            cell.r,
            inInclusiveRange(0, level.rows - 1),
            reason: 'level ${level.id} arrow out of bounds',
          );
          expect(
            cell.c,
            inInclusiveRange(0, level.cols - 1),
            reason: 'level ${level.id} arrow out of bounds',
          );
          expect(
            seen.add(cell),
            isTrue,
            reason: 'level ${level.id} has overlapping arrows at $cell',
          );
          if (i > 0) {
            final Cell prev = cells[i - 1];
            final int gap = (prev.r - cell.r).abs() + (prev.c - cell.c).abs();
            expect(
              gap,
              1,
              reason: 'level ${level.id} path is not connected at $cell',
            );
          }
        }
      }
    }
  });

  test('no arrow sits inside its own exit ray', () {
    for (final Level level in levels) {
      for (final ArrowSpec spec in level.arrows) {
        final List<Cell> cells = spec.resolveCells();
        final Arrow arrow = Arrow(id: 0, cells: cells, dir: spec.dir);
        final ArrowQuestEngine engine = ArrowQuestEngine(level);
        final Set<Cell> ray = engine.exitRay(arrow).toSet();
        for (final Cell cell in cells) {
          expect(
            ray.contains(cell),
            isFalse,
            reason: 'level ${level.id}: $cell is both body and ray',
          );
        }
      }
    }
  });

  test('every level is solvable according to the independent solver', () {
    for (final Level level in levels) {
      expect(
        LevelSolver.isSolvable(level),
        isTrue,
        reason: 'level ${level.id} is not solvable',
      );
      expect(LevelSolver.solve(level)!.length, level.arrows.length);
    }
  });

  test('the stored solution replays cleanly through the engine', () {
    for (final Level level in levels) {
      final ArrowQuestEngine engine = ArrowQuestEngine(level);
      for (final Cell cell in level.solution) {
        final MoveOutcome outcome = engine.tap(cell.r, cell.c);
        expect(
          outcome.result,
          MoveResult.escaped,
          reason: 'level ${level.id}: move at $cell was ${outcome.result}',
        );
      }
      expect(engine.isOver, isTrue, reason: 'level ${level.id} did not finish');
      expect(engine.arrowsLeft, 0);
      expect(engine.moves, level.arrows.length);
      expect(engine.mistakes, 0);
      expect(engine.hearts, ArrowQuestEngine.maxHearts);
    }
  });

  test('the last level does not try to load a 101st level', () {
    final Level last = levels.firstWhere((Level l) => l.id == 100);
    expect(last.id + 1, 101);
    expect(levels.any((Level l) => l.id == 101), isFalse);
  });
}
