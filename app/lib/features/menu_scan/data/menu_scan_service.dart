import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/services/gemini_model_registry.dart';
import '../../../shared/utils/app_logger.dart';
import '../../auth/data/ai_cost_tracker_service.dart';
import '../../auth/domain/taste_profile.dart';
import '../domain/menu_wine.dart';
import 'wine_knowledge_cache_service.dart';

final menuScanServiceProvider = Provider<MenuScanService>((ref) {
  final cache = ref.read(wineKnowledgeCacheServiceProvider);
  return MenuScanService(cache);
});

class MenuScanService {
  final WineKnowledgeCacheService _knowledgeCache;
  static const String _geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AQ.Ab8RN6JFZQNPfXmDdjdGT0posCOmn_4wPIFv_TiviorSGL6BDg',
  );

  MenuScanService(this._knowledgeCache);

  /// Helper to load bytes from a path (local file, XFile, or blob/network)
  static Future<Uint8List> _readImageBytes(String imagePath) async {
    if (kIsWeb || imagePath.startsWith('blob:') || imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      try {
        final xfile = XFile(imagePath);
        return await xfile.readAsBytes();
      } catch (_) {
        final uri = Uri.parse(imagePath);
        final res = await http.get(uri);
        if (res.statusCode == 200) return res.bodyBytes;
        throw Exception('Impossible de charger l\'image : HTTP ${res.statusCode}');
      }
    } else {
      try {
        final xfile = XFile(imagePath);
        return await xfile.readAsBytes();
      } catch (_) {
        return await File(imagePath).readAsBytes();
      }
    }
  }

  /// 📸 Analyze multiple menu pages in ONE SINGLE Gemini multimodal request
  Future<ScannedMenu> analyzeMenuPages({
    required List<String> imagePaths,
    List<Uint8List>? imageBytesList,
    String? restaurantNameHint,
    TasteProfile? userTasteProfile,
  }) async {
    final startTime = DateTime.now();
    AppLogger.info('MENU_SCAN', 'Starting multi-page restaurant menu analysis (${imagePaths.length} pages)');

    GeminiModelRegistry.refreshAvailableModels();

    final parts = <Map<String, dynamic>>[];

    // 1. Convert all captured pages into inlineData parts
    final count = imageBytesList != null && imageBytesList.isNotEmpty
        ? imageBytesList.length
        : imagePaths.length;

    for (int i = 0; i < count; i++) {
      Uint8List bytes;
      String mimeType = 'image/jpeg';

      if (imageBytesList != null && i < imageBytesList.length) {
        bytes = imageBytesList[i];
      } else {
        final path = imagePaths[i];
        bytes = await _readImageBytes(path);
        final pLower = path.toLowerCase();
        if (pLower.endsWith('.png')) mimeType = 'image/png';
        if (pLower.endsWith('.webp')) mimeType = 'image/webp';
      }

      parts.add({
        'inlineData': {
          'mimeType': mimeType,
          'data': base64Encode(bytes),
        }
      });
    }

    const systemPrompt = '''You are Chatmelier, the world's most capable sommelier and OCR wine recognition AI.
You are given one or multiple photos of pages from a restaurant's wine menu (carte des vins).
Extract EVERY single wine listed across all provided pages.

For each wine, output a JSON object with:
- "name": Official wine cuvée or name (e.g. "Château Smith Haut Lafitte", "Chablis Premier Cru Fourchaume", "Côtes du Rhône Belleruche").
- "producer": Winery, Domaine, Château, or House.
- "vintage": Integer year (e.g. 2019, 2020) or null if non-vintage (NV/NM).
- "wine_type": "red", "white", "rose", "sparkling", "dessert", or "fortified".
- "appellation": AOC/AOP/DOC or sub-appellation (e.g. "Pessac-Léognan", "Chablis 1er Cru", "Saint-Joseph").
- "region": Broad wine region (e.g. "Bordeaux", "Bourgogne", "Vallée du Rhône", "Loire", "Alsace", "Toscane").
- "country": Country of origin (e.g. "France", "Italie", "Espagne").
- "grapes": Array of strings of grape varieties (e.g. ["Cabernet Sauvignon", "Merlot"] or ["Chardonnay"]).
- "bottle_price": Numeric price for the whole bottle as written on the menu (e.g. 45.0), or null if not available.
- "glass_prices": Array of objects [{"format": "125ml", "price": 7.5}, {"format": "175ml", "price": 10.5}] for all glass sizes mentioned on the menu, or empty array [] if none.
- "metrics": Object with sensory ratings from 1.0 to 10.0:
    - "tannins": 0.0 for white/rosé/sparkling, 1.0 to 10.0 for red (tannic structure).
    - "acidity": 1.0 to 10.0 (freshness, tension, liveliness).
    - "body": 1.0 to 10.0 (fullness, alcohol weight, power).
    - "fruit": 1.0 to 10.0 (aromatic fruitiness and richness).
    - "oak": 1.0 to 10.0 (wood aging, vanilla, toast).
    - "minerality": 1.0 to 10.0 (flinty, chalky, saline terroir character).
    - "butteriness": 0.0 to 10.0 (brioche/buttery lactic notes, typical in oaked Chardonnay).
    - "sweetness": 1.0 to 10.0 (residual sugar).
- "tags": Array of relevant keywords in French from: ["minéral", "beurré", "tannique", "fruité", "léger", "puissant", "boisé", "floral", "épicé", "frais", "rond", "gourmand"].
- "sommelier_comment": 1 sharp sentence in French describing the style and dining occasion.
- "food_pairings": Array of 3 specific restaurant dish pairings (e.g. ["Côte de bœuf grillée", "Bar rôti au fenouil", "Plateau de fromages affinés"]).

Also extract the restaurant name if visible on headers/cover, else return null.
Return STRICTLY a JSON object with:
{
  "restaurant_name": "Name of restaurant if detected or null",
  "wines": [ ... ]
}''';

    parts.add({'text': systemPrompt});

    final requestBody = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': parts,
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
      }
    });

    final activeModels = GeminiModelRegistry.getModelsForTier(GeminiTaskTier.standardFlashPreferred);
    Map<String, dynamic>? parsedJson;
    String? usedModel;

    for (final model in activeModels) {
      try {
        AppLogger.debug('MENU_SCAN', 'Calling Gemini with model $model for ${parts.length - 1} images...');
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_geminiApiKey',
        );

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: requestBody,
        ).timeout(const Duration(seconds: 35));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          String rawText = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '{}';
          if (rawText.contains('```json')) {
            rawText = rawText.split('```json')[1].split('```')[0].trim();
          } else if (rawText.contains('```')) {
            rawText = rawText.split('```')[1].split('```')[0].trim();
          }
          parsedJson = jsonDecode(rawText) as Map<String, dynamic>;
          usedModel = model;

          AiCostTrackerService().recordRawResponse(
            model: model,
            feature: 'menu_scan_vision',
            responseJson: data,
            isSearchGrounded: false,
          );
          break;
        }
      } catch (e) {
        AppLogger.warning('MENU_SCAN', 'Attempt with $model failed: $e. Trying next model...');
      }
    }

    if (parsedJson == null) {
      throw Exception('Impossible d\'extraire les vins du menu avec l\'IA. Veuillez vérifier vos photos et réessayer.');
    }

    final detectedRestaurant = (parsedJson['restaurant_name'] as String?) ?? restaurantNameHint ?? 'Restaurant';
    final rawWinesList = (parsedJson['wines'] as List?) ?? [];
    final extractedWines = <MenuWine>[];
    const uuid = Uuid();

    for (final raw in rawWinesList) {
      final map = Map<String, dynamic>.from(raw as Map);
      final id = uuid.v4();
      final name = (map['name'] ?? 'Vin').toString();
      final producer = (map['producer'] ?? 'Domaine').toString();
      final vintage = map['vintage'] as int?;
      final type = (map['wine_type'] ?? 'red').toString();

      // Check if we already have this wine in our persistent Wine Knowledge Database!
      final cachedKnowledge = await _knowledgeCache.findWine(name, producer, vintage, type);

      MenuWineRadarMetrics metrics;
      List<String> tags;
      List<String> grapes;
      String? sommelierComment;
      List<String> foodPairings;

      if (cachedKnowledge != null) {
        // Reuse cached sensory attributes!
        metrics = cachedKnowledge.metrics;
        tags = cachedKnowledge.tags;
        grapes = cachedKnowledge.grapes;
        sommelierComment = cachedKnowledge.sommelierComment;
        foodPairings = cachedKnowledge.foodPairings;
      } else {
        metrics = map['metrics'] != null
            ? MenuWineRadarMetrics.fromJson(Map<String, dynamic>.from(map['metrics'] as Map))
            : const MenuWineRadarMetrics();
        tags = (map['tags'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
        grapes = (map['grapes'] as List?)?.map((e) => e.toString()).toList() ?? [];
        sommelierComment = map['sommelier_comment'] as String?;
        foodPairings = (map['food_pairings'] as List?)?.map((e) => e.toString()).toList() ?? [];
      }

      final glassPrices = (map['glass_prices'] as List?)
              ?.map((g) => MenuWineGlassPrice.fromJson(Map<String, dynamic>.from(g as Map)))
              .toList() ??
          [];

      final bottlePrice = (map['bottle_price'] as num?)?.toDouble();

      var wine = MenuWine(
        id: id,
        name: name,
        producer: producer,
        vintage: vintage,
        wineType: type,
        appellation: map['appellation'] as String?,
        region: map['region'] as String?,
        country: map['country'] as String?,
        grapes: grapes,
        bottlePrice: bottlePrice,
        glassPrices: glassPrices,
        metrics: metrics,
        tags: tags,
        sommelierComment: sommelierComment,
        foodPairings: foodPairings,
      );

      // If user has a taste profile, compute personalized match score!
      if (userTasteProfile != null) {
        final matchScore = MenuWineMatchCalculator.computeMatchScore(wine, userTasteProfile);
        wine = wine.copyWith(userMatchScore: matchScore);
      }

      extractedWines.add(wine);
    }

    // Persist all recognized wines into the persistent database
    await _knowledgeCache.bulkCache(extractedWines);

    final duration = DateTime.now().difference(startTime).inMilliseconds;
    AppLogger.info('MENU_SCAN', 'Menu analysis finished in ${duration}ms via $usedModel! Extracted ${extractedWines.length} wines.');

    return ScannedMenu(
      id: uuid.v4(),
      restaurantName: detectedRestaurant,
      scannedAt: DateTime.now(),
      pagePhotoPaths: imagePaths,
      wines: extractedWines,
    );
  }

  /// 💬 Contextual Sommelier Chat grounded specifically in this scanned menu
  Future<String> askMenuSommelier({
    required ScannedMenu menu,
    required String userQuestion,
    TasteProfile? userProfile,
  }) async {
    final wineListText = menu.wines.map((w) {
      final priceStr = w.priceDisplay;
      final tagsStr = w.tags.join(', ');
      return '- "${w.name}" (${w.vintage ?? "NM"}), ${w.producer} [${w.wineType}, ${w.region ?? w.appellation ?? ""}] - $priceStr. Profil: $tagsStr. Style: ${w.sommelierComment ?? ""}';
    }).join('\n');

    String profileContext = '';
    if (userProfile != null) {
      profileContext = '''\nProfil de l'utilisateur :
- Aime : ${userProfile.favoriteTypes.join(', ')} / Régions : ${userProfile.favoriteRegions.join(', ')} / Cépages : ${userProfile.favoriteGrapes.join(', ')}
- N'aime pas : ${userProfile.dislikedCharacteristics.join(', ')}
- Notes : ${userProfile.notes.isNotEmpty ? userProfile.notes : 'Non précisé'}''';
    }

    final prompt = '''Tu es Chatmelier, le maître sommelier du restaurant "${menu.restaurantName}".
Voici la carte des vins exacte disponible sur les tables :
$wineListText
$profileContext

Question du client :
"$userQuestion"

Consignes absolues :
1. Réponds en français de façon chaleureuse, précise et experte comme un sommelier à table.
2. Recommande EXCLUSIVEMENT des vins figurant sur la carte ci-dessus. N'invente aucun vin extérieur.
3. Mentionne toujours le prix (à la bouteille ou au verre) tel qu'affiché sur la carte.
4. Explique clairement l'accord mets/vins ou la raison de ton conseil en t'appuyant sur les caractéristiques du vin (tannins, minéralité, vivacité, boisé).
5. Sois concis (2 à 3 paragraphes maximum).''';

    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ]
        }
      ]
    });

    final activeModels = GeminiModelRegistry.getModelsForTier(GeminiTaskTier.standardFlashPreferred);

    for (final model in activeModels) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_geminiApiKey',
        );
        final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        ).timeout(const Duration(seconds: 15));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final answer = data['candidates']?[0]?['content']?[0]?['text'] ??
              data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
              'Désolé, je n\'ai pas pu formuler de réponse.';

          AiCostTrackerService().recordRawResponse(
            model: model,
            feature: 'menu_chat_assistant',
            responseJson: data,
            isSearchGrounded: false,
          );
          return answer.toString().trim();
        }
      } catch (e) {
        AppLogger.warning('MENU_CHAT', 'Chat attempt with $model failed: $e');
      }
    }

    return 'Désolé, impossible de joindre le sommelier IA pour le moment. Veuillez vérifier votre connexion.';
  }
}
