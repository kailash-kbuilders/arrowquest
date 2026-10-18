import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Local, device-only progress: unlocks, stars, best results and lifetime
/// statistics. Nothing leaves the device.
///
/// Every read is defensive — a missing, malformed or outdated save must fall
/// back to defaults instead of breaking the game.
class ProgressService extends ChangeNotifier {
  ProgressService._();

  static final ProgressService instance = ProgressService._();

  static const String _kUnlocked = 'aq_unlocked';
  static const String _kCompleted = 'aq_completed';
  static const String _kStars = 'aq_stars';
  static const String _kBest = 'aq_best_moves';
  static const String _kTotalArrows = 'aq_total_arrows';
  static const String _kTotalSeconds = 'aq_total_seconds';
  static const String _kTotalHints = 'aq_total_hints';
  static const String _kTotalMistakes = 'aq_total_mistakes';

  SharedPreferences? _prefs;

  int _unlocked = 1;
  final Set<int> _completed = <int>{};
  final Map<int, int> _stars = <int, int>{};
  final Map<int, int> _bestMoves = <int, int>{};
  int _totalArrows = 0;
  int _totalSeconds = 0;
  int _totalHints = 0;
  int _totalMistakes = 0;

  Future<SharedPreferences> _prefsInstance() async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> init() async {
    try {
      final SharedPreferences p = await _prefsInstance();
      _unlocked = p.getInt(_kUnlocked) ?? 1;
      _completed
        ..clear()
        ..addAll(_decodeIntSet(p.getString(_kCompleted)));
      _stars
        ..clear()
        ..addAll(_decodeIntMap(p.getString(_kStars)));
      _bestMoves
        ..clear()
        ..addAll(_decodeIntMap(p.getString(_kBest)));
      _totalArrows = p.getInt(_kTotalArrows) ?? 0;
      _totalSeconds = p.getInt(_kTotalSeconds) ?? 0;
      _totalHints = p.getInt(_kTotalHints) ?? 0;
      _totalMistakes = p.getInt(_kTotalMistakes) ?? 0;
    } catch (_) {
      // Corrupt or unavailable storage: keep the in-memory defaults.
    }
    _sanitize();
    notifyListeners();
  }

  /// Drops anything out of range so a bad save can never lock the game.
  void _sanitize() {
    _unlocked = _unlocked < 1
        ? 1
        : (_unlocked > AppConstants.totalLevels
            ? AppConstants.totalLevels
            : _unlocked);
    _completed.removeWhere((int id) => id < 1 || id > AppConstants.totalLevels);
    _stars.removeWhere((int id, int v) =>
        id < 1 ||
        id > AppConstants.totalLevels ||
        v < 0 ||
        v > AppConstants.maxStars);
    _bestMoves.removeWhere(
        (int id, int v) => id < 1 || id > AppConstants.totalLevels || v < 0);
    if (_totalArrows < 0) _totalArrows = 0;
    if (_totalSeconds < 0) _totalSeconds = 0;
    if (_totalHints < 0) _totalHints = 0;
    if (_totalMistakes < 0) _totalMistakes = 0;
  }

  // ---- Reads -------------------------------------------------------------

  int get unlocked => _unlocked;
  int get levelsCompleted => _completed.length;
  int get totalStars => _stars.values.fold(0, (int sum, int v) => sum + v);
  int get maxStarsTotal => AppConstants.totalLevels * AppConstants.maxStars;
  int get totalArrowsRemoved => _totalArrows;
  int get totalPlaySeconds => _totalSeconds;
  int get totalHintsUsed => _totalHints;
  int get totalMistakes => _totalMistakes;
  Set<int> get completed => Set<int>.unmodifiable(_completed);

  bool isUnlocked(int id) => id >= 1 && id <= _unlocked;
  bool isCompleted(int id) => _completed.contains(id);
  int starsFor(int id) => _stars[id] ?? 0;
  int? bestMovesFor(int id) => _bestMoves[id];

  /// Progress across the whole game, 0.0 – 1.0.
  double get overallProgress => _completed.length / AppConstants.totalLevels;

  // ---- Writes ------------------------------------------------------------

  /// Records a cleared level and folds the run into the lifetime statistics.
  Future<void> completeLevel({
    required int id,
    required int stars,
    required int moves,
    required int seconds,
    required int hintsUsed,
    required int mistakes,
    required int arrowsCleared,
  }) async {
    _completed.add(id);
    // Clearing a level unlocks the next one; level 100 has no successor.
    final int next = id < AppConstants.totalLevels ? id + 1 : id;
    if (next > _unlocked) _unlocked = next;
    if (stars > starsFor(id)) _stars[id] = stars;
    final int? prev = _bestMoves[id];
    if (prev == null || moves < prev) _bestMoves[id] = moves;

    _totalArrows += arrowsCleared;
    _totalSeconds += seconds;
    _totalHints += hintsUsed;
    _totalMistakes += mistakes;

    _sanitize();
    notifyListeners();
    await _save();
  }

  /// Adds a hint to the lifetime counter (called when a hint is revealed).
  Future<void> recordHint() async {
    _totalHints += 1;
    notifyListeners();
    await _save();
  }

  /// Wipes every trace of progress.
  Future<void> resetProgress() async {
    _unlocked = 1;
    _completed.clear();
    _stars.clear();
    _bestMoves.clear();
    _totalArrows = 0;
    _totalSeconds = 0;
    _totalHints = 0;
    _totalMistakes = 0;
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    try {
      final SharedPreferences p = await _prefsInstance();
      await p.setInt(_kUnlocked, _unlocked);
      await p.setString(_kCompleted, json.encode(_completed.toList()));
      // json.encode requires string keys, so the int-keyed maps are stringified
      // here and parsed back in _decodeIntMap.
      await p.setString(_kStars, json.encode(_stringKeyed(_stars)));
      await p.setString(_kBest, json.encode(_stringKeyed(_bestMoves)));
      await p.setInt(_kTotalArrows, _totalArrows);
      await p.setInt(_kTotalSeconds, _totalSeconds);
      await p.setInt(_kTotalHints, _totalHints);
      await p.setInt(_kTotalMistakes, _totalMistakes);
    } catch (_) {
      // A failed write must never crash the game.
    }
  }

  static Map<String, int> _stringKeyed(Map<int, int> source) =>
      source.map((int k, int v) => MapEntry<String, int>('$k', v));

  // ---- Decoders ----------------------------------------------------------

  static Set<int> _decodeIntSet(String? raw) {
    if (raw == null || raw.isEmpty) return <int>{};
    try {
      final Object? decoded = json.decode(raw);
      if (decoded is List) {
        return decoded.whereType<num>().map((num n) => n.toInt()).toSet();
      }
    } catch (_) {
      // Legacy comma-separated format.
      final Set<int> out = <int>{};
      for (final String part in raw.split(',')) {
        final int? v = int.tryParse(part.trim());
        if (v != null) out.add(v);
      }
      return out;
    }
    return <int>{};
  }

  static Map<int, int> _decodeIntMap(String? raw) {
    if (raw == null || raw.isEmpty) return <int, int>{};
    final Map<int, int> out = <int, int>{};
    try {
      final Object? decoded = json.decode(raw);
      if (decoded is Map) {
        decoded.forEach((Object? k, Object? v) {
          final int? key = k is num ? k.toInt() : int.tryParse('$k');
          final int? value = v is num ? v.toInt() : int.tryParse('$v');
          if (key != null && value != null) out[key] = value;
        });
      }
    } catch (_) {
      // Ignore malformed maps.
    }
    return out;
  }
}
