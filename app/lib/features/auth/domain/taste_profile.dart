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

  /// Nombre d'observations accumulées par axe sensoriel, clé = nom d'axe
  /// (`tannin`, `body`, `oak`, `ripeFruit`, `spice`, `freshFruit`, `minerality`, `acidity`).
  ///
  /// Sert à calculer [axisConfidence]. Sans lui, les huit axes du radar s'affichent avec la
  /// même netteté qu'ils reposent sur soixante dégustations ou sur deux — une fausse
  /// précision qui rend le profil invérifiable, et ne donne à personne de raison de
  /// continuer à nourrir l'application.
  final Map<String, int> axisObservations;

  /// Concentrations de cave déjà constatées ('appellation:Saint-Joseph', 'age:Jeune…').
  ///
  /// Sert uniquement à ne pas réécrire la même entrée au registre à chaque chargement de
  /// la cave : le fournisseur se déclenche à chaque ouverture de l'écran de profil.
  final List<String> concentrationsConnues;
  final String? friendUserId; // Set if this profile corresponds to a connected friend who has the app

  bool get hasApp => friendUserId != null && friendUserId!.isNotEmpty;

  /// Les huit axes sensoriels, dans l'ordre du radar.
  static const List<String> axisKeys = [
    'tannin', 'body', 'oak', 'ripeFruit', 'spice', 'freshFruit', 'minerality', 'acidity',
  ];

  /// Confiance du modèle sur un axe, de 0 (aucune idée) à 1 (bien établi).
  ///
  /// Saturation douce : une observation donne déjà 0,17, cinq donnent 0,55, dix 0,71,
  /// vingt 0,83. La courbe est délibérément généreuse au début — il faut peu de
  /// dégustations pour avoir une idée grossière d'un palais — et lente ensuite, parce
  /// qu'une certitude réelle demande d'avoir vu la personne dans des contextes variés.
  ///
  /// C'est cette valeur qui rend l'empreinte de palais nette là où le modèle a observé et
  /// floue là où il devine, au lieu d'afficher partout la même fausse assurance.
  /// La valeur d'un axe par sa clé, ou nul s'il n'a jamais été renseigné.
  ///
  /// Les huit axes sont huit champs distincts ; sans cet accesseur, tout ce qui veut les
  /// parcourir — l'historique, le registre, le radar — doit répéter le même switch.
  double? valeurAxe(String axis) => switch (axis) {
        'acidity' => avgAcidityPreference,
        'body' => avgBodyPreference,
        'tannin' => avgTanninPreference,
        'oak' => avgOakPreference,
        'ripeFruit' => avgRipeFruitPreference,
        'spice' => avgSpicePreference,
        'freshFruit' => avgFreshFruitPreference,
        'minerality' => avgMineralityPreference,
        _ => null,
      };

  double axisConfidence(String axis) {
    final n = axisObservations[axis] ?? 0;
    if (n <= 0) return 0.0;
    return n / (n + 5.0);
  }

  /// Confiance moyenne sur les huit axes — utile pour décider si le profil mérite d'être
  /// présenté comme un portrait ou comme une esquisse.
  double get overallConfidence {
    final sum = axisKeys.fold<double>(0, (acc, k) => acc + axisConfidence(k));
    return sum / axisKeys.length;
  }

  /// L'axe le moins établi : c'est là qu'une dégustation apprendrait le plus.
  /// Entrée du moteur de frontière (S4).
  String get leastKnownAxis {
    var worst = axisKeys.first;
    for (final k in axisKeys) {
      if (axisConfidence(k) < axisConfidence(worst)) worst = k;
    }
    return worst;
  }

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
    this.axisObservations = const {},
    this.concentrationsConnues = const [],
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
    Map<String, int>? axisObservations,
    List<String>? concentrationsConnues,
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
      axisObservations: axisObservations ?? this.axisObservations,
      concentrationsConnues: concentrationsConnues ?? this.concentrationsConnues,
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
        'axis_observations': axisObservations,
        'concentrations_connues': concentrationsConnues,
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
      // `toJson` écrivait déjà `axis_observations`, mais rien ne le relisait : le compte
      // par axe était recalculé à chaque enregistrement puis perdu au rechargement, donc
      // la confiance affichée serait restée nulle en permanence.
      axisObservations: _castIntMap(json['axis_observations']),
      concentrationsConnues: (json['concentrations_connues'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
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
