import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/audio_service.dart';
import '../../core/storage/progress_service.dart';
import '../../core/storage/settings_service.dart';
import '../../core/theme/app_theme.dart';
import '../data/models/arrow.dart';
import '../data/models/level.dart';
import '../levels/level_complete_screen.dart';
import '../settings/settings_screen.dart';
import 'logic/engine.dart';
import 'widgets/action_bar.dart';
import 'widgets/board_view.dart';

/// The play screen: board, counters and the Undo / Restart / Hint controls.
class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key, required this.level});

  final Level level;

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen>
    with SingleTickerProviderStateMixin {
  late final ArrowQuestEngine _engine;
  late final AnimationController _ctrl;

  Arrow? _ghost;
  double _ghostT = 0;
  Arrow? _blocked;
  double _blockedT = 0;
  Cell? _hintHead;

  bool _busy = false;
  bool _resultShown = false;
  int _hintsUsed = 0;
  int _mistakes = 0;

  DateTime _started = DateTime.now();
  int _elapsed = 0;
  Timer? _ticker;
  Timer? _hintTimer;

  bool get _timed => SettingsService.instance.challengeMode;

  /// Transparent star rule: 1 star for clearing the level, +1 for at most two
  /// rejected attempts, +1 for never using a hint. Time is never penalised.
  static int starsFor({required int mistakes, required int hintsUsed}) {
    var stars = 1;
    if (mistakes <= 2) stars++;
    if (hintsUsed == 0) stars++;
    return stars;
  }

  @override
  void initState() {
    super.initState();
    _engine = ArrowQuestEngine(widget.level);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _ctrl.addListener(_onTick);
    _ctrl.addStatusListener(_onStatus);
    if (_timed) {
      _started = DateTime.now();
      _ticker = Timer.periodic(const Duration(seconds: 1), (Timer _) {
        if (mounted) {
          setState(
              () => _elapsed = DateTime.now().difference(_started).inSeconds);
        }
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _hintTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  // ---- Animation plumbing ------------------------------------------------

  void _onTick() {
    if (!mounted) return;
    setState(() {
      if (_ghost != null) _ghostT = _ctrl.value;
      if (_blocked != null) _blockedT = _ctrl.value;
    });
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (_ghost != null) {
      setState(() {
        _ghost = null;
        _ghostT = 0;
        _busy = false;
      });
      if (_engine.isOver) _finish();
      return;
    }
    if (_blocked != null) {
      setState(() {
        _blocked = null;
        _blockedT = 0;
        _busy = false;
      });
    }
  }

  // ---- Interaction -------------------------------------------------------

  void _onTapCell(int r, int c) {
    if (_busy || _engine.isOver) return;
    final MoveOutcome outcome = _engine.tap(r, c);

    if (outcome.result == MoveResult.ignored) return;

    if (outcome.result == MoveResult.blocked) {
      AudioService.instance.blocked();
      setState(() => _mistakes = _engine.mistakes);
      if (SettingsService.instance.reducedMotion) return;
      _busy = true;
      _blocked = outcome.arrow;
      _blockedT = 0;
      _ctrl.duration = const Duration(milliseconds: 180);
      _ctrl.forward(from: 0);
      return;
    }

    // Escaped.
    AudioService.instance.escape();
    setState(() {});
    if (SettingsService.instance.reducedMotion) {
      if (_engine.isOver) _finish();
      return;
    }
    _busy = true;
    _ghost = outcome.arrow;
    _ghostT = 0;
    _ctrl.duration = const Duration(milliseconds: 340);
    _ctrl.forward(from: 0);
  }

  void _undo() {
    if (_busy) return;
    if (!_engine.undo()) return;
    AudioService.instance.tap();
    setState(() {
      _hintHead = null;
      _mistakes = _engine.mistakes;
    });
  }

  void _restart() {
    if (_busy) return;
    AudioService.instance.tap();
    setState(() {
      _engine.restart();
      _hintHead = null;
      _hintsUsed = 0;
      _mistakes = 0;
      _elapsed = 0;
      _started = DateTime.now();
    });
  }

  void _hint() {
    if (_busy || _engine.isOver) return;
    final Cell? cell = _engine.hint();
    if (cell == null) {
      _toast('No arrow can escape right now — try Restart.');
      return;
    }
    AudioService.instance.tap();
    ProgressService.instance.recordHint();
    setState(() {
      _hintHead = cell;
      _hintsUsed++;
    });
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _hintHead = null);
    });
  }

  Future<void> _finish() async {
    if (_resultShown) return;
    _resultShown = true;
    AudioService.instance.win();
    _ticker?.cancel();

    final int seconds =
        _timed ? DateTime.now().difference(_started).inSeconds : 0;
    final int stars = starsFor(mistakes: _mistakes, hintsUsed: _hintsUsed);

    await ProgressService.instance.completeLevel(
      id: widget.level.id,
      stars: stars,
      moves: _engine.moves,
      seconds: seconds,
      hintsUsed: _hintsUsed,
      mistakes: _mistakes,
      arrowsCleared: widget.level.arrows.length,
    );
    if (!mounted) return;

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => LevelCompleteScreen(
          level: widget.level,
          moves: _engine.moves,
          seconds: seconds,
          stars: stars,
          arrowsCleared: widget.level.arrows.length,
          timed: _timed,
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message), duration: const Duration(milliseconds: 1400)),
    );
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('How to play'),
        content: const Text(
          'Tap an arrow to send it out in the direction it points.\n\n'
          'If the path from its head to the edge is clear, the whole arrow '
          'escapes. If another arrow is in the way, the move is refused and '
          'the arrow stays put.\n\n'
          'Clear every arrow to finish the level.',
          style: TextStyle(height: 1.5),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  String get _time {
    final int m = _elapsed ~/ 60;
    final int s = _elapsed % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Level level = widget.level;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Level ${level.id}'),
        actions: <Widget>[
          IconButton(
            tooltip: 'How to play',
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
          ),
          IconButton(
            tooltip: 'Restart',
            icon: const Icon(Icons.refresh),
            onPressed: _restart,
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  _Stat(
                    label: 'CLEARED',
                    value: '${_engine.cleared}/${_engine.totalArrows}',
                  ),
                  _Stat(label: 'MOVES', value: '${_engine.moves}'),
                  if (_timed) _Stat(label: 'TIME', value: _time),
                  _Stat(label: 'HINTS', value: '$_hintsUsed'),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                level.chapter.toUpperCase(),
                style: TextStyle(
                  color: palette.textDim,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: BoardView(
                  rows: _engine.rows,
                  cols: _engine.cols,
                  arrows: _engine.arrows,
                  onTapCell: _onTapCell,
                  ghost: _ghost,
                  ghostT: _ghostT,
                  blockedArrow: _blocked,
                  blockedT: _blockedT,
                  hintHead: _hintHead,
                  hintT: 0.5,
                  zoomable: _engine.rows > 8 || _engine.cols > 8,
                ),
              ),
              const SizedBox(height: 12),
              ActionBar(
                canUndo: _engine.canUndo && !_busy,
                canHint: !_busy && !_engine.isOver,
                onUndo: _undo,
                onRestart: _restart,
                onHint: _hint,
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
    final AppPalette palette = AppPalette.of(context);
    return Column(
      children: <Widget>[
        Text(
          value,
          style: TextStyle(
            color: palette.text,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: palette.textDim,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
