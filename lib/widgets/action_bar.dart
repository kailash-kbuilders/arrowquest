import 'package:flutter/material.dart';

import '../engine/game_engine.dart';

/// The three core actions: FIRE, PARK, SWITCH.
class ActionBar extends StatelessWidget {
  const ActionBar({
    super.key,
    required this.engine,
    required this.onFire,
    required this.onPark,
    required this.onSwitch,
  });

  final GameEngine engine;
  final VoidCallback onFire;
  final VoidCallback onPark;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    final canFire = engine.canFire;
    final canPark = engine.front != null;
    final canSwitch = engine.switchTokens > 0 && engine.rail.length > 1;

    return Row(
      children: <Widget>[
        Expanded(
          child: FilledButton.icon(
            onPressed: canFire ? onFire : null,
            icon: const Icon(Icons.bolt),
            label: const Text('FIRE'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: canPark ? onPark : null,
            icon: const Icon(Icons.arrow_downward),
            label: const Text('PARK'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: canSwitch ? onSwitch : null,
            icon: const Icon(Icons.swap_horiz),
            label: Text('SWITCH ${engine.switchTokens}'),
          ),
        ),
      ],
    );
  }
}
