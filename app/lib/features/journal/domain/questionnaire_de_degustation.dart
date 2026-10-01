import '../../../shared/utils/langue.dart';
import '../../auth/domain/taste_profile.dart';
import '../../friends/domain/friend.dart';
import 'tasting_questionnaire_result.dart';

// Ce que le questionnaire de dégustation décide, hors de l'écran (V2.3 · I4).
//
// `tasting_questionnaire_sheet.dart` mêlait l'affichage et les règles : quelles questions
// selon la couleur du vin, ce que vaut un visage, ce qu'un toucher de bouche suppose de la
// structure, qui peut répondre, ce qui part au journal et ce que devient la bouteille. Les
// règles vivent ici, testées ; l'écran n'en garde que l'affichage.

/// La couleur du vin telle que le questionnaire l'entend : `red`, `white`, `rose`,
/// `sparkling`, `dessert`, ou le type reçu (en minuscules) s'il n'est pas reconnu.
///
/// L'ordre compte : « Blanc de blancs » est un blanc avant d'être une bulle, « Crémant
/// rosé » un rosé.
String couleurDuQuestionnaire(String? typeDuVin) {
  final t = (typeDuVin ?? '').toLowerCase().trim();
  if (t.contains('rouge') || t == 'red') return 'red';
  if (t.contains('blanc') || t == 'white') return 'white';
  if (t.contains('ros') || t == 'rose') return 'rose';
  if (t.contains('champ') || t.contains('sparkling') || t.contains('bulles') || t.contains('effervescent')) {
    return 'sparkling';
  }
  if (t.contains('liquoreux') || t.contains('moelleux') || t.contains('dessert') || t.contains('doux')) {
    return 'dessert';
  }
  return t;
}

/// Les questions qui ont un sens pour ce vin.
class QuestionnaireDuVin {
  final String couleur;

  QuestionnaireDuVin(String? typeDuVin) : couleur = couleurDuQuestionnaire(typeDuVin);

  bool get estRouge => couleur == 'red';
  bool get estBlanc => couleur == 'white';
  bool get estRose => couleur == 'rose';
  bool get estEffervescent => couleur == 'sparkling';

  /// Un blanc, un rosé ou un effervescent n'a pas de tanins qui se jugent.
  bool get demandeLesTanins => estRouge;

  /// La minéralité se demande aux blancs et aux rosés.
  bool get demandeLaMineralite => estBlanc || estRose;

  bool get demandeLEffervescence => estEffervescent;
}

/// Les réponses d'un convive pendant son tour.
///
/// Mutable, comme le formulaire qu'elles remplissent : l'écran les modifie geste après
/// geste, et en prend de neuves au convive suivant.
class ReponsesDuConvive {
  int visage = 3; // 😊
  double note = 7.0;
  Set<String> aromes = {};
  final List<String> aromesLibres = [];
  double intensiteAromatique = 0.5;

  /// `sublime`, `harmonious`, `neutral`, `clashing` : ne compte que si le vin a été bu
  /// avec un plat.
  String? accordAvecLePlat;

  /// Mode express : `silky_lacy`, `crisp_salivating`, `dense_structured`.
  String? texture;

  /// Mode express : `crunchy_tart`, `deep_ripe`, `spicy_herbal`.
  String? fruit;

  double acidite = 0.5;
  double tanins = 0.5;
  double mineralite = 0.5;
  double corps = 0.5;
  double longueur = 0.5;
  double effervescence = 0.5;

  /// `yes`, `maybe`, `no`.
  String racheter = 'maybe';
  String moment = 'repas';
  Set<String> aime = {};
  Set<String> aimePas = {};

  /// Un visage choisi donne la note de sa tranche.
  void choisirLeVisage(int i) {
    visage = i;
    note = TastingQuestionnaireResult.notesDesVisages[i];
  }

  /// Une note réglée au curseur emmène son visage.
  void reglerLaNote(double valeur) {
    note = valeur;
    visage = TastingQuestionnaireResult.emojiIndexForRating(valeur);
  }

  /// Le toucher de bouche dit aussi quelque chose de la structure : un vin soyeux a des
  /// tanins fondus, un vin qui fait saliver une acidité vive, un vin dense du corps.
  /// Toucher de nouveau le même retire le choix, sans défaire les curseurs.
  void basculerLaTexture(String id) {
    if (texture == id) {
      texture = null;
      return;
    }
    texture = id;
    switch (id) {
      case 'silky_lacy':
        tanins = 0.40;
        acidite = 0.55;
      case 'crisp_salivating':
        acidite = 0.80;
        mineralite = 0.75;
      case 'dense_structured':
        corps = 0.80;
        tanins = 0.80;
    }
  }

  /// L'éclat du fruit ajoute l'arôme qu'il nomme, et ce qu'il suppose de la bouche.
  void basculerLeFruit(String id) {
    if (fruit == id) {
      fruit = null;
      return;
    }
    fruit = id;
    switch (id) {
      case 'crunchy_tart':
        aromes.add('fruits_rouges');
        acidite = 0.70;
      case 'deep_ripe':
        aromes.add('fruits_noirs');
        corps = 0.70;
      case 'spicy_herbal':
        aromes.add('epices_vives');
    }
  }

