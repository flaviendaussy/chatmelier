import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/utils/app_logger.dart';
import '../domain/apprentissage_du_palais.dart';
import '../domain/description_du_palais.dart';
import '../domain/palais.dart';
import '../domain/taste_profile.dart';
import '../../sommelier/domain/profil_du_vin.dart';
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
        palais: const {},
        observationsPalais: const {},
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

      var updated = profile.copyWith(
        favoriteTypes: favTypes,
        favoriteRegions: favRegions,
        favoriteGrapes: favGrapes,
        // Le compteur s'incrémente pour TOUTE dégustation, y compris décevante : il mesure
        // l'expérience accumulée, pas le nombre de bons souvenirs.
        questionnairesCompleted: profile.questionnairesCompleted + 1,
      );
      // Une note seule dit encore quelque chose du palais (V2.6 · P4) : le vin aimé tire
      // ses axes d'un demi-pas, son âge et une douceur écrite comptent.
      final famille = TasteProfile.familleDe(wine.type);
      if (famille != null) {
        updated = await _apprendreLePalais(
          updated,
          famille: famille,
          note: rating,
          vin: ProfilDuVin.deLaCave(wine),
          source: 'degustation',
          tastingId: tastingId,
          wineName: wine.name,
        );
      }
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
    Wine? vin,
    DateTime? le,
  }) =>
      // Le vin, quand l'appelant le donne entier, dit lui-même sa région, ses cépages et sa
      // couleur.
      _appliquerLeQuestionnaire(
        result: result,
        wineRegion: wineRegion ?? ((vin != null && vin.region.isNotEmpty && vin.region != 'Autre') ? vin.region : null),
        wineGrapes: wineGrapes ?? (vin == null ? null : [for (final g in vin.grapes) if (g.name.trim().isNotEmpty) g.name.trim()]),
        wineType: wineType ?? vin?.type,
        tastingId: tastingId,
        wineName: wineName ?? vin?.name,
        vin: vin,
        le: le,
      );

  Future<void> _appliquerLeQuestionnaire({
    required TastingQuestionnaireResult result,
    String? wineRegion,
    List<String>? wineGrapes,
    String? wineType,
    String? tastingId,
    String? wineName,
    Wine? vin,
    DateTime? le,
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

    // 5. Les axes du palais, appris par famille (V2.6 · P1, P4) : les rouges d'un côté,
    // les blancs, rosés et bulles de l'autre. Un muté ou un spiritueux n'apprend rien au
    // palais des vins de table.
    final famille = TasteProfile.familleDe(wineType ?? vin?.type);
    if (famille != null) {
      profile = await _apprendreLePalais(
        profile,
        famille: famille,
        note: result.noteOutOf10,
        jugements: ApprentissageDuPalais.jugementsDe(result.jugements, result.whatDislikedMost),
        mesures: _mesuresDe(result, famille),
        vin: ProfilDuVin.deLaCave(vin ?? _vinDe(wineName, wineType, wineRegion, wineGrapes), le: le),
        source: result.isExpressMode ? 'gorgee' : 'degustation',
        tastingId: tastingId,
        wineName: wineName ?? vin?.name,
      );
    }

    // 6. Update ideal moments
    if (result.idealMoment.isNotEmpty) {
      final updatedMoments = Map<String, int>.from(profile.idealMoments);
      updatedMoments[result.idealMoment] = (updatedMoments[result.idealMoment] ?? 0) + 1;
      profile = profile.copyWith(idealMoments: updatedMoments);
    }

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
        // Le palais par famille, en mots, avec ce qu'on en sait (V2.6).
        for (final l in DescriptionDuPalais.lignes(p)) {
          buffer.writeln(l);
        }

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
        buffer.writeln('  * ${DescriptionDuPalais.garde(p.name, p.questionnairesCompleted)}');
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
        for (final l in DescriptionDuPalais.lignes(p)) {
          buffer.writeln(l);
        }
        if (p.aromaPreferences.isNotEmpty) {
          final sorted = p.aromaPreferences.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          final top = sorted.take(4).map((e) => e.key.replaceAll('_', ' ')).join(', ');
          buffer.writeln('    - Arômes préférés: $top');
        }
      }

      final isSparse = (p.favoriteTypes.isEmpty && p.favoriteRegions.isEmpty && p.favoriteGrapes.isEmpty) || p.questionnairesCompleted <= 1;
      if (isSparse) {
        buffer.writeln('  * ${DescriptionDuPalais.garde(f.displayName, p.questionnairesCompleted)}');
      }
    }
    return buffer.toString();
  }

  // — Private helpers —

  /// Applique au palais de [famille] ce qu'une dégustation lui apprend, et l'inscrit au
  /// registre, axe par axe, avec l'avant et l'après pour pouvoir le défaire.
  Future<TasteProfile> _apprendreLePalais(
    TasteProfile profile, {
    required String famille,
    required double note,
    Map<String, String> jugements = const {},
    Map<String, double> mesures = const {},
    required ProfilDuVin vin,
    required String source,
    String? tastingId,
    String? wineName,
  }) async {
    final changements = ApprentissageDuPalais.apprendre(
      profil: profile,
      famille: famille,
      note: note,
      jugements: jugements,
      mesures: mesures,
      vin: vin,
    );
    if (changements.isEmpty) return profile;
    final maintenant = DateTime.now();
    final traces = <TasteEvidenceEntry>[];
    var p = profile;
    for (final c in changements) {
      // Le compte d'un axe encore hérité du palais d'avant devient le sien : sans cela, le
      // premier pas déduit le ferait retomber à zéro.
      final n = p.observationsSur(c.famille, c.axe);
      p = p.avecAxeDuPalais(c.famille, c.axe, c.apres, observations: c.compte ? n + 1 : n);
      traces.add(TasteEvidenceEntry(
        quand: maintenant,
        source: source,
        cible: 'axe:${c.famille}:${c.axe}',
        effet: _effetDuChangement(c, note),
        vin: wineName,
        tastingId: tastingId,
        avant: c.avant,
        apres: c.apres,
        compte: c.compte,
      ));
    }
    await (await TasteEvidenceLedger.ouvrir()).ajouter(traces);
    return p;
  }

  /// L'effet d'un changement, en clair, pour le registre.
  static String _effetDuChangement(ChangementDAxe c, double note) {
    final famille = c.famille == FamillesDeVins.rouge ? 'rouges' : 'blancs';
    final axe = AxesDuPalais.nom(c.axe).toLowerCase();
    final av = c.avant;
    final sens = av == null
        ? 'renseigné à ${c.apres.toStringAsFixed(2)}'
        : c.apres == av
            ? 'confirmé à ${c.apres.toStringAsFixed(2)}'
            : '${c.apres > av ? 'monté' : 'descendu'} de ${av.toStringAsFixed(2)} à ${c.apres.toStringAsFixed(2)}';
    final (pasAssez, juste, trop) = AxesDuPalais.jugements(c.axe);
    final raison = switch (c.motif) {
      'jugement' => '« ${switch (c.jugement) { 'trop' => trop, 'pas_assez' => pasAssez, _ => juste }} » à vos yeux',
      'mesure' => 'la bouche décrite',
      'sur' => c.axe == AxesDuPalais.evolution ? 'l\'âge du vin' : 'sa douceur écrite',
      'deception' => 'une déception',
      _ => 'déduit d\'un vin aimé',
    };
    return '$famille, $axe : $sens — $raison (note ${note.toStringAsFixed(1)}/10).';
  }

  /// La bouche que la personne a décrite elle-même (une dictée, les micro-touches d'avant
  /// la V2.6 qu'une dégustation porte encore) : une mesure par axe, moyenne de ce qui la dit.
  static Map<String, double> _mesuresDe(TastingQuestionnaireResult r, String famille) {
    final rouge = famille == FamillesDeVins.rouge;
    final parAxe = <String, List<double>>{};
    void ajouter(String axe, double? v) {
      if (v != null) (parAxe[axe] ??= []).add(v);
    }

    ajouter(AxesDuPalais.fraicheur, r.acidity);
    ajouter(AxesDuPalais.corps, r.body);
    if (rouge && (r.tannins ?? 0) > 0) ajouter(AxesDuPalais.tanins, r.tannins);
    switch (r.mouthfeelTexture) {
      case 'silky_lacy':
        if (rouge) ajouter(AxesDuPalais.tanins, 0.40);
        break;
      case 'crisp_salivating':
        ajouter(AxesDuPalais.fraicheur, 0.85);
        break;
      case 'dense_structured':
        ajouter(AxesDuPalais.corps, 0.80);
        if (rouge) ajouter(AxesDuPalais.tanins, 0.80);
        break;
    }
    switch (r.fruitProfile) {
      case 'crunchy_tart':
        ajouter(AxesDuPalais.fraicheur, 0.75);
        break;
      case 'deep_ripe':
        ajouter(AxesDuPalais.corps, 0.70);
        break;
    }
    return {for (final e in parAxe.entries) e.key: e.value.reduce((a, b) => a + b) / e.value.length};
  }

  /// Le vin dont on ne connaît que ce que la dégustation en a transmis.
  static Wine _vinDe(String? nom, String? type, String? region, List<String>? cepages) => Wine(
        id: '',
        name: nom ?? '',
        type: type ?? '',
        country: '',
        region: region ?? '',
        grapes: [for (final c in cepages ?? const <String>[]) if (c.trim().isNotEmpty) Grape(name: c.trim())],
      );

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
