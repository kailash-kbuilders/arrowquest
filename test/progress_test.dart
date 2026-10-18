import 'package:arrowquest/core/constants/app_constants.dart';
import 'package:arrowquest/core/storage/progress_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final ProgressService progress = ProgressService.instance;

  // Set the mock store exactly once: ProgressService caches its SharedPreferences
  // handle, so re-mocking between tests would leave it pointing at a stale store.
  setUpAll(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  setUp(() async {
    await progress.init();
    await progress.resetProgress();
  });

  test('a fresh install starts at level 1 with nothing completed', () {
    expect(progress.unlocked, 1);
    expect(progress.levelsCompleted, 0);
    expect(progress.totalStars, 0);
    expect(progress.isUnlocked(1), isTrue);
    expect(progress.isUnlocked(2), isFalse);
  });

  test('clearing a level unlocks the next one and records stars', () async {
    await progress.completeLevel(
      id: 1,
      stars: 3,
      moves: 6,
      seconds: 12,
      hintsUsed: 0,
      mistakes: 0,
      arrowsCleared: 6,
    );
    expect(progress.isCompleted(1), isTrue);
    expect(progress.isUnlocked(2), isTrue);
    expect(progress.isUnlocked(3), isFalse);
    expect(progress.starsFor(1), 3);
    expect(progress.bestMovesFor(1), 6);
    expect(progress.totalArrowsRemoved, 6);
    expect(progress.totalPlaySeconds, 12);
  });

  test('clearing level 100 does not create a level 101', () async {
    await progress.completeLevel(
      id: AppConstants.totalLevels,
      stars: 2,
      moves: 20,
      seconds: 30,
      hintsUsed: 1,
      mistakes: 3,
      arrowsCleared: 40,
    );
    expect(progress.unlocked, AppConstants.totalLevels);
    expect(progress.isUnlocked(101), isFalse);
  });

  test('a better score replaces the previous best', () async {
    await progress.completeLevel(
      id: 3,
      stars: 1,
      moves: 30,
      seconds: 5,
      hintsUsed: 0,
      mistakes: 0,
      arrowsCleared: 10,
    );
    await progress.completeLevel(
      id: 3,
      stars: 2,
      moves: 20,
      seconds: 5,
      hintsUsed: 0,
      mistakes: 0,
      arrowsCleared: 10,
    );
    expect(progress.bestMovesFor(3), 20);
    expect(progress.starsFor(3), 2);
  });

  test('progress survives a reload', () async {
    await progress.completeLevel(
      id: 2,
      stars: 3,
      moves: 8,
      seconds: 9,
      hintsUsed: 0,
      mistakes: 1,
      arrowsCleared: 8,
    );
    await progress.init();
    expect(progress.isCompleted(2), isTrue);
    expect(progress.starsFor(2), 3);
    expect(progress.bestMovesFor(2), 8);
    expect(progress.isUnlocked(3), isTrue);
  });

  test('malformed save data is handled without crashing', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('aq_unlocked', 9999);
    await prefs.setString('aq_completed', 'not-json-at-all');
    await prefs.setString('aq_stars', '{"1": 99, "2": 2}');
    await prefs.setString('aq_best_moves', 'nonsense');
    await prefs.setInt('aq_total_seconds', -5);

    await progress.init();

    expect(progress.unlocked, AppConstants.totalLevels); // clamped
    expect(progress.levelsCompleted, 0); // unparseable -> empty
    expect(progress.starsFor(1), 0); // out-of-range star value dropped
    expect(progress.starsFor(2), 2); // valid entry kept
    expect(progress.totalPlaySeconds, 0); // negative clamped
  });

  test('legacy comma-separated completion data still loads', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('aq_completed', '1,2,3');
    await progress.init();
    expect(progress.levelsCompleted, 3);
    expect(progress.isCompleted(2), isTrue);
  });

  test('reset progress clears everything', () async {
    await progress.completeLevel(
      id: 5,
      stars: 3,
      moves: 4,
      seconds: 4,
      hintsUsed: 0,
      mistakes: 0,
      arrowsCleared: 4,
    );
    await progress.resetProgress();
    expect(progress.unlocked, 1);
    expect(progress.levelsCompleted, 0);
    expect(progress.totalStars, 0);
    expect(progress.totalArrowsRemoved, 0);
  });
}
