/// Du web à l'app (V2.3 · J6, K2) : ce que la page invité amène jusqu'à l'app installée, et
/// ce que l'IA du web coûte par installation obtenue (fonction serveur `admin_croissance`,
/// migration 053).
class BilanCroissance {
  /// Les sources d'installation qui viennent du web : le lien « Installer l'app » de la
  /// page invité. Les autres (« google-play » : une recherche dans le Play Store) ne sont
  /// pas dues au web et ne comptent pas dans le coût par installation.
  static const sourcesWeb = {'page_invite'};

  final int jours;
  final Map<String, int> parType;
  final Map<String, int> installationsParSource;
  final double coutIaWebEur;

  const BilanCroissance({
    required this.jours,
    required this.parType,
    required this.installationsParSource,
    required this.coutIaWebEur,
  });

  int evenements(String type) => parType[type] ?? 0;

  int get installationsWeb => [
        for (final e in installationsParSource.entries)
          if (sourcesWeb.contains(e.key)) e.value,
      ].fold(0, (a, b) => a + b);

  /// Le coût de l'IA du web divisé par les seules installations venues du web. Nul tant
  /// qu'aucune n'est venue : un coût infini ne dirait rien. (La fonction serveur divise par
  /// toutes les premières ouvertures, organiques comprises.)
  double? get coutWebParInstallationEur => installationsWeb == 0 ? null : coutIaWebEur / installationsWeb;

  static int _i(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
  static double _d(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
  static Map<String, int> _m(Object? v) =>
      v is Map ? {for (final e in v.entries) '${e.key}': _i(e.value)} : const {};

  factory BilanCroissance.fromJson(Map<String, dynamic> j) => BilanCroissance(
        jours: _i(j['jours']),
        parType: _m(j['par_type']),
        installationsParSource: _m(j['installations_par_source']),
        coutIaWebEur: _d(j['cout_ia_web_eur']),
      );
}
