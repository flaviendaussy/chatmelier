import 'dart:math' as math;
import '../../cellar/domain/bottle.dart';
import '../../cellar/domain/wine.dart';
import '../../auth/domain/taste_profile.dart';
import '../../auth/domain/wine_taste_radar.dart';
import '../../journal/domain/questionnaire_de_degustation.dart';
import '../../../shared/utils/langue.dart';
import 'profil_du_vin_de_cave.dart';

/// Représente un convive pour la recherche d'accord partagé.
class GuestProfile {
  final String id;
  final String name;
  final String? avatarUrl;
  final TasteProfile? tasteProfile;
  final List<String> favoriteTypes;
  final List<String> favoriteGrapes;
  final List<String> dislikedCharacteristics;
  final String archetype;

  /// Le radar d'un convive venu d'ailleurs.
  ///
  /// Un invité qui rejoint une table depuis son téléphone n'apporte pas son `TasteProfile`
  /// entier — celui-ci est local à son appareil. Il apporte ses huit axes, qui sont tout
  /// ce dont le moteur de consensus a besoin. Sans ce champ, un convive distant retombait
  /// sur le radar grossier déduit de son archétype, et la table votait sur une caricature
  /// de son goût.
  final WineTasteRadarMetrics? radarDistant;

  /// Venu « juste avec son prénom » : il est compté à table, mais ne pèse pas sur le
  /// classement — on ne devine pas les goûts de quelqu'un qui n'a rien dit.
  final bool sansPreferences;

  /// Ses avis au matchmaker de table : clé du vin (`MenuWine.cacheKey`) → avis
  /// (`AvisDeTable.name`). Ils voyagent dans le profil envoyé à la table, et pèsent plus
  /// que ce que le moteur devine.
  final Map<String, String> avis;

  /// « Je ne bois pas ce soir » (V2.3 · E3) : il est à table, mais sans vin à choisir. Il
  /// ne vote pas et ne compte pas parmi les buveurs à satisfaire.
  final bool neBoitPas;

  const GuestProfile({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.tasteProfile,
    this.favoriteTypes = const [],
    this.favoriteGrapes = const [],
    this.dislikedCharacteristics = const [],
    this.archetype = 'Curieux & Éclectique',
    this.radarDistant,
    this.sansPreferences = false,
    this.avis = const {},
    this.neBoitPas = false,
  });

