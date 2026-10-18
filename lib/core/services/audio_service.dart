import 'package:flutter/services.dart';

import '../storage/settings_service.dart';

/// Lightweight, asset-free sound and haptics.
///
/// The game deliberately ships **no** audio files: effects are synthesised by
/// the platform ([SystemSound] / [HapticFeedback]). That removes the single
/// biggest crash risk in a puzzle game — a missing or mis-declared asset — and
/// the whole class no-ops safely when sound or vibration is unavailable.
class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  SettingsService get _settings => SettingsService.instance;

  /// Button press.
  void tap() {
    _sound(SystemSoundType.click);
  }

  /// A successful escape.
  void escape() {
    _sound(SystemSoundType.click);
    _haptic(HapticFeedback.selectionClick);
  }

  /// A rejected move.
  void blocked() {
    _haptic(HapticFeedback.mediumImpact);
  }

  /// Level completed.
  void win() {
    _sound(SystemSoundType.click);
    _haptic(HapticFeedback.heavyImpact);
  }

  void _sound(SystemSoundType type) {
    if (!_settings.soundOn) return;
    try {
      SystemSound.play(type);
    } catch (_) {
      // Sound is a nicety; never let it break gameplay.
    }
  }

  void _haptic(Future<void> Function() effect) {
    if (!_settings.vibrationOn) return;
    try {
      effect();
    } catch (_) {
      // Haptics are a nicety; never let them break gameplay.
    }
  }
}
