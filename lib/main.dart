import 'dart:async';

import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
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

      runApp(const QuiverApp());
    },
    (Object error, StackTrace stack) {
      debugPrint('Uncaught error: $error');
    },
  );
}

class QuiverApp extends StatelessWidget {
  const QuiverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiver',
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