  /// Le même convive, sous un autre identifiant, un autre prénom ou avec d'autres avis.
  GuestProfile copie({String? id, String? name, Map<String, String>? avis, bool? neBoitPas}) => GuestProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        avatarUrl: avatarUrl,
        tasteProfile: tasteProfile,
        favoriteTypes: favoriteTypes,
        favoriteGrapes: favoriteGrapes,
        dislikedCharacteristics: dislikedCharacteristics,
        archetype: archetype,
        radarDistant: radarDistant,
        sansPreferences: sansPreferences,
        avis: avis ?? this.avis,
        neBoitPas: neBoitPas ?? this.neBoitPas,
      );

  /// Ce qu'un convive emporte avec lui en rejoignant une table.
  ///
  /// Volontairement maigre : un nom, des préférences déclarées et huit nombres. Pas
  /// l'historique de dégustations, pas la cave, pas l'identifiant de compte — rien de ce
  /// que les autres convives n'ont pas besoin de savoir pour choisir une bouteille.
  Map<String, dynamic> toJson() => {
        'name': name,
        'archetype': archetype,
        'favorite_types': favoriteTypes,
        'favorite_grapes': favoriteGrapes,
        'disliked': dislikedCharacteristics,
        if (sansPreferences) 'sans_preferences': true,
        if (neBoitPas) 'ne_boit_pas': true,
        if (avis.isNotEmpty) 'avis': avis,
        'radar': {
          'tannin': radar.tannin,
          'body': radar.body,
          'oak': radar.oak,
          'ripe_fruit': radar.ripeFruit,
          'spice': radar.spice,
          'fresh_fruit': radar.freshFruit,
          'minerality': radar.minerality,
          'acidity': radar.acidity,
        },
      };

  factory GuestProfile.fromJson(String id, Map<String, dynamic> json) {
    final r = json['radar'];
    double axe(String cle, double defaut) => r is Map
        ? (double.tryParse(r[cle]?.toString() ?? '') ?? defaut)
        : defaut;
    List<String> liste(String cle) =>
        (json[cle] as List?)?.map((e) => e.toString()).toList() ?? const [];

    return GuestProfile(
      id: id,
      name: (json['name'] ?? 'Convive').toString(),
      archetype: (json['archetype'] ?? 'Curieux & Éclectique').toString(),
      favoriteTypes: liste('favorite_types'),
      favoriteGrapes: liste('favorite_grapes'),
      dislikedCharacteristics: liste('disliked'),
      sansPreferences: json['sans_preferences'] == true,
      neBoitPas: json['ne_boit_pas'] == true,
      avis: json['avis'] is Map
          ? {for (final e in (json['avis'] as Map).entries) e.key.toString(): e.value.toString()}
          : const {},
      radarDistant: r is Map
          ? WineTasteRadarMetrics(
              tannin: axe('tannin', 5.0),
              body: axe('body', 5.0),
              oak: axe('oak', 3.0),
              ripeFruit: axe('ripe_fruit', 5.0),
              spice: axe('spice', 4.0),
              freshFruit: axe('fresh_fruit', 5.5),
              minerality: axe('minerality', 5.0),
              acidity: axe('acidity', 5.5),
            )
          : null,
    );
  }

  /// [nom] remplace le nom stocké du profil : le profil principal s'appelle « Moi » en
  /// base, il doit se lire « Me » en anglais.
  factory GuestProfile.fromTasteProfile(TasteProfile tp, {String? avatarUrl, String? nom}) {
    return GuestProfile(
      id: tp.id,
      name: nom ?? tp.name,
      avatarUrl: avatarUrl,
      tasteProfile: tp,
      favoriteTypes: tp.favoriteTypes,
      favoriteGrapes: tp.favoriteGrapes,
      dislikedCharacteristics: tp.dislikedCharacteristics,
      archetype: _detectArchetype(tp),
    );
  }

  /// L'archétype à l'écran, dans la langue du lecteur.
  ///
  /// La valeur stockée ne change pas : pour un convive sans radar, [radar] s'en sert de
  /// clé (« Minéral », « Puissant »…), la traduire casserait la déduction. On traduit
  /// dans les deux sens : un invité qui a rejoint en anglais s'affiche en français chez
  /// un hôte francophone.
  static String archetypeAffiche(String archetype, bool fr) {
    const versAnglais = {
      'Curieux & Éclectique': 'Curious & eclectic',
      'Amateur de Grands Rouges Puissants': 'Lover of big, powerful reds',
      'Adepte de Minéralité & Fraîcheur Droite': 'Mineral & crisp lover',
      'Palais Friand & Fruit Croquant': 'Crunchy-fruit lover',
      'Amateur de Vins Épicés & Singuliers': 'Spicy & singular wines lover',
      'Aversion aux tanins durs': 'Dislikes firm tannins',
      'Aversion Tanins Durs': 'Dislikes firm tannins',
      'Grands Rouges Puissants': 'Big, powerful reds',
      'Blancs Minéraux & Tendus': 'Taut, mineral whites',
      'Blancs Minéraux & Frais': 'Crisp, mineral whites',
      'Rouges Fruits Croquants': 'Crunchy fruity reds',
      'Fruit Croquant': 'Crunchy fruit',
      'Sans préférences déclarées': 'No stated preferences',
      'Ne boit pas ce soir': 'Not drinking tonight',
    };
    // La clé française d'abord : un invité anglophone a pu l'enregistrer en anglais.
    var francais = archetype;
    if (!versAnglais.containsKey(archetype)) {
      for (final e in versAnglais.entries) {
        if (e.value == archetype) {
          francais = e.key;
          break;
        }
      }
    }
    return trDonneeSi(fr, francais, versAnglais);
  }

  static String _detectArchetype(TasteProfile tp) {
    final radar = tp.radarMetrics;
    if (radar.tannin >= 7.0 && radar.body >= 7.0) {
      return 'Amateur de Grands Rouges Puissants';
    } else if (radar.acidity >= 7.0 && radar.minerality >= 6.5) {
      return 'Adepte de Minéralité & Fraîcheur Droite';
    } else if (radar.freshFruit >= 7.0) {
      return 'Palais Friand & Fruit Croquant';
    } else if (radar.spice >= 7.0) {
      return 'Amateur de Vins Épicés & Singuliers';
    }
    return 'Curieux & Éclectique';
  }

  WineTasteRadarMetrics get radar {
    // Le radar transmis prime : il vient d'un vrai profil, mesuré sur l'appareil de son
    // propriétaire, là où l'archétype n'est qu'une étiquette.
    if (radarDistant != null) return radarDistant!;
    if (tasteProfile != null) {
      return tasteProfile!.radarMetrics;
    }
    if (archetype.contains('Minéral') || archetype.contains('Blanc')) {
      return const WineTasteRadarMetrics(
        tannin: 0.0,
        body: 5.0,
        oak: 2.0,
        ripeFruit: 4.5,
        spice: 3.0,
        freshFruit: 7.0,
        minerality: 7.5,
        acidity: 7.0,
      );
    }
    if (archetype.contains('Puissant') || archetype.contains('Tannique')) {
      return const WineTasteRadarMetrics(
        tannin: 8.0,
        body: 8.0,
        oak: 6.0,
        ripeFruit: 7.0,
        spice: 6.5,
        freshFruit: 5.0,
        minerality: 5.0,
        acidity: 4.5,
      );
    }
    // Fallback radar selon archétype
    return const WineTasteRadarMetrics(
      tannin: 4.0,
      body: 5.0,
      oak: 3.5,
      ripeFruit: 5.0,
      spice: 4.5,
      freshFruit: 6.0,
      minerality: 5.5,
      acidity: 5.5,
    );
  }
}

