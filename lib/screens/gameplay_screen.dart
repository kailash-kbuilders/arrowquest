import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/level.dart';
import '../services/ads_service.dart';
import '../services/level_repository.dart';
import '../services/progress_service.dart';
import '../theme/app_colors.dart';
import '../widgets/action_bar.dart';
import '../widgets/board_view.dart';
import '../widgets/booster_bar.dart';
import '../widgets/buffer_view.dart';
import '../widgets/rail_view.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key, required this.level});

  final Level level;

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  late GameEngine _engine;
  List<int>? _hint;
  bool _resultShown = false;

  @override
  void initState() {
    super.initState();
    _engine = GameEngine(widget.level);
  }

  // ---- Actions -----------------------------------------------------------

  void _fire() {
    setState(() {
      _engine.fire();
      _hint = null;
    });
    _afterAction();
  }

  void _park() {
    setState(() {
      _engine.park();
      _hint = null;
    });
    _afterAction();
  }

  void _switch() {
    setState(() {
      _engine.switchDirection();
      _hint = null;
    });
    _afterAction();
  }

  void _undo() {
    setState(() {
      _engine.undo();
      _hint = null;
      _resultShown = false;
    });
  }

  void _afterAction() {
    if (_resultShown) return;
    if (_engine.won) {
      _resultShown = true;
      _showWin();
    } else if (_engine.lost) {
      _resultShown = true;
      _showLose();
    }
  }

  // ---- Rewarded boosters -------------------------------------------------

  /// Returns true when the effect should be granted. If the ad SDK is not
  /// available the booster is granted for free so the game stays playable.
  Future<bool> _rewardGate() async {
    if (!AdsService.instance.ready) return true;
    return AdsService.instance.showRewarded();
  }

  Future<void> _useHint() async {
    final tile = _engine.hintTile();
    if (tile == null) {
      _toast('Front emitter is blocked — SWITCH or PARK instead.');
      return;
    }
    final ok = await _rewardGate();
    if (!mounted) return;
    if (!ok) {
      _toast('Ad not completed — no hint this time.');
      return;
    }
    setState(() => _hint = tile);
    _toast('Next tile highlighted.');
  }

  Future<void> _useExtraSlot() async {
    final ok = await _rewardGate();
    if (!mounted) return;
    if (!ok) {
      _toast('Ad not completed.');
      return;
    }
    setState(() {
      _engine.grantBufferSlot();
      _hint = null;
    });
    _toast('+1 buffer slot.');
  }

  Future<void> _useExtraSwitch() async {
    final ok = await _rewardGate();
    if (!mounted) return;
    if (!ok) {
      _toast('Ad not completed.');
      return;
    }
    setState(() {
      _engine.grantSwitchToken();
      _hint = null;
    });
    _toast('+1 switch token.');
  }

  // ---- Result dialogs ----------------------------------------------------

  Future<void> _showWin() async {
    await ProgressService.instance.completeLevel(widget.level.id);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Level cleared'),
        content: Text(
          '${widget.level.name} solved in ${_engine.moves} moves.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Level map'),
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

  Future<void> _showLose() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Jammed'),
        content: const Text(
          'The buffer filled up. Revive to open a slot, or retry the level.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Level map'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _retry();
            },
            child: const Text('Retry'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final ok = await _rewardGate();
              if (!ok) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Ad not completed.')),
                  );
                }
                return;
              }
              Navigator.of(ctx).pop();
              setState(() {
                _engine.revive();
                _resultShown = false;
              });
            },
            icon: const Icon(Icons.play_circle_fill, size: 16),
            label: const Text('Revive'),
          ),
        ],
      ),
    );
  }

  Future<void> _goNext() async {
    await AdsService.instance.maybeShowInterstitial();
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

  void _retry() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GameplayScreen(level: widget.level),
      ),
    );
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // ---- Build -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final level = widget.level;
    final front = _engine.front;
    final blocked = front != null && !_engine.canFire;

    return Scaffold(
      appBar: AppBar(
        title: Text('Level ${level.id} · ${level.name}'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Undo',
            onPressed: _engine.isOver ? null : _undo,
            icon: const Icon(Icons.undo),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  _Stat(label: 'MOVES', value: '${_engine.moves}'),
                  _Stat(label: 'TILES', value: '${_engine.tilesLeft}'),
                  _Stat(label: 'SWITCH', value: '${_engine.switchTokens}'),
                ],
              ),
              const SizedBox(height: 12),
              BufferView(engine: _engine),
              const SizedBox(height: 12),
              Expanded(child: BoardView(engine: _engine, hintTile: _hint)),
              const SizedBox(height: 10),
              if (blocked)
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Front emitter is blocked — PARK or SWITCH',
                    style: TextStyle(color: AppColors.danger, fontSize: 12),
                  ),
                ),
              Row(
                children: <Widget>[
                  const Text(
                    'FLOW',
                    style: TextStyle(
                      color: AppColors.textDim,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _engine.direction >= 0
                        ? Icons.arrow_forward
                        : Icons.arrow_back,
                    size: 16,
                    color: AppColors.accentSoft,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              RailView(engine: _engine),
              const SizedBox(height: 12),
              ActionBar(
                engine: _engine,
                onFire: _fire,
                onPark: _park,
                onSwitch: _switch,
              ),
              const SizedBox(height: 8),
              BoosterBar(
                onHint: _useHint,
                onExtraSlot: _useExtraSlot,
                onExtraSwitch: _useExtraSwitch,
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
            color: Colors.white,
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
