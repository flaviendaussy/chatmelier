import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../config/constants.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/services/fonctions_ia.dart';
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

  /// Fabrique une connexion HTTP neuve par appel à scan-menu (voir [_appelScanMenu]).
  final http.Client Function() _nouveauTransport;

  MenuScanService(this._knowledgeCache, [this._supabaseClient, http.Client Function()? nouveauTransport])
      : _nouveauTransport = nouveauTransport ?? (() => http.Client());

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

    Map<String, dynamic>? parsedJson;
    String? usedModel;

    // Depuis la V2.3, seul le serveur lit la carte (scan-menu) : l'app n'a plus de clé.
    onStepUpdate?.call(isEn ? 'Analyzing wine list via Chatmelier Cloud...' : 'Analyse de la carte des vins via le Cloud Chatmelier...');
    parsedJson = await _analyserPagesEnParallele(parts, languageCode, restaurantNameHint, onStepUpdate, isEn);
    usedModel = parsedJson?['modele'] as String?;

    if (parsedJson == null) {
      throw Exception(isEn
          ? 'The wines on this menu could not be read. Check your photos and try again.'
          : 'Les vins de cette carte n\'ont pas pu être lus. Vérifiez vos photos et réessayez.');
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


    // Sans clé embarquée (tous les builds publiés depuis le 14/09), seule la fonction edge
    // peut répondre. L'appel direct ci-dessous n'existe plus que pour le développement :
    // c'est lui qui échouait en silence le 23/09 à 19h07.
    final isEn = languageCode.toLowerCase().startsWith('en');
    final injoignable = isEn
        ? 'Sorry, the sommelier cannot be reached right now. Please check your connection and try again.'
        : 'Désolé, impossible de joindre le sommelier IA pour le moment. Vérifiez votre connexion et réessayez.';
    return await _demanderAuSommelierDistant(
          menu: menu,
          question: userQuestion,
          carte: wineListText,
          profil: profileContext,
          languageCode: languageCode,
        ) ??
        injoignable;
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
      final corps = {
        'imagesBase64': imagesBase64,
        'languageCode': languageCode,
        'restaurantNameHint': restaurantNameHint,
      };
      // 150 s : la limite de durée d'une fonction edge. Abandonner avant ne fait rien
      // gagner — le serveur va au bout et facture l'appel quand même (18/09, 25/09).
      final data = await appelerAvecRelance(
        (delai) => _appelScanMenu(client, corps, delai),
        total: _delaiScanMenu,
        relance: _relanceScanMenu,
        siRelance: () => AppLogger.warning(
            'MENU_SCAN',
            'scan-menu silencieux après ${_relanceScanMenu.inSeconds} s '
                '(${SchedulerBinding.instance.lifecycleState?.name}) : seconde tentative sur une connexion neuve'),
      );

      if (data != null) {
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
      AppLogger.warning('MENU_SCAN', 'scan-menu returned no usable body');
    } on LimiteIaAtteinte {
      // La limite du jour n'est pas une panne : l'écran doit la dire telle quelle.
      rethrow;
    } catch (e, stack) {
      AppLogger.error('MENU_SCAN', 'Edge function scan-menu error: $e', e, stack);
    }
    return null;
  }

  static const _delaiScanMenu = Duration(seconds: 150);

  /// Au-delà, une page silencieuse est relancée. Une page répond en 12 à 25 s ; les plus
  /// chargées (près de trente vins) en 50 s au plus.
  static const _relanceScanMenu = Duration(seconds: 45);

  /// Un appel à scan-menu sur une connexion NEUVE, refermée après.
  ///
  /// Le client Supabase recycle ses connexions. Le 29/09 au matin, deux scans sont restés
  /// figés jusqu'au délai de 150 s pendant que les journaux, envoyés au même serveur par
  /// le même client, passaient : la signature d'une connexion réutilisée, morte en
  /// silence sur un réseau qui venait de hoqueter (lecture des notifications en échec à
  /// 06:05:43). Une connexion ouverte pour l'appel ne peut pas l'être.
  Future<Map<String, dynamic>?> _appelScanMenu(
    SupabaseClient client,
    Map<String, dynamic> corps,
    Duration delai,
  ) async {
    // Une session, anonyme au besoin : le serveur peut l'exiger (V2.3 · B2), et elle porte
    // le quota du jour de la personne.
    var jeton = client.auth.currentSession?.accessToken;
    if (jeton == null) {
      try {
        jeton = (await client.auth.signInAnonymously()).session?.accessToken;
      } catch (e) {
        AppLogger.warning('MENU_SCAN', 'Session anonyme impossible avant scan-menu : $e');
      }
    }
    final transport = _nouveauTransport();
    try {
      final res = await transport
          .post(
            Uri.parse('${AppConstants.supabaseUrl}/functions/v1/scan-menu'),
            headers: {
              'apikey': AppConstants.supabaseAnonKey,
              'Authorization': 'Bearer ${jeton ?? AppConstants.supabaseAnonKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(corps),
          )
          .timeout(delai);
      if (res.statusCode == 429) {
        final corpsErreur = jsonDecode(utf8.decode(res.bodyBytes));
        if (corpsErreur is Map && corpsErreur['error'] == 'limite_du_jour') {
          throw LimiteIaAtteinte(
            limite: (corpsErreur['limite'] as num?)?.toInt(),
            anonyme: corpsErreur['anonyme'] == true,
          );
        }
      }
      if (res.statusCode != 200) {
        final extrait = res.body.length > 200 ? res.body.substring(0, 200) : res.body;
        throw http.ClientException('scan-menu HTTP ${res.statusCode} : $extrait');
      }
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      return data is Map ? Map<String, dynamic>.from(data) : null;
    } finally {
      transport.close();
    }
  }

  /// Lance [appel] ; sans réponse après [relance], en lance un second, et rend la
  /// première RÉPONSE des deux — une erreur ne l'emporte que si les deux échouent, et
  /// une erreur rapide du premier (429, réseau coupé) remonte sans relance. Les deux
  /// s'arrêtent au même instant, [total] après le départ : la relance ne rallonge jamais
  /// l'attente, elle la raccourcit quand le premier appel s'est perdu.
  @visibleForTesting
  static Future<T> appelerAvecRelance<T>(
    Future<T> Function(Duration delai) appel, {
    required Duration total,
    required Duration relance,
    void Function()? siRelance,
  }) async {
    final issue = Completer<T>();
    var enCours = 0;
    void suivre(Future<T> essai) {
      enCours++;
      essai.then((v) {
        if (!issue.isCompleted) issue.complete(v);
      }, onError: (Object e, StackTrace pile) {
        if (--enCours == 0 && !issue.isCompleted) issue.completeError(e, pile);
      });
    }

    suivre(appel(total));
    final minuteur = Timer(relance, () {
      if (issue.isCompleted) return;
      siRelance?.call();
      suivre(appel(total - relance));
    });
    try {
      return await issue.future;
    } finally {
      minuteur.cancel();
    }
  }
}
