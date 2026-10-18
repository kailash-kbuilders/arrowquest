import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/ads_service.dart';
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

/// The play screen: hearts, board, and the hint / undo / zoom controls.
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
  bool _zoomed = false;
  bool _adBusy = false;

  /// Hints revealed on *this* level, which is what the star rule looks at.
  int _hintsThisLevel = 0;

  DateTime _started = DateTime.now();
  int _elapsed = 0;
  Timer? _ticker;
  Timer? _hintTimer;

  bool get _timed => SettingsService.instance.challengeMode;
  ProgressService get _progress => ProgressService.instance;

  /// Transparent star rule: 1 star for clearing the level, +1 for at most two
  /// refused attempts, +1 for never using a hint. Time is never penalised.
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
      duration: const Duration(milliseconds: 420),
    );
    _ctrl.addListener(_onTick);
    _ctrl.addStatusListener(_onStatus);
    _progress.setCurrentLevel(widget.level.id);
    if (_timed) {
      _started = DateTime.now();
      _ticker = Timer.periodic(const Duration(seconds: 1), (Timer _) {
        if (mounted) {
          setState(
            () => _elapsed = DateTime.now().difference(_started).inSeconds,
          );
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

    if (outcome.result == MoveResult.failed) {
      AudioService.instance.blocked();
      setState(() {});
      _showOutOfHearts();
      return;
    }

    if (outcome.result == MoveResult.blocked) {
      AudioService.instance.blocked();
      setState(() {});
      if (SettingsService.instance.reducedMotion) return;
      _busy = true;
      _blocked = outcome.arrow;
      _blockedT = 0;
      _ctrl.duration = const Duration(milliseconds: 220);
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
    _ctrl.duration = const Duration(milliseconds: 460);
    _ctrl.forward(from: 0);
  }

  void _showOutOfHearts() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Out of hearts'),
        content: const Text(
          'Three arrows got in the way, so this level starts again from the '
          'top.',
          style: TextStyle(height: 1.5),
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _restart();
            },
            child: const Text('Restart level'),
          ),
        ],
      ),
    );
  }

  void _undo() {
    if (_busy) return;
    if (!_engine.undo()) return;
    AudioService.instance.tap();
    setState(() => _hintHead = null);
  }

  void _restart() {
    if (_busy) return;
    AudioService.instance.tap();
    setState(() {
      _engine.restart();
      _hintHead = null;
      _hintsThisLevel = 0;
      _elapsed = 0;
      _started = DateTime.now();
    });
  }

  Future<void> _hint() async {
    if (_busy || _engine.isOver) return;

    if (_progress.hintsAvailable <= 0) {
      await _offerRewardedHint();
      return;
    }
    await _progress.useHint();
    _revealHint();
  }

  void _revealHint() {
    final Cell? cell = _engine.hint();
    if (cell == null) {
      _toast('No arrow can escape right now — try Restart.');
      return;
    }
    AudioService.instance.tap();
    setState(() {
      _hintHead = cell;
      _hintsThisLevel++;
    });
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _hintHead = null);
    });
  }

  Future<void> _offerRewardedHint() async {
    if (_adBusy) return;
    if (!AdsService.instance.ready) {
      _toast('Hints are empty — you get more by watching a short ad.');
      return;
    }
    final bool? watch = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Hints are empty'),
        content: const Text(
          'Watch a short video to earn one hint?',
          style: TextStyle(height: 1.5),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Watch ad'),
          ),
        ],
      ),
    );
    if (watch != true || !mounted) return;

    setState(() => _adBusy = true);
    final bool earned = await AdsService.instance.showRewarded();
    if (!mounted) return;
    setState(() => _adBusy = false);
    if (!earned) {
      _toast('No reward this time — try again.');
      return;
    }
    await _progress.grantHint();
    await _progress.useHint();
    if (!mounted) return;
    _revealHint();
  }

  Future<void> _finish() async {
    if (_resultShown) return;
    _resultShown = true;
    AudioService.instance.win();
    _ticker?.cancel();

    final int seconds =
        _timed ? DateTime.now().difference(_started).inSeconds : 0;
    final int stars = starsFor(
      mistakes: _engine.mistakes,
      hintsUsed: _hintsThisLevel,
    );

    await _progress.completeLevel(
      id: widget.level.id,
      stars: stars,
      moves: _engine.moves,
      seconds: seconds,
      hintsUsed: 0,
      mistakes: _engine.mistakes,
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
        content: Text(message),
        duration: const Duration(milliseconds: 1600),
      ),
    );
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('How to play'),
        content: const Text(
          'Every arrow is a little path with a head. Tap an arrow to send it '
          'along its own path and off the board.\n\n'
          'It only leaves if the straight run from its head to the edge is '
          'clear. If another arrow is in the way the move is refused and you '
          'lose a heart — lose all three and the level restarts.\n\n'
          'Clear every arrow to finish.',
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
    final Size screen = MediaQuery.sizeOf(context);
    final bool compact = screen.height < 720;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _timed ? 'Timer · $_time' : 'Difficulty · ${level.difficulty.label}',
        ),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Level ${level.id}',
                          style: TextStyle(
                            color: palette.text,
                            fontSize: compact ? 21 : 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          level.difficulty.label,
                          style: TextStyle(
                            color: palette.textDim,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Hearts(hearts: _engine.hearts, palette: palette),
                ],
              ),
              SizedBox(height: compact ? 4 : 10),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    // Keeps the board a sensible size on tablets and in
                    // landscape instead of stretching it across the screen.
                    constraints: const BoxConstraints(maxWidth: 560),
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
                      zoomable: _zoomed,
                    ),
                  ),
                ),
              ),
              SizedBox(height: compact ? 8 : 14),
              ActionBar(
                canUndo: _engine.canUndo && !_busy,
                canHint: !_busy && !_engine.isOver && !_adBusy,
                hintCount: _progress.hintsAvailable,
                zoomed: _zoomed,
                onUndo: _undo,
                onHint: _hint,
                onToggleZoom: () {
                  AudioService.instance.tap();
                  setState(() => _zoomed = !_zoomed);
                },
              ),
              const SizedBox(height: 10),
              Text(
                '${_engine.arrowsLeft} arrows remaining',
                style: TextStyle(color: palette.textDim, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hearts extends StatelessWidget {
  const _Hearts({required this.hearts, required this.palette});

  final int hearts;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (int i = 0; i < ArrowQuestEngine.maxHearts; i++)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              i < hearts ? Icons.favorite : Icons.favorite_border,
              color: i < hearts ? palette.error : palette.textDim,
              size: 26,
            ),
          ),
      ],
    );
  }
}
