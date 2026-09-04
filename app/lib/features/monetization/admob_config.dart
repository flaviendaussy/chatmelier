import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Centralized configuration for Google Mobile Ads (AdMob).
/// Defaulted to official Google sample test unit IDs to protect developer accounts
/// from invalid traffic suspensions during development and testing.
class AdMobConfig {
  /// Toggle to switch between Google Test Ads and live Production Ads.
  /// When true, official Google test ad unit IDs are served.
  /// Set to false once your AdMob account and ad units are approved on Google Play.
  static bool useTestAds = true;

  // --- Official Google AdMob Sample Test IDs ---
  // https://developers.google.com/admob/android/test-ads#sample_ad_units
  static const String testAndroidRewardedUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String testIosRewardedUnitId =
      'ca-app-pub-3940256099942544/1712485313';

  // --- Production IDs (Replace with your approved AdMob ad unit IDs) ---
  static String? productionAndroidRewardedUnitId;
  static String? productionIosRewardedUnitId;

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
}
