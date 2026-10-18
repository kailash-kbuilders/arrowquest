import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import 'home_screen.dart';

/// Brand splash. A short visual transition only — there is no artificial
/// loading delay and nothing heavy is loaded here.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    _timer = Timer(const Duration(milliseconds: 1150), _goHome);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[palette.panel, palette.bg],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Image.asset(
                    AppConstants.logoAsset,
                    height: 140,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.explore,
                      size: 110,
                      color: palette.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.appName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 7,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppConstants.tagline,
                    style: TextStyle(
                      color: palette.textDim,
                      fontSize: 12,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 34),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.keyboard_arrow_up,
                          color: palette.dirUp, size: 26),
                      Icon(Icons.keyboard_arrow_down,
                          color: palette.dirDown, size: 26),
                      Icon(Icons.keyboard_arrow_left,
                          color: palette.dirLeft, size: 26),
                      Icon(Icons.keyboard_arrow_right,
                          color: palette.dirRight, size: 26),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
