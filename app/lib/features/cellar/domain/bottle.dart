import 'wine.dart';
import 'wine_image_service.dart';

enum BottleStatus { inCellar, consumed, gifted, sold }

class Bottle {
  final String id;
  final String cellarId;
  final String wineId;
  final String addedBy;
  final String ownerId;
  final int quantity;
  final double? purchasePrice;
  final String currency;
  final DateTime? purchaseDate;
  final String? purchaseLocation;
  final String? sourceType; // 'estate', 'merchant', 'gift', 'supermarket', 'auction', 'other'
  final String? sourceDetails; // Merchant name/ID or gifted by person name
  final String? notes;
  final String? rack;
  final String? shelf;
  final String? position;
  final String status;
  final DateTime? consumedAt;
  final DateTime createdAt;
  final Wine? wine;
  final String? ownerName;
  final String? photoUrl;
  final int fillLevel; // 0 to 100 %, default 100

  const Bottle({
    required this.id,
    required this.cellarId,
    required this.wineId,
    required this.addedBy,
    required this.ownerId,
    this.quantity = 1,
    this.purchasePrice,
    this.currency = 'EUR',
    this.purchaseDate,
    this.purchaseLocation,
    this.sourceType,
    this.sourceDetails,
    this.notes,
    this.rack,
    this.shelf,
    this.position,
    this.status = 'in_cellar',
    this.consumedAt,
    required this.createdAt,
    this.wine,
    this.ownerName,
    this.photoUrl,
    this.fillLevel = 100,
  });

