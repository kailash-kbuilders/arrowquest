import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/ads_service.dart';
import '../../core/services/audio_service.dart';
import '../../core/storage/progress_service.dart';
import '../../core/theme/app_theme.dart';
import '../data/levels/level_repository.dart';
import '../data/models/level.dart';
import '../gameplay/gameplay_screen.dart';
import '../levels/level_select_screen.dart';
import '../settings/settings_screen.dart';
import '../statistics/statistics_screen.dart';

/// The main menu.
///
/// Laid out as a centred, scrollable column capped at a comfortable reading
/// width, so it fits a small phone without overflowing and still looks right on
/// a tablet.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// A stable puzzle for the day: the same level all day, a new one tomorrow.
  int get _dailyLevelId {
    final DateTime now = DateTime.now();
    final int seed = now.year * 372 + now.month * 31 + now.day;
    return 1 + (seed % AppConstants.totalLevels);
  }

  Future<void> _openLevel(int id) async {
    AudioService.instance.tap();
    final Level? level = await LevelRepository.instance.byId(id);
    if (!mounted) return;
    if (level == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That level could not be loaded.')),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => GameplayScreen(level: level)),
    );
    if (mounted) setState(() {});
  }

  void _push(Widget screen) {
    AudioService.instance.tap();
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen))
        .then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ProgressService progress = ProgressService.instance;
    final Size screen = MediaQuery.sizeOf(context);
    final bool compact = screen.height < 700;

    // Resume where the player left off, never past what they have unlocked.
    final int current = progress.currentLevel <= progress.unlocked
        ? progress.currentLevel
        : progress.unlocked;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[palette.panel, palette.bg],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: CustomPaint(painter: _GridPainter(palette: palette)),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            child: FadeTransition(
                              opacity: _fade,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  SizedBox(height: compact ? 8 : 28),
                                  Image.asset(
                                    AppConstants.logoAsset,
                                    height: compact ? 96 : 128,
                                    filterQuality: FilterQuality.high,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.explore,
                                      size: compact ? 72 : 96,
                                      color: palette.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    AppConstants.appName.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: compact ? 28 : 34,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 5,
                                      color: palette.text,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppConstants.tagline,
                                    style: TextStyle(
                                      color: palette.textDim,
                                      fontSize: 12,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                  SizedBox(height: compact ? 14 : 24),
                                  _ProgressCard(
                                    level: current,
                                    progress: progress.overallProgress,
                                    stars: progress.totalStars,
                                    hints: progress.hintsAvailable,
                                    palette: palette,
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: () => _openLevel(current),
                                      child: const Text('CONTINUE'),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _MenuButton(
                                    icon: Icons.grid_view_rounded,
                                    label: 'Play Levels',
                                    onPressed: () =>
                                        _push(const LevelSelectScreen()),
                                  ),
                                  const SizedBox(height: 10),
                                  _MenuButton(
                                    icon: Icons.today,
                                    label: 'Daily Puzzle',
                                    onPressed: () => _openLevel(_dailyLevelId),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: _MenuButton(
                                          icon: Icons.bar_chart,
                                          label: 'Stats',
                                          onPressed: () =>
                                              _push(const StatisticsScreen()),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _MenuButton(
                                          icon: Icons.settings_outlined,
                                          label: 'Settings',
                                          onPressed: () =>
                                              _push(const SettingsScreen()),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const AdBanner(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.level,
    required this.progress,
    required this.stars,
    required this.hints,
    required this.palette,
  });

  final int level;
  final double progress;
  final int stars;
  final int hints;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: palette.panel.withAlpha(200),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.panelHi),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: Text(
                  'Level $level of ${AppConstants.totalLevels}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  Icon(Icons.star_rounded, size: 16, color: palette.dirLeft),
                  const SizedBox(width: 4),
                  Text(
                    '$stars',
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.lightbulb_outline,
                      size: 16, color: palette.dirLeft),
                  const SizedBox(width: 4),
                  Text(
                    '$hints',
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: palette.panelHi,
              valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle board grid behind the menu.
class _GridPainter extends CustomPainter {
  const _GridPainter({required this.palette});

  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final double cell = size.width / 7;
    final Paint paint = Paint()
      ..color = palette.panelHi.withAlpha(70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double x = 0; x <= size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.palette != palette;
}
