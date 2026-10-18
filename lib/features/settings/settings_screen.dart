import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/audio_service.dart';
import '../../core/storage/progress_service.dart';
import '../../core/storage/settings_service.dart';
import '../../core/theme/app_theme.dart';

/// Functional settings: audio, haptics, motion, theme, progress reset and about.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings = SettingsService.instance;
  final ProgressService _progress = ProgressService.instance;

  Future<void> _confirmReset() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Reset progress?'),
        content: const Text(
          'This clears every level unlock, star and statistic. It cannot be '
          'undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _progress.resetProgress();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Progress reset.')),
    );
  }

  void _showAbout() {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('${AppConstants.appName} ${AppConstants.version}'),
        content: Text(
          '${AppConstants.appName}: ${AppConstants.tagline}.\n\n'
          'A relaxed logic puzzle with ${AppConstants.totalLevels} levels. '
          'Progress is stored on your device only — nothing is uploaded '
          'anywhere, and the game is fully playable offline.',
          style: const TextStyle(height: 1.5),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final int done = _progress.levelsCompleted;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: <Widget>[
            const _SectionHeader('Audio'),
            SwitchListTile(
              title: const Text('Sound'),
              value: _settings.soundOn,
              onChanged: (bool v) async {
                await _settings.setSound(v);
                if (v) AudioService.instance.tap();
                if (mounted) setState(() {});
              },
            ),
            SwitchListTile(
              title: const Text('Music'),
              value: _settings.musicOn,
              onChanged: (bool v) async {
                await _settings.setMusic(v);
                if (mounted) setState(() {});
              },
            ),
            SwitchListTile(
              title: const Text('Vibration'),
              value: _settings.vibrationOn,
              onChanged: (bool v) async {
                await _settings.setVibration(v);
                if (mounted) setState(() {});
              },
            ),
            const _SectionHeader('Play'),
            SwitchListTile(
              title: const Text('Reduced motion'),
              subtitle: const Text('Shorten arrow animations'),
              value: _settings.reducedMotion,
              onChanged: (bool v) async {
                await _settings.setReducedMotion(v);
                if (mounted) setState(() {});
              },
            ),
            SwitchListTile(
              title: const Text('Challenge mode (timer)'),
              subtitle:
                  const Text('Off by default — the relaxed mode has no clock'),
              value: _settings.challengeMode,
              onChanged: (bool v) async {
                await _settings.setChallengeMode(v);
                if (mounted) setState(() {});
              },
            ),
            const _SectionHeader('Appearance'),
            SwitchListTile(
              title: const Text('Dark theme'),
              value: _settings.darkTheme,
              onChanged: (bool v) async {
                await _settings.setDarkTheme(v);
                if (mounted) setState(() {});
              },
            ),
            const _SectionHeader('Progress'),
            ListTile(
              leading:
                  Icon(Icons.emoji_events_outlined, color: palette.dirLeft),
              title: const Text('Levels cleared'),
              subtitle: Text('$done of ${AppConstants.totalLevels}'),
            ),
            ListTile(
              leading: Icon(Icons.restart_alt, color: palette.error),
              title: const Text('Reset progress'),
              subtitle: const Text('Clears unlocks, stars and statistics'),
              onTap: _confirmReset,
            ),
            const _SectionHeader('About'),
            ListTile(
              leading: Icon(Icons.info_outline, color: palette.primary),
              title: Text('${AppConstants.appName} ${AppConstants.version}'),
              onTap: _showAbout,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                'Offline puzzle game. No account, no ads, no network needed.',
                style: TextStyle(
                    color: palette.textDim, fontSize: 12, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: palette.textDim,
          fontSize: 11,
          letterSpacing: 2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
