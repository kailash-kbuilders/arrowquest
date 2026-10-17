import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Rewarded-ad boosters. Each button is expected to show a rewarded ad before
/// granting its effect — the wiring lives in the gameplay screen.
class BoosterBar extends StatelessWidget {
  const BoosterBar({
    super.key,
    required this.onHint,
    required this.onExtraSlot,
    required this.onExtraSwitch,
  });

  final VoidCallback onHint;
  final VoidCallback onExtraSlot;
  final VoidCallback onExtraSwitch;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        _Booster(icon: Icons.lightbulb_outline, label: 'Hint', onTap: onHint),
        _Booster(icon: Icons.add_box_outlined, label: '+Slot', onTap: onExtraSlot),
        _Booster(icon: Icons.add_circle_outline, label: '+Switch', onTap: onExtraSwitch),
      ],
    );
  }
}

class _Booster extends StatelessWidget {
  const _Booster({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: AppColors.accentSoft, size: 22),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.play_circle_fill, color: AppColors.accentSoft, size: 11),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: const TextStyle(color: AppColors.textDim, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
