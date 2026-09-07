import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'admob_config.dart';
import '../../shared/utils/app_logger.dart';

final admobServiceProvider = Provider<AdMobService>((ref) {
  return AdMobService();
});

/// Service responsible for initializing, preloading, and showing Google AdMob
/// Rewarded Video Ads and App Open Ads on mobile platforms, with automatic
/// background replenishment, deferred startup ads, and centralized logging.
class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;
  bool _isInitialized = false;

  AppOpenAd? _appOpenAd;
  bool _isAppOpenAdLoading = false;
  bool _isShowingAppOpenAd = false;
  Completer<bool>? _appOpenCompleter;
  DateTime? _appStartTime;
  bool _hasShownStartupAd = false;
  bool _pendingStartupAd = false;
  DateTime? _lastPausedTime;
  DateTime? _appOpenLoadTime;
  DateTime? _lastAppOpenShowTime;
  AppLifecycleListener? _lifecycleListener;
  bool Function()? _isPremiumChecker;

  bool get isReady => _rewardedAd != null;
  bool get isAppOpenAdAvailable =>
      _appOpenAd != null &&
      _appOpenLoadTime != null &&
      DateTime.now().difference(_appOpenLoadTime!) < const Duration(hours: 4);

  /// Initializes the Google Mobile Ads SDK on supported mobile platforms with UMP GDPR consent.
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (!AdMobConfig.isPlatformSupported) {
      AppLogger.info('ADMOB', 'Platform not supported for native AdMob (Web/Desktop).');
      return;
    }

    _appStartTime = DateTime.now();
    final completer = Completer<void>();

    try {
      // UMP Consent flow for European Regulations (GDPR)
      final params = ConsentRequestParameters();
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          ConsentForm.loadAndShowConsentFormIfRequired((FormError? formError) async {
            if (formError != null) {
              AppLogger.warning('ADMOB', 'UMP ConsentForm error: ${formError.message} (code: ${formError.errorCode})');
            }
            final canRequest = await ConsentInformation.instance.canRequestAds();
            AppLogger.info('ADMOB', 'UMP consent resolved. canRequestAds: $canRequest');
            if (canRequest) {
              await _initMobileAds();
            } else {
              AppLogger.warning('ADMOB', 'Ads cannot be requested per current UMP consent state.');
            }
            if (!completer.isCompleted) completer.complete();
          });
        },
        (FormError formError) async {
          AppLogger.warning('ADMOB', 'ConsentInfoUpdate failed: ${formError.message} (code: ${formError.errorCode}). Proceeding with standard init.');
          await _initMobileAds();
          if (!completer.isCompleted) completer.complete();
        },
      );
    } catch (e, st) {
      AppLogger.warning('ADMOB', 'Error setting up UMP consent: $e. Proceeding with standard init.', e);
      AppLogger.error('ADMOB', 'UMP consent error details', e, st);
      await _initMobileAds();
      if (!completer.isCompleted) completer.complete();
    }

    // Await up to 3 seconds for UMP & Mobile Ads to initialize so ads can start loading
    await completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        AppLogger.info('ADMOB', 'UMP consent setup still resolving in background.');
      },
    );
  }

  Future<void> _initMobileAds() async {
    if (_isInitialized) return;
    try {
      if (AdMobConfig.testDeviceIds.isNotEmpty) {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(testDeviceIds: AdMobConfig.testDeviceIds),
        );
        AppLogger.info('ADMOB', 'Configured testDeviceIds: ${AdMobConfig.testDeviceIds}');
      }
      final initStatus = await MobileAds.instance.initialize();
      _isInitialized = true;
      final adapterStatuses = initStatus.adapterStatuses.entries
          .map((e) => '${e.key}: ${e.value.state.name}')
          .join(', ');
      AppLogger.info('ADMOB', 'MobileAds SDK initialized. Adapters: [$adapterStatuses]');
      preloadRewardedAd();
      preloadAppOpenAd();
    } catch (e, st) {
      AppLogger.error('ADMOB', 'MobileAds initialization failed: $e', e, st);
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
    AppLogger.info('ADMOB', 'Preloading RewardedAd with ID: $adUnitId (testMode: ${AdMobConfig.useTestAds})');

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          AppLogger.info('ADMOB', 'RewardedAd loaded successfully.');
          _rewardedAd = ad;
          _isAdLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          AppLogger.warning('ADMOB', 'RewardedAd failed to load: code=${error.code}, message=${error.message}, domain=${error.domain}');
          _rewardedAd = null;
          _isAdLoading = false;
        },
      ),
    );
  }

  /// Displays the preloaded Google AdMob Rewarded Video ad.
  /// Returns `true` if AdMob ad was launched.
  /// Returns `false` if AdMob is unavailable (Web, not preloaded, offline, etc.).
  Future<bool> showRewardedAd({
    required VoidCallback onRewardEarned,
    required VoidCallback onAdDismissed,
  }) async {
    if (!AdMobConfig.isPlatformSupported || _rewardedAd == null) {
      AppLogger.info('ADMOB', 'Native AdMob rewarded ad not available (isPlatformSupported: ${AdMobConfig.isPlatformSupported}, isReady: ${_rewardedAd != null}).');
      // Replenish for next time
      preloadRewardedAd();
      return false;
    }

    final ad = _rewardedAd!;
    _rewardedAd = null; // Consume the ad

    bool userEarnedReward = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        AppLogger.info('ADMOB', 'RewardedAd showed full screen content.');
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        AppLogger.info('ADMOB', 'RewardedAd dismissed full screen content. Reward earned: $userEarnedReward');
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
        AppLogger.warning('ADMOB', 'RewardedAd failed to show: code=${error.code}, message=${error.message}');
        ad.dispose();
        preloadRewardedAd();
        onAdDismissed();
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          AppLogger.info('ADMOB', 'User earned reward from AdMob: ${reward.amount} ${reward.type}');
          userEarnedReward = true;
        },
      );
      return true;
    } catch (e, st) {
      AppLogger.error('ADMOB', 'Exception while showing RewardedAd: $e', e, st);
      preloadRewardedAd();
      return false;
    }
  }

  /// Preloads an App Open ad in the background.
  Future<bool> preloadAppOpenAd() {
    if (!AdMobConfig.isPlatformSupported) {
      return Future.value(false);
    }
    if (isAppOpenAdAvailable) {
      return Future.value(true);
    }
    if (_isAppOpenAdLoading && _appOpenCompleter != null) {
      return _appOpenCompleter!.future;
    }

    final adUnitId = AdMobConfig.appOpenAdUnitId;
    if (adUnitId.isEmpty) return Future.value(false);

    _isAppOpenAdLoading = true;
    _appOpenCompleter = Completer<bool>();
    AppLogger.info('ADMOB', 'Preloading AppOpenAd with ID: $adUnitId (testMode: ${AdMobConfig.useTestAds})');

    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (AppOpenAd ad) {
          AppLogger.info('ADMOB', 'AppOpenAd loaded successfully.');
          _appOpenAd = ad;
          _appOpenLoadTime = DateTime.now();
          _isAppOpenAdLoading = false;
          if (_appOpenCompleter != null && !_appOpenCompleter!.isCompleted) {
            _appOpenCompleter!.complete(true);
          }

          // If the app just launched and user wanted startup ad, show it as soon as loaded!
          if (_pendingStartupAd && !_hasShownStartupAd && !_isShowingAppOpenAd) {
            final now = DateTime.now();
            final elapsedSinceStart = _appStartTime != null
                ? now.difference(_appStartTime!).inSeconds
                : 999;
            if (elapsedSinceStart <= 45) {
              AppLogger.info('ADMOB', 'Displaying deferred startup AppOpenAd (${elapsedSinceStart}s after launch).');
              _pendingStartupAd = false;
              _hasShownStartupAd = true;
              showAppOpenAdIfAvailable();
            } else {
              _pendingStartupAd = false;
            }
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          AppLogger.warning('ADMOB', 'AppOpenAd failed to load: code=${error.code}, message=${error.message}, domain=${error.domain}');
          _appOpenAd = null;
          _isAppOpenAdLoading = false;
          if (_appOpenCompleter != null && !_appOpenCompleter!.isCompleted) {
            _appOpenCompleter!.complete(false);
          }
        },
      ),
    );

    return _appOpenCompleter!.future;
  }

  /// Displays an App Open ad on app startup.
  /// If the ad is not yet loaded, waits up to [timeout] for it to load.
  /// If [timeout] elapses, the app displays immediately and the ad will
  /// pop up automatically as soon as loading finishes.
  Future<bool> showAppOpenAdOnLaunch({
    Duration timeout = const Duration(milliseconds: 2500),
    VoidCallback? onDismissed,
  }) async {
    if (!AdMobConfig.isPlatformSupported) {
      onDismissed?.call();
      return false;
    }

    _appStartTime ??= DateTime.now();

    if (isAppOpenAdAvailable) {
      _hasShownStartupAd = true;
      _pendingStartupAd = false;
      return showAppOpenAdIfAvailable(onDismissed: onDismissed);
    }

    // Flag that we want to show a startup ad as soon as it's ready
    _pendingStartupAd = true;

    try {
      final loaded = await preloadAppOpenAd().timeout(
        timeout,
        onTimeout: () {
          AppLogger.info('ADMOB', 'Startup ad not ready within initial ${timeout.inMilliseconds}ms. Continuing app launch; ad will display as soon as ready.');
          return false;
        },
      );
      if (loaded && isAppOpenAdAvailable && _pendingStartupAd) {
        _hasShownStartupAd = true;
        _pendingStartupAd = false;
        return await showAppOpenAdIfAvailable(onDismissed: onDismissed);
      }
    } catch (e) {
      AppLogger.warning('ADMOB', 'Error in showAppOpenAdOnLaunch: $e');
    }

    onDismissed?.call();
    return false;
  }

  /// Displays the preloaded App Open ad if available and not already showing.
  /// Returns `true` if an ad was displayed, `false` otherwise.
  Future<bool> showAppOpenAdIfAvailable({VoidCallback? onDismissed}) async {
    if (!isAppOpenAdAvailable || _isShowingAppOpenAd) {
      preloadAppOpenAd();
      onDismissed?.call();
      return false;
    }

    // Protection anti-spam : cooldown de 4 minutes entre deux annonces d'ouverture
    if (_lastAppOpenShowTime != null &&
        DateTime.now().difference(_lastAppOpenShowTime!) < const Duration(minutes: 4)) {
      AppLogger.info('ADMOB', 'AppOpenAd ignored: 4-minute cooldown active.');
      onDismissed?.call();
      return false;
    }

    final completer = Completer<bool>();
    final ad = _appOpenAd!;
    _appOpenAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAppOpenAd = true;
        _lastAppOpenShowTime = DateTime.now();
        AppLogger.info('ADMOB', 'AppOpenAd showed full screen content.');
      },
      onAdDismissedFullScreenContent: (ad) {
        AppLogger.info('ADMOB', 'AppOpenAd dismissed full screen content.');
        _isShowingAppOpenAd = false;
        ad.dispose();
        preloadAppOpenAd();
        onDismissed?.call();
        if (!completer.isCompleted) completer.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, AdError error) {
        AppLogger.warning('ADMOB', 'AppOpenAd failed to show: code=${error.code}, message=${error.message}');
        _isShowingAppOpenAd = false;
        ad.dispose();
        preloadAppOpenAd();
        onDismissed?.call();
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    try {
      await ad.show();
      return await completer.future;
    } catch (e, st) {
      AppLogger.error('ADMOB', 'Exception while showing AppOpenAd: $e', e, st);
      _isShowingAppOpenAd = false;
      preloadAppOpenAd();
      onDismissed?.call();
      return false;
    }
  }

  /// Starts listening to app lifecycle changes (onResume) to trigger App Open Ads
  /// when the user brings the app back to the foreground, if user is not premium.
  void startAppLifecycleObservation({required bool Function() isPremium}) {
    _isPremiumChecker = isPremium;
    if (_lifecycleListener != null) return;
    _lifecycleListener = AppLifecycleListener(
      onPause: () {
        _lastPausedTime = DateTime.now();
      },
      onHide: () {
        _lastPausedTime ??= DateTime.now();
      },
      onResume: () {
        AppLogger.info('ADMOB', 'App resumed from background. Checking AppOpenAd eligibility...');
        final premium = _isPremiumChecker?.call() ?? false;
        if (premium) return;

        // Check how long the app was paused
        final pausedAt = _lastPausedTime;
        _lastPausedTime = null;

        if (pausedAt != null) {
          final backgroundDuration = DateTime.now().difference(pausedAt);
          // Only show ad if the app was backgrounded for at least 30 seconds
          // to avoid showing ads when simply locking/unlocking or quickly switching apps
          if (backgroundDuration < const Duration(seconds: 30)) {
            AppLogger.info('ADMOB', 'AppOpenAd skipped on resume: in background for only ${backgroundDuration.inSeconds}s (< 30s threshold).');
            return;
          }
        }

        showAppOpenAdIfAvailable();
      },
    );
    AppLogger.info('ADMOB', 'AppLifecycleListener registered for AppOpenAd.');
  }

  /// Disposes the lifecycle listener when tearing down.
  void disposeLifecycleListener() {
    _lifecycleListener?.dispose();
    _lifecycleListener = null;
  }
}
