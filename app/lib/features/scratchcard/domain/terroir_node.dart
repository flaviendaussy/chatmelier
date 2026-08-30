enum TerroirLevel {
  continent,
  country,
  region,
  appellation,
}

class TerroirNode {
  final String id;
  final String name;
  final String? parentName;
  final TerroirLevel level;
  final String flagEmoji;
  final String icon;
  final String description;
  final int tastedCount;
  final bool isUnlocked;
  final List<String> bottleNames;

  const TerroirNode({
    required this.id,
    required this.name,
    this.parentName,
    required this.level,
    required this.flagEmoji,
    required this.icon,
    required this.description,
    this.tastedCount = 0,
    this.isUnlocked = false,
    this.bottleNames = const [],
  });

  TerroirNode copyWith({
    int? tastedCount,
    bool? isUnlocked,
    List<String>? bottleNames,
  }) {
    return TerroirNode(
      id: id,
      name: name,
      parentName: parentName,
      level: level,
      flagEmoji: flagEmoji,
      icon: icon,
      description: description,
      tastedCount: tastedCount ?? this.tastedCount,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      bottleNames: bottleNames ?? this.bottleNames,
    );
  }
}
