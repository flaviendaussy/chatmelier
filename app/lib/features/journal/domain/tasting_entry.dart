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
  });

  /// User-friendly label for bottle origin and ownership
  String get originDescription {
    if (isExternal) {
      if (locationName != null && locationName!.isNotEmpty) {
        return 'Hors-cave ($locationName)';
      }
      return 'Hors-cave (Restaurant / Bar / Amis)';
    }
    if (bottleOwnerName != null && bottleOwnerName!.isNotEmpty) {
      return 'Cave de $bottleOwnerName';
    }
    return 'Ma Cave';
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
      wineName: wineMap?['name'] as String?,
      vintage: (wineMap?['vintage'] as num?)?.toInt(),
      region: wineMap?['region'] as String?,
      country: wineMap?['country'] as String?,
      appellation: wineMap?['appellation'] as String?,
      wineType: wineMap?['type'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      occasion: json['occasion'] as String?,
      foodPaired: json['food_paired'] as String?,
      tastingNotes: json['tasting_notes'] as String?,
      photoUrl: json['photo_url'] as String?,
      coTasters: parsedCoTasters,
      bottleOwnerId: json['bottle_owner_id'] as String?,
      bottleOwnerName: json['bottle_owner_name'] as String?,
      locationName: json['location_name'] as String?,
      isExternal: json['is_external'] == true,
      consumedAt: json['consumed_at'] != null ? DateTime.tryParse(json['consumed_at'].toString()) ?? DateTime.now() : DateTime.now(),
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
}
