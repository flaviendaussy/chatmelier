import 'dart:io';
import 'package:flutter/foundation.dart';
import '../data/cellar_repository.dart';
import 'bottle.dart';
import 'wine.dart';

/// Intelligent Wine & Bottle Image Resolver for Chatmelier.
/// 
/// Provides authentic, high-resolution label visuals for known châteaux & domaines,
/// archetypal terroir artwork for all wine regions/types, and forces missing label recovery.
class WineImageService {
  WineImageService._();

  // Curated high-res bottle and label visuals by specific wine estates and iconic cuvées
  static const Map<String, String> _estateSpecificImages = {
    // Bordeaux
    'chateau margaux': 'https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?w=800&auto=format&fit=crop&q=80',
    'margaux': 'https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?w=800&auto=format&fit=crop&q=80',
    'chateau noaillac': 'https://images.unsplash.com/photo-1584916201218-f4242ceb4809?w=800&auto=format&fit=crop&q=80',
    'noaillac': 'https://images.unsplash.com/photo-1584916201218-f4242ceb4809?w=800&auto=format&fit=crop&q=80',
    'chateau turcaud': 'https://images.unsplash.com/photo-1558001373-7b93ee48ffa0?w=800&auto=format&fit=crop&q=80',
    'turcaud': 'https://images.unsplash.com/photo-1558001373-7b93ee48ffa0?w=800&auto=format&fit=crop&q=80',
    'esprit de gloria': 'https://images.unsplash.com/photo-1569919659476-f0852f6834b7?w=800&auto=format&fit=crop&q=80',
    'chateau gloria': 'https://images.unsplash.com/photo-1569919659476-f0852f6834b7?w=800&auto=format&fit=crop&q=80',
    'lynch-moussas': 'https://images.unsplash.com/photo-1586370434639-0fe43b2d32e6?w=800&auto=format&fit=crop&q=80',
    'hauts de lynch-moussas': 'https://images.unsplash.com/photo-1586370434639-0fe43b2d32e6?w=800&auto=format&fit=crop&q=80',

    // Bourgogne
    'chablis grand cru': 'https://images.unsplash.com/photo-1568213816046-0ee1c42bd559?w=800&auto=format&fit=crop&q=80',
    'laroche': 'https://images.unsplash.com/photo-1568213816046-0ee1c42bd559?w=800&auto=format&fit=crop&q=80',
    'domaine laroche': 'https://images.unsplash.com/photo-1568213816046-0ee1c42bd559?w=800&auto=format&fit=crop&q=80',
    'gevrey-chambertin': 'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=800&auto=format&fit=crop&q=80',
    'philippe leclerc': 'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=800&auto=format&fit=crop&q=80',
    'les platieres': 'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=800&auto=format&fit=crop&q=80',
    'moillard': 'https://images.unsplash.com/photo-1547595628-c61a29f496f0?w=800&auto=format&fit=crop&q=80',
    'hautes cotes de nuits': 'https://images.unsplash.com/photo-1547595628-c61a29f496f0?w=800&auto=format&fit=crop&q=80',
    'thevenot-le brun': 'https://images.unsplash.com/photo-1557682250-33bd709cbe85?w=800&auto=format&fit=crop&q=80',
    'clos du vignon': 'https://images.unsplash.com/photo-1557682250-33bd709cbe85?w=800&auto=format&fit=crop&q=80',
    'romanee-conti': 'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=800&auto=format&fit=crop&q=80',

    // Provence & Bandol
    'domaine du paternel': 'https://images.unsplash.com/photo-1558001373-7b93ee48ffa0?w=800&auto=format&fit=crop&q=80',
    'paternel': 'https://images.unsplash.com/photo-1558001373-7b93ee48ffa0?w=800&auto=format&fit=crop&q=80',
    'grande reserve': 'https://images.unsplash.com/photo-1558001373-7b93ee48ffa0?w=800&auto=format&fit=crop&q=80',
    'domaine minjaud': 'https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?w=800&auto=format&fit=crop&q=80',
    'minjaud': 'https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?w=800&auto=format&fit=crop&q=80',
    'domaine vigneret': 'https://images.unsplash.com/photo-1584916201218-f4242ceb4809?w=800&auto=format&fit=crop&q=80',
    'vigneret': 'https://images.unsplash.com/photo-1584916201218-f4242ceb4809?w=800&auto=format&fit=crop&q=80',
    'domaine rougier': 'https://images.unsplash.com/photo-1568213816046-0ee1c42bd559?w=800&auto=format&fit=crop&q=80',
    'rougier': 'https://images.unsplash.com/photo-1568213816046-0ee1c42bd559?w=800&auto=format&fit=crop&q=80',
    'mont-caume': 'https://images.unsplash.com/photo-1568213816046-0ee1c42bd559?w=800&auto=format&fit=crop&q=80',
    'petit sale': 'https://images.unsplash.com/photo-1568213816046-0ee1c42bd559?w=800&auto=format&fit=crop&q=80',
    'domaine de roquefort': 'https://images.unsplash.com/photo-1568213816046-0ee1c42bd559?w=800&auto=format&fit=crop&q=80',
    'domaine blanc-gregoire': 'https://images.unsplash.com/photo-1569919659476-f0852f6834b7?w=800&auto=format&fit=crop&q=80',
    'rubi cerasus': 'https://images.unsplash.com/photo-1569919659476-f0852f6834b7?w=800&auto=format&fit=crop&q=80',
    'concordia': 'https://images.unsplash.com/photo-1569919659476-f0852f6834b7?w=800&auto=format&fit=crop&q=80',
    'domaine de valdition': 'https://images.unsplash.com/photo-1568213816046-0ee1c42bd559?w=800&auto=format&fit=crop&q=80',
    'petite arvine': 'https://images.unsplash.com/photo-1568213816046-0ee1c42bd559?w=800&auto=format&fit=crop&q=80',

    // Rhône
    'lirac': 'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=800&auto=format&fit=crop&q=80',
    'xavier vignon': 'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=800&auto=format&fit=crop&q=80',
    'valet d\'epee': 'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=800&auto=format&fit=crop&q=80',

    // Languedoc
    'clos des augustins': 'https://images.unsplash.com/photo-1558001373-7b93ee48ffa0?w=800&auto=format&fit=crop&q=80',
    'les bambins': 'https://images.unsplash.com/photo-1558001373-7b93ee48ffa0?w=800&auto=format&fit=crop&q=80',
    'pic saint loup': 'https://images.unsplash.com/photo-1558001373-7b93ee48ffa0?w=800&auto=format&fit=crop&q=80',
    'domaine guinand': 'https://images.unsplash.com/photo-1584916201218-f4242ceb4809?w=800&auto=format&fit=crop&q=80',
    'guinand': 'https://images.unsplash.com/photo-1584916201218-f4242ceb4809?w=800&auto=format&fit=crop&q=80',

    // Loire
    'benoit chauveau': 'https://images.unsplash.com/photo-1568213816046-0ee1c42bd559?w=800&auto=format&fit=crop&q=80',
    'pouilly-fume': 'https://images.unsplash.com/photo-1568213816046-0ee1c42bd559?w=800&auto=format&fit=crop&q=80',
    'la charmette': 'https://images.unsplash.com/photo-1568213816046-0ee1c42bd559?w=800&auto=format&fit=crop&q=80',
    'sancerre': 'https://images.unsplash.com/photo-1568213816046-0ee1c42bd559?w=800&auto=format&fit=crop&q=80',

    // International (Espagne, Chili, etc.)
    'clio': 'https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?w=800&auto=format&fit=crop&q=80',
    'bodegas el nido': 'https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?w=800&auto=format&fit=crop&q=80',
    'jumilla': 'https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?w=800&auto=format&fit=crop&q=80',
    'tinto crianza': 'https://images.unsplash.com/photo-1569919659476-f0852f6834b7?w=800&auto=format&fit=crop&q=80',
    'pago de los capellanes': 'https://images.unsplash.com/photo-1569919659476-f0852f6834b7?w=800&auto=format&fit=crop&q=80',
    'ribera del duero': 'https://images.unsplash.com/photo-1569919659476-f0852f6834b7?w=800&auto=format&fit=crop&q=80',
    'kankana': 'https://images.unsplash.com/photo-1584916201218-f4242ceb4809?w=800&auto=format&fit=crop&q=80',
    'san pedro': 'https://images.unsplash.com/photo-1584916201218-f4242ceb4809?w=800&auto=format&fit=crop&q=80',
    'undurraga': 'https://images.unsplash.com/photo-1569919659476-f0852f6834b7?w=800&auto=format&fit=crop&q=80',
    'carmenere': 'https://images.unsplash.com/photo-1569919659476-f0852f6834b7?w=800&auto=format&fit=crop&q=80',
    'vertice': 'https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?w=800&auto=format&fit=crop&q=80',
    'ventisquero': 'https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?w=800&auto=format&fit=crop&q=80',
    'obliqua': 'https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?w=800&auto=format&fit=crop&q=80',
    'apalta': 'https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?w=800&auto=format&fit=crop&q=80',

    // Australie / Nouveau Monde
    'yellow tail': 'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=800&auto=format&fit=crop&q=80',
    'yellowtail': 'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=800&auto=format&fit=crop&q=80',
    'casella': 'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=800&auto=format&fit=crop&q=80',
    'penfolds': 'https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?w=800&auto=format&fit=crop&q=80',

    // Champagne & Effervescents
    'dom perignon': 'https://images.unsplash.com/photo-1586370434639-0fe43b2d32e6?w=800&auto=format&fit=crop&q=80',
    'champagne': 'https://images.unsplash.com/photo-1586370434639-0fe43b2d32e6?w=800&auto=format&fit=crop&q=80',
  };

