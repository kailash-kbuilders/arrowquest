import 'package:flutter/material.dart';

import '../models/level.dart';
import '../services/level_repository.dart';
import '../services/progress_service.dart';
import '../theme/app_colors.dart';
import 'gameplay_screen.dart';

class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({super.key});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen> {
  Future<List<Level>>? _future;

  @override
  void initState() {
    super.initState();
    _future = LevelRepository.instance.load();
  }

  Future<void> _open(Level level) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => GameplayScreen(level: level)),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Levels')),
      body: SafeArea(
        child: FutureBuilder<List<Level>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final levels = snapshot.data ?? const <Level>[];
            if (levels.isEmpty) {
              return const Center(
                child: Text('No levels found.',
                    style: TextStyle(color: AppColors.textDim)),
              );
            }

            // Group by chapter, preserving level order.
            final grouped = <String, List<Level>>{};
            for (final level in levels) {
              grouped.putIfAbsent(level.chapter, () => <Level>[]).add(level);
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: <Widget>[
                for (final entry in grouped.entries) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Text(
                      entry.key.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 12,
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
                      childAspectRatio: 1,
                    ),
                    itemCount: entry.value.length,
                    itemBuilder: (context, index) {
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
    final progress = ProgressService.instance;
    final unlocked = progress.isUnlocked(level.id);
    final done = progress.isCompleted(level.id);

    final Color bg;
    if (!unlocked) {
      bg = AppColors.panel;
    } else if (done) {
      bg = AppColors.ok;
    } else {
      bg = AppColors.accent;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: unlocked ? () => onOpen(level) : null,
        child: Center(
          child: unlocked
              ? Text(
                  '${level.id}',
                  style: TextStyle(
                    color: done ? Colors.white : AppColors.bg,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : const Icon(Icons.lock_outline, color: AppColors.textDim, size: 18),
        ),
      ),
    );
  }
}
