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
    defaultValue: 'AQ.Ab8RN6JFZQNPfXmDdjdGT0posCOmn_4wPIFv_TiviorSGL6BDg',
  );

  ChatService(this._client, this._repo, this._offlineStorage, this._tasteProfileService);

  Future<String> sendMessage(String message, String? cellarId, {String languageCode = 'fr'}) async {
    final startTime = DateTime.now();
    AppLogger.info('CHAT_AI', 'User asked Chatmelier: "$message" (Cellar: $cellarId)');

    // Refresh dynamic models in background
    GeminiModelRegistry.refreshAvailableModels();

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
      };
    }).toList();

    // 5. Fetch taste profiles and connected friends taste cards
    final tasteProfiles = await _tasteProfileService.getProfiles();
    final profilesContext = _tasteProfileService.formatProfilesForSommelier(tasteProfiles);

    final friends = await FriendsRepository(_client).getFriends();
    final friendsTasteContext = _tasteProfileService.formatFriendsForSommelier(friends);

    // 6. Fetch recent tasting logs (cellar + external restaurants/friends)
    List<Map<String, dynamic>> recentTastings = [];
    if (user != null) {
      try {
        final tRes = await _client
            .from('tasting_log')
            .select('rating, occasion, food_paired, tasting_notes, wines(name, producer, vintage, wine_type, region)')
            .eq('user_id', user.id)
            .order('consumed_at', ascending: false)
            .limit(10);
        recentTastings = List<Map<String, dynamic>>.from(tRes);
      } catch (e) {
        AppLogger.warning('CHAT_AI', 'Could not fetch remote tasting logs: $e');
      }
    }

    final tastingLogSummary = recentTastings.map((t) {
      final w = t['wines'] as Map<String, dynamic>?;
      return '- ${w?['name'] ?? "Vin"} (${w?['vintage'] ?? "NM"}, ${w?['region'] ?? ""}) : Note ${t['rating']}/5, Avis: "${t['tasting_notes'] ?? ""}", Plat: "${t['food_paired'] ?? ""}", Contexte: "${t['occasion'] ?? ""}"';
    }).join('\n');

    final langName = languageCode == 'en' ? 'English' : 'French (Français)';
    final currentYear = DateTime.now().year;

    final systemInstruction = '''You are Chatmelier, the world-class sommelier, cellar master, and wine intelligence companion.
Always introduce and refer to yourself strictly as "Chatmelier" (never say "Chatmelier Sommelier", "votre sommelier IA", or "l'IA").
Current Year: $currentYear.
User language: $langName.

CELLAR INVENTORY AVAILABLE IN THE USER'S CELLAR (${bottlesSummary.length} available references):
${jsonEncode(bottlesSummary)}

TASTE PROFILES & PREFERENCES OF USER AND CO-TASTERS:
$profilesContext

CONNECTED FRIENDS & THEIR WINE TASTE CARDS:
$friendsTasteContext

PAST TASTING EXPERIENCES & RECENT FEEDBACK (what they loved or disliked):
${tastingLogSummary.isNotEmpty ? tastingLogSummary : "Pas encore d'historique de dégustation enregistré."}

SOMMELIER RULES:
1. LANGUAGE: Respond strictly in $langName with warmth, passion, elegance, conciseness, and high professional sommelier expertise. Format your answers with clear Markdown (headers, bullet points, bolding).
2. CELLAR GROUNDING:
   - When the user asks what to drink, what to pair with a meal/dish, or asks about their cellar, PRIORITIZE AND HIGHLIGHT matching bottles from their actual cellar inventory!
   - Clearly state why that specific bottle is a fantastic match (grape variety, vintage maturity, tannins, acidity, terroir).
   - Give the exact location in the cellar (Rack / Shelf) when recommending a bottle from their cellar.
   - If no bottle in their cellar fits the dish, explain why gently and recommend the ideal external wine style / appellation to look for.
3. MATURITY & APOGÉE:
   - When discussing drinking windows, respect the exact peak window and status provided.
   - For young powerful wines, recommend decanting time (e.g. 1h30 to 2h) and service temperature (e.g. 16-17°C for Bordeaux/Rhône, 14-15°C for Bourgogne Pinot Noir, 10-12°C for rich white, 8-10°C for Champagne).
4. INTERACTIVE WINE CARDS:
   - Whenever you recommend one or more specific bottles from their cellar (or an ideal wine), insert an interactive card tag on its own line:
   [WINE_CARD: {"id": "bottle_id", "name": "Nom du Vin", "vintage": 2018, "producer": "Domaine", "region": "Bordeaux", "wine_type": "red", "location": "Casier B3", "reason": "Accord parfait avec votre plat"}]
   Use the exact bottle "id" from the cellar inventory when recommending a cellar bottle.
5. VOCABULARY: Always use "bouteille" or "vin". NEVER use the word "flacon".
6. TASTE PROFILE PERSONALIZATION & FRIENDS TASTE CONSULTING:
   - Use individual taste profiles and connected friends' taste cards.
   - When the user asks for wine/vineyard recommendations for a friend or family member (e.g. "quel vin pour mon père?", "que proposer à mes invités pour l'apéro?"):
     * Automatically consult their respective taste card (favorite grape varieties, favorite terroirs/regions, palate sensitivities, and aversions).
     * If geographic criteria or budget is specified, filter for top matching appellations, vignobles/estates or specific cuvées within that terroir and price range!
     * Explicitly explain why this person will love your recommendation based on their taste preferences.
   - When recommending for a couple or group of friends, propose harmonious wines that reconcile everyone's preferences while strictly avoiding their stated aversions.
7. EXPERTISE ŒNOLOGIQUE & MOLÉCULAIRE :
   - Accompagne et explique les vins et dégustations avec passion, précision et profondeur scientifique, en descendant jusqu'au niveau moléculaire lorsque pertinent :
     * Polyphénols & texture : Anthocyanes (malvidine-3-glucoside), tannins condensés (proanthocyanidines), polymérisation au fil des ans et réduction de l'astringence par interaction avec la proline salivaire.
     * Molécules aromatiques emblématiques : Pyrazines (notes végétales nobles/poivron chez Cabernets/Sauvignon), Rotundone (sesquiterpène signature du poivre chez la Syrah), Terpènes (Linalol/Géraniol floraux chez Muscat/Viognier), Thiols volatils (3-mercaptohexanol pour pamplemousse/passion), Diacétyle (2,3-butanedione issu de la fermentation malolactique bactérienne pour le beurre/brioche), Lactones de chêne & vanilline issues du fût.
     * Structure acide & équilibre : Acide tartrique (C₄H₆O₆, colonne vertébrale minérale) et acide malique/lactique.
     * Persistance rétro-nasale mesurée en caudalies (secondes de rémanence).
   - Fais preuve d'une pédagogie captivante et élégante, qui émerveille aussi bien le novice que le passionné érudit.''';

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

    String reply = '';
    final tier = GeminiModelRegistry.classifyChatComplexity(message, conversationTurnCount: history.length);
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
            'parts': [{'text': systemInstruction}]
          },
          'contents': contents,
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
              userId: _client.auth.currentUser?.id,
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
          'cellarId': resolvedCellarId ?? '',
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
      reply = _generateLocalSommelierAdvice(message, cellarBottles, languageCode);
    }

    // Save assistant response to database if authenticated
    if (resolvedCellarId != null && resolvedCellarId.isNotEmpty && user != null) {
      try {
        await _client.from('chat_messages').insert({
          'cellar_id': resolvedCellarId,
          'user_id': user.id,
          'role': 'assistant',
          'content': reply,
        });
      } catch (e) {
        debugPrint('Error saving assistant message: $e');
      }
    }

    return reply;
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
      return "### 🍷 Conseil de Dégustation Chatmelier\n\n"
          "Je suis **Chatmelier**, votre compagnon de cave personnel.\n\n"
          "- **Accords mets-vins** : Indiquez-moi votre plat ou vos ingrédients pour trouver la meilleure bouteille dans votre cave.\n"
          "- **Apogée & Dégustation** : Demandez-moi si un millésime est prêt à boire ou la température idéale de service.";
    } else {
      return "### 🍷 Chatmelier Sommelier Advice\n\n"
          "I am **Chatmelier**, your personal wine advisor.\n\n"
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
