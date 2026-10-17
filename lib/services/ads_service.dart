/// Ads are temporarily disabled.
///
/// The AdMob SDK was the only unusual native dependency in the app, and the
/// prime suspect for a launch crash on a real device. It is removed for now so
/// the game starts reliably. The class keeps exactly the surface the game
/// already uses, so bringing ads back is a small, contained change:
///
///   * restore the `google_mobile_ads` dependency in pubspec.yaml
///   * restore the real bodies (see git history for the previous version)
///   * the "Configure AdMob" workflow step is still in place
///
/// While [ready] is false the boosters grant their effect directly, so the
/// whole game remains playable without ads.
class AdsService {
  AdsService._();

  static final AdsService instance = AdsService._();

  /// False while ads are disabled. Callers use this to skip the reward gate.
  bool get ready => false;

  Future<void> init() async {}

  /// Returns whether the user earned the reward. Without ads there is nothing
  /// to watch, so the caller grants the effect itself.
  Future<bool> showRewarded() async => false;

  Future<void> maybeShowInterstitial() async {}
}
