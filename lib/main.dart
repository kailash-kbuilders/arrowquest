import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/ads_service.dart';
import 'services/progress_service.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProgressService.instance.init();
  // Ad initialisation is fire-and-forget: a slow or unavailable ad SDK must
  // never block the first frame.
  AdsService.instance.init();
  runApp(const HueRushApp());
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