/// Résultat du calcul d'accord pour une bouteille donnée.
class GuestMatchResult {
  final Bottle bottle;
  final double consensusScore; // 0 à 100 %
  final Map<String, double> guestScores; // guestId -> score
  final List<String> aversionAlerts; // Liste des alertes d'aversions détectées
  final String sommelierRationale;

  /// Où en est la bouteille ce soir : elle départage deux accords voisins.
  final DrinkWindowStatus? maturite;

  const GuestMatchResult({
    required this.bottle,
    required this.consensusScore,
    required this.guestScores,
    required this.aversionAlerts,
    required this.sommelierRationale,
    this.maturite,
  });
}

class GuestMatcherEngine {
  /// Calcule et classe les bouteilles de la cave pour maximiser le plaisir de l'ensemble des convives.
  static List<GuestMatchResult> rankBottlesForGuests({
    required List<Bottle> bottles,
    required List<GuestProfile> guests,
    int maxResults = 10,
    String? idLecteur,
  }) {
    if (bottles.isEmpty || guests.isEmpty) return const [];

    final results = <GuestMatchResult>[];

    for (final bottle in bottles) {
      final wine = bottle.wine;
      if (wine == null) continue;

      final wineRadar = ProfilDuVinDeCave.estimer(wine);
      final guestScores = <String, double>{};
      final aversionAlerts = <String>[];

      for (final guest in guests) {
        double score = _calculateCompatibility(wine, wineRadar, guest);

        // Détection des aversions critiques. Le profil du vin est estimé (cépages,
        // région) : l'alerte dit « risque », pas « a ».
        final vous = idLecteur != null && guest.id == idLecteur;
        for (final disliked in guest.dislikedCharacteristics) {
          final dLower = disliked.toLowerCase();
          if (dLower.contains('tannique') && wineRadar.tannin >= 7.2) {
            score *= 0.4;
            aversionAlerts.add(vous
                ? tr('Vous n\'aimez pas les tanins fermes : celui-ci risque d\'en avoir trop', 'You dislike firm tannins: this one may have too much')
                : tr('{guest_name} n\'aime pas les tanins fermes : celui-ci risque d\'en avoir trop', '{guest_name} dislikes firm tannins: this one may have too much', {'guest_name': guest.name}));
          } else if (dLower.contains('acide') && wineRadar.acidity >= 7.5) {
            score *= 0.45;
            aversionAlerts.add(vous
                ? tr('Vous n\'aimez pas les vins très vifs : celui-ci risque de l\'être trop', 'You dislike very crisp wines: this one may be too sharp')
                : tr('{guest_name} n\'aime pas les vins très vifs : celui-ci risque de l\'être trop', '{guest_name} dislikes very crisp wines: this one may be too sharp', {'guest_name': guest.name}));
          } else if (dLower.contains('bois') && wineRadar.oak >= 6.5) {
            score *= 0.45;
            aversionAlerts.add(vous
                ? tr('Vous n\'aimez pas le boisé : celui-ci risque d\'en avoir trop', 'You dislike oak: this one may have too much')
                : tr('{guest_name} n\'aime pas le boisé : celui-ci risque d\'en avoir trop', '{guest_name} dislikes oak: this one may have too much', {'guest_name': guest.name}));
          }
        }

        guestScores[guest.id] = score.clamp(10.0, 100.0);
      }

      // Calcul du consensus global :
      // Utilisation d'une moyenne pondérée qui pénalise fortement les désaccords (écart-type)
      // pour favoriser un vin que TOUT LE MONDE apprécie plutôt qu'un vin 100% pour l'un et 20% pour l'autre.
      final scores = guestScores.values.toList();
      final mean = scores.reduce((a, b) => a + b) / scores.length;
      final variance = scores.map((s) => math.pow(s - mean, 2)).reduce((a, b) => a + b) / scores.length;
      final stdDev = math.sqrt(variance);

      // Pénalité proportionnelle à l'hétérogénéité des avis
      final consensusScore = (mean - (stdDev * 0.45)).clamp(5.0, 99.0);

      final maturite = wine.windowStatus;
      final rationale = _generateSommelierRationale(guests, guestScores, aversionAlerts, idLecteur);
      final quand = _phraseDeMaturite(wine, maturite);

      results.add(GuestMatchResult(
        bottle: bottle,
        consensusScore: double.parse(consensusScore.toStringAsFixed(1)),
        guestScores: guestScores,
        aversionAlerts: aversionAlerts.toSet().toList(),
        sommelierRationale: quand == null ? rationale : '$rationale $quand',
        maturite: maturite,
      ));
    }

    // Ce soir, une bouteille à son apogée passe devant une bouteille trop jeune au même
    // accord : la maturité départage, sans changer le pourcentage affiché, qui ne parle
    // que des goûts. À égalité parfaite, le moins d'alertes, puis le nom, pour un ordre
    // stable d'une fois sur l'autre.
    results.sort((a, b) {
      final c = (b.consensusScore + _bonusDeMaturite(b.maturite)).compareTo(a.consensusScore + _bonusDeMaturite(a.maturite));
      if (c != 0) return c;
      final d = b.consensusScore.compareTo(a.consensusScore);
      if (d != 0) return d;
      final e = a.aversionAlerts.length.compareTo(b.aversionAlerts.length);
      if (e != 0) return e;
      return (a.bottle.wine?.name ?? '').compareTo(b.bottle.wine?.name ?? '');
    });
    return results.take(maxResults).toList();
  }

