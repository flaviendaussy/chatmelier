import 'wine_taste_radar.dart';

class TasteProfile {
  final String id;
  final String name;
  final bool isPrimary;

  WineTasteRadarMetrics get radarMetrics => WineTasteRadarCalculator.compute(this);

  /// Whether this profile has sufficient tasting history or depth to reliably flag personalized menu matches.
  /// Empty or bare profiles return false so UI indicates "Profil à compléter" instead of a flat 70%.
  bool get isWellProvided {
    if (questionnairesCompleted >= 3) return true;
    final totalExplicitPrefs = favoriteTypes.length + favoriteRegions.length + favoriteGrapes.length;
    if (totalExplicitPrefs >= 3) return true;
    if (aromaPreferences.length >= 3) return true;
    if (likedTraits.length >= 3) return true;
    return false;
  }

  final List<String> favoriteTypes; // e.g. ['Rouge', 'Blanc sec', 'Champagne']
  final List<String> favoriteRegions; // e.g. ['Vallée du Rhône', 'Bourgogne', 'Provence']
  final List<String> favoriteGrapes; // e.g. ['Pinot Noir', 'Syrah', 'Chardonnay']
  final List<String> dislikedCharacteristics; // e.g. ['Trop boisé', 'Trop acide', 'Trop tannique']
  final String notes;

  // — Learned from questionnaires (incremental) —
  final Map<String, int> aromaPreferences; // aromaId → cumulative score (each positive questionnaire adds +1)
  final Map<String, int> likedTraits; // likedId → count of times selected
  final Map<String, int> dislikedTraits; // dislikedId → count of times selected across different wines
  final double? avgAcidityPreference; // running average of preferred acidity (0-1)
  final double? avgTanninPreference; // running average of preferred tannins (0-1)
  final double? avgBodyPreference; // running average of preferred body (0-1)
  final double? avgOakPreference; // running average of preferred oak (0-1)
  final double? avgRipeFruitPreference; // running average of preferred ripe fruit (0-1)
  final double? avgSpicePreference; // running average of preferred spice (0-1)
  final double? avgFreshFruitPreference; // running average of preferred fresh fruit (0-1)
  final double? avgMineralityPreference; // running average of preferred minerality (0-1)
  final Map<String, int> wishlistGrapes; // grape -> wishlist intent (+4.5)
  final Map<String, int> cellarGrapes; // grape -> cellar inventory count (+5.0 multi-bottle)
  final Map<String, int> idealMoments; // momentId → count
  final int questionnairesCompleted; // total number of questionnaires answered
  final String? friendUserId; // Set if this profile corresponds to a connected friend who has the app

  bool get hasApp => friendUserId != null && friendUserId!.isNotEmpty;

  const TasteProfile({
    required this.id,
    required this.name,
    this.isPrimary = false,
    this.favoriteTypes = const [],
    this.favoriteRegions = const [],
    this.favoriteGrapes = const [],
    this.dislikedCharacteristics = const [],
    this.notes = '',
    this.aromaPreferences = const {},
    this.likedTraits = const {},
    this.dislikedTraits = const {},
    this.avgAcidityPreference,
    this.avgTanninPreference,
    this.avgBodyPreference,
    this.avgOakPreference,
    this.avgRipeFruitPreference,
    this.avgSpicePreference,
    this.avgFreshFruitPreference,
    this.avgMineralityPreference,
    this.wishlistGrapes = const {},
    this.cellarGrapes = const {},
    this.idealMoments = const {},
    this.questionnairesCompleted = 0,
    this.friendUserId,
  });

