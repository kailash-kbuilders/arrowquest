import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Round icon button used across the play screen.
class CircleActionButton extends StatelessWidget {
  const CircleActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.badge,
    this.tooltip,
    this.highlighted = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? badge;
  final String? tooltip;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool enabled = onPressed != null;
    final Widget button = Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: highlighted ? palette.primary : palette.panelHi,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 54,
            height: 54,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Icon(
                  icon,
                  size: 24,
                  color: highlighted ? Colors.white : palette.text,
                ),
                if (badge != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: palette.dirLeft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// Hint / Undo / Zoom controls beneath the board.
class ActionBar extends StatelessWidget {
  const ActionBar({
    super.key,
    required this.canUndo,
    required this.canHint,
    required this.hintCount,
    required this.zoomed,
    required this.onUndo,
    required this.onHint,
    required this.onToggleZoom,
  });

  final bool canUndo;
  final bool canHint;
  final int hintCount;
  final bool zoomed;
  final VoidCallback onUndo;
  final VoidCallback onHint;
  final VoidCallback onToggleZoom;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        CircleActionButton(
          icon: Icons.lightbulb_outline,
          tooltip: 'Hint',
          onPressed: canHint ? onHint : null,
          badge: hintCount > 0 ? '$hintCount' : 'AD',
          highlighted: hintCount == 0,
        ),
        Row(
          children: <Widget>[
            CircleActionButton(
              icon: Icons.undo,
              tooltip: 'Undo',
              onPressed: canUndo ? onUndo : null,
            ),
            const SizedBox(width: 12),
            CircleActionButton(
              icon: zoomed ? Icons.zoom_out_map : Icons.zoom_in_map,
              tooltip: zoomed ? 'Fit board' : 'Zoom board',
              onPressed: onToggleZoom,
              highlighted: zoomed,
            ),
          ],
        ),
      ],
    );
  }
}
