import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// A rich terroir geographic profile containing real GPS coordinates,
/// geological data, climate classification, and hexbin geometry properties.
class TerroirGeoProfile {
  final String id;
  final String name;
  final String appellation;
  final String region;
  final String? subRegion;
  final String country;
  final String countryCode;
  final String flag;
  final LatLng center;
  final double defaultZoom;
  final double hexRadiusKm;
  final int hexRings;
  final String soilType;
  final String climate;
  final String exposure;
  final String elevation;
  final String keyGrapes;
  final String classification;
  final String sommelierNotes;
  final Color accentColor;
  final List<String> keywords;

  const TerroirGeoProfile({
    required this.id,
    required this.name,
    required this.appellation,
    required this.region,
    this.subRegion,
    required this.country,
    required this.countryCode,
    required this.flag,
    required this.center,
    this.defaultZoom = 11.5,
    this.hexRadiusKm = 2.0,
    this.hexRings = 1,
    required this.soilType,
    required this.climate,
    required this.exposure,
    required this.elevation,
    required this.keyGrapes,
    required this.classification,
    required this.sommelierNotes,
    this.accentColor = const Color(0xFFD4AF37),
    required this.keywords,
  });

  /// Generates a smooth, organic polygon boundary representing the appellation / cru zone.
  List<LatLng> generateAppellationBoundary({double scale = 1.0}) {
    final double radiusKm = hexRadiusKm * 1.8 * scale;
    const int pointsCount = 36;
    const double degToRad = math.pi / 180.0;
    final double centerLat = center.latitude;
    final double centerLon = center.longitude;

    final List<LatLng> boundary = [];
    for (int i = 0; i < pointsCount; i++) {
      final double angle = (i * 360.0 / pointsCount) * degToRad;
      final double variation = 1.0 + 0.12 * math.sin(3 * angle + centerLat) + 0.06 * math.cos(5 * angle + centerLon);
      final double r = radiusKm * variation;
      final double latOffset = r / 111.32;
      final double lonOffset = r / (111.32 * math.cos(centerLat * degToRad));

      boundary.add(LatLng(
        centerLat + latOffset * math.sin(angle),
        centerLon + lonOffset * math.cos(angle),
      ));
    }
    return boundary;
  }

  /// Generates a set of hexagonal polygons centered on this terroir profile
  List<TerroirHexPolygon> generateHexagons() {
    final List<TerroirHexPolygon> hexList = [];
    const double degToRad = math.pi / 180.0;
    final double centerLat = center.latitude;
    final double centerLon = center.longitude;

    // Ring 0: Center Primary Hexagon (The core Cru parcel)
    final centerPoints = _createHexPoints(center, hexRadiusKm);
    hexList.add(
      TerroirHexPolygon(
        points: centerPoints,
        center: center,
        color: accentColor.withValues(alpha: 0.18),
        borderColor: accentColor,
        borderWidth: 1.8,
        isCenterCru: true,
        label: appellation,
      ),
    );

    // Ring 1: 6 Surrounding Hexagons (Appellation Terroir Zones)
    final double neighborDist = hexRadiusKm * math.sqrt(3);
    final List<Color> ringColors = [
      accentColor.withValues(alpha: 0.10),
      const Color(0xFF8B1E3F).withValues(alpha: 0.12), // Burgundy/Wine red
      accentColor.withValues(alpha: 0.08),
      const Color(0xFF704214).withValues(alpha: 0.09), // Terroir loam
      accentColor.withValues(alpha: 0.10),
      const Color(0xFF8B1E3F).withValues(alpha: 0.08),
    ];

    for (int i = 0; i < 6; i++) {
      final double angle = (60.0 * i + 30.0) * degToRad;
      final double dLat = (neighborDist * math.sin(angle)) / 111.32;
      final double dLon = (neighborDist * math.cos(angle)) /
          (111.32 * math.cos(centerLat * degToRad));

      final neighborCenter = LatLng(centerLat + dLat, centerLon + dLon);
      final neighborPoints = _createHexPoints(neighborCenter, hexRadiusKm * 0.96);

      hexList.add(
        TerroirHexPolygon(
          points: neighborPoints,
          center: neighborCenter,
          color: ringColors[i % ringColors.length],
          borderColor: accentColor.withValues(alpha: 0.35),
          borderWidth: 1.0,
          isCenterCru: false,
          label: 'Zone ${i + 1}',
        ),
      );
    }

    // Optional Ring 2 if large regional terroir
    if (hexRings >= 2) {
      for (int i = 0; i < 6; i++) {
        final double angle = (60.0 * i) * degToRad;
        final double dLat = (neighborDist * 1.8 * math.sin(angle)) / 111.32;
        final double dLon = (neighborDist * 1.8 * math.cos(angle)) /
            (111.32 * math.cos(centerLat * degToRad));
        final outerCenter = LatLng(centerLat + dLat, centerLon + dLon);
        final outerPoints = _createHexPoints(outerCenter, hexRadiusKm * 0.92);

        hexList.add(
          TerroirHexPolygon(
            points: outerPoints,
            center: outerCenter,
            color: accentColor.withValues(alpha: 0.06),
            borderColor: accentColor.withValues(alpha: 0.20),
            borderWidth: 0.8,
            isCenterCru: false,
            label: null,
          ),
        );
      }
    }

    return hexList;
  }

  static List<LatLng> _createHexPoints(LatLng c, double radiusKm) {
    const double degToRad = math.pi / 180.0;
    final double latOffset = radiusKm / 111.32;
    final double lonOffset =
        radiusKm / (111.32 * math.cos(c.latitude * degToRad));
    final List<LatLng> pts = [];
    for (int i = 0; i < 6; i++) {
      final double angle = (60.0 * i + 30.0) * degToRad;
      pts.add(LatLng(
        c.latitude + latOffset * math.sin(angle),
        c.longitude + lonOffset * math.cos(angle),
      ));
    }
    return pts;
  }
}

/// Represents an individual rendered hexagon parcel on the map
class TerroirHexPolygon {
  final List<LatLng> points;
  final LatLng center;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final bool isCenterCru;
  final String? label;

  const TerroirHexPolygon({
    required this.points,
    required this.center,
    required this.color,
    required this.borderColor,
    required this.borderWidth,
    required this.isCenterCru,
    this.label,
  });
}

