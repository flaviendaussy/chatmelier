import '../../cellar/domain/bottle.dart';
import '../../../shared/utils/langue.dart';

/// Ce dont parle une conversation avec le sommelier (V2.5 · F4) : un vin, ou rien (le chat
/// général).
///
/// 13/10, Flavien, depuis la fiche d'un crozes-hermitage : « à chaque fois qu'on ouvre le
/// Chatmelier à partir d'un vin, d'un menu, etc... ça devrait spin une nouvelle instance du
/// Chatmelier dédiée à cet item, avec son propre historique, et avec un message d'accueil
/// personnalisé sur l'item, avec un knowledge spécifique à l'item, etc... et une interface
/// qui rappelle en partie l'item pour montrer qu'on est pas dans le Chatmelier général ».
///
/// La clé (`vin:<id du vin>`) range l'historique côté serveur (`chat_messages.sujet`,
/// migration 071) : deux bouteilles du même vin partagent leur conversation.
class SujetDeChat {
  final String cle;
  final String? bottleId;
  final String nom;
  final String? millesime;
  final String? domaine;
  final String? appellation;
  final String? region;
  final String? type;

  const SujetDeChat({
    required this.cle,
    required this.nom,
    this.bottleId,
    this.millesime,
    this.domaine,
    this.appellation,
    this.region,
    this.type,
  });

  static final _forme = RegExp(r'^[A-Za-z0-9_-]{1,100}$');

  /// Le sujet d'une fiche de vin ouverte depuis la cave : nul sans identifiant de vin
  /// utilisable (le chat général s'ouvre alors, comme avant).
  static SujetDeChat? vin({
    required String? wineId,
    required String? nom,
    String? bottleId,
    String? millesime,
    String? domaine,
    String? appellation,
    String? region,
    String? type,
  }) {
    final id = (wineId ?? '').trim();
    final n = (nom ?? '').trim();
    if (!_forme.hasMatch(id) || n.isEmpty) return null;
    String? rempli(String? v) => (v ?? '').trim().isEmpty ? null : v!.trim();
    return SujetDeChat(
      cle: 'vin:$id',
      nom: n,
      bottleId: rempli(bottleId),
      millesime: rempli(millesime),
      domaine: rempli(domaine),
      appellation: rempli(appellation),
      region: rempli(region),
      type: rempli(type),
    );
  }

  /// Depuis l'adresse `/chat?wineId=…&wineName=…` que pousse la fiche d'une bouteille.
  static SujetDeChat? depuisLAdresse(Map<String, String> p) => vin(
        wineId: p['wineId'],
        nom: p['wineName'],
        bottleId: p['bottleId'],
        millesime: p['vintage'],
        domaine: p['producer'],
        appellation: p['appellation'],
        region: p['region'],
        type: p['wineType'],
      );

  /// « Crozes-Hermitage 2024 ».
  String get titre => [nom, if (millesime != null) millesime!].join(' ');

  /// « Domaine Combier · Crozes-Hermitage ».
  String? get sousTitre {
    final morceaux = [
      if (domaine != null && !nom.toLowerCase().contains(domaine!.toLowerCase())) domaine!,
      if (appellation != null && !nom.toLowerCase().contains(appellation!.toLowerCase())) appellation!
      else if (region != null) region!,
    ];
    return morceaux.isEmpty ? null : morceaux.join(' · ');
  }

  /// Ce que le sommelier sait de ce vin, en tête de son contexte : la bouteille de la cave
  /// quand on la retrouve (quantité, emplacement, fenêtre de garde, notes), sinon ce que la
  /// fiche a transmis.
  String contexte(List<Bottle> cave) {
    final b = bottleId == null ? null : cave.where((x) => x.id == bottleId).firstOrNull;
    final w = b?.wine;
    final lignes = <String>[
      'CURRENT TOPIC — the user opened this conversation from this wine:',
      '- Wine: $titre${domaine != null ? ' — $domaine' : ''}',
      if (appellation != null || region != null) '- Origin: ${[appellation, region].whereType<String>().join(', ')}',
      if (type != null) '- Type: $type',
      if (w != null) ...[
        if (w.country.isNotEmpty) '- Country: ${w.country}',
        if (w.grapes.isNotEmpty) '- Grapes: ${w.grapes.map((g) => g.name).join(', ')}',
        '- Drinking window: ${w.fenetreEffective.drinkStart}–${w.fenetreEffective.drinkEnd}, '
            'peak ${w.fenetreEffective.peakStart}–${w.fenetreEffective.peakEnd}',
        if ((w.tastingNotes ?? '').trim().isNotEmpty) '- Notes on record: ${w.tastingNotes!.trim()}',
        if (w.alcoholPct != null) '- Alcohol: ${w.alcoholPct}%',
      ],
      if (b != null) ...[
        '- In the cellar: ${b.quantity} bottle(s)'
            '${(b.rack ?? '').isNotEmpty ? ', rack ${b.rack}' : ''}${(b.shelf ?? '').isNotEmpty ? ', shelf ${b.shelf}' : ''}',
        if (b.purchasePrice != null) '- Paid: ${b.purchasePrice} ${b.currency}',
        '- bottle id (for its card only): ${b.id}',
      ],
    ];
    return lignes.join('\n');
  }

  /// L'accueil de la conversation, propre à ce vin.
  String get accueil => tr(
      'Parlons de votre {vin}. Je peux vous dire quand l\'ouvrir, comment le servir, avec quoi le boire, ou ce que raconte son terroir.',
      'Let\'s talk about your {vin}. I can tell you when to open it, how to serve it, what to drink it with, or what its terroir has to say.',
      {'vin': titre});
}