  /// Une dégustation dictée, lue par le sommelier : elle remplit ce qu'elle dit, sans
  /// donner de tanins à un vin qui n'en a pas à juger, ni de minéralité à un rouge.
  void appliquerLaDictee({
    required QuestionnaireDuVin vin,
    required double note,
    required int visage,
    required Set<String> aromes,
    required double acidite,
    double? tanins,
    double? mineralite,
    required double corps,
    required double longueur,
  }) {
    this.note = note;
    this.visage = visage;
    this.aromes = aromes;
    this.acidite = acidite;
    if (tanins != null && vin.demandeLesTanins) this.tanins = tanins;
    if (mineralite != null && !vin.demandeLesTanins) this.mineralite = mineralite;
    this.corps = corps;
    this.longueur = longueur;
  }

  /// Ce que le palais apprendra de ce tour.
  ///
  /// Le plat et l'accord ne partent que si le vin a été bu avec un plat ; les tanins, la
  /// minéralité et l'effervescence, que si la couleur les a fait demander.
  TastingQuestionnaireResult resultat({
    required String profileId,
    required String profileName,
    required QuestionnaireDuVin vin,
    required bool express,
    bool? avecUnPlat,
    String plat = '',
  }) {
    final avecPlat = avecUnPlat == true;
    return TastingQuestionnaireResult(
      emojiImpression: visage,
      noteOutOf10: note,
      perceivedAromas: Set<String>.from(aromes),
      customAromas: List<String>.from(aromesLibres),
      foodPairingSynergy: avecPlat ? accordAvecLePlat : null,
      platAccorde: avecPlat && plat.trim().isNotEmpty ? plat.trim() : null,
      mouthfeelTexture: texture,
      fruitProfile: fruit,
      isExpressMode: express,
      aromaIntensity: intensiteAromatique,
      acidity: acidite,
      tannins: vin.demandeLesTanins ? tanins : null,
      mineralite: vin.demandeLaMineralite ? mineralite : null,
      body: corps,
      length: longueur,
      effervescence: vin.demandeLEffervescence ? effervescence : null,
      wouldBuyAgain: racheter,
      idealMoment: moment,
      whatLikedMost: Set<String>.from(aime),
      whatDislikedMost: Set<String>.from(aimePas),
      profileId: profileId,
      profileName: profileName,
    );
  }
}

/// Qui peut répondre : les profils de la personne, et ses amis.
class ConvivesDuQuestionnaire {
  /// Un ami et un profil du même nom (sans tenir compte de la casse) sont la même
  /// personne : le profil prend le lien vers son compte, pour que la dégustation lui
  /// parvienne. Un ami sans profil en reçoit un.
  static List<TasteProfile> rassembler(List<TasteProfile> profils, List<Friend> amis) {
    String cle(String nom) => nom.toLowerCase();
    final tous = [
      for (final p in profils)
        switch (amis.where((a) => cle(a.displayName) == cle(p.name)).firstOrNull) {
          final ami? => p.copyWith(friendUserId: ami.friendUserId),
          null => p,
        },
    ];
    for (final a in amis) {
      if (!tous.any((p) => cle(p.name) == cle(a.displayName))) {
        tous.add(TasteProfile(id: a.friendUserId, name: a.displayName, friendUserId: a.friendUserId));
      }
    }
    return tous;
  }

  /// Le maître de cave, plus les convives annoncés par leur nom.
  static Set<String> selectionInitiale(List<TasteProfile> tous, List<String>? annonces) {
    if (tous.isEmpty) return {};
    final principal = tous.firstWhere((p) => p.isPrimary, orElse: () => tous.first);
    return {
      principal.id,
      for (final nom in annonces ?? const <String>[])
        ...tous.where((p) => p.name.toLowerCase() == nom.toLowerCase()).take(1).map((p) => p.id),
    };
  }
}

final _uuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

/// Les identifiants qui partent en base doivent en être : un identifiant local (« demo-1 »,
/// « TABLE-… ») ferait refuser toute la ligne.
bool estUnUuid(String? id) => id != null && _uuid.hasMatch(id);

/// La ligne de journal que laisse le questionnaire : celle du maître de cave, et ses
/// replis pour les bases restées en retard.
class LigneDuQuestionnaire {
  final String id;
  final String wineId;
  final String userId;
  final String? bottleId;
  final String? cellarId;

  /// Les réponses du maître de cave (`resultatDuMaitreDeCave`).
  final TastingQuestionnaireResult? resultat;

  /// Tous ceux qui ont répondu ; le maître de cave n'est pas son propre convive.
  final List<TasteProfile> convives;
  final String occasionSaisie;
  final String? photo;
  final String? proprietaireId;
  final String? proprietaireNom;
  final bool aLAveugle;

