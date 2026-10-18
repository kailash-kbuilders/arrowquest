import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User preferences: audio, haptics, motion and theme.
///
/// A [ChangeNotifier] so the app can rebuild the moment the theme is switched.
class SettingsService extends ChangeNotifier {
  SettingsService._();

  static final SettingsService instance = SettingsService._();

  static const String _kSound = 'aq_sound';
  static const String _kMusic = 'aq_music';
  static const String _kVibration = 'aq_vibration';
  static const String _kReducedMotion = 'aq_reduced_motion';
  static const String _kDarkTheme = 'aq_dark_theme';
  static const String _kChallenge = 'aq_challenge_mode';

  SharedPreferences? _prefs;

  bool _sound = true;
  bool _music = true;
  bool _vibration = true;
  bool _reducedMotion = false;
  bool _darkTheme = true;
  bool _challengeMode = false;

  Future<SharedPreferences> _prefsInstance() async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> init() async {
    try {
      final SharedPreferences p = await _prefsInstance();
      _sound = p.getBool(_kSound) ?? true;
      _music = p.getBool(_kMusic) ?? true;
      _vibration = p.getBool(_kVibration) ?? true;
      _reducedMotion = p.getBool(_kReducedMotion) ?? false;
      _darkTheme = p.getBool(_kDarkTheme) ?? true;
      _challengeMode = p.getBool(_kChallenge) ?? false;
    } catch (_) {
      // Keep defaults.
    }
    notifyListeners();
  }

  bool get soundOn => _sound;
  bool get musicOn => _music;
  bool get vibrationOn => _vibration;
  bool get reducedMotion => _reducedMotion;
  bool get darkTheme => _darkTheme;

  /// Optional timed mode. Off by default — the relaxed mode never has a clock.
  bool get challengeMode => _challengeMode;

  Future<void> setSound(bool value) =>
      _update(() => _sound = value, _kSound, value);

  Future<void> setMusic(bool value) =>
      _update(() => _music = value, _kMusic, value);

  Future<void> setVibration(bool value) =>
      _update(() => _vibration = value, _kVibration, value);

  Future<void> setReducedMotion(bool value) =>
      _update(() => _reducedMotion = value, _kReducedMotion, value);

  Future<void> setDarkTheme(bool value) =>
      _update(() => _darkTheme = value, _kDarkTheme, value);

  Future<void> setChallengeMode(bool value) =>
      _update(() => _challengeMode = value, _kChallenge, value);

  Future<void> _update(void Function() apply, String key, bool value) async {
    apply();
    notifyListeners();
    try {
      final SharedPreferences p = await _prefsInstance();
      await p.setBool(key, value);
    } catch (_) {
      // A failed write must never crash the game.
    }
  }
}