/// Intelligent GIS Resolver matching bottles and wines to authentic Terroir Profiles
class TerroirGeoResolver {
  static String normalize(String str) {
    return str
        .toLowerCase()
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ùûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Resolves the optimal terroir profile for the given wine or spirit metadata
  static TerroirGeoProfile resolve({
    required String country,
    required String region,
    String? subRegion,
    String? appellation,
    bool isSpirit = false,
    String? wineType,
    String? wineName,
    String? producer,
  }) {
    final normApp = normalize(appellation ?? '');
    final normSub = normalize(subRegion ?? '');
    final normReg = normalize(region);
    final normCtry = normalize(country);
    final normName = normalize('${wineName ?? ""} ${producer ?? ""}');
    final normType = normalize(wineType ?? '');

    final fullCorpus = '$normName $normType $normApp $normSub $normReg $normCtry';

    final spiritKeywords = [
      'spirit', 'spiritueux', 'whisky', 'whiskey', 'scotch', 'bourbon',
      'rhum', 'rum', 'gin', 'vodka', 'tequila', 'mezcal', 'cognac',
      'armagnac', 'calvados', 'chartreuse', 'benedictine', 'liqueur',
      'digestif', 'eau de vie', 'eau-de-vie', 'pastis', 'anise'
    ];

    final isSpiritBottle = isSpirit ||
        spiritKeywords.any((k) => normType.contains(k) || normName.contains(k) || normApp.contains(k));

    if (isSpiritBottle) {
      final spiritProfiles = _profiles.where((p) => p.id.startsWith('spirit_')).toList();

      // 1. Appellation / Keyword match within spirit profiles
      if (normApp.isNotEmpty) {
        for (final profile in spiritProfiles) {
          for (final kw in profile.keywords) {
            if (normApp == kw || normApp.contains(kw) || kw.contains(normApp)) {
              return profile;
            }
          }
        }
      }

      // 2. Name & Producer match within spirit profiles
      for (final profile in spiritProfiles) {
        for (final kw in profile.keywords) {
          if (normName.contains(kw)) {
            return profile;
          }
        }
      }

      // 3. Region / SubRegion match within spirit profiles
      if (normReg.isNotEmpty || normSub.isNotEmpty) {
        for (final profile in spiritProfiles) {
          for (final kw in profile.keywords) {
            if ((normReg.isNotEmpty && (normReg == kw || normReg.contains(kw))) ||
                (normSub.isNotEmpty && (normSub == kw || normSub.contains(kw)))) {
              return profile;
            }
          }
        }
      }

      // 4. Corpus Search among spirit profiles
      for (final profile in spiritProfiles) {
        for (final kw in profile.keywords) {
          if (kw.length >= 4 && fullCorpus.contains(kw)) {
            return profile;
          }
        }
      }

      // 5. Spirit Country & Regional Fallback (NEVER Pauillac!)
      if (normCtry == 'france' || normCtry == 'fr') {
        if (normReg.contains('normandie') || normApp.contains('calvados')) {
          return spiritProfiles.firstWhere((p) => p.id == 'spirit_calvados');
        }
        if (normReg.contains('gascon') || normReg.contains('gers') || normReg.contains('sud ouest')) {
          return spiritProfiles.firstWhere((p) => p.id == 'spirit_armagnac');
        }
        if (normReg.contains('alpes') || normReg.contains('isere')) {
          return spiritProfiles.firstWhere((p) => p.id == 'spirit_chartreuse');
        }
        if (normReg.contains('martinique') || normReg.contains('guadeloupe') || normReg.contains('caraibes')) {
          return spiritProfiles.firstWhere((p) => p.id == 'spirit_rhum_martinique');
        }
        return spiritProfiles.firstWhere((p) => p.id == 'spirit_cognac');
      }

      if (normCtry.contains('royaume') || normCtry.contains('uk') || normCtry.contains('scotland') || normCtry.contains('ecosse')) {
        if (RegExp(r'\bgin\b', caseSensitive: false).hasMatch(normName) || RegExp(r'\bgin\b', caseSensitive: false).hasMatch(normApp)) {
          return spiritProfiles.firstWhere((p) => p.id == 'spirit_gin_london');
        }
        if (fullCorpus.contains('islay') || fullCorpus.contains('tourbe') || fullCorpus.contains('peated')) {
          return spiritProfiles.firstWhere((p) => p.id == 'spirit_whisky_islay');
        }
        return spiritProfiles.firstWhere((p) => p.id == 'spirit_whisky_speyside');
      }

      if (normCtry.contains('etats') || normCtry.contains('usa') || normCtry.contains('us') || normCtry.contains('america')) {
        return spiritProfiles.firstWhere((p) => p.id == 'spirit_bourbon_kentucky');
      }

      if (normCtry.contains('irlande') || normCtry.contains('ireland')) {
        return spiritProfiles.firstWhere((p) => p.id == 'spirit_whiskey_ireland');
      }

      if (normCtry.contains('mexique') || normCtry.contains('mexico')) {
        return spiritProfiles.firstWhere((p) => p.id == 'spirit_tequila_jalisco');
      }

      if (normCtry.contains('pologne') || normCtry.contains('poland') || normCtry.contains('russie') || normCtry.contains('russia')) {
        return spiritProfiles.firstWhere((p) => p.id == 'spirit_vodka_tradition');
      }

      // Default spirit fallback: Cognac (never Pauillac wine!)
      return spiritProfiles.firstWhere((p) => p.id == 'spirit_cognac');
    }

    // --- Wine Profiles Resolution ---
    final wineProfiles = _profiles.where((p) => !p.id.startsWith('spirit_')).toList();

    // 1. Exact Appellation Match
    if (normApp.isNotEmpty) {
      for (final profile in wineProfiles) {
        for (final kw in profile.keywords) {
          if (normApp == kw || normApp.contains(kw) || kw.contains(normApp)) {
            return profile;
          }
        }
      }
    }

    // 2. SubRegion Match
    if (normSub.isNotEmpty) {
      for (final profile in wineProfiles) {
        for (final kw in profile.keywords) {
          if (normSub == kw || normSub.contains(kw)) {
            return profile;
          }
        }
      }
    }

    // 3. Region Keyword Match
    if (normReg.isNotEmpty) {
      for (final profile in wineProfiles) {
        for (final kw in profile.keywords) {
          if (normReg == kw || normReg.contains(kw)) {
            return profile;
          }
        }
      }
    }

    // 4. Corpus Search
    for (final profile in wineProfiles) {
      for (final kw in profile.keywords) {
        if (kw.length >= 4 && fullCorpus.contains(kw)) {
          return profile;
        }
      }
    }

    // 5. Country Fallback
    for (final profile in wineProfiles) {
      if (normalize(profile.country) == normCtry ||
          profile.countryCode.toLowerCase() == normCtry) {
        return profile;
      }
    }

    // Default universal fallback (France - Bordeaux Pauillac for wines)
    return wineProfiles.first;
  }

  // ===========================================================================
  // Comprehensive Terroir Catalog
  // ===========================================================================
  static const List<TerroirGeoProfile> _profiles = [
    // -------------------------------------------------------------------------
    // BORDEAUX — RIVE GAUCHE (MÉDOC & GRAVES)
    // -------------------------------------------------------------------------
    TerroirGeoProfile(
      id: 'pauillac',
      name: 'Pauillac & Haut-Médoc',
      appellation: 'Pauillac',
      region: 'Bordeaux',
      subRegion: 'Médoc',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(45.1985, -0.7485),
      defaultZoom: 12.8,
      hexRadiusKm: 2.2,
      hexRings: 2,
      soilType: 'Croupes de graves garonnaises profondes, alios et sables',
      climate: 'Océanique tempéré régulé par l\'estuaire de la Gironde',
      exposure: 'Coteaux en pente douce orientés Est / Sud-Est vers le fleuve',
      elevation: '12 - 30 mètres',
      keyGrapes: 'Cabernet Sauvignon (70%), Merlot, Cabernet Franc, Petit Verdot',
      classification: 'Premiers Grands Crus Classés 1855 (Latour, Lafite, Mouton)',
      sommelierNotes: 'Les graves pauvres et filtrantes forcent la vigne à plonger ses racines jusqu\'à 6 mètres pour puiser l\'eau, conférant aux vins une structure tannique royale et un potentiel de garde centenaire.',
      accentColor: Color(0xFFD4AF37),
      keywords: ['pauillac', 'medoc', 'haut medoc', 'haut-medoc', 'lafite', 'latour', 'mouton', 'ciron'],
    ),
    TerroirGeoProfile(
      id: 'margaux',
      name: 'Margaux',
      appellation: 'Margaux',
      region: 'Bordeaux',
      subRegion: 'Médoc',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(45.0425, -0.6765),
      defaultZoom: 12.5,
      hexRadiusKm: 2.0,
      soilType: 'Graves fines très calcaires et caillouteuses, sables quartzeux',
      climate: 'Océanique doux et tempéré',
      exposure: 'Croupes ondulées douces face au fleuve',
      elevation: '10 - 24 mètres',
      keyGrapes: 'Cabernet Sauvignon, Merlot, Petit Verdot',
      classification: 'Premier Grand Cru Classé 1855 (Château Margaux)',
      sommelierNotes: 'Les graves les plus fines du Médoc offrent un soyeux de tanins inimitable et un bouquet floral délicat de violette et de cèdre.',
      keywords: ['margaux', 'chateau margaux', 'cantemerle', 'palmer'],
    ),
    TerroirGeoProfile(
      id: 'saint_julien',
      name: 'Saint-Julien',
      appellation: 'Saint-Julien',
      region: 'Bordeaux',
      subRegion: 'Médoc',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(45.1585, -0.7420),
      defaultZoom: 13.0,
      hexRadiusKm: 1.8,
      soilType: 'Graves garonnaises sédimentaires sur socle marneux',
      climate: 'Océanique maritime protecteur',
      exposure: 'Plateau légèrement incliné vers l\'Est',
      elevation: '15 - 22 mètres',
      keyGrapes: 'Cabernet Sauvignon, Merlot, Cabernet Franc',
      classification: 'Crus Classés 1855 (Léoville, Ducru-Beaucaillou)',
      sommelierNotes: 'L\'équilibre parfait du Médoc : la force et la charpente de Pauillac mariées à l\'élégance et la finesse de Margaux.',
      keywords: ['saint julien', 'saint-julien', 'leoville', 'las cases', 'ducru'],
    ),
    TerroirGeoProfile(
      id: 'saint_estephe',
      name: 'Saint-Estèphe',
      appellation: 'Saint-Estèphe',
      region: 'Bordeaux',
      subRegion: 'Médoc',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(45.2630, -0.7680),
      defaultZoom: 12.5,
      hexRadiusKm: 2.3,
      soilType: 'Graves mêlées d\'argiles denses retenant la fraîcheur',
      climate: 'Océanique maritime septentrional',
      exposure: 'Coteaux bordant l\'estuaire de la Gironde',
      elevation: '14 - 28 mètres',
      keyGrapes: 'Cabernet Sauvignon, Merlot (forte proportion)',
      classification: 'Deuxièmes Crus Classés (Cos d\'Estournel, Montrose)',
      sommelierNotes: 'Les sous-sols argileux confèrent une fraîcheur minérale et une trame compacte résistant magistralement aux millésimes chauds.',
      keywords: ['saint estephe', 'saint-estephe', 'cos destournel', 'montrose', 'calon segur'],
    ),
    TerroirGeoProfile(
      id: 'pessac_leognan',
      name: 'Pessac-Léognan & Graves',
      appellation: 'Pessac-Léognan',
      region: 'Bordeaux',
      subRegion: 'Graves',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(44.7560, -0.5980),
      defaultZoom: 12.2,
      hexRadiusKm: 2.8,
      soilType: 'Graves galets quartzeux, sables, argiles et calcaire coquillier',
      climate: 'Océanique adouci par la forêt des Landes',
      exposure: 'Croupes de graves bien drainées',
      elevation: '25 - 60 mètres',
      keyGrapes: 'Cabernet Sauvignon, Merlot, Sauvignon Blanc, Sémillon',
      classification: 'Cru Classé de Graves (Château Haut-Brion 1855)',
      sommelierNotes: 'Berceau historique du vin de Bordeaux depuis l\'Antiquité romaine. Minéralité fumée légendaire en rouge comme en blanc.',
      keywords: ['pessac', 'pessac-leognan', 'pessac leognan', 'graves', 'haut-brion', 'smith haut lafitte', 'bouscaut'],
    ),
    TerroirGeoProfile(
      id: 'sauternes',
      name: 'Sauternes & Barsac',
      appellation: 'Sauternes',
      region: 'Bordeaux',
      subRegion: 'Sauternais',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(44.5350, -0.3400),
      defaultZoom: 12.5,
      hexRadiusKm: 2.0,
      soilType: 'Graves sur calcaires argileux et marnes miocènes',
      climate: 'Microclimat brumeux matinal unique né de la confluence Ciron-Garonne',
      exposure: 'Coteaux orientés Nord/Nord-Est protégés des vents',
      elevation: '30 - 80 mètres',
      keyGrapes: 'Sémillon (80%), Sauvignon Blanc, Muscadelle',
      classification: 'Premier Cru Supérieur 1855 (Château d\'Yquem)',
      sommelierNotes: 'Les brumes matinales favorisent l\'apparition du Botrytis Cinerea (pourriture noble) tandis que les après-midis chauds concentrent les sucres et les arômes d\'abricot confit et de safran.',
      keywords: ['sauternes', 'barsac', 'yquem', 'suduiraut', 'rieussec', 'climens'],
    ),

    // -------------------------------------------------------------------------
    // BORDEAUX — RIVE DROITE (SAINT-ÉMILION & POMEROL)
    // -------------------------------------------------------------------------
    TerroirGeoProfile(
      id: 'saint_emilion',
      name: 'Saint-Émilion Grand Cru',
      appellation: 'Saint-Émilion',
      region: 'Bordeaux',
      subRegion: 'Libournais',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(44.8945, -0.1555),
      defaultZoom: 13.0,
      hexRadiusKm: 2.0,
      soilType: 'Plateau calcaire à astéries, argiles blanches et crasse de fer',
      climate: 'Océanique à influence continentale marquée',
      exposure: 'Amphithéâtre naturel exposé plein Sud',
      elevation: '40 - 100 mètres',
      keyGrapes: 'Merlot (dominant), Cabernet Franc (Bouchet), Cabernet Sauvignon',
      classification: 'Premiers Grands Crus Classés A (Ausone, Cheval Blanc, Figeac)',
      sommelierNotes: 'Le socle calcaire à astéries agit comme une éponge régulatrice d\'eau, offrant aux Merlots une opulence veloutée et une fraîcheur calcaire vibrante.',
      keywords: ['saint emilion', 'saint-emilion', 'saint-émilion', 'cheval blanc', 'ausone', 'figeac', 'angelus', 'pavie'],
    ),
    TerroirGeoProfile(
      id: 'pomerol',
      name: 'Pomerol',
      appellation: 'Pomerol',
      region: 'Bordeaux',
      subRegion: 'Libournais',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(44.9310, -0.2010),
      defaultZoom: 13.5,
      hexRadiusKm: 1.4,
      soilType: 'Boutonnière d\'argiles bleues smectites sur crasse de fer',
      climate: 'Océanique tempéré continentalisé',
      exposure: 'Plateau doux culminant à 40 mètres',
      elevation: '25 - 42 mètres',
      keyGrapes: 'Merlot (95%), Cabernet Franc',
      classification: 'AOC Communale d\'élite (Petrus, Le Pin, Lafleur)',
      sommelierNotes: 'La légendaire boutonnière d\'argile bleue de Petrus retient l\'humidité et confère aux vins une texture soyeuse, de la truffe noire et une intensité aromatique inégalée.',
      keywords: ['pomerol', 'petrus', 'le pin', 'lafleur', 'clinet', 'evangile', 'gazel'],
    ),

    // -------------------------------------------------------------------------
    // BOURGOGNE — CÔTE DE NUITS
    // -------------------------------------------------------------------------
    TerroirGeoProfile(
      id: 'vosne_romanee',
      name: 'Vosne-Romanée & Côte de Nuits',
      appellation: 'Vosne-Romanée',
      region: 'Bourgogne',
      subRegion: 'Côte de Nuits',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(47.1610, 4.9540),
      defaultZoom: 13.8,
      hexRadiusKm: 1.2,
      soilType: 'Calcaires bajociens et marnes oxfordiennes riches en fer',
      climate: 'Semi-continental aux nuits fraîches et étés chauds',
      exposure: 'Coteau pentu plein Levant (Est)',
      elevation: '250 - 310 mètres',
      keyGrapes: 'Pinot Noir (100%)',
      classification: 'Grands Crus Monopoles (Romanée-Conti, La Tâche, Richebourg)',
      sommelierNotes: 'La perle de la Côte d\'Or. Un équilibre aristocratique entre dentelle florale (rose fanée, pivoine), épices d\'Orient et tension minérale incomparable.',
      accentColor: Color(0xFF8B1E3F),
      keywords: ['vosne', 'vosne-romanee', 'vosne romanee', 'romanee', 'romanee-conti', 'la tache', 'richebourg', 'cote de nuits', 'bourgogne', 'burgundy'],
    ),
    TerroirGeoProfile(
      id: 'gevrey_chambertin',
      name: 'Gevrey-Chambertin',
      appellation: 'Gevrey-Chambertin',
      region: 'Bourgogne',
      subRegion: 'Côte de Nuits',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(47.2260, 4.9680),
      defaultZoom: 13.2,
      hexRadiusKm: 1.8,
      soilType: 'Cône de déjection de la Combe Lavaux, calcaires caillouteux et marnes',
      climate: 'Semi-continental septentrional',
      exposure: 'Est et Sud-Est à flanc de coteau',
      elevation: '260 - 380 mètres',
      keyGrapes: 'Pinot Noir (100%)',
      classification: '9 Grands Crus (Chambertin, Chambertin-Clos de Bèze)',
      sommelierNotes: 'Le "Roi des Vins". Vigueur, puissance musculaire, tanins fermes et arômes de cerise noire sauvage, de réglisse et de sous-bois.',
      keywords: ['gevrey', 'gevrey-chambertin', 'gevrey chambertin', 'chambertin', 'clos de beze', 'rousseau'],
    ),
    TerroirGeoProfile(
      id: 'chambolle_musigny',
      name: 'Chambolle-Musigny',
      appellation: 'Chambolle-Musigny',
      region: 'Bourgogne',
      subRegion: 'Côte de Nuits',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(47.1850, 4.9520),
      defaultZoom: 13.5,
      hexRadiusKm: 1.3,
      soilType: 'Calcaires très fissurés du Bathonien, sol mince et pierreux',
      climate: 'Semi-continental tempéré par la combe d\'Ambin',
      exposure: 'Plein Est recevant le soleil dès l\'aube',
      elevation: '250 - 350 mètres',
      keyGrapes: 'Pinot Noir (100%)',
      classification: 'Grands Crus (Musigny, Bonnes-Mares)',
      sommelierNotes: 'La quintessence de la délicatesse. Évoqué comme "le vin le plus soyeux de Bourgogne", d\'une grâce féminine et aérienne.',
      keywords: ['chambolle', 'chambolle-musigny', 'chambolle musigny', 'musigny', 'amoureuses'],
    ),

    // -------------------------------------------------------------------------
    // BOURGOGNE — CÔTE DE BEAUNE & CHABLIS
    // -------------------------------------------------------------------------
    TerroirGeoProfile(
      id: 'puligny_montrachet',
      name: 'Puligny-Montrachet & Meursault',
      appellation: 'Puligny-Montrachet',
      region: 'Bourgogne',
      subRegion: 'Côte de Beaune',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(46.9740, 4.7520),
      defaultZoom: 13.0,
      hexRadiusKm: 1.8,
      soilType: 'Marnes blanches oxfordiennes, calcaires bathoniens friables',
      climate: 'Semi-continental ensoleillé',
      exposure: 'Est et Sud-Est à mi-coteau',
      elevation: '230 - 320 mètres',
      keyGrapes: 'Chardonnay (100%)',
      classification: 'Grands Crus (Montrachet, Chevalier-Montrachet, Bâtard-Montrachet)',
      sommelierNotes: 'Le sommet mondial du vin blanc sec. Minéralité tranchante comme un scalpel, arômes de noisette grillée, silex frotté et beurré noble.',
      keywords: ['puligny', 'puligny-montrachet', 'montrachet', 'meursault', 'chassagne', 'chassagne-montrachet', 'cote de beaune'],
    ),
    TerroirGeoProfile(
      id: 'chablis',
      name: 'Chablis Grand Cru',
      appellation: 'Chablis',
      region: 'Bourgogne',
      subRegion: 'Chablisien',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(47.8150, 3.8010),
      defaultZoom: 12.8,
      hexRadiusKm: 2.2,
      soilType: 'Marnes kimméridgiennes fossilisées de minuscules huîtres (Exogyra virgula)',
      climate: 'Semi-continental frais exposé aux gelées de printemps',
      exposure: 'Coteau abrupt exposé Sud-Ouest dominant le Serein',
      elevation: '130 - 250 mètres',
      keyGrapes: 'Chardonnay (100%)',
      classification: '7 Climats de Chablis Grand Cru (Les Clos, Valmur, Vaudésir)',
      sommelierNotes: 'L\'empreinte iodée de l\'ancienne mer jurassique confère au vin une pureté cristalline, une salinité minérale et une vivacité électrique.',
      keywords: ['chablis', 'les clos', 'vaudesir', 'grenouilles', 'kimmeridgien', 'auxerrois'],
    ),

    // -------------------------------------------------------------------------
    // CHAMPAGNE
    // -------------------------------------------------------------------------
    TerroirGeoProfile(
      id: 'champagne_cote_des_blancs',
      name: 'Champagne — Côte des Blancs & Montagne de Reims',
      appellation: 'Champagne',
      region: 'Champagne',
      subRegion: 'Côte des Blancs',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(48.9740, 4.0050),
      defaultZoom: 11.8,
      hexRadiusKm: 3.5,
      hexRings: 2,
      soilType: 'Craie campanienne pure affleurante, bélemnites et nodules de silex',
      climate: 'Double influence océanique et continentale froide',
      exposure: 'Falaise de craie orientée plein Est',
      elevation: '120 - 240 mètres',
      keyGrapes: 'Chardonnay (Avize, Cramant), Pinot Noir (Bouzy, Ambonnay), Pinot Meunier',
      classification: '17 Villages classés 100% Grand Cru',
      sommelierNotes: 'La craie poreuse agit comme un régulateur thermique et hydrique parfait, apportant une effervescence fine, de la craie broyée et une allonge saline remarquable.',
      keywords: ['champagne', 'cote des blancs', 'cramant', 'avize', 'mesnil', 'ambonnay', 'bouzy', 'reims', 'epernay', 'ay'],
    ),

    // -------------------------------------------------------------------------
    // VALLÉE DU RHÔNE
    // -------------------------------------------------------------------------
    TerroirGeoProfile(
      id: 'rhone_cote_rotie_hermitage',
      name: 'Vallée du Rhône Septentrionale (Côte-Rôtie & Hermitage)',
      appellation: 'Côte-Rôtie',
      region: 'Vallée du Rhône',
      subRegion: 'Rhône Nord',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(45.4850, 4.8080),
      defaultZoom: 12.5,
      hexRadiusKm: 2.0,
      soilType: 'Micaschistes feuilletés (Côte Brune) et calcaires sableux (Côte Blonde)',
      climate: 'Continental tempéré balayé par le vent du Nord (Mistral)',
      exposure: 'Pentes vertigineuses terrassées en cheys jusqu\'à 60% face au Sud-Est',
      elevation: '180 - 340 mètres',
      keyGrapes: 'Syrah (dominant), co-fermentée avec jusqu\'à 20% de Viognier',
      classification: 'AOC Crus du Rhône Nord (Côte-Rôtie, Hermitage, Cornas, Condrieu)',
      sommelierNotes: 'Les terrasses en vertige surplombant le Rhône captent la chaleur solaire. La Syrah y exhale des notes d\'olive noire, de lard fumé, de violette et de poivre blanc.',
      keywords: ['cote-rotie', 'cote rotie', 'hermitage', 'l hermitage', 'cornas', 'condrieu', 'saint-joseph', 'saint joseph', 'rhone nord', 'rhone'],
    ),
    TerroirGeoProfile(
      id: 'rhone_chateauneuf_du_pape',
      name: 'Châteauneuf-du-Pape & Rhône Sud',
      appellation: 'Châteauneuf-du-Pape',
      region: 'Vallée du Rhône',
      subRegion: 'Rhône Sud',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(44.0580, 4.8320),
      defaultZoom: 12.5,
      hexRadiusKm: 2.5,
      soilType: 'Galets roulés quartzeux du Rhône sur socle d\'argiles rouges et sables',
      climate: 'Méditerranéen chaud et très sec, assaini par le Mistral vigoureux',
      exposure: 'Plateaux et terrasses ouvertes baignées de soleil',
      elevation: '40 - 120 mètres',
      keyGrapes: 'Grenache Noir (dominant), Mourvèdre, Syrah, Cinsault (13 cépages autorisés)',
      classification: 'Premier Cru de la Vallée du Rhône Méridionale (AOC 1936)',
      sommelierNotes: 'Les galets roulés emmagasinent la chaleur du soleil le jour et la restituent aux grappes la nuit, menant les Grenaches à une plénitude charnue et épicée de garrigue.',
      keywords: ['chateauneuf', 'chateauneuf-du-pape', 'chateauneuf du pape', 'gigondas', 'vacqueyras', 'beaumes de venise', 'rhone sud', 'tavel'],
    ),

    // -------------------------------------------------------------------------
    // VALLÉE DE LA LOIRE
    // -------------------------------------------------------------------------
    TerroirGeoProfile(
      id: 'loire_sancerre',
      name: 'Sancerre & Pouilly-Fumé',
      appellation: 'Sancerre',
      region: 'Vallée de la Loire',
      subRegion: 'Centre-Loire',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(47.3315, 2.8390),
      defaultZoom: 12.2,
      hexRadiusKm: 2.6,
      soilType: 'Terres blanches (marnes kimméridgiennes), caillottes et silex',
      climate: 'Océanique dégradé à tonalité continentale',
      exposure: 'Piton rocheux et collines escarpées dominant la Loire',
      elevation: '150 - 310 mètres',
      keyGrapes: 'Sauvignon Blanc (80%), Pinot Noir',
      classification: 'AOC Vignobles du Centre-Loire',
      sommelierNotes: 'Les sols de silex confèrent cette fameuse touche de "pierre à fusil" et de zeste de pamplemousse, tandis que les caillottes apportent vivacité et dentelle.',
      keywords: ['sancerre', 'pouilly-fume', 'pouilly fume', 'menetou', 'loire', 'centre loire', 'chinon', 'saumur', 'vouvray', 'muscadet'],
    ),

    // -------------------------------------------------------------------------
    // ALSACE
    // -------------------------------------------------------------------------
    TerroirGeoProfile(
      id: 'alsace_grands_crus',
      name: 'Alsace Grands Crus',
      appellation: 'Alsace Grand Cru',
      region: 'Alsace',
      subRegion: 'Haut-Rhin',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(48.1650, 7.3010), // Riquewihr / Ribeauvillé
      defaultZoom: 12.0,
      hexRadiusKm: 2.8,
      soilType: 'Mosaïque géologique unique : granites, grès roses des Vosges, calcaires et marnes',
      climate: 'Semi-continental très abrité et sec (effet de foehn des Vosges)',
      exposure: 'Coteaux abrupts exposés Est à Sud-Est',
      elevation: '200 - 450 mètres',
      keyGrapes: 'Riesling, Gewurztraminer, Pinot Gris, Muscat d\'Alsace',
      classification: '51 Terroirs d\'Alsace Grand Cru',
      sommelierNotes: 'La barrière vosgienne protège le vignoble, créant l\'une des régions les plus sèches de France où le Riesling exprime une minéralité de roche ciselée.',
      keywords: ['alsace', 'alsace grand cru', 'riesling', 'gewurztraminer', 'riqewihr', 'ribeauville', 'colmar', 'kastelberg', 'geisberg'],
    ),

    // -------------------------------------------------------------------------
    // PROVENCE & LANGUEDOC
    // -------------------------------------------------------------------------
    TerroirGeoProfile(
      id: 'provence_bandol',
      name: 'Bandol & Côtes de Provence',
      appellation: 'Bandol',
      region: 'Provence',
      subRegion: 'Var',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(43.1610, 5.7530),
      defaultZoom: 12.2,
      hexRadiusKm: 2.5,
      soilType: 'Restanques d\'argiles et de grès triasiques très calcaires',
      climate: 'Méditerranéen maritime avec plus de 3000 heures de soleil/an',
      exposure: 'Amphithéâtre naturel ouvert sur la mer Méditerranée',
      elevation: '50 - 250 mètres',
      keyGrapes: 'Mourvèdre (minimum 50% en rouge), Grenache, Cinsault',
      classification: 'Cru Majeur de Provence (AOC 1941)',
      sommelierNotes: 'Le Mourvèdre y trouve sa terre sacrée les pieds dans la mer. Vins de garde aux notes de cuir noble, cerise noire, sous-bois méditerranéen et épices.',
      keywords: ['bandol', 'provence', 'cotes de provence', 'cassis', 'tempier', 'pibarnon'],
    ),
    TerroirGeoProfile(
      id: 'languedoc_pic_saint_loup',
      name: 'Pic Saint-Loup & Terrasses du Larzac',
      appellation: 'Pic Saint-Loup',
      region: 'Languedoc',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(43.7820, 3.8110),
      defaultZoom: 12.0,
      hexRadiusKm: 3.0,
      soilType: 'Éboulis calcaires jurassiques et marnes au pied de la falaise',
      climate: 'Méditerranéen d\'altitude aux amplitudes thermiques jour/nuit marquées',
      exposure: 'Contreforts sud et est du massif calcaire',
      elevation: '150 - 400 mètres',
      keyGrapes: 'Syrah, Grenache, Mourvèdre',
      classification: 'Cru du Languedoc (AOC Communale)',
      sommelierNotes: 'L\'air frais descendant du causse la nuit préserve une fraîcheur aromatique et une finesse tannique qui tranchent avec la chaleur méridionale.',
      keywords: ['pic saint-loup', 'pic saint loup', 'larzac', 'terrasses du larzac', 'languedoc', 'corbieres', 'minervois', 'collioure'],
    ),

    // -------------------------------------------------------------------------
    // ESPAGNE — RIOJA & RIBERA DEL DUERO & JUMILLA
    // -------------------------------------------------------------------------
    TerroirGeoProfile(
      id: 'spain_rioja',
      name: 'Rioja (Alta & Alavesa)',
      appellation: 'DOCa Rioja',
      region: 'La Rioja',
      country: 'Espagne',
      countryCode: 'ES',
      flag: '🇪🇸',
      center: LatLng(42.5780, -2.8520), // Haro / Rioja Alta
      defaultZoom: 11.5,
      hexRadiusKm: 3.5,
      hexRings: 2,
      soilType: 'Argilo-calcaire sur terrasses alluviales de l\'Èbre, grès ferreux',
      climate: 'Continental tempéré par l\'influence atlantique de la Sierra Cantabria',
      exposure: 'Terrasses et versants orientés Sud',
      elevation: '400 - 700 mètres',
      keyGrapes: 'Tempranillo (dominant), Garnacha, Graciano, Mazuelo',
      classification: 'Denominación de Origen Calificada (DOCa)',
      sommelierNotes: 'Les fûts de chêne et la maturité lente confèrent au Tempranillo ses arômes emblématiques de vanille, cuir, tabac blond et fruits rouges macérés.',
      keywords: ['rioja', 'rioja alta', 'rioja alavesa', 'haro', 'tempranillo', 'crianza', 'reserva', 'gran reserva'],
    ),
    TerroirGeoProfile(
      id: 'spain_ribera_del_duero',
      name: 'Ribera del Duero',
      appellation: 'DO Ribera del Duero',
      region: 'Castille-et-León',
      country: 'Espagne',
      countryCode: 'ES',
      flag: '🇪🇸',
      center: LatLng(41.5950, -4.1180), // Peñafiel / Valbuena
      defaultZoom: 11.5,
      hexRadiusKm: 3.2,
      soilType: 'Calcaires tertiaires, couches limoneuses et craie de plateau',
      climate: 'Continental extrême : hivers rigoureux et étés torrides à nuits fraîches',
      exposure: 'Plateaux arides et coteaux bordant le fleuve Douro',
      elevation: '720 - 880 mètres (Vignoble d\'altitude)',
      keyGrapes: 'Tinto Fino (Tempranillo local 95%), Cabernet Sauvignon',
      classification: 'DO Ribera del Duero (Vega Sicilia, Pingus)',
      sommelierNotes: 'L\'altitude extrême préserve une acidité vibrante malgré la concentration solaire formidable de baies noires et de réglisse.',
      keywords: ['ribera', 'ribera del duero', 'vega sicilia', 'pingus', 'penafiel', 'pesquera'],
    ),
    TerroirGeoProfile(
      id: 'spain_jumilla',
      name: 'Jumilla & Murcia',
      appellation: 'DO Jumilla',
      region: 'Murcie',
      country: 'Espagne',
      countryCode: 'ES',
      flag: '🇪🇸',
      center: LatLng(38.4750, -1.3250),
      defaultZoom: 11.2,
      hexRadiusKm: 3.8,
      soilType: 'Sols bruns calcaires encroûtés très perméables retenant l\'eau en profondeur',
      climate: 'Méditerranéen semi-aride avec plus de 300 jours d\'ensoleillement',
      exposure: 'Plateaux d\'altitude et vallées entourées de massifs',
      elevation: '400 - 900 mètres',
      keyGrapes: 'Monastrell (Mourvèdre 80%), Syrah, Garnacha Tintorera',
      classification: 'Denominación de Origen (DO Jumilla)',
      sommelierNotes: 'Le royaume des vieilles vignes de Monastrell franches de pied. Concentration de fruits noirs confits, garrigue sauvage et finale chocolatée.',
      keywords: ['jumilla', 'murcia', 'murcie', 'monastrell', 'yecla', 'bullas'],
    ),
    TerroirGeoProfile(
      id: 'spain_priorat',
      name: 'Priorat (Llicorella)',
      appellation: 'DOQ Priorat',
      region: 'Catalogne',
      country: 'Espagne',
      countryCode: 'ES',
      flag: '🇪🇸',
      center: LatLng(41.1950, 0.7720), // Gratallops
      defaultZoom: 12.2,
      hexRadiusKm: 2.2,
      soilType: 'Llicorella : schistes ardoisiers noirs et cuivreux du Paléozoïque',
      climate: 'Méditerranéen aride de montagne',
      exposure: 'Costerets (pentes vertigineuses jusqu\'à 50%) en terrasses',
      elevation: '300 - 750 mètres',
      keyGrapes: 'Garnacha Peluda, Cariñena (Carignan centenaire), Syrah',
      classification: 'DOQ (Denominació d\'Origen Qualificada)',
      sommelierNotes: 'La roche schisteuse llicorella donne des rendements minuscules (10 hl/ha) produisant des vins d\'une intensité minérale, fumée et graphite renversante.',
      keywords: ['priorat', 'llicorella', 'gratallops', 'porrera', 'claudio', 'alvaro palacios', 'l ermita'],
    ),

    // -------------------------------------------------------------------------
    // ITALIE — PIÉMONT & TOSCANE
    // -------------------------------------------------------------------------
    TerroirGeoProfile(
      id: 'italy_barolo',
      name: 'Barolo & Barbaresco (Langhe)',
      appellation: 'DOCG Barolo',
      region: 'Piémont',
      country: 'Italie',
      countryCode: 'IT',
      flag: '🇮🇹',
      center: LatLng(44.6110, 7.9430),
      defaultZoom: 12.6,
      hexRadiusKm: 2.2,
      hexRings: 2,
      soilType: 'Marnes de Sant\'Agata (argiles et sables fins) et grès d\'Helvétien',
      climate: 'Continental tempéré aux brumes automnales mythiques (Nebbia)',
      exposure: 'Coteaux sinueux (Sorì) orientés plein Sud',
      elevation: '250 - 450 mètres',
      keyGrapes: 'Nebbiolo (100%)',
      classification: 'DOCG Barolo & Barbaresco (Menzioni Geografiche Aggiuntive - MGA)',
      sommelierNotes: 'Le Nebbiolo y livre son éclat translucide grenat orné d\'arômes de goudron noble, de pétale de rose séchée, de truffe blanche et d\'une acidité magistrale.',
      accentColor: Color(0xFFE11D48),
      keywords: ['barolo', 'barbaresco', 'langhe', 'piemont', 'piedmont', 'nebbiolo', 'alba', 'cannubi', 'la morra', 'serralunga'],
    ),
    TerroirGeoProfile(
      id: 'italy_montalcino',
      name: 'Brunello di Montalcino & Chianti Classico',
      appellation: 'DOCG Brunello di Montalcino',
      region: 'Toscane',
      country: 'Italie',
      countryCode: 'IT',
      flag: '🇮🇹',
      center: LatLng(43.0560, 11.4880),
      defaultZoom: 12.2,
      hexRadiusKm: 2.8,
      soilType: 'Galestro (schistes friables) et Alberese (calcaire compact toscan)',
      climate: 'Méditerranéen chaud tempéré par la brise marine thyrrhénienne',
      exposure: 'Collines douces toscanes culminant face au mont Amiata',
      elevation: '200 - 550 mètres',
      keyGrapes: 'Sangiovese Grosso (Brunello 100%)',
      classification: 'DOCG Brunello di Montalcino',
      sommelierNotes: 'Le Sangiovese trouve sur le Galestro sa plus noble expression : cerise griotte, thé noir, cuir de Russie et tanins denses et vibrants.',
      keywords: ['brunello', 'montalcino', 'chianti', 'chianti classico', 'toscane', 'tuscany', 'sangiovese', 'bolgheri', 'sassicaia'],
    ),

    // -------------------------------------------------------------------------
    // ÉTATS-UNIS — NAPA VALLEY
    // -------------------------------------------------------------------------
    TerroirGeoProfile(
      id: 'usa_napa_valley',
      name: 'Napa Valley (Oakville & Rutherford)',
      appellation: 'Napa Valley AVA',
      region: 'Californie',
      subRegion: 'North Coast',
      country: 'États-Unis',
      countryCode: 'US',
      flag: '🇺🇸',
      center: LatLng(38.4320, -122.4080),
      defaultZoom: 11.5,
      hexRadiusKm: 3.5,
      hexRings: 2,
      soilType: 'Cône alluvionnaire de Rutherford, bancs de graviers et cendres volcaniques',
      climate: 'Méditerranéen tempéré par les brouillards matinaux de la baie de San Pablo',
      exposure: 'Fond de vallée et coteaux des monts Mayacamas et Vaca',
      elevation: '50 - 450 mètres',
      keyGrapes: 'Cabernet Sauvignon (dominant), Merlot, Cabernet Franc, Chardonnay',
      classification: 'American Viticultural Area (AVA Oakville, Rutherford, Stags Leap)',
      sommelierNotes: 'Le célèbre "Rutherford Dust". Cabernets cossus et opulents aux notes de cassis mûr, moka, bois de cèdre et tanins veloutés à grains très fins.',
      keywords: ['napa', 'napa valley', 'oakville', 'rutherford', 'stags leap', 'californie', 'opus one', 'screaming eagle', 'sonoma'],
    ),

    // -------------------------------------------------------------------------
    // ARGENTINE — MENDOZA
    // -------------------------------------------------------------------------
    TerroirGeoProfile(
      id: 'argentina_mendoza',
      name: 'Mendoza — Valle de Uco',
      appellation: 'Valle de Uco',
      region: 'Mendoza',
      country: 'Argentine',
      countryCode: 'AR',
      flag: '🇦🇷',
      center: LatLng(-33.6200, -69.1200),
      defaultZoom: 11.0,
      hexRadiusKm: 4.2,
      hexRings: 2,
      soilType: 'Alluvions sableuses caillouteuses incrustées de calcaire blanc pur',
      climate: 'Désertique d\'altitude (soleil permanent et eau de fonte des glaciers des Andes)',
      exposure: 'Piémont andin sous le mont Tupungato',
      elevation: '900 - 1450 mètres (Vignoble très haut)',
      keyGrapes: 'Malbec (dominant), Cabernet Franc, Torrontés',
      classification: 'Indicación Geográfica (IG Gualtallary, Paraje Altamira)',
      sommelierNotes: 'L\'ensoleillement UV intense épaissit la peau du Malbec tandis que les nuits glaciales des Andes fixent l\'acidité, créant des vins violets profonds aux notes de myrtille et de violette.',
      keywords: ['mendoza', 'uco', 'valle de uco', 'gualtallary', 'altamira', 'malbec', 'argentine', 'argentina'],
    ),

    // -------------------------------------------------------------------------
    // AUSTRALIE — BAROSSA VALLEY
    // -------------------------------------------------------------------------
    TerroirGeoProfile(
      id: 'australia_barossa',
      name: 'Barossa Valley',
      appellation: 'Barossa Valley',
      region: 'South Australia',
      country: 'Australie',
      countryCode: 'AU',
      flag: '🇦🇺',
      center: LatLng(-34.5200, 138.9800),
      defaultZoom: 11.2,
      hexRadiusKm: 3.5,
      soilType: 'Argiles rouges profondes fertiles mêlées de sables et de fer',
      climate: 'Méditerranéen chaud et ensoleillé',
      exposure: 'Vallée vallonnée protégée par les collines de Barossa Ranges',
      elevation: '250 - 400 mètres',
      keyGrapes: 'Shiraz (Syrah centenaire préphylloxérique), Cabernet Sauvignon, Grenache',
      classification: 'Geographical Indication (GI Barossa)',
      sommelierNotes: 'Certaines des plus vieilles vignes franches de pied de Shiraz au monde (plantées en 1843). Fruits noirs confiturés, pruneau, eucalyptus et chocolat noir.',
      keywords: ['barossa', 'barossa valley', 'shiraz', 'penfolds', 'grange', 'australie', 'australia'],
    ),

    // -------------------------------------------------------------------------
    // PORTUGAL — DOURO
    // -------------------------------------------------------------------------
    TerroirGeoProfile(
      id: 'portugal_douro',
      name: 'Vallée du Douro (Cima Corgo)',
      appellation: 'DOC Douro & Porto',
      region: 'Douro',
      country: 'Portugal',
      countryCode: 'PT',
      flag: '🇵🇹',
      center: LatLng(41.1850, -7.5450), // Pinhão
      defaultZoom: 12.0,
      hexRadiusKm: 2.8,
      soilType: 'Schistes verticaux fracturés permettant aux racines de boire à 10m',
      climate: 'Méditerranéen très sec et torride protégé par la Serra do Marão',
      exposure: 'Terrasses escarpées vertigineuses (Socalcos et Patamares)',
      elevation: '100 - 600 mètres',
      keyGrapes: 'Touriga Nacional, Touriga Franca, Tinta Roriz (Tempranillo)',
      classification: 'Vignoble classé Patrimoine Mondial UNESCO',
      sommelierNotes: 'La plus ancienne région délimitée au monde (1756). Terroir héroïque sculpté par la main de l\'homme produisant les grands Vintages de Porto et de somptueux vins secs.',
      keywords: ['douro', 'porto', 'pinhao', 'touriga', 'portugal', 'alentejo', 'dao', 'vinho verde'],
    ),

    // =========================================================================
    // SPIRITUEUX & EAUX-DE-VIE D'EXCEPTION
    // =========================================================================

    // 1. COGNAC & CHARENTE
    TerroirGeoProfile(
      id: 'spirit_cognac',
      name: 'Cognac & Charente (Grande Champagne)',
      appellation: 'AOC Cognac',
      region: 'Nouvelle-Aquitaine',
      subRegion: 'Grande Champagne & Fins Bois',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(45.6960, -0.3280),
      defaultZoom: 11.5,
      hexRadiusKm: 3.5,
      soilType: 'Campanien calcaire crayeux friable (Terres blanches de Grande Champagne)',
      climate: 'Océanique doux et tempéré à forte hygrométrie favorisant la part des anges',
      exposure: 'Coteaux ouverts et vallonnés le long du fleuve Charente',
      elevation: '20 - 160 mètres',
      keyGrapes: 'Ugni Blanc (dominant), Colombard, Folle Blanche',
      classification: 'AOC Cognac (Cru Grande Champagne / Petite Champagne)',
      sommelierNotes: 'Double distillation au repasse dans l\'alambic charentais en cuivre, puis long vieillissement sous fûts de chêne français du Limousin développant le rancio mythique.',
      accentColor: Color(0xFFD4AF37),
      keywords: ['cognac', 'charente', 'pineau', 'hennessy', 'remy martin', 'courvoisier', 'martell', 'delamain', 'camus', 'otard', 'hine', 'ugni blanc'],
    ),

    // 2. ARMAGNAC & BAS-ARMAGNAC
    TerroirGeoProfile(
      id: 'spirit_armagnac',
      name: 'Armagnac & Bas-Armagnac',
      appellation: 'AOC Bas-Armagnac',
      region: 'Gascogne',
      subRegion: 'Bas-Armagnac & Ténarèze',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(43.8610, 0.1010),
      defaultZoom: 11.5,
      hexRadiusKm: 3.5,
      soilType: 'Sables fauves siliceux et boulbènes typiques du Bas-Armagnac',
      climate: 'Subatlantique tempéré sous influence pyrénéenne et océanique',
      exposure: 'Pentes douces boisées de chênes pédonculés gascons',
      elevation: '80 - 200 mètres',
      keyGrapes: 'Baco 22A, Ugni Blanc, Folle Blanche, Colombard',
      classification: 'AOC Armagnac / Bas-Armagnac',
      sommelierNotes: 'Plus ancienne eau-de-vie de France (1310). Distillation continue sur alambic armagnacais et élevage sous chêne noir de Gascogne : eau-de-vie rustique, puissante, aux notes de pruneau, vanille et épices.',
      accentColor: Color(0xFFC05621),
      keywords: ['armagnac', 'bas armagnac', 'bas-armagnac', 'gers', 'gascogne', 'tenareze', 'haut armagnac', 'baco', 'darmaillac', 'tariquet', 'laberdolive'],
    ),

    // 3. CALVADOS PAYS D'AUGE
    TerroirGeoProfile(
      id: 'spirit_calvados',
      name: 'Calvados Pays d\'Auge',
      appellation: 'AOC Calvados Pays d\'Auge',
      region: 'Normandie',
      subRegion: 'Pays d\'Auge',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(49.2880, 0.1870),
      defaultZoom: 11.8,
      hexRadiusKm: 3.0,
      soilType: 'Marnes argilo-calcaires jurassiques et silex des vallons normands',
      climate: 'Océanique humide, doux et tempéré favorisant la pomologie',
      exposure: 'Vergers traditionnels haute-tige enherbés et pâturés',
      elevation: '40 - 150 mètres',
      keyGrapes: 'Pommes à cidre douces-amères (Bisquet, Bédan) et acidulées, Poires',
      classification: 'AOC Calvados Pays d\'Auge (Double distillation)',
      sommelierNotes: 'Nectar né de la distillation du cidre normand pur jus vieilli en fûts de chêne. Arômes intenses de pomme rôtie au beurre, de tarte tatin, de caramel au beurre salé et d\'épices douces.',
      accentColor: Color(0xFFDD6B20),
      keywords: ['calvados', 'normandie', 'pays d auge', 'pays d\'auge', 'pommeau', 'cidre', 'cider', 'dupont', 'drouin', 'groult', 'boulard', 'camut'],
    ),

    // 4. CHARTREUSE (VOIRON & MASSIF)
    TerroirGeoProfile(
      id: 'spirit_chartreuse',
      name: 'Liqueur des Pères Chartreux (Voiron)',
      appellation: 'Liqueur de Chartreuse',
      region: 'Auvergne-Rhône-Alpes',
      subRegion: 'Massif de la Chartreuse / Voiron',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(45.3640, 5.8150),
      defaultZoom: 12.0,
      hexRadiusKm: 2.5,
      soilType: 'Massif préalpin calcaire urgonien et forêts d\'altitude',
      climate: 'Alpin rigoureux et tempéré par les vallées',
      exposure: 'Coteaux alpins abrités de la combe d\'Isère',
      elevation: '280 - 1000 mètres',
      keyGrapes: 'Alcool de grain infusé et distillé avec 130 plantes et herbes alpines',
      classification: 'Liqueur monastique historique (Manuscrit 1605)',
      sommelierNotes: 'La seule liqueur au monde entièrement naturelle à vieillir et se bonifier en bouteille pendant des décennies. Complexe symphonie végétale de menthe poivrée, d\'anis, de thym serpolet, de génépi et de safran.',
      accentColor: Color(0xFF10B981),
      keywords: ['chartreuse', 'voiron', 'aiguenoire', 'isere', 'verte', 'jaune', 'elixir', 'vep', 'chartreux'],
    ),

    // 5. BÉNÉDICTINE (FÉCAMP)
    TerroirGeoProfile(
      id: 'spirit_benedictine',
      name: 'Palais Bénédictine (Fécamp)',
      appellation: 'Bénédictine D.O.M.',
      region: 'Normandie',
      subRegion: 'Côte d\'Albâtre / Fécamp',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(49.7570, 0.3750),
      defaultZoom: 12.0,
      hexRadiusKm: 2.5,
      soilType: 'Falaise de craie blanche sénonienne du pays de Caux',
      climate: 'Océanique vivifiant balayé par les vents de la Manche',
      exposure: 'Vallée maritime de Fécamp ouverte sur le littoral',
      elevation: '10 - 80 mètres',
      keyGrapes: '27 plantes et épices du monde (angélique, hysope, safran, genièvre, cannelle)',
      classification: 'Élixir de santé monastique né en 1510',
      sommelierNotes: 'Distillation quadruple sous alambics martelés en cuivre de 1888 et vieillissement en foudres de chêne centenaires. Texture soyeuse, miel épicé, écorces d\'oranges confites et notes orientales.',
      accentColor: Color(0xFFD97706),
      keywords: ['benedictine', 'fecamp', 'dom', 'd.o.m', 'le grand', 'b&b', 'caux'],
    ),

    // 6. ISLAY SINGLE MALT SCOTCH WHISKY
    TerroirGeoProfile(
      id: 'spirit_whisky_islay',
      name: 'Islay Single Malt Scotch Whisky',
      appellation: 'Single Malt Islay Scotch Whisky',
      region: 'Écosse / Scotland',
      subRegion: 'Islay (Hébrides intérieures)',
      country: 'Royaume-Uni',
      countryCode: 'GB',
      flag: '🏴󠁧󠁢󠁳󠁣󠁴󠁿',
      center: LatLng(55.7570, -6.2870),
      defaultZoom: 11.2,
      hexRadiusKm: 3.8,
      soilType: 'Tourbières épaisses gorgées d\'eau de bruyère et quartz précambrien',
      climate: 'Océanique sauvage, pluvieux et balayé par les embruns atlantiques',
      exposure: 'Rivages côtiers sauvages du Loch Indaal et du Sound of Islay',
      elevation: '0 - 150 mètres',
      keyGrapes: 'Orge maltée séchée à la fumée de tourbe locale (Peat)',
      classification: 'Protected Geographical Indication (PGI Scotch Whisky)',
      sommelierNotes: 'Le sanctuaire mondial des whiskies tourbés et iodés. Notes intenses de fumée de feu de bois, goudron médical, algues salines, huître, et tourbe sauvage tempérée par des fûts de Bourbon ou Sherry.',
      accentColor: Color(0xFF374151),
      keywords: ['islay', 'laphroaig', 'lagavulin', 'ardbeg', 'bowmore', 'bruichladdich', 'caol ila', 'kilchoman', 'bunnahabhain', 'tourbe', 'peated'],
    ),

    // 7. SPEYSIDE & HIGHLAND WHISKY
    TerroirGeoProfile(
      id: 'spirit_whisky_speyside',
      name: 'Speyside & Highland Single Malt Whisky',
      appellation: 'Speyside Single Malt Scotch Whisky',
      region: 'Écosse / Scotland',
      subRegion: 'Vallée de la Spey / Highlands',
      country: 'Royaume-Uni',
      countryCode: 'GB',
      flag: '🏴󠁧󠁢󠁳󠁣󠁴󠁿',
      center: LatLng(57.4440, -3.1280),
      defaultZoom: 11.0,
      hexRadiusKm: 4.0,
      soilType: 'Socle granitique calédonien et alluvions glaciaires de la rivière Spey',
      climate: 'Subpolaire océanique tempéré, eau de source cristalline des monts Cairngorms',
      exposure: 'Vallons protégés de la Spey bordés de forêts de pins calédoniens',
      elevation: '150 - 500 mètres',
      keyGrapes: '100% Orge maltée (malt non tourbé ou délicatement toasté)',
      classification: 'PGI Scotch Whisky (Speyside / Highlands)',
      sommelierNotes: 'Le cœur historique et prestigieux du whisky écossais. Élégance, rondeur, notes miellées de pomme verte, poire mûre, malt toasté, vanille et fûts de Sherry Oloroso somptueux.',
      accentColor: Color(0xFFB45309),
      keywords: ['speyside', 'whisky', 'whiskey', 'scotch', 'highland', 'highlands', 'macallan', 'glenfiddich', 'balvenie', 'glenlivet', 'aberlour', 'glenmorangie', 'talisker', 'oban', 'dalmore', 'scotland', 'ecosse'],
    ),

    // 8. IRISH WHISKEY
    TerroirGeoProfile(
      id: 'spirit_whiskey_ireland',
      name: 'Irish Whiskey (Midleton & Bushmills)',
      appellation: 'Single Pot Still Irish Whiskey',
      region: 'Irlande',
      subRegion: 'County Cork / County Antrim',
      country: 'Irlande',
      countryCode: 'IE',
      flag: '🇮🇪',
      center: LatLng(51.9160, -8.1720),
      defaultZoom: 11.0,
      hexRadiusKm: 3.5,
      soilType: 'Plaines calcaires herbeuses et tourbières alluvionnaires irlandaises',
      climate: 'Océanique doux et tempéré à fortes précipitations',
      exposure: 'Verdoyantes vallées côtières tempérées du sud et du nord',
      elevation: '20 - 120 mètres',
      keyGrapes: 'Orge maltée et orge crue non maltée (Single Pot Still)',
      classification: 'GI Irish Whiskey (Triple Distillation)',
      sommelierNotes: 'La tradition de la triple distillation en pot still apporte une onctuosité beurrée incomparable, sans aucune agressivité fumée, aux notes d\'épices de cuisson, pêche jaune, fudge et bois noble.',
      accentColor: Color(0xFF047857),
      keywords: ['ireland', 'irlande', 'irish', 'jameson', 'bushmills', 'redbreast', 'midleton', 'teeling', 'pot still', 'tullamore'],
    ),

    // 9. KENTUCKY STRAIGHT BOURBON
    TerroirGeoProfile(
      id: 'spirit_bourbon_kentucky',
      name: 'Kentucky Straight Bourbon Whiskey',
      appellation: 'Kentucky Straight Bourbon Whiskey',
      region: 'Kentucky / Tennessee',
      subRegion: 'Bluegrass Region (Bardstown & Frankfort)',
      country: 'États-Unis',
      countryCode: 'US',
      flag: '🇺🇸',
      center: LatLng(37.8090, -85.4660),
      defaultZoom: 11.0,
      hexRadiusKm: 4.5,
      soilType: 'Plateau calcaire ordovicien filtrant une eau de source exempte de fer',
      climate: 'Continental humide à variations thermiques saisonnières extrêmes',
      exposure: 'Collines ondulantes de la région Bluegrass et vallées de la Kentucky River',
      elevation: '150 - 300 mètres',
      keyGrapes: 'Au moins 51% Maïs jaune, Seigle (Rye), Orge maltée, Blé',
      classification: 'Federal Standard of Identity (Bourbon / Straight Bourbon)',
      sommelierNotes: 'Les étés caniculaires et hivers glacés du Kentucky font respirer les fûts neufs de chêne américain brûlé (char #4), extrayant de puissants arômes de vanille, caramel, érable, maïs toasté et cuir.',
      accentColor: Color(0xFF92400E),
      keywords: ['bourbon', 'kentucky', 'rye', 'tennessee', 'jack daniel', 'jim beam', 'makers mark', 'woodford', 'buffalo trace', 'bulleit', 'knob creek', 'pappy', 'wild turkey', 'america'],
    ),

    // 10. RHUM AGRICOLE DE LA MARTINIQUE
    TerroirGeoProfile(
      id: 'spirit_rhum_martinique',
      name: 'Rhum Agricole de la Martinique & Caraïbes',
      appellation: 'AOC Rhum Agricole de Martinique',
      region: 'Martinique / Caraïbes',
      subRegion: 'Montagne Pelée & Caravelle',
      country: 'France',
      countryCode: 'FR',
      flag: '🇲🇶',
      center: LatLng(14.8160, -61.1660),
      defaultZoom: 11.2,
      hexRadiusKm: 3.8,
      soilType: 'Sols volcaniques andosols riches et fertiles de la Montagne Pelée',
      climate: 'Tropical maritime chaud et humide rythmé par les alizés',
      exposure: 'Versants volcaniques et plaines cannières ensoleillées',
      elevation: '20 - 450 mètres',
      keyGrapes: 'Pur jus frais de canne à sucre broyée (Vesou non raffiné)',
      classification: 'AOC Rhum de Martinique (Seule AOC mondiale du rhum)',
      sommelierNotes: 'Contrairement aux rhums industriels de mélasse, le rhum agricole est distillé à partir du vesou frais. Explosion aromatique de canne fraîche, zeste de lime, fleurs blanches en blanc, et boisé vanillé noble en vieux.',
      accentColor: Color(0xFFEAB308),
      keywords: ['rhum', 'rum', 'martinique', 'guadeloupe', 'agricole', 'clement', 'bally', 'neisson', 'depaz', 'j.m', 'jm', 'damoiseau', 'caraibes', 'caribbean', 'vesou', 'trois rivieres', 'havana', 'diplomatico', 'zacapa', 'plantation', 'bologne'],
    ),

    // 11. TEQUILA & MEZCAL (JALISCO & OAXACA)
    TerroirGeoProfile(
      id: 'spirit_tequila_jalisco',
      name: 'Tequila & Mezcal d\'Agave (Jalisco & Oaxaca)',
      appellation: 'DO Tequila / DO Mezcal',
      region: 'Jalisco / Oaxaca',
      subRegion: 'Valle de Tequila & Los Altos',
      country: 'Mexique',
      countryCode: 'MX',
      flag: '🇲🇽',
      center: LatLng(20.8860, -103.8370),
      defaultZoom: 11.5,
      hexRadiusKm: 3.5,
      soilType: 'Terres volcaniques rouges riches en fer et minéraux du volcan de Tequila',
      climate: 'Semi-aride subtropical avec saisons sèche et pluvieuse bien marquées',
      exposure: 'Plateaux arides et pentes volcaniques sous le volcan Tequila',
      elevation: '1200 - 2100 mètres (Haute altitude)',
      keyGrapes: '100% Agave Tequilana Weber Variedad Azul (cœurs d\'agave / piñas)',
      classification: 'Denominación de Origen Tequila (CRT certifié)',
      sommelierNotes: 'Les piñas d\'agave bleu mûrissent 7 à 10 ans sous le soleil mexicain avant d\'être cuites lentement en fours maçonnés. Arômes végétaux frais, poivre blanc, agave confit, herbes sauvages et minéralité volcanique.',
      accentColor: Color(0xFF15803D),
      keywords: ['tequila', 'mezcal', 'agave', 'jalisco', 'oaxaca', 'mexique', 'mexico', 'don julio', 'patron', 'casamigos', 'clase azul', 'fortaleza', 'herradura', 'siete leguas', 'del maguey'],
    ),

    // 12. LONDON DRY GIN
    TerroirGeoProfile(
      id: 'spirit_gin_london',
      name: 'London Dry Gin & Botanicals',
      appellation: 'London Dry Gin',
      region: 'Royaume-Uni / Europe',
      subRegion: 'Londres & Distilleries Artisanales',
      country: 'Royaume-Uni',
      countryCode: 'GB',
      flag: '🇬🇧',
      center: LatLng(51.5074, -0.1278),
      defaultZoom: 11.8,
      hexRadiusKm: 3.5,
      soilType: 'Bassin alluvionnaire de la Tamise et sources d\'eau pures',
      climate: 'Océanique tempéré maritime',
      exposure: 'Cœur historique de la distillation urbaine britannique',
      elevation: '15 - 40 mètres',
      keyGrapes: 'Alcool neutre redistillé avec baies de genièvre (Juniperus communis), coriandre, angélique, agrumes',
      classification: 'Catégorie Réglementaire Européenne London Dry Gin',
      sommelierNotes: 'Distillation pure sans aucun arôme ni sucre ajouté après alambic. Dominance résineuse et piquante du genièvre, fraîcheur de zeste de citron jaune, racine d\'iris et graines de coriandre.',
      accentColor: Color(0xFF0284C7),
      keywords: ['gin', 'london dry', 'tanqueray', 'bombay', 'hendrick', 'beefeater', 'botanical', 'genievre', 'juniper', 'roku', 'monkey 47', 'citadelle'],
    ),

    // 13. VODKA TRADITION
    TerroirGeoProfile(
      id: 'spirit_vodka_tradition',
      name: 'Vodka de Tradition (Seigle, Blé & Pomme de terre)',
      appellation: 'Vodka Traditionnelle',
      region: 'Europe de l\'Est / Pologne & France',
      subRegion: 'Mazovie & Charente',
      country: 'Pologne',
      countryCode: 'PL',
      flag: '🇵🇱',
      center: LatLng(52.2297, 21.0122),
      defaultZoom: 11.0,
      hexRadiusKm: 4.0,
      soilType: 'Plaines fertiles de Tchernoziom et terres sablo-limoneuses de céréales nobles',
      climate: 'Continental tempéré aux hivers glaciaux',
      exposure: 'Grands plateaux céréaliers d\'Europe centrale',
      elevation: '80 - 200 mètres',
      keyGrapes: 'Seigle d\'or Dankowskie, Blé tendre d\'hiver, Pommes de terre Stobrawa',
      classification: 'Protected Geographical Indication Polska Wódka',
      sommelierNotes: 'Pureté absolue issue de multiples distillations en colonnes et filtrations au charbon de bois. Texture grasse, crémeuse, notes de pain de seigle frais, vanille douce et poivre blanc délicat.',
      accentColor: Color(0xFF64748B),
      keywords: ['vodka', 'belvedere', 'grey goose', 'chopin', 'smirnoff', 'stolichnaya', 'absolut', 'seigle', 'rye vodka', 'wheat vodka'],
    ),
  ];
}