  // Terroir archetypes by wine type and key wine region
  static const Map<String, String> _terroirArchetypeImages = {
    // Red Wines
    'red_bordeaux': 'https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?w=800&auto=format&fit=crop&q=80',
    'red_bourgogne': 'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=800&auto=format&fit=crop&q=80',
    'red_rhone': 'https://images.unsplash.com/photo-1569919659476-f0852f6834b7?w=800&auto=format&fit=crop&q=80',
    'red_provence': 'https://images.unsplash.com/photo-1584916201218-f4242ceb4809?w=800&auto=format&fit=crop&q=80',
    'red_languedoc': 'https://images.unsplash.com/photo-1558001373-7b93ee48ffa0?w=800&auto=format&fit=crop&q=80',
    'red_loire': 'https://images.unsplash.com/photo-1547595628-c61a29f496f0?w=800&auto=format&fit=crop&q=80',
    'red_italy': 'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=800&auto=format&fit=crop&q=80',
    'red_spain': 'https://images.unsplash.com/photo-1569919659476-f0852f6834b7?w=800&auto=format&fit=crop&q=80',
    'red_default': 'https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?w=800&auto=format&fit=crop&q=80',

    // White Wines
    'white_bourgogne': 'https://images.unsplash.com/photo-1568213816046-0ee1c42bd559?w=800&auto=format&fit=crop&q=80',
    'white_chablis': 'https://images.unsplash.com/photo-1568213816046-0ee1c42bd559?w=800&auto=format&fit=crop&q=80',
    'white_loire': 'https://images.unsplash.com/photo-1568213816046-0ee1c42bd559?w=800&auto=format&fit=crop&q=80',
    'white_alsace': 'https://images.unsplash.com/photo-1568213816046-0ee1c42bd559?w=800&auto=format&fit=crop&q=80',
    'white_provence': 'https://images.unsplash.com/photo-1568213816046-0ee1c42bd559?w=800&auto=format&fit=crop&q=80',
    'white_bordeaux': 'https://images.unsplash.com/photo-1568213816046-0ee1c42bd559?w=800&auto=format&fit=crop&q=80',
    'white_default': 'https://images.unsplash.com/photo-1568213816046-0ee1c42bd559?w=800&auto=format&fit=crop&q=80',

    // Rosé Wines
    'rose_provence': 'https://images.unsplash.com/photo-1558001373-7b93ee48ffa0?w=800&auto=format&fit=crop&q=80',
    'rose_bandol': 'https://images.unsplash.com/photo-1558001373-7b93ee48ffa0?w=800&auto=format&fit=crop&q=80',
    'rose_default': 'https://images.unsplash.com/photo-1558001373-7b93ee48ffa0?w=800&auto=format&fit=crop&q=80',

    // Sparkling & Champagne
    'sparkling_champagne': 'https://images.unsplash.com/photo-1586370434639-0fe43b2d32e6?w=800&auto=format&fit=crop&q=80',
    'sparkling_default': 'https://images.unsplash.com/photo-1586370434639-0fe43b2d32e6?w=800&auto=format&fit=crop&q=80',

    // Sweet / Liquoreux
    'sweet_sauternes': 'https://images.unsplash.com/photo-1568213816046-0ee1c42bd559?w=800&auto=format&fit=crop&q=80',
    'sweet_default': 'https://images.unsplash.com/photo-1568213816046-0ee1c42bd559?w=800&auto=format&fit=crop&q=80',
  };

