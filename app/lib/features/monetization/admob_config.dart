import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Centralized configuration for Google Mobile Ads (AdMob).
/// Defaulted to official Google sample test unit IDs to protect developer accounts
/// from invalid traffic suspensions during development and testing.
class AdMobConfig {
  /// Toggle to switch between Google Test Ads and live Production Ads.
  /// When true, official Google test ad unit IDs are served.
  /// Set to false to serve real production AdMob ads.
  static bool useTestAds = false;

  /// Whether to fallback to the internal mock/sponsor video player when AdMob is unavailable.
  /// Set to false per user preference: only real AdMob ads or nothing (no fake ads).
  static bool fallbackToMockVideo = false;

  // --- Official Google AdMob Sample Test IDs ---
  // https://developers.google.com/admob/android/test-ads#sample_ad_units
  static const String testAndroidRewardedUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String testIosRewardedUnitId =
      'ca-app-pub-3940256099942544/1712485313';

  // --- Production IDs (Configured with user's AdMob Ad Unit) ---
  static String? productionAndroidRewardedUnitId =
      'ca-app-pub-6095914862192850/1740903138';
  /// Set this once you create the iOS app and rewarded ad unit in the AdMob console
  static String? productionIosRewardedUnitId;

  /// Test device identifiers to prevent "Invalid Traffic" penalties on your personal phone.
  /// Add your test device ID here (displayed in logcat/console on launch).
  static List<String> testDeviceIds = [];

  /// Returns true if AdMob is supported on the current running platform.
  /// AdMob Flutter SDK supports Android and iOS native; Web uses fallback player.
  static bool get isPlatformSupported {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  /// Returns the appropriate Rewarded Ad Unit ID for the current platform and mode.
  static String get rewardedAdUnitId {
    if (kIsWeb) return '';

    try {
      if (Platform.isIOS) {
        if (!useTestAds &&
            productionIosRewardedUnitId != null &&
            productionIosRewardedUnitId!.isNotEmpty) {
          return productionIosRewardedUnitId!;
        }
        return testIosRewardedUnitId;
      }
    } catch (_) {}

    // Default to Android ad unit
    if (!useTestAds &&
        productionAndroidRewardedUnitId != null &&
        productionAndroidRewardedUnitId!.isNotEmpty) {
      return productionAndroidRewardedUnitId!;
    }
    return testAndroidRewardedUnitId;
  }

  // --- Official Google AdMob App Open Test IDs ---
  // https://developers.google.com/admob/android/test-ads#sample_ad_units
  static const String testAndroidAppOpenUnitId =
      'ca-app-pub-3940256099942544/9257395921';
  static const String testIosAppOpenUnitId =
      'ca-app-pub-3940256099942544/5575463023';

  // --- Production IDs for App Open Ads ---
  static String? productionAndroidAppOpenUnitId =
      'ca-app-pub-6095914862192850/1658916157';
  static String? productionIosAppOpenUnitId;

  /// Returns the appropriate App Open Ad Unit ID for the current platform and mode.
  static String get appOpenAdUnitId {
    if (kIsWeb) return '';

    try {
      if (Platform.isIOS) {
        if (!useTestAds &&
            productionIosAppOpenUnitId != null &&
            productionIosAppOpenUnitId!.isNotEmpty) {
          return productionIosAppOpenUnitId!;
        }
        return testIosAppOpenUnitId;
      }
    } catch (_) {}

    // Default to Android ad unit
    if (!useTestAds &&
        productionAndroidAppOpenUnitId != null &&
        productionAndroidAppOpenUnitId!.isNotEmpty) {
      return productionAndroidAppOpenUnitId!;
    }
    return testAndroidAppOpenUnitId;
  }
}
