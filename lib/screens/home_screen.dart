import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'level_map_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFF141A2E), AppColors.bg],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: <Widget>[
                const Spacer(flex: 2),
                Image.asset(
                  'assets/branding/logo.png',
                  height: 150,
                  filterQuality: FilterQuality.high,
                ),
                const SizedBox(height: 10),
                const Text(
                  'QUIVER',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 8,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tap an arrow and it slides out —\nunless something is in the way.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textDim,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LevelMapScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'PLAY',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showHowToPlay(context),
                        icon: const Icon(Icons.help_outline, size: 18),
                        label: const Text('How to play'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                      child: const Icon(Icons.settings_outlined, size: 20),
                    ),
                  ],
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHowToPlay(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('How to play'),
        content: const Text(
          'Tap an arrow and it shoots in the direction it points.\n\n'
          'It keeps going until it reaches the edge — then it leaves the '
          'board — or until another arrow is in the way, in which case it '
          'stops right there.\n\n'
          'An arrow with something directly in front of it cannot move at '
          'all. Clear the board to finish the level.',
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
}
