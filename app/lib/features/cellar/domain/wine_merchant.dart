import 'package:uuid/uuid.dart';

/// Represents a wine merchant / caviste with Google Maps / location metadata.
class WineMerchant {
  final String id;
  final String name;
  final String? address;
  final String? city;
  final String? postalCode;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? placeId; // Google Maps Place ID
  final String? phoneNumber;
  final String? website;
  final String? notes;
  final bool isFavorite;
  final DateTime createdAt;

  const WineMerchant({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.postalCode,
    this.country,
    this.latitude,
    this.longitude,
    this.placeId,
    this.phoneNumber,
    this.website,
    this.notes,
    this.isFavorite = false,
    required this.createdAt,
  });

  factory WineMerchant.create({
    required String name,
    String? address,
    String? city,
    String? postalCode,
    String? country,
    double? latitude,
    double? longitude,
    String? placeId,
    String? phoneNumber,
    String? website,
    String? notes,
    bool isFavorite = false,
  }) {
    return WineMerchant(
      id: const Uuid().v4(),
      name: name,
      address: address,
      city: city,
      postalCode: postalCode,
      country: country,
      latitude: latitude,
      longitude: longitude,
      placeId: placeId,
      phoneNumber: phoneNumber,
      website: website,
      notes: notes,
      isFavorite: isFavorite,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'city': city,
        'postal_code': postalCode,
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
        'place_id': placeId,
        'phone_number': phoneNumber,
        'website': website,
        'notes': notes,
        'is_favorite': isFavorite,
        'created_at': createdAt.toIso8601String(),
      };

  factory WineMerchant.fromJson(Map<String, dynamic> json) => WineMerchant(
        id: json['id'] as String? ?? const Uuid().v4(),
        name: json['name'] as String? ?? 'Caviste',
        address: json['address'] as String?,
        city: json['city'] as String?,
        postalCode: json['postal_code'] as String?,
        country: json['country'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        placeId: json['place_id'] as String?,
        phoneNumber: json['phone_number'] as String?,
        website: json['website'] as String?,
        notes: json['notes'] as String?,
        isFavorite: json['is_favorite'] == true,
        createdAt: json['created_at'] != null
            ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
            : DateTime.now(),
      );

  WineMerchant copyWith({
    String? id,
    String? name,
    String? address,
    String? city,
    String? postalCode,
    String? country,
    double? latitude,
    double? longitude,
    String? placeId,
    String? phoneNumber,
    String? website,
    String? notes,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return WineMerchant(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeId: placeId ?? this.placeId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get fullAddressDisplay {
    final parts = [
      if (address != null && address!.isNotEmpty) address,
      if (city != null && city!.isNotEmpty) city,
      if (country != null && country!.isNotEmpty) country,
    ];
    return parts.isNotEmpty ? parts.join(', ') : 'Adresse non renseignée';
  }
}
