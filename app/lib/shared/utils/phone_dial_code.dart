import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/cellar_location_service.dart';
import 'app_logger.dart';

/// Representation of a country and its international telephone dial code.
class CountryDialCode {
  final String isoCode; // 'FR', 'GB', 'IT', etc.
  final String dialCode; // '+33', '+44', '+39', etc.
  final String name; // 'France', 'Royaume-Uni (UK)', etc.
  final String flag; // '🇫🇷', '🇬🇧', etc.
  final String example; // '6 12 34 56 78'

  const CountryDialCode({
    required this.isoCode,
    required this.dialCode,
    required this.name,
    required this.flag,
    required this.example,
  });

  String get displayLabel => '$flag $name ($dialCode)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountryDialCode && runtimeType == other.runtimeType && isoCode == other.isoCode;

  @override
  int get hashCode => isoCode.hashCode;
}

class PhoneDialCodeHelper {
  // Pre-suggested top countries requested by user:
  // 1. France (default)
  // 2. UK
  static const CountryDialCode defaultCountry = CountryDialCode(
    isoCode: 'FR',
    dialCode: '+33',
    name: 'France',
    flag: '🇫🇷',
    example: '6 12 34 56 78',
  );

  static const CountryDialCode ukCountry = CountryDialCode(
    isoCode: 'GB',
    dialCode: '+44',
    name: 'Royaume-Uni (UK)',
    flag: '🇬🇧',
    example: '7911 123456',
  );

  /// Full worldwide list of country dialing codes
  static const List<CountryDialCode> supportedCountries = [
    defaultCountry,
    ukCountry,
    CountryDialCode(isoCode: 'IT', dialCode: '+39', name: 'Italie', flag: '🇮🇹', example: '312 345 6789'),
    CountryDialCode(isoCode: 'ES', dialCode: '+34', name: 'Espagne', flag: '🇪🇸', example: '612 34 56 78'),
    CountryDialCode(isoCode: 'BE', dialCode: '+32', name: 'Belgique', flag: '🇧🇪', example: '470 12 34 56'),
    CountryDialCode(isoCode: 'CH', dialCode: '+41', name: 'Suisse', flag: '🇨🇭', example: '78 123 45 67'),
    CountryDialCode(isoCode: 'DE', dialCode: '+49', name: 'Allemagne', flag: '🇩🇪', example: '151 23456789'),
    CountryDialCode(isoCode: 'PT', dialCode: '+351', name: 'Portugal', flag: '🇵🇹', example: '912 345 678'),
    CountryDialCode(isoCode: 'NL', dialCode: '+31', name: 'Pays-Bas', flag: '🇳🇱', example: '6 12345678'),
    CountryDialCode(isoCode: 'LU', dialCode: '+352', name: 'Luxembourg', flag: '🇱🇺', example: '621 123 456'),
    CountryDialCode(isoCode: 'US', dialCode: '+1', name: 'États-Unis', flag: '🇺🇸', example: '202 555 0123'),
    CountryDialCode(isoCode: 'CA', dialCode: '+1', name: 'Canada', flag: '🇨🇦', example: '416 555 0123'),
    CountryDialCode(isoCode: 'AT', dialCode: '+43', name: 'Autriche', flag: '🇦🇹', example: '650 1234567'),
    CountryDialCode(isoCode: 'GR', dialCode: '+30', name: 'Grèce', flag: '🇬🇷', example: '691 234 5678'),
    CountryDialCode(isoCode: 'IE', dialCode: '+353', name: 'Irlande', flag: '🇮🇪', example: '83 123 4567'),
    CountryDialCode(isoCode: 'AU', dialCode: '+61', name: 'Australie', flag: '🇦🇺', example: '412 345 678'),
    CountryDialCode(isoCode: 'NZ', dialCode: '+64', name: 'Nouvelle-Zélande', flag: '🇳🇿', example: '21 123 4567'),
    CountryDialCode(isoCode: 'ZA', dialCode: '+27', name: 'Afrique du Sud', flag: '🇿🇦', example: '71 123 4567'),
    CountryDialCode(isoCode: 'JP', dialCode: '+81', name: 'Japon', flag: '🇯🇵', example: '90 1234 5678'),
    CountryDialCode(isoCode: 'SE', dialCode: '+46', name: 'Suède', flag: '🇸🇪', example: '70 123 45 67'),
    CountryDialCode(isoCode: 'NO', dialCode: '+47', name: 'Norvège', flag: '🇳🇴', example: '412 34 567'),
    CountryDialCode(isoCode: 'DK', dialCode: '+45', name: 'Danemark', flag: '🇩🇰', example: '20 12 34 56'),
    CountryDialCode(isoCode: 'FI', dialCode: '+358', name: 'Finlande', flag: '🇫🇮', example: '40 1234567'),
    CountryDialCode(isoCode: 'PL', dialCode: '+48', name: 'Pologne', flag: '🇵🇱', example: '512 345 678'),
    CountryDialCode(isoCode: 'MA', dialCode: '+212', name: 'Maroc', flag: '🇲🇦', example: '612 345678'),
    CountryDialCode(isoCode: 'TN', dialCode: '+216', name: 'Tunisie', flag: '🇹🇳', example: '20 123 456'),
    CountryDialCode(isoCode: 'DZ', dialCode: '+213', name: 'Algérie', flag: '🇩🇿', example: '551 23 45 67'),
    CountryDialCode(isoCode: 'SG', dialCode: '+65', name: 'Singapour', flag: '🇸🇬', example: '8123 4567'),
    CountryDialCode(isoCode: 'HK', dialCode: '+852', name: 'Hong Kong', flag: '🇭🇰', example: '9123 4567'),
    CountryDialCode(isoCode: 'AE', dialCode: '+971', name: 'Émirats Arabes Unis', flag: '🇦🇪', example: '50 123 4567'),
  ];

