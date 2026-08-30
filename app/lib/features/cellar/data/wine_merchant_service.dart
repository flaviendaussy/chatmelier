import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/utils/app_logger.dart';
import '../domain/wine_merchant.dart';

final wineMerchantServiceProvider = Provider<WineMerchantService>((ref) {
  return WineMerchantService();
});

final wineMerchantsProvider = FutureProvider<List<WineMerchant>>((ref) async {
  final service = ref.watch(wineMerchantServiceProvider);
  return service.getMerchants();
});

class WineMerchantService {
  static const String _storageKey = 'chatmelier_wine_merchants_v1';
  List<WineMerchant>? _cachedMerchants;

  Future<List<WineMerchant>> getMerchants() async {
    if (_cachedMerchants != null) return _cachedMerchants!;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        _cachedMerchants = list.map((e) => WineMerchant.fromJson(e as Map<String, dynamic>)).toList();
        return _cachedMerchants!;
      }
    } catch (e) {
      AppLogger.warning('MERCHANTS', 'Error reading cached wine merchants: $e');
    }

    // Default pre-seeded prestigious cavistes for instant demonstration
    _cachedMerchants = [
      WineMerchant.create(
        name: 'Les Caves Legrand Filles & Fils',
        address: '1 Rue de la Banque, Galerie Vivienne',
        city: 'Paris',
        postalCode: '75002',
        country: 'France',
        latitude: 48.8665,
        longitude: 2.3396,
        isFavorite: true,
        notes: 'Caviste historique galerie Vivienne - Grands Bourgognes et Champagnes',
      ),
      WineMerchant.create(
        name: 'Lavinia Madeleine',
        address: '22 Boulevard de la Madeleine',
        city: 'Paris',
        postalCode: '75008',
        country: 'France',
        latitude: 48.8702,
        longitude: 2.3245,
        isFavorite: true,
        notes: 'Large sélection internationale et grands crus',
      ),
      WineMerchant.create(
        name: 'Berry Bros. & Rudd',
        address: '3 St James\'s St',
        city: 'London',
        postalCode: 'SW1A 1EG',
        country: 'United Kingdom',
        latitude: 51.5058,
        longitude: -0.1384,
        isFavorite: true,
        notes: 'Plus ancien marchand de vin de Londres (fondé en 1698)',
      ),
    ];
    await _saveToStorage(_cachedMerchants!);
    return _cachedMerchants!;
  }

  Future<void> saveMerchant(WineMerchant merchant) async {
    final list = await getMerchants();
    final index = list.indexWhere((m) => m.id == merchant.id || m.name.toLowerCase() == merchant.name.toLowerCase());
    if (index != -1) {
      list[index] = merchant;
    } else {
      list.insert(0, merchant);
    }
    _cachedMerchants = list;
    await _saveToStorage(list);
    AppLogger.info('MERCHANTS', 'Saved wine merchant: "${merchant.name}" (${merchant.city ?? ""})');
  }

  Future<void> deleteMerchant(String id) async {
    final list = await getMerchants();
    list.removeWhere((m) => m.id == id);
    _cachedMerchants = list;
    await _saveToStorage(list);
    AppLogger.info('MERCHANTS', 'Deleted wine merchant ID: $id');
  }

  Future<void> _saveToStorage(List<WineMerchant> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(list.map((m) => m.toJson()).toList());
      await prefs.setString(_storageKey, raw);
    } catch (e) {
      AppLogger.error('MERCHANTS', 'Failed to persist merchants', e);
    }
  }

  /// Search online places (Google Maps / OpenStreetMap Nominatim) for wine merchants / cavistes
  Future<List<WineMerchant>> searchOnlineMerchants(String query, {double? userLat, double? userLng}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    try {
      final encodedQuery = Uri.encodeComponent(
        cleanQuery.toLowerCase().contains('caviste') || cleanQuery.toLowerCase().contains('wine')
            ? cleanQuery
            : '$cleanQuery caviste vin',
      );

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&addressdetails=1&limit=8',
      );

      final res = await http.get(url, headers: {
        'User-Agent': 'ChatmelierWineApp/1.2.0 (contact@chatmelier.app)',
        'Accept-Language': 'fr,en;q=0.9',
      }).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        final List<WineMerchant> results = [];

        for (final item in data) {
          if (item is Map<String, dynamic>) {
            final displayName = item['display_name'] as String? ?? '';
            final name = item['name'] as String? ?? displayName.split(',').first;
            final addr = item['address'] as Map<String, dynamic>?;
            final road = addr?['road'] as String?;
            final houseNumber = addr?['house_number'] as String?;
            final city = addr?['city'] as String? ?? addr?['town'] as String? ?? addr?['village'] as String? ?? addr?['municipality'] as String?;
            final postcode = addr?['postcode'] as String?;
            final country = addr?['country'] as String?;
            final lat = double.tryParse(item['lat']?.toString() ?? '');
            final lon = double.tryParse(item['lon']?.toString() ?? '');

            String streetAddress = [if (houseNumber != null) houseNumber, if (road != null) road].join(' ');
            if (streetAddress.isEmpty) streetAddress = displayName;

            results.add(WineMerchant.create(
              name: name,
              address: streetAddress,
              city: city,
              postalCode: postcode,
              country: country,
              latitude: lat,
              longitude: lon,
              placeId: item['place_id']?.toString(),
            ));
          }
        }
        return results;
      }
    } catch (e) {
      AppLogger.warning('MERCHANTS', 'Online merchant search notice: $e');
    }

    // Fallback: Return matching local merchants or mock candidate based on query
    final local = await getMerchants();
    final localMatches = local.where((m) => m.name.toLowerCase().contains(cleanQuery.toLowerCase()) || (m.city ?? '').toLowerCase().contains(cleanQuery.toLowerCase())).toList();
    if (localMatches.isNotEmpty) return localMatches;

    return [
      WineMerchant.create(
        name: cleanQuery,
        address: 'Adresse à préciser',
        city: 'France / International',
        notes: 'Ajouté manuellement',
      ),
    ];
  }
}
