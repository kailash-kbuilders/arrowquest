import 'package:flutter/material.dart';

import '../models/level.dart';
import '../services/level_repository.dart';
import '../services/progress_service.dart';
import '../theme/app_colors.dart';
import '../widgets/ad_banner.dart';
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
    // Progress may have changed while playing.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Levels')),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
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
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: levels.length,
                    itemBuilder: (context, index) {
                      final level = levels[index];
                      return _LevelTile(level: level, onOpen: _open);
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: unlocked ? () => onOpen(level) : null,
        child: Center(
          child: unlocked
              ? Text(
                  '${level.id}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : const Icon(Icons.lock_outline, color: AppColors.textDim),
        ),
      ),
    );
  }
}