  /// Find a CountryDialCode by ISO-2 (e.g. 'FR', 'GB', 'IT')
  static CountryDialCode findByIso(String? iso) {
    if (iso == null || iso.isEmpty) return defaultCountry;
    final upper = iso.toUpperCase().trim();
    return supportedCountries.firstWhere(
      (c) => c.isoCode == upper,
      orElse: () => defaultCountry,
    );
  }

  /// Find a CountryDialCode by dial prefix (e.g. '+33', '+44', '+39')
  static CountryDialCode findByDialCode(String? dial) {
    if (dial == null || dial.isEmpty) return defaultCountry;
    final clean = dial.startsWith('+') ? dial.trim() : '+${dial.trim()}';
    return supportedCountries.firstWhere(
      (c) => c.dialCode == clean,
      orElse: () => defaultCountry,
    );
  }

  /// Formats international phone number combining dialCode and nationalNumber.
  /// Automatically strips leading zero from nationalNumber (e.g. "06 12..." + "+33" -> "+33 6 12...").
  static String formatInternational({required String dialCode, required String nationalNumber}) {
    final cleanDial = dialCode.startsWith('+') ? dialCode.trim() : '+${dialCode.trim()}';
    String cleanNat = nationalNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // Strip leading zero for international format (standard in France, UK, Europe)
    if (cleanNat.startsWith('0') && cleanDial != '+39') {
      cleanNat = cleanNat.substring(1);
    }

    if (cleanNat.isEmpty) return '';
    return '$cleanDial $cleanNat';
  }

