import 'package:shared_preferences/shared_preferences.dart';

/// Local, synchronous-after-init progress store backed by shared_preferences.
class ProgressService {
  ProgressService._();

  static final ProgressService instance = ProgressService._();

  static const String _kUnlocked = 'unlocked_level';
  static const String _kCompleted = 'completed_ids';
  static const String _kBest = 'best_moves'; // "id:moves,id:moves"
  static const String _kSound = 'sound_on';
  static const String _kHaptics = 'haptics_on';

  SharedPreferences? _prefs;

  int _unlocked = 1;
  Set<int> _completed = <int>{};
  Map<int, int> _best = <int, int>{};
  bool _sound = true;
  bool _haptics = true;

  Future<SharedPreferences> _p() async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> init() async {
    final p = await _p();
    _unlocked = p.getInt(_kUnlocked) ?? 1;
    final csv = p.getString(_kCompleted) ?? '';
    _completed = csv.isEmpty
        ? <int>{}
        : csv.split(',').where((s) => s.isNotEmpty).map(int.parse).toSet();
    _best = <int, int>{};
    for (final part in (p.getString(_kBest) ?? '').split(',')) {
      final bits = part.split(':');
      if (bits.length == 2) {
        final id = int.tryParse(bits[0]);
        final mv = int.tryParse(bits[1]);
        if (id != null && mv != null) _best[id] = mv;
      }
    }
    _sound = p.getBool(_kSound) ?? true;
    _haptics = p.getBool(_kHaptics) ?? true;
  }

  int get unlocked => _unlocked;
  Set<int> get completed => _completed;
  bool get soundOn => _sound;
  bool get hapticsOn => _haptics;

  bool isCompleted(int id) => _completed.contains(id);
  bool isUnlocked(int id) => id <= _unlocked;
  int? bestFor(int id) => _best[id];

  Future<void> completeLevel(int id, int movesUsed) async {
    _completed.add(id);
    if (id + 1 > _unlocked) _unlocked = id + 1;
    final prev = _best[id];
    if (prev == null || movesUsed < prev) _best[id] = movesUsed;

    final p = await _p();
    await p.setString(_kCompleted, _completed.join(','));
    await p.setInt(_kUnlocked, _unlocked);
    await p.setString(
      _kBest,
      _best.entries.map((e) => '${e.key}:${e.value}').join(','),
    );
  }

  Future<void> setSound(bool value) async {
    _sound = value;
    await (await _p()).setBool(_kSound, value);
  }

  Future<void> setHaptics(bool value) async {
    _haptics = value;
    await (await _p()).setBool(_kHaptics, value);
  }
}
