import 'admin_console.dart';

/// Ce que coûte l'IA et ce que rapporte la pub, sur une période (migration 047, S5).
///
/// Le revenu est une ESTIMATION : impressions × eCPM de `app_config.ecpm_eur_estime`,
/// à remplacer par les chiffres réels de la console AdMob. L'écran le dit.
class BilanEconomique {
  final int jours;
  final bool inclutTests;
  final Map<String, double> ecpmEstime;
  final double coutIaEur;
  final int appelsIa;
  final int appelsGroundes;
  final double revenuPubEur;
  final int impressions;
  final List<LigneDeCout> parFonctionnalite;
  final List<LigneDePub> parEmplacement;
  final List<LigneDePlateforme> parPlateforme;
  final List<LigneDePersonne> parPersonne;

  const BilanEconomique({
    required this.jours,
    required this.inclutTests,
    required this.ecpmEstime,
    required this.coutIaEur,
    required this.appelsIa,
    required this.appelsGroundes,
    required this.revenuPubEur,
    required this.impressions,
    required this.parFonctionnalite,
    required this.parEmplacement,
    required this.parPlateforme,
    required this.parPersonne,
  });

  /// Revenu ÷ coût. Nul quand rien n'a coûté : un ratio infini ne dirait rien.
  double? get ratio => coutIaEur > 0 ? revenuPubEur / coutIaEur : null;

  static double _d(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
  static int _i(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
  static List<Map<String, dynamic>> _l(Object? v) =>
      v is List ? [for (final e in v) if (e is Map) Map<String, dynamic>.from(e)] : const [];

  factory BilanEconomique.fromJson(Map<String, dynamic> j) => BilanEconomique(
        jours: _i(j['jours']),
        inclutTests: j['inclut_tests'] == true,
        ecpmEstime: j['ecpm_eur_estime'] is Map
            ? {for (final e in (j['ecpm_eur_estime'] as Map).entries) '${e.key}': _d(e.value)}
            : const {},
        coutIaEur: _d(j['cout_ia_eur']),
        appelsIa: _i(j['appels_ia']),
        appelsGroundes: _i(j['appels_groundes']),
        revenuPubEur: _d(j['revenu_pub_eur_estime']),
        impressions: _i(j['impressions']),
        parFonctionnalite: [
          for (final e in _l(j['par_fonctionnalite']))
            LigneDeCout(e['fonctionnalite']?.toString() ?? '?', _i(e['appels']), _d(e['cout_eur'])),
        ],
        parEmplacement: [
          for (final e in _l(j['par_emplacement']))
            LigneDePub(e['format']?.toString() ?? '?', e['emplacement']?.toString() ?? '?', _i(e['impressions']),
                _d(e['revenu_eur'])),
        ],
        parPlateforme: [
          for (final e in _l(j['par_plateforme']))
            LigneDePlateforme(e['plateforme']?.toString() ?? '?', _d(e['cout_eur']), _d(e['revenu_eur'])),
        ],
        parPersonne: [
          for (final e in _l(j['par_personne']))
            LigneDePersonne(
              e['user_id']?.toString() ?? '',
              e['prenom']?.toString() ?? '?',
              _d(e['cout_eur']),
              _i(e['appels']),
              _d(e['revenu_eur']),
              _i(e['impressions']),
            ),
        ],
      );
}

class LigneDeCout {
  final String fonctionnalite;
  final int appels;
  final double coutEur;
  const LigneDeCout(this.fonctionnalite, this.appels, this.coutEur);

  /// Le nom lisible d'une fonctionnalité, tel qu'enregistré par l'app.
  String get libelle => switch (fonctionnalite) {
        'menu_scan_vision' => 'Scan de carte',
        'menu_chat_assistant' => 'Sommelier de la carte',
        'scan_vision' => 'Scan d\'étiquette',
        'scan_enrichment' => 'Enrichissement d\'étiquette',
        'chat_sommelier' => 'Sommelier de la cave',
        'offline_enrichment' => 'Enrichissement hors ligne',
        'text_wine_analysis' => 'Analyse d\'un vin saisi',
        // Les tâches de `taches-ia` comptent leur coût sous leur propre nom.
        _ => TachesIa.libelle(fonctionnalite),
      };
}

class LigneDePub {
  final String format;
  final String emplacement;
  final int impressions;
  final double revenuEur;
  const LigneDePub(this.format, this.emplacement, this.impressions, this.revenuEur);
}

class LigneDePlateforme {
  final String plateforme;
  final double coutEur;
  final double revenuEur;
  const LigneDePlateforme(this.plateforme, this.coutEur, this.revenuEur);
}

class LigneDePersonne {
  final String userId;
  final String prenom;
  final double coutEur;
  final int appels;
  final double revenuEur;
  final int impressions;
  const LigneDePersonne(this.userId, this.prenom, this.coutEur, this.appels, this.revenuEur, this.impressions);
}

/// Des montants de quelques centièmes de centime : en c€ sous un euro, en € au-delà,
/// avec la virgule française.
String euros(double v) {
  final texte = v.abs() < 1
      ? '${(v * 100).toStringAsFixed(v.abs() < 0.01 ? 3 : 2)} c€'
      : '${v.toStringAsFixed(2)} €';
  return texte.replaceAll('.', ',');
}
