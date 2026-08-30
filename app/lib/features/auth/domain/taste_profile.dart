class TasteProfile {
  final String id;
  final String name;
  final bool isPrimary;
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
  final Map<String, int> idealMoments; // momentId → count
  final int questionnairesCompleted; // total number of questionnaires answered

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
    this.idealMoments = const {},
    this.questionnairesCompleted = 0,
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
    Map<String, int>? idealMoments,
    int? questionnairesCompleted,
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
      idealMoments: idealMoments ?? this.idealMoments,
      questionnairesCompleted: questionnairesCompleted ?? this.questionnairesCompleted,
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
        'ideal_moments': idealMoments,
        'questionnaires_completed': questionnairesCompleted,
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
      idealMoments: _castIntMap(json['ideal_moments']),
      questionnairesCompleted: ((json['questionnaires_completed'] ?? json['questionnairesCompleted']) as num?)?.toInt() ?? 0,
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
