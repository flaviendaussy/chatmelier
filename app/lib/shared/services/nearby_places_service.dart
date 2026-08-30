import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../utils/app_logger.dart';
import 'cellar_location_service.dart';

/// A location place (restaurant, bar, or user's custom location like "Chez Dimitri").
class NearbyPlace {
  final String id;
  final String name;
  final String type; // 'restaurant', 'bar', 'bistro', 'pub', 'cafe', 'wine_bar', 'custom', 'friend', 'home'
  final double? distanceMeters;
  final bool isCustom;
  final double? latitude;
  final double? longitude;
  final String? address;

  const NearbyPlace({
    required this.id,
    required this.name,
    required this.type,
    this.distanceMeters,
    this.isCustom = false,
    this.latitude,
    this.longitude,
    this.address,
  });

  String get iconEmoji {
    if (isCustom) return '⭐';
    switch (type.toLowerCase()) {
      case 'bar':
      case 'pub':
        return '🍺';
      case 'wine_bar':
        return '🍷';
      case 'cafe':
        return '☕';
      case 'bistro':
      case 'restaurant':
      default:
        return '🍽️';
    }
  }

  String get displayLabel {
    if (distanceMeters != null) {
      final distStr = distanceMeters! < 1000
          ? '${distanceMeters!.round()} m'
          : '${(distanceMeters! / 1000).toStringAsFixed(1)} km';
      return '$iconEmoji $name ($distStr)';
    }
    return '$iconEmoji $name';
  }
}

/// A custom place memorized by the user (e.g. "Chez Dimitri", "Chez mes parents").
class CustomPlace {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final int visitCount;
  final DateTime createdAt;
  final DateTime lastVisitedAt;

  const CustomPlace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 250.0,
    this.visitCount = 1,
    required this.createdAt,
    required this.lastVisitedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
        'visitCount': visitCount,
        'createdAt': createdAt.toIso8601String(),
        'lastVisitedAt': lastVisitedAt.toIso8601String(),
      };

  factory CustomPlace.fromJson(Map<String, dynamic> json) => CustomPlace(
        id: json['id'] as String,
        name: json['name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 250.0,
        visitCount: (json['visitCount'] as int?) ?? 1,
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastVisitedAt: DateTime.parse(json['lastVisitedAt'] as String),
      );

  CustomPlace copyWith({
    String? name,
    int? visitCount,
    DateTime? lastVisitedAt,
    double? radiusMeters,
  }) =>
      CustomPlace(
        id: id,
        name: name ?? this.name,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters ?? this.radiusMeters,
        visitCount: visitCount ?? this.visitCount,
        createdAt: createdAt,
        lastVisitedAt: lastVisitedAt ?? this.lastVisitedAt,
      );
}

final nearbyPlacesServiceProvider = Provider<NearbyPlacesService>((ref) {
  return NearbyPlacesService();
});

class NearbyPlacesService {
  static const String _customPlacesKey = 'chatmelier_custom_places_v1';
  static const String _userAgent = 'ChatmelierApp/1.0 (contact@chatmelier.app)';

  // =========================================================================
  // 1. CUSTOM PLACES MANAGEMENT (Chez Dimitri, etc.)
  // =========================================================================

