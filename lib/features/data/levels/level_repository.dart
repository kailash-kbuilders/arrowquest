import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../core/constants/app_constants.dart';
import '../models/level.dart';

/// Loads the bundled level pack from [AppConstants.levelsAsset].
///
/// Malformed levels are skipped rather than crashing the game, so a single bad
/// entry can never make the app unlaunchable.
class LevelRepository {
  LevelRepository._();

  static final LevelRepository instance = LevelRepository._();

  List<Level>? _cache;

  Future<List<Level>> load() async {
    final List<Level>? cached = _cache;
    if (cached != null) return cached;

    final String raw = await rootBundle.loadString(AppConstants.levelsAsset);
    final Object? decoded = json.decode(raw);
    final List<Level> levels = <Level>[];

    if (decoded is Map<String, dynamic> && decoded['levels'] is List) {
      for (final Object? entry in decoded['levels'] as List) {
        if (entry is Map<String, dynamic>) {
          try {
            levels.add(Level.fromJson(entry));
          } catch (_) {
            // Skip a malformed level; keep the rest of the pack playable.
          }
        }
      }
    }
    levels.sort((Level a, Level b) => a.id.compareTo(b.id));
    _cache = levels;
    return levels;
  }

  Future<Level?> byId(int id) async {
    for (final Level level in await load()) {
      if (level.id == id) return level;
    }
    return null;
  }
}
