import 'package:flutter/material.dart';

/// Undo / Restart / Hint controls beneath the board.
class ActionBar extends StatelessWidget {
  const ActionBar({
    super.key,
    required this.canUndo,
    required this.canHint,
    required this.onUndo,
    required this.onRestart,
    required this.onHint,
  });

  final bool canUndo;
  final bool canHint;
  final VoidCallback onUndo;
  final VoidCallback onRestart;
  final VoidCallback onHint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton.icon(
            onPressed: canUndo ? onUndo : null,
            icon: const Icon(Icons.undo, size: 18),
            label: const Text('Undo'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onRestart,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Restart'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            onPressed: canHint ? onHint : null,
            icon: const Icon(Icons.lightbulb_outline, size: 18),
            label: const Text('Hint'),
          ),
        ),
      ],
    );
  }
}
