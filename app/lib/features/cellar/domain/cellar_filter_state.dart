class CellarFilterState {
  final String? wineType;
  final String? continent;
  final String? country;
  final String? grape;
  final String? appellation;
  final String? maturityStatus;
  final int? vintage;
  final String searchQuery;
  final bool onlyFavorites;

  const CellarFilterState({
    this.wineType,
    this.continent,
    this.country,
    this.grape,
    this.appellation,
    this.maturityStatus,
    this.vintage,
    this.searchQuery = '',
    this.onlyFavorites = false,
  });

  bool get isActive =>
      wineType != null ||
      continent != null ||
      country != null ||
      grape != null ||
      appellation != null ||
      maturityStatus != null ||
      vintage != null ||
      onlyFavorites ||
      searchQuery.isNotEmpty;

  int get activeFilterCount {
    int count = 0;
    if (wineType != null) count++;
    if (continent != null) count++;
    if (country != null) count++;
    if (grape != null) count++;
    if (appellation != null) count++;
    if (maturityStatus != null) count++;
    if (vintage != null) count++;
    if (onlyFavorites) count++;
    return count;
  }

  CellarFilterState copyWith({
    String? Function()? wineType,
    String? Function()? continent,
    String? Function()? country,
    String? Function()? grape,
    String? Function()? appellation,
    String? Function()? maturityStatus,
    int? Function()? vintage,
    String? searchQuery,
    bool? onlyFavorites,
  }) {
    return CellarFilterState(
      wineType: wineType != null ? wineType() : this.wineType,
      continent: continent != null ? continent() : this.continent,
      country: country != null ? country() : this.country,
      grape: grape != null ? grape() : this.grape,
      appellation: appellation != null ? appellation() : this.appellation,
      maturityStatus: maturityStatus != null ? maturityStatus() : this.maturityStatus,
      vintage: vintage != null ? vintage() : this.vintage,
      searchQuery: searchQuery ?? this.searchQuery,
      onlyFavorites: onlyFavorites ?? this.onlyFavorites,
    );
  }

  CellarFilterState clear() => const CellarFilterState();
}
