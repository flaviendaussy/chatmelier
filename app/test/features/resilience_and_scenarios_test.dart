import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmelier/config/theme.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/cellar/domain/cellar.dart';
import 'package:chatmelier/features/offline/domain/offline_action.dart';
import 'package:chatmelier/shared/services/cellar_location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Chatmelier User Scenarios & Edge Cases Tests', () {
    
    // Helper cleaning methods mirroring review_screen logic
    String cleanProducer(String s) {
      return s
          .toLowerCase()
          .replaceAll(RegExp(r'\b(domaine|château|chateau|maison|vignoble|vignobles|clos|cave|de|la|les|du|des|le)\b'), '')
          .replaceAll(RegExp(r'[^a-z0-9]'), '')
          .trim();
    }

    String cleanWineName(String s) {
      return s
          .toLowerCase()
          .replaceAll(RegExp(r'\b(rouge|blanc|rosé|rose|brut|sec|demi-sec|grand cru|premier cru|cru)\b'), '')
          .replaceAll(RegExp(r'[^a-z0-9]'), '')
          .trim();
    }

    String normalizeColor(String? type) {
      final t = (type ?? 'red').toLowerCase().trim();
      if (t.contains('red') || t.contains('rouge')) return 'red';
      if (t.contains('white') || t.contains('blanc')) return 'white';
      if (t.contains('rosé') || t.contains('rose')) return 'rosé';
      return t;
    }

    bool isDuplicate({
      required String scannedName,
      required String scannedProducer,
      required int? scannedVintage,
      required String scannedType,
      String? scannedCuvee,
      required Wine cellarWine,
    }) {
      // 1. Vintage
      if (scannedVintage != null || cellarWine.vintage != null) {
        if (scannedVintage != cellarWine.vintage) return false;
      }

      // 2. Color
      if (normalizeColor(scannedType) != normalizeColor(cellarWine.type)) return false;

      // 3. Producer
      final cleanCurrentProd = cleanProducer(scannedProducer);
      final cleanBProd = cleanProducer(cellarWine.producer ?? '');

      if (cleanCurrentProd.isNotEmpty && cleanBProd.isNotEmpty) {
        bool prodMatch = cleanCurrentProd == cleanBProd;
        if (!prodMatch && cleanCurrentProd.length >= 5 && cleanBProd.length >= 5) {
          prodMatch = cleanCurrentProd.contains(cleanBProd) || cleanBProd.contains(cleanCurrentProd);
        }
        if (!prodMatch) return false;
      } else if (cleanCurrentProd.isNotEmpty && cleanBProd.isEmpty) {
        final cleanBName = cleanWineName(cellarWine.name);
        if (!cleanBName.contains(cleanCurrentProd)) return false;
      } else if (cleanCurrentProd.isEmpty && cleanBProd.isNotEmpty) {
        final cleanCurrentName = cleanWineName(scannedName);
        if (!cleanCurrentName.contains(cleanBProd)) return false;
      }

      // 3.5. Check Cuvée / Parcelle (e.g. "La Tourtine" vs "La Miguoua")
      final cuvee1 = (scannedCuvee ?? '').trim().toLowerCase();
      final cuvee2 = (cellarWine.cuveeParcel ?? '').trim().toLowerCase();

      final cleanCurrentName = cleanWineName(scannedName);
      final cleanBName = cleanWineName(cellarWine.name);
      if (cleanCurrentName.isEmpty || cleanBName.isEmpty) return false;

      if (cuvee1.isNotEmpty && cuvee2.isNotEmpty) {
        final c1Clean = cleanWineName(cuvee1);
        final c2Clean = cleanWineName(cuvee2);
        if (c1Clean != c2Clean && !c1Clean.contains(c2Clean) && !c2Clean.contains(c1Clean)) {
          return false; // Different explicit cuvée/parcel -> NOT duplicate!
        }
      } else if (cuvee1.isNotEmpty && cuvee2.isEmpty) {
        final c1Clean = cleanWineName(cuvee1);
        if (c1Clean.length >= 4 && !cleanBName.contains(c1Clean)) {
          return false; // Current has specific parcel not in cellar wine
        }
      } else if (cuvee1.isEmpty && cuvee2.isNotEmpty) {
        final c2Clean = cleanWineName(cuvee2);
        if (c2Clean.length >= 4 && !cleanCurrentName.contains(c2Clean)) {
          return false; // Cellar wine has specific parcel not in current wine
        }
      }

      // 4. Wine Name
      final lengthDiff = (cleanCurrentName.length - cleanBName.length).abs();
      final nameMatch = cleanCurrentName == cleanBName ||
          (lengthDiff <= 3 && cleanCurrentName.length >= 6 && cleanBName.length >= 6 &&
              (cleanBName.contains(cleanCurrentName) || cleanCurrentName.contains(cleanBName)));

      return nameMatch;
    }

    test('Duplicate Detection properly distinguishes parcels/cuvées: La Tourtine vs La Miguoua', () {
      const tempierTourtine = Wine(
        id: 'wine-tempier-tourtine',
        name: 'Bandol',
        cuveeParcel: 'La Tourtine',
        producer: 'Domaine Tempier',
        vintage: 2020,
        type: 'red',
        country: 'France',
        region: 'Provence',
      );

      // Scenario A: Scanned is La Miguoua vs existing La Tourtine (with explicit cuvee field) -> NOT duplicate!
      final diffParcelResult = isDuplicate(
        scannedName: 'Bandol',
        scannedProducer: 'Domaine Tempier',
        scannedVintage: 2020,
        scannedType: 'red',
        scannedCuvee: 'La Miguoua',
        cellarWine: tempierTourtine,
      );
      expect(diffParcelResult, isFalse, reason: 'La Tourtine and La Miguoua must NEVER be considered duplicates');

      // Scenario B: Scanned is generic Bandol (no cuvée) vs existing La Tourtine -> NOT duplicate!
      final genericVsParcelResult = isDuplicate(
        scannedName: 'Bandol',
        scannedProducer: 'Domaine Tempier',
        scannedVintage: 2020,
        scannedType: 'red',
        scannedCuvee: null,
        cellarWine: tempierTourtine,
      );
      expect(genericVsParcelResult, isFalse, reason: 'Generic Bandol and Parcel La Tourtine must not be duplicate');

      // Scenario C: Parcel name embedded directly in name ("Bandol La Tourtine" vs "Bandol La Miguoua")
      const tempierTourtineInName = Wine(
        id: 'wine-tempier-tourtine-name',
        name: 'Bandol La Tourtine',
        producer: 'Domaine Tempier',
        vintage: 2020,
        type: 'red',
        country: 'France',
        region: 'Provence',
      );

      final embeddedParcelDiff = isDuplicate(
        scannedName: 'Bandol La Miguoua',
        scannedProducer: 'Domaine Tempier',
        scannedVintage: 2020,
        scannedType: 'red',
        cellarWine: tempierTourtineInName,
      );
      expect(embeddedParcelDiff, isFalse, reason: 'Embedded parcel names must not match');

      // Scenario D: Exact parcel match (La Tourtine vs La Tourtine) -> IS duplicate!
      final exactParcelMatch = isDuplicate(
        scannedName: 'Bandol',
        scannedProducer: 'Domaine Tempier',
        scannedVintage: 2020,
        scannedType: 'red',
        scannedCuvee: 'La Tourtine',
        cellarWine: tempierTourtine,
      );
      expect(exactParcelMatch, isTrue, reason: 'Same producer, vintage, and parcel must match as duplicate');
    });

    test('Duplicate Detection logic properly distinguishes wines from different domains', () {
      const tempierBandol = Wine(
        id: 'wine-tempier',
        name: 'Bandol Rouge',
        producer: 'Domaine Tempier',
        vintage: 2020,
        type: 'red',
        country: 'France',
        region: 'Provence',
      );

      // Scenario 1: User scans Bandol Rouge from Château de Pibarnon (different producer) -> NOT duplicate!
      final diffProducerResult = isDuplicate(
        scannedName: 'Bandol Rouge',
        scannedProducer: 'Château de Pibarnon',
        scannedVintage: 2020,
        scannedType: 'red',
        cellarWine: tempierBandol,
      );
      expect(diffProducerResult, isFalse, reason: 'Pibarnon and Tempier must not be considered duplicates');

      // Scenario 2: User scans Bandol Rouge from Domaine Tempier (exact match) -> IS duplicate!
      final sameProducerResult = isDuplicate(
        scannedName: 'Bandol Rouge',
        scannedProducer: 'Domaine Tempier',
        scannedVintage: 2020,
        scannedType: 'red',
        cellarWine: tempierBandol,
      );
      expect(sameProducerResult, isTrue, reason: 'Exact producer, name, vintage and color must match as duplicate');
    });

    test('Moillard 2022 with peak 2030 is En Garde and NOT À l\'apogée', () {
      const moillard = Wine(
        id: 'moillard-2022',
        name: 'Hautes Côtes de Nuits',
        producer: 'Moillard',
        vintage: 2022,
        type: 'red',
        country: 'France',
        region: 'Bourgogne',
        drinkStart: 2025,
        peakStart: 2030,
        peakEnd: 2035,
        drinkEnd: 2040,
      );

      expect(moillard.windowStatus, DrinkWindowStatus.aging);
      expect(moillard.windowStatus.labelFr, 'En garde');
    });

    test('Short aging rosé has strict peak window', () {
      const roseProvence = Wine(
        id: 'rose-2025',
        name: 'Côtes de Provence Rosé',
        producer: 'Château Minuty',
        vintage: 2025,
        type: 'rosé',
        country: 'France',
        region: 'Provence',
        drinkStart: 2025,
        peakStart: 2025,
        peakEnd: 2026,
        drinkEnd: 2027,
      );

      expect(roseProvence.windowStatus, DrinkWindowStatus.inPeak);
      expect(roseProvence.windowStatus.labelFr, 'À l\'apogée');
    });

    test('Cellar Domain Model serialization, copyWith, and location helpers', () {
      final cellar = Cellar(
        id: 'cellar-1',
        name: 'Cave de Bordeaux',
        nickname: 'Maison Principale',
        locationName: 'Bordeaux',
        latitude: 44.8378,
        longitude: -0.5792,
        wifiSsid: 'Livebox-Cave',
        radiusMeters: 250,
        ownerId: 'user-1',
        createdAt: DateTime(2026, 1, 1),
      );

      expect(cellar.hasGpsLocation, isTrue);
      expect(cellar.hasWifi, isTrue);
      expect(cellar.displayName, 'Maison Principale');

      final json = cellar.toJson();
      expect(json['wifi_ssid'], 'Livebox-Cave');
      expect(json['radius_meters'], 250);
      expect(json['latitude'], 44.8378);

      final restored = Cellar.fromJson(json);
      expect(restored.wifiSsid, 'Livebox-Cave');
      expect(restored.radiusMeters, 250);

      final updated = cellar.copyWith(wifiSsid: 'Freebox-Campagne', radiusMeters: 500);
      expect(updated.wifiSsid, 'Freebox-Campagne');
      expect(updated.radiusMeters, 500);
      expect(updated.name, 'Cave de Bordeaux');
    });

    test('CellarLocationService calculates accurate distance and evaluates distant cellars', () async {
      // Paris coordinates
      const parisLat = 48.8566;
      const parisLon = 2.3522;

      // Bordeaux coordinates (~500 km away)
      const bordeauxLat = 44.8378;
      const bordeauxLon = -0.5792;

      final distanceMeters = CellarLocationService.calculateDistanceMeters(
        parisLat,
        parisLon,
        bordeauxLat,
        bordeauxLon,
      );

      // Distance should be between 480 km and 520 km
      expect(distanceMeters, greaterThan(480000));
      expect(distanceMeters, lessThan(520000));

      // Test close distance (50 meters away)
      final closeDistance = CellarLocationService.calculateDistanceMeters(
        parisLat,
        parisLon,
        parisLat + 0.0004,
        parisLon + 0.0004,
      );
      expect(closeDistance, lessThan(100));
    });

    test('OfflineActionType.updateWine serializes and deserializes properly', () {
      final action = OfflineAction(
        type: OfflineActionType.updateWine,
        data: {
          'wine_id': 'wine-123',
          'name': 'Pomerol Grand Cru',
          'peak_drinking_start': 2028,
          'user_overrides': ['name', 'peak_drinking_start'],
        },
      );

      final json = action.toJson();
      expect(json['type'], 'updateWine');
      expect(json['data']['wine_id'], 'wine-123');

      final restored = OfflineAction.fromJson(json);
      expect(restored.type, OfflineActionType.updateWine);
      expect(restored.data['peak_drinking_start'], 2028);
    });

    test('Chat history multi-turn sanitization prevents consecutive identical roles', () {
      final rawHistory = [
        {'role': 'assistant', 'content': 'Bonjour ! Que puis-je vous servir ?'},
        {'role': 'user', 'content': 'J\'ai une côte de bœuf'},
        {'role': 'user', 'content': 'Et aussi du fromage'},
        {'role': 'assistant', 'content': 'Pour la côte de bœuf, un Bordeaux puissant...'},
        {'role': 'assistant', 'content': 'Et pour le fromage, un rouge rond...'},
      ];

      const incomingMessage = 'Quel vin choisir ?';

      final List<Map<String, dynamic>> contents = [];
      String? lastRole;

      for (final m in rawHistory) {
        final rawRole = m['role'];
        final role = rawRole == 'assistant' ? 'model' : 'user';
        final text = m['content']?.trim() ?? '';
        if (text.isEmpty) continue;

        if (contents.isEmpty && role != 'user') continue;

        if (role == lastRole && contents.isNotEmpty) {
          final lastEntry = contents.last;
          final parts = lastEntry['parts'] as List;
          parts.add({'text': text});
        } else {
          contents.add({
            'role': role,
            'parts': [{'text': text}],
          });
          lastRole = role;
        }
      }

      if (contents.isNotEmpty && lastRole == 'user') {
        final lastEntry = contents.last;
        final parts = lastEntry['parts'] as List;
        parts.add({'text': incomingMessage});
      } else {
        contents.add({
          'role': 'user',
          'parts': [{'text': incomingMessage}],
        });
      }

      expect(contents.first['role'], 'user');
      expect(contents.last['role'], 'user');
      for (int i = 0; i < contents.length - 1; i++) {
        expect(contents[i]['role'], isNot(equals(contents[i + 1]['role'])));
      }
      expect((contents[0]['parts'] as List).length, 2);
      expect((contents[1]['parts'] as List).length, 2);
      expect(contents[2]['role'], 'user');
    });

    test('Personal notes vs AI Tasting Notes separation & AI pollution filter', () {
      const wine = Wine(
        id: 'wine-bandol-1',
        name: 'Domaine de Terrebrune',
        vintage: 2019,
        type: 'red',
        country: 'France',
        region: 'Provence',
        appellation: 'Bandol',
        tastingNotes: 'Robe grenat intense, arômes complexes de sous-bois, mûres et épices orientales.',
        summary: 'Grand vin rouge de garde de Bandol.',
      );

      // Scenario 1: Raw notes match AI tastingNotes -> Polluted -> Filtered out to null
      const rawNotes1 = 'Robe grenat intense, arômes complexes de sous-bois, mûres et épices orientales.';
      final isAIPolluted1 =
          rawNotes1.trim().toLowerCase() == (wine.tastingNotes ?? '').trim().toLowerCase() ||
          rawNotes1.trim().toLowerCase() == (wine.summary ?? '').trim().toLowerCase() ||
          rawNotes1.contains('Sortie enregistrée par commande vocale');
      final userNotes1 = isAIPolluted1 ? null : rawNotes1;
      expect(userNotes1, isNull);

      // Scenario 2: Raw notes match AI summary -> Polluted -> Filtered out to null
      const rawNotes2 = 'Grand vin rouge de garde de Bandol.';
      final isAIPolluted2 =
          rawNotes2.trim().toLowerCase() == (wine.tastingNotes ?? '').trim().toLowerCase() ||
          rawNotes2.trim().toLowerCase() == (wine.summary ?? '').trim().toLowerCase() ||
          rawNotes2.contains('Sortie enregistrée par commande vocale');
      final userNotes2 = isAIPolluted2 ? null : rawNotes2;
      expect(userNotes2, isNull);

      // Scenario 3: Raw notes contains old fake voice boilerplate -> Polluted -> Filtered out
      const rawNotes3 = 'Sortie enregistrée par commande vocale au fond de la cave.';
      final isAIPolluted3 =
          rawNotes3.trim().toLowerCase() == (wine.tastingNotes ?? '').trim().toLowerCase() ||
          rawNotes3.trim().toLowerCase() == (wine.summary ?? '').trim().toLowerCase() ||
          rawNotes3.contains('Sortie enregistrée par commande vocale');
      final userNotes3 = isAIPolluted3 ? null : rawNotes3;
      expect(userNotes3, isNull);

      // Scenario 4: Genuine user personal notes -> Preserved intact
      const rawNotes4 = 'Cadeau de mariage de Marc, à garder jusqu\'en 2030 pour nos 10 ans.';
      final isAIPolluted4 =
          rawNotes4.trim().toLowerCase() == (wine.tastingNotes ?? '').trim().toLowerCase() ||
          rawNotes4.trim().toLowerCase() == (wine.summary ?? '').trim().toLowerCase() ||
          rawNotes4.contains('Sortie enregistrée par commande vocale');
      final userNotes4 = isAIPolluted4 ? null : rawNotes4;
      expect(userNotes4, 'Cadeau de mariage de Marc, à garder jusqu\'en 2030 pour nos 10 ans.');
    });

    test('Theme primary and secondary color definitions', () {
      expect(AppTheme.primaryColor, const Color(0xFF8B1E3F));
      expect(AppTheme.secondaryColor, const Color(0xFFC9A84C));
      expect(AppTheme.surfaceColor, const Color(0xFFFAF7F2));
      expect(AppTheme.backgroundColor, const Color(0xFFF5F0E8));
    });

    test('Cross-user uniqueness rules: Pseudo, Phone and Email exclusivity', () {
      const existingUsers = [
        {'id': 'u1', 'username': 'flavien', 'phone': '+33612345678', 'email': 'flavien@chatmelier.app'},
        {'id': 'u2', 'username': 'caro', 'phone': '+33698765432', 'email': 'caro@chatmelier.app'},
      ];

      bool isUsernameTaken(String username, String currentUserId) {
        final clean = username.toLowerCase().replaceAll('@', '').trim();
        return existingUsers.any((u) => u['id'] != currentUserId && u['username'] == clean);
      }

      bool isPhoneTaken(String phone, String currentUserId) {
        final cleanDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
        final noLeadingZero = cleanDigits.startsWith('0') ? cleanDigits.substring(1) : cleanDigits;
        return existingUsers.any((u) {
          if (u['id'] == currentUserId) return false;
          final userDigits = (u['phone'] as String).replaceAll(RegExp(r'[^0-9]'), '');
          return userDigits == cleanDigits ||
              (noLeadingZero.length >= 6 && userDigits.contains(noLeadingZero));
        });
      }

      bool isEmailTaken(String email, String currentUserId) {
        final clean = email.toLowerCase().trim();
        return existingUsers.any((u) => u['id'] != currentUserId && u['email'] == clean);
      }

      // Test Pseudo
      expect(isUsernameTaken('flavien', 'u2'), isTrue); // Taken by u1
      expect(isUsernameTaken('@Flavien', 'u2'), isTrue); // Case insensitive & @ stripped
      expect(isUsernameTaken('flavien', 'u1'), isFalse); // u1 can keep his own pseudo
      expect(isUsernameTaken('new_sommelier', 'u2'), isFalse); // Available

      // Test Phone
      expect(isPhoneTaken('+33612345678', 'u2'), isTrue); // Taken by u1
      expect(isPhoneTaken('0612345678', 'u2'), isTrue); // Match with national prefix
      expect(isPhoneTaken('+33612345678', 'u1'), isFalse); // u1 can keep his own phone
      expect(isPhoneTaken('+33600000000', 'u2'), isFalse); // Available

      // Test Email
      expect(isEmailTaken('flavien@chatmelier.app', 'u2'), isTrue); // Taken by u1
      expect(isEmailTaken('FLAVIEN@chatmelier.app', 'u2'), isTrue); // Case insensitive
      expect(isEmailTaken('flavien@chatmelier.app', 'u1'), isFalse); // u1 can keep his own email
      expect(isEmailTaken('sommelier@cave.fr', 'u2'), isFalse); // Available
    });

    test('Local cache and metadata prevent repeat username dialog popups', () {
      final userMetadata = {'username': 'flavien'};
      final prefsCache = {'user_profile_configured_u1': true, 'user_profile_username_u1': 'flavien'};

      bool shouldPromptForUsername({
        required String? metadataUsername,
        required bool isConfiguredInPrefs,
        required String? cachedUsername,
        required String? remoteUsername,
      }) {
        if (metadataUsername != null && metadataUsername.isNotEmpty) return false;
        if (isConfiguredInPrefs || (cachedUsername != null && cachedUsername.isNotEmpty)) return false;
        if (remoteUsername != null && remoteUsername.isNotEmpty) return false;
        return true;
      }

      // Scenario 1: Already in Auth User Metadata -> No prompt
      expect(shouldPromptForUsername(
        metadataUsername: userMetadata['username'],
        isConfiguredInPrefs: false,
        cachedUsername: null,
        remoteUsername: null,
      ), isFalse);

      // Scenario 2: Already in SharedPreferences -> No prompt
      expect(shouldPromptForUsername(
        metadataUsername: null,
        isConfiguredInPrefs: prefsCache['user_profile_configured_u1'] as bool,
        cachedUsername: prefsCache['user_profile_username_u1'] as String,
        remoteUsername: null,
      ), isFalse);

      // Scenario 3: Already in Remote DB -> No prompt
      expect(shouldPromptForUsername(
        metadataUsername: null,
        isConfiguredInPrefs: false,
        cachedUsername: null,
        remoteUsername: 'flavien',
      ), isFalse);

      // Scenario 4: Brand new account without username anywhere -> PROMPT REQUIRED
      expect(shouldPromptForUsername(
        metadataUsername: null,
        isConfiguredInPrefs: false,
        cachedUsername: null,
        remoteUsername: null,
      ), isTrue);
    });

  });
}
