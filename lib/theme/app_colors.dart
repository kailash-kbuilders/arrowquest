import 'package:flutter/material.dart';

/// Central palette. Tile colours are keyed by a single letter so level files
/// stay readable ("RRBB" = two red tiles then two blue).
class AppColors {
  AppColors._();

  static const Map<String, Color> tile = <String, Color>{
    'R': Color(0xFFE5484D), // red
    'B': Color(0xFF3E7BFA), // blue
    'G': Color(0xFF30A46C), // green
    'Y': Color(0xFFF5D90A), // yellow
    'P': Color(0xFF8E4EC6), // purple
    'O': Color(0xFFF76B15), // orange
    'C': Color(0xFF00A2C7), // cyan
    'M': Color(0xFFE93D82), // magenta
  };

  static Color forKey(String key) => tile[key] ?? const Color(0xFF9E9E9E);

  static const Color bg = Color(0xFF0E0E16);
  static const Color panel = Color(0xFF1B1B27);
  static const Color panelHi = Color(0xFF262636);
  static const Color accent = Color(0xFF7C6CFF);
  static const Color accentSoft = Color(0xFF9E93FF);
  static const Color danger = Color(0xFFE5484D);
  static const Color ok = Color(0xFF30A46C);
  static const Color textDim = Color(0xFF9A9AB0);
}
