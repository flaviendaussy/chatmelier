import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/services/gemini_model_registry.dart';
import '../../../shared/utils/app_logger.dart';
import '../../auth/data/ai_cost_tracker_service.dart';
import '../domain/scan_result.dart';

class ScanService {
  final SupabaseClient _client;
  static const String _geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AQ.Ab8RN6JFZQNPfXmDdjdGT0posCOmn_4wPIFv_TiviorSGL6BDg',
  );

  ScanService(this._client);

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
  Future<ScanResult> analyzeBottleImage({
    String? imagePath,
    Uint8List? imageBytes,
    File? imageFile,
  }) async {
    final startTime = DateTime.now();
    final effectivePath = imagePath ?? imageFile?.path ?? '';
    AppLogger.info('SCAN_AI', 'Starting label analysis for image: $effectivePath');

    // Dynamically refresh newest available Gemini models in background
    GeminiModelRegistry.refreshAvailableModels();

    try {
      Uint8List bytes;
      if (imageBytes != null && imageBytes.isNotEmpty) {
        bytes = imageBytes;
      } else if (effectivePath.isNotEmpty) {
        bytes = await _readImageBytes(effectivePath);
      } else {
        throw Exception('Aucune photo fournie pour l\'analyse.');
      }

      final base64Image = base64Encode(bytes);
      final fileSizeKb = (bytes.length / 1024).round();
      AppLogger.debug('SCAN_AI', 'Encoded image size: $fileSizeKb KB');

      // Determine mime type
      String mimeType = 'image/jpeg';
      final pathLower = effectivePath.toLowerCase();
      if (pathLower.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (pathLower.endsWith('.webp')) {
        mimeType = 'image/webp';
      } else if (pathLower.endsWith('.heic') || pathLower.endsWith('.heif')) {
        mimeType = 'image/heic';
      }

      const prompt = '''You are Chatmelier, the world-class master sommelier and OCR wine recognition engine.
Analyze this wine bottle label photo with maximum precision.
Extract or infer the following factual beverage properties:
1. "name": The wine or spirit name / cuvée (e.g. "Château Margaux", "Bénédictine D.O.M.", "Chartreuse Verte", "Lagavulin 16").
2. "producer": The winery, estate, domain, distillery or house name (e.g. "Bénédictine", "Domaine de Terrebrune", "Antinori").
3. "vintage": Year as integer (e.g. 2018, 2019) or null if non-vintage / not visible / spirit.
4. "cuvee_parcel": Specific cuvée, parcel, or cask/expression name if indicated, else null.
5. "wine_type": One of ["red", "white", "rosé", "sparkling", "dessert", "fortified", "orange", "liqueur", "spirit", "whisky", "gin", "rum", "vodka", "tequila", "cognac", "vermouth"]. CRITICAL: Spirits, aperitifs, gins, and herbal liqueurs (e.g. Italicus, Rosolio, Bénédictine, Chartreuse, Cointreau, Amaretto, Disaronno, Gin, Pisco, Grappa, Aguardente, Rum, Whisky, Vodka, Pastis) must be classified as their specific spirit type ("gin", "whisky", "rum", "vodka", "tequila", "cognac") or as "liqueur" or "spirit". NEVER classify any spirit, gin, or liqueur as "fortified", "dessert", or "wine"! "fortified" is STRICTLY reserved for true fortified wines (Porto, Sherry/Xérès, Banyuls, Madeira, Marsala).
6. "country": Country of origin (e.g. "France", "Italy", "Scotland", "United States").
7. "region": Region (e.g. "Normandie", "Bordeaux", "Bourgogne", "Islay").
8. "sub_region": Sub-region if applicable, else null.
9. "appellation": Appellation or AOC/DOC/AOP/type if applicable, else null.
10. "classification": Official classification if applicable (e.g. "Liqueur de plantes", "Grand Cru Classé", "Single Malt"), else null.
11. "alcohol_pct": Alcohol percentage (% vol / ABV) as number (e.g. 40.0 for Bénédictine, 55.0 for Chartreuse Verte, 13.5 for wine). Look closely for % vol on label or provide the verified standard ABV. Do not leave null if known.
12. "grapes": Array of objects [{"name": "Grape Variety Name", "pct": percentage_number or null}]. YOU MUST strictly extract or deduce the exact grape variety composition (e.g., Bandol Rouge Terrebrune = 85% Mourvèdre, 10% Grenache, 5% Cinsault; Châteauneuf-du-Pape = Grenache, Syrah, Mourvèdre, Cinsault; Bordeaux = Cabernet Sauvignon, Merlot, etc.).
13. "tasting_notes": Expert sommelier aromas, palate, and structure notes.
14. "food_pairings": Array of 3 to 5 matching food pairings.
15. "ideal_drinking_start": Recommended start year for drinking window or null.
16. "ideal_drinking_end": Recommended end year for drinking window or null.
17. "peak_drinking_start": Peak maturity start year (apogée) or null.
18. "peak_drinking_end": Peak maturity end year (apogée) or null.
19. "estimated_market_value": Approximate retail market price estimation in EUR as number (e.g. 45.0, 120.0) or null.
20. "estimated_value_currency": "EUR".
21. "ai_summary": Brief 1-2 sentence sommelier overview in French, systematically mentioning the grape varieties / cépages (e.g. "Cépage : Mourvèdre 85%, Grenache 10%, Cinsault 5%").
22. "detected_quantity": Integer count of bottles represented in this photo. If the image shows a carton/box of 6, return 6. If a wooden case of 12, return 12. If multiple identical bottles are visible side-by-side, count them. If a single bottle, return 1.
23. "packaging_type": One of ["single", "carton_6", "crate_12", "multi_bottles"].

CRITICAL ENOLOGICAL RULES FOR DRINKING WINDOW (APOGÉE) & GRAPES:
- Search Google in real time for this wine name, producer, and vintage.
- Retrieve verified data from official guides (Guide Hachette des Vins, Revue du Vin de France, Wine Spectator, Robert Parker, Bettane+Desseauve) to extract the exact drinking window / apogée years.
- Always identify grape varieties (cépages) with high fidelity.
- For non-vintage (NM) or everyday table wines, set peak window to current year or 1-2 years max.

Return strictly a valid JSON object matching this schema.''';

      final requestBodyWithSearch = jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'inlineData': {
                  'mimeType': mimeType,
                  'data': base64Image,
                }
              },
              {'text': prompt}
            ]
          }
        ],
        'tools': [
          {'googleSearch': {}}
        ]
      });

      final requestBodyDirect = jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'inlineData': {
                  'mimeType': mimeType,
                  'data': base64Image,
                }
              },
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'responseMimeType': 'application/json',
        }
      });

      final activeModels = GeminiModelRegistry.getModelsForTier(GeminiTaskTier.standardFlashPreferred);

      // Attempt scanning: Try Direct Fast JSON OCR FIRST (1.5-3s), then Web Search tool fallback if needed
      for (int attempt = 1; attempt <= 2; attempt++) {
        for (final model in activeModels) {
          // Pass 1: Direct JSON OCR (super fast, ~2s); Pass 2: Search tool fallback
          for (final isSearch in [false, attempt == 2]) {
            final reqBody = isSearch ? requestBodyWithSearch : requestBodyDirect;
            final timeoutSec = isSearch ? 18 : 12;
            try {
              AppLogger.debug('SCAN_AI', 'Calling Gemini API (Attempt $attempt) with model: $model (Search tool: $isSearch, Timeout: ${timeoutSec}s)');
              final url = Uri.parse(
                'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_geminiApiKey',
              );

              final response = await http.post(
                url,
                headers: {'Content-Type': 'application/json'},
                body: reqBody,
              ).timeout(Duration(seconds: timeoutSec));

              if (response.statusCode == 200) {
                final data = jsonDecode(response.body);
                String rawText = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '{}';
                if (rawText.contains('```json')) {
                  rawText = rawText.split('```json')[1].split('```')[0].trim();
                } else if (rawText.contains('```')) {
                  rawText = rawText.split('```')[1].split('```')[0].trim();
                }
                final parsed = jsonDecode(rawText) as Map<String, dynamic>;
                final result = ScanResult.fromJson(parsed);

                final duration = DateTime.now().difference(startTime).inMilliseconds;
                AppLogger.info('SCAN_AI', 'Scan succeeded on attempt $attempt via $model (Search: $isSearch) in ${duration}ms! Found: "${result.name}" (${result.vintage ?? "NM"}), Qty: ${result.detectedQuantity}');

                // Track AI token and cost metrics
                AiCostTrackerService().recordRawResponse(
                  model: model,
                  feature: 'scan_vision',
                  responseJson: data,
                  isSearchGrounded: isSearch,
                  userId: _client.auth.currentUser?.id,
                );

                return result;
              } else if (response.statusCode == 429) {
                GeminiModelRegistry.recordRateLimit(model);
                AppLogger.warning('SCAN_AI', 'Model $model returned HTTP 429 (Quota limit), moving to next model');
                break; // Skip to next model immediately
              } else if (response.statusCode == 404) {
                GeminiModelRegistry.recordDisabledModel(model);
                AppLogger.warning('SCAN_AI', 'Model $model returned HTTP 404 (Deprecated), moving to next active model');
                break;
              } else {
                AppLogger.warning('SCAN_AI', 'Model $model returned HTTP ${response.statusCode}: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
              }
            } catch (modelErr) {
              AppLogger.warning('SCAN_AI', 'Model $model failed (Attempt $attempt, Search: $isSearch) with error: $modelErr');
            }
          }
        }
        if (attempt == 1) {
          // Short delay before second pass
          await Future.delayed(const Duration(milliseconds: 600));
        }
      }

      // If all direct Gemini endpoints failed, try Supabase Edge function
      AppLogger.info('SCAN_AI', 'Direct Gemini calls failed. Attempting Supabase Edge Function fallback...');
      final fallbackResult = await _invokeEdgeFunction(base64Image, mimeType);
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      AppLogger.info('SCAN_AI', 'Edge function scan succeeded in ${duration}ms');
      return fallbackResult;
    } catch (e, stack) {
      AppLogger.error('SCAN_AI', 'All scan methods failed for image: $effectivePath', e, stack);
      rethrow;
    }
  }

  Future<ScanResult> _invokeEdgeFunction(String base64Image, String mimeType) async {
    try {
      final res = await _client.functions.invoke('scan-label', body: {
        'imageBase64': base64Image,
        'mimeType': mimeType,
      }).timeout(const Duration(seconds: 15));

      if (res.data != null) {
        return ScanResult.fromJson(res.data as Map<String, dynamic>);
      }
    } catch (e, stack) {
      AppLogger.error('SCAN_AI', 'Edge function fallback error: $e', e, stack);
    }
    throw Exception('Analyse de l\'étiquette impossible. Vérifiez votre connexion ou saisissez les informations manuellement.');
  }

  /// Uploads photo to Supabase storage bucket 'labels' (Web & Mobile compatible)
  Future<String?> uploadPhoto({
    required String bottleId,
    String? imagePath,
    Uint8List? imageBytes,
    File? file,
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
      if (!bottleId.startsWith('temp_')) {
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
  }) async {
    AppLogger.info('SCAN_AI', 'Enriching wine data: $wineName ($vintage) by $producer');

    final prompt = '''You are Chatmelier, the world-class sommelier and oenology AI engine.
Provide comprehensive, verified sommelier data for:
- Wine Name: $wineName
- Producer/Domaine: ${producer ?? "Unknown"}
- Vintage: ${vintage != null ? vintage.toString() : "Non-vintage / Non millésimé"}
- Region/Terroir: ${region ?? "Unknown"}
- Appellation: ${appellation ?? "Unknown"}
- Wine Type: ${wineType ?? "red"}

Search verified wine references (Guide Hachette, Revue du Vin de France, Bettane+Desseauve, Wine Spectator, Decanter) to retrieve exact facts:
1. "grapes": Array of [{"name": "Grape Name", "pct": percentage or null}]. STRICTLY identify the real blend of this appellation/cuvée.
2. "appellation": Standardized official Appellation AOC/DOC/AOP.
3. "region": Primary wine region.
4. "sub_region": Specific sub-region/commune/cru if applicable.
5. "classification": Official classification (e.g. Grand Cru Classé, Premier Cru, Cru Bourgeois, AOC), else null.
6. "tasting_notes": Precise aromas, texture, acidity, and structure notes in French.
7. "food_pairings": 3-5 harmonious culinary pairings in French.
8. "ideal_drinking_start": First year this wine becomes enjoyable.
9. "ideal_drinking_end": Last year of good condition before decline.
10. "peak_drinking_start": Optimal peak maturity start year (Apogée début).
11. "peak_drinking_end": Optimal peak maturity end year (Apogée fin).
12. "estimated_market_value": Approximate fair bottle retail price in EUR as number (e.g. 35.0, 90.0).
13. "estimated_value_currency": "EUR".
14. "alcohol_pct": Standard alcohol content as number (e.g. 13.5) or null.
15. "ai_summary": 1-2 sentence sommelier summary in French systematically highlighting the grape varieties (cépages).

Return strictly a valid JSON object matching this schema.''';

    final requestBodyWithSearch = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [{'text': prompt}]
        }
      ],
      'tools': [
        {'googleSearch': {}}
      ]
    });

    final requestBodyDirect = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [{'text': prompt}]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
      }
    });

    final activeModels = GeminiModelRegistry.getModelsForTier(GeminiTaskTier.litePreferred);

    for (final model in activeModels) {
      for (final isSearch in [true, false]) {
        final reqBody = isSearch ? requestBodyWithSearch : requestBodyDirect;
        final timeoutSec = isSearch ? 18 : 8;
        try {
          final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_geminiApiKey',
          );

          final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: reqBody,
          ).timeout(Duration(seconds: timeoutSec));

          if (response.statusCode == 200) {
            final jsonResp = jsonDecode(response.body) as Map<String, dynamic>;
            final candidates = jsonResp['candidates'] as List<dynamic>?;
            if (candidates != null && candidates.isNotEmpty) {
              final content = candidates.first['content'] as Map<String, dynamic>?;
              final parts = content?['parts'] as List<dynamic>?;
              if (parts != null && parts.isNotEmpty) {
                final rawText = parts.first['text'] as String? ?? '';
                final parsed = extractJsonFromText(rawText);
                if (parsed != null) {
                  AppLogger.info('SCAN_AI', 'Enrichment succeeded via $model for $wineName');

                  // Track AI token and cost metrics
                  AiCostTrackerService().recordRawResponse(
                    model: model,
                    feature: 'scan_enrichment',
                    responseJson: jsonResp,
                    isSearchGrounded: isSearch,
                    userId: _client.auth.currentUser?.id,
                  );

                  return parsed;
                }
              }
            }
          } else if (response.statusCode == 429) {
            GeminiModelRegistry.recordRateLimit(model);
            AppLogger.warning('SCAN_AI', 'Model $model returned HTTP 429 (Quota limit) during enrichment, skipping');
            break;
          } else if (response.statusCode == 404) {
            GeminiModelRegistry.recordDisabledModel(model);
            AppLogger.warning('SCAN_AI', 'Model $model returned HTTP 404 during enrichment, disabled');
            break;
          } else {
            AppLogger.warning('SCAN_AI', 'Model $model returned HTTP ${response.statusCode}');
          }
        } catch (err) {
          AppLogger.warning('SCAN_AI', 'Enrichment failed on $model (Search: $isSearch): $err');
        }
      }
    }

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
    } catch (_) {}

    final match = RegExp(r'\{[\s\S]*\}').firstMatch(rawText);
    if (match != null) {
      try {
        final decoded = jsonDecode(match.group(0)!);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
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

    GeminiModelRegistry.refreshAvailableModels();

    final prompt = '''You are Chatmelier, the world-class master sommelier and enological intelligence engine.
Analyze the following wine description, restaurant wine list entry, or chalkboard text:
"$text"

Extract or deduce the exact factual wine or spirit properties:
1. "name": The wine or spirit name / cuvée (e.g. "Château Margaux", "Bénédictine D.O.M.", "Chartreuse", "Lagavulin 16").
2. "producer": The winery, estate or distillery producer name (e.g. "Bénédictine", "Domaine Laroche", "Domaine de Terrebrune").
3. "vintage": Year as integer (e.g. 2021, 2022) or null if not indicated / spirit.
4. "cuvee_parcel": Specific parcel/cuvée name or null.
5. "wine_type": One of ["red", "white", "rosé", "sparkling", "dessert", "fortified", "orange", "liqueur", "spirit", "whisky", "gin", "rum", "vodka", "tequila", "cognac", "vermouth"]. CRITICAL: Spirits, aperitifs, gins, and herbal liqueurs (e.g. Italicus, Rosolio, Bénédictine, Chartreuse, Cointreau, Amaretto, Disaronno, Gin, Pisco, Grappa, Aguardente, Rum, Whisky, Vodka, Pastis) must be classified as their specific spirit type ("gin", "whisky", "rum", "vodka", "tequila", "cognac") or as "liqueur" or "spirit". NEVER classify any spirit, gin, or liqueur as "fortified", "dessert", or "wine"! "fortified" is STRICTLY reserved for true fortified wines (Porto, Sherry/Xérès, Banyuls, Madeira, Marsala).
6. "country": Country of origin (default "France" if French appellation or distillery).
7. "region": Region (e.g. "Normandie", "Vallée du Rhône", "Bourgogne", "Bordeaux").
8. "sub_region": Sub-region or null.
9. "appellation": Appellation or AOC/AOP/IGP or null.
10. "classification": Official classification or null.
11. "alcohol_pct": Typical alcohol percentage (% vol / ABV) as number (e.g. 40.0, 13.5) or null.
12. "grapes": Array of objects [{"name": "Grape Variety", "pct": percentage_number or null}] (e.g. Syrah 100%, Chardonnay 100%, etc.).
13. "tasting_notes": Expert sommelier aromas, palate, and structure notes.
14. "food_pairings": Array of 3 to 5 matching food pairings.
15. "ideal_drinking_start": Recommended start year or null.
16. "ideal_drinking_end": Recommended end year or null.
17. "peak_drinking_start": Peak maturity start year or null.
18. "peak_drinking_end": Peak maturity end year or null.
19. "estimated_market_value": Approximate retail price in EUR as number or null.
20. "estimated_value_currency": "EUR".
21. "ai_summary": Brief 1-2 sentence sommelier overview in French, systematically mentioning the grape varieties / cépages.
22. "detected_quantity": 1.
23. "packaging_type": "single".

Return strictly a valid JSON object matching this schema.''';

    final requestBody = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
      }
    });

    final activeModels = GeminiModelRegistry.getModelsForTier(GeminiTaskTier.litePreferred);

    for (final model in activeModels) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_geminiApiKey',
        );

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: requestBody,
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          String rawText = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '{}';
          if (rawText.contains('```json')) {
            rawText = rawText.split('```json')[1].split('```')[0].trim();
          } else if (rawText.contains('```')) {
            rawText = rawText.split('```')[1].split('```')[0].trim();
          }
          final parsed = jsonDecode(rawText) as Map<String, dynamic>;
          final result = ScanResult.fromJson(parsed);

          final duration = DateTime.now().difference(startTime).inMilliseconds;
          AppLogger.info('SCAN_AI', 'Text wine analysis succeeded via $model in ${duration}ms: "${result.name}"');

          AiCostTrackerService().recordRawResponse(
            model: model,
            feature: 'text_wine_analysis',
            responseJson: data,
            isSearchGrounded: false,
            userId: _client.auth.currentUser?.id,
          );

          return result;
        }
      } catch (e) {
        AppLogger.warning('SCAN_AI', 'Model $model text wine analysis failed: $e');
      }
    }

    // Heuristic fallback if offline
    return ScanResult(
      name: text.trim().isNotEmpty ? text.trim() : 'Vin Dégusté',
      producer: null,
      vintage: null,
      wineType: 'red',
      country: 'France',
      region: 'France',
      tastingNotes: 'Vin dégusté hors-cave.',
      foodPairings: const [],
      detectedQuantity: 1,
    );
  }
}
