import 'dart:math' as math;

import '../../journal/domain/questionnaire_de_degustation.dart';
import 'palais.dart';
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

  /// Le palais que la personne a DÉCLARÉ à la première ouverture (six curseurs), par
  /// axe, sur 0–10. Un a priori, pas une observation : `axisObservations` reste à 0, la
  /// confiance affichée reste nulle, et dès la première vraie dégustation d'un axe la
  /// déclaration n'y pèse plus que 15 % (voir `WineTasteRadarCalculator.compute`).
  final Map<String, double> palaisDeDepart;

  /// Concentrations de cave déjà constatées ('appellation:Saint-Joseph', 'age:Jeune…').
  ///
  /// Sert uniquement à ne pas réécrire la même entrée au registre à chaque chargement de
  /// la cave : le fournisseur se déclenche à chaque ouverture de l'écran de profil.
  final List<String> concentrationsConnues;

  /// Les palais appris par famille de vins (V2.6 · P1) : `rouge`, et `blanc` pour les
  /// blancs, rosés, bulles, orange et liquoreux — chacun sur les six axes de
  /// [AxesDuPalais], de 0 à 1. Une seule moyenne de tous les vins disait « moyen » de
  /// quelqu'un qui aime les blancs légers et les rouges puissants : ni l'un ni l'autre.
  ///
  /// Les anciens champs `avg…Preference` sont le palais d'avant, toutes couleurs
  /// confondues : ils ne bougent plus, et servent de repli à un axe qu'une famille n'a pas
  /// encore appris ([valeurPalais]).
  final Map<String, Map<String, double>> palais;

  /// Les observations par famille et par axe : ce que la personne a dit elle-même (un
  /// « pour vous », une bouche décrite) ou ce que le vin disait sûrement (son âge, une
  /// douceur écrite). Ce qui n'est que déduit des vins aimés n'y compte pas.
  final Map<String, Map<String, int>> observationsPalais;
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

  // ---------------------------------------------------------------------------
  // Le palais par famille (V2.6)
  // ---------------------------------------------------------------------------

  /// La famille dont un vin relève : `rouge`, `blanc` (blancs, rosés, bulles, orange,
  /// liquoreux), ou nulle pour ce qui n'est pas un vin de table (muté, spiritueux, type
  /// inconnu) : on n'en apprend rien sur le palais.
  static String? familleDe(String? typeDuVin) {
    final c = couleurDuQuestionnaire(typeDuVin);
    if (c == 'red') return FamillesDeVins.rouge;
    if (const {'white', 'rose', 'sparkling', 'dessert', 'orange'}.contains(c)) return FamillesDeVins.blanc;
    return null;
  }

  /// Ce que la famille a appris sur un axe (0–1), sinon le palais d'avant, toutes couleurs
  /// confondues.
  double? valeurPalais(String famille, String axe) {
    if (!AxesDuPalais.deLaFamille(famille, axe)) return null;
    return palais[famille]?[axe] ?? _herite(famille, axe);
  }

  /// Ce que la famille a appris elle-même, sans le repli.
  double? valeurPropre(String famille, String axe) => palais[famille]?[axe];

  double? _herite(String famille, String axe) => switch (axe) {
        AxesDuPalais.fraicheur => avgAcidityPreference,
        AxesDuPalais.corps => avgBodyPreference,
        AxesDuPalais.boise => avgOakPreference,
        AxesDuPalais.tanins => famille == FamillesDeVins.rouge ? avgTanninPreference : null,
        _ => null,
      };

  /// Les observations d'un axe dans une famille. Un axe encore hérité du palais d'avant,
  /// appris sur toutes les couleurs, en reçoit la part que disent les couleurs préférées :
  /// toutes à la seule famille aimée, rien à l'autre ; la moitié à chacune sinon. Les
  /// tanins ne s'observaient que sur des rouges : ils leur reviennent en entier.
  int observationsSur(String famille, String axe) {
    final propres = observationsPalais[famille]?[axe];
    if (propres != null) return propres;
    if (palais[famille]?[axe] != null) return 0;
    if (_herite(famille, axe) == null) return 0;
    final n = axisObservations[axe] ?? 0;
    if (axe == AxesDuPalais.tanins) return n;
    final aimees = {for (final t in favoriteTypes) if (familleDe(t) case final f?) f};
    if (aimees.length == 1) return aimees.contains(famille) ? n : 0;
    return (n / 2).ceil();
  }

  /// Même saturation douce que [axisConfidence].
  double confianceSur(String famille, String axe) {
    final n = observationsSur(famille, axe);
    return n <= 0 ? 0.0 : n / (n + 5.0);
  }

  /// La famille la mieux connue ; à égalité, celle des couleurs préférées, sinon les rouges.
  String get familleDominante {
    int total(String f) => AxesDuPalais.de(f).fold(0, (s, a) => s + observationsSur(f, a));
    final r = total(FamillesDeVins.rouge);
    final b = total(FamillesDeVins.blanc);
    if (r != b) return r > b ? FamillesDeVins.rouge : FamillesDeVins.blanc;
    final types = favoriteTypes.map((t) => t.toLowerCase());
    final rouges = types.any((t) => t.contains('rouge') || t.contains('red'));
    final autres = types.any((t) => !(t.contains('rouge') || t.contains('red')));
    return autres && !rouges ? FamillesDeVins.blanc : FamillesDeVins.rouge;
  }

  /// Le palais d'une famille tel qu'on le montre et le compare (V2.6 · P5) : appris, sinon
  /// déclaré à l'accueil, sinon neutre — et rien d'autre. Les couleurs, régions et cépages
  /// préférés n'y ajoutent plus rien : ajoutés axe après axe, ils saturaient le radar à 10.
  /// Une aversion dite, faute de mieux, place l'axe bas.
  PalaisDeFamille palaisPour(String famille) {
    final valeurs = <String, double>{};
    final confiance = <String, double>{};
    final connus = <String>{};
    final aversions = dislikedCharacteristics.map((d) => d.toLowerCase()).toList();
    for (final axe in AxesDuPalais.de(famille)) {
      final appris = valeurPalais(famille, axe);
      final declare = palaisDeDepart[axe];
      final n = observationsSur(famille, axe);
      double v;
      if (appris != null) {
        v = (appris * 10).clamp(0.0, 10.0);
        if (declare != null) {
          // La déclaration s'efface devant l'observation : à parts égales avec une simple
          // déduction, puis 15 %, 10 % après une, deux observations, puis rien.
          final poids = n == 0 ? 0.5 : (n >= 3 ? 0.0 : 0.3 / (1 + n));
          v = declare * poids + v * (1 - poids);
        }
        connus.add(axe);
      } else if (declare != null) {
        v = declare.clamp(0.0, 10.0);
        connus.add(axe);
      } else {
        v = _aversion(axe, aversions) ?? AxesDuPalais.neutre(famille, axe);
      }
      valeurs[axe] = v;
      confiance[axe] = confianceSur(famille, axe);
    }
    return PalaisDeFamille(famille: famille, valeurs: valeurs, confiance: confiance, connus: connus);
  }

  static double? _aversion(String axe, List<String> aversions) {
    bool dit(List<String> mots) => aversions.any((d) => mots.any(d.contains));
    return switch (axe) {
      AxesDuPalais.tanins when dit(['tann', 'astringent', 'râpeux']) => 2.5,
      AxesDuPalais.fraicheur when dit(['acid', 'vif', 'vert']) => 3.0,
      AxesDuPalais.boise when dit(['boisé', 'bois', 'vanill']) => 1.5,
      AxesDuPalais.douceur when dit(['sucr', 'doux']) => 0.3,
      AxesDuPalais.corps when dit(['lourd', 'alcool', 'puissant']) => 3.5,
      AxesDuPalais.corps when dit(['léger', 'dilu']) => 7.0,
      _ => null,
    };
  }

  /// Un axe d'une famille fixé à [valeur] (nulle : effacé, le repli reprend), avec son
  /// nombre d'observations (nul : effacé).
  TasteProfile avecAxeDuPalais(String famille, String axe, double? valeur, {int? observations, bool effacerObservations = false}) {
    final p = {for (final e in palais.entries) e.key: Map<String, double>.from(e.value)};
    final o = {for (final e in observationsPalais.entries) e.key: Map<String, int>.from(e.value)};
    if (valeur == null) {
      p[famille]?.remove(axe);
    } else {
      (p[famille] ??= {})[axe] = valeur.clamp(0.0, 1.0).toDouble();
    }
    if (effacerObservations) {
      o[famille]?.remove(axe);
    } else if (observations != null) {
      (o[famille] ??= {})[axe] = observations;
    }
    p.removeWhere((_, v) => v.isEmpty);
    o.removeWhere((_, v) => v.isEmpty);
    return copyWith(palais: p, observationsPalais: o);
  }

  double axisConfidence(String axis) {
    final n = axisObservations[axis] ?? 0;
    if (n <= 0) return 0.0;
    return n / (n + 5.0);
  }

  /// Confiance moyenne sur les huit axes — utile pour décider si le profil mérite d'être
  /// présenté comme un portrait ou comme une esquisse.
  double get overallConfidence =>
      // V2.6 : le palais le mieux connu des deux familles — quelqu'un qui ne boit que des
      // rouges a un palais connu, même si ses blancs restent à deviner.
      FamillesDeVins.toutes.map((f) => palaisPour(f).connaissance).reduce(math.max);

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
    this.palaisDeDepart = const {},
    this.concentrationsConnues = const [],
    this.palais = const {},
    this.observationsPalais = const {},
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
    Map<String, double>? palaisDeDepart,
    List<String>? concentrationsConnues,
    Map<String, Map<String, double>>? palais,
    Map<String, Map<String, int>>? observationsPalais,
    String? friendUserId,
    bool clearFriendUserId = false,
    // Les axes à vider (clés de [axisKeys]) : un `null` passé ci-dessus garde la valeur, et
    // défaire la dégustation qui a renseigné un axe doit le rendre vide.
    Set<String> clearAxes = const {},
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
      avgAcidityPreference: clearAxes.contains('acidity') ? null : (avgAcidityPreference ?? this.avgAcidityPreference),
      avgTanninPreference: clearAxes.contains('tannin') ? null : (avgTanninPreference ?? this.avgTanninPreference),
      avgBodyPreference: clearAxes.contains('body') ? null : (avgBodyPreference ?? this.avgBodyPreference),
      avgOakPreference: clearAxes.contains('oak') ? null : (avgOakPreference ?? this.avgOakPreference),
      avgRipeFruitPreference: clearAxes.contains('ripeFruit') ? null : (avgRipeFruitPreference ?? this.avgRipeFruitPreference),
      avgSpicePreference: clearAxes.contains('spice') ? null : (avgSpicePreference ?? this.avgSpicePreference),
      avgFreshFruitPreference: clearAxes.contains('freshFruit') ? null : (avgFreshFruitPreference ?? this.avgFreshFruitPreference),
      avgMineralityPreference: clearAxes.contains('minerality') ? null : (avgMineralityPreference ?? this.avgMineralityPreference),
      wishlistGrapes: wishlistGrapes ?? this.wishlistGrapes,
      cellarGrapes: cellarGrapes ?? this.cellarGrapes,
      idealMoments: idealMoments ?? this.idealMoments,
      questionnairesCompleted: questionnairesCompleted ?? this.questionnairesCompleted,
      axisObservations: axisObservations ?? this.axisObservations,
      palaisDeDepart: palaisDeDepart ?? this.palaisDeDepart,
      concentrationsConnues: concentrationsConnues ?? this.concentrationsConnues,
      palais: palais ?? this.palais,
      observationsPalais: observationsPalais ?? this.observationsPalais,
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
        if (palaisDeDepart.isNotEmpty) 'palais_de_depart': palaisDeDepart,
        'concentrations_connues': concentrationsConnues,
        if (palais.isNotEmpty) 'palais': palais,
        if (observationsPalais.isNotEmpty) 'observations_palais': observationsPalais,
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
      palaisDeDepart: (json['palais_de_depart'] is Map)
          ? {
              for (final e in (json['palais_de_depart'] as Map).entries)
                if (e.value is num) e.key.toString(): (e.value as num).toDouble(),
            }
          : const {},
      concentrationsConnues: (json['concentrations_connues'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      questionnairesCompleted: ((json['questionnaires_completed'] ?? json['questionnairesCompleted']) as num?)?.toInt() ?? 0,
      palais: _parFamille(json['palais'], (v) => v is num ? v.toDouble().clamp(0.0, 1.0).toDouble() : null),
      observationsPalais: _parFamille(json['observations_palais'], (v) => v is num ? v.toInt() : null),
      friendUserId: json['friend_user_id']?.toString(),
    );
  }

  static Map<String, Map<String, T>> _parFamille<T>(dynamic brut, T? Function(dynamic) lire) {
    if (brut is! Map) return const {};
    return {
      for (final f in brut.entries)
        if (f.value is Map)
          f.key.toString(): {
            for (final a in (f.value as Map).entries)
              if (lire(a.value) case final v?) a.key.toString(): v,
          },
    };
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
