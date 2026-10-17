import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/emitter.dart';
import '../theme/app_colors.dart';

/// The rail: the ordered queue of emitters. The leftmost chip is the one the
/// player acts on.
class RailView extends StatelessWidget {
  const RailView({super.key, required this.engine});

  final GameEngine engine;

  @override
  Widget build(BuildContext context) {
    final rail = engine.rail;
    if (rail.isEmpty) {
      return const SizedBox(
        height: 64,
        child: Center(
          child: Text('Rail empty', style: TextStyle(color: AppColors.textDim)),
        ),
      );
    }

    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: rail.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          return EmitterChip(emitter: rail[index], isFront: index == 0);
        },
      ),
    );
  }
}

class EmitterChip extends StatelessWidget {
  const EmitterChip({super.key, required this.emitter, this.isFront = false});

  final Emitter emitter;
  final bool isFront;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forKey(emitter.color);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: isFront ? 68 : 52,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: isFront
            ? Border.all(color: Colors.white, width: 3)
            : Border.all(color: Colors.black.withAlpha(40)),
        boxShadow: isFront
            ? <BoxShadow>[
                BoxShadow(color: color.withAlpha(150), blurRadius: 14, spreadRadius: 1),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            '${emitter.ammo}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const Text(
            'AMMO',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 8,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
