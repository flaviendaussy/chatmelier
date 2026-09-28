import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../config/constants.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/services/gemini_model_registry.dart';
import '../../../shared/utils/app_logger.dart';
import '../../auth/data/ai_cost_tracker_service.dart';
import '../../auth/domain/taste_profile.dart';
import '../../scan/data/label_image_optimizer.dart';
import '../domain/menu_flagging_engine.dart';
import '../domain/menu_wine.dart';
import 'wine_knowledge_cache_service.dart';

final menuScanServiceProvider = Provider<MenuScanService>((ref) {
  final cache = ref.read(wineKnowledgeCacheServiceProvider);
  final client = ref.read(supabaseProvider);
  return MenuScanService(cache, client);
});

class MenuScanService {
  final WineKnowledgeCacheService _knowledgeCache;
  final SupabaseClient? _supabaseClient;
  static const String _geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: AppConstants.geminiApiKey,
  );

  MenuScanService(this._knowledgeCache, [this._supabaseClient]);

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
    String languageCode = 'fr',
    void Function(String step)? onStepUpdate,
  }) async {
    final startTime = DateTime.now();
    AppLogger.info('MENU_SCAN', 'Starting multi-page restaurant menu analysis (${imagePaths.length} pages, lang=$languageCode)');
    final isEn = languageCode.toLowerCase().startsWith('en');
    onStepUpdate?.call(isEn ? 'Chatmelier is analyzing the wine menu...' : 'Chatmelier analyse le menu...');

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
      }

      // Optimize & downsample image to prevent HTTP 413 / huge payloads while keeping text ultra-crisp
      try {
        final optimized = LabelImageOptimizer.optimize(bytes, autoCrop: false, maxDimension: 2560);
        bytes = optimized.bytes;
        mimeType = 'image/jpeg';
      } catch (e) {
        AppLogger.warning('MENU_SCAN', 'Image optimization skipped for page $i: $e');
      }

      parts.add({
        'inlineData': {
          'mimeType': mimeType,
          'data': base64Encode(bytes),
        }
      });
    }

    final langInstructions = isEn
        ? '''- "tags": Array of relevant keywords in English from: ["mineral", "buttery", "tannic", "fruity", "light", "bold", "oaky", "floral", "spicy", "fresh", "round", "savory"].
- "sommelier_comment": 1 sharp sentence in English describing the style and dining occasion.
- "food_pairings": Array of 3 specific restaurant dish pairings in English (e.g. ["Grilled ribeye steak", "Roasted sea bass with fennel", "Aged artisan cheese board"]).
- "is_gem": boolean. True if this wine is from an acclaimed artisan domain, biodynamic star, cult producer, or exceptional hidden gem.
- "gem_reason": Short reason in English why this is a gem (e.g. "Biodynamic cult superstar", "Rare sought-after parcel"), or null.
- "is_deal": boolean. True if this bottle represents an outstanding value / bargain (unusually low restaurant markup or exceptional price-to-pleasure ratio).
- "deal_reason": Short reason in English why this is a deal (e.g. "Outstanding price very close to cellar door cost", "Exceptional markup advantage"), or null.'''
        : '''- "tags": Array of relevant keywords in French from: ["minéral", "beurré", "tannique", "fruité", "léger", "puissant", "boisé", "floral", "épicé", "frais", "rond", "gourmand"].
- "sommelier_comment": 1 sharp sentence in French describing the style and dining occasion.
- "food_pairings": Array of 3 specific restaurant dish pairings (e.g. ["Côte de bœuf grillée", "Bar rôti au fenouil", "Plateau de fromages affinés"]).
- "is_gem": boolean. True if this wine is from an acclaimed artisan domain, biodynamic star, cult producer, or exceptional hidden gem.
- "gem_reason": Short reason in French why this is a gem (e.g. "Vigneron star en biodynamie", "Domaine confidentiel très recherché"), or null.
- "is_deal": boolean. True if this bottle represents an outstanding value / bargain / "grosse affaire" (unusually low restaurant markup or great quality-to-price ratio).
- "deal_reason": Short reason in French why this is a deal (e.g. "Tarif exceptionnel très proche du prix domaine", "Superbe rapport prix/plaisir", "Coefficient multiplicateur très avantageux"), or null.''';

    final systemPrompt = '''You are Chatmelier, the world's most capable sommelier and OCR wine recognition AI.
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
$langInstructions
- "estimated_retail_price": Estimated typical retail/merchant price in euros (e.g. 18.0) or null.

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

    // Prioritize high-throughput, fast responsive multimodal vision models with broad fallbacks
    final registryModels = GeminiModelRegistry.getModelsForTier(GeminiTaskTier.standardFlashPreferred);
    final candidateModels = <String>[
      'gemini-3.8-flash',
      'gemini-3.6-flash',
      'gemini-3.5-flash',
      'gemini-flash-latest',
      ...registryModels,
    ].toSet().toList();

    Map<String, dynamic>? parsedJson;
    String? usedModel;

    // Fast-path: if direct Gemini API key is empty, invoke Supabase Edge Function directly!
    if (_geminiApiKey.trim().isEmpty) {
      AppLogger.info('MENU_SCAN', 'Direct Gemini API key not configured, calling Supabase Edge Function scan-menu...');
      onStepUpdate?.call(isEn ? 'Analyzing wine list via Chatmelier Cloud...' : 'Analyse de la carte des vins via le Cloud Chatmelier...');
      parsedJson = await _analyserPagesEnParallele(parts, languageCode, restaurantNameHint, onStepUpdate, isEn);
      usedModel = parsedJson?['modele'] as String?;
    } else {
      for (final model in candidateModels) {
        try {
          AppLogger.debug('MENU_SCAN', 'Calling Gemini with model $model for ${parts.length - 1} images...');
          onStepUpdate?.call(isEn ? 'Optical recognition of wines, estates & vintages...' : 'Déchiffrage optique des cuvées, producteurs et millésimes...');
          final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_geminiApiKey',
          );

          final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          ).timeout(const Duration(seconds: 55));

          if (response.statusCode == 200) {
            onStepUpdate?.call(isEn ? 'Extracting prices, pairings & sensory profiles...' : 'Extraction des prix, accords mets & vins et profils sensoriels...');
            final data = jsonDecode(response.body);
            String rawText = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '{}';
            if (rawText.contains('```json')) {
              rawText = rawText.split('```json')[1].split('```')[0].trim();
            } else if (rawText.contains('```')) {
              rawText = rawText.split('```')[1].split('```')[0].trim();
            }

            try {
              parsedJson = jsonDecode(rawText) as Map<String, dynamic>;
            } catch (_) {
              // Robust repair for minor JSON quirks (trailing commas, unbalanced braces)
              var repaired = rawText.replaceAll(RegExp(r',\s*\}'), '}').replaceAll(RegExp(r',\s*\]'), ']');
              final start = repaired.indexOf('{');
              final end = repaired.lastIndexOf('}');
              if (start != -1 && end != -1 && end > start) {
                repaired = repaired.substring(start, end + 1);
              }
              parsedJson = jsonDecode(repaired) as Map<String, dynamic>;
            }

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

      // If direct Gemini calls failed, try Supabase Edge Function fallback!
      if (parsedJson == null) {
        AppLogger.info('MENU_SCAN', 'Direct Gemini calls failed. Falling back to Supabase Edge Function scan-menu...');
        onStepUpdate?.call(isEn ? 'Analyzing wine list via Chatmelier Cloud fallback...' : 'Analyse de secours via le Cloud Chatmelier...');
        parsedJson = await _analyserPagesEnParallele(parts, languageCode, restaurantNameHint, onStepUpdate, isEn);
        usedModel = parsedJson?['modele'] as String?;
      }
    }

    if (parsedJson == null) {
      throw Exception('Impossible d\'extraire les vins du menu avec l\'IA. Veuillez vérifier vos photos et réessayer.');
    }

    onStepUpdate?.call('Vérification dans la cave de connaissances Chatmelier...');

    final detectedRestaurant = (parsedJson['restaurant_name'] as String?) ?? restaurantNameHint ?? 'Restaurant';
    final devise = ScannedMenu.normaliserDevise(parsedJson['currency']);
    final pagesNonLues = (parsedJson['pages_non_lues'] as num?)?.toInt() ?? 0;
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
      final isGem = (map['is_gem'] as bool?) ?? false;
      final gemReason = map['gem_reason'] as String?;
      final isDeal = (map['is_deal'] as bool?) ?? false;
      final dealReason = map['deal_reason'] as String?;
      final estimatedRetailPrice = (map['estimated_retail_price'] as num?)?.toDouble();

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
        isGem: isGem,
        gemReason: gemReason,
        isDeal: isDeal,
        dealReason: dealReason,
        estimatedRetailPrice: estimatedRetailPrice,
        devise: devise,
      );

      // If user has a taste profile, compute personalized match score!
      if (userTasteProfile != null) {
        final matchScore = MenuWineMatchCalculator.computeMatchScore(wine, userTasteProfile);
        wine = wine.copyWith(userMatchScore: matchScore);
      }

      extractedWines.add(wine);
    }

    // Apply smart sommelier highlight flags (Deals, Gems, Taste Matches) with quota
    final flaggedWines = MenuFlaggingEngine.applyFlags(extractedWines, userTasteProfile);

    // Persist all recognized wines into the persistent database
    await _knowledgeCache.bulkCache(flaggedWines);

    final duration = DateTime.now().difference(startTime).inMilliseconds;
    AppLogger.info('MENU_SCAN',
        'Menu analysis finished in ${duration}ms via $usedModel! Extracted ${flaggedWines.length} wines '
        '(currency: ${devise ?? 'unknown'}, unread pages: $pagesNonLues).');

    return ScannedMenu(
      id: uuid.v4(),
      restaurantName: detectedRestaurant,
      scannedAt: DateTime.now(),
      pagePhotoPaths: imagePaths,
      wines: flaggedWines,
      currency: devise,
      pagesNonLues: pagesNonLues,
    );
  }

  /// Une page par appel à `scan-menu`, toutes en parallèle, puis fusion.
  ///
  /// La durée d'un scan suit le nombre de vins, pas le nombre de photos : 12 vins en
  /// 12 à 18 s, 27 à 29 vins en 38 à 50 s (journaux du 04/09 au 26/09). Envoyées ensemble,
  /// les pages d'une longue carte dépassaient le délai d'abandon du client — les échecs du
  /// 18/09 et du 25/09. Séparément, chacune reste dans la fourchette courte, et le tout
  /// dure le temps de la plus lente. Une page illisible n'emporte plus les autres : elle est
  /// comptée dans `pages_non_lues` et l'écran de résultat le signale.
  Future<Map<String, dynamic>?> _analyserPagesEnParallele(
    List<Map<String, dynamic>> parts,
    String languageCode,
    String? restaurantNameHint,
    void Function(String step)? onStepUpdate,
    bool isEn,
  ) async {
    final pages = parts.where((p) => p['inlineData'] != null).toList();
    if (pages.length <= 1) {
      return _invokeEdgeFunction(pages, languageCode, restaurantNameHint);
    }

    var lues = 0;
    final resultats = await Future.wait(pages.map((page) async {
      final r = await _invokeEdgeFunction([page], languageCode, restaurantNameHint);
      lues++;
      onStepUpdate?.call(isEn
          ? 'Page $lues of ${pages.length} read…'
          : 'Page $lues sur ${pages.length} déchiffrée…');
      return r;
    }));

    final valides = resultats.whereType<Map<String, dynamic>>().toList();
    if (valides.isEmpty) return null;
    return fusionnerPagesDeCarte(valides, pagesDemandees: pages.length);
  }

  /// Fusionne les lectures page par page d'une même carte.
  ///
  /// Un vin présent sur deux pages — la liste au verre et la liste à la bouteille — n'est
  /// gardé qu'une fois, avec ses deux prix.
  @visibleForTesting
  static Map<String, dynamic> fusionnerPagesDeCarte(
    List<Map<String, dynamic>> pages, {
    required int pagesDemandees,
  }) {
    final vins = <String, Map<String, dynamic>>{};
    for (final page in pages) {
      for (final brut in (page['wines'] as List?) ?? const []) {
        final vin = Map<String, dynamic>.from(brut as Map);
        final cle = [vin['name'], vin['producer'], vin['vintage']]
            .map((v) => (v ?? '').toString().trim().toLowerCase())
            .join('|');
        final deja = vins[cle];
        if (deja == null) {
          vins[cle] = vin;
          continue;
        }
        deja['bottle_price'] ??= vin['bottle_price'];
        final verres = [...?(deja['glass_prices'] as List?), ...?(vin['glass_prices'] as List?)];
        final formats = <String>{};
        deja['glass_prices'] = [
          for (final g in verres)
            if (formats.add('${(g as Map)['format']}')) g,
        ];
      }
    }

    String? premier(String cle) => pages
        .map((p) => p[cle])
        .whereType<String>()
        .where((v) => v.trim().isNotEmpty)
        .firstOrNull;

    return {
      'restaurant_name': premier('restaurant_name'),
      'currency': premier('currency'),
      'modele': premier('modele'),
      'wines': vins.values.toList(),
      'pages_non_lues': pagesDemandees - pages.length,
    };
  }

  /// 💬 Contextual Sommelier Chat grounded specifically in this scanned menu
  Future<String> askMenuSommelier({
    required ScannedMenu menu,
    required String userQuestion,
    TasteProfile? userProfile,
    String languageCode = 'fr',
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

    // Sans clé embarquée (tous les builds publiés depuis le 14/09), seule la fonction edge
    // peut répondre. L'appel direct ci-dessous n'existe plus que pour le développement :
    // c'est lui qui échouait en silence le 23/09 à 19h07.
    final isEn = languageCode.toLowerCase().startsWith('en');
    final injoignable = isEn
        ? 'Sorry, the sommelier cannot be reached right now. Please check your connection and try again.'
        : 'Désolé, impossible de joindre le sommelier IA pour le moment. Vérifiez votre connexion et réessayez.';
    if (_geminiApiKey.trim().isEmpty) {
      return await _demanderAuSommelierDistant(
        menu: menu,
        question: userQuestion,
        carte: wineListText,
        profil: profileContext,
        languageCode: languageCode,
      ) ??
          injoignable;
    }

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

        if (res.statusCode != 200) {
          AppLogger.warning('MENU_CHAT',
              'Chat attempt with $model returned HTTP ${res.statusCode}: ${res.body.length > 200 ? res.body.substring(0, 200) : res.body}');
        }
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

    AppLogger.error('MENU_CHAT', 'Every direct menu chat attempt failed');
    return injoignable;
  }

  /// Pose la question à la fonction edge `menu-chat`, qui détient la clé Gemini.
  ///
  /// Chaque échec est journalisé avec sa cause : le 23/09, l'écran affichait « injoignable »
  /// sans une ligne dans les journaux, et l'incident était indiagnosticable.
  Future<String?> _demanderAuSommelierDistant({
    required ScannedMenu menu,
    required String question,
    required String carte,
    required String profil,
    required String languageCode,
  }) async {
    final client = _supabaseClient ?? (Supabase.instance.isInitialized ? Supabase.instance.client : null);
    if (client == null) {
      AppLogger.error('MENU_CHAT', 'Supabase client not available for menu-chat');
      return null;
    }
    final debut = DateTime.now();
    try {
      final res = await client.functions.invoke('menu-chat', body: {
        'question': question,
        'carte': carte,
        'profil': profil,
        'restaurantName': menu.restaurantName,
        'languageCode': languageCode,
      }).timeout(const Duration(seconds: 60));

      final data = res.data;
      final reponse = data is Map ? data['reponse'] as String? : null;
      if (reponse == null || reponse.trim().isEmpty) {
        AppLogger.error('MENU_CHAT', 'menu-chat returned no answer (status ${res.status}): $data');
        return null;
      }
      final modele = data['modele'] as String?;
      if (modele != null && data['usageMetadata'] is Map) {
        AiCostTrackerService().recordRawResponse(
          model: modele,
          feature: 'menu_chat_assistant',
          responseJson: {'usageMetadata': data['usageMetadata']},
          isSearchGrounded: false,
        );
      }
      // La question et le début de la réponse : la console d'administration les montre
      // dans le fil de la personne (phase de test — à retirer avant la production).
      String extrait(String t) => t.length > 300 ? '${t.substring(0, 300)}…' : t;
      AppLogger.info('MENU_CHAT',
          'menu-chat answered in ${DateTime.now().difference(debut).inMilliseconds}ms via $modele'
          ' — Q : ${extrait(question)} — R : ${extrait(reponse.trim())}');
      return reponse.trim();
    } catch (e, stack) {
      AppLogger.error('MENU_CHAT',
          'menu-chat failed after ${DateTime.now().difference(debut).inMilliseconds}ms: $e', e, stack);
      return null;
    }
  }

  Future<Map<String, dynamic>?> _invokeEdgeFunction(
    List<Map<String, dynamic>> parts,
    String languageCode,
    String? restaurantNameHint,
  ) async {
    final client = _supabaseClient ?? (Supabase.instance.isInitialized ? Supabase.instance.client : null);
    if (client == null) {
      AppLogger.warning('MENU_SCAN', 'Supabase client not available for scan-menu fallback');
      return null;
    }

    try {
      final imagesBase64 = <String>[];
      for (final part in parts) {
        final inlineData = part['inlineData'];
        if (inlineData is Map && inlineData['data'] is String) {
          imagesBase64.add(inlineData['data'] as String);
        }
      }

      if (imagesBase64.isEmpty) {
        AppLogger.warning('MENU_SCAN', 'No base64 image data found for scan-menu edge function');
        return null;
      }

      AppLogger.info('MENU_SCAN', 'Invoking Supabase Edge Function scan-menu with ${imagesBase64.length} image(s)...');
      final debut = DateTime.now();
      // 150 s : la limite de durée d'une fonction edge. Abandonner avant ne fait rien
      // gagner — le serveur va au bout et facture l'appel quand même (18/09, 25/09).
      final res = await client.functions.invoke('scan-menu', body: {
        'imagesBase64': imagesBase64,
        'languageCode': languageCode,
        'restaurantNameHint': restaurantNameHint,
      }).timeout(_delaiScanMenu);

      if (res.data != null && res.data is Map) {
        final data = Map<String, dynamic>.from(res.data as Map);
        final modele = data['modele'] as String?;
        if (modele != null && data['usageMetadata'] is Map) {
          AiCostTrackerService().recordRawResponse(
            model: modele,
            feature: 'menu_scan_vision',
            responseJson: {'usageMetadata': data['usageMetadata']},
            isSearchGrounded: false,
          );
        }
        AppLogger.info('MENU_SCAN',
            'scan-menu answered in ${DateTime.now().difference(debut).inMilliseconds}ms via $modele '
            '(${(data['wines'] as List?)?.length ?? 0} wines)');
        return data;
      }
      AppLogger.warning('MENU_SCAN', 'scan-menu returned no usable body (status ${res.status})');
    } catch (e, stack) {
      AppLogger.error('MENU_SCAN', 'Edge function scan-menu error: $e', e, stack);
    }
    return null;
  }

  static const _delaiScanMenu = Duration(seconds: 150);
}
