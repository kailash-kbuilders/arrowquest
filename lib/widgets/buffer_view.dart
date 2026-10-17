import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/emitter.dart';
import '../theme/app_colors.dart';

/// The five park slots. A full buffer ends the level, so this is the pressure
/// gauge the player watches.
class BufferView extends StatelessWidget {
  const BufferView({super.key, required this.engine});

  final GameEngine engine;

  @override
  Widget build(BuildContext context) {
    final slots = engine.buffer;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(right: 10),
          child: Text(
            'BUFFER',
            style: TextStyle(
              color: AppColors.textDim,
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        for (var i = 0; i < slots.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _Slot(emitter: slots[i]),
          ),
      ],
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.emitter});

  final Emitter? emitter;

  @override
  Widget build(BuildContext context) {
    final e = emitter;
    if (e == null) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.panelHi, width: 2),
        ),
      );
    }

    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.forKey(e.color),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.black.withAlpha(50)),
      ),
      child: Text(
        '${e.ammo}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
