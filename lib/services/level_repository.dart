import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/level.dart';

/// Loads the bundled level pack from assets/levels/levels.json.
class LevelRepository {
  LevelRepository._();

  static final LevelRepository instance = LevelRepository._();

  List<Level>? _cache;

  Future<List<Level>> load() async {
    final cached = _cache;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString('assets/levels/levels.json');
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final list = (decoded['levels'] as List)
        .map((e) => Level.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = list;
    return list;
  }

  Future<Level?> byId(int id) async {
    for (final level in await load()) {
      if (level.id == id) return level;
    }
    return null;
  }
}
