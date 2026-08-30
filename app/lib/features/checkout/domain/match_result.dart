class MatchResult {
  final String bottleId;
  final String wineId;
  final String wineName;
  final int? vintage;
  final double similarity;
  final String? storagePath;

  const MatchResult({
    required this.bottleId,
    required this.wineId,
    required this.wineName,
    this.vintage,
    required this.similarity,
    this.storagePath,
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) => MatchResult(
    bottleId: json['bottle_id'] as String? ?? '',
    wineId: json['wine_id'] as String? ?? '',
    wineName: json['wine_name'] as String? ?? '',
    vintage: json['vintage'] as int?,
    similarity: (json['similarity'] as num?)?.toDouble() ?? 0.0,
    storagePath: json['storage_path'] as String?,
  );
}
