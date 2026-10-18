import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/storage/settings_service.dart';
import '../../core/theme/app_theme.dart';
import '../data/levels/level_repository.dart';
import '../data/models/level.dart';
import '../gameplay/gameplay_screen.dart';

/// Shown the moment a level is cleared.
class LevelCompleteScreen extends StatefulWidget {
  const LevelCompleteScreen({
    super.key,
    required this.level,
    required this.moves,
    required this.seconds,
    required this.stars,
    required this.arrowsCleared,
    required this.timed,
  });

  final Level level;
  final int moves;
  final int seconds;
  final int stars;
  final int arrowsCleared;
  final bool timed;

  @override
  State<LevelCompleteScreen> createState() => _LevelCompleteScreenState();
}

class _LevelCompleteScreenState extends State<LevelCompleteScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pop;

  @override
  void initState() {
    super.initState();
    final bool reduced = SettingsService.instance.reducedMotion;
    _ctrl = AnimationController(
      vsync: this,
      duration: reduced
          ? const Duration(milliseconds: 1)
          : const Duration(milliseconds: 650),
    );
    _pop = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final Level? next =
        await LevelRepository.instance.byId(widget.level.id + 1);
    if (!mounted) return;
    if (next == null) {
      Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => GameplayScreen(level: next)),
    );
  }

  void _replay() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
          builder: (_) => GameplayScreen(level: widget.level)),
    );
  }

  void _home() {
    Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
  }

  String get _time {
    final int m = widget.seconds ~/ 60;
    final int s = widget.seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool isLast = widget.level.id >= AppConstants.totalLevels;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ScaleTransition(
              scale: _pop,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.check_circle, color: palette.success, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    isLast ? 'All levels cleared!' : 'Level cleared',
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Level ${widget.level.id} · ${widget.level.chapter}',
                    style: TextStyle(color: palette.textDim, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  _StarsRow(stars: widget.stars, palette: palette),
                  const SizedBox(height: 24),
                  _StatRow(
                      label: 'Arrows cleared',
                      value: '${widget.arrowsCleared}'),
                  _StatRow(label: 'Moves', value: '${widget.moves}'),
                  if (widget.timed) _StatRow(label: 'Time', value: _time),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isLast ? _home : _next,
                      child: Text(isLast ? 'Back to home' : 'Next level'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _replay,
                          child: const Text('Replay'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _home,
                          child: const Text('Home'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StarsRow extends StatelessWidget {
  const _StarsRow({required this.stars, required this.palette});

  final int stars;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < AppConstants.maxStars; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
              color: i < stars ? palette.dirLeft : palette.textDim,
              size: 44,
            ),
          ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: TextStyle(color: palette.textDim, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: palette.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