  Future<List<CustomPlace>> getCustomPlaces() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_customPlacesKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        return list.map((e) => CustomPlace.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      AppLogger.warning('NEARBY_PLACES', 'Error loading custom places: $e');
    }
    return [];
  }

  Future<void> saveCustomPlaces(List<CustomPlace> places) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(places.map((p) => p.toJson()).toList());
      await prefs.setString(_customPlacesKey, jsonStr);
    } catch (e) {
      AppLogger.error('NEARBY_PLACES', 'Error saving custom places', e);
    }
  }

  /// Save or update a custom place associated with GPS coordinates.
  Future<CustomPlace> rememberPlace({
    required String name,
    required double latitude,
    required double longitude,
    double radiusMeters = 250.0,
  }) async {
    final places = await getCustomPlaces();
    final cleanName = name.trim();

    // Check if an existing place matches nearby (within radius) or has the exact same name
    final existingIdx = places.indexWhere((p) {
      final dist = CellarLocationService.calculateDistanceMeters(
        latitude,
        longitude,
        p.latitude,
        p.longitude,
      );
      return dist <= radiusMeters || p.name.toLowerCase() == cleanName.toLowerCase();
    });

    final now = DateTime.now();
    if (existingIdx != -1) {
      final existing = places[existingIdx];
      final updated = existing.copyWith(
        name: cleanName,
        visitCount: existing.visitCount + 1,
        lastVisitedAt: now,
      );
      places[existingIdx] = updated;
      await saveCustomPlaces(places);
      AppLogger.info('NEARBY_PLACES', 'Updated custom place "$cleanName" (visits: ${updated.visitCount})');
      return updated;
    } else {
      final newPlace = CustomPlace(
        id: const Uuid().v4(),
        name: cleanName,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        visitCount: 1,
        createdAt: now,
        lastVisitedAt: now,
      );
      places.add(newPlace);
      await saveCustomPlaces(places);
      AppLogger.info('NEARBY_PLACES', 'Created new custom place "$cleanName" at ($latitude, $longitude)');
      return newPlace;
    }
  }

  // =========================================================================
  // 2. NEARBY PLACES DISCOVERY (Custom Places + Overpass API + Nominatim)
  // =========================================================================

  /// Search for nearby places (Custom places first, then restaurants/bars around the user).
  Future<List<NearbyPlace>> getNearbyPlaces({
    double? latitude,
    double? longitude,
    int maxResults = 12,
  }) async {
    double? lat = latitude;
    double? lon = longitude;

    if (lat == null || lon == null) {
      final pos = await CellarLocationService.getCurrentPosition();
      if (pos != null) {
        lat = pos.latitude;
        lon = pos.longitude;
      }
    }

    if (lat == null || lon == null) {
      // Fallback: return any frequently visited custom places
      final customPlaces = await getCustomPlaces();
      customPlaces.sort((a, b) => b.visitCount.compareTo(a.visitCount));
      return customPlaces
          .take(5)
          .map((c) => NearbyPlace(
                id: c.id,
                name: c.name,
                type: 'custom',
                isCustom: true,
                latitude: c.latitude,
                longitude: c.longitude,
              ))
          .toList();
    }

    final List<NearbyPlace> results = [];
    final Set<String> seenNames = {};

    // A. Check Custom Saved Places matching proximity
    final customPlaces = await getCustomPlaces();
    for (final c in customPlaces) {
      final dist = CellarLocationService.calculateDistanceMeters(lat, lon, c.latitude, c.longitude);
      if (dist <= c.radiusMeters * 1.5) {
        seenNames.add(c.name.toLowerCase());
        results.add(NearbyPlace(
          id: c.id,
          name: c.name,
          type: 'custom',
          isCustom: true,
          distanceMeters: dist,
          latitude: c.latitude,
          longitude: c.longitude,
        ));
      }
    }

    // Sort custom places by distance
    results.sort((a, b) => (a.distanceMeters ?? 0).compareTo(b.distanceMeters ?? 0));

    // B. Search nearby Restaurants & Bars via Overpass API (OSM)
    try {
      final osmPlaces = await _fetchOsmNearby(lat, lon);
      for (final place in osmPlaces) {
        if (!seenNames.contains(place.name.toLowerCase())) {
          seenNames.add(place.name.toLowerCase());
          results.add(place);
        }
      }
    } catch (e) {
      AppLogger.warning('NEARBY_PLACES', 'Overpass fetch error, trying Nominatim fallback: $e');
      try {
        final fallbackPlaces = await _fetchNominatimNearby(lat, lon);
        for (final place in fallbackPlaces) {
          if (!seenNames.contains(place.name.toLowerCase())) {
            seenNames.add(place.name.toLowerCase());
            results.add(place);
          }
        }
      } catch (e2) {
        AppLogger.warning('NEARBY_PLACES', 'Nominatim fallback also failed: $e2');
      }
    }

    // Sort POIs (custom first, then by ascending distance)
    results.sort((a, b) {
      if (a.isCustom && !b.isCustom) return -1;
      if (!a.isCustom && b.isCustom) return 1;
      return (a.distanceMeters ?? 9999).compareTo(b.distanceMeters ?? 9999);
    });

    return results.take(maxResults).toList();
  }

  /// Query OpenStreetMap Overpass API for restaurants/bars/wine bars within 400m
  Future<List<NearbyPlace>> _fetchOsmNearby(double lat, double lon) async {
    final query =
        '[out:json][timeout:4];(node["amenity"~"restaurant|bar|pub|bistro|cafe"](around:400,$lat,$lon);way["amenity"~"restaurant|bar|pub|bistro|cafe"](around:400,$lat,$lon););out center 20;';

    final uri = Uri.parse('https://overpass-api.de/api/interpreter');
    final response = await http
        .post(
          uri,
          headers: {'User-Agent': _userAgent, 'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'data': query},
        )
        .timeout(const Duration(seconds: 4));

    if (response.statusCode != 200) {
      throw Exception('Overpass API returned status ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final elements = data['elements'] as List<dynamic>? ?? [];

    final List<NearbyPlace> list = [];
    for (final elem in elements) {
      final tags = elem['tags'] as Map<String, dynamic>? ?? {};
      final name = tags['name'] as String?;
      if (name == null || name.trim().isEmpty) continue;

      double? elemLat = (elem['lat'] as num?)?.toDouble();
      double? elemLon = (elem['lon'] as num?)?.toDouble();

      if (elemLat == null || elemLon == null) {
        final center = elem['center'] as Map<String, dynamic>?;
        if (center != null) {
          elemLat = (center['lat'] as num?)?.toDouble();
          elemLon = (center['lon'] as num?)?.toDouble();
        }
      }

      double? dist;
      if (elemLat != null && elemLon != null) {
        dist = CellarLocationService.calculateDistanceMeters(lat, lon, elemLat, elemLon);
      }

      final amenity = tags['amenity']?.toString() ?? 'restaurant';
      final street = tags['addr:street']?.toString();
      final housenumber = tags['addr:housenumber']?.toString();
      final address = (housenumber != null && street != null) ? '$housenumber $street' : street;

      list.add(NearbyPlace(
        id: elem['id']?.toString() ?? const Uuid().v4(),
        name: name.trim(),
        type: amenity,
        distanceMeters: dist,
        isCustom: false,
        latitude: elemLat,
        longitude: elemLon,
        address: address,
      ));
    }

    return list;
  }

  /// Fallback reverse geocoding via Nominatim
  Future<List<NearbyPlace>> _fetchNominatimNearby(double lat, double lon) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1',
    );

    final response = await http.get(
      uri,
      headers: {'User-Agent': _userAgent},
    ).timeout(const Duration(seconds: 4));

    if (response.statusCode != 200) return [];

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final name = data['name'] as String?;
    final address = data['address'] as Map<String, dynamic>? ?? {};
    final amenity = address['amenity'] as String? ?? address['restaurant'] as String? ?? address['bar'] as String?;

    final placeName = name ?? amenity ?? address['road'] as String?;
    if (placeName != null && placeName.isNotEmpty) {
      return [
        NearbyPlace(
          id: const Uuid().v4(),
          name: placeName,
          type: amenity != null ? 'restaurant' : 'custom',
          distanceMeters: 20,
          isCustom: false,
          latitude: lat,
          longitude: lon,
        ),
      ];
    }

    return [];
  }
}
