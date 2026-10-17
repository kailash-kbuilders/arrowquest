import 'package:flutter/material.dart';

import '../services/progress_service.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ProgressService _progress = ProgressService.instance;

  @override
  Widget build(BuildContext context) {
    final done = _progress.completed.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          children: <Widget>[
            SwitchListTile(
              title: const Text('Sound'),
              value: _progress.soundOn,
              onChanged: (value) async {
                await _progress.setSound(value);
                if (mounted) setState(() {});
              },
            ),
            SwitchListTile(
              title: const Text('Haptics'),
              value: _progress.hapticsOn,
              onChanged: (value) async {
                await _progress.setHaptics(value);
                if (mounted) setState(() {});
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.emoji_events_outlined,
                  color: AppColors.accent),
              title: const Text('Levels cleared'),
              subtitle: Text('$done of 100'),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Quiver is a puzzle game. Progress is stored on your device '
                'only — nothing is uploaded anywhere.',
                style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
