import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/services/fonctions_ia.dart';
import '../domain/completion_par_le_web.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/langue.dart';
import '../../auth/data/ai_cost_tracker_service.dart';
import '../domain/scan_result.dart';
import 'label_image_optimizer.dart';
import 'scan_cache_service.dart';
import '../domain/region_contradiction.dart';
import '../domain/grounded_verification_budget.dart';

class ScanService {
  final SupabaseClient _client;
  final FonctionsIa _ia;

  /// Depuis la V2.3, toute l'IA passe par le serveur (scan-label, taches-ia) : l'app n'a
  /// plus de clé, et plus aucun appel direct à Google.
  ScanService(this._client, {FonctionsIa? ia, Future<User?> Function()? assurerUneSession})
      : _ia = ia ?? FonctionsIa(_client, assurerUneSession: assurerUneSession);

  /// Helper to safely read bytes from any image path or url across Web, iOS, Android and Desktop
  static Future<Uint8List> _readImageBytes(String imagePath) async {
    if (kIsWeb || imagePath.startsWith('blob:') || imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      try {
        final xfile = XFile(imagePath);
        return await xfile.readAsBytes();
      } catch (_) {
        final uri = Uri.parse(imagePath);
        final res = await http.get(uri);
        if (res.statusCode == 200) {
          return res.bodyBytes;
        }
        throw Exception('Impossible de charger l\'image Web: HTTP ${res.statusCode}');
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

  /// Analyze wine bottle photo with Google Gemini Multimodal Vision AI
  ///
  /// Avec [onLecture], en deux temps (23/10) : le vin lu arrive dès que l'étiquette est
  /// lue (cinq secondes), la description — notes, cépages, garde — ensuite ; le résultat
  /// rendu est complet. Sans, d'un seul tenant, comme avant.
  Future<ScanResult> analyzeBottleImage({
    String? imagePath,
    Uint8List? imageBytes,
    File? imageFile,
    String languageCode = 'fr',
    void Function(ScanResult lu)? onLecture,
  }) async {
    final startTime = DateTime.now();
    final effectivePath = imagePath ?? imageFile?.path ?? '';
    AppLogger.info('SCAN_AI', 'Starting label analysis for image: $effectivePath (lang=$languageCode)');

    try {
      Uint8List bytes;
      if (imageBytes != null && imageBytes.isNotEmpty) {
        bytes = imageBytes;
      } else if (effectivePath.isNotEmpty) {
        bytes = await _readImageBytes(effectivePath);
      } else {
        throw Exception('Aucune photo fournie pour l\'analyse.');
      }

      // 1. Optimize image: Central ROI crop + scale down to max 1024px + JPEG compression
      final optimized = await LabelImageOptimizer.optimiserEnArrierePlan(bytes);
      final optimizedBytes = optimized.bytes;
      final sha256Hash = optimized.sha256Hash;
      final mimeType = optimized.mimeType;

      // 2. Check local fingerprint cache
      final cachedScan = await ScanCacheService().getCachedResult(sha256Hash);
      if (cachedScan != null) {
        AppLogger.info('SCAN_AI', 'Exact image hash match found in local cache ($sha256Hash), skipping AI scan entirely!');
        return cachedScan;
      }

      final base64Image = base64Encode(optimizedBytes);
      final fileSizeKb = (optimizedBytes.length / 1024).round();
      AppLogger.debug('SCAN_AI', 'Encoded optimized image size: $fileSizeKb KB (Hash: ${sha256Hash.substring(0, 10)}...)');

      if (onLecture == null) {
        final resultat = await _analyserParLeServeur(base64Image, mimeType, languageCode);
        final duree = DateTime.now().difference(startTime).inMilliseconds;
        AppLogger.info('SCAN_AI', 'Étiquette lue par le serveur en $duree ms');
        await ScanCacheService().cacheResult(sha256Hash, resultat);
        return resultat;
      }
      final (resultat, complet) = await _analyserEnDeuxTemps(base64Image, mimeType, languageCode, onLecture, startTime);
      // Une description manquée ne se garde pas : la même photo la redemandera.
      if (complet) await ScanCacheService().cacheResult(sha256Hash, resultat);
      return resultat;
    } catch (e, stack) {
      AppLogger.error('SCAN_AI', 'All scan methods failed for image: $effectivePath', e, stack);
      rethrow;
    }
  }

  /// Enregistre ce que `scan-label` a payé (champ `couts`) : un événement par appel IA.
  ///
  /// Sans cela, les scans d'étiquette passés par le serveur échappaient à la mesure du
  /// coût de l'IA (P1). Un vin trouvé au catalogue n'en rapporte qu'un : la lecture.
  static List<Future<void>> enregistrerLesCouts(Map<String, dynamic> reponse, String? userId,
          {AiCostTrackerService? suivi}) =>
      (suivi ?? AiCostTrackerService()).enregistrerCoutsServeur(reponse, userId);

  /// La lecture, puis la description avec la suite signée que la lecture a rendue. Une
  /// fonction serveur d'avant la 88 rend tout d'un coup : la lecture est alors complète.
  Future<(ScanResult, bool)> _analyserEnDeuxTemps(String base64Image, String mimeType, String languageCode,
      void Function(ScanResult) onLecture, DateTime debut) async {
    final r1 = await _ia.appeler('scan-label', {
      'imageBase64': base64Image,
      'mimeType': mimeType,
      'languageCode': languageCode,
      'etape': 'lecture',
    }, delai: const Duration(seconds: 40));
    if (!r1.ok) {
      if (r1.limiteAtteinte) throw Exception(r1.messageDeLimite());
      throw Exception(tr(
          'Analyse de l\'étiquette impossible. Vérifiez votre connexion ou saisissez les informations manuellement.',
          'The label couldn\'t be analysed. Check your connection or enter the details manually.'));
    }
    final lecture = r1.donnees!;
    final lu = ScanResult.fromJson(lecture);
    final suite = lecture['suite'];
    if (lecture['complete'] != false || suite is! String) {
      _journaliser(lu, lecture, debut, 'lue par le serveur');
      return (lu, true);
    }
    AppLogger.info('SCAN_AI', 'Étiquette lue en ${DateTime.now().difference(debut).inMilliseconds} ms, description à suivre');
    onLecture(lu);
    final r2 = await _ia.appeler('scan-label', {
      'etape': 'description',
      'suite': suite,
      'languageCode': languageCode,
    }, delai: const Duration(seconds: 50));
    if (!r2.ok) {
      AppLogger.warning('SCAN_AI', 'Description de l\'étiquette manquée (${r2.erreur}) : le vin lu reste');
      return (lu, false);
    }
    final complet = ScanResult.fromJson({...lecture, ...r2.donnees!});
    _journaliser(complet, r2.donnees!, debut, 'décrite');
    return (complet, true);
  }

  void _journaliser(ScanResult r, Map<String, dynamic> donnees, DateTime debut, String quoi) {
    final etapes = donnees['etapes'];
    AppLogger.info('SCAN_AI', 'Étiquette $quoi en ${DateTime.now().difference(debut).inMilliseconds} ms : « ${r.name} »'
        '${r.producer != null ? ', ${r.producer}' : ''}${r.vintage != null ? ', ${r.vintage}' : ''}'
        ' — ${etapes is Map ? etapes.entries.map((e) => '${e.key} : ${e.value}').join(', ') : 'étapes non rendues par le serveur'}'
        ', ${r.grapes.length} cépage(s)');
  }

  Future<ScanResult> _analyserParLeServeur(String base64Image, String mimeType, String languageCode) async {
    // 60 s : un scan d'étiquette réussi en prend 16 (le 16/09, 16 391 ms), et celui d'edith a
    // été abandonné à 15 s pile le 22/09. Le serveur, lui, va au bout et facture l'appel.
    final r = await _ia.appeler('scan-label', {
      'imageBase64': base64Image,
      'mimeType': mimeType,
      'languageCode': languageCode,
    }, delai: const Duration(seconds: 60));
    if (r.ok) {
      final resultat = ScanResult.fromJson(r.donnees!);
      // Ce que l'étiquette a donné et ce que chaque étape du serveur a fait (17/10) : le 16/10,
      // deux vins sont revenus presque vides sans que rien ne dise pourquoi.
      final etapes = r.donnees!['etapes'];
      AppLogger.info('SCAN_AI', 'Étiquette : « ${resultat.name} »'
          '${resultat.producer != null ? ', ${resultat.producer}' : ''}${resultat.vintage != null ? ', ${resultat.vintage}' : ''}'
          ' — ${etapes is Map ? etapes.entries.map((e) => '${e.key} : ${e.value}').join(', ') : 'étapes non rendues par le serveur'}'
          ' — origine : ${[resultat.appellation, resultat.region, resultat.country].where((v) => (v ?? '').isNotEmpty).join(', ')}'
          ', ${resultat.grapes.length} cépage(s)');
      return resultat;
    }
    if (r.limiteAtteinte) throw Exception(r.messageDeLimite());
    throw Exception(tr(
        'Analyse de l\'étiquette impossible. Vérifiez votre connexion ou saisissez les informations manuellement.',
        'The label couldn\'t be analysed. Check your connection or enter the details manually.'));
  }

  /// Uploads photo to Supabase storage bucket 'labels' (Web & Mobile compatible)
  ///
  /// [rattacherALaBouteille] faux pour une photo sans bouteille en cave (dégustation hors
  /// cave) : la ligne `bottle_photos` exige une bouteille existante, et l'essai
  /// d'insertion échouait à chaque fois (30/09).
  Future<String?> uploadPhoto({
    required String bottleId,
    String? imagePath,
    Uint8List? imageBytes,
    File? file,
    bool rattacherALaBouteille = true,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        AppLogger.warning('SCAN_AI', 'Cannot upload photo: no authenticated user');
        return null;
      }

      final effectivePath = imagePath ?? file?.path ?? 'bottle_image.jpg';
      String ext = 'jpg';
      if (!effectivePath.startsWith('blob:') && !effectivePath.startsWith('http')) {
        final rawExt = effectivePath.split('.').last.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        if (['jpg', 'jpeg', 'png', 'webp'].contains(rawExt)) {
          ext = rawExt == 'jpeg' ? 'jpg' : rawExt;
        }
      }
      final fileName = '${user.id}/${bottleId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      Uint8List bytes;
      if (imageBytes != null && imageBytes.isNotEmpty) {
        bytes = imageBytes;
      } else if (effectivePath.isNotEmpty) {
        bytes = await _readImageBytes(effectivePath);
      } else {
        return null;
      }

      await _client.storage.from('labels').uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(
          contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
          upsert: true,
        ),
      );

      final publicUrl = _client.storage.from('labels').getPublicUrl(fileName);

      // Save to bottle_photos table only if bottleId is a valid UUID (not a temporary offline string)
      if (rattacherALaBouteille && !bottleId.startsWith('temp_')) {
        try {
          await _client.from('bottle_photos').insert({
            'bottle_id': bottleId,
            'storage_path': publicUrl,
            'photo_type': 'front',
          });
        } catch (dbErr) {
          AppLogger.warning('SCAN_AI', 'Saved photo to storage but bottle_photos insert skipped: $dbErr');
        }
      }

      AppLogger.info('SCAN_AI', 'Uploaded photo successfully to $publicUrl');
      return publicUrl;
    } catch (e, stack) {
      AppLogger.error('SCAN_AI', 'Error uploading photo to storage', e, stack);
      return null;
    }
  }

  /// Enrich existing wine data with sommelier tasting notes, apogée window, and pairings

  /// Enrichit un vin, et **ne croit pas la première réponse sur parole** quand le nom du
  /// vin la contredit.
  ///
  /// Motivé par une remontée : un Crémant du Jura enrichi « Pauillac & Haut-Médoc ».
  /// Le nom était resté juste, c'est la région qui était inventée.
  ///
  /// La règle : quand le nom d'un vin nomme lui-même une région et que l'enrichissement
  /// en renvoie une autre, on redemande — **une seule fois, et sans redonner les indices
  /// de région**, pour ne pas ancrer la seconde réponse sur la première erreur.
  ///
  /// Ce chemin coûte cher : chaque appel groundé est facturé 0,035 \$ forfaitaires, soit
  /// 119× le coût en jetons. Il est donc gardé par trois verrous décrits dans
  /// [GroundedVerificationBudget] — détection locale gratuite, jamais deux fois le même
  /// vin, plafond quotidien. Sur un corpus de vingt vins correctement renseignés, il ne
  /// se déclenche pas une seule fois (`region_contradiction_test.dart`).
  ///
  /// En cas de doute persistant, la première réponse est conservée mais marquée
  /// `region_douteuse` : on préfère signaler qu'inventer.
  Future<Map<String, dynamic>> enrichWineDataVerified({
    required String wineName,
    String? producer,
    int? vintage,
    String? country,
    String? region,
    String? subRegion,
    String? appellation,
    String? classification,
    String? wineType,
  }) async {
    final premier = await enrichWineData(
      wineName: wineName,
      producer: producer,
      vintage: vintage,
      country: country,
      region: region,
      subRegion: subRegion,
      appellation: appellation,
      classification: classification,
      wineType: wineType,
    );

    final contradiction = RegionContradictionDetector.detecter(
      nomDuVin: wineName,
      regionEnrichie: premier['region']?.toString(),
      appellationEnrichie: premier['appellation']?.toString(),
    );
    if (contradiction == null) return premier;

    final budget = await GroundedVerificationBudget.ouvrir();
    if (!budget.peutVerifier(wineName)) {
      AppLogger.info('SCAN_AI',
          'Contradiction de région non vérifiée (déjà vue ou plafond atteint) : $contradiction');
      return {...premier, 'region_douteuse': true};
    }

    AppLogger.warning('SCAN_AI', 'Contradiction de région détectée : $contradiction — '
        'seconde source demandée');
    // Marqué AVANT l'appel : si celui-ci échoue, on ne doit pas le relancer en boucle.
    await budget.enregistrerVerification(wineName);

    final second = await enrichWineData(
      wineName: wineName,
      producer: producer,
      vintage: vintage,
      wineType: wineType,
      // Volontairement sans country/region/subRegion/appellation : la première réponse
      // s'est trompée dessus, les redonner reviendrait à souffler la mauvaise réponse.
      // Cette seconde source cherche sur le web : c'est le seul appel groundé de l'app, et
      // GroundedVerificationBudget le borne.
      avecRecherche: true,
    );

    final contradictionRestante = RegionContradictionDetector.detecter(
      nomDuVin: wineName,
      regionEnrichie: second['region']?.toString(),
      appellationEnrichie: second['appellation']?.toString(),
    );

    if (contradictionRestante == null &&
        (second['region']?.toString().trim().isNotEmpty ?? false)) {
      AppLogger.info('SCAN_AI',
          'Seconde source cohérente avec le nom : région corrigée en ${second['region']}');
      // On garde le premier enrichissement (plus complet car guidé) et on n'en remplace
      // que ce qui était faux.
      return {
        ...premier,
        'region': second['region'],
        if (second['appellation'] != null) 'appellation': second['appellation'],
        if (second['country'] != null) 'country': second['country'],
        if (second['sub_region'] != null) 'sub_region': second['sub_region'],
      };
    }

    AppLogger.warning('SCAN_AI',
        'Seconde source toujours en contradiction avec le nom : fiche marquée douteuse');
    return {...premier, 'region_douteuse': true};
  }

  Future<Map<String, dynamic>> enrichWineData({
    required String wineName,
    String? producer,
    int? vintage,
    String? country,
    String? region,
    String? subRegion,
    String? appellation,
    String? classification,
    String? wineType,
    bool avecRecherche = false,
  }) async {
    AppLogger.info('SCAN_AI', 'Enriching wine data: $wineName ($vintage) by $producer');

    // 1. Check Supabase wine catalog cache (0 token cost if already enriched)
    try {
      final cachedRows = await _client.rpc('find_cached_wine', params: {
        'p_producer': producer,
        'p_name': wineName,
        'p_vintage': vintage,
      });
      if (cachedRows is List && cachedRows.isNotEmpty) {
        final row = cachedRows.first as Map<String, dynamic>;
        final tastingNotes = row['tasting_notes'] as String?;
        if (tastingNotes != null && tastingNotes.isNotEmpty) {
          AppLogger.info('SCAN_AI', 'Enrichment resolved from Supabase catalog cache for $wineName (0 API tokens consumed!)');
          return {
            'grapes': row['grapes'],
            'appellation': row['appellation'],
            'region': row['region'],
            'sub_region': row['sub_region'],
            'classification': row['classification'],
            'tasting_notes': tastingNotes,
            // La colonne du catalogue s'appelle ai_food_pairings : lire « food_pairings »
            // rendait toujours une liste vide.
            'food_pairings': row['ai_food_pairings'] is List
                ? List<String>.from(row['ai_food_pairings'])
                : (row['food_pairings'] is List ? List<String>.from(row['food_pairings']) : <String>[]),
            'ideal_drinking_start': row['ideal_drinking_start'],
            'ideal_drinking_end': row['ideal_drinking_end'],
            'peak_drinking_start': row['peak_drinking_start'],
            'peak_drinking_end': row['peak_drinking_end'],
            // Une valeur de marché ne circule que sourcée (V2.3 · B3).
            // `is_verified_online` n'en est plus la preuve : l'app le posait après chaque
            // enrichissement par l'IA, qui ne vérifiait rien (30/09).
            'estimated_market_value': (row['external_links'] is Map && (row['external_links'] as Map)['valeur_source'] != null)
                ? (row['estimated_market_value'] as num?)?.toDouble()
                : null,
            'estimated_value_currency': 'EUR',
            'alcohol_pct': (row['alcohol_pct'] as num?)?.toDouble(),
            'ai_summary': row['ai_summary'],
          };
        }
      }
    } catch (e) {
      AppLogger.debug('SCAN_AI', 'find_cached_wine check skipped: $e');
    }

    final r = await _ia.appeler('taches-ia', {
      'tache': 'enrichir_fiche',
      'nom': wineName,
      if (producer != null) 'producteur': producer,
      if (vintage != null) 'millesime': vintage,
      if (region != null) 'region': region,
      if (appellation != null) 'appellation': appellation,
      if (wineType != null) 'type': wineType,
      'recherche': avecRecherche,
      'langue': Langue.code,
    }, delai: Duration(seconds: avecRecherche ? 50 : 35));
    final brut = r.ok ? r.donnees!['resultat'] : null;
    if (brut is Map) return Map<String, dynamic>.from(brut);
    if (r.limiteAtteinte) throw Exception(r.messageDeLimite());

    // Curated local enological knowledge fallback (e.g. Domaine de Terrebrune, Bandol, Bordeaux, Bourgogne)
    final localFallback = _getLocalEnologicalFallback(
      wineName: wineName,
      producer: producer,
      vintage: vintage,
      region: region,
      appellation: appellation,
      wineType: wineType,
    );
    if (localFallback != null) {
      AppLogger.info('SCAN_AI', 'Enrichment resolved via built-in enological knowledge base for $wineName');
      return localFallback;
    }

    throw Exception('Impossible d\'enrichir les données pour le moment. Veuillez vérifier votre connexion ou réessayer.');
  }

  static Map<String, dynamic>? extractJsonFromText(String rawText) {
    String clean = rawText.trim();
    if (clean.contains('```json')) {
      clean = clean.split('```json')[1].split('```')[0].trim();
    } else if (clean.contains('```')) {
      clean = clean.split('```')[1].split('```')[0].trim();
    }
    try {
      final decoded = jsonDecode(clean);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (e) {
        AppLogger.debug('SCAN_AI', 'Repli : $e');
      }

    final match = RegExp(r'\{[\s\S]*\}').firstMatch(rawText);
    if (match != null) {
      try {
        final decoded = jsonDecode(match.group(0)!);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (e) {
        AppLogger.debug('SCAN_AI', 'Repli : $e');
      }
    }
    return null;
  }

  Map<String, dynamic>? _getLocalEnologicalFallback({
    required String wineName,
    String? producer,
    int? vintage,
    String? region,
    String? appellation,
    String? wineType,
  }) {
    final nameLower = '$wineName ${producer ?? ""} ${appellation ?? ""} ${region ?? ""}'.toLowerCase();
    final v = vintage ?? (DateTime.now().year - 3);

    // 1. Domaine de Terrebrune (Bandol)
    if (nameLower.contains('terrebrune') || nameLower.contains('bandol')) {
      final isRose = (wineType ?? '').toLowerCase().contains('ros');
      final isWhite = (wineType ?? '').toLowerCase().contains('white') || (wineType ?? '').toLowerCase().contains('blanc');

      if (isRose) {
        return {
          'grapes': [
            {'name': 'Mourvèdre', 'pct': 60},
            {'name': 'Grenache', 'pct': 20},
            {'name': 'Cinsault', 'pct': 20},
          ],
          'appellation': 'Bandol AOP',
          'region': 'Provence',
          'sub_region': 'Bandol',
          'classification': 'AOC Bandol',
          'tasting_notes': 'Robe saumonée brillante. Arômes délicats d\'agrumes, pêche de vigne, épices fines et minéralité saline. Grande persistance gastronomique.',
          'food_pairings': ['Rouget barbet grillé', 'Bouillabaisse', 'Cuisine méditerranéenne aux herbes', 'Petits farcis provençaux'],
          'ideal_drinking_start': v + 1,
          'ideal_drinking_end': v + 8,
          'peak_drinking_start': v + 2,
          'peak_drinking_end': v + 5,
          'estimated_market_value': 26.0,
          'estimated_value_currency': 'EUR',
          'alcohol_pct': 13.5,
          'ai_summary': 'Bandol Rosé d\'exception (Mourvèdre 60%, Grenache 20%, Cinsault 20%) issu de terroirs calcaires du Trias.',
        };
      } else if (isWhite) {
        return {
          'grapes': [
            {'name': 'Clairette', 'pct': 50},
            {'name': 'Ugni Blanc', 'pct': 25},
            {'name': 'Bourboulenc', 'pct': 25},
          ],
          'appellation': 'Bandol AOP',
          'region': 'Provence',
          'sub_region': 'Bandol',
          'classification': 'AOC Bandol',
          'tasting_notes': 'Robe jaune pâle aux reflets verts. Nez de fleurs blanches, anis, fenouil sauvage et pierre à fusil. Bouche ample et saline.',
          'food_pairings': ['Loup de mer au fenouil', 'Coquillages et crustacés', 'Fromages de chèvre frais'],
          'ideal_drinking_start': v + 2,
          'ideal_drinking_end': v + 10,
          'peak_drinking_start': v + 3,
          'peak_drinking_end': v + 7,
          'estimated_market_value': 28.0,
          'estimated_value_currency': 'EUR',
          'alcohol_pct': 13.5,
          'ai_summary': 'Grand vin blanc de Bandol dominé par la Clairette sur sol calcaire triasique.',
        };
      } else {
        return {
          'grapes': [
            {'name': 'Mourvèdre', 'pct': 85},
            {'name': 'Grenache', 'pct': 10},
            {'name': 'Cinsault', 'pct': 5},
          ],
          'appellation': 'Bandol AOP',
          'region': 'Provence',
          'sub_region': 'Bandol',
          'classification': 'AOC Bandol',
          'tasting_notes': 'Robe pourpre profonde. Bouquet complexe de fruits noirs, réglisse, cuir noble, garrigue et cacao. Bouche puissante aux tannins veloutés et superbe fraîcheur minérale.',
          'food_pairings': ['Gigot d\'agneau confit au thym', 'Daube provençale', 'Côte de bœuf maturée', 'Gibier en sauce'],
          'ideal_drinking_start': v + 5,
          'ideal_drinking_end': v + 25,
          'peak_drinking_start': v + 8,
          'peak_drinking_end': v + 18,
          'estimated_market_value': 38.0,
          'estimated_value_currency': 'EUR',
          'alcohol_pct': 14.0,
          'ai_summary': 'Monument de Bandol dominé par le Mourvèdre (85%), offrant un potentiel de garde exceptionnel.',
        };
      }
    }
    return null;
  }

  /// Fast AI wine detection based on minimal text input (e.g. from bar chalkboard, restaurant wine list, or verbal note)
  Future<ScanResult> analyzeWineFromText(String text) async {
    final startTime = DateTime.now();
    AppLogger.info('SCAN_AI', 'Analyzing wine from text: "$text"');

    final r = await _ia.appeler('taches-ia', {
      'tache': 'vin_depuis_texte',
      'texte': text,
      'langue': Langue.code,
    }, delai: const Duration(seconds: 30));
    final brut = r.ok ? r.donnees!['resultat'] : null;
    if (brut is Map && nonReconnu(brut)) {
      AppLogger.info('SCAN_AI', 'Vin non reconnu depuis le texte : rien n\'est inventé');
      throw VinNonReconnu();
    }
    if (brut is Map) {
      var result = ScanResult.fromJson(Map<String, dynamic>.from(brut));
      // ScanResult.fromJson prend « rouge » sans couleur donnée : depuis un nom, une couleur
      // inconnue reste inconnue (R1).
      if (brut['wine_type'] == null) result = result.copyWith(wineType: '');
      AppLogger.info('SCAN_AI',
          'Vin reconnu depuis le texte en ${DateTime.now().difference(startTime).inMilliseconds} ms');
      return result;
    }

    // Hors ligne ou vin non reconnu : le texte tel quel, et rien d'inventé (V2.4 · R1). Le
    // repli d'avant écrivait « rouge, France » sur n'importe quel vin.
    return ScanResult(
      name: text.trim(),
      producer: null,
      vintage: null,
      wineType: '',
      country: '',
      region: '',
      foodPairings: const [],
      detectedQuantity: 1,
    );
  }

  /// Le serveur a répondu qu'il ne reconnaissait pas ce vin avec certitude.
  static bool nonReconnu(Map brut) => brut['reconnu'] == false;

  /// Cherche sur le web un vin que l'étiquette n'a pas suffi à trouver (17/10) : la
  /// recherche Google de `vin_depuis_texte`, à partir de ce que l'étiquette dit
  /// ([CompletionParLeWeb.requete]). Rend la fiche complétée — ce que l'étiquette a lu ne
  /// bouge pas — et les adresses des sources ; nul si le web ne confirme pas ce vin, ou
  /// s'il répond pour un autre. Chaque issue s'écrit au journal, avec ce qui a été cherché.
  Future<({ScanResult fiche, List<String> sources, List<String> completes})?> chercherSurLeWeb(
    ScanResult lu, {
    required String requete,
  }) async {
    final debut = DateTime.now();
    final r = await _ia.appeler('taches-ia', {
      'tache': 'vin_depuis_texte',
      'texte': requete,
      'langue': Langue.code,
    }, delai: const Duration(seconds: 45));
    final duree = DateTime.now().difference(debut).inMilliseconds;
    final brut = r.ok ? r.donnees!['resultat'] : null;
    if (brut is! Map || nonReconnu(brut)) {
      AppLogger.info('SCAN_WEB',
          'Introuvable sur le web en $duree ms : « $requete »${r.ok ? '' : ' (${r.erreur ?? 'pas de réponse'})'}');
      return null;
    }
    final web = ScanResult.fromJson(Map<String, dynamic>.from(brut));
    if (!CompletionParLeWeb.memeVin(lu, web)) {
      AppLogger.warning('SCAN_WEB', 'Le web répond pour un autre vin (« ${web.name} », ${web.producer ?? '?'}) : '
          '« $requete » laissé tel quel');
      return null;
    }
    // Les sources par leur nom (« vinosdeespana.com ») : leurs adresses sont des renvois
    // de Google, illisibles et éphémères.
    final sources = <String>{
      for (final s in (r.donnees!['sources'] as List?) ?? const [])
        if (s is Map && '${s['titre'] ?? ''}'.trim().isNotEmpty) '${s['titre']}'.trim()
        else if (s is Map && s['url'] is String) s['url'] as String,
    }.toList();
    final fiche = CompletionParLeWeb.fusionner(lu, web, sources: sources);
    final completes = CompletionParLeWeb.champsCompletes(lu, fiche);
    AppLogger.info('SCAN_WEB', 'Trouvé sur le web en $duree ms : « $requete » → '
        '${completes.isEmpty ? 'rien de plus' : completes.join(', ')} (${sources.length} source(s))');
    return (fiche: fiche, sources: sources, completes: completes);
  }
}

/// Le texte ne suffit pas à reconnaître le vin avec certitude (V2.4 · R1).
class VinNonReconnu implements Exception {}
