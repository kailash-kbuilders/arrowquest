import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
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
        .push(
      MaterialPageRoute<void>(builder: (_) => screen),
    )
        .then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ProgressService progress = ProgressService.instance;
    final int current = progress.unlocked;

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
              child: FadeTransition(
                opacity: _fade,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: <Widget>[
                      const Spacer(flex: 2),
                      Image.asset(
                        AppConstants.logoAsset,
                        height: 128,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.explore,
                          size: 96,
                          color: palette.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppConstants.appName.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 6,
                          color: palette.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppConstants.tagline,
                        style: TextStyle(
                          color: palette.textDim,
                          fontSize: 13,
                          letterSpacing: 3,
                        ),
                      ),
                      const Spacer(flex: 2),
                      _ProgressCard(
                        level: current,
                        progress: progress.overallProgress,
                        stars: progress.totalStars,
                        palette: palette,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => _openLevel(current),
                          child: const Text('CONTINUE'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _push(const LevelSelectScreen()),
                          icon: const Icon(Icons.grid_view_rounded, size: 18),
                          label: const Text('Play Levels'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _openLevel(_dailyLevelId),
                          icon: const Icon(Icons.today, size: 18),
                          label: const Text('Daily Puzzle'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _push(const StatisticsScreen()),
                              icon: const Icon(Icons.bar_chart, size: 18),
                              label: const Text('Stats'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _push(const SettingsScreen()),
                              icon:
                                  const Icon(Icons.settings_outlined, size: 18),
                              label: const Text('Settings'),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(flex: 1),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.level,
    required this.progress,
    required this.stars,
    required this.palette,
  });

  final int level;
  final double progress;
  final int stars;
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
              Text(
                'Level $level of ${AppConstants.totalLevels}',
                style: TextStyle(
                  color: palette.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
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
