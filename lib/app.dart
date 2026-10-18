import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/storage/settings_service.dart';
import 'core/theme/app_theme.dart';
import 'features/home/splash_screen.dart';

/// Root widget. Rebuilds when the theme preference changes.
class ArrowQuestApp extends StatelessWidget {
  const ArrowQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SettingsService.instance,
      builder: (BuildContext context, Widget? _) {
        final bool dark = SettingsService.instance.darkTheme;
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
        );
      },
    );
  }
}
