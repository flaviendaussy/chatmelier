import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/services/gemini_model_registry.dart';
import '../../../shared/utils/app_logger.dart';
import '../../cellar/data/cellar_repository.dart';
import '../../cellar/domain/bottle.dart';
import '../../offline/data/offline_storage_service.dart';
import '../../offline/presentation/sync_provider.dart';
import '../../auth/data/taste_profile_service.dart';
import '../../auth/data/ai_cost_tracker_service.dart';
import '../../friends/data/friends_repository.dart';
import '../../cocktails/data/bar_pantry_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/chat_message.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  final supabase = ref.read(supabaseProvider);
  final repo = ref.read(cellarRepositoryProvider);
  final offlineStorage = ref.read(offlineStorageServiceProvider);
  final tasteProfileService = ref.read(tasteProfileServiceProvider);
  return ChatService(supabase, repo, offlineStorage, tasteProfileService);
});

class ChatService {
  final SupabaseClient _client;
  final CellarRepository _repo;
  final OfflineStorageService _offlineStorage;
  final TasteProfileService _tasteProfileService;

  static const String _geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  ChatService(this._client, this._repo, this._offlineStorage, this._tasteProfileService);

  /// Strips any raw UUIDs or technical identifier fragments from user-facing text
  static String sanitizeCustomerFacingText(String text) {
    // 1. Strip raw standard UUIDs (e.g. 489c72e6-81a1-43fd-a144-ec8587d55bfb)
    final uuidRegex = RegExp(
      r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b',
    );
    var cleaned = text.replaceAll(uuidRegex, '');

    // 2. Strip leftover id labels like "(id: )", "(ID: )", "(identifiant: )"
    cleaned = cleaned.replaceAll(
      RegExp(r'\(\s*(?:id|ID|identifiant|uuid)\s*:\s*\)', caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'\b(?:id|ID|identifiant|uuid)\s*:\s*(?=[,\.\s\)])', caseSensitive: false),
      '',
    );

    // 3. Strip non-JSON card tags or malformed tags (e.g. [WINE_CARD: uuid] or [WINE_CARD: ])
    cleaned = cleaned.replaceAll(
      RegExp(r'\[(?:WINE_CARD|COCKTAIL_CARD):\s*(?!\{)[^\]]*\]', caseSensitive: false),
      '',
    );

    return cleaned;
  }