  /// Bouchon, oxydation, réduction : la bouteille, pas le palais.
  final String? defaut;
  final DateTime quand;

  const LigneDuQuestionnaire({
    required this.id,
    required this.wineId,
    required this.userId,
    this.bottleId,
    this.cellarId,
    required this.resultat,
    this.convives = const [],
    this.occasionSaisie = '',
    this.photo,
    this.proprietaireId,
    this.proprietaireNom,
    this.aLAveugle = false,
    this.defaut,
    required this.quand,
  });

  /// La note du maître de cave. Sans réponse, pas de note : on n'en invente pas.
  double? get note => resultat?.noteOutOf10;

  /// « Dégustation guidée. Arômes : 🍋 Agrumes, 🌸 Floral », dans la langue de l'écran.
  String get notes {
    final aromes = libellesDesAromes(resultat?.perceivedAromas ?? const <String>{});
    return aromes.isNotEmpty
        ? tr('Dégustation guidée. Arômes : {v1}', 'Guided tasting. Aromas: {v1}', {'v1': aromes.join(', ')})
        : tr('Dégustation guidée.', 'Guided tasting.');
  }

  String get occasion => occasionSaisie.isNotEmpty
      ? occasionSaisie
      : (resultat?.idealMoment ?? tr('Dégustation guidée', 'Guided tasting'));

  /// Le noyau que toutes les bases acceptent, y compris celles d'avant la migration 027.
  Map<String, dynamic> essentielle() => {
        'id': id,
        'wine_id': wineId,
        if (estUnUuid(bottleId)) 'bottle_id': bottleId,
        'user_id': userId,
        if (estUnUuid(cellarId)) 'cellar_id': cellarId,
        'rating': note,
        'occasion': occasion,
        if (photo != null) 'photo_url': photo,
        'tasting_notes': notes,
        'consumed_at': quand.toIso8601String(),
      };

  /// La ligne entière.
  Map<String, dynamic> complete() => {
        ...essentielle(),
        'co_tasters': [
          for (final p in convives)
            if (!p.isPrimary) p.name,
        ],
        if (estUnUuid(proprietaireId)) 'bottle_owner_id': proprietaireId,
        if (proprietaireNom != null) 'bottle_owner_name': proprietaireNom,
        'is_external': false,
        'rating_scale': 10,
        'is_blind': aLAveugle,
        if (defaut != null) 'fault': defaut,
        if (resultat?.platAccorde != null) 'food_paired': resultat!.platAccorde,
      };

  /// Dernier recours, pour une base restée sur l'ancienne contrainte « note ≤ 5 ».
  ///
  /// L'échelle n'est PAS marquée : arrivée à cet étage, la migration 032 n'a pas tourné,
  /// la colonne `rating_scale` n'existe donc pas, et la nommer ferait échouer cet insert
  /// aussi. La relecture s'en sort seule : colonne absente ⇒ échelle 5
  /// (`TastingEntry.fromJson`).
  Map<String, dynamic> ancienneEchelle() => {
        ...essentielle(),
        'rating': note == null ? null : (note! / 2.0).clamp(0.0, 5.0),
      };
}

/// Ce que devient la bouteille après la dégustation : la quantité baisse, ou elle sort de
/// la cave avec la dernière.
Map<String, dynamic> bouteilleApresDegustation({
  required int quantite,
  required int bues,
  required DateTime quand,
}) =>
    quantite > bues
        ? {'quantity': quantite - bues}
        : {'quantity': 0, 'status': 'consumed', 'consumed_at': quand.toIso8601String()};

/// La dégustation envoyée à un ami qui a l'app (`record_shared_tasting_log`) : elle entre
/// dans son journal à lui, avec ses réponses.
Map<String, dynamic> degustationPartagee({
  required String wineId,
  required String amiId,
  required TastingQuestionnaireResult resultat,
  required List<String> convives,
  String? bottleId,
  String? cellarId,
  String? proprietaireId,
  String? proprietaireNom,
}) {
  final aromes = libellesDesAromes(resultat.perceivedAromas);
  return {
    'p_wine_id': wineId,
    'p_friend_user_id': amiId,
    'p_rating': resultat.noteOutOf10,
    if (estUnUuid(bottleId)) 'p_bottle_id': bottleId,
    if (estUnUuid(cellarId)) 'p_cellar_id': cellarId,
    'p_notes': aromes.isNotEmpty
        ? tr('Dégustation partagée. Arômes : {v1}', 'Shared tasting. Aromas: {v1}', {'v1': aromes.join(', ')})
        : tr('Dégustation partagée.', 'Shared tasting.'),
    'p_occasion': resultat.idealMoment,
    'p_co_tasters': convives,
    if (estUnUuid(proprietaireId)) 'p_bottle_owner_id': proprietaireId,
    if (proprietaireNom != null) 'p_bottle_owner_name': proprietaireNom,
    'p_is_external': false,
    'p_questionnaire_data': resultat.toJson(),
  };
}
