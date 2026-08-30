class ChangelogCategory {
  final String category;
  final List<String> items;

  const ChangelogCategory({
    required this.category,
    required this.items,
  });

  factory ChangelogCategory.fromJson(Map<String, dynamic> json) {
    return ChangelogCategory(
      category: json['category'] as String? ?? 'General',
      items: (json['items'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class ClientChangelog {
  final String summary;
  final List<String> highlights;

  const ClientChangelog({
    required this.summary,
    required this.highlights,
  });

  factory ClientChangelog.fromJson(Map<String, dynamic> json) {
    return ClientChangelog(
      summary: json['summary'] as String? ?? '',
      highlights: (json['highlights'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class DeveloperChangelog {
  final String summary;
  final List<ChangelogCategory> sections;

  const DeveloperChangelog({
    required this.summary,
    required this.sections,
  });

  factory DeveloperChangelog.fromJson(Map<String, dynamic> json) {
    return DeveloperChangelog(
      summary: json['summary'] as String? ?? '',
      sections: (json['sections'] as List<dynamic>?)
              ?.map((e) => ChangelogCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ChangelogEntry {
  final String version;
  final int buildNumber;
  final String releaseDate;
  final String title;
  final bool isLatest;
  final ClientChangelog client;
  final DeveloperChangelog developer;

  const ChangelogEntry({
    required this.version,
    required this.buildNumber,
    required this.releaseDate,
    required this.title,
    required this.isLatest,
    required this.client,
    required this.developer,
  });

  factory ChangelogEntry.fromJson(Map<String, dynamic> json) {
    return ChangelogEntry(
      version: json['version'] as String? ?? '1.0.0',
      buildNumber: json['buildNumber'] as int? ?? 1,
      releaseDate: json['releaseDate'] as String? ?? '',
      title: json['title'] as String? ?? '',
      isLatest: json['isLatest'] as bool? ?? false,
      client: ClientChangelog.fromJson(json['client'] as Map<String, dynamic>? ?? {}),
      developer: DeveloperChangelog.fromJson(json['developer'] as Map<String, dynamic>? ?? {}),
    );
  }
}