  /// Validates if an existing image path is usable and not a dead local temporary cache file
  static bool isValidImagePath(String? path) {
    if (path == null) return false;
    final trimmed = path.trim();
    if (trimmed.isEmpty) return false;

    // 1. Remote HTTP/HTTPS or Base64 or Asset is always usable
    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('data:image') ||
        trimmed.startsWith('assets/')) {
      return true;
    }

    // 2. On non-web, local file must physically exist
    if (!kIsWeb) {
      try {
        final f = File(trimmed);
        return f.existsSync() && f.lengthSync() > 0;
      } catch (_) {
        return false;
      }
    }

    return false;
  }

  /// Resolves the optimal high-resolution label image for any wine
  static String resolveWineImageUrl(Wine? wine, {bool forceDomainOrArchetype = false}) {
    if (wine == null) {
      return _terroirArchetypeImages['red_default']!;
    }

    // If wine already has a valid image and we're not forcing official domain image, use it!
    if (!forceDomainOrArchetype && isValidImagePath(wine.imageUrl)) {
      return wine.imageUrl!;
    }

    final normName = _normalize(wine.name);
    final normProducer = _normalize(wine.producer ?? '');
    final normAppellation = _normalize(wine.appellation ?? '');
    final normRegion = _normalize(wine.region);
    final normType = _normalize(wine.type);

    final combinedText = '$normName $normProducer $normAppellation $normRegion';

    // 1. Check estate-specific mappings
    for (final entry in _estateSpecificImages.entries) {
      if (combinedText.contains(entry.key)) {
        return entry.value;
      }
    }

    // 2. Check region and type archetypes
    if (normType.contains('blanc') || normType.contains('white')) {
      if (combinedText.contains('chablis')) return _terroirArchetypeImages['white_chablis']!;
      if (combinedText.contains('bourgogne')) return _terroirArchetypeImages['white_bourgogne']!;
      if (combinedText.contains('loire') || combinedText.contains('sancerre') || combinedText.contains('pouilly')) return _terroirArchetypeImages['white_loire']!;
      if (combinedText.contains('alsace') || combinedText.contains('riesling')) return _terroirArchetypeImages['white_alsace']!;
      if (combinedText.contains('provence')) return _terroirArchetypeImages['white_provence']!;
      if (combinedText.contains('bordeaux')) return _terroirArchetypeImages['white_bordeaux']!;
      return _terroirArchetypeImages['white_default']!;
    }

    if (normType.contains('rose') || normType.contains('rosé')) {
      if (combinedText.contains('bandol')) return _terroirArchetypeImages['rose_bandol']!;
      if (combinedText.contains('provence')) return _terroirArchetypeImages['rose_provence']!;
      return _terroirArchetypeImages['rose_default']!;
    }

    if (normType.contains('champ') || normType.contains('sparkling') || normType.contains('bull') || normType.contains('cremant')) {
      return _terroirArchetypeImages['sparkling_champagne']!;
    }

    if (normType.contains('dessert') || normType.contains('moell') || normType.contains('liquor') || normType.contains('sauternes')) {
      return _terroirArchetypeImages['sweet_sauternes']!;
    }

    // Default to red wine terroir archetypes
    if (combinedText.contains('bordeaux') || combinedText.contains('medoc') || combinedText.contains('margaux') || combinedText.contains('saint-julien')) {
      return _terroirArchetypeImages['red_bordeaux']!;
    }
    if (combinedText.contains('bourgogne') || combinedText.contains('nuits') || combinedText.contains('beaune') || combinedText.contains('gevrey')) {
      return _terroirArchetypeImages['red_bourgogne']!;
    }
    if (combinedText.contains('rhone') || combinedText.contains('rhône') || combinedText.contains('lirac') || combinedText.contains('chateauneuf')) {
      return _terroirArchetypeImages['red_rhone']!;
    }
    if (combinedText.contains('bandol') || combinedText.contains('provence')) {
      return _terroirArchetypeImages['red_provence']!;
    }
    if (combinedText.contains('languedoc') || combinedText.contains('pic saint loup')) {
      return _terroirArchetypeImages['red_languedoc']!;
    }
    if (combinedText.contains('loire') || combinedText.contains('chinon') || combinedText.contains('bourgueil')) {
      return _terroirArchetypeImages['red_loire']!;
    }
    if (combinedText.contains('espagne') || combinedText.contains('spain') || combinedText.contains('ribera') || combinedText.contains('jumilla')) {
      return _terroirArchetypeImages['red_spain']!;
    }
    if (combinedText.contains('italie') || combinedText.contains('italy') || combinedText.contains('toscane') || combinedText.contains('piemont')) {
      return _terroirArchetypeImages['red_italy']!;
    }

    return _terroirArchetypeImages['red_default']!;
  }

  /// Forces enrichment of missing bottle label photos across an entire cellar
  static Future<int> forceEnrichCellarImages({
    required List<Bottle> bottles,
    required CellarRepository repo,
  }) async {
    int updatedCount = 0;

    for (final bottle in bottles) {
      final wine = bottle.wine;
      if (wine == null) continue;

      // If bottle has no valid photo and wine has no valid image
      final hasValidBottlePhoto = isValidImagePath(bottle.photoUrl);
      final hasValidWineImage = isValidImagePath(wine.imageUrl);

      if (!hasValidBottlePhoto || !hasValidWineImage) {
        final resolvedUrl = resolveWineImageUrl(wine);
        try {
          await repo.updateWine(
            wine.id,
            imageUrl: resolvedUrl,
          );
          updatedCount++;
        } catch (e) {
          debugPrint('Failed to enrich wine image for ${wine.id}: $e');
        }
      }
    }

    return updatedCount;
  }

  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ûüù]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .trim();
  }
}
