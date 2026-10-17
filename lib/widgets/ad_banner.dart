import 'package:flutter/material.dart';

/// Placeholder for the anchored banner.
///
/// Renders nothing while ads are disabled. The layout seam is kept so a real
/// banner can drop straight back in when the AdMob dependency returns.
class AdBanner extends StatelessWidget {
  const AdBanner({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