  /// Ce que la maturité pèse dans l'ordre de la soirée (pas dans l'accord affiché).
  static double _bonusDeMaturite(DrinkWindowStatus? m) => switch (m) {
        DrinkWindowStatus.inPeak => 3.0,
        DrinkWindowStatus.drinkSoon => 2.0,
        DrinkWindowStatus.aging || null => 0.0,
        DrinkWindowStatus.pastPeak => -5.0,
        DrinkWindowStatus.tooYoung => -6.0,
      };

  /// La phrase qui dit pourquoi elle passe devant, ou derrière, ce soir.
  static String? _phraseDeMaturite(Wine wine, DrinkWindowStatus m) {
    if (wine.tracksFillLevel) return null;
    return switch (m) {
      DrinkWindowStatus.inPeak => tr('À son apogée.', 'At its peak.'),
      DrinkWindowStatus.drinkSoon => tr('À boire sans trop attendre.', 'Best drunk soon.'),
      DrinkWindowStatus.tooYoung => tr('Encore jeune : il gagnerait à attendre {annee}.', 'Still young: worth waiting until {annee}.',
          {'annee': wine.fenetreEffective.drinkStart}),
      DrinkWindowStatus.pastPeak => tr('Passé son apogée : à ouvrir sans trop en attendre.', 'Past its peak: open it without expecting too much.'),
      DrinkWindowStatus.aging => null,
    };
  }

