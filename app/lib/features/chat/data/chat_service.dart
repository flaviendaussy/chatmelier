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
import '../domain/bouteilles_citees.dart';
import '../domain/chat_message.dart';
import '../domain/sujet_de_chat.dart';
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

  /// Sans la colonne `sujet` (migration 071 pas encore appliquée), une conversation dédiée
  /// à un vin n'est pas gardée : mieux vaut qu'elle se perde que de se mêler au chat général.
  static bool _colonneSujetAbsente(Object e) => e.toString().contains('sujet');

  Future<_ChatContext> _preparePromptContext(
    String message,
    String? cellarId,
    String languageCode, {
    SujetDeChat? sujet,
  }) async {
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

    // 2. Save user message in database (if authenticated). L'historique, lui, est relu par
    // la fonction `chat`, sujet par sujet.
    if (resolvedCellarId != null && resolvedCellarId.isNotEmpty && user != null) {
      await _enregistrer(resolvedCellarId, user.id, 'user', message, sujet);
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
      // Le vin d'où la conversation est ouverte, en tête : le sommelier en parle d'abord.
      if (sujet != null) sujet.contexte(cellarBottles),
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
      sujet: sujet,
      contexte: contexte.length > 12000 ? contexte.substring(0, 12000) : contexte,
    );
  }

  /// Un message de la conversation, rangé sous son sujet.
  Future<void> _enregistrer(String cellarId, String userId, String role, String contenu, SujetDeChat? sujet) async {
    try {
      await _client.from('chat_messages').insert({
        'cellar_id': cellarId,
        'user_id': userId,
        'role': role,
        'content': contenu,
        if (sujet != null) 'sujet': sujet.cle,
      });
    } catch (e) {
      AppLogger.warning(
          'CHAT_AI',
          sujet != null && _colonneSujetAbsente(e)
              ? 'Conversation dédiée non gardée : migration 071 absente'
              : 'Message non enregistré : $e');
    }
  }

  /// Pose la question au sommelier du serveur. Sans lui (réseau, panne, limite du jour), la
  /// réponse le dit, puis propose une piste tirée de la cave.
  Future<String> _demander(String message, _ChatContext ctx, String languageCode) async {
    final r = await _ia.appeler('chat', {
      'message': message,
      'cellarId': ctx.resolvedCellarId ?? '',
      'contexte': ctx.contexte,
      'langue': languageCode,
      if (ctx.sujet != null) 'sujet': ctx.sujet!.cle,
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
    await _enregistrer(ctx.resolvedCellarId!, ctx.user!.id, 'assistant', reply, ctx.sujet);
  }

  /// La réponse nettoyée, et la carte de chaque bouteille de la cave qu'elle nomme sans
  /// la poser (V2.5 · F5 : « tu me parles de "cette rioja" […] il manque la carte »).
  String _reponseFinale(String brute, _ChatContext ctx) =>
      BouteillesCitees.avecLeursCartes(sanitizeCustomerFacingText(brute), ctx.cellarBottles);

  Future<String> sendMessage(String message, String? cellarId, {String languageCode = 'fr', SujetDeChat? sujet}) async {
    final debut = DateTime.now();
    // La question elle-même n'est pas journalisée : c'est une donnée personnelle (V2.3 · B4).
    AppLogger.info('CHAT_AI', 'Question au sommelier (${message.length} caractères)');
    final ctx = await _preparePromptContext(message, cellarId, languageCode, sujet: sujet);
    final reply = _reponseFinale(await _demander(message, ctx, languageCode), ctx);
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
    SujetDeChat? sujet,
  }) async* {
    final debut = DateTime.now();
    AppLogger.info('CHAT_AI', 'Question au sommelier (${message.length} caractères)');
    final ctx = await _preparePromptContext(message, cellarId, languageCode, sujet: sujet);
    final reply = _reponseFinale(await _demander(message, ctx, languageCode), ctx);
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
    // Les mots des questions, en français, en anglais et en espagnol.
    bool parle(List<String> mots) => mots.any(q.contains);
    final viande = parle(['viande', 'boeuf', 'bœuf', 'steak', 'côte de b', 'entrecôte', 'magret', 'gibier', 'beef', 'lamb', 'carne', 'ternera', 'cordero', 'chuletón']);
    final poisson = parle(['poisson', 'fruits de mer', 'huitre', 'huître', 'saumon', 'fish', 'seafood', 'oyster', 'salmon', 'pescado', 'marisco', 'ostra', 'salmón']);
    final fromage = parle(['fromage', 'cheese', 'chèvre', 'queso']);

    // Check if user has matching bottles in cellar
    Bottle? bestMatch;
    for (final b in bottles) {
      if (b.isConsumed) continue;
      final bw = b.wine;
      if (bw == null) continue;
      final reg = bw.region.toLowerCase();
      final app = (bw.appellation ?? '').toLowerCase();

      if (viande) {
        if (bw.type.contains('red') && (reg.contains('bordeaux') || reg.contains('rhône') || app.contains('bandol') || reg.contains('bourgogne'))) {
          bestMatch = b;
          break;
        }
      } else if (poisson) {
        if (bw.type.contains('white') && (reg.contains('chablis') || reg.contains('bourgogne') || reg.contains('loire') || reg.contains('alsace'))) {
          bestMatch = b;
          break;
        }
      }
    }

    String carte(Bottle b, int millesimeParDefaut, String couleur, String raison) =>
        "[WINE_CARD: {\"id\": \"${b.id}\", \"name\": \"${b.wine?.name}\", \"vintage\": ${b.wine?.vintage ?? millesimeParDefaut}, \"producer\": \"${b.wine?.producer ?? ''}\", \"region\": \"${b.wine?.region ?? ''}\", \"wine_type\": \"$couleur\", \"location\": \"${trSi(isFr, 'Casier', 'Rack')} ${b.rack ?? '-'}\", \"reason\": \"$raison\"}]\n";

    if (viande) {
      final buffer = StringBuffer();
      buffer.writeln(trSi(isFr, '### 🥩 Accord Idéal pour Viande Rouge / Grillades\n', '### 🥩 Ideal Pairing for Red Meat / Steaks\n'));
      if (bestMatch != null) {
        final wineName = bestMatch.wine != null ? bestMatch.wine!.fullDisplayName : trSi(isFr, 'bouteille', 'bottle');
        buffer.writeln(trSi(isFr, 'Dans votre cave, je vous recommande tout particulièrement votre **{vin}** !\n', 'From your cellar, I especially recommend your **{vin}**!\n', {'vin': wineName}));
        buffer.writeln(carte(bestMatch, 2020, 'red', trSi(isFr, 'Idéal sur viande rouge', 'Ideal with red meat')));
      }
      buffer.writeln(trSi(isFr, '1. **Bordeaux / Médoc ou Rhône Septentrional** : La puissance tannique enrobe parfaitement le jus et le gras de la viande.', '1. **Bordeaux / Médoc or Northern Rhône**: Rich tannins and deep dark fruit notes balance the savory richness.'));
      buffer.writeln(trSi(isFr, '2. **Température de service** : **16°C à 17°C** (carafez 1h à l\'avance si le millésime a moins de 8 ans).', '2. **Service temperature**: **16°C to 17°C** (decant 1 hour ahead if the vintage is less than 8 years old).'));
      return buffer.toString();
    }

    if (poisson) {
      final buffer = StringBuffer();
      buffer.writeln(trSi(isFr, '### 🐟 Accord Idéal pour Poissons & Fruits de Mer\n', '### 🐟 Ideal Pairing for Fish & Seafood\n'));
      if (bestMatch != null) {
        final wineName = bestMatch.wine != null ? bestMatch.wine!.fullDisplayName : trSi(isFr, 'bouteille', 'bottle');
        buffer.writeln(trSi(isFr, 'Dans votre cave, je vous conseille d\'ouvrir votre **{vin}** !\n', 'From your cellar, I suggest opening your **{vin}**!\n', {'vin': wineName}));
        buffer.writeln(carte(bestMatch, 2022, 'white', trSi(isFr, 'Fraîcheur iodée idéale', 'Ideal briny freshness')));
      }
      buffer.writeln(trSi(isFr, '1. **Chablis / Sancerre blanc** : Minéralité tranchante et vivacité pour accompagner la chair délicate.', '1. **Chablis / white Sancerre**: Sharp minerality and freshness for delicate fish.'));
      buffer.writeln(trSi(isFr, '2. **Température de service** : **9°C à 11°C**.', '2. **Service temperature**: **9°C to 11°C**.'));
      return buffer.toString();
    }

    if (fromage) {
      return trSi(isFr, '### 🧀 Accord Fromages & Vins\n\n'
          'Contrairement aux idées reçues, les vins blancs sont souvent les meilleurs compagnons du fromage :\n\n'
          '1. **Chèvre** : Sancerre blanc ou Pouilly-Fumé (Sauvignon blanc vif et minéral).\n'
          '2. **Pâtes dures (Comté affiné, Beaufort)** : Vin Jaune du Jura ou grand Chardonnay boisé.\n'
          '3. **Pâtes persillées (Roquefort, Bleu)** : Vin liquoreux (Sauternes, Monbazillac).',
          '### 🧀 Cheese & Wine Pairing\n\n'
          'Contrary to popular belief, white wines are often the best partners for cheese:\n\n'
          '1. **Goat\'s cheese**: white Sancerre or Pouilly-Fumé (crisp, mineral Sauvignon Blanc).\n'
          '2. **Hard cheeses (aged Comté, Beaufort)**: Vin Jaune from the Jura or a great oaked Chardonnay.\n'
          '3. **Blue cheeses (Roquefort, Stilton)**: a sweet wine (Sauternes, Monbazillac).');
    }

    return trSi(isFr, '### 🍷 Conseils & Suggestions Sommelier\n\n'
        '- **Accords mets-vins** : Indiquez-moi votre plat ou vos ingrédients pour trouver la meilleure bouteille dans votre cave.\n'
        '- **Apogée & Dégustation** : Demandez-moi si un millésime est prêt à boire ou la température idéale de service.',
        '### 🍷 Sommelier Recommendations\n\n'
        '- **Food Pairing**: Tell me what you\'re cooking and I\'ll find the best matching bottle in your cellar.\n'
        '- **Drinking Windows**: Ask me which bottles are at their peak or how long to decant.');
  }

  /// Efface la conversation d'une cave.
  ///
  /// Ce n'est pas qu'un nettoyage d'affichage : les dix derniers messages sont réinjectés
  /// dans chaque requête (voir `_buildContext`). Tant qu'ils existent, l'IA continue de
  /// répondre à la lumière d'une conversation qu'on croyait effacée.
  ///
  /// Une conversation à la fois : effacer celle d'un vin laisse le chat général, et
  /// inversement. Jusqu'à la migration 071, aucune règle ne permettait de supprimer ses
  /// messages : « Effacer » ne supprimait rien, et le sommelier relisait la conversation.
  Future<void> clearChatHistory(String cellarId, {SujetDeChat? sujet}) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    var requete = _client.from('chat_messages').delete().eq('cellar_id', cellarId).eq('user_id', user.id);
    requete = sujet != null ? requete.eq('sujet', sujet.cle) : requete.isFilter('sujet', null);
    final effaces = await requete.select('id');
    AppLogger.info('CHAT_AI', 'Conversation effacée (${(effaces as List).length} messages)${sujet != null ? ' sur un vin' : ''}');
  }

  Future<List<ChatMessage>> getChatHistory(String cellarId, {SujetDeChat? sujet}) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    Future<List<ChatMessage>> lire(bool parSujet) async {
      var requete = _client.from('chat_messages').select().eq('cellar_id', cellarId).eq('user_id', user.id);
      if (parSujet) requete = sujet != null ? requete.eq('sujet', sujet.cle) : requete.isFilter('sujet', null);
      final res = await requete.order('created_at', ascending: true);
      return (res as List<dynamic>).map((j) => ChatMessage.fromJson(j as Map<String, dynamic>)).toList();
    }

    try {
      return await lire(true);
    } catch (e) {
      // Sans la colonne `sujet` : le chat général relit tout, comme avant ; un chat dédié
      // part de zéro.
      if (sujet == null && _colonneSujetAbsente(e)) {
        try {
          return await lire(false);
        } catch (_) {}
      }
      debugPrint('Error getting chat history: $e');
      return [];
    }
  }
}

class _ChatContext {
  final User? user;
  final String? resolvedCellarId;
  final List<Bottle> cellarBottles;
  final SujetDeChat? sujet;
  final String contexte;

  _ChatContext({
    required this.user,
    required this.resolvedCellarId,
    required this.cellarBottles,
    required this.sujet,
    required this.contexte,
  });
}