  /// Parses an existing phone string into its CountryDialCode and national number part.
  static (CountryDialCode country, String nationalNumber) parseExisting(String? fullPhone) {
    if (fullPhone == null || fullPhone.trim().isEmpty) {
      return (defaultCountry, '');
    }

    final trimmed = fullPhone.trim();

    // Check longest matching dial codes first (e.g. +351, +352 before +35)
    final sorted = List<CountryDialCode>.from(supportedCountries)
      ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));

    for (final c in sorted) {
      if (trimmed.startsWith(c.dialCode)) {
        final rest = trimmed.substring(c.dialCode.length).trim();
        return (c, rest);
      }
    }

    // If starts with 00XX...
    if (trimmed.startsWith('00')) {
      final withPlus = '+${trimmed.substring(2)}';
      for (final c in sorted) {
        if (withPlus.startsWith(c.dialCode)) {
          final rest = withPlus.substring(c.dialCode.length).trim();
          return (c, rest);
        }
      }
    }

    // Fallback: assume default (France)
    return (defaultCountry, trimmed);
  }

  /// Validates that an international phone number is well formed.
  static String? validateInternational(String? fullPhone) {
    if (fullPhone == null || fullPhone.trim().isEmpty) return null; // Optional if empty
    final trimmed = fullPhone.trim();

    if (!trimmed.startsWith('+')) {
      return 'Le numéro doit obligatoirement inclure l\'indicatif national (ex: +33, +44).';
    }

    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 7) {
      return 'Le numéro de téléphone est trop court (au moins 7 chiffres).';
    }
    if (digits.length > 16) {
      return 'Le numéro de téléphone est trop long (max 15 chiffres).';
    }

    return null;
  }

  // =========================================================================
  // GPS AUTO-DETECTION OF COUNTRY DIAL CODE
  // =========================================================================

  /// Detects the user's country code using GPS location.
  /// Falls back to geographic bounding boxes or OpenStreetMap reverse geocoding.
  static Future<CountryDialCode?> detectCountryFromGps() async {
    try {
      final pos = await CellarLocationService.getCurrentPosition();
      if (pos == null) return null;

      final lat = pos.latitude;
      final lon = pos.longitude;

      // 1. Fast offline geometric bounding boxes check
      final fastMatch = _matchBoundingBox(lat, lon);
      if (fastMatch != null) {
        AppLogger.info('PHONE_GEO', 'Detected country via fast bbox: ${fastMatch.isoCode} (${fastMatch.dialCode})');
        return fastMatch;
      }

      // 2. Online reverse geocode via Nominatim
      final uri = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=5');
      final resp = await http.get(
        uri,
        headers: {'User-Agent': 'Chatmelier-App/1.0 (wine app)'},
      ).timeout(const Duration(seconds: 3));

      if (resp.statusCode == 200) {
        final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        final countryCode = address?['country_code']?.toString().toUpperCase();
        if (countryCode != null && countryCode.isNotEmpty) {
          final matched = findByIso(countryCode);
          AppLogger.info('PHONE_GEO', 'Detected country via Nominatim: $countryCode -> ${matched.dialCode}');
          return matched;
        }
      }
    } catch (e) {
      AppLogger.warning('PHONE_GEO', 'Error detecting GPS country: $e');
    }
    return null;
  }

  /// Fast bounding box matcher for European & worldwide countries
  static CountryDialCode? _matchBoundingBox(double lat, double lon) {
    if (lat >= 41.3 && lat <= 51.1 && lon >= -5.1 && lon <= 9.6) {
      return defaultCountry; // FR +33
    }
    if (lat >= 49.9 && lat <= 60.9 && lon >= -8.6 && lon <= 1.8) {
      return ukCountry; // GB +44
    }
    if (lat >= 36.6 && lat <= 47.1 && lon >= 6.6 && lon <= 18.5) {
      return findByIso('IT'); // IT +39
    }
    if (lat >= 36.0 && lat <= 43.8 && lon >= -9.3 && lon <= 3.3) {
      return findByIso('ES'); // ES +34
    }
    if (lat >= 45.8 && lat <= 47.8 && lon >= 5.9 && lon <= 10.5) {
      return findByIso('CH'); // CH +41
    }
    if (lat >= 49.5 && lat <= 51.5 && lon >= 2.5 && lon <= 6.4) {
      return findByIso('BE'); // BE +32
    }
    if (lat >= 47.3 && lat <= 55.1 && lon >= 5.9 && lon <= 15.0) {
      return findByIso('DE'); // DE +49
    }
    if (lat >= 36.9 && lat <= 42.2 && lon >= -9.5 && lon <= -6.2) {
      return findByIso('PT'); // PT +351
    }
    if (lat >= 24.5 && lat <= 49.4 && lon >= -125.0 && lon <= -66.9) {
      return findByIso('US'); // US +1
    }
    return null;
  }
}
