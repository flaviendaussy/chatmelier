import '../../../shared/utils/langue.dart';
import '../../auth/domain/taste_profile.dart';
import '../../friends/domain/friend.dart';
import '../../offline/domain/offline_action.dart';
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

  /// Ce que la personne a décrit du vin (V2.6) : `acidity`, `tannin`, `body`, `length`,
  /// `effervescence`, `minerality`. Un curseur qu'elle n'a pas touché ne part pas : ses
  /// 0,5 se lisaient comme « moyen », et le palais l'apprenait.
  final Set<String> decrits = {};

  /// Le « pour vous » (V2.6 · P6) : axe du palais → `trop`, `juste` ou `pas_assez`.
  final Map<String, String> jugements = {};

  /// `yes`, `maybe`, `no`.
  String racheter = 'maybe';

  /// Nul tant que la personne n'a rien choisi : le moment ne se suppose pas.
  String? moment;

  /// Le « pour vous » d'un axe ; le même choix une seconde fois le retire.
  void juger(String axe, String sens) {
    if (jugements[axe] == sens) {
      jugements.remove(axe);
    } else {
      jugements[axe] = sens;
    }
  }

  /// Un curseur de description touché : sa valeur part avec la dégustation.
  void decrire(String quoi, double v) {
    decrits.add(quoi);
    switch (quoi) {
      case 'acidity':
        acidite = v;
      case 'tannin':
        tanins = v;
      case 'body':
        corps = v;
      case 'length':
        longueur = v;
      case 'effervescence':
        effervescence = v;
      case 'minerality':
        mineralite = v;
    }
  }
  Set<String> aime = {};
  Set<String> aimePas = {};

  /// Ce qui a plu et ce qui a déplu : une réponse « rien » exclut les traits, et un trait
  /// exclut les réponses « rien » (V2.4 · R3).
  void basculerAime(String id, bool choisi) => _basculer(aime, id, choisi);
  void basculerAimePas(String id, bool choisi) => _basculer(aimePas, id, choisi);

  static void _basculer(Set<String> choix, String id, bool choisi) {
    if (!choisi) {
      choix.remove(id);
    } else if (TastingQuestionnaireResult.reponsesSansTrait.contains(id)) {
      choix
        ..clear()
        ..add(id);
    } else {
      choix
        ..removeAll(TastingQuestionnaireResult.reponsesSansTrait)
        ..add(id);
    }
  }

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
        decrire('tannin', 0.40);
        decrire('acidity', 0.55);
      case 'crisp_salivating':
        decrire('acidity', 0.80);
        decrire('minerality', 0.75);
      case 'dense_structured':
        decrire('body', 0.80);
        decrire('tannin', 0.80);
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
        decrire('acidity', 0.70);
      case 'deep_ripe':
        aromes.add('fruits_noirs');
        decrire('body', 0.70);
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
    decrire('acidity', acidite);
    if (tanins != null && vin.demandeLesTanins) decrire('tannin', tanins);
    if (mineralite != null && !vin.demandeLesTanins) decrire('minerality', mineralite);
    decrire('body', corps);
    decrire('length', longueur);
  }

  /// Ce que le palais apprendra de ce tour.
  ///
  /// Le plat et l'accord ne partent que si le vin a été bu avec un plat ; les tanins, la
  /// minéralité et l'effervescence, que si la couleur les a fait demander ; une description,
  /// que si la personne l'a donnée (V2.6).
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
      acidity: decrits.contains('acidity') ? acidite : null,
      tannins: vin.demandeLesTanins && decrits.contains('tannin') ? tanins : null,
      mineralite: vin.demandeLaMineralite && decrits.contains('minerality') ? mineralite : null,
      body: decrits.contains('body') ? corps : null,
      length: longueur,
      effervescence: vin.demandeLEffervescence && decrits.contains('effervescence') ? effervescence : null,
      jugements: Map<String, String>.from(jugements),
      wouldBuyAgain: racheter,
      idealMoment: moment ?? '',
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

  /// La note du maître de cave. Sans réponse, pas de note : on n'en invente pas. Une
  /// bouteille défectueuse non plus : c'est la bouteille qu'on a jugée, pas le vin (le
  /// Bio Tinto oxydé du 22/10 s'affichait « Pas aimé 1,0/10 »).
  double? get note => defaut != null ? null : resultat?.noteOutOf10;

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