  static double _calculateCompatibility(Wine wine, WineTasteRadarMetrics wineRadar, GuestProfile guest) {
    final guestRadar = guest.radar;

    // Distance euclidienne normalisée sur les 8 axes
    final dist = math.sqrt(
      math.pow(wineRadar.tannin - guestRadar.tannin, 2) +
      math.pow(wineRadar.body - guestRadar.body, 2) +
      math.pow(wineRadar.oak - guestRadar.oak, 2) +
      math.pow(wineRadar.ripeFruit - guestRadar.ripeFruit, 2) +
      math.pow(wineRadar.spice - guestRadar.spice, 2) +
      math.pow(wineRadar.freshFruit - guestRadar.freshFruit, 2) +
      math.pow(wineRadar.minerality - guestRadar.minerality, 2) +
      math.pow(wineRadar.acidity - guestRadar.acidity, 2),
    );

    // Max theoretical distance on 8 axes with scale 0-10 is sqrt(8 * 10^2) = 28.28
    double baseScore = (1.0 - (dist / 22.0)) * 100.0;

    // Bonus de cépages favoris
    if (guest.favoriteGrapes.isNotEmpty && wine.grapes.isNotEmpty) {
      final hasFavGrape = wine.grapes.any((g) =>
          guest.favoriteGrapes.any((fav) => fav.toLowerCase() == g.name.toLowerCase()));
      if (hasFavGrape) baseScore += 12.0;
    }

    // Bonus de type favori (ex: Rouge, Blanc sec, Champagne). Les deux côtés passent par
    // la même lecture de la couleur : le profil range « Rouge », la fiche `red`, et la
    // comparaison des textes ne les rapprochait jamais.
    if (guest.favoriteTypes.isNotEmpty) {
      final couleur = couleurDuQuestionnaire(wine.type);
      final matchesType = couleur.isNotEmpty && guest.favoriteTypes.any((t) => couleurDuQuestionnaire(t) == couleur);
      if (matchesType) baseScore += 8.0;
    }

    return baseScore.clamp(15.0, 100.0);
  }

