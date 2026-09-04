import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'admob_config.dart';

final admobServiceProvider = Provider<AdMobService>((ref) {
  return AdMobService();
});

/// Service responsible for initializing, preloading, and showing Google AdMob
/// Rewarded Video Ads on mobile platforms, with automatic background replenishment
/// and zero-crash fallback handling.
class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;
  bool _isInitialized = false;

  bool get isReady => _rewardedAd != null;

  /// Initializes the Google Mobile Ads SDK on supported mobile platforms with UMP GDPR consent.
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (!AdMobConfig.isPlatformSupported) {
      debugPrint('[AdMobService] Platform not supported for native AdMob (Web/Desktop). Using fallback.');
      return;
    }

    try {
      // UMP Consent flow for European Regulations (GDPR)
      final params = ConsentRequestParameters();
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          ConsentForm.loadAndShowConsentFormIfRequired((FormError? formError) async {
            if (formError != null) {
              debugPrint('[AdMobService] UMP ConsentForm error: ${formError.message}');
            }
            final canRequest = await ConsentInformation.instance.canRequestAds();
            if (canRequest) {
              await _initMobileAds();
            } else {
              debugPrint('[AdMobService] Ads cannot be requested per current UMP consent state.');
            }
          });
        },
        (FormError formError) async {
          debugPrint('[AdMobService] ConsentInfoUpdate failed: ${formError.message}. Proceeding with standard init.');
          await _initMobileAds();
        },
      );
    } catch (e) {
      debugPrint('[AdMobService] Error setting up UMP consent: $e. Proceeding with standard init.');
      await _initMobileAds();
    }
  }

  Future<void> _initMobileAds() async {
    if (_isInitialized) return;
    try {
      if (AdMobConfig.testDeviceIds.isNotEmpty) {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(testDeviceIds: AdMobConfig.testDeviceIds),
        );
      }
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('[AdMobService] MobileAds SDK initialized successfully.');
      preloadRewardedAd();
    } catch (e) {
      debugPrint('[AdMobService] MobileAds initialization failed: $e');
    }
  }

  /// Displays the UMP Privacy Options form so users can review/update consent at any time.
  Future<void> showPrivacyOptionsForm({void Function(FormError? error)? onDismissed}) async {
    if (!AdMobConfig.isPlatformSupported) return;
    try {
      await ConsentForm.showPrivacyOptionsForm((FormError? formError) {
        if (formError != null) {
          debugPrint('[AdMobService] Error showing privacy options: ${formError.message}');
        }
        onDismissed?.call(formError);
      });
    } catch (e) {
      debugPrint('[AdMobService] showPrivacyOptionsForm failed: $e');
    }
  }

  /// Checks if privacy options button is required for current user jurisdiction.
  Future<bool> isPrivacyOptionsRequired() async {
    if (!AdMobConfig.isPlatformSupported) return false;
    try {
      final status = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      return false;
    }
  }

  /// Preloads a rewarded ad in the background so it is instantly ready when the user initiates a scan.
  void preloadRewardedAd() {
    if (!AdMobConfig.isPlatformSupported || _isAdLoading || _rewardedAd != null) {
      return;
    }

    final adUnitId = AdMobConfig.rewardedAdUnitId;
    if (adUnitId.isEmpty) return;

    _isAdLoading = true;
    debugPrint('[AdMobService] Preloading RewardedAd with ID: $adUnitId');

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          debugPrint('[AdMobService] RewardedAd loaded successfully.');
          _rewardedAd = ad;
          _isAdLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('[AdMobService] RewardedAd failed to load: code=${error.code}, message=${error.message}');
          _rewardedAd = null;
          _isAdLoading = false;
        },
      ),
    );
  }

  /// Displays the preloaded Google AdMob Rewarded Video ad.
  /// Returns `true` if AdMob ad was launched.
  /// Returns `false` if AdMob is unavailable (Web, not preloaded, offline, etc.),
  /// allowing the UI to fallback gracefully to the internal sponsor video sheet.
  Future<bool> showRewardedAd({
    required VoidCallback onRewardEarned,
    required VoidCallback onAdDismissed,
  }) async {
    if (!AdMobConfig.isPlatformSupported || _rewardedAd == null) {
      debugPrint('[AdMobService] Native AdMob ad not available. Invoking fallback player.');
      // Try reloading for next time
      preloadRewardedAd();
      return false;
    }

    final ad = _rewardedAd!;
    _rewardedAd = null; // Consume the ad

    bool userEarnedReward = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        debugPrint('[AdMobService] RewardedAd showed full screen content.');
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        debugPrint('[AdMobService] RewardedAd dismissed full screen content. Reward earned: $userEarnedReward');
        ad.dispose();
        // Immediately replenish the inventory
        preloadRewardedAd();

        if (userEarnedReward) {
          onRewardEarned();
        } else {
          onAdDismissed();
        }
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        debugPrint('[AdMobService] RewardedAd failed to show: $error');
        ad.dispose();
        preloadRewardedAd();
        onAdDismissed();
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          debugPrint('[AdMobService] User earned reward from AdMob: ${reward.amount} ${reward.type}');
          userEarnedReward = true;
        },
      );
      return true;
    } catch (e) {
      debugPrint('[AdMobService] Exception while showing RewardedAd: $e');
      preloadRewardedAd();
      return false;
    }
  }
}
