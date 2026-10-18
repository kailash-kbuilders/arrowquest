import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/storage/progress_service.dart';
import '../../core/theme/app_theme.dart';

/// Lifetime statistics, read straight from the local progress store.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final ProgressService _progress = ProgressService.instance;

  String _duration(int seconds) {
    final int h = seconds ~/ 3600;
    final int m = (seconds % 3600) ~/ 60;
    final int s = seconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final double pct = _progress.overallProgress * 100;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: palette.panel,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'COMPLETION',
                    style: TextStyle(
                      color: palette.textDim,
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_progress.levelsCompleted} / ${AppConstants.totalLevels} levels',
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progress.overallProgress,
                      minHeight: 10,
                      backgroundColor: palette.panelHi,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(palette.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${pct.toStringAsFixed(0)}% complete',
                    style: TextStyle(color: palette.textDim, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _StatTile(
              icon: Icons.star_rounded,
              color: palette.dirLeft,
              label: 'Stars earned',
              value: '${_progress.totalStars} / ${_progress.maxStarsTotal}',
            ),
            _StatTile(
              icon: Icons.ads_click,
              color: palette.dirRight,
              label: 'Arrows removed',
              value: '${_progress.totalArrowsRemoved}',
            ),
            _StatTile(
              icon: Icons.lightbulb_outline,
              color: palette.dirDown,
              label: 'Hints used',
              value: '${_progress.totalHintsUsed}',
            ),
            _StatTile(
              icon: Icons.close_rounded,
              color: palette.error,
              label: 'Blocked attempts',
              value: '${_progress.totalMistakes}',
            ),
            _StatTile(
              icon: Icons.timer_outlined,
              color: palette.primary,
              label: 'Total play time',
              value: _duration(_progress.totalPlaySeconds),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: palette.text, fontSize: 15),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: palette.text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
