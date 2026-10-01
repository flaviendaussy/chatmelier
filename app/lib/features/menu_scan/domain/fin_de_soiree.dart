import '../../sommelier/domain/guest_matcher_engine.dart';
import 'menu_table_matcher_engine.dart';
import 'menu_wine.dart';

/// Un vin que la table a commandé (V2.3 · E2).
class VinChoisi {
  /// `MenuWine.cacheKey` : retrouve le vin dans la carte.
  final String cle;
  final String nom;
  final String? producteur;
  final int? millesime;

  /// Comme la colonne `wine_type` du journal : red, white, rose, sparkling, dessert.
  final String couleur;

  const VinChoisi({
    required this.cle,
    required this.nom,
    this.producteur,
    this.millesime,
    this.couleur = 'red',
  });

  factory VinChoisi.depuisLaCarte(MenuWine w) => VinChoisi(
        cle: w.cacheKey,
        nom: w.name,
        producteur: w.producer.trim().isEmpty ? null : w.producer.trim(),
        millesime: w.vintage,
        couleur: couleurPourLeJournal(w),
      );

  factory VinChoisi.fromJson(Map<String, dynamic> j) => VinChoisi(
        cle: j['cle']?.toString() ?? '',
        nom: j['nom']?.toString() ?? '',
        producteur: j['producteur']?.toString(),
        millesime: (j['millesime'] as num?)?.toInt(),
        couleur: j['couleur']?.toString() ?? 'red',
      );

  Map<String, dynamic> toJson() => {
        'cle': cle,
        'nom': nom,
        if (producteur != null) 'producteur': producteur,
        if (millesime != null) 'millesime': millesime,
        'couleur': couleur,
      };

  /// « Morgon 2022 ».
  String get libelle => '$nom${millesime != null ? ' $millesime' : ''}';
}

/// La couleur d'un vin de la carte, telle que le journal la range.
String couleurPourLeJournal(MenuWine w) {
  if (w.isSparkling) return 'sparkling';
  if (w.isRose) return 'rose';
  if (w.isWhite) return 'white';
  final t = w.wineType.toLowerCase();
  if (t.contains('dessert') || t.contains('sweet') || t.contains('moelleux') || t.contains('liquoreux')) {
    return 'dessert';
  }
  return 'red';
}

/// Ce que la table a choisi et publié (`lire_etat_table`, migration 057).
class EtatDeTable {
  final List<VinChoisi> choix;
  final Map<String, dynamic>? resultat;
  final DateTime? publieLe;

  const EtatDeTable({this.choix = const [], this.resultat, this.publieLe});

  factory EtatDeTable.fromRow(Map<String, dynamic> r) => EtatDeTable(
        choix: [
          if (r['choix'] is List)
            for (final c in r['choix'] as List)
              if (c is Map) VinChoisi.fromJson(Map<String, dynamic>.from(c)),
        ],
        resultat: r['resultat'] is Map ? Map<String, dynamic>.from(r['resultat'] as Map) : null,
        publieLe: DateTime.tryParse(r['resultat_publie_le']?.toString() ?? ''),
      );
}

/// Noter d'un geste : cinq visages, et ce que chacun vaut sur dix.
///
/// Le milieu de chaque tranche de `TastingQuestionnaireResult.emojiIndexForRating` : relue
/// par le journal, une note donnée d'un geste retombe sur le même visage.
class NoteDUnGeste {
  static const visages = ['😖', '😕', '😐', '😊', '😍'];
  static const notes = [2.5, 4.5, 6.5, 8.0, 9.5];
}

/// Le résultat de la table, publié par l'hôte pour la page invité (V2.3 · F1).
///
/// L'hôte calcule, la page invité affiche : elle n'a rien à recalculer, et rien à
/// dupliquer du moteur de consensus. `raison` et `phrase` sont dans la langue de l'hôte ;
/// `raisons` et `phrases`, quand l'hôte les fournit, dans chaque langue de l'app, pour que
/// chaque convive les lise dans la sienne.
class ResultatDeTable {
  static Map<String, dynamic> publier({
    required String restaurant,
    required String langue,
    required List<GuestProfile> convives,
    required List<MenuTableMatchResult> podium,
    PaireDeBouteilles? paire,
    String? phraseDeLaPaire,
    // Clé du vin → langue → raison.
    Map<String, Map<String, String>> raisonsTraduites = const {},
    Map<String, String> phrasesDeLaPaire = const {},
  }) {
    final nomParId = {for (final g in convives) g.id: g.name};
    return {
      'version': 1,
      'restaurant': restaurant,
      'langue': langue,
      'convives': [
        for (final g in convives)
          {
            'nom': g.name,
            if (g.neBoitPas) 'ne_boit_pas': true,
          },
      ],
      'podium': [
        for (final r in podium)
          {
            'cle': r.menuWine.cacheKey,
            'nom': r.menuWine.name,
            if (r.menuWine.producer.trim().isNotEmpty) 'producteur': r.menuWine.producer.trim(),
            if (r.menuWine.vintage != null) 'millesime': r.menuWine.vintage,
            'couleur': couleurPourLeJournal(r.menuWine),
            if (r.menuWine.bottlePrice != null) 'prix': r.menuWine.formaterPrix(r.menuWine.bottlePrice!),
            'accord': r.harmonyScore.round(),
            'raison': r.consensusRationale,
            if (raisonsTraduites[r.menuWine.cacheKey]?.isNotEmpty ?? false)
              'raisons': raisonsTraduites[r.menuWine.cacheKey],
            'scores': {
              for (final e in r.guestScores.entries) (nomParId[e.key] ?? e.key): e.value.round(),
            },
          },
      ],
      if (paire != null && phraseDeLaPaire != null)
        'paire': {
          'phrase': phraseDeLaPaire,
          if (phrasesDeLaPaire.isNotEmpty) 'phrases': phrasesDeLaPaire,
          'vins': [paire.premiere.menuWine.cacheKey, paire.seconde.menuWine.cacheKey],
        },
    };
  }
}