  factory Bottle.fromJson(Map<String, dynamic> json) {
    final photos = json['bottle_photos'];
    String? resolvedPhoto;
    if (photos is List && photos.isNotEmpty) {
      final first = photos.first;
      if (first is Map) {
        resolvedPhoto = (first['storage_path'] ?? first['photo_url']) as String?;
      }
    } else if (photos is Map) {
      resolvedPhoto = (photos['storage_path'] ?? photos['photo_url']) as String?;
    }
    resolvedPhoto ??= json['photo_url'] as String?;
    final wineObj = json['wines'] != null
        ? Wine.fromJson(json['wines'] as Map<String, dynamic>)
        : (json['wine'] != null ? Wine.fromJson(json['wine'] as Map<String, dynamic>) : null);

    if (resolvedPhoto == null || !WineImageService.isValidImagePath(resolvedPhoto)) {
      if (wineObj != null && WineImageService.isValidImagePath(wineObj.imageUrl)) {
        resolvedPhoto = wineObj.imageUrl;
      } else if (wineObj != null) {
        resolvedPhoto = WineImageService.resolveWineImageUrl(wineObj);
      }
    }

    final rawLocation = (json['purchase_location'] ?? json['purchaseLocation']) as String?;
    String? rawSourceType = json['source_type'] as String?;
    String? rawSourceDetails = json['source_details'] as String? ?? rawLocation;

    // Intelligent auto-detection of source type if not explicitly stored
    if (rawSourceType == null && rawLocation != null && rawLocation.isNotEmpty) {
      final locLower = rawLocation.toLowerCase();
      if (locLower.contains('domaine') || locLower.contains('château') || locLower.contains('propriété') || locLower.contains('vigneron')) {
        rawSourceType = 'estate';
      } else if (locLower.contains('caviste') || locLower.contains('cave') || locLower.contains('legrand') || locLower.contains('lavinia') || locLower.contains('nicolas')) {
        rawSourceType = 'merchant';
      } else if (locLower.contains('offert') || locLower.contains('cadeau')) {
        rawSourceType = 'gift';
      } else if (locLower.contains('leclerc') || locLower.contains('carrefour') || locLower.contains('monoprix') || locLower.contains('supermarché')) {
        rawSourceType = 'supermarket';
      } else if (locLower.contains('enchère') || locLower.contains('auction') || locLower.contains('idealwine')) {
        rawSourceType = 'auction';
      }
    }

    return Bottle(
      id: json['id'] as String? ?? '',
      cellarId: (json['cellar_id'] ?? json['cellarId']) as String? ?? '',
      wineId: (json['wine_id'] ?? json['wineId']) as String? ?? '',
      addedBy: (json['added_by'] ?? json['addedBy']) as String? ?? '',
      ownerId: (json['owner_id'] ?? json['ownerId']) as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      purchasePrice: ((json['purchase_price'] ?? json['purchasePrice']) as num?)?.toDouble(),
      currency: (json['currency'] as String?) ?? 'EUR',
      purchaseDate: (json['purchase_date'] ?? json['purchaseDate']) != null
          ? DateTime.tryParse((json['purchase_date'] ?? json['purchaseDate']).toString())
          : null,
      purchaseLocation: rawLocation,
      sourceType: rawSourceType,
      sourceDetails: rawSourceDetails,
      notes: json['notes'] as String?,
      rack: json['rack'] as String?,
      shelf: json['shelf'] as String?,
      position: json['position'] as String?,
      status: json['status'] as String? ?? 'in_cellar',
      consumedAt: (json['consumed_at'] ?? json['consumedAt']) != null
          ? DateTime.tryParse((json['consumed_at'] ?? json['consumedAt']).toString())
          : null,
      createdAt: (json['created_at'] ?? json['createdAt']) != null
          ? (DateTime.tryParse((json['created_at'] ?? json['createdAt']).toString()) ?? DateTime.now())
          : DateTime.now(),
      wine: wineObj,
      ownerName: (json['profiles'] as Map<String, dynamic>?)?['display_name'] as String?,
      photoUrl: resolvedPhoto,
      fillLevel: (json['fill_level'] ?? json['fillLevel'] as num?)?.toInt() ?? 100,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cellar_id': cellarId,
        'wine_id': wineId,
        'added_by': addedBy,
        'owner_id': ownerId,
        'quantity': quantity,
        if (purchasePrice != null) 'purchase_price': purchasePrice,
        'currency': currency,
        if (purchaseDate != null) 'purchase_date': purchaseDate!.toIso8601String(),
        if (purchaseLocation != null) 'purchase_location': purchaseLocation,
        if (sourceType != null) 'source_type': sourceType,
        if (sourceDetails != null) 'source_details': sourceDetails,
        if (notes != null) 'notes': notes,
        if (rack != null) 'rack': rack,
        if (shelf != null) 'shelf': shelf,
        if (position != null) 'position': position,
        'status': status,
        if (consumedAt != null) 'consumed_at': consumedAt!.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        if (wine != null) 'wines': wine!.toJson(),
        if (ownerName != null) 'profiles': {'display_name': ownerName},
        if (photoUrl != null) 'photo_url': photoUrl,
        'fill_level': fillLevel,
      };

  bool get isInCellar => status == 'in_cellar';
  bool get isConsumed => status == 'consumed';
  double get fillFraction => (fillLevel.clamp(0, 100)) / 100.0;
  bool get isSpiritBottle => wine?.isSpirit ?? false;

  /// Returns user-facing sommelier display text for bottle origin
  String get provenanceDisplay {
    final details = sourceDetails?.trim();
    switch (sourceType) {
      case 'estate':
        return '🏰 Acheté au domaine';
      case 'merchant':
        return details != null && details.isNotEmpty ? '🏪 Caviste : $details' : '🏪 Chez un caviste';
      case 'gift':
        return details != null && details.isNotEmpty ? '🎁 Offert par $details' : '🎁 Bouteille offerte';
      case 'supermarket':
        return details != null && details.isNotEmpty ? '🛒 Grande surface ($details)' : '🛒 Grande surface';
      case 'auction':
        return details != null && details.isNotEmpty ? '🔨 Enchères ($details)' : '🔨 Vente aux enchères';
      case 'other':
        return details != null && details.isNotEmpty ? '📦 $details' : '📦 Autre provenance';
      default:
        if (purchaseLocation != null && purchaseLocation!.isNotEmpty) {
          return '📍 $purchaseLocation';
        }
        return '📦 Stock cave';
    }
  }

  Bottle copyWith({
    String? id,
    String? cellarId,
    String? wineId,
    String? addedBy,
    String? ownerId,
    int? quantity,
    double? purchasePrice,
    String? currency,
    DateTime? purchaseDate,
    String? purchaseLocation,
    String? sourceType,
    String? sourceDetails,
    String? notes,
    String? rack,
    String? shelf,
    String? position,
    String? status,
    DateTime? consumedAt,
    DateTime? createdAt,
    Wine? wine,
    String? ownerName,
    String? photoUrl,
    int? fillLevel,
  }) {
    return Bottle(
      id: id ?? this.id,
      cellarId: cellarId ?? this.cellarId,
      wineId: wineId ?? this.wineId,
      addedBy: addedBy ?? this.addedBy,
      ownerId: ownerId ?? this.ownerId,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      currency: currency ?? this.currency,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchaseLocation: purchaseLocation ?? this.purchaseLocation,
      sourceType: sourceType ?? this.sourceType,
      sourceDetails: sourceDetails ?? this.sourceDetails,
      notes: notes ?? this.notes,
      rack: rack ?? this.rack,
      shelf: shelf ?? this.shelf,
      position: position ?? this.position,
      status: status ?? this.status,
      consumedAt: consumedAt ?? this.consumedAt,
      createdAt: createdAt ?? this.createdAt,
      wine: wine ?? this.wine,
      ownerName: ownerName ?? this.ownerName,
      photoUrl: photoUrl ?? this.photoUrl,
      fillLevel: fillLevel ?? this.fillLevel,
    );
  }
}
