import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/utils/app_logger.dart';
import '../domain/taste_profile.dart';
import '../domain/taste_evidence.dart';
import '../domain/taste_profile_history.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../cellar/domain/bottle.dart';
import '../domain/cellar_behaviour_evidence.dart';
import '../domain/cellar_concentration.dart';
import '../../cellar/domain/wine.dart';
import '../../friends/domain/friend.dart';
import '../../journal/domain/questionnaire_de_degustation.dart';
import '../../journal/domain/tasting_questionnaire_result.dart';
import 'palais_distant.dart';

/// Seuils d'apprentissage, sur l'échelle /10.
///
/// Entre les deux, la dégustation ne dit rien de tranché et le profil n'est pas modifié —
/// c'est délibéré : un 6/10 n'est ni un goût ni un dégoût.
const double kLikedThreshold = 7.5;
const double kDislikedThreshold = 4.0;

/// Facteur de lissage de la moyenne exponentielle des axes sensoriels.
///
/// 0,25 correspond à une demi-vie d'environ dix dégustations : le profil suit un palais qui
/// évolue sans osciller à chaque bouteille. La moyenne cumulative qu'il remplace donnait à
/// une dégustation un poids de 1/(n+1) — soit 0,33 % après trois cents, autant dire zéro.
const double kAxisSmoothing = 0.25;

final tasteProfileServiceProvider = Provider<TasteProfileService>((ref) {
  return TasteProfileService();
});

/// Un palais rapatrié du serveur (appareil neuf, reprise d'une soirée) recharge les écrans.
final palaisRapatrieProvider = StreamProvider<int>((ref) => PalaisDistant.rapatriements);

final tasteProfilesListProvider = FutureProvider<List<TasteProfile>>((ref) async {
  ref.watch(palaisRapatrieProvider);
  final service = ref.watch(tasteProfileServiceProvider);
  return service.getProfiles();
});

/// Recalcule l'inventaire de cépages du profil principal à partir de la cave.
///
/// `syncCellarGrapes` existait mais n'avait **aucun appelant** : `cellarGrapes` restait donc
/// toujours vide, alors que le radar lui accorde jusqu'à 3,3 points sur un axe
/// (`wine_taste_radar.dart:433`). Le bloc était pondéré lourdement et ne s'exécutait jamais.
///
/// À observer depuis les écrans qui affichent le radar : la synchronisation devient un effet
/// de bord du chargement de la cave, sans bouton ni geste supplémentaire.
final cellarGrapeSyncProvider = FutureProvider<void>((ref) async {
  final bottles = await ref.watch(bottlesProvider(null).future);
  final service = ref.watch(tasteProfileServiceProvider);
  final primary = await service.getPrimaryProfile();
  await service.syncCellarGrapes(
    primary.id,
    TasteProfileService.cellarGrapeStock(bottles),
  );
  // Et ce que les gestes révèlent : les rachats entrent dans les favoris explicites.
  await service.applyCellarBehaviour(primary.id, bottles);
  // Et ce que la composition révèle : appellations, cépages, façons de boire.
  await service.applyCellarConcentration(primary.id, bottles);

  // Fige l'état du mois. Idempotent : rappeler ne fait que remplacer l'instantané du
  // mois courant. Posé maintenant pour qu'il y ait quelque chose à montrer dans un an —
  // c'est la fonctionnalité qu'il faut écrire le plus tôt et afficher le plus tard.
  await (await TasteProfileHistory.ouvrir())
      .capturer(await service.getPrimaryProfile());

  ref.invalidate(tasteProfilesListProvider);
});

class TasteProfileService {
  static const String _prefsKey = 'chatmelier_taste_profiles_v2';

