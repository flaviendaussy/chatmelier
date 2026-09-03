class VineyardKnowledge {
  final String key;
  final String producerName;
  final String region;
  final String appellation;
  final String country;
  final String terroirDescription;
  final String? soilType;
  final String? viticultureStyle;
  final DateTime verifiedAt;
  final String source;

  const VineyardKnowledge({
    required this.key,
    required this.producerName,
    required this.region,
    required this.appellation,
    required this.country,
    required this.terroirDescription,
    this.soilType,
    this.viticultureStyle,
    required this.verifiedAt,
    this.source = 'sommelier_encyclopedia',
  });

  /// Check if the verification is 1 year old or more (>= 365 days)
  bool get isExpired {
    return DateTime.now().difference(verifiedAt).inDays >= 365;
  }

  /// Days remaining before re-verification
  int get daysUntilExpiry {
    final passed = DateTime.now().difference(verifiedAt).inDays;
    return (365 - passed).clamp(0, 365);
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'producer_name': producerName,
      'region': region,
      'appellation': appellation,
      'country': country,
      'terroir_description': terroirDescription,
      'soil_type': soilType,
      'viticulture_style': viticultureStyle,
      'verified_at': verifiedAt.toIso8601String(),
      'source': source,
    };
  }

  factory VineyardKnowledge.fromJson(Map<String, dynamic> json) {
    return VineyardKnowledge(
      key: json['key'] as String? ?? '',
      producerName: json['producer_name'] as String? ?? '',
      region: json['region'] as String? ?? '',
      appellation: json['appellation'] as String? ?? '',
      country: json['country'] as String? ?? '',
      terroirDescription: json['terroir_description'] as String? ?? '',
      soilType: json['soil_type'] as String?,
      viticultureStyle: json['viticulture_style'] as String?,
      verifiedAt: json['verified_at'] != null
          ? DateTime.tryParse(json['verified_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      source: json['source'] as String? ?? 'sommelier_encyclopedia',
    );
  }
}
