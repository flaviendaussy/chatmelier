class Cellar {
  final String id;
  final String name;
  final String? nickname;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final String? description;
  final String? wifiSsid;
  final int radiusMeters;
  final String ownerId;
  final DateTime createdAt;

  const Cellar({
    required this.id,
    required this.name,
    this.nickname,
    this.locationName,
    this.latitude,
    this.longitude,
    this.description,
    this.wifiSsid,
    this.radiusMeters = 300,
    required this.ownerId,
    required this.createdAt,
  });

  factory Cellar.fromJson(Map<String, dynamic> json) => Cellar(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'My Cellar',
    nickname: json['nickname'] as String?,
    locationName: json['location_name'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    description: json['description'] as String?,
    wifiSsid: json['wifi_ssid'] as String?,
    radiusMeters: (json['radius_meters'] as num?)?.toInt() ?? 300,
    ownerId: json['owner_id'] as String? ?? '',
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (nickname != null) 'nickname': nickname,
    if (locationName != null) 'location_name': locationName,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (description != null) 'description': description,
    if (wifiSsid != null) 'wifi_ssid': wifiSsid,
    'radius_meters': radiusMeters,
    'owner_id': ownerId,
    'created_at': createdAt.toIso8601String(),
  };

  Cellar copyWith({
    String? id,
    String? name,
    String? nickname,
    String? locationName,
    double? latitude,
    double? longitude,
    String? description,
    String? wifiSsid,
    int? radiusMeters,
    String? ownerId,
    DateTime? createdAt,
  }) {
    return Cellar(
      id: id ?? this.id,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      wifiSsid: wifiSsid ?? this.wifiSsid,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get displayName => nickname ?? name;
  bool get hasLocation => locationName != null && locationName!.isNotEmpty;
  bool get hasGpsLocation => latitude != null && longitude != null;
  bool get hasWifi => wifiSsid != null && wifiSsid!.trim().isNotEmpty;
}