  Future<_ChatContext> _preparePromptContext(
    String message,
    String? cellarId,
    String languageCode,
  ) async {
    final user = _client.auth.currentUser;

    // Resolve fallback cellar if null or empty
    String? resolvedCellarId = cellarId;
    if ((resolvedCellarId == null || resolvedCellarId.isEmpty) && user != null) {
      try {
        final cellars = await _repo.getUserCellarsWithRole();
        if (cellars.isNotEmpty) {
          final first = cellars.first;
          final cMap = first['cellars'];
          resolvedCellarId = (cMap is Map ? cMap['id']?.toString() : null) ?? first['cellar_id']?.toString();
          AppLogger.info('CHAT_AI', 'Auto-resolved fallback cellar for Chatmelier: $resolvedCellarId');
        }
      } catch (e) {
        AppLogger.warning('CHAT_AI', 'Could not auto-resolve cellar for Chatmelier: $e');
      }
    }

    // 1. Fetch current cellar bottles inventory for real-time AI grounding
    List<Bottle> cellarBottles = [];
    if (resolvedCellarId != null && resolvedCellarId.isNotEmpty) {
      try {
        cellarBottles = await _repo.getBottles(resolvedCellarId);
      } catch (e) {
        AppLogger.warning('CHAT_AI', 'Could not fetch bottles from repo, checking cache: $e');
        cellarBottles = _offlineStorage.getCachedBottles(resolvedCellarId);
      }
    }

    // 2. Fetch past conversation history (last 10 messages)
    List<Map<String, dynamic>> history = [];
    if (resolvedCellarId != null && resolvedCellarId.isNotEmpty && user != null) {
      try {
        final histRes = await _client
            .from('chat_messages')
            .select('role, content')
            .eq('cellar_id', resolvedCellarId)
            .eq('user_id', user.id)
            .order('created_at', ascending: false)
            .limit(10);
        history = List<Map<String, dynamic>>.from(histRes).reversed.toList();
      } catch (e) {
        debugPrint('Error fetching history: $e');
      }
    }

    // 3. Save user message in database (if authenticated)
    if (resolvedCellarId != null && resolvedCellarId.isNotEmpty && user != null) {
      try {
        await _client.from('chat_messages').insert({
          'cellar_id': resolvedCellarId,
          'user_id': user.id,
          'role': 'user',
          'content': message,
        });
      } catch (e) {
        debugPrint('Error saving user message: $e');
      }
    }

    // 4. Format cellar inventory for sommelier
    final bottlesSummary = cellarBottles.where((b) => !b.isConsumed).map((b) {
      final wine = b.wine;
      return {
        'id': b.id,
        'name': wine?.name ?? 'Vin',
        'producer': wine?.producer ?? '',
        'vintage': wine?.vintage,
        'type': wine?.type ?? 'red',
        'region': wine?.region ?? '',
        'appellation': wine?.appellation ?? '',
        'cuvee': wine?.cuveeParcel ?? '',
        'grapes': wine?.grapes.map((g) => '${g.name} ${g.pct != null ? "(${g.pct}%)" : ""}').join(', '),
        'quantity': b.quantity,
        'location': 'Rack: ${b.rack ?? "-"}, Shelf: ${b.shelf ?? "-"}, Pos: ${b.position ?? "-"}',
        'ideal_drinking_start': wine?.drinkStart,
        'ideal_drinking_end': wine?.drinkEnd,
        'peak_start': wine?.peakStart,
        'peak_end': wine?.peakEnd,
        'status': wine?.windowStatus.name,
        'is_spirit': wine?.isSpirit ?? false,
      };
    }).toList();

    // 5. Fetch taste profiles and connected friends taste cards
    final tasteProfiles = await _tasteProfileService.getProfiles();
    final profilesContext = _tasteProfileService.formatProfilesForSommelier(tasteProfiles);

    final friends = await FriendsRepository(_client).getFriends();
    final friendsTasteContext = _tasteProfileService.formatFriendsForSommelier(friends);

    // 5b. Fetch Bar Pantry fresh ingredients & mixers in stock
    String barPantryContext = "Aucun ingrédient de bar renseigné pour le moment.";
    try {
      final prefs = await SharedPreferences.getInstance();
      final pantryService = BarPantryService(prefs);
      final inStockItems = pantryService.getItems().where((i) => i.inStock).toList();
      if (inStockItems.isNotEmpty) {
        barPantryContext = inStockItems.map((i) => '- ${i.name} (Catégorie: ${i.category.labelFr}, Quantité: ${i.quantity} ${i.unit})').join('\n');
      }
    } catch (_) {}

    // 6. Fetch recent tasting logs (cellar + external restaurants/friends)
    List<Map<String, dynamic>> recentTastings = [];
    if (user != null) {
      try {
        final tRes = await _client
            .from('tasting_log')
            .select('rating, occasion, food_paired, tasting_notes, co_tasters, wines(name, producer, vintage, wine_type, region)')
            .eq('user_id', user.id)
            .order('consumed_at', ascending: false)
            .limit(15);
        recentTastings = List<Map<String, dynamic>>.from(tRes);
      } catch (e) {
        AppLogger.warning('CHAT_AI', 'Could not fetch remote tasting logs: $e');
      }
    }

    final tastingLogSummary = recentTastings.map((t) {
      final w = t['wines'] as Map<String, dynamic>?;
      final rawCo = t['co_tasters'];
      final coList = rawCo is List ? rawCo.map((e) => e.toString()).where((s) => s.isNotEmpty).toList() : <String>[];
      final coStr = coList.isNotEmpty ? ' [Partagé avec : ${coList.join(", ")}]' : '';
      final wType = w?['wine_type'] != null ? 'Type: ${w!['wine_type']}, ' : '';
      return '- ${w?['name'] ?? "Vin"} (${w?['vintage'] ?? "NM"}, $wType${w?['region'] ?? ""}) : Note ${t['rating']}/5$coStr, Avis: "${t['tasting_notes'] ?? ""}", Plat: "${t['food_paired'] ?? ""}", Contexte: "${t['occasion'] ?? ""}"';
    }).join('\n');

    final langName = languageCode == 'en' ? 'English' : 'French (Français)';
    final currentYear = DateTime.now().year;

    final isFirstMessageEver = history.isEmpty;
    final systemInstruction = '''You are Chatmelier, the world-class sommelier, cellar master, mixologist, and wine & cocktail intelligence companion.
Current Year: $currentYear.
User language: $langName.

CRITICAL IDENTITY & INTRODUCTION RULES:
${isFirstMessageEver ? '- This is the user\'s first time chatting with you: you may briefly introduce yourself ONCE as "Chatmelier".' : '- DO NOT INTRODUCE YOURSELF! You already know this user and this is an ongoing dialogue. NEVER repeat "Je suis Chatmelier...", "Bonjour, je suis Chatmelier...", "En tant que Chatmelier...", "En tant que sommelier...", or similar self-introductions. Never start with a generic greeting about who you are. Jump DIRECTLY into your answer and wine/cocktail recommendations!'}
- Never say "Chatmelier Sommelier", "votre sommelier IA", or "l'IA". Refer to yourself strictly as "Chatmelier" only when naturally required.

CELLAR & BAR INVENTORY AVAILABLE IN THE USER'S CELLAR (${bottlesSummary.length} available references, wines & spirits):
${jsonEncode(bottlesSummary)}

BAR PANTRY FRESH INGREDIENTS & MIXERS IN STOCK:
$barPantryContext

TASTE PROFILES & PREFERENCES OF USER AND CO-TASTERS:
$profilesContext

CONNECTED FRIENDS & THEIR WINE TASTE CARDS:
$friendsTasteContext

PAST TASTING EXPERIENCES & RECENT FEEDBACK (what they loved or disliked):
${tastingLogSummary.isNotEmpty ? tastingLogSummary : "Pas encore d'historique de dégustation enregistré."}

SOMMELIER & MIXOLOGIST RULES:
1. LANGUAGE: Respond strictly in $langName with warmth, passion, elegance, conciseness, and high professional expertise. Format your answers with clear Markdown (headers, bullet points, bolding).
2. CELLAR & BAR GROUNDING:
   - When the user asks what to drink, what cocktail to make, what to pair with a meal/dish, or asks about their cellar/bar, PRIORITIZE AND HIGHLIGHT matching bottles from their actual cellar inventory!
   - Clearly state why that specific bottle is a fantastic match.
   - Give the exact location in the cellar (Rack / Shelf) when recommending a bottle from their cellar.
3. COCKTAILS & MIXOLOGY INTELLIGENCE:
   - When the user asks about cocktails, mixed drinks, spirits, or what they can prepare:
     * Cross-reference their available spirits (gin, rhum, whisky, vodka, tequila, liqueurs...) and their fresh Bar Pantry stock (citrons, menthe, ginger beer, tonics, sirops...).
     * Propose classic recipes they have 100% in stock, or craft inventive, balanced, haute-mixologie bespoke cocktails.
     * Follow mixology fundamentals: balance of alcohol, sweet, sour and bitter; proper ice management; dilution; and aromatic garnishes.
   - INTERACTIVE COCKTAIL CARDS:
     Whenever you recommend one or more specific cocktails, generate an interactive cocktail card on its own line:
     [COCKTAIL_CARD: {"name": "Nom du Cocktail", "base_spirit": "gin|rhum|whisky|vodka|tequila|mezcal|etc", "glass": "Coupe ou Verre Old Fashioned", "method": "Au shaker ou Au verre à mélange", "ingredients": ["5 cl Gin", "2.5 cl Jus de citron jaune", "2 cl Sirop de sucre", "10 feuilles de Basilic frais"], "recipe": "Pilonner le basilic avec le citron, ajouter le gin et le sirop, shaker vigoureusement avec de la glace pendant 15s et double-filtrer.", "garnish": "Tête de basilic frais", "reason": "Parfaitement réalisable avec vos ingrédients en stock !"}]
4. INTERACTIVE WINE CARDS:
   - Whenever you recommend one or more specific wine bottles from their cellar (or an ideal wine), insert an interactive card tag on its own line:
   [WINE_CARD: {"id": "bottle_id", "name": "Nom du Vin", "vintage": 2018, "producer": "Domaine", "region": "Bordeaux", "wine_type": "red", "location": "Casier B3", "reason": "Accord parfait avec votre plat"}]
   Use the exact bottle "id" from the cellar inventory when recommending a cellar bottle.
5. VOCABULARY: Always use "bouteille" or "vin". NEVER use the word "flacon".
6. TASTE PROFILE PERSONALIZATION & FRIENDS TASTE CONSULTING:
   - Use individual taste profiles and connected friends' taste cards.
   - When recommending for a couple or group of friends, propose harmonious wines/drinks that reconcile everyone's preferences while strictly avoiding their stated aversions.
   - STRICT FACTUAL GROUNDING ON CONVIVES / FRIENDS' TASTES:
     * NEVER invent or assume unrecorded preferences!
     * If asked about what a co-taster (e.g. Caro) likes, and her profile has very few or no recordings (e.g. she only tasted one white wine), NEVER hallucinate that she loves red wines or terroirs like Galicia!
     * Honestly and factually state what she actually tasted (mentioning the wine and context), and clarify that her palate is still being discovered with future tastings.
7. EXPERTISE ŒNOLOGIQUE & MIXOLOGIQUE :
   - Accompagne et explique les vins et cocktails avec passion, précision et profondeur scientifique (molécules aromatiques, terpènes, équilibre des acides, émulsion au shaker, dilution thermique).
   - Fais preuve d'une pédagogie captivante et élégante, qui émerveille aussi bien le novice que le passionné érudit.
8. ZERO TECHNICAL IDS / NO UUIDS (STRICT CUSTOMER-FACING RULE):
   - NEVER output raw database IDs, UUIDs, or internal identifiers in your conversational text to the user!
   - The bottle "id" MUST ONLY appear inside the hidden [WINE_CARD: {"id": "..."}] JSON tag.
   - NEVER write phrases like "(id: ...)", "(ID: ...)", "id:", "UUID", or mention any hexadecimal strings in your text. The user must only read vineyard names, cuvées, vintages, and producer names.''';

    // Build sanitized alternating conversation history for Gemini API
    final List<Map<String, dynamic>> contents = [];
    String? lastRole;

    for (final m in history) {
      final rawRole = m['role'] as String?;
      final role = rawRole == 'assistant' ? 'model' : 'user';
      final text = (m['content'] as String?)?.trim() ?? '';
      if (text.isEmpty) continue;

      // Gemini history MUST start with a 'user' turn
      if (contents.isEmpty && role != 'user') continue;

      if (role == lastRole && contents.isNotEmpty) {
        // Merge consecutive messages from same role
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

    // Now append the current user message
    if (contents.isNotEmpty && lastRole == 'user') {
      final lastEntry = contents.last;
      final parts = lastEntry['parts'] as List;
      parts.add({'text': message});
    } else {
      contents.add({
        'role': 'user',
        'parts': [{'text': message}],
      });
    }

    return _ChatContext(
      user: user,
      resolvedCellarId: resolvedCellarId,
      cellarBottles: cellarBottles,
      history: history,
      systemInstruction: systemInstruction,
      contents: contents,
    );
  }

  Future<String> sendMessage(String message, String? cellarId, {String languageCode = 'fr'}) async {
    final startTime = DateTime.now();
    AppLogger.info('CHAT_AI', 'User asked Chatmelier: "$message" (Cellar: $cellarId)');

    // Refresh dynamic models in background
    GeminiModelRegistry.refreshAvailableModels();

    final ctx = await _preparePromptContext(message, cellarId, languageCode);

    String reply = '';
    final tier = GeminiModelRegistry.classifyChatComplexity(message, conversationTurnCount: ctx.history.length);
    final activeModels = GeminiModelRegistry.getModelsForTier(tier);
    AppLogger.info('CHAT_AI', 'Chat query routed to tier: ${tier.name} (first model: ${activeModels.isNotEmpty ? activeModels.first : "none"})');

    // Multi-model fallback cascade for chat sommelier
    for (final model in activeModels) {
      try {
        AppLogger.debug('CHAT_AI', 'Calling Gemini ($model)...');

        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_geminiApiKey',
        );

        final body = {
          'systemInstruction': {
            'parts': [{'text': ctx.systemInstruction}]
          },
          'contents': ctx.contents,
          'generationConfig': {
            'maxOutputTokens': 1500,
            'temperature': 0.6,
          },
        };

        final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 25));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
          if (text != null && text.trim().isNotEmpty) {
            reply = text.trim();
            final duration = DateTime.now().difference(startTime).inMilliseconds;
            AppLogger.info('CHAT_AI', 'Chat reply generated via $model in ${duration}ms');

            // Track AI token and cost metrics
            AiCostTrackerService().recordRawResponse(
              model: model,
              feature: 'chat_sommelier',
              responseJson: data,
              promptFallbackText: message,
              candidateFallbackText: reply,
              isSearchGrounded: false,
              userId: ctx.user?.id,
            );
            break;
          }
        } else if (res.statusCode == 429) {
          GeminiModelRegistry.recordRateLimit(model);
          AppLogger.warning('CHAT_AI', 'Model $model returned HTTP 429 (Quota limit), switching to next model');
        } else if (res.statusCode == 404) {
          GeminiModelRegistry.recordDisabledModel(model);
          AppLogger.warning('CHAT_AI', 'Model $model returned HTTP 404, blacklisting model for session');
        } else {
          AppLogger.warning('CHAT_AI', 'Model $model returned HTTP ${res.statusCode}: ${res.body.substring(0, res.body.length > 200 ? 200 : res.body.length)}');
        }
      } catch (e) {
        AppLogger.warning('CHAT_AI', 'Model $model call failed: $e');
      }
      if (reply.isNotEmpty) break;
    }

    // Edge function fallback if direct API calls exhausted
    if (reply.isEmpty) {
      try {
        final edgeRes = await _client.functions.invoke('chat', body: {
          'message': message,
          'cellarId': ctx.resolvedCellarId ?? '',
        });
        if (edgeRes.data is Map<String, dynamic>) {
          reply = edgeRes.data['reply']?.toString() ?? '';
        }
      } catch (e) {
        AppLogger.warning('CHAT_AI', 'Edge function chat fallback failed: $e');
      }
    }

    // Offline local intelligence fallback
    if (reply.isEmpty) {
      AppLogger.info('CHAT_AI', 'Using local sommelier heuristic fallback');
      reply = _generateLocalSommelierAdvice(message, ctx.cellarBottles, languageCode);
    }

    reply = sanitizeCustomerFacingText(reply);

    // Save assistant response to database if authenticated
    if (ctx.resolvedCellarId != null && ctx.resolvedCellarId!.isNotEmpty && ctx.user != null && reply.isNotEmpty) {
      try {
        await _client.from('chat_messages').insert({
          'cellar_id': ctx.resolvedCellarId,
          'user_id': ctx.user!.id,
          'role': 'assistant',
          'content': reply,
        });
      } catch (e) {
        debugPrint('Error saving assistant message: $e');
      }
    }

    return reply;
  }

  /// Streams Chatmelier response token-by-token using Gemini SSE endpoint
  Stream<String> sendMessageStream(
    String message,
    String? cellarId, {
    String languageCode = 'fr',
  }) async* {
    final startTime = DateTime.now();
    AppLogger.info('CHAT_AI', 'User asked Chatmelier (streaming): "$message" (Cellar: $cellarId)');

    GeminiModelRegistry.refreshAvailableModels();

    final ctx = await _preparePromptContext(message, cellarId, languageCode);
    final tier = GeminiModelRegistry.classifyChatComplexity(message, conversationTurnCount: ctx.history.length);
    final activeModels = GeminiModelRegistry.getModelsForTier(tier);

    final StringBuffer fullReplyBuffer = StringBuffer();
    bool streamedSuccessfully = false;

    for (final model in activeModels) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:streamGenerateContent?alt=sse&key=$_geminiApiKey',
        );

        final client = http.Client();
        final request = http.Request('POST', url)
          ..headers['Content-Type'] = 'application/json'
          ..headers['Accept'] = 'text/event-stream'
          ..body = jsonEncode({
            'systemInstruction': {
              'parts': [{'text': ctx.systemInstruction}]
            },
            'contents': ctx.contents,
            'generationConfig': {
              'maxOutputTokens': 1500,
              'temperature': 0.6,
            },
          });

        final streamedResponse = await client.send(request).timeout(const Duration(seconds: 25));

        if (streamedResponse.statusCode == 200) {
          await for (final line in streamedResponse.stream
              .toStringStream()
              .transform(const LineSplitter())) {
            if (line.startsWith('data: ')) {
              final jsonStr = line.substring(6).trim();
              if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;
              try {
                final data = jsonDecode(jsonStr);
                final textChunk = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
                if (textChunk != null && textChunk.isNotEmpty) {
                  final sanitizedChunk = sanitizeCustomerFacingText(textChunk);
                  fullReplyBuffer.write(textChunk);
                  yield sanitizedChunk;
                }
              } catch (_) {}
            }
          }

          if (fullReplyBuffer.isNotEmpty) {
            streamedSuccessfully = true;
            final duration = DateTime.now().difference(startTime).inMilliseconds;
            AppLogger.info('CHAT_AI', 'Streamed chat reply via $model in ${duration}ms');
            break;
          }
        } else if (streamedResponse.statusCode == 429) {
          GeminiModelRegistry.recordRateLimit(model);
        } else if (streamedResponse.statusCode == 404) {
          GeminiModelRegistry.recordDisabledModel(model);
        }
      } catch (e) {
        AppLogger.warning('CHAT_AI', 'Streaming failed for model $model: $e');
      }
    }

    // Fallback if direct SSE streaming did not succeed
    if (!streamedSuccessfully) {
      String fallbackText = '';
      try {
        final edgeRes = await _client.functions.invoke('chat', body: {
          'message': message,
          'cellarId': ctx.resolvedCellarId ?? '',
        });
        if (edgeRes.data is Map<String, dynamic>) {
          fallbackText = edgeRes.data['reply']?.toString() ?? '';
        }
      } catch (_) {}

      if (fallbackText.isEmpty) {
        fallbackText = _generateLocalSommelierAdvice(message, ctx.cellarBottles, languageCode);
      }

      fallbackText = sanitizeCustomerFacingText(fallbackText);
      fullReplyBuffer.write(fallbackText);

      final words = fallbackText.split(' ');
      for (int i = 0; i < words.length; i++) {
        yield words[i] + (i < words.length - 1 ? ' ' : '');
        await Future.delayed(const Duration(milliseconds: 20));
      }
    }

    final finalReply = sanitizeCustomerFacingText(fullReplyBuffer.toString().trim());

    if (ctx.resolvedCellarId != null && ctx.resolvedCellarId!.isNotEmpty && ctx.user != null && finalReply.isNotEmpty) {
      try {
        await _client.from('chat_messages').insert({
          'cellar_id': ctx.resolvedCellarId,
          'user_id': ctx.user!.id,
          'role': 'assistant',
          'content': finalReply,
        });
      } catch (e) {
        debugPrint('Error saving assistant message: $e');
      }
    }
  }

  String _generateLocalSommelierAdvice(String query, List<Bottle> bottles, String langCode) {
    final q = query.toLowerCase();
    final isFr = langCode == 'fr';

    // Check if user has matching bottles in cellar
    Bottle? bestMatch;
    for (final b in bottles) {
      if (b.isConsumed) continue;
      final bw = b.wine;
      if (bw == null) continue;
      final reg = bw.region.toLowerCase();
      final app = (bw.appellation ?? '').toLowerCase();

      if (q.contains('viande') || q.contains('boeuf') || q.contains('steak') || q.contains('côte') || q.contains('magret')) {
        if (bw.type.contains('red') && (reg.contains('bordeaux') || reg.contains('rhône') || app.contains('bandol') || reg.contains('bourgogne'))) {
          bestMatch = b;
          break;
        }
      } else if (q.contains('poisson') || q.contains('huitre') || q.contains('mer') || q.contains('saumon')) {
        if (bw.type.contains('white') && (reg.contains('chablis') || reg.contains('bourgogne') || reg.contains('loire') || reg.contains('alsace'))) {
          bestMatch = b;
          break;
        }
      }
    }

    if (q.contains('viande') || q.contains('boeuf') || q.contains('côte') || q.contains('steak') || q.contains('gibier')) {
      if (isFr) {
        final buffer = StringBuffer();
        buffer.writeln("### 🥩 Accord Idéal pour Viande Rouge / Grillades\n");
        if (bestMatch != null) {
          final wineName = bestMatch.wine != null ? bestMatch.wine!.fullDisplayName : 'bouteille';
          buffer.writeln("Dans votre cave, je vous recommande tout particulièrement votre **$wineName** !\n");
          buffer.writeln("[WINE_CARD: {\"id\": \"${bestMatch.id}\", \"name\": \"${bestMatch.wine?.name}\", \"vintage\": ${bestMatch.wine?.vintage ?? 2020}, \"producer\": \"${bestMatch.wine?.producer ?? ''}\", \"region\": \"${bestMatch.wine?.region ?? ''}\", \"wine_type\": \"red\", \"location\": \"Casier ${bestMatch.rack ?? '-'}\", \"reason\": \"Idéal sur viande rouge\"}]\n");
        }
        buffer.writeln("1. **Bordeaux / Médoc ou Rhône Septentrional** : La puissance tannique enrobe parfaitement le jus et le gras de la viande.");
        buffer.writeln("2. **Température de service** : **16°C à 17°C** (carafez 1h à l'avance si le millésime a moins de 8 ans).");
        return buffer.toString();
      } else {
        return "### 🥩 Ideal Pairing for Red Meat / Steaks\n\n"
            "For a grilled ribeye or roasted red meat, here are my sommelier recommendations:\n\n"
            "1. **Bordeaux / Médoc or Northern Rhône**: Rich tannins and deep dark fruit notes balance the savory richness.\n"
            "2. **Service temperature**: 16°C to 17°C with 1 to 2 hours decanting for younger vintages.";
      }
    }

    if (q.contains('poisson') || q.contains('fruits de mer') || q.contains('huitre') || q.contains('huître') || q.contains('saumon')) {
      if (isFr) {
        final buffer = StringBuffer();
        buffer.writeln("### 🐟 Accord Idéal pour Poissons & Fruits de Mer\n");
        if (bestMatch != null) {
          final wineName = bestMatch.wine != null ? bestMatch.wine!.fullDisplayName : 'bouteille';
          buffer.writeln("Dans votre cave, je vous conseille d'ouvrir votre **$wineName** !\n");
          buffer.writeln("[WINE_CARD: {\"id\": \"${bestMatch.id}\", \"name\": \"${bestMatch.wine?.name}\", \"vintage\": ${bestMatch.wine?.vintage ?? 2022}, \"producer\": \"${bestMatch.wine?.producer ?? ''}\", \"region\": \"${bestMatch.wine?.region ?? ''}\", \"wine_type\": \"white\", \"location\": \"Casier ${bestMatch.rack ?? '-'}\", \"reason\": \"Fraîcheur iodée idéale\"}]\n");
        }
        buffer.writeln("1. **Chablis / Sancerre blanc** : Minéralité tranchante et vivacité pour accompagner la chair délicate.");
        buffer.writeln("2. **Température de service** : **9°C à 11°C**.");
        return buffer.toString();
      }
    }

    if (q.contains('fromage') || q.contains('cheese') || q.contains('chèvre')) {
      if (isFr) {
        return "### 🧀 Accord Fromages & Vins\n\n"
            "Contrairement aux idées reçues, les vins blancs sont souvent les meilleurs compagnons du fromage :\n\n"
            "1. **Chèvre** : Sancerre blanc ou Pouilly-Fumé (Sauvignon blanc vif et minéral).\n"
            "2. **Pâtes dures (Comté affiné, Beaufort)** : Vin Jaune du Jura ou grand Chardonnay boisé.\n"
            "3. **Pâtes persillées (Roquefort, Bleu)** : Vin liquoreux (Sauternes, Monbazillac).";
      }
    }

    if (isFr) {
      return "### 🍷 Conseils & Suggestions Sommelier\n\n"
          "- **Accords mets-vins** : Indiquez-moi votre plat ou vos ingrédients pour trouver la meilleure bouteille dans votre cave.\n"
          "- **Apogée & Dégustation** : Demandez-moi si un millésime est prêt à boire ou la température idéale de service.";
    } else {
      return "### 🍷 Sommelier Recommendations\n\n"
          "- **Food Pairing**: Tell me what you're cooking and I'll find the best matching bottle in your cellar.\n"
          "- **Drinking Windows**: Ask me which bottles are at their peak or how long to decant.";
    }
  }

  Future<List<ChatMessage>> getChatHistory(String cellarId) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final res = await _client
          .from('chat_messages')
          .select()
          .eq('cellar_id', cellarId)
          .eq('user_id', user.id)
          .order('created_at', ascending: true);

      return (res as List<dynamic>)
          .map((j) => ChatMessage.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting chat history: $e');
      return [];
    }
  }
}

class _ChatContext {
  final User? user;
  final String? resolvedCellarId;
  final List<Bottle> cellarBottles;
  final List<Map<String, dynamic>> history;
  final String systemInstruction;
  final List<Map<String, dynamic>> contents;

  _ChatContext({
    required this.user,
    required this.resolvedCellarId,
    required this.cellarBottles,
    required this.history,
    required this.systemInstruction,
    required this.contents,
  });
}

