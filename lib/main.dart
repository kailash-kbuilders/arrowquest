import 'dart:async';

import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/ads_service.dart';
import 'services/progress_service.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
      };

      // Saved progress is best-effort: a storage problem must never stop the
      // app from starting.
      try {
        await ProgressService.instance.init();
      } catch (_) {
        // Fall back to in-memory defaults.
      }

      // Ads initialise after the first frame so they can never block startup.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AdsService.instance.init();
      });

      runApp(const HueRushApp());
    },
    (Object error, StackTrace stack) {
      debugPrint('Uncaught error: $error');
    },
  );
}

class HueRushApp extends StatelessWidget {
  const HueRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hue Rush',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bg,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