  Future<List<TasteProfile>> getProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final List<dynamic> list = jsonDecode(raw);
        final loaded = list.map((j) => TasteProfile.fromJson(j as Map<String, dynamic>)).toList();
        // Filter out any legacy hardcoded mock profiles or erroneously created "primary" guest profiles
        final clean = loaded.where((p) {
          final idLower = p.id.toLowerCase();
          final nameLower = p.name.trim().toLowerCase();
          if (idLower == 'flavien_main' || idLower == 'caro_profile') return false;
          if (idLower == 'primary' || nameLower == 'primary') return false;
          if (idLower == 'primary_user' && !p.isPrimary) return false;
          return true;
        }).toList();
        if (clean.length != loaded.length) {
          await saveProfiles(clean);
        }
        if (clean.isNotEmpty) {
          return clean;
        }
      }
    } catch (e) {
      AppLogger.warning('TASTE_PROFILE', 'Error loading local profiles: $e');
    }

    // Default clean profile for current user (neutral, unassigned preferences)
    final defaultProfiles = [
      const TasteProfile(
        id: 'primary_user',
        name: 'Moi',
        isPrimary: true,
        favoriteTypes: [],
        favoriteRegions: [],
        favoriteGrapes: [],
        dislikedCharacteristics: [],
        notes: '',
      ),
    ];

    await saveProfiles(defaultProfiles);
    return defaultProfiles;
  }

  Future<TasteProfile> getPrimaryProfile() async {
    final profiles = await getProfiles();
    return profiles.firstWhere((p) => p.isPrimary, orElse: () => profiles.first);
  }

  Future<void> resetProfile(String profileId) async {
    final profiles = await getProfiles();
    final index = profiles.indexWhere((p) => p.id == profileId);
    if (index != -1) {
      final existing = profiles[index];
      profiles[index] = TasteProfile(
        id: existing.id,
        name: existing.name,
        isPrimary: existing.isPrimary,
        favoriteTypes: const [],
        favoriteRegions: const [],
        favoriteGrapes: const [],
        dislikedCharacteristics: const [],
        notes: '',
        aromaPreferences: const {},
        likedTraits: const {},
        dislikedTraits: const {},
        avgAcidityPreference: null,
        avgTanninPreference: null,
        avgBodyPreference: null,
        idealMoments: const {},
        questionnairesCompleted: 0,
      );
      await saveProfiles(profiles);
    }
  }

  Future<void> saveProfiles(List<TasteProfile> profiles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(profiles.map((p) => p.toJson()).toList());
      await prefs.setString(_prefsKey, jsonStr);
      PalaisDistant.planifierEnvoi();
    } catch (e) {
      AppLogger.error('TASTE_PROFILE', 'Error saving profiles', e);
    }
  }

  Future<TasteProfile> addProfile({
    required String name,
    List<String> favoriteTypes = const [],
    List<String> favoriteRegions = const [],
    List<String> favoriteGrapes = const [],
    List<String> dislikedCharacteristics = const [],
    String notes = '',
  }) async {
    final profiles = await getProfiles();
    final newProfile = TasteProfile(
      id: const Uuid().v4(),
      name: name,
      isPrimary: false,
      favoriteTypes: favoriteTypes,
      favoriteRegions: favoriteRegions,
      favoriteGrapes: favoriteGrapes,
      dislikedCharacteristics: dislikedCharacteristics,
      notes: notes,
    );

    profiles.add(newProfile);
    await saveProfiles(profiles);
    return newProfile;
  }

  /// Le palais déclaré à la première ouverture : un a priori, pas une observation.
  ///
  /// Les axes vont dans `palaisDeDepart` (0–10) et nulle part ailleurs : aucune moyenne
  /// n'est touchée, aucune observation n'est comptée, et la confiance reste nulle. Les
  /// couleurs aimées ne remplacent pas celles que le profil connaît déjà.
  Future<void> enregistrerPalaisDeDepart({
    required Map<String, double> axes,
    List<String> couleurs = const [],
    List<String> aversions = const [],
  }) async {
    final p = await getPrimaryProfile();
    await updateProfile(p.copyWith(
      palaisDeDepart: axes,
      favoriteTypes: p.favoriteTypes.isEmpty ? couleurs : p.favoriteTypes,
      dislikedCharacteristics: {...p.dislikedCharacteristics, ...aversions}.toList(),
    ));
  }

  Future<void> updateProfile(TasteProfile updated) async {
    final profiles = await getProfiles();
    final index = profiles.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      profiles[index] = updated;
      await saveProfiles(profiles);
    }
  }

  Future<TasteProfile> addOrGetProfileByName(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      return getPrimaryProfile();
    }

    final profiles = await getProfiles();
    final match = profiles.firstWhere(
      (p) => p.name.trim().toLowerCase() == cleanName.toLowerCase(),
      orElse: () => const TasteProfile(id: '', name: ''),
    );

    if (match.id.isNotEmpty) {
      return match;
    }

    return addProfile(
      name: cleanName,
      notes: 'Invité / Membre de la famille ajouté lors d\'une dégustation',
    );
  }

  /// Enregistre une dégustation dans le profil de goût.
  ///
  /// **Apprentissage symétrique.** La version précédente avait tout son corps à l'intérieur
  /// d'un `if (rating >= 7.5)` : une note de 2/10 ne déclenchait rien, pas même le compteur.
  /// Les favoris ne faisaient que s'accumuler, si bien qu'après cinquante dégustations le
  /// profil « aimait » six types, six régions et huit cépages — et ne discriminait plus rien.
  ///
  /// Désormais une note basse **retire** ce qu'une note haute avait ajouté.
  ///
  /// [hadFault] : une bouteille bouchonnée ou oxydée n'apprend rien sur le palais de la
  /// personne, et lui apprendrait même le contraire de la vérité. Elle est ignorée.
  ///
  /// [tastingId] : l'entrée de journal d'où vient cette dégustation. Sans lui, le registre
  /// sait qu'une conviction existe mais pas de quelle dégustation elle vient — et supprimer
  /// cette dégustation ne pourrait rien défaire.
  Future<void> recordTastingExperience({
    required String nameOrId,
    required Wine wine,
    required double rating,
    bool hadFault = false,
    String? tastingId,
  }) async {
    if (hadFault) {
      AppLogger.info('TASTE_PROFILE', 'Dégustation ignorée (vin défectueux) pour $nameOrId');
      return;
    }
    try {
      final profiles = await getProfiles();
      final cleanQuery = nameOrId.trim().toLowerCase();
      TasteProfile profile;
      if (cleanQuery == 'primary' || cleanQuery == 'primary_user' || cleanQuery.isEmpty || cleanQuery == 'moi') {
        profile = await getPrimaryProfile();
      } else {
        int idx = profiles.indexWhere((p) => p.id.toLowerCase() == cleanQuery || p.name.trim().toLowerCase() == cleanQuery);
        if (idx == -1) {
          profile = await addOrGetProfileByName(nameOrId);
        } else {
          profile = profiles[idx];
        }
      }

      var favTypes = profile.favoriteTypes;
      var favRegions = profile.favoriteRegions;
      var favGrapes = profile.favoriteGrapes;

      // La couleur dans le vocabulaire du profil. Les fiches rangent `white`, `red`… :
      // chercher « blanc » dans `white` rangeait chaque blanc aimé parmi les rouges. Un
      // moelleux ou un type inconnu n'ajoute aucune couleur plutôt qu'une fausse.
      final normalizedType = switch (couleurDuQuestionnaire(wine.type)) {
        'red' => 'Rouge',
        'white' => 'Blanc',
        'rose' => 'Rosé',
        'sparkling' => 'Bulles',
        _ => null,
      };
      final region = (wine.region.isNotEmpty && wine.region != 'Autre') ? wine.region : null;
      final grapes = wine.grapes.map((g) => g.name).where((n) => n.isNotEmpty).toList();

      if (rating >= kLikedThreshold) {
        // Aimé : on renforce, et ce qui vient d'être aimé passe devant.
        if (normalizedType != null) favTypes = _enTete(favTypes, [normalizedType], 6);
        if (region != null) favRegions = _enTete(favRegions, [region], 6);
        favGrapes = _enTete(favGrapes, grapes, 8);
      } else if (rating <= kDislikedThreshold) {
        // Déplu : on retire ce qui avait été ajouté. Le type de couleur est trop grossier
        // pour être retiré sur une seule déception — on ne touche qu'aux régions et cépages,
        // qui sont des signaux plus spécifiques.
        if (region != null) favRegions = _sans(favRegions, [region]);
        favGrapes = _sans(favGrapes, grapes);
      }
      // Entre les deux seuils, la dégustation ne dit rien de tranché : on n'ajoute ni ne retire.

      final updated = profile.copyWith(
        favoriteTypes: favTypes,
        favoriteRegions: favRegions,
        favoriteGrapes: favGrapes,
        // Le compteur s'incrémente pour TOUTE dégustation, y compris décevante : il mesure
        // l'expérience accumulée, pas le nombre de bons souvenirs.
        questionnairesCompleted: profile.questionnairesCompleted + 1,
      );
      await updateProfile(updated);

      final registre = await TasteEvidenceLedger.ouvrir();
      final maintenant = DateTime.now();
      final aime = rating >= kLikedThreshold;
      final deplu = rating <= kDislikedThreshold;
      if (aime || deplu) {
        final verbe = aime ? 'ajouté' : 'retiré';
        await registre.ajouter([
          if (region != null)
            TasteEvidenceEntry(
              quand: maintenant,
              source: 'degustation',
              cible: 'region:$region',
              effet: '$verbe après une note de ${rating.toStringAsFixed(1)}/10.',
              vin: wine.name,
              tastingId: tastingId,
            ),
          for (final g in grapes)
            TasteEvidenceEntry(
              quand: maintenant,
              source: 'degustation',
              cible: 'cepage:$g',
              effet: '$verbe après une note de ${rating.toStringAsFixed(1)}/10.',
              vin: wine.name,
              tastingId: tastingId,
            ),
        ]);
      }
    } catch (e) {
      AppLogger.warning('TASTE_PROFILE', 'Could not record tasting experience for $nameOrId: $e');
    }
  }

  Future<void> deleteProfile(String profileId) async {
    final profiles = await getProfiles();
    profiles.removeWhere((p) => p.id == profileId && !p.isPrimary);
    await saveProfiles(profiles);
  }

  // =========================================================================
  // INCREMENTAL LEARNING: Apply questionnaire results to a profile
  // =========================================================================

  /// Apply one questionnaire result to the given profile.
  /// [wineRegion], [wineGrapes], [wineType] provide context about what was drunk.
  Future<void> applyQuestionnaireResult({
    required TastingQuestionnaireResult result,
    String? wineRegion,
    List<String>? wineGrapes,
    String? wineType,
    String? tastingId,
    String? wineName,
  }) async {
    final profiles = await getProfiles();
    final idx = profiles.indexWhere((p) => p.id == result.profileId);
    if (idx == -1) return;

    var profile = profiles[idx];
    final n = profile.questionnairesCompleted;

    // 1. Increment questionnaire count
    profile = profile.copyWith(questionnairesCompleted: n + 1);

    // 2. Update aroma preferences: +1 for each selected aroma on liked wines (note ≥ 6)
    if (result.noteOutOf10 >= 6.0) {
      final updatedAromas = Map<String, int>.from(profile.aromaPreferences);
      for (final aroma in result.perceivedAromas) {
        updatedAromas[aroma] = (updatedAromas[aroma] ?? 0) + 1;
      }
      profile = profile.copyWith(aromaPreferences: updatedAromas);
    }

    // 3. Update liked traits
    final updatedLiked = Map<String, int>.from(profile.likedTraits);
    for (final trait in result.whatLikedMost) {
      // « Rien de particulier », « Décevant » : pas des goûts (V2.4 · R3).
      if (TastingQuestionnaireResult.reponsesSansTrait.contains(trait)) continue;
      updatedLiked[trait] = (updatedLiked[trait] ?? 0) + 1;
    }
    profile = profile.copyWith(likedTraits: updatedLiked);

    // 4. Update disliked traits
    final updatedDisliked = Map<String, int>.from(profile.dislikedTraits);
    for (final trait in result.whatDislikedMost) {
      if (TastingQuestionnaireResult.reponsesSansTrait.contains(trait)) continue;
      updatedDisliked[trait] = (updatedDisliked[trait] ?? 0) + 1;
    }
    profile = profile.copyWith(dislikedTraits: updatedDisliked);

    // 5. Les axes du palais.
    //
    // Une dégustation fait au plus UN pas par axe, vers la moyenne de ce qu'elle y a
    // mesuré (la réponse, les micro-touches). Avant, l'acidité d'un même vin pouvait être
    // appliquée par la réponse, le toucher et le fruit, puis une quatrième fois par le
    // cépage : une bouteille pesait pour quatre.
    //
    // Un vin aimé (≥ 5) attire l'axe vers lui. Un vin qui déçoit (≤ 4) l'en éloigne d'un
    // demi-pas au plus, et seulement s'il ressemblait à la préférence : loin du palais, la
    // déception confirme le modèle sans rien lui apprendre. Un défaut nommé (« trop
    // acide ») vaut pour son axe quelle que soit la note : un vin aimé malgré son acidité
    // n'apprend pas le goût de l'acidité.
    //
    // Le cépage n'est pas une mesure. Sur un vin aimé, il pose au plus un a priori sur un
    // axe encore vide, que rien n'a observé ni déclaré : le radar le dessine flou, et la
    // première mesure le remplace. Ni boisé ni minéralité : ils tiennent à l'élevage et au
    // sol, pas au cépage (un Chardonnay de Chablis n'est pas un Chardonnay de Californie).
    final aime = result.noteOutOf10 >= 5.0;
    final decu = result.noteOutOf10 <= kDislikedThreshold;
    final cleanType = (wineType ?? '').toLowerCase();
    final isRedWine = cleanType.contains('rouge') || cleanType == 'red';

    // Une gorgée qui n'a pas mesuré la bouche ne doit rien apprendre sur ces axes : les
    // appliquer avec une valeur neutre créerait une observation, donc de la confiance, à
    // partir de rien.
    final mesures = <String, List<double>>{};
    void mesurer(String axe, double? valeur) {
      if (valeur != null) (mesures[axe] ??= []).add(valeur);
    }

    mesurer('acidity', result.acidity);
    mesurer('body', result.body);
    // La minéralité perçue d'un blanc ou d'un rosé, comme l'acidité et le corps.
    mesurer('minerality', result.mineralite);
    if (isRedWine && result.tannins != null && result.tannins! > 0) {
      mesurer('tannin', result.tannins);
    }

    // Fast-Tasting Micro-Tap 1: Toucher de Bouche
    switch (result.mouthfeelTexture) {
      case 'silky_lacy':
        mesurer('freshFruit', 0.75);
        mesurer('minerality', 0.70);
        if (isRedWine) mesurer('tannin', 0.40);
        break;
      case 'crisp_salivating':
        mesurer('acidity', 0.85);
        mesurer('minerality', 0.80);
        break;
      case 'dense_structured':
        mesurer('body', 0.80);
        if (isRedWine) mesurer('tannin', 0.80);
        break;
    }

    // Fast-Tasting Micro-Tap 2: Éclat du Fruit
    switch (result.fruitProfile) {
      case 'crunchy_tart':
        mesurer('freshFruit', 0.85);
        mesurer('acidity', 0.75);
        break;
      case 'deep_ripe':
        mesurer('ripeFruit', 0.85);
        mesurer('body', 0.70);
        break;
      case 'spicy_herbal':
        mesurer('spice', 0.85);
        mesurer('minerality', 0.65);
        break;
    }

    final sensDesDefauts = <String, double>{};
    for (final defaut in result.whatDislikedMost) {
      _axesDesDefauts[defaut]?.forEach((axe, sens) => sensDesDefauts[axe] = sens);
    }

    final observations = Map<String, int>.from(profile.axisObservations);
    final avant = {for (final axe in TasteProfile.axisKeys) axe: profile.valeurAxe(axe)};
    final apres = Map<String, double?>.from(avant);
    final confirmes = <String>{};
    mesures.forEach((axe, valeurs) {
      final cible = valeurs.reduce((a, b) => a + b) / valeurs.length;
      // Sans observation, la valeur en place n'est qu'un a priori : la mesure la remplace.
      final etabli = (observations[axe] ?? 0) > 0 ? avant[axe] : null;
      final sensImpose = sensDesDefauts[axe];
      if (aime && sensImpose == null) {
        apres[axe] = _runningAvg(etabli, cible, n);
        confirmes.add(axe);
      } else if ((decu || sensImpose != null) && etabli != null) {
        final sens = sensImpose ?? (etabli - cible).sign;
        final marge = sens * (etabli - cible);
        if (sens != 0 && marge < 0.5) {
          apres[axe] = (etabli + sens * kAxisSmoothing / 2 * (0.5 - marge)).clamp(0.0, 1.0);
        }
      }
    });

    // L'a priori du cépage (Passive Bottle Auto-Enrichment), sur un vin bien aimé.
    final supposes = <String>{};
    if (result.noteOutOf10 >= 7.0 && wineGrapes != null) {
      final parAxe = <String, List<double>>{};
      void supposer(String axe, double valeur) => (parAxe[axe] ??= []).add(valeur);
      for (final g in wineGrapes) {
        final cepage = g.toLowerCase();
        if (cepage.contains('syrah') || cepage.contains('shiraz')) {
          supposer('spice', 0.85);
          supposer('ripeFruit', 0.75);
        } else if ((cepage.contains('cabernet') && !cepage.contains('franc')) ||
            cepage.contains('malbec') || cepage.contains('mourv') || cepage.contains('tannat')) {
          if (isRedWine) supposer('tannin', 0.80);
        } else if (cepage.contains('pinot noir') || cepage.contains('gamay')) {
          supposer('freshFruit', 0.80);
          supposer('acidity', 0.75);
        } else if (cepage.contains('sauvignon') || cepage.contains('riesling') || cepage.contains('chenin')) {
          supposer('acidity', 0.85);
        }
      }
      parAxe.forEach((axe, valeurs) {
        final libre = apres[axe] == null &&
            (observations[axe] ?? 0) == 0 &&
            !profile.palaisDeDepart.containsKey(axe);
        if (!libre) return;
        apres[axe] = valeurs.reduce((a, b) => a + b) / valeurs.length;
        supposes.add(axe);
      });
    }

    // Compter les observations par axe : un axe mesuré sur un vin aimé, même s'il ne
    // bouge pas (une mesure qui confirme la préférence est une preuve de plus : sans elle,
    // quelqu'un qui touche toujours « Vif & Salivant » restait à une observation), ou
    // déplacé par une déception. Jamais par l'a priori du cépage. C'est ce compte qui
    // permet d'afficher la confiance du modèle plutôt qu'une fausse précision uniforme sur
    // les huit axes, et de tracer en pointillé ce qui n'est que deviné.
    //
    // Tracer chaque observation, avant d'écraser les anciennes valeurs : c'est le seul
    // moment où l'on dispose de l'avant et de l'après, et ce qui permet de la décompter si
    // la dégustation est supprimée.
    final tracesAxes = <TasteEvidenceEntry>[];
    final maintenant = DateTime.now();
    for (final axe in TasteProfile.axisKeys) {
      final av = avant[axe];
      final ap = apres[axe];
      if (ap == null || (ap == av && !confirmes.contains(axe))) continue;
      final suppose = supposes.contains(axe);
      if (!suppose) observations[axe] = (observations[axe] ?? 0) + 1;
      final sens = suppose
          ? 'supposé à ${ap.toStringAsFixed(2)} d\'après le cépage, en attendant une mesure'
          : av == null
              ? 'renseigné à ${ap.toStringAsFixed(2)}'
              : ap == av
                  ? 'confirmé à ${ap.toStringAsFixed(2)}'
                  : '${ap > av ? 'monté' : 'descendu'} '
                      'de ${av.toStringAsFixed(2)} à ${ap.toStringAsFixed(2)}';
      tracesAxes.add(TasteEvidenceEntry(
        quand: maintenant,
        source: result.isExpressMode ? 'gorgee' : 'degustation',
        cible: 'axe:$axe',
        effet: '$sens (note ${result.noteOutOf10.toStringAsFixed(1)}/10).',
        vin: wineName,
        tastingId: tastingId,
        // L'avant et l'après en clair : la moyenne exponentielle ne se remonte pas, donc
        // le seul moyen de pouvoir défaire ce pas est de l'avoir noté en le faisant.
        avant: av,
        apres: ap,
      ));
    }
    if (tracesAxes.isNotEmpty) {
      await (await TasteEvidenceLedger.ouvrir()).ajouter(tracesAxes);
    }

    profile = profile.copyWith(
      avgAcidityPreference: apres['acidity'],
      avgBodyPreference: apres['body'],
      avgTanninPreference: apres['tannin'],
      avgOakPreference: apres['oak'],
      avgRipeFruitPreference: apres['ripeFruit'],
      avgSpicePreference: apres['spice'],
      avgFreshFruitPreference: apres['freshFruit'],
      avgMineralityPreference: apres['minerality'],
      axisObservations: observations,
    );

    // 6. Update ideal moments
    final updatedMoments = Map<String, int>.from(profile.idealMoments);
    updatedMoments[result.idealMoment] = (updatedMoments[result.idealMoment] ?? 0) + 1;
    profile = profile.copyWith(idealMoments: updatedMoments);

    // Ce que cette dégustation ajoute ou retire aux favoris, tracé pour pouvoir être défait.
    // Contrairement aux axes, l'appartenance à un ensemble s'annule exactement : il suffit
    // de savoir ce qui a été mis pour savoir quoi enlever.
    final tracesFavoris = <TasteEvidenceEntry>[];
    final horodatage = DateTime.now();
    void tracerFavori(String cible, String effet) => tracesFavoris.add(TasteEvidenceEntry(
          quand: horodatage,
          source: result.isExpressMode ? 'gorgee' : 'degustation',
          cible: cible,
          effet: effet,
          vin: wineName,
          tastingId: tastingId,
        ));

    // 7. Auto-discover favorites (conservative: on high ratings + would buy again)
    // Ce que la dégustation confirme passe devant (`_enTete`) ; seul ce qui n'y était pas
    // est tracé comme ajouté.
    if (result.noteOutOf10 >= 7.5 && result.wouldBuyAgain != 'no') {
      final note = result.noteOutOf10.toStringAsFixed(1);
      if (wineRegion != null && wineRegion.isNotEmpty) {
        final deja = profile.favoriteRegions;
        final regions = _enTete(deja, [wineRegion], 6);
        if (!_contient(deja, wineRegion)) {
          tracerFavori('region:$wineRegion', 'ajouté après une note de $note/10.');
        }
        profile = profile.copyWith(favoriteRegions: regions);
      }

      if (wineGrapes != null) {
        final deja = profile.favoriteGrapes;
        final grapes = _enTete(deja, wineGrapes, 8);
        for (final g in grapes) {
          if (!_contient(deja, g)) tracerFavori('cepage:$g', 'ajouté après une note de $note/10.');
        }
        profile = profile.copyWith(favoriteGrapes: grapes);
      }

      if (wineType != null && wineType.isNotEmpty) {
        profile = profile.copyWith(
          favoriteTypes: _enTete(profile.favoriteTypes, [_wineTypeToLabel(wineType)], 6),
        );
      }
    }

    // 7 bis. Symétrie : une déception retire ce qu'un enthousiasme avait ajouté.
    // `recordTastingExperience` le fait déjà ; sans cet équivalent ici, le chemin du
    // questionnaire restait un cliquet — les favoris ne pouvaient que s'accumuler, et une
    // région détestée deux fois de suite y figurait toujours.
    if (result.noteOutOf10 <= kDislikedThreshold) {
      final note = result.noteOutOf10.toStringAsFixed(1);
      if (wineRegion != null && wineRegion.isNotEmpty) {
        final regions = List<String>.from(profile.favoriteRegions)
          ..removeWhere((r) => r.toLowerCase() == wineRegion.toLowerCase());
        if (regions.length != profile.favoriteRegions.length) {
          tracerFavori('region:$wineRegion', 'retiré après une note de $note/10.');
        }
        profile = profile.copyWith(favoriteRegions: regions);
      }
      if (wineGrapes != null && wineGrapes.isNotEmpty) {
        final lowered = wineGrapes.map((g) => g.toLowerCase()).toSet();
        final grapes = List<String>.from(profile.favoriteGrapes)
          ..removeWhere((g) => lowered.contains(g.toLowerCase()));
        if (grapes.length != profile.favoriteGrapes.length) {
          for (final g in wineGrapes) {
            tracerFavori('cepage:$g', 'retiré après une note de $note/10.');
          }
        }
        profile = profile.copyWith(favoriteGrapes: grapes);
      }
      // Le type de couleur n'est pas retiré : trop grossier pour une seule déception.
    }

    // 8. Auto-discover dislikes & Aversions (Hard negative filtering)
    final newDislikes = List<String>.from(profile.dislikedCharacteristics);
    for (final entry in updatedDisliked.entries) {
      if (entry.value >= 2 || (result.noteOutOf10 <= 4.0 && entry.value >= 1)) {
        final readable = _dislikedIdToLabel(entry.key);
        if (!newDislikes.any((d) => d.toLowerCase() == readable.toLowerCase())) {
          newDislikes.add(readable);
        }
      }
    }
    profile = profile.copyWith(dislikedCharacteristics: newDislikes);

    if (tracesFavoris.isNotEmpty) {
      await (await TasteEvidenceLedger.ouvrir()).ajouter(tracesFavoris);
    }

    // Save
    profiles[idx] = profile;
    await saveProfiles(profiles);

    AppLogger.info('TASTE_PROFILE',
        'Applied questionnaire for ${result.profileName}: note=${result.noteOutOf10}, '
        'texture=${result.mouthfeelTexture}, fruit=${result.fruitProfile}, total=${n + 1}');
  }

  /// Record a bottle addition to wishlist (+4.5 intent weight)
  Future<void> recordWishlistGrape(String profileId, String grape) async {
    final profiles = await getProfiles();
    final idx = profiles.indexWhere((p) => p.id == profileId);
    if (idx == -1) return;
    final p = profiles[idx];
    final updatedWish = Map<String, int>.from(p.wishlistGrapes);
    updatedWish[grape] = (updatedWish[grape] ?? 0) + 1;
    profiles[idx] = p.copyWith(wishlistGrapes: updatedWish);
    await saveProfiles(profiles);
  }


  /// Applique au profil ce que la cave révèle des gestes, et non des déclarations.
  ///
  /// Hiérarchie de preuves : **un rachat vaut plus qu'une bonne note.** Noter 9/10 coûte
  /// un geste ; revenir acheter le même vin six mois plus tard coûte de l'argent et une
  /// décision prise en connaissance de cause. Un vin racheté entre donc directement dans
  /// les favoris, sans attendre qu'une dégustation soit saisie.
  ///
  /// Ne touche qu'aux favoris explicites. L'inventaire de cépages, lui, alimente le
  /// radar par un autre champ ([syncCellarGrapes]) : les deux ne se recouvrent pas.
  Future<void> applyCellarBehaviour(String profileId, List<Bottle> bottles) async {
    final regions = CellarBehaviourEvidence.regionsRachetees(bottles);
    final cepages = CellarBehaviourEvidence.cepagesRachetes(bottles);
    if (regions.isEmpty && cepages.isEmpty) return;

    final profiles = await getProfiles();
    final idx = profiles.indexWhere((p) => p.id == profileId);
    if (idx == -1) return;

    final p = profiles[idx];
    final favRegions = List<String>.from(p.favoriteRegions);
    final favGrapes = List<String>.from(p.favoriteGrapes);
    final regionsAjoutees = [for (final r in regions.keys) if (_siPlace(favRegions, r, 6)) r];
    final cepagesAjoutes = [for (final c in cepages.keys) if (_siPlace(favGrapes, c, 8)) c];
    if (regionsAjoutees.isEmpty && cepagesAjoutes.isEmpty) return;

    profiles[idx] = p.copyWith(favoriteRegions: favRegions, favoriteGrapes: favGrapes);
    await saveProfiles(profiles);

    // Seulement ce qui est réellement entré : une liste pleine réécrivait la même entrée
    // au registre à chaque ouverture du profil.
    final maintenant = DateTime.now();
    final registre = await TasteEvidenceLedger.ouvrir();
    await registre.ajouter([
      for (final r in regionsAjoutees)
        TasteEvidenceEntry(
          quand: maintenant,
          source: 'rachat',
          cible: 'region:$r',
          effet: 'Vous y êtes revenu : ${regions[r]} vin racheté.',
        ),
      for (final c in cepagesAjoutes)
        TasteEvidenceEntry(
          quand: maintenant,
          source: 'rachat',
          cible: 'cepage:$c',
          effet: 'Vous y êtes revenu : ${cepages[c]} vin racheté.',
        ),
    ]);

    AppLogger.info('TASTE_PROFILE',
        'Rachats appliqués : régions=${regions.keys.join(", ")} '
        'cépages=${cepages.keys.join(", ")}');
  }

  /// Applique ce que la COMPOSITION de la cave révèle, indépendamment du rachat.
  ///
  /// Une cave n'est pas un échantillon aléatoire : c'est une suite de choix. Se fournir
  /// surtout en Saint-Joseph, ou accumuler quinze Syrah, en dit autant qu'une note — et
  /// souvent plus tôt, puisqu'on achète avant de déguster.
  ///
  /// Seules les régions et les cépages entrent dans les favoris : ce sont les deux
  /// dimensions que le profil sait porter. Les autres — appellation, type,
  /// classification, bande d'âge — sont enregistrées au registre, où elles expliquent le
  /// profil sans prétendre le piloter.
  Future<void> applyCellarConcentration(String profileId, List<Bottle> bottles) async {
    final signaux = CellarConcentration.detecter(bottles);
    if (signaux.isEmpty) return;

    final profiles = await getProfiles();
    final idx = profiles.indexWhere((p) => p.id == profileId);
    if (idx == -1) return;

    final p = profiles[idx];
    final favRegions = List<String>.from(p.favoriteRegions);
    final favGrapes = List<String>.from(p.favoriteGrapes);

    // Une région ou un cépage n'est nouveau que s'il entre dans les favoris : une liste
    // pleine le réécrivait au registre à chaque ouverture du profil.
    final nouveaux = <ConcentrationSignal>[];
    for (final s in signaux) {
      final nouveau = switch (s.dimension) {
        'region' => _siPlace(favRegions, s.valeur, 6),
        'cepage' => _siPlace(favGrapes, s.valeur, 8),
        _ => !p.concentrationsConnues.contains(s.cible),
      };
      if (nouveau) nouveaux.add(s);
    }

    if (nouveaux.isEmpty) return;

    profiles[idx] = p.copyWith(
      favoriteRegions: favRegions,
      favoriteGrapes: favGrapes,
      concentrationsConnues: {
        ...p.concentrationsConnues,
        ...nouveaux.map((s) => s.cible),
      }.toList(),
    );
    await saveProfiles(profiles);

    final maintenant = DateTime.now();
    await (await TasteEvidenceLedger.ouvrir()).ajouter([
      for (final s in nouveaux)
        TasteEvidenceEntry(
          quand: maintenant,
          source: 'cave',
          cible: s.cible,
          effet: s.effet,
        ),
    ]);
    AppLogger.info('TASTE_PROFILE',
        'Concentrations de cave : ${nouveaux.join(" · ")}');
  }

  /// Compte les cépages réellement **choisis** et encore en cave.
  ///
  /// Posséder plusieurs bouteilles d'un cépage est un signal d'intention fort — c'est
  /// pourquoi le radar le pondère lourdement (`wine_taste_radar.dart:433`). Mais il n'est
  /// un signal de goût que si la personne a choisi la bouteille :
  ///
  ///  - **`gift`** : un cadeau dit le goût de celui qui l'offre, pas celui qui le reçoit.
  ///    C'est l'inversion la plus grossière que le modèle puisse faire.
  ///  - **`supermarket`** : achat de dépannage, guidé par ce qui était en rayon.
  ///
  /// Les bouteilles bues (`consumed`) sont exclues aussi : elles sont déjà comptées, et
  /// bien mieux, par la dégustation elle-même. Ne compter que ce qui reste en cave évite
  /// de faire peser deux fois la même bouteille.
  static Map<String, int> cellarGrapeStock(List<Bottle> bottles) {
    const excluded = {'gift', 'supermarket'};
    final stock = <String, int>{};
    for (final b in bottles) {
      if (!b.isInCellar || b.quantity <= 0) continue;
      if (excluded.contains(b.sourceType)) continue;
      for (final grape in b.wine?.grapes ?? const <Grape>[]) {
        final name = grape.name.trim();
        if (name.isEmpty) continue;
        stock[name] = (stock[name] ?? 0) + b.quantity;
      }
    }
    return stock;
  }

  /// Sync cellar grape inventory bottle counts (+5.0 multi-bottle high intent weight)
  Future<void> syncCellarGrapes(String profileId, Map<String, int> grapeStock) async {
    final profiles = await getProfiles();
    final idx = profiles.indexWhere((p) => p.id == profileId);
    if (idx == -1) return;
    profiles[idx] = profiles[idx].copyWith(cellarGrapes: grapeStock);
    await saveProfiles(profiles);
  }

  // =========================================================================
  // Sommelier prompt formatting
  // =========================================================================

  String formatProfilesForSommelier(List<TasteProfile> profiles) {
    if (profiles.isEmpty) return 'Aucun profil renseigné.';
    final buffer = StringBuffer();
    for (final p in profiles) {
      buffer.writeln('- Profil: ${p.name} ${p.isPrimary ? "(Utilisateur principal)" : "(Co-dégustateur / Partenaire)"}');
      if (p.favoriteTypes.isNotEmpty) buffer.writeln('  * Couleurs/Types préférés: ${p.favoriteTypes.join(", ")}');
      if (p.favoriteRegions.isNotEmpty) buffer.writeln('  * Régions & Terroirs de prédilection: ${p.favoriteRegions.join(", ")}');
      if (p.favoriteGrapes.isNotEmpty) buffer.writeln('  * Cépages favoris: ${p.favoriteGrapes.join(", ")}');
      if (p.dislikedCharacteristics.isNotEmpty) buffer.writeln('  * N\'aime pas / À éviter: ${p.dislikedCharacteristics.join(", ")}');
      if (p.notes.isNotEmpty) buffer.writeln('  * Remarques & Style: ${p.notes}');

      // Learned palate profile
      if (p.questionnairesCompleted > 0) {
        buffer.writeln('  * Profil palais (basé sur ${p.questionnairesCompleted} dégustation${p.questionnairesCompleted > 1 ? "s" : ""}):');
        if (p.avgAcidityPreference != null) buffer.writeln('    - Acidité préférée: ${_axisLabel(p.avgAcidityPreference!, "mou", "vif")}');
        if (p.avgTanninPreference != null) buffer.writeln('    - Tanins préférés: ${_axisLabel(p.avgTanninPreference!, "fondus", "puissants")}');
        if (p.avgBodyPreference != null) buffer.writeln('    - Corps préféré: ${_axisLabel(p.avgBodyPreference!, "léger", "puissant")}');

        // Top aromas
        if (p.aromaPreferences.isNotEmpty) {
          final sorted = p.aromaPreferences.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          final top = sorted.take(5).map((e) => e.key.replaceAll('_', ' ')).join(', ');
          buffer.writeln('    - Arômes préférés: $top');
        }

        // Top liked traits. Un profil d'avant la V2.4 peut porter « rien_decevant » parmi ses
        // traits aimés : ce n'est pas un goût.
        final traitsAimes = p.likedTraits.entries
            .where((e) => !TastingQuestionnaireResult.reponsesSansTrait.contains(e.key))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        if (traitsAimes.isNotEmpty) {
          final top = traitsAimes.take(4).map((e) => _likedIdToLabel(e.key)).join(', ');
          buffer.writeln('    - Ce qu\'il/elle apprécie le plus: $top');
        }
      }

      // Strict anti-hallucination guard for sparse profiles
      final isSparse = (p.favoriteTypes.isEmpty && p.favoriteRegions.isEmpty && p.favoriteGrapes.isEmpty) || p.questionnairesCompleted <= 1;
      if (isSparse && !p.isPrimary) {
        buffer.writeln('  * STATUT STRICT SOMMELIER: Données très limitées pour ${p.name}. INTERDICTION FORMELLE d\'extrapoler des préférences pour les vins rouges ou des terroirs comme la Galice ! Si l\'utilisateur demande ce qu\'aime ${p.name}, indique factuellement qu\'elle n\'a dégusté qu\'un seul vin (un blanc) et que ses goûts sont encore en cours de découverte.');
      }
    }
    return buffer.toString();
  }

  /// Formats connected friends taste cards for the AI sommelier context
  String formatFriendsForSommelier(List<Friend> friends) {
    if (friends.isEmpty) return 'Aucun ami connecté.';
    final buffer = StringBuffer();
    for (final f in friends) {
      final p = f.tasteProfile;
      buffer.writeln('- Ami(e): ${f.displayName} (${f.handle})');
      if (p.favoriteTypes.isNotEmpty) buffer.writeln('  * Couleurs/Types préférés: ${p.favoriteTypes.join(", ")}');
      if (p.favoriteRegions.isNotEmpty) buffer.writeln('  * Régions & Terroirs de prédilection: ${p.favoriteRegions.join(", ")}');
      if (p.favoriteGrapes.isNotEmpty) buffer.writeln('  * Cépages favoris: ${p.favoriteGrapes.join(", ")}');
      if (p.dislikedCharacteristics.isNotEmpty) buffer.writeln('  * N\'aime pas / À éviter: ${p.dislikedCharacteristics.join(", ")}');
      if (p.notes.isNotEmpty) buffer.writeln('  * Remarques & Style: ${p.notes}');

      if (p.questionnairesCompleted > 0) {
        buffer.writeln('  * Palais appris:');
        if (p.avgAcidityPreference != null) buffer.writeln('    - Acidité préférée: ${_axisLabel(p.avgAcidityPreference!, "mou", "vif")}');
        if (p.avgTanninPreference != null) buffer.writeln('    - Tanins préférés: ${_axisLabel(p.avgTanninPreference!, "fondus", "puissants")}');
        if (p.avgBodyPreference != null) buffer.writeln('    - Corps préféré: ${_axisLabel(p.avgBodyPreference!, "léger", "puissant")}');
        if (p.aromaPreferences.isNotEmpty) {
          final sorted = p.aromaPreferences.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          final top = sorted.take(4).map((e) => e.key.replaceAll('_', ' ')).join(', ');
          buffer.writeln('    - Arômes préférés: $top');
        }
      }

      final isSparse = (p.favoriteTypes.isEmpty && p.favoriteRegions.isEmpty && p.favoriteGrapes.isEmpty) || p.questionnairesCompleted <= 1;
      if (isSparse) {
        buffer.writeln('  * STATUT STRICT SOMMELIER: Données très limitées pour ${f.displayName}. INTERDICTION FORMELLE d\'inventer des goûts pour les vins rouges ou terroirs non prouvés ! Expliquer factuellement que son profil se construit progressivement.');
      }
    }
    return buffer.toString();
  }

  // — Private helpers —

  /// Moyenne exponentielle d'un axe sensoriel.
  ///
  /// Remplace une moyenne cumulative `(courant × n + nouveau) / (n + 1)` qui gelait le profil :
  /// le poids d'une dégustation y valait 1/(n+1), soit 1,96 % après cinquante et 0,33 % après
  /// trois cents. Un palais qui évolue — ce qui est la norme les deux premières années —
  /// devenait intraçable. Simulation sur le cas d'un palais basculant de 0,80 à 0,32 :
  /// 120 dégustations contradictoires n'amenaient l'axe qu'à 0,400 ; l'exponentielle
  /// y parvient en huit.
  ///
  /// Le paramètre `count` n'est plus utilisé pour la pondération — il est conservé dans la
  /// signature parce que les appelants le passent, et parce qu'il sert à distinguer la
  /// toute première observation (qui initialise l'axe) des suivantes.
  double _runningAvg(double? current, double newVal, int count) {
    if (current == null) return newVal;
    return current * (1 - kAxisSmoothing) + newVal * kAxisSmoothing;
  }

  /// Les défauts que le questionnaire laisse nommer, avec l'axe qu'ils jugent et leur
  /// sens : « trop » demande moins (-1), « pas assez » davantage (+1).
  static const Map<String, Map<String, double>> _axesDesDefauts = {
    'trop_acide': {'acidity': -1},
    'trop_tannique': {'tannin': -1},
    'trop_boise': {'oak': -1},
    'trop_alcoolise': {'body': -1},
    'trop_leger': {'body': 1},
    'manque_fruit': {'freshFruit': 1, 'ripeFruit': 1},
  };

  static bool _contient(List<String> liste, String valeur) =>
      liste.any((x) => x.toLowerCase() == valeur.toLowerCase());

  /// Les favoris par ordre récent : ce qu'une dégustation vient de confirmer passe
  /// devant, et la liste garde les [max] plus récents. `take` sur un ensemble gardait les
  /// plus anciens : une liste pleine ne bougeait plus, quoi qu'on goûte ensuite.
  static List<String> _enTete(List<String> liste, Iterable<String> confirmes, int max) {
    final devant = <String>[];
    for (final c in confirmes) {
      if (c.isNotEmpty && !_contient(devant, c)) devant.add(c);
    }
    return [...devant, ...liste.where((x) => !_contient(devant, x))].take(max).toList();
  }

  static List<String> _sans(List<String> liste, Iterable<String> retires) =>
      [for (final x in liste) if (!retires.any((r) => r.toLowerCase() == x.toLowerCase())) x];

  /// Ce que la cave ajoute aux favoris : à la fin, et seulement s'il reste de la place.
  ///
  /// La cave est relue à chaque ouverture du profil. Si elle pouvait pousser dehors ce
  /// qu'une dégustation a mis, une cave de sept régions rachetées ferait tourner la liste
  /// à chaque ouverture. Une dégustation est une nouvelle ; la cave, un fond.
  static bool _siPlace(List<String> liste, String valeur, int max) {
    if (valeur.isEmpty || liste.length >= max || _contient(liste, valeur)) return false;
    liste.add(valeur);
    return true;
  }

  String _axisLabel(double val, String low, String high) {
    if (val < 0.3) return 'Plutôt $low';
    if (val < 0.5) return 'Modéré (légèrement $low)';
    if (val < 0.7) return 'Modéré (légèrement $high)';
    return 'Plutôt $high';
  }

  String _wineTypeToLabel(String type) {
    switch (type.toLowerCase()) {
      case 'red': return 'Rouge';
      case 'white': return 'Blanc';
      case 'rose': return 'Rosé';
      case 'sparkling': return 'Bulles / Champagne';
      case 'dessert': return 'Liquoreux / Dessert';
      case 'orange': return 'Vin Orange';
      default: return type;
    }
  }

  String _dislikedIdToLabel(String id) {
    switch (id) {
      case 'trop_acide': return 'Acidité agressive';
      case 'trop_tannique': return 'Tanins trop râpeux';
      case 'trop_boise': return 'Boisé / vanillé excessif';
      case 'trop_alcoolise': return 'Vins lourds et trop alcoolisés';
      case 'trop_leger': return 'Vins trop légers / dilués';
      case 'manque_fruit': return 'Manque de fruit';
      case 'trop_sucre': return 'Vins trop sucrés';
      case 'trop_cher': return 'Rapport qualité-prix décevant';
      default: return id.replaceAll('_', ' ');
    }
  }

  String _likedIdToLabel(String id) {
    switch (id) {
      case 'fraicheur': return 'la fraîcheur';
      case 'fruite': return 'le fruité';
      case 'complexite': return 'la complexité';
      case 'elegance': return 'l\'élégance';
      case 'puissance': return 'la puissance';
      case 'soyeux': return 'le côté soyeux';
      case 'originalite': return 'l\'originalité';
      case 'accord_plat': return 'les accords mets-vins';
      case 'minerale': return 'la minéralité';
      case 'longueur': return 'la longueur en bouche';
      default: return id.replaceAll('_', ' ');
    }
  }

  String momentIdToLabel(String id) {
    switch (id) {
      case 'apero': return 'Apéritif';
      case 'repas': return 'Repas du quotidien';
      case 'grand_diner': return 'Grand dîner';
      case 'diner_romantique': return 'Dîner romantique';
      case 'solo': return 'Solo / Méditation';
      default: return id.replaceAll('_', ' ');
    }
  }
}
