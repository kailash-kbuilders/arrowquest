import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Thin wrapper around Google Mobile Ads.
///
/// Every call is defensive: if the SDK is not ready, or an ad is not loaded,
/// the game keeps working and the caller simply gets `false` back. Only Google
/// **test** ad unit IDs are used here — swap them for the real IDs at release.
class AdsService {
  AdsService._();

  static final AdsService instance = AdsService._();

  // Google's official Android test units.
  static const String _androidBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String _androidInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _androidRewarded = 'ca-app-pub-3940256099942544/5224354917';

  // Google's official iOS test units.
  static const String _iosBanner = 'ca-app-pub-3940256099942544/2934735716';
  static const String _iosInterstitial =
      'ca-app-pub-3940256099942544/4411468910';
  static const String _iosRewarded = 'ca-app-pub-3940256099942544/1712485313';

  static const int _maxLoadAttempts = 3;

  bool _ready = false;
  bool get ready => _ready;

  RewardedAd? _rewarded;
  InterstitialAd? _interstitial;
  int _rewardedAttempts = 0;
  int _interstitialAttempts = 0;
  int _levelsSinceInterstitial = 0;

  bool get _isIOS => !kIsWeb && Platform.isIOS;

  String get _bannerUnit => _isIOS ? _iosBanner : _androidBanner;
  String get _interstitialUnit => _isIOS ? _iosInterstitial : _androidInterstitial;
  String get _rewardedUnit => _isIOS ? _iosRewarded : _androidRewarded;

  Future<void> init() async {
    if (kIsWeb) return;
    try {
      await MobileAds.instance.initialize();
      _ready = true;
      _loadRewarded();
      _loadInterstitial();
    } catch (_) {
      _ready = false;
    }
  }

  // ---- Rewarded ----------------------------------------------------------

  void _loadRewarded() {
    if (!_ready) return;
    RewardedAd.load(
      adUnitId: _rewardedUnit,
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewarded = ad;
          _rewardedAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewarded = null;
          _rewardedAttempts++;
          if (_rewardedAttempts < _maxLoadAttempts) _loadRewarded();
        },
      ),
    );
  }

  /// Shows a rewarded ad. Returns true only if the user earned the reward.
  Future<bool> showRewarded() async {
    if (!_ready) return false;
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }

    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd a) {
        a.dispose();
        _rewarded = null;
        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd a, AdError error) {
        a.dispose();
        _rewarded = null;
        _loadRewarded();
      },
    );

    await ad.show(
      onUserEarnedReward: (AdWithoutView a, RewardItem reward) {
        earned = true;
      },
    );
    return earned;
  }

  // ---- Interstitial ------------------------------------------------------

  void _loadInterstitial() {
    if (!_ready) return;
    InterstitialAd.load(
      adUnitId: _interstitialUnit,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitial = ad;
          _interstitialAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitial = null;
          _interstitialAttempts++;
          if (_interstitialAttempts < _maxLoadAttempts) _loadInterstitial();
        },
      ),
    );
  }

  /// Called after a level is won. Shows an interstitial on every 2nd clear,
  /// honouring a simple frequency cap.
  Future<void> maybeShowInterstitial() async {
    if (!_ready) return;
    _levelsSinceInterstitial++;
    if (_levelsSinceInterstitial < 2) return;
    _levelsSinceInterstitial = 0;

    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd a) {
        a.dispose();
        _interstitial = null;
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd a, AdError error) {
        a.dispose();
        _interstitial = null;
        _loadInterstitial();
      },
    );
    await ad.show();
    _interstitial = null;
  }

  // ---- Banner ------------------------------------------------------------

  BannerAd createBanner() {
    final ad = BannerAd(
      size: AdSize.banner,
      adUnitId: _bannerUnit,
      request: AdRequest(),
      listener: BannerAdListener(),
    );
    ad.load();
    return ad;
  }
}
