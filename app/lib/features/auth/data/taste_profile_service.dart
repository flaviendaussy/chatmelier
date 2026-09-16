import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/utils/app_logger.dart';
import '../domain/taste_profile.dart';
import '../domain/taste_evidence.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../cellar/domain/bottle.dart';
import '../domain/cellar_behaviour_evidence.dart';
import '../domain/cellar_concentration.dart';
import '../../cellar/domain/wine.dart';
import '../../friends/domain/friend.dart';
import '../../journal/domain/tasting_questionnaire_result.dart';

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

final tasteProfilesListProvider = FutureProvider<List<TasteProfile>>((ref) async {
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
  Future<void> recordTastingExperience({
    required String nameOrId,
    required Wine wine,
    required double rating,
    bool hadFault = false,
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

      final favTypes = Set<String>.from(profile.favoriteTypes);
      final favRegions = Set<String>.from(profile.favoriteRegions);
      final favGrapes = Set<String>.from(profile.favoriteGrapes);

      final normalizedType = wine.type.isEmpty
          ? null
          : (wine.type.toLowerCase().contains('blanc')
              ? 'Blanc'
              : (wine.type.toLowerCase().contains('ros') ? 'Rosé' : 'Rouge'));
      final region = (wine.region.isNotEmpty && wine.region != 'Autre') ? wine.region : null;
      final grapes = wine.grapes.map((g) => g.name).where((n) => n.isNotEmpty).toList();

      if (rating >= kLikedThreshold) {
        // Aimé : on renforce.
        if (normalizedType != null) favTypes.add(normalizedType);
        if (region != null) favRegions.add(region);
        favGrapes.addAll(grapes);
      } else if (rating <= kDislikedThreshold) {
        // Déplu : on retire ce qui avait été ajouté. Le type de couleur est trop grossier
        // pour être retiré sur une seule déception — on ne touche qu'aux régions et cépages,
        // qui sont des signaux plus spécifiques.
        if (region != null) favRegions.remove(region);
        favGrapes.removeAll(grapes);
      }
      // Entre les deux seuils, la dégustation ne dit rien de tranché : on n'ajoute ni ne retire.

      final updated = profile.copyWith(
        favoriteTypes: favTypes.take(6).toList(),
        favoriteRegions: favRegions.take(6).toList(),
        favoriteGrapes: favGrapes.take(8).toList(),
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
            ),
          for (final g in grapes)
            TasteEvidenceEntry(
              quand: maintenant,
              source: 'degustation',
              cible: 'cepage:$g',
              effet: '$verbe après une note de ${rating.toStringAsFixed(1)}/10.',
              vin: wine.name,
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
      updatedLiked[trait] = (updatedLiked[trait] ?? 0) + 1;
    }
    profile = profile.copyWith(likedTraits: updatedLiked);

    // 4. Update disliked traits
    final updatedDisliked = Map<String, int>.from(profile.dislikedTraits);
    for (final trait in result.whatDislikedMost) {
      if (trait == 'rien') continue; // "Rien, c'était parfait" doesn't count
      updatedDisliked[trait] = (updatedDisliked[trait] ?? 0) + 1;
    }
    profile = profile.copyWith(dislikedTraits: updatedDisliked);

    // 5. Update palate axis running averages (for liked wines, note ≥ 5)
    if (result.noteOutOf10 >= 5.0) {
      // Une gorgée qui n'a pas mesuré la bouche ne doit rien apprendre sur ces deux axes :
      // les appliquer avec une valeur neutre créerait une observation, donc de la confiance,
      // à partir de rien. On laisse l'axe exactement où il était.
      double? newAcidity = result.acidity == null
          ? profile.avgAcidityPreference
          : _runningAvg(profile.avgAcidityPreference, result.acidity!, n);
      double? newBody = result.body == null
          ? profile.avgBodyPreference
          : _runningAvg(profile.avgBodyPreference, result.body!, n);
      double? newTannin = profile.avgTanninPreference;
      double? newOak = profile.avgOakPreference;
      double? newRipeFruit = profile.avgRipeFruitPreference;
      double? newSpice = profile.avgSpicePreference;
      double? newFreshFruit = profile.avgFreshFruitPreference;
      double? newMinerality = profile.avgMineralityPreference;

      final cleanType = (wineType ?? '').toLowerCase();
      final isRedWine = cleanType.contains('rouge') || cleanType == 'red';
      if (isRedWine && result.tannins != null && result.tannins! > 0) {
        newTannin = _runningAvg(profile.avgTanninPreference, result.tannins!, n);
      }

      // Fast-Tasting Micro-Tap 1: Toucher de Bouche
      if (result.mouthfeelTexture != null) {
        switch (result.mouthfeelTexture) {
          case 'silky_lacy':
            newFreshFruit = _runningAvg(newFreshFruit, 0.75, n);
            newMinerality = _runningAvg(newMinerality, 0.70, n);
            if (isRedWine) newTannin = _runningAvg(newTannin, 0.40, n);
            break;
          case 'crisp_salivating':
            newAcidity = _runningAvg(newAcidity, 0.85, n);
            newMinerality = _runningAvg(newMinerality, 0.80, n);
            break;
          case 'dense_structured':
            newBody = _runningAvg(newBody, 0.80, n);
            if (isRedWine) newTannin = _runningAvg(newTannin, 0.80, n);
            break;
        }
      }

      // Fast-Tasting Micro-Tap 2: Éclat du Fruit
      if (result.fruitProfile != null) {
        switch (result.fruitProfile) {
          case 'crunchy_tart':
            newFreshFruit = _runningAvg(newFreshFruit, 0.85, n);
            newAcidity = _runningAvg(newAcidity, 0.75, n);
            break;
          case 'deep_ripe':
            newRipeFruit = _runningAvg(newRipeFruit, 0.85, n);
            newBody = _runningAvg(newBody, 0.70, n);
            break;
          case 'spicy_herbal':
            newSpice = _runningAvg(newSpice, 0.85, n);
            newMinerality = _runningAvg(newMinerality, 0.65, n);
            break;
        }
      }

      // Passive Bottle Auto-Enrichment (Implicit learning from grape variety on liked bottles)
      if (result.noteOutOf10 >= 7.0 && wineGrapes != null) {
        for (final g in wineGrapes) {
          final lowG = g.toLowerCase();
          if (lowG.contains('syrah') || lowG.contains('shiraz')) {
            newSpice = _runningAvg(newSpice, 0.85, n);
            newRipeFruit = _runningAvg(newRipeFruit, 0.75, n);
          } else if (lowG.contains('cabernet') || lowG.contains('malbec') || lowG.contains('mourvèdre')) {
            newTannin = _runningAvg(newTannin, 0.80, n);
            newOak = _runningAvg(newOak, 0.65, n);
          } else if (lowG.contains('pinot noir') || lowG.contains('gamay')) {
            newFreshFruit = _runningAvg(newFreshFruit, 0.80, n);
            newAcidity = _runningAvg(newAcidity, 0.75, n);
          } else if (lowG.contains('chardonnay')) {
            newMinerality = _runningAvg(newMinerality, 0.75, n);
            newOak = _runningAvg(newOak, 0.65, n);
          } else if (lowG.contains('sauvignon') || lowG.contains('riesling') || lowG.contains('chenin')) {
            newAcidity = _runningAvg(newAcidity, 0.85, n);
            newMinerality = _runningAvg(newMinerality, 0.80, n);
          }
        }
      }

      // Compter les observations par axe. Un axe n'est incrémenté que s'il a réellement
      // reçu une valeur : les tanins, par exemple, ne sont renseignés que sur les rouges.
      // C'est ce compte qui permet d'afficher la confiance du modèle plutôt qu'une
      // fausse précision uniforme sur les huit axes.
      final observations = Map<String, int>.from(profile.axisObservations);
      void observe(String axis, double? before, double? after) {
        if (after != null && after != before) {
          observations[axis] = (observations[axis] ?? 0) + 1;
        }
      }

      observe('acidity', profile.avgAcidityPreference, newAcidity);
      observe('body', profile.avgBodyPreference, newBody);
      observe('tannin', profile.avgTanninPreference, newTannin);
      observe('oak', profile.avgOakPreference, newOak);
      observe('ripeFruit', profile.avgRipeFruitPreference, newRipeFruit);
      observe('spice', profile.avgSpicePreference, newSpice);
      observe('freshFruit', profile.avgFreshFruitPreference, newFreshFruit);
      observe('minerality', profile.avgMineralityPreference, newMinerality);

      // Tracer ce qui a réellement bougé, avant d'écraser les anciennes valeurs : c'est
      // le seul moment où l'on dispose de l'avant et de l'après.
      final tracesAxes = <TasteEvidenceEntry>[];
      final maintenant = DateTime.now();
      void tracer(String axe, double? avant, double? apres) {
        if (apres == null || apres == avant) return;
        final sens = avant == null
            ? 'renseigné à ${apres.toStringAsFixed(2)}'
            : '${apres > avant ? 'monté' : 'descendu'} '
                'de ${avant.toStringAsFixed(2)} à ${apres.toStringAsFixed(2)}';
        tracesAxes.add(TasteEvidenceEntry(
          quand: maintenant,
          source: result.isExpressMode ? 'gorgee' : 'degustation',
          cible: 'axe:$axe',
          effet: '$sens (note ${result.noteOutOf10.toStringAsFixed(1)}/10).',
        ));
      }

      tracer('acidity', profile.avgAcidityPreference, newAcidity);
      tracer('body', profile.avgBodyPreference, newBody);
      tracer('tannin', profile.avgTanninPreference, newTannin);
      tracer('oak', profile.avgOakPreference, newOak);
      tracer('ripeFruit', profile.avgRipeFruitPreference, newRipeFruit);
      tracer('spice', profile.avgSpicePreference, newSpice);
      tracer('freshFruit', profile.avgFreshFruitPreference, newFreshFruit);
      tracer('minerality', profile.avgMineralityPreference, newMinerality);
      if (tracesAxes.isNotEmpty) {
        await (await TasteEvidenceLedger.ouvrir()).ajouter(tracesAxes);
      }

      profile = profile.copyWith(
        avgAcidityPreference: newAcidity,
        avgBodyPreference: newBody,
        avgTanninPreference: newTannin,
        avgOakPreference: newOak,
        avgRipeFruitPreference: newRipeFruit,
        avgSpicePreference: newSpice,
        avgFreshFruitPreference: newFreshFruit,
        avgMineralityPreference: newMinerality,
        axisObservations: observations,
      );
    }

    // 6. Update ideal moments
    final updatedMoments = Map<String, int>.from(profile.idealMoments);
    updatedMoments[result.idealMoment] = (updatedMoments[result.idealMoment] ?? 0) + 1;
    profile = profile.copyWith(idealMoments: updatedMoments);

    // 7. Auto-discover favorites (conservative: on high ratings + would buy again)
    if (result.noteOutOf10 >= 7.5 && result.wouldBuyAgain != 'no') {
      // Add region if not already present
      if (wineRegion != null && wineRegion.isNotEmpty) {
        final regions = List<String>.from(profile.favoriteRegions);
        if (!regions.any((r) => r.toLowerCase() == wineRegion.toLowerCase())) {
          regions.add(wineRegion);
          profile = profile.copyWith(favoriteRegions: regions);
        }
      }

      // Add grapes if not already present
      if (wineGrapes != null) {
        final grapes = List<String>.from(profile.favoriteGrapes);
        for (final g in wineGrapes) {
          if (g.isNotEmpty && !grapes.any((x) => x.toLowerCase() == g.toLowerCase())) {
            grapes.add(g);
          }
        }
        profile = profile.copyWith(favoriteGrapes: grapes);
      }

      // Add wine type if not present
      if (wineType != null && wineType.isNotEmpty) {
        final typeLabel = _wineTypeToLabel(wineType);
        final types = List<String>.from(profile.favoriteTypes);
        if (!types.any((t) => t.toLowerCase() == typeLabel.toLowerCase())) {
          types.add(typeLabel);
          profile = profile.copyWith(favoriteTypes: types);
        }
      }
    }

    // 7 bis. Symétrie : une déception retire ce qu'un enthousiasme avait ajouté.
    // `recordTastingExperience` le fait déjà ; sans cet équivalent ici, le chemin du
    // questionnaire restait un cliquet — les favoris ne pouvaient que s'accumuler, et une
    // région détestée deux fois de suite y figurait toujours.
    if (result.noteOutOf10 <= kDislikedThreshold) {
      if (wineRegion != null && wineRegion.isNotEmpty) {
        final regions = List<String>.from(profile.favoriteRegions)
          ..removeWhere((r) => r.toLowerCase() == wineRegion.toLowerCase());
        profile = profile.copyWith(favoriteRegions: regions);
      }
      if (wineGrapes != null && wineGrapes.isNotEmpty) {
        final lowered = wineGrapes.map((g) => g.toLowerCase()).toSet();
        final grapes = List<String>.from(profile.favoriteGrapes)
          ..removeWhere((g) => lowered.contains(g.toLowerCase()));
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
    final favRegions = Set<String>.from(p.favoriteRegions);
    final favGrapes = Set<String>.from(p.favoriteGrapes);
    final avant = favRegions.length + favGrapes.length;

    favRegions.addAll(regions.keys);
    favGrapes.addAll(cepages.keys);

    if (favRegions.length + favGrapes.length == avant) return;

    profiles[idx] = p.copyWith(
      favoriteRegions: favRegions.take(6).toList(),
      favoriteGrapes: favGrapes.take(8).toList(),
    );
    await saveProfiles(profiles);

    final maintenant = DateTime.now();
    final registre = await TasteEvidenceLedger.ouvrir();
    await registre.ajouter([
      for (final r in regions.keys)
        if (!p.favoriteRegions.contains(r))
          TasteEvidenceEntry(
            quand: maintenant,
            source: 'rachat',
            cible: 'region:$r',
            effet: 'Vous y êtes revenu : ${regions[r]} vin racheté.',
          ),
      for (final c in cepages.keys)
        if (!p.favoriteGrapes.contains(c))
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
    final favRegions = Set<String>.from(p.favoriteRegions);
    final favGrapes = Set<String>.from(p.favoriteGrapes);
    final avant = favRegions.length + favGrapes.length;

    final nouveaux = <ConcentrationSignal>[];
    for (final s in signaux) {
      final connu = switch (s.dimension) {
        'region' => !favRegions.add(s.valeur),
        'cepage' => !favGrapes.add(s.valeur),
        _ => p.concentrationsConnues.contains(s.cible),
      };
      if (!connu) nouveaux.add(s);
    }

    if (nouveaux.isEmpty) return;

    profiles[idx] = p.copyWith(
      favoriteRegions: favRegions.take(6).toList(),
      favoriteGrapes: favGrapes.take(8).toList(),
      concentrationsConnues: {
        ...p.concentrationsConnues,
        ...nouveaux.map((s) => s.cible),
      }.toList(),
    );
    if (favRegions.length + favGrapes.length != avant ||
        nouveaux.isNotEmpty) {
      await saveProfiles(profiles);
    }

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

        // Top liked traits
        if (p.likedTraits.isNotEmpty) {
          final sorted = p.likedTraits.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          final top = sorted.take(4).map((e) => _likedIdToLabel(e.key)).join(', ');
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
