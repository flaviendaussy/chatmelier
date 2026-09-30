import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/services/fonctions_ia.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/langue.dart';
import '../../cellar/data/cellar_repository.dart';
import '../../cellar/domain/bottle.dart';
import '../../offline/data/offline_storage_service.dart';
import '../../offline/presentation/sync_provider.dart';
import '../../auth/data/taste_profile_service.dart';
import '../../friends/data/friends_repository.dart';
import '../domain/chat_message.dart';
import '../domain/cellar_macro_summary.dart';
import '../domain/cellar_rag_retriever.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  final supabase = ref.read(supabaseProvider);
  final repo = ref.read(cellarRepositoryProvider);
  final offlineStorage = ref.read(offlineStorageServiceProvider);
  final tasteProfileService = ref.read(tasteProfileServiceProvider);
  final ia = FonctionsIa(supabase, assurerUneSession: ref.read(authRepositoryProvider).assurerUneSession);
  return ChatService(supabase, repo, offlineStorage, tasteProfileService, ia: ia);
});

class ChatService {
  final SupabaseClient _client;
  final CellarRepository _repo;
  final OfflineStorageService _offlineStorage;
  final TasteProfileService _tasteProfileService;
  final FonctionsIa _ia;

  ChatService(this._client, this._repo, this._offlineStorage, this._tasteProfileService, {FonctionsIa? ia})
      : _ia = ia ?? FonctionsIa(_client);

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

