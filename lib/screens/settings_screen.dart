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
            const ListTile(
              leading: Icon(Icons.block, color: AppColors.textDim),
              title: Text('Remove ads'),
              subtitle: Text('Coming with the in-app purchase.'),
              enabled: false,
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Hue Rush uses Google AdMob. During development only Google '
                'test ad units are used, and no personal data is collected by '
                'this build.',
                style: TextStyle(color: AppColors.textDim, fontSize: 12, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
