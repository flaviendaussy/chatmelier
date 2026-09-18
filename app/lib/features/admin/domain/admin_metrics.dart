/// Un jour d'usage.
class JourDUsage {
  final DateTime jour;
  final int actifs;
  final int nouveaux;
  final int degustations;
  final int bouteilles;
  final int messages;
  final int vinsDecouverts;

  const JourDUsage({
    required this.jour,
    required this.actifs,
    required this.nouveaux,
    required this.degustations,
    required this.bouteilles,
    required this.messages,
    required this.vinsDecouverts,
  });

  factory JourDUsage.fromJson(Map<String, dynamic> j) => JourDUsage(
        jour: DateTime.tryParse(j['jour']?.toString() ?? '') ?? DateTime.now(),
        actifs: (j['actifs'] as num?)?.toInt() ?? 0,
        nouveaux: (j['nouveaux'] as num?)?.toInt() ?? 0,
        degustations: (j['degustations'] as num?)?.toInt() ?? 0,
        bouteilles: (j['bouteilles'] as num?)?.toInt() ?? 0,
        messages: (j['messages'] as num?)?.toInt() ?? 0,
        vinsDecouverts: (j['vins_decouverts'] as num?)?.toInt() ?? 0,
      );

  /// Tout ce qui a été produit ce jour-là, gestes confondus.
  int get gestes => degustations + bouteilles + messages + vinsDecouverts;
}

/// Les grands nombres, ceux qu'on lit en premier.
class ResumeDUsage {
  final int utilisateursTotal;
  final int anonymes;
  final int actifsPeriode;
  final int nouveauxPeriode;
  final int degustationsPeriode;
  final int bouteillesTotal;
  final int cavesTotal;
  final int vinsTotal;

  const ResumeDUsage({
    required this.utilisateursTotal,
    required this.anonymes,
    required this.actifsPeriode,
    required this.nouveauxPeriode,
    required this.degustationsPeriode,
    required this.bouteillesTotal,
    required this.cavesTotal,
    required this.vinsTotal,
  });

  factory ResumeDUsage.fromJson(Map<String, dynamic> j) => ResumeDUsage(
        utilisateursTotal: (j['utilisateurs_total'] as num?)?.toInt() ?? 0,
        anonymes: (j['anonymes'] as num?)?.toInt() ?? 0,
        actifsPeriode: (j['actifs_periode'] as num?)?.toInt() ?? 0,
        nouveauxPeriode: (j['nouveaux_periode'] as num?)?.toInt() ?? 0,
        degustationsPeriode: (j['degustations_periode'] as num?)?.toInt() ?? 0,
        bouteillesTotal: (j['bouteilles_total'] as num?)?.toInt() ?? 0,
        cavesTotal: (j['caves_total'] as num?)?.toInt() ?? 0,
        vinsTotal: (j['vins_total'] as num?)?.toInt() ?? 0,
      );

  static const vide = ResumeDUsage(
    utilisateursTotal: 0, anonymes: 0, actifsPeriode: 0, nouveauxPeriode: 0,
    degustationsPeriode: 0, bouteillesTotal: 0, cavesTotal: 0, vinsTotal: 0,
  );

  /// Part des comptes ouverts sans inscription. Utile : ils comptent dans la facture
  /// Supabase et ne rapportent rien tant qu'ils ne sont pas convertis.
  double get partAnonymes =>
      utilisateursTotal == 0 ? 0 : anonymes / utilisateursTotal;
}

/// Une part d'un camembert.
class Part {
  final String famille;
  final String libelle;
  final int valeur;
  const Part({required this.famille, required this.libelle, required this.valeur});

  factory Part.fromJson(Map<String, dynamic> j) => Part(
        famille: j['famille']?.toString() ?? '',
        libelle: j['libelle']?.toString() ?? '',
        valeur: (j['valeur'] as num?)?.toInt() ?? 0,
      );
}

/// Tout ce que la console affiche, pour une période donnée.
class TableauDeBord {
  final ResumeDUsage resume;
  final List<JourDUsage> jours;
  final List<Part> parts;

  const TableauDeBord({
    required this.resume,
    required this.jours,
    required this.parts,
  });

  List<Part> famille(String f) =>
      parts.where((p) => p.famille == f && p.valeur > 0).toList()
        ..sort((a, b) => b.valeur.compareTo(a.valeur));

  bool get estVide => jours.every((j) => j.actifs == 0 && j.gestes == 0);
}
