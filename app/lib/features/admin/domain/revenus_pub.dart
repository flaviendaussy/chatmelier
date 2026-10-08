/// Le revenu réel des pubs, tel que Google l'a payé impression par impression (migration
/// 065, `onPaidEvent`) : il remplace, dans la console, l'estimation par eCPM saisi à la main.
class RevenusPub {
  final int paiements;
  final int impressions;

  /// En euros ; nul si aucun paiement n'est convertible (devise sans taux connu).
  final double? revenuEur;
  final List<RevenuParDevise> parDevise;
  final List<RevenuParFormat> parFormat;

  const RevenusPub({
    required this.paiements,
    required this.impressions,
    required this.revenuEur,
    required this.parDevise,
    required this.parFormat,
  });

  /// Les montants dans une devise dont le taux n'est pas connu : montrés à part, jamais
  /// convertis au jugé.
  List<RevenuParDevise> get nonConvertis => [for (final d in parDevise) if (!d.converti) d];

  /// La part de l'IA que la pub paie, au revenu réel.
  double? ratioSur(double coutIaEur) => revenuEur == null || coutIaEur <= 0 ? null : revenuEur! / coutIaEur;

  factory RevenusPub.fromJson(Map<String, dynamic> j) => RevenusPub(
        paiements: _entier(j['paiements']),
        impressions: _entier(j['impressions']),
        revenuEur: _nombre(j['revenu_eur']),
        parDevise: [
          for (final d in (j['par_devise'] as List? ?? const []))
            if (d is Map)
              RevenuParDevise(
                devise: '${d['devise']}',
                total: _nombre(d['total']) ?? 0,
                paiements: _entier(d['paiements']),
                converti: d['converti'] == true,
              ),
        ],
        parFormat: [
          for (final f in (j['par_format'] as List? ?? const []))
            if (f is Map)
              RevenuParFormat(
                format: '${f['format']}',
                impressions: _entier(f['impressions']),
                paiements: _entier(f['paiements']),
                revenuEur: _nombre(f['revenu_eur']),
                ecpmReelEur: _nombre(f['ecpm_reel_eur']),
                ecpmEstimeEur: _nombre(f['ecpm_estime_eur']),
              ),
        ],
      );

  static int _entier(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
  static double? _nombre(Object? v) => v is num ? v.toDouble() : (v == null ? null : double.tryParse('$v'));
}

class RevenuParDevise {
  final String devise;
  final double total;
  final int paiements;
  final bool converti;
  const RevenuParDevise({required this.devise, required this.total, required this.paiements, required this.converti});
}

class RevenuParFormat {
  final String format;
  final int impressions;
  final int paiements;
  final double? revenuEur;
  final double? ecpmReelEur;
  final double? ecpmEstimeEur;
  const RevenuParFormat({
    required this.format,
    required this.impressions,
    required this.paiements,
    required this.revenuEur,
    required this.ecpmReelEur,
    required this.ecpmEstimeEur,
  });
}