/// Ce que le questionnaire ajoute à une dégustation déjà au journal — un vin bu dehors, un
/// verre de la carte : la note, le défaut, les arômes, le plat.
///
/// Le 22/10, ces quatre-là restaient en route : « Noter un vin bu dehors » écrivait la ligne
/// sans note, et le questionnaire, sans fiche de cave, n'y revenait jamais. Vingt et une
/// dégustations « Non noté » pour deux personnes qui avaient tout rempli.
Map<String, dynamic> complementDuJournal({
  required TastingQuestionnaireResult? resultat,
  String? defaut,
  String? notesDeja,
  bool aLAveugle = false,
}) {
  final aromes = libellesDesAromes(resultat?.perceivedAromas ?? const <String>{});
  final notes = [
    if ((notesDeja ?? '').trim().isNotEmpty) notesDeja!.trim(),
    if (aromes.isNotEmpty) tr('Arômes : {v1}', 'Aromas: {v1}', {'v1': aromes.join(', ')}),
  ].join('\n');
  return {
    'rating': defaut != null ? null : resultat?.noteOutOf10,
    'rating_scale': 10,
    if (defaut != null) 'fault': defaut,
    if (notes.isNotEmpty) 'tasting_notes': notes,
    if (resultat?.platAccorde != null) 'food_paired': resultat!.platAccorde,
    if (aLAveugle) 'is_blind': true,
  };
}

/// La sortie de cave et sa dégustation, mises en file quand le réseau a manqué : la
/// synchronisation (`OfflineActionType.consumeBottle`) décompte la bouteille — sauf si
/// c'est déjà fait — puis écrit la dégustation. L'action porte l'identifiant de la ligne
/// affichée en attendant, pour qu'elles ne fassent qu'une une fois parties.
OfflineAction sortieDeCaveEnFile({
  required LigneDuQuestionnaire ligne,
  required String bouteille,
  String? cave,
  required String nomDuVin,
  int? millesime,
  String? region,
  required int bues,
  required bool dejaDecomptee,
}) =>
    OfflineAction(
      id: ligne.id,
      type: OfflineActionType.consumeBottle,
      cellarId: cave,
      createdAt: ligne.quand,
      data: {
        ...ligne.complete(),
        'bottle_id': bouteille,
        if (cave != null) 'cellar_id': cave,
        'wine_name': nomDuVin,
        'vintage': millesime,
        'region': region,
        'quantity': bues,
        if (dejaDecomptee) OfflineAction.bouteilleDecompteeKey: true,
      },
    );

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

/// La dégustation faite pour un ami qui a l'app, proposée à son journal (V2.4 · R4,
/// migration 066 `proposer_degustation`) : elle n'y entre que s'il l'accepte. Le vin voyage
/// en instantané (l'ami n'a pas forcément accès à la cave) et les réponses brutes, que son
/// app rédige dans sa langue et apprend à son palais — sauf bouteille défectueuse.
Map<String, dynamic> propositionDeDegustation({
  required String amiId,
  required String nomDuVin,
  int? millesime,
  String? producteur,
  String? couleur,
  String? region,
  String? pays,
  List<String> cepages = const [],
  String? photo,
  required TastingQuestionnaireResult resultat,
  required List<String> convives,
  String? defaut,
  String? proprietaireNom,
}) {
  String? propre(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();
  return {
    'p_pour': amiId,
    'p_vin': {
      'nom': nomDuVin.trim(),
      if (millesime != null) 'millesime': millesime,
      if (propre(producteur) != null) 'producteur': propre(producteur),
      if (propre(couleur) != null) 'couleur': propre(couleur),
      if (propre(region) != null) 'region': propre(region),
      if (propre(pays) != null) 'pays': propre(pays),
      if (cepages.isNotEmpty) 'cepages': cepages,
      if (propre(photo) != null && photo!.startsWith('http')) 'photo': propre(photo),
    },
    'p_note': resultat.noteOutOf10,
    'p_questionnaire': resultat.toJson(),
    if (propre(defaut) != null) 'p_defaut': propre(defaut),
    if (propre(resultat.platAccorde) != null) 'p_plat': propre(resultat.platAccorde),
    'p_convives': convives,
    if (propre(proprietaireNom) != null) 'p_proprietaire_nom': propre(proprietaireNom),
  };
}
