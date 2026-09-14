import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/utils/app_logger.dart';
import '../domain/taste_profile.dart';
import '../../cellar/domain/wine.dart';
import '../../friends/domain/friend.dart';
import '../../journal/domain/tasting_questionnaire_result.dart';

final tasteProfileServiceProvider = Provider<TasteProfileService>((ref) {
  return TasteProfileService();
});

final tasteProfilesListProvider = FutureProvider<List<TasteProfile>>((ref) async {
  final service = ref.watch(tasteProfileServiceProvider);
  return service.getProfiles();
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

  Future<void> recordTastingExperience({
    required String nameOrId,
    required Wine wine,
    required double rating,
  }) async {
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

      // If user loved the wine (rating >= 7.5), reinforce preferred regions, types, and grapes
      if (rating >= 7.5) {
        final favTypes = Set<String>.from(profile.favoriteTypes);
        final favRegions = Set<String>.from(profile.favoriteRegions);
        final favGrapes = Set<String>.from(profile.favoriteGrapes);

        if (wine.type.isNotEmpty) {
          favTypes.add(wine.type.toLowerCase().contains('blanc') ? 'Blanc' : (wine.type.toLowerCase().contains('ros') ? 'Rosé' : 'Rouge'));
        }
        if (wine.region.isNotEmpty && wine.region != 'Autre') {
          favRegions.add(wine.region);
        }
        for (final g in wine.grapes) {
          if (g.name.isNotEmpty) favGrapes.add(g.name);
        }

        final updated = profile.copyWith(
          favoriteTypes: favTypes.take(6).toList(),
          favoriteRegions: favRegions.take(6).toList(),
          favoriteGrapes: favGrapes.take(8).toList(),
          questionnairesCompleted: profile.questionnairesCompleted + 1,
        );
        await updateProfile(updated);
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
      double? newAcidity = _runningAvg(profile.avgAcidityPreference, result.acidity, n);
      double? newBody = _runningAvg(profile.avgBodyPreference, result.body, n);
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

      profile = profile.copyWith(
        avgAcidityPreference: newAcidity,
        avgBodyPreference: newBody,
        avgTanninPreference: newTannin,
        avgOakPreference: newOak,
        avgRipeFruitPreference: newRipeFruit,
        avgSpicePreference: newSpice,
        avgFreshFruitPreference: newFreshFruit,
        avgMineralityPreference: newMinerality,
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

  double _runningAvg(double? current, double newVal, int count) {
    if (current == null || count == 0) return newVal;
    return (current * count + newVal) / (count + 1);
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
