import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/ads_service.dart';
import '../../core/services/audio_service.dart';
import '../../core/storage/progress_service.dart';
import '../../core/theme/app_theme.dart';
import '../data/levels/level_repository.dart';
import '../data/models/level.dart';
import '../gameplay/gameplay_screen.dart';

/// All 100 levels in one continuous grid — no chapters, no categories.
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  late Future<List<Level>> _future;

  @override
  void initState() {
    super.initState();
    _future = LevelRepository.instance.load();
  }

  Future<void> _open(Level level) async {
    AudioService.instance.tap();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => GameplayScreen(level: level)),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ProgressService progress = ProgressService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Levels')),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: FutureBuilder<List<Level>>(
                future: _future,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<List<Level>> snapshot,
                ) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final List<Level> levels = snapshot.data ?? const <Level>[];
                  if (levels.isEmpty) {
                    return Center(
                      child: Text(
                        'No levels found.',
                        style: TextStyle(color: palette.textDim),
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: levels.length,
                    itemBuilder: (BuildContext context, int index) {
                      return _LevelTile(
                        level: levels[index],
                        onOpen: _open,
                        progress: progress,
                      );
                    },
                  );
                },
              ),
            ),
            const AdBanner(),
          ],
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.onOpen,
    required this.progress,
  });

  final Level level;
  final Future<void> Function(Level level) onOpen;
  final ProgressService progress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool unlocked = progress.isUnlocked(level.id);
    final bool done = progress.isCompleted(level.id);
    final int stars = progress.starsFor(level.id);
    final bool current = level.id == progress.currentLevel;

    final Color bg = !unlocked
        ? palette.panel
        : done
            ? palette.success
            : current
                ? palette.primary
                : palette.panelHi;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: unlocked ? () => onOpen(level) : null,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: unlocked
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      '${level.id}',
                      style: TextStyle(
                        color: done ? Colors.white : palette.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        for (int i = 0; i < AppConstants.maxStars; i++)
                          Icon(
                            i < stars
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 11,
                            color: i < stars
                                ? Colors.white
                                : palette.textDim.withAlpha(110),
                          ),
                      ],
                    ),
                  ],
                )
              : Center(
                  child: Icon(
                    Icons.lock_outline,
                    color: palette.textDim,
                    size: 18,
                  ),
                ),
        ),
      ),
    );
  }
}
