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
        // Filter out any legacy hardcoded mock profiles by specific IDs
        final clean = loaded.where((p) => p.id != 'flavien_main' && p.id != 'caro_profile' && (p.id != 'primary_user' || p.isPrimary)).toList();
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
      int idx = profiles.indexWhere((p) => p.id == nameOrId || p.name.trim().toLowerCase() == nameOrId.trim().toLowerCase());
      TasteProfile profile;
      if (idx == -1) {
        profile = await addOrGetProfileByName(nameOrId);
        final freshProfiles = await getProfiles();
        idx = freshProfiles.indexWhere((p) => p.id == profile.id);
      } else {
        profile = profiles[idx];
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
      profile = profile.copyWith(
        avgAcidityPreference: _runningAvg(profile.avgAcidityPreference, result.acidity, n),
        avgBodyPreference: _runningAvg(profile.avgBodyPreference, result.body, n),
      );
      if (result.tannins > 0) {
        profile = profile.copyWith(
          avgTanninPreference: _runningAvg(profile.avgTanninPreference, result.tannins, n),
        );
      }
    }

    // 6. Update ideal moments
    final updatedMoments = Map<String, int>.from(profile.idealMoments);
    updatedMoments[result.idealMoment] = (updatedMoments[result.idealMoment] ?? 0) + 1;
    profile = profile.copyWith(idealMoments: updatedMoments);

    // 7. Auto-discover favorites (conservative: only on high ratings + buy again)
    if (result.noteOutOf10 >= 8.0 && result.wouldBuyAgain == 'yes') {
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

    // 8. Auto-discover dislikes (conservative: need ≥ 3 mentions across questionnaires)
    final newDislikes = List<String>.from(profile.dislikedCharacteristics);
    for (final entry in updatedDisliked.entries) {
      if (entry.value >= 3) {
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
        'aromas=${result.perceivedAromas.length}, total=${n + 1}');
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
        buffer.writeln('  * Profil palais (basé sur ${p.questionnairesCompleted} dégustations):');
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
}
