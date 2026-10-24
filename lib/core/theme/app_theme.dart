import 'package:flutter/material.dart';

/// The ArrowQuest palette, exposed as a [ThemeExtension] so the light and dark
/// themes can be swapped at runtime without any widget hard-coding a colour.
///
/// The light theme is the default and is what the board is designed around: a
/// cream board with near-black arrow paths, so the maze of arrows reads exactly
/// the way a good arrow puzzle should. The dark theme is the same design
/// inverted, for anyone who prefers it.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bg,
    required this.board,
    required this.boardCell,
    required this.panel,
    required this.panelHi,
    required this.primary,
    required this.secondary,
    required this.success,
    required this.error,
    required this.text,
    required this.textDim,
    required this.ink,
    required this.dirUp,
    required this.dirDown,
    required this.dirLeft,
    required this.dirRight,
  });

  final Color bg;

  /// The board plate behind the arrows.
  final Color board;

  /// The faint cell tint inside the board.
  final Color boardCell;

  final Color panel;
  final Color panelHi;
  final Color primary;
  final Color secondary;
  final Color success;
  final Color error;
  final Color text;
  final Color textDim;

  /// Colour of the arrow paths themselves.
  final Color ink;

  // Arrow head colours, one per direction.
  final Color dirUp;
  final Color dirDown;
  final Color dirLeft;
  final Color dirRight;

  /// Cream board, near-black arrow paths, coloured heads.
  static const AppPalette light = AppPalette(
    bg: Color(0xFFFAF9F3),
    board: Color(0xFFF5F3E8),
    boardCell: Color(0xFFEBE8D9),
    panel: Color(0xFFFFFFFF),
    panelHi: Color(0xFFEDEADE),
    primary: Color(0xFF2F6BFF),
    secondary: Color(0xFF7C3AED),
    success: Color(0xFF16A34A),
    error: Color(0xFFE4573D),
    text: Color(0xFF17181C),
    textDim: Color(0xFF6E7178),
    ink: Color(0xFF1B1C21),
    dirUp: Color(0xFFE4573D),
    dirDown: Color(0xFF16A34A),
    dirLeft: Color(0xFFD98A16),
    dirRight: Color(0xFF2F6BFF),
  );

  /// The same design, inverted.
  static const AppPalette dark = AppPalette(
    bg: Color(0xFF0C1020),
    board: Color(0xFF141A2C),
    boardCell: Color(0xFF1D2438),
    panel: Color(0xFF161B2E),
    panelHi: Color(0xFF20263C),
    primary: Color(0xFF5B8DEF),
    secondary: Color(0xFF8B5CF6),
    success: Color(0xFF34D399),
    error: Color(0xFFFF6B81),
    text: Color(0xFFF2F4F8),
    textDim: Color(0xFF9AA4BC),
    ink: Color(0xFFE9EBF2),
    dirUp: Color(0xFFFF6B81),
    dirDown: Color(0xFF34D399),
    dirLeft: Color(0xFFF5A524),
    dirRight: Color(0xFF5B8DEF),
  );

  /// Convenience accessor for the palette of the current context.
  static AppPalette of(BuildContext context) {
    return Theme.of(context).extension<AppPalette>() ?? AppPalette.light;
  }

  @override
  AppPalette copyWith({
    Color? bg,
    Color? board,
    Color? boardCell,
    Color? panel,
    Color? panelHi,
    Color? primary,
    Color? secondary,
    Color? success,
    Color? error,
    Color? text,
    Color? textDim,
    Color? ink,
    Color? dirUp,
    Color? dirDown,
    Color? dirLeft,
    Color? dirRight,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      board: board ?? this.board,
      boardCell: boardCell ?? this.boardCell,
      panel: panel ?? this.panel,
      panelHi: panelHi ?? this.panelHi,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      success: success ?? this.success,
      error: error ?? this.error,
      text: text ?? this.text,
      textDim: textDim ?? this.textDim,
      ink: ink ?? this.ink,
      dirUp: dirUp ?? this.dirUp,
      dirDown: dirDown ?? this.dirDown,
      dirLeft: dirLeft ?? this.dirLeft,
      dirRight: dirRight ?? this.dirRight,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      board: Color.lerp(board, other.board, t)!,
      boardCell: Color.lerp(boardCell, other.boardCell, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      panelHi: Color.lerp(panelHi, other.panelHi, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      text: Color.lerp(text, other.text, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      dirUp: Color.lerp(dirUp, other.dirUp, t)!,
      dirDown: Color.lerp(dirDown, other.dirDown, t)!,
      dirLeft: Color.lerp(dirLeft, other.dirLeft, t)!,
      dirRight: Color.lerp(dirRight, other.dirRight, t)!,
    );
  }
}

/// Builds the two Material 3 themes from a palette.
class AppTheme {
  AppTheme._();

  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);

  static ThemeData light() => _build(AppPalette.light, Brightness.light);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: p.primary,
      brightness: brightness,
    ).copyWith(
      primary: p.primary,
      secondary: p.secondary,
      error: p.error,
      surface: p.panel,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      extensions: <ThemeExtension<dynamic>>[p],
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.text,
        elevation: 0,
        centerTitle: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.text,
          side: BorderSide(color: p.panelHi),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.primary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.panelHi,
        contentTextStyle: TextStyle(color: p.text),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
