import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob wrapper.
///
/// Everything here uses Google's **official test ad units**, so the app shows
/// demo ads and can be built and run without an AdMob account. Swapping in real
/// unit ids later is a one-line change per format.
///
/// Every call is defensive: if the ads SDK is unavailable (no network, no
/// platform support, widget tests) the game carries on untouched.
class AdsService extends ChangeNotifier {
  AdsService._();

  static final AdsService instance = AdsService._();

  // Google's official test ad units.
  static const String bannerUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String rewardedUnitId = 'ca-app-pub-3940256099942544/5224354917';

  /// Must match the `com.google.android.gms.ads.APPLICATION_ID` meta-data that
  /// the build workflow writes into AndroidManifest.xml.
  static const String testAppId = 'ca-app-pub-3940256099942544~3347511713';

  static const Duration _rewardTimeout = Duration(minutes: 3);

  bool _ready = false;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;

  bool get ready => _ready;

  Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      _ready = true;
    } catch (_) {
      _ready = false;
      return;
    }
    notifyListeners();
    _loadInterstitial();
    _loadRewarded();
  }

  // ---- Interstitial ------------------------------------------------------

  void _loadInterstitial() {
    if (!_ready) return;
    try {
      InterstitialAd.load(
        adUnitId: interstitialUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) => _interstitial = ad,
          onAdFailedToLoad: (LoadAdError error) => _interstitial = null,
        ),
      );
    } catch (_) {
      _interstitial = null;
    }
  }

  /// Shows an interstitial if one is ready. Never blocks the caller.
  void showInterstitial() {
    if (!_ready) return;
    final InterstitialAd? ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    try {
      ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
        onAdDismissedFullScreenContent: (InterstitialAd shown) {
          shown.dispose();
          _loadInterstitial();
        },
        onAdFailedToShowFullScreenContent:
            (InterstitialAd shown, AdError error) {
          shown.dispose();
          _loadInterstitial();
        },
      );
      ad.show();
    } catch (_) {
      _loadInterstitial();
    }
  }

  // ---- Rewarded ----------------------------------------------------------

  void _loadRewarded() {
    if (!_ready) return;
    try {
      RewardedAd.load(
        adUnitId: rewardedUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) => _rewarded = ad,
          onAdFailedToLoad: (LoadAdError error) => _rewarded = null,
        ),
      );
    } catch (_) {
      _rewarded = null;
    }
  }

  /// True when a rewarded ad is loaded and can be shown right now.
  bool get rewardedReady => _ready && _rewarded != null;

  /// Shows a rewarded ad and resolves to true only if the user actually earned
  /// the reward (i.e. watched it through).
  Future<bool> showRewarded() async {
    if (!_ready) return false;
    final RewardedAd? ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }
    _rewarded = null;

    var earned = false;
    final Completer<void> closed = Completer<void>();
    void finish() {
      if (!closed.isCompleted) closed.complete();
    }

    try {
      ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
        onAdDismissedFullScreenContent: (RewardedAd shown) {
          shown.dispose();
          _loadRewarded();
          finish();
        },
        onAdFailedToShowFullScreenContent: (RewardedAd shown, AdError error) {
          shown.dispose();
          _loadRewarded();
          finish();
        },
      );
      await ad.show(
        onUserEarnedReward: (AdWithoutView shown, RewardItem reward) {
          earned = true;
        },
      );
    } catch (_) {
      finish();
    }

    // Wait for the ad to actually close before reporting the outcome, with a
    // safety timeout so a stuck ad can never freeze the game.
    await closed.future.timeout(_rewardTimeout, onTimeout: () {});
    return earned;
  }
}

/// A banner that owns its own [BannerAd], so several screens can show one
/// without ever handing the same ad instance to two widgets at once.
///
/// Renders nothing until the ad is loaded — and nothing at all if the ads SDK
/// is unavailable, which keeps widget tests and offline runs clean.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    AdsService.instance.addListener(_maybeLoad);
    _maybeLoad();
  }

  @override
  void dispose() {
    AdsService.instance.removeListener(_maybeLoad);
    _ad?.dispose();
    super.dispose();
  }

  void _maybeLoad() {
    if (!mounted || _ad != null || _failed || !AdsService.instance.ready)
      return;
    try {
      final BannerAd ad = BannerAd(
        adUnitId: AdsService.bannerUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (Ad loaded) {
            if (mounted) {
              setState(() => _ad = loaded as BannerAd);
            } else {
              loaded.dispose();
            }
          },
          onAdFailedToLoad: (Ad failed, LoadAdError error) {
            failed.dispose();
            if (mounted) setState(() => _failed = true);
          },
        ),
      );
      ad.load();
    } catch (_) {
      _failed = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final BannerAd? ad = _ad;
    if (ad == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
