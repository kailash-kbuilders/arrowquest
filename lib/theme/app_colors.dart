import 'package:flutter/material.dart';

/// Central palette. Arrows are coloured by the direction they point, which is
/// what makes a dense board readable at a glance.
class AppColors {
  AppColors._();

  static const Color bg = Color(0xFF0C0F16);
  static const Color panel = Color(0xFF171B24);
  static const Color panelHi = Color(0xFF232833);
  static const Color accent = Color(0xFFFFB020);
  static const Color ok = Color(0xFF2FC7A8);
  static const Color danger = Color(0xFFFF5C7A);
  static const Color text = Color(0xFFE8EAF0);
  static const Color textDim = Color(0xFF8A93A6);

  // Direction colours.
  static const Color dirUp = Color(0xFFFF5C7A);
  static const Color dirDown = Color(0xFF2FC7A8);
  static const Color dirLeft = Color(0xFFE8804B);
  static const Color dirRight = Color(0xFF5B8DEF);
}
