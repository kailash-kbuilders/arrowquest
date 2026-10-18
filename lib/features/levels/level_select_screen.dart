import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/audio_service.dart';
import '../../core/storage/progress_service.dart';
import '../../core/theme/app_theme.dart';
import '../data/levels/level_repository.dart';
import '../data/models/level.dart';
import '../gameplay/gameplay_screen.dart';

/// Levels 1–100 as a scrollable grid, grouped by chapter.
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

    return Scaffold(
      appBar: AppBar(title: const Text('Levels')),
      body: SafeArea(
        child: FutureBuilder<List<Level>>(
          future: _future,
          builder: (BuildContext context, AsyncSnapshot<List<Level>> snapshot) {
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

            final Map<String, List<Level>> grouped = <String, List<Level>>{};
            for (final Level level in levels) {
              grouped.putIfAbsent(level.chapter, () => <Level>[]).add(level);
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: <Widget>[
                for (final MapEntry<String, List<Level>> entry
                    in grouped.entries) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 8),
                    child: Text(
                      entry.key.toUpperCase(),
                      style: TextStyle(
                        color: palette.textDim,
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.86,
                    ),
                    itemCount: entry.value.length,
                    itemBuilder: (BuildContext context, int index) {
                      return _LevelTile(
                        level: entry.value[index],
                        onOpen: _open,
                      );
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({required this.level, required this.onOpen});

  final Level level;
  final Future<void> Function(Level level) onOpen;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ProgressService progress = ProgressService.instance;
    final bool unlocked = progress.isUnlocked(level.id);
    final bool done = progress.isCompleted(level.id);
    final int stars = progress.starsFor(level.id);
    final bool current = unlocked && !done && level.id == progress.unlocked;

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
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
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
                            size: 10,
                            color: i < stars
                                ? Colors.white
                                : palette.textDim.withAlpha(120),
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