  /// Le « pourquoi » d'une bouteille : qui l'aimera, qui risque de moins l'aimer, tiré des
  /// seuls scores des convives. Les trois phrases fixes d'avant prêtaient à n'importe quel
  /// vin « l'élégance » et « une ouverture préalable de 30 minutes » — le défaut corrigé
  /// sur la table du restaurant le 28/09.
  static String _generateSommelierRationale(
    List<GuestProfile> guests,
    Map<String, double> guestScores,
    List<String> aversionAlerts,
    String? idLecteur,
  ) {
    final fr = Langue.estFr;
    final notes = [
      for (final g in guests)
        if (guestScores.containsKey(g.id)) (g, guestScores[g.id]!)
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    if (notes.isEmpty) return tr('Une bouteille pour la table', 'A bottle for the table');

    String phrase;
    if (notes.length == 1) {
      final (g, s) = notes.single;
      final vous = idLecteur == null || g.id == idLecteur;
      phrase = s >= 85
          ? (vous ? tr('Taillé pour vos goûts', 'Made for your taste') : tr('Taillé pour les goûts de {g_name}', 'Made for {g_name}\'s taste', {'g_name': g.name}))
          : s >= 65
              ? (vous ? tr('Dans vos goûts', 'Close to your taste') : tr('Dans les goûts de {g_name}', 'Close to {g_name}\'s taste', {'g_name': g.name}))
              : (vous
                  ? tr('Un pas de côté par rapport à vos goûts', 'A step away from your usual taste')
                  : tr('Un pas de côté pour {g_name}', 'A step away from {g_name}\'s usual taste', {'g_name': g.name}));
    } else {
      // Celui qui lit se lit « vous », en dernier, et le verbe s'accorde.
      bool estLecteur(GuestProfile g) => idLecteur != null && g.id == idLecteur;
      (List<String>, bool) groupe(bool Function(double) dedans) {
        final autres = [for (final n in notes) if (dedans(n.$2) && !estLecteur(n.$1)) n.$1.name];
        final lecteur = notes.any((n) => dedans(n.$2) && estLecteur(n.$1));
        return ([...autres, if (lecteur) tr('vous', 'you')], lecteur);
      }

      String verbe((List<String>, bool) g, FormesDuVerbe formes) =>
          '${_liste(g.$1, fr)} ${formes.pour(fr: fr, lecteur: g.$2, plusieurs: g.$1.length > 1)}';
      final fans = groupe((s) => s >= 85);
      final contents = groupe((s) => s >= 65 && s < 85);
      final tiedes = groupe((s) => s >= 55 && s < 65);
      final reticents = groupe((s) => s < 55);
      final parts = [
        if (fans.$1.isNotEmpty) verbe(fans, FormesDuVerbe.adorer),
        if (contents.$1.isNotEmpty) verbe(contents, FormesDuVerbe.apprecier),
        if (tiedes.$1.isNotEmpty) verbe(tiedes, FormesDuVerbe.sAccommoder),
        if (reticents.$1.isNotEmpty) verbe(reticents, FormesDuVerbe.moinsAimer),
      ];
      phrase = parts.join(trSi(fr, ' ; ', '; '));
    }
    phrase = phrase[0].toUpperCase() + phrase.substring(1);
    return aversionAlerts.isEmpty ? '$phrase.' : '$phrase. ${aversionAlerts.first}.';
  }

  static String _liste(List<String> noms, bool fr) {
    if (noms.length <= 1) return noms.join();
    return '${noms.sublist(0, noms.length - 1).join(', ')} ${trSi(fr, 'et', 'and')} ${noms.last}';
  }
}

/// Les formes d'un verbe selon le groupe qui l'emploie, par langue.
/// Un verbe qui s'accorde avec le groupe de convives qu'il suit, dans chaque langue.
/// En français, « vous » vaut pour la personne seule comme pour le groupe où elle figure ;
/// en espagnol, « tú » seul (« lo vas a adorar ») et le groupe (« lo van a adorar »)
/// diffèrent. Une clé de catalogue ne suffit pas : les formes sont données ici.
class FormesDuVerbe {
  final String vous, un, plusieurs, en, esTu, esUn, esPlusieurs;

  const FormesDuVerbe(this.vous, this.un, this.plusieurs, this.en, this.esTu, this.esUn, this.esPlusieurs);

  /// [lecteur] : celui qui lit fait partie du groupe ; [plusieurs] : plus d'une personne.
  String pour({required bool fr, required bool lecteur, required bool plusieurs}) {
    if (fr) return lecteur ? vous : (plusieurs ? this.plusieurs : un);
    if (Langue.code == 'es') return plusieurs ? esPlusieurs : (lecteur ? esTu : esUn);
    return en;
  }

  static const adorer = FormesDuVerbe('allez l\'adorer', 'va l\'adorer', 'vont l\'adorer', 'will love it',
      'lo vas a adorar', 'lo va a adorar', 'lo van a adorar');
  static const apprecier = FormesDuVerbe('l\'apprécierez', 'l\'appréciera', 'l\'apprécieront', 'will enjoy it',
      'lo disfrutarás', 'lo disfrutará', 'lo disfrutarán');
  static const sAccommoder = FormesDuVerbe('vous en accommoderez', 's\'en accommodera', 's\'en accommoderont',
      'will be fine with it', 'lo aceptarás', 'lo aceptará', 'lo aceptarán');
  static const moinsAimer = FormesDuVerbe('risquez de moins l\'aimer', 'risque de moins l\'aimer',
      'risquent de moins l\'aimer', 'may like it less', 'quizá lo disfrutes menos', 'quizá lo disfrute menos',
      'quizá lo disfruten menos');
}