    // 4. Generate high-density Macro Summary (Metadata on proportions) + RAG candidate retrieval
    final macroSummary = CellarMacroSummary.generate(cellarBottles, languageCode: languageCode);
    final ragResult = CellarRagRetriever.retrieve(
      query: message,
      bottles: cellarBottles,
      maxBottles: 8,
      languageCode: languageCode,
    );

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
            .select('rating, rating_scale, occasion, food_paired, tasting_notes, co_tasters, wines(name, producer, vintage, wine_type, region)')
            .eq('user_id', user.id)
            .order('consumed_at', ascending: false)
            .limit(15);
        recentTastings = List<Map<String, dynamic>>.from(tRes);
      } catch (e) {
        // `rating_scale` arrive avec la migration 032. Son absence n'est pas un incident :
        // c'est la preuve que la contrainte `rating <= 5` tient encore et donc que toutes
        // les notes stockées sont sur 5. On le dit explicitement plutôt que de perdre
        // l'historique du sommelier.
        AppLogger.warning('CHAT_AI', 'Tasting log select with rating_scale failed ($e), retrying without it');
        try {
          final tRes = await _client
              .from('tasting_log')
              .select('rating, occasion, food_paired, tasting_notes, co_tasters, wines(name, producer, vintage, wine_type, region)')
              .eq('user_id', user.id)
              .order('consumed_at', ascending: false)
              .limit(15);
          recentTastings = List<Map<String, dynamic>>.from(tRes)
              .map((t) => {...t, 'rating_scale': 5})
              .toList();
        } catch (e2) {
          AppLogger.warning('CHAT_AI', 'Could not fetch remote tasting logs: $e2');
        }
      }
    }

    final tastingLogSummary = recentTastings.map((t) {
      final w = t['wines'] as Map<String, dynamic>?;
      final rawCo = t['co_tasters'];
      final coList = rawCo is List ? rawCo.map((e) => e.toString()).where((s) => s.isNotEmpty).toList() : <String>[];
      final coStr = coList.isNotEmpty ? ' [Partagé avec : ${coList.join(", ")}]' : '';
      final wType = w?['wine_type'] != null ? 'Type: ${w!['wine_type']}, ' : '';
      // Les lignes antérieures à la migration 032 sont stockées sur 5 : la contrainte
      // `rating <= 5` faisait diviser la note par deux à l'écriture. On les ramène sur 10
      // comme le fait `TastingEntry.displayRating`, sinon le sommelier lit un 5,5/10 en 2,8.
      final rawRating = (t['rating'] as num?)?.toDouble();
      final scale = (t['rating_scale'] as num?)?.toInt() ?? 10;
      final noteStr = rawRating == null
          ? 'non notée'
          : '${(scale == 5 ? rawRating * 2 : rawRating).toStringAsFixed(1)}/10';
      return '- ${w?['name'] ?? "Vin"} (${w?['vintage'] ?? "NM"}, $wType${w?['region'] ?? ""}) : Note $noteStr$coStr, Avis: "${t['tasting_notes'] ?? ""}", Plat: "${t['food_paired'] ?? ""}", Contexte: "${t['occasion'] ?? ""}"';
    }).join('\n');

    // Depuis la V2.3, les consignes du sommelier vivent dans la fonction `chat` ; l'app
    // n'envoie que des données : la cave résumée, les bouteilles choisies pour la question,
    // les palais, les amis et les dernières dégustations.
    final contexte = [
      macroSummary,
      ragResult.formattedContext,
      'TASTE PROFILES OF THE USER AND CO-TASTERS:\n$profilesContext',
      'CONNECTED FRIENDS AND THEIR TASTE CARDS:\n$friendsTasteContext',
      'PAST TASTINGS (what they loved or disliked):\n${tastingLogSummary.isNotEmpty ? tastingLogSummary : '(none recorded yet)'}',
    ].where((p) => p.trim().isNotEmpty).join('\n\n');

    return _ChatContext(
      user: user,
      resolvedCellarId: resolvedCellarId,
      cellarBottles: cellarBottles,
      history: history,
      contexte: contexte.length > 12000 ? contexte.substring(0, 12000) : contexte,
    );
  }

  /// Pose la question au sommelier du serveur. Sans lui (réseau, panne, limite du jour), la
  /// réponse le dit, puis propose une piste tirée de la cave.
  Future<String> _demander(String message, _ChatContext ctx, String languageCode) async {
    final r = await _ia.appeler('chat', {
      'message': message,
      'cellarId': ctx.resolvedCellarId ?? '',
      'contexte': ctx.contexte,
      'langue': languageCode,
    });
    final reply = r.ok ? (r.donnees!['reply']?.toString() ?? '') : '';
    if (reply.isNotEmpty) return reply;
    if (r.limiteAtteinte) return r.messageDeLimite();
    AppLogger.info('CHAT_AI', 'Sommelier injoignable (${r.erreur ?? 'réponse vide'}) : piste locale');
    return '${tr('*Le sommelier est injoignable pour le moment : voici une piste tirée de votre cave, sans lui.*', '*The sommelier can\'t be reached right now: here is a lead from your cellar, without it.*')}\n\n'
        '${_generateLocalSommelierAdvice(message, ctx.cellarBottles, languageCode)}';
  }

  Future<void> _enregistrerLaReponse(_ChatContext ctx, String reply) async {
    if (ctx.resolvedCellarId == null || ctx.resolvedCellarId!.isEmpty || ctx.user == null || reply.isEmpty) return;
    try {
      await _client.from('chat_messages').insert({
        'cellar_id': ctx.resolvedCellarId,
        'user_id': ctx.user!.id,
        'role': 'assistant',
        'content': reply,
      });
    } catch (e) {
      AppLogger.warning('CHAT_AI', 'Réponse non enregistrée : $e');
    }
  }

  Future<String> sendMessage(String message, String? cellarId, {String languageCode = 'fr'}) async {
    final debut = DateTime.now();
    // La question elle-même n'est pas journalisée : c'est une donnée personnelle (V2.3 · B4).
    AppLogger.info('CHAT_AI', 'Question au sommelier (${message.length} caractères)');
    final ctx = await _preparePromptContext(message, cellarId, languageCode);
    final reply = sanitizeCustomerFacingText(await _demander(message, ctx, languageCode));
    AppLogger.info('CHAT_AI', 'Réponse en ${DateTime.now().difference(debut).inMilliseconds} ms');
    await _enregistrerLaReponse(ctx, reply);
    return reply;
  }

  /// La réponse arrive d'un bloc du serveur ; on la déroule mot à mot pour garder l'écriture
  /// progressive de l'écran.
  Stream<String> sendMessageStream(
    String message,
    String? cellarId, {
    String languageCode = 'fr',
  }) async* {
    final debut = DateTime.now();
    AppLogger.info('CHAT_AI', 'Question au sommelier (${message.length} caractères)');
    final ctx = await _preparePromptContext(message, cellarId, languageCode);
    final reply = sanitizeCustomerFacingText(await _demander(message, ctx, languageCode));
    AppLogger.info('CHAT_AI', 'Réponse en ${DateTime.now().difference(debut).inMilliseconds} ms');
    final mots = reply.split(' ');
    for (var i = 0; i < mots.length; i++) {
      yield mots[i] + (i < mots.length - 1 ? ' ' : '');
      await Future<void>.delayed(const Duration(milliseconds: 12));
    }
    await _enregistrerLaReponse(ctx, reply);
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

  /// Efface la conversation d'une cave.
  ///
  /// Ce n'est pas qu'un nettoyage d'affichage : les dix derniers messages sont réinjectés
  /// dans chaque requête (voir `_buildContext`). Tant qu'ils existent, l'IA continue de
  /// répondre à la lumière d'une conversation qu'on croyait effacée.
  Future<void> clearChatHistory(String cellarId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client
        .from('chat_messages')
        .delete()
        .eq('cellar_id', cellarId)
        .eq('user_id', user.id);
    AppLogger.info('CHAT_AI', 'Conversation effacée pour la cave $cellarId');
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
  final String contexte;

  _ChatContext({
    required this.user,
    required this.resolvedCellarId,
    required this.cellarBottles,
    required this.history,
    required this.contexte,
  });
}

