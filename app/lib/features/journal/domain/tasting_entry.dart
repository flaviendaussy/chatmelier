class TastingEntry {
  final String id;
  final String? bottleId;
  final String wineId;
  final String? wineName;
  final int? vintage;
  final String? region;
  final String? country;
  final String? appellation;
  final String? wineType;
  final double? rating;
  final String? occasion;
  final String? foodPaired;
  final String? tastingNotes;
  final String? photoUrl;
  final List<String> coTasters; // List of friend names or usernames who tasted together
  final String? bottleOwnerId; // Id of the user whose cellar the bottle came from
  final String? bottleOwnerName; // e.g. 'Flavien', 'Caro'
  final String? locationName; // e.g. 'Chez Dimitri', 'Restaurant Le Comptoir'
  final bool isExternal; // true if tasted outside cellar
  final DateTime consumedAt;

  /// Échelle sur laquelle [rating] a été saisi : 10 après la migration 032, 5 avant —
  /// la contrainte `rating <= 5` n'ayant jamais été élargie en production, le client
  /// divisait chaque note par deux pour réussir l'insert. Explicite plutôt que devinée.
  final int ratingScale;

  /// Coup de cœur. Était auparavant encodé par `rating = 5.0`, indistinguable d'un 5/10 tiède.
  final bool isFavorite;

  /// Dégustation à l'aveugle : la seule note non contaminée par l'étiquette, le prix ou la
  /// réputation de l'appellation. Le mode existait dans le questionnaire, l'information était jetée.
  final bool isBlind;

  /// Défaut identifié ('cork', 'oxidation', 'reduction', 'other'). Non nul ⇒ la dégustation
  /// est **exclue** de l'apprentissage du profil : une bouteille bouchonnée n'apprend rien
  /// sur les goûts de la personne, et apprendrait même le contraire de la vérité.
  final String? fault;

  /// Conditions de service réellement appliquées ('cold', 'right', 'warm'), qui confondent
  /// autrement la note avec la température de service.
  final String? servedTemp;
  final bool? wasDecanted;

  const TastingEntry({
    required this.id,
    this.bottleId,
    required this.wineId,
    this.wineName,
    this.vintage,
    this.region,
    this.country,
    this.appellation,
    this.wineType,
    this.rating,
    this.occasion,
    this.foodPaired,
    this.tastingNotes,
    this.photoUrl,
    this.coTasters = const [],
    this.bottleOwnerId,
    this.bottleOwnerName,
    this.locationName,
    this.isExternal = false,
    required this.consumedAt,
    this.ratingScale = 10,
    this.isFavorite = false,
    this.isBlind = false,
    this.fault,
    this.servedTemp,
    this.wasDecanted,
  });

  /// User-friendly label for bottle origin and ownership
  String get originDescription {
    if (isExternal) {
      if (locationName != null && locationName!.isNotEmpty) {
        return 'Hors-cave ($locationName)';
      }
      return 'Hors-cave (Restaurant / Bar / Amis)';
    }
    final cleanOwnerName = bottleOwnerName?.trim();
    if (cleanOwnerName != null &&
        cleanOwnerName.isNotEmpty &&
        cleanOwnerName.toLowerCase() != 'moi' &&
        cleanOwnerName.toLowerCase() != 'primary' &&
        cleanOwnerName.toLowerCase() != 'primary_user') {
      return 'Cave de $cleanOwnerName';
    }
    return 'Ma Cave';
  }

  /// Note ramenée sur 10, d'après l'échelle **enregistrée** et non devinée.
  ///
  /// L'ancienne version doublait toute note ≤ 5 pour rattraper les lignes héritées de
  /// l'échelle /5. Correcte pour celles-là, elle transformait un 3,5/10 « décevant » en
  /// 7,0/10 « aimé » — repliant toute la moitié basse de l'échelle sur la moitié haute et
  /// rendant tout dégoût inapprenable. C'est désormais `rating_scale` qui tranche.
  double? get displayRating {
    if (rating == null) return null;
    return ratingScale == 5 ? rating! * 2 : rating;
  }

  /// Une dégustation n'apprend quelque chose sur le palais que si le vin était sain.
  bool get isUsableForTasteModel => fault == null;

  /// Formatted rating string, e.g. "10/10" or "9.5/10"
  String get formattedRating {
    final r = displayRating;
    if (r == null) return 'Non noté';
    return r % 1 == 0 ? '${r.toInt()}/10' : '${r.toStringAsFixed(1)}/10';
  }

  factory TastingEntry.fromJson(Map<String, dynamic> json) {
    final wineMap = json['wines'] as Map<String, dynamic>?;

    List<String> parsedCoTasters = [];
    final rawCo = json['co_tasters'];
    if (rawCo is List) {
      parsedCoTasters = rawCo.map((e) => e.toString()).toList();
    }

    return TastingEntry(
      id: json['id'] as String? ?? '',
      bottleId: json['bottle_id'] as String?,
      wineId: json['wine_id'] as String? ?? '',
      wineName: wineMap?['name'] as String? ?? json['wine_name'] as String? ?? json['name'] as String?,
      vintage: (wineMap?['vintage'] as num?)?.toInt() ?? (json['vintage'] as num?)?.toInt() ?? int.tryParse(json['vintage']?.toString() ?? ''),
      region: wineMap?['region'] as String? ?? json['region'] as String?,
      country: wineMap?['country'] as String? ?? json['country'] as String?,
      appellation: wineMap?['appellation'] as String? ?? json['appellation'] as String?,
      wineType: wineMap?['type'] as String? ?? json['wine_type'] as String? ?? json['type'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      occasion: json['occasion'] as String?,
      foodPaired: json['food_paired'] as String? ?? json['paired'] as String?,
      tastingNotes: json['tasting_notes'] as String? ?? json['notes'] as String?,
      photoUrl: json['photo_url'] as String? ?? json['image_url'] as String?,
      coTasters: parsedCoTasters,
      bottleOwnerId: json['bottle_owner_id'] as String?,
      bottleOwnerName: json['bottle_owner_name'] as String?,
      locationName: json['location_name'] as String?,
      isExternal: json['is_external'] == true,
      consumedAt: json['consumed_at'] != null ? DateTime.tryParse(json['consumed_at'].toString()) ?? DateTime.now() : DateTime.now(),
      ratingScale: _deduceScale(json),
      isFavorite: json['is_favorite'] == true,
      isBlind: json['is_blind'] == true,
      fault: json['fault'] as String?,
      servedTemp: json['served_temp'] as String?,
      wasDecanted: json['was_decanted'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (bottleId != null) 'bottle_id': bottleId,
        'wine_id': wineId,
        if (rating != null) 'rating': rating,
        if (occasion != null) 'occasion': occasion,
        if (foodPaired != null) 'food_paired': foodPaired,
        if (tastingNotes != null) 'tasting_notes': tastingNotes,
        if (photoUrl != null) 'photo_url': photoUrl,
        'co_tasters': coTasters,
        if (bottleOwnerId != null) 'bottle_owner_id': bottleOwnerId,
        if (bottleOwnerName != null) 'bottle_owner_name': bottleOwnerName,
        if (locationName != null) 'location_name': locationName,
        'is_external': isExternal,
        'rating_scale': ratingScale,
        'is_favorite': isFavorite,
        'is_blind': isBlind,
        if (fault != null) 'fault': fault,
        if (servedTemp != null) 'served_temp': servedTemp,
        if (wasDecanted != null) 'was_decanted': wasDecanted,
        'consumed_at': consumedAt.toIso8601String(),
        'wines': {
          'id': wineId,
          if (wineName != null) 'name': wineName,
          if (vintage != null) 'vintage': vintage,
          if (region != null) 'region': region,
          if (country != null) 'country': country,
          if (appellation != null) 'appellation': appellation,
          if (wineType != null) 'type': wineType,
        },
      };

  /// Déduit l'échelle d'une ligne qui ne la porte pas explicitement.
  ///
  /// L'absence de `rating_scale` n'est pas une information manquante : c'est la preuve que
  /// la migration 032 n'a pas tourné, donc que la contrainte `rating <= 5` tient encore,
  /// donc que le client a divisé la note par deux pour réussir l'insert. Le défaut est
  /// donc 5, et non 10. Deux exceptions, toutes deux démontrables :
  ///
  ///  1. **Une note > 5 était impossible côté serveur** sous cette contrainte. Une telle
  ///     valeur ne peut donc venir que du cache local, qui conserve la note pleine.
  ///  2. **Les charges locales du questionnaire et du checkout portent un identifiant
  ///     horodaté**, pas un UUID : elles n'ont jamais transité par la base, et stockent
  ///     elles aussi la note pleine.
  ///
  /// Reste un cas indécidable : une entrée locale non synchronisée, écrite par une version
  /// antérieure de l'app avec un identifiant UUID *et* une note ≤ 5/10. Aucune information
  /// disponible ne permet de trancher ; elle sera lue sur 5. Le cas se referme dès que la
  /// migration 032 est appliquée, puisque toute ligne porte alors son échelle.
  static int _deduceScale(Map<String, dynamic> json) {
    final explicite = (json['rating_scale'] as num?)?.toInt();
    if (explicite != null) return explicite;

    final note = (json['rating'] as num?)?.toDouble();
    if (note != null && note > 5.0) return 10;

    final id = json['id']?.toString() ?? '';
    final estUuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(id);
    if (id.isNotEmpty && !estUuid) return 10;

    return 5;
  }

}
