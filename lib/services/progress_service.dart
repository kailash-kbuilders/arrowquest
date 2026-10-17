import 'package:shared_preferences/shared_preferences.dart';

/// Local, synchronous-after-init progress store backed by shared_preferences.
class ProgressService {
  ProgressService._();

  static final ProgressService instance = ProgressService._();

  static const String _kUnlocked = 'unlocked_level';
  static const String _kCompleted = 'completed_ids';
  static const String _kSound = 'sound_on';
  static const String _kHaptics = 'haptics_on';
  static const String _kRemoveAds = 'remove_ads';

  SharedPreferences? _prefs;

  int _unlocked = 1;
  Set<int> _completed = <int>{};
  bool _sound = true;
  bool _haptics = true;
  bool _removeAds = false;

  Future<SharedPreferences> _p() async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> init() async {
    final p = await _p();
    _unlocked = p.getInt(_kUnlocked) ?? 1;
    final csv = p.getString(_kCompleted) ?? '';
    _completed = csv.isEmpty
        ? <int>{}
        : csv.split(',').where((s) => s.isNotEmpty).map(int.parse).toSet();
    _sound = p.getBool(_kSound) ?? true;
    _haptics = p.getBool(_kHaptics) ?? true;
    _removeAds = p.getBool(_kRemoveAds) ?? false;
  }

  int get unlocked => _unlocked;
  Set<int> get completed => _completed;
  bool get soundOn => _sound;
  bool get hapticsOn => _haptics;
  bool get removeAds => _removeAds;

  bool isCompleted(int id) => _completed.contains(id);
  bool isUnlocked(int id) => id <= _unlocked;

  Future<void> completeLevel(int id) async {
    _completed.add(id);
    if (id + 1 > _unlocked) _unlocked = id + 1;
    final p = await _p();
    await p.setString(_kCompleted, _completed.join(','));
    await p.setInt(_kUnlocked, _unlocked);
  }

  Future<void> setSound(bool value) async {
    _sound = value;
    final p = await _p();
    await p.setBool(_kSound, value);
  }

  Future<void> setHaptics(bool value) async {
    _haptics = value;
    final p = await _p();
    await p.setBool(_kHaptics, value);
  }

  Future<void> setRemoveAds(bool value) async {
    _removeAds = value;
    final p = await _p();
    await p.setBool(_kRemoveAds, value);
  }
}