  TasteProfile copyWith({
    String? id,
    String? name,
    bool? isPrimary,
    List<String>? favoriteTypes,
    List<String>? favoriteRegions,
    List<String>? favoriteGrapes,
    List<String>? dislikedCharacteristics,
    String? notes,
    Map<String, int>? aromaPreferences,
    Map<String, int>? likedTraits,
    Map<String, int>? dislikedTraits,
    double? avgAcidityPreference,
    double? avgTanninPreference,
    double? avgBodyPreference,
    double? avgOakPreference,
    double? avgRipeFruitPreference,
    double? avgSpicePreference,
    double? avgFreshFruitPreference,
    double? avgMineralityPreference,
    Map<String, int>? wishlistGrapes,
    Map<String, int>? cellarGrapes,
    Map<String, int>? idealMoments,
    int? questionnairesCompleted,
    String? friendUserId,
    bool clearFriendUserId = false,
  }) {
    return TasteProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      isPrimary: isPrimary ?? this.isPrimary,
      favoriteTypes: favoriteTypes ?? this.favoriteTypes,
      favoriteRegions: favoriteRegions ?? this.favoriteRegions,
      favoriteGrapes: favoriteGrapes ?? this.favoriteGrapes,
      dislikedCharacteristics: dislikedCharacteristics ?? this.dislikedCharacteristics,
      notes: notes ?? this.notes,
      aromaPreferences: aromaPreferences ?? this.aromaPreferences,
      likedTraits: likedTraits ?? this.likedTraits,
      dislikedTraits: dislikedTraits ?? this.dislikedTraits,
      avgAcidityPreference: avgAcidityPreference ?? this.avgAcidityPreference,
      avgTanninPreference: avgTanninPreference ?? this.avgTanninPreference,
      avgBodyPreference: avgBodyPreference ?? this.avgBodyPreference,
      avgOakPreference: avgOakPreference ?? this.avgOakPreference,
      avgRipeFruitPreference: avgRipeFruitPreference ?? this.avgRipeFruitPreference,
      avgSpicePreference: avgSpicePreference ?? this.avgSpicePreference,
      avgFreshFruitPreference: avgFreshFruitPreference ?? this.avgFreshFruitPreference,
      avgMineralityPreference: avgMineralityPreference ?? this.avgMineralityPreference,
      wishlistGrapes: wishlistGrapes ?? this.wishlistGrapes,
      cellarGrapes: cellarGrapes ?? this.cellarGrapes,
      idealMoments: idealMoments ?? this.idealMoments,
      questionnairesCompleted: questionnairesCompleted ?? this.questionnairesCompleted,
      friendUserId: clearFriendUserId ? null : (friendUserId ?? this.friendUserId),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'is_primary': isPrimary,
        'favorite_types': favoriteTypes,
        'favorite_regions': favoriteRegions,
        'favorite_grapes': favoriteGrapes,
        'disliked_characteristics': dislikedCharacteristics,
        'notes': notes,
        'aroma_preferences': aromaPreferences,
        'liked_traits': likedTraits,
        'disliked_traits': dislikedTraits,
        'avg_acidity_preference': avgAcidityPreference,
        'avg_tannin_preference': avgTanninPreference,
        'avg_body_preference': avgBodyPreference,
        'avg_oak_preference': avgOakPreference,
        'avg_ripe_fruit_preference': avgRipeFruitPreference,
        'avg_spice_preference': avgSpicePreference,
        'avg_fresh_fruit_preference': avgFreshFruitPreference,
        'avg_minerality_preference': avgMineralityPreference,
        'wishlist_grapes': wishlistGrapes,
        'cellar_grapes': cellarGrapes,
        'ideal_moments': idealMoments,
        'questionnaires_completed': questionnairesCompleted,
        if (friendUserId != null) 'friend_user_id': friendUserId,
      };

  factory TasteProfile.fromJson(Map<String, dynamic> json) {
    return TasteProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Utilisateur',
      isPrimary: json['is_primary'] == true,
      favoriteTypes: List<String>.from(json['favorite_types'] ?? []),
      favoriteRegions: List<String>.from(json['favorite_regions'] ?? []),
      favoriteGrapes: List<String>.from(json['favorite_grapes'] ?? []),
      dislikedCharacteristics: List<String>.from(json['disliked_characteristics'] ?? []),
      notes: json['notes']?.toString() ?? '',
      aromaPreferences: _castIntMap(json['aroma_preferences']),
      likedTraits: _castIntMap(json['liked_traits']),
      dislikedTraits: _castIntMap(json['disliked_traits']),
      avgAcidityPreference: (json['avg_acidity_preference'] as num?)?.toDouble(),
      avgTanninPreference: (json['avg_tannin_preference'] as num?)?.toDouble(),
      avgBodyPreference: (json['avg_body_preference'] as num?)?.toDouble(),
      avgOakPreference: (json['avg_oak_preference'] as num?)?.toDouble(),
      avgRipeFruitPreference: (json['avg_ripe_fruit_preference'] as num?)?.toDouble(),
      avgSpicePreference: (json['avg_spice_preference'] as num?)?.toDouble(),
      avgFreshFruitPreference: (json['avg_fresh_fruit_preference'] as num?)?.toDouble(),
      avgMineralityPreference: (json['avg_minerality_preference'] as num?)?.toDouble(),
      wishlistGrapes: _castIntMap(json['wishlist_grapes']),
      cellarGrapes: _castIntMap(json['cellar_grapes']),
      idealMoments: _castIntMap(json['ideal_moments']),
      questionnairesCompleted: ((json['questionnaires_completed'] ?? json['questionnairesCompleted']) as num?)?.toInt() ?? 0,
      friendUserId: json['friend_user_id']?.toString(),
    );
  }

  static Map<String, int> _castIntMap(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(
            k.toString(),
            v is num ? v.toInt() : (int.tryParse(v?.toString() ?? '') ?? 0),
          ));
    }
    return {};
  }
}
