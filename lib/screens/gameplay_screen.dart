import 'dart:async';

import 'package:flutter/material.dart';

import '../engine/quiver_engine.dart';
import '../models/level.dart';
import '../services/level_repository.dart';
import '../services/progress_service.dart';
import '../theme/app_colors.dart';
import '../widgets/action_bar.dart';
import '../widgets/board_view.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key, required this.level});

  final Level level;

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  late QuiverEngine _engine;
  List<int>? _hint;
  bool _resultShown = false;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    _engine = QuiverEngine(widget.level);
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _tap(int r, int c) {
    if (!_engine.tap(r, c)) {
      _toast('That arrow is jammed — clear what is in front of it.');
      return;
    }
    setState(() => _hint = null);
    _afterAction();
  }

  void _undo() {
    setState(() {
      _engine.undo();
      _hint = null;
      _resultShown = false;
    });
  }

  void _restart() {
    setState(() {
      _engine.restart();
      _hint = null;
      _resultShown = false;
    });
  }

  void _hintNow() {
    final h = _engine.hint();
    if (h == null) {
      _toast('Nothing can move — restart the level.');
      return;
    }
    setState(() => _hint = h);
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _hint = null);
    });
  }

  void _afterAction() {
    if (_resultShown || !_engine.won) return;
    _resultShown = true;
    _showWin();
  }

  Future<void> _showWin() async {
    final id = widget.level.id;
    final used = _engine.moves;
    await ProgressService.instance.completeLevel(id, used);
    if (!mounted) return;
    final best = ProgressService.instance.bestFor(id);
    final bestLine = (best != null && best < used) ? '\nBest: $best moves' : '';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Cleared'),
        content: Text('Solved in $used moves.$bestLine'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Levels'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _goNext();
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Future<void> _goNext() async {
    final next = await LevelRepository.instance.byId(widget.level.id + 1);
    if (!mounted) return;
    if (next == null) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => GameplayScreen(level: next)),
    );
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(milliseconds: 1200)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.level;
    final best = ProgressService.instance.bestFor(level.id);

    return Scaffold(
      appBar: AppBar(title: Text('Level ${level.id} · ${level.chapter}')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  _Stat(label: 'MOVES', value: '${_engine.moves}'),
                  _Stat(label: 'ARROWS', value: '${_engine.arrowsLeft}'),
                  _Stat(label: 'BEST', value: best == null ? '—' : '$best'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: BoardView(engine: _engine, onTap: _tap, hint: _hint),
              ),
              const SizedBox(height: 14),
              ActionBar(
                canUndo: _engine.canUndo,
                onUndo: _undo,
                onRestart: _restart,
                onHint: _hintNow,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textDim,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
