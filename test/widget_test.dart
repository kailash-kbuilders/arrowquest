import 'package:arrowquest/app.dart';
import 'package:arrowquest/core/storage/progress_service.dart';
import 'package:arrowquest/core/storage/settings_service.dart';
import 'package:arrowquest/features/data/levels/level_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Widget-level tests: the app launches, navigates, plays and toggles settings.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The mock store is installed once: the services cache their SharedPreferences
  // handle, so re-mocking between tests would leave them on a stale store.
  setUpAll(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  setUp(() async {
    await SettingsService.instance.init();
    await ProgressService.instance.init();
    await ProgressService.instance.resetProgress();
    // Warm the level cache here, outside the widget tests' fake-async zone,
    // so the level map resolves immediately instead of staying on its spinner.
    await LevelRepository.instance.load();
  });

  /// Launches the app and lets the splash transition settle.
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const ArrowQuestApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> openLevelMap(WidgetTester tester) async {
    await tester.tap(find.text('Play Levels'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> openFirstLevel(WidgetTester tester) async {
    await pumpApp(tester);
    await openLevelMap(tester);
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('smoke: launches to the home screen without exceptions',
      (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.text('CONTINUE'), findsOneWidget);
    expect(find.text('Play Levels'), findsOneWidget);
    expect(find.text('Daily Puzzle'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home navigates to the level map', (WidgetTester tester) async {
    await pumpApp(tester);
    await openLevelMap(tester);

    expect(find.text('Levels'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the level map shows all 100 levels in one grid',
      (WidgetTester tester) async {
    await pumpApp(tester);
    await openLevelMap(tester);

    // Only level 1 is unlocked on a fresh install, so exactly one number shows.
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a level starts and shows hearts, difficulty and controls',
      (WidgetTester tester) async {
    await openFirstLevel(tester);

    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('Difficulty · Easy'), findsOneWidget);
    expect(find.textContaining('arrows remaining'), findsOneWidget);
    expect(find.byTooltip('Hint'), findsOneWidget);
    expect(find.byTooltip('Undo'), findsOneWidget);
    expect(find.byTooltip('Zoom board'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hint and restart are safe to press',
      (WidgetTester tester) async {
    await openFirstLevel(tester);

    final int before = ProgressService.instance.hintsAvailable;
    await tester.tap(find.byTooltip('Hint'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(ProgressService.instance.hintsAvailable, before - 1);

    await tester.tap(find.byTooltip('Restart'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('home navigates to statistics', (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Stats'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Statistics'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings toggle persists', (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Settings'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Sound'), findsOneWidget);
    expect(SettingsService.instance.soundOn, isTrue);

    await tester.tap(find.text('Sound'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(SettingsService.instance.soundOn, isFalse);
    expect(tester.takeException(), isNull);
  });
}
