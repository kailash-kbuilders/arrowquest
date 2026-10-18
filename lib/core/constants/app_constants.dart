/// App-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'ArrowQuest';
  static const String tagline = 'Escape Puzzle';
  static const String version = '1.0.0';

  /// Exactly 100 curated levels ship with the game.
  static const int totalLevels = 100;

  /// Maximum stars a level can award.
  static const int maxStars = 3;

  /// Asset path for the bundled level pack.
  static const String levelsAsset = 'assets/levels/levels.json';

  /// Asset path for the logo.
  static const String logoAsset = 'assets/branding/logo.png';
}
