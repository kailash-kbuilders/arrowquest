import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/services/ads_service.dart';
import 'core/services/audio_service.dart';
import 'core/storage/progress_service.dart';
import 'core/storage/settings_service.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
      };

      // Storage is best-effort: a corrupt or unavailable save must never stop
      // the game from starting. Both services fall back to in-memory defaults.
      try {
        await SettingsService.instance.init();
      } catch (_) {
        // Ignore — defaults are already in place.
      }
      try {
        await ProgressService.instance.init();
      } catch (_) {
        // Ignore — defaults are already in place.
      }

      runApp(const ArrowQuestApp());

      // Ads are optional and must never delay or break startup, so the SDK is
      // initialised after the first frame — and every call is defensive.
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        AdsService.instance.initialize();
        AudioService.instance.initialize();
      });
    },
    (Object error, StackTrace stack) {
      debugPrint('Uncaught error: $error');
    },
  );
}
