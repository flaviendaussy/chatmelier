import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../../features/cellar/domain/cellar.dart';
import '../utils/app_logger.dart';

enum ProximityMatchType { wifi, gps }

class CellarProximityMatch {
  final Cellar cellar;
  final ProximityMatchType matchType;
  final double? distanceMeters;
  final String? wifiSsid;
  final String explanation;

  const CellarProximityMatch({
    required this.cellar,
    required this.matchType,
    this.distanceMeters,
    this.wifiSsid,
    required this.explanation,
  });
}

class DistantCellarCheck {
  final bool isDistant;
  final double? distanceKm;
  final String? warningMessage;

  const DistantCellarCheck({
    required this.isDistant,
    this.distanceKm,
    this.warningMessage,
  });
}

class CellarLocationService {
  static final NetworkInfo _networkInfo = NetworkInfo();

  /// Retrieve current connected Wi-Fi SSID (clean of surrounding quotes)
  static Future<String?> getCurrentWifiSsid() async {
    if (kIsWeb) return null;
    try {
      final rawSsid = await _networkInfo.getWifiName();
      if (rawSsid == null || rawSsid.isEmpty || rawSsid == '<unknown ssid>') return null;
      // Strip surrounding quotes that Android/iOS may return e.g. "\"Livebox-1234\""
      return rawSsid.replaceAll(RegExp(r'^"|"$'), '').trim();
    } catch (e) {
      debugPrint('CellarLocationService.getCurrentWifiSsid notice: $e');
      return null;
    }
  }

  /// Retrieve current GPS Position safely with permission handling
  static Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      debugPrint('CellarLocationService.getCurrentPosition notice: $e');
      return null;
    }
  }

  /// Calculate distance between two coordinates in meters
  static double calculateDistanceMeters(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    try {
      return Geolocator.distanceBetween(
        startLatitude,
        startLongitude,
        endLatitude,
        endLongitude,
      );
    } catch (_) {
      // Fallback: Haversine formula
      const earthRadius = 6371000.0; // meters
      final dLat = (endLatitude - startLatitude) * (pi / 180.0);
      final dLon = (endLongitude - startLongitude) * (pi / 180.0);

      final a = sin(dLat / 2) * sin(dLat / 2) +
          cos(startLatitude * (pi / 180.0)) *
              cos(endLatitude * (pi / 180.0)) *
              sin(dLon / 2) *
              sin(dLon / 2);
      final c = 2 * atan2(sqrt(a), sqrt(1 - a));
      return earthRadius * c;
    }
  }

  /// Evaluates whether the user is physically at or close to a specific cellar
  static Future<CellarProximityMatch?> findProximityCellar({
    required List<Cellar> cellars,
    String? currentCellarId,
  }) async {
    if (cellars.isEmpty) return null;

    // 1. Check Wi-Fi SSID Match (100% confidence)
    final currentWifi = await getCurrentWifiSsid();
    if (currentWifi != null && currentWifi.isNotEmpty) {
      for (final c in cellars) {
        if (c.wifiSsid != null && c.wifiSsid!.trim().isNotEmpty) {
          final targetSsid = c.wifiSsid!.trim().toLowerCase();
          if (targetSsid == currentWifi.toLowerCase()) {
            AppLogger.info('LOCATION', 'Matched cellar "${c.name}" by Wi-Fi SSID: $currentWifi');
            return CellarProximityMatch(
              cellar: c,
              matchType: ProximityMatchType.wifi,
              wifiSsid: currentWifi,
              explanation: 'Connecté au Wi-Fi "$currentWifi"',
            );
          }
        }
      }
    }

    // 2. Check GPS Coordinates Geofencing
    final position = await getCurrentPosition();
    if (position != null) {
      Cellar? closestCellar;
      double closestDistance = double.infinity;

      for (final c in cellars) {
        if (c.latitude != null && c.longitude != null) {
          final dist = calculateDistanceMeters(
            position.latitude,
            position.longitude,
            c.latitude!,
            c.longitude!,
          );

          final maxRadius = (c.radiusMeters > 0 ? c.radiusMeters : 300).toDouble();
          if (dist <= maxRadius && dist < closestDistance) {
            closestDistance = dist;
            closestCellar = c;
          }
        }
      }

      if (closestCellar != null) {
        final distStr = closestDistance < 1000
            ? '${closestDistance.toStringAsFixed(0)} m'
            : '${(closestDistance / 1000).toStringAsFixed(1)} km';
        AppLogger.info('LOCATION', 'Matched cellar "${closestCellar.name}" by GPS ($distStr)');
        return CellarProximityMatch(
          cellar: closestCellar,
          matchType: ProximityMatchType.gps,
          distanceMeters: closestDistance,
          explanation: 'Position GPS détectée à $distStr',
        );
      }
    }

    return null;
  }

  /// Checks if the target cellar is far from the user's current location
  static Future<DistantCellarCheck> checkDistantCellar({
    required Cellar targetCellar,
    List<Cellar> allCellars = const [],
  }) async {
    // 1. Check Wi-Fi discrepancy: If connected to a known Wi-Fi of ANOTHER cellar
    final currentWifi = await getCurrentWifiSsid();
    if (currentWifi != null && currentWifi.isNotEmpty) {
      for (final other in allCellars) {
        if (other.id != targetCellar.id &&
            other.wifiSsid != null &&
            other.wifiSsid!.trim().toLowerCase() == currentWifi.toLowerCase()) {
          return DistantCellarCheck(
            isDistant: true,
            warningMessage:
                'Vous êtes actuellement connecté au Wi-Fi "${other.wifiSsid}" associé à votre autre cave "${other.displayName}".',
          );
        }
      }
    }

    // 2. Check GPS discrepancy
    if (targetCellar.latitude != null && targetCellar.longitude != null) {
      final pos = await getCurrentPosition();
      if (pos != null) {
        final distMeters = calculateDistanceMeters(
          pos.latitude,
          pos.longitude,
          targetCellar.latitude!,
          targetCellar.longitude!,
        );

        // Distance threshold for warning: > 5 km (or 5x radius)
        const thresholdMeters = 5000.0;
        if (distMeters > thresholdMeters) {
          final distKm = distMeters / 1000.0;
          return DistantCellarCheck(
            isDistant: true,
            distanceKm: distKm,
            warningMessage:
                'Vous êtes actuellement situé à environ ${distKm.toStringAsFixed(distKm > 10 ? 0 : 1)} km de "${targetCellar.displayName}".',
          );
        }
      }
    }

    return const DistantCellarCheck(isDistant: false);
  }
}
