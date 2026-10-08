import 'package:flutter/material.dart';

/// La console, deuxième version (V2.4 · R9, migration 060) : les réglages qui se changeaient
/// au SQL Editor, les retours suivis, l'économie et les erreurs jour par jour, les versions
/// installées. Réservée au compte administrateur de Flavien.

double? _nombre(Object? v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}');
int _entier(Object? v) => _nombre(v)?.round() ?? 0;
DateTime? _date(Object? v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

// =============================================================================
// Les réglages
// =============================================================================

/// Les tâches d'IA et leur nom à l'écran, dans l'ordre où on les regarde.
class TachesIa {
  static const libelles = {
    'scan_carte': 'Lire une carte des vins',
    'scan_etiquette_lecture': 'Lire une étiquette',
    'scan_etiquette_description': 'Décrire un vin scanné',
    'vin_depuis_texte': 'Identifier un vin depuis son nom',
    'fiche_texte': 'Fiche d\'un vin saisi hors ligne',
    'question_carte': 'Question sur une carte',
    'chat': 'Sommelier (chat)',
    'synthese_table': 'Synthèse de table',
    'recit': 'Récit d\'un vin',
    'enrichir_fiche': 'Enrichir une fiche',
    'traduire_fiche': 'Traduire une fiche (autre langue)',
    'notes_degustation': 'Notes de dégustation dictées',
    'meuble': 'Meuble de cave (photo)',
    'import_cave': 'Import Excel',
    'valeurs_marche': 'Valeur de marché',
  };

  /// Les familles que les fonctions résolvent au plus récent modèle stable (V2.3 · K8).
  static const familles = {
    'flash': 'Le plus récent Flash',
    'flash-lite': 'Le plus récent Flash-Lite',
    'pro': 'Le plus récent Pro',
  };

  static const reflexions = {
    'minimal': 'minimale',
    'low': 'basse',
    'medium': 'moyenne',
    'high': 'haute',
  };

  static String libelle(String tache) => libelles[tache] ?? tache;

  static String reflexion(Object? niveau) => niveau == null ? 'par défaut' : (reflexions['$niveau'] ?? '$niveau');

  /// « gemini-3.5-flash-lite, réflexion minimale ».
  static String reglage(Object? valeur) {
    if (valeur is! Map) return '—';
    final modele = '${valeur['modele'] ?? '?'}';
    return '${familles[modele] ?? modele}, réflexion ${reflexion(valeur['reflexion'])}';
  }
}

class ReglageCourant {
  final String cle;
  final Object? valeur;
  final DateTime? majLe;
  const ReglageCourant({required this.cle, required this.valeur, this.majLe});
}

class ModeleServi {
  final String modele;
  final int appels;
  const ModeleServi(this.modele, this.appels);
}

class ChangementDeReglage {
  final String cle;
  final Object? avant;
  final Object? apres;
  final DateTime? le;
  final String? par;

  const ChangementDeReglage({required this.cle, this.avant, this.apres, this.le, this.par});

  factory ChangementDeReglage.fromJson(Map<String, dynamic> j) => ChangementDeReglage(
        cle: '${j['cle']}',
        avant: j['avant'],
        apres: j['apres'],
        le: _date(j['le']),
        par: j['par'] as String?,
      );

  /// Ce qui a changé, lisible d'un coup d'œil : « non → oui », « build 74 → 77 »,
  /// « Lire une carte : … → … ».
  String get resume => DescriptionDeReglage.difference(cle, avant, apres);
}

class ReglagesDeLaConsole {
  final Map<String, ReglageCourant> valeurs;
  final List<ModeleServi> modelesServis;
  final List<ChangementDeReglage> journal;

  const ReglagesDeLaConsole({required this.valeurs, required this.modelesServis, required this.journal});

  factory ReglagesDeLaConsole.fromJson(Map<String, dynamic> j) {
    final r = j['reglages'];
    return ReglagesDeLaConsole(
      valeurs: {
        if (r is Map)
          for (final e in r.entries)
            if (e.value is Map)
              '${e.key}': ReglageCourant(
                  cle: '${e.key}', valeur: (e.value as Map)['valeur'], majLe: _date((e.value as Map)['maj_le'])),
      },
      modelesServis: [
        for (final m in (j['modeles_servis'] as List? ?? const []))
          if (m is Map) ModeleServi('${m['modele']}', _entier(m['appels'])),
      ],
      journal: [
        for (final c in (j['journal'] as List? ?? const []))
          if (c is Map) ChangementDeReglage.fromJson(Map<String, dynamic>.from(c)),
      ],
    );
  }

  Object? valeur(String cle) => valeurs[cle]?.valeur;
  bool interrupteur(String cle) => valeur(cle) == true;

  Map<String, Map<String, dynamic>> get modelesIa {
    final v = valeur('modeles_ia');
    return {
      if (v is Map)
        for (final e in v.entries)
          if (e.value is Map) '${e.key}': Map<String, dynamic>.from(e.value as Map),
    };
  }
}

/// Ce qu'un réglage veut dire, et ce qu'un changement a changé.
class DescriptionDeReglage {
  static const libelles = {
    'modeles_ia': 'Modèles d\'IA',
    'scan_etiquette_recherche': 'Recherche Google au scan d\'étiquette',
    'ia_session_obligatoire': 'Session obligatoire pour l\'IA',
    'admin_detail_nominatif': 'Console nominative',
    'version_minimale_test': 'Version minimale',
    'ecpm_eur_estime': 'eCPM estimés',
    'quotas_ia': 'Quotas d\'IA par jour',
  };

  static String libelle(String cle) => libelles[cle] ?? cle;

  static String _ouiNon(Object? v) => v == true ? 'oui' : (v == false ? 'non' : '—');

  static String _euros(Object? v) {
    final n = _nombre(v);
    return n == null ? '—' : '${n.toStringAsFixed(1).replaceAll('.', ',')} €';
  }

  static String difference(String cle, Object? avant, Object? apres) {
    switch (cle) {
      case 'scan_etiquette_recherche':
      case 'ia_session_obligatoire':
      case 'admin_detail_nominatif':
        return '${_ouiNon(avant)} → ${_ouiNon(apres)}';
      case 'version_minimale_test':
        final a = avant is Map ? avant['build'] : null;
        final b = apres is Map ? apres['build'] : null;
        return 'build ${a ?? '—'} → ${b ?? '—'}';
      case 'modeles_ia':
        final a = avant is Map ? avant : const {};
        final b = apres is Map ? apres : const {};
        final changees = <String>[
          for (final t in {...a.keys, ...b.keys})
            if ('${a[t]}' != '${b[t]}')
              '${TachesIa.libelle('$t')} : ${a[t] == null ? '—' : TachesIa.reglage(a[t])} → ${b[t] == null ? '—' : TachesIa.reglage(b[t])}',
        ];
        return changees.isEmpty ? 'aucun changement' : changees.join(' · ');
      case 'ecpm_eur_estime':
      case 'quotas_ia':
        final a = avant is Map ? avant : const {};
        final b = apres is Map ? apres : const {};
        String lire(Object? v) =>
            cle == 'ecpm_eur_estime' ? _euros(v) : (v is Map ? '${v['compte'] ?? '—'}/${v['anonyme'] ?? '—'}' : '—');
        final changees = <String>[
          for (final k in {...a.keys, ...b.keys})
            if ('${a[k]}' != '${b[k]}') '$k ${lire(a[k])} → ${lire(b[k])}',
        ];
        return changees.isEmpty ? 'aucun changement' : changees.join(' · ');
      default:
        return '$avant → $apres';
    }
  }
}

// =============================================================================
// Les retours suivis
// =============================================================================
enum StatutDeRetour {
  aTraiter('a_traiter', 'À traiter', Color(0xFFC62828)),
  enCours('en_cours', 'En cours', Color(0xFFEF6C00)),
  resolu('resolu', 'Résolu', Color(0xFF2E7D32)),
  ecarte('ecarte', 'Écarté', Color(0xFF757575));

  final String code;
  final String libelle;
  final Color couleur;
  const StatutDeRetour(this.code, this.libelle, this.couleur);

  static StatutDeRetour depuis(Object? code) =>
      StatutDeRetour.values.firstWhere((s) => s.code == '$code', orElse: () => StatutDeRetour.aTraiter);

  /// Ce qui reste à faire : à traiter, ou commencé.
  bool get ouvert => this == aTraiter || this == enCours;
}

class RetourSuivi {
  final String id;
  final DateTime? quand;
  final String qui;
  final String? plateforme;
  final String? version;
  final String commentaire;
  final String? capture;
  final bool annotations;
  final StatutDeRetour statut;
  final String? note;
  final DateTime? majLe;

  const RetourSuivi({
    required this.id,
    this.quand,
    required this.qui,
    this.plateforme,
    this.version,
    required this.commentaire,
    this.capture,
    this.annotations = false,
    this.statut = StatutDeRetour.aTraiter,
    this.note,
    this.majLe,
  });

  factory RetourSuivi.fromJson(Map<String, dynamic> j) => RetourSuivi(
        id: '${j['id']}',
        quand: _date(j['quand']),
        qui: (j['qui'] as String?)?.trim().isNotEmpty == true ? j['qui'] as String : 'Anonyme',
        plateforme: j['plateforme'] as String?,
        version: j['version'] as String?,
        commentaire: '${j['commentaire'] ?? ''}'.trim(),
        capture: j['capture'] as String?,
        annotations: j['annotations'] == true,
        statut: StatutDeRetour.depuis(j['statut']),
        note: j['note'] as String?,
        majLe: _date(j['maj_le']),
      );

  RetourSuivi avec({StatutDeRetour? statut, String? note}) => RetourSuivi(
        id: id,
        quand: quand,
        qui: qui,
        plateforme: plateforme,
        version: version,
        commentaire: commentaire,
        capture: capture,
        annotations: annotations,
        statut: statut ?? this.statut,
        note: note ?? this.note,
        majLe: DateTime.now(),
      );
}

// =============================================================================
// L'économie, jour par jour et par modèle
// =============================================================================
class JourEconomique {
  final DateTime jour;
  final double coutEur;
  final int appels;
  final double revenuEur;
  final int impressions;
  final double? carteMoyenEur;
  final double? etiquetteMoyenEur;

  const JourEconomique({
    required this.jour,
    required this.coutEur,
    required this.appels,
    required this.revenuEur,
    required this.impressions,
    this.carteMoyenEur,
    this.etiquetteMoyenEur,
  });

  factory JourEconomique.fromJson(Map<String, dynamic> j) => JourEconomique(
        jour: DateTime.parse('${j['jour']}'),
        coutEur: _nombre(j['cout_eur']) ?? 0,
        appels: _entier(j['appels']),
        revenuEur: _nombre(j['revenu_eur']) ?? 0,
        impressions: _entier(j['impressions']),
        carteMoyenEur: _nombre(j['carte_moyen_eur']),
        etiquetteMoyenEur: _nombre(j['etiquette_moyen_eur']),
      );
}

class CoutParModele {
  final String modele;
  final int appels;
  final double coutEur;
  final double coutMoyenEur;
  final int entreeMoyenne;
  final int sortieMoyenne;

  const CoutParModele({
    required this.modele,
    required this.appels,
    required this.coutEur,
    required this.coutMoyenEur,
    required this.entreeMoyenne,
    required this.sortieMoyenne,
  });

  factory CoutParModele.fromJson(Map<String, dynamic> j) => CoutParModele(
        modele: '${j['modele']}',
        appels: _entier(j['appels']),
        coutEur: _nombre(j['cout_eur']) ?? 0,
        coutMoyenEur: _nombre(j['cout_moyen_eur']) ?? 0,
        entreeMoyenne: _entier(j['entree_moyenne']),
        sortieMoyenne: _entier(j['sortie_moyenne']),
      );
}

class DetailEconomique {
  final List<JourEconomique> parJour;
  final List<CoutParModele> parModele;
  final int recherchesDuMois;
  final int franchiseMensuelle;

  const DetailEconomique({
    required this.parJour,
    required this.parModele,
    required this.recherchesDuMois,
    required this.franchiseMensuelle,
  });

  factory DetailEconomique.fromJson(Map<String, dynamic> j) => DetailEconomique(
        parJour: [
          for (final d in (j['par_jour'] as List? ?? const []))
            if (d is Map) JourEconomique.fromJson(Map<String, dynamic>.from(d)),
        ],
        parModele: [
          for (final m in (j['par_modele'] as List? ?? const []))
            if (m is Map) CoutParModele.fromJson(Map<String, dynamic>.from(m)),
        ],
        recherchesDuMois: _entier(j['recherches_du_mois']),
        franchiseMensuelle: _entier(j['franchise_mensuelle']) == 0 ? 5000 : _entier(j['franchise_mensuelle']),
      );

  /// L'objectif fixé en V2.3 : moins de 0,8 c€ par page de carte.
  static const objectifCarteEur = 0.008;
}

// =============================================================================
// Les erreurs et les versions
// =============================================================================
class JourDErreurs {
  final DateTime jour;
  final int erreurs;
  final int alertes;
  const JourDErreurs(this.jour, this.erreurs, this.alertes);

  factory JourDErreurs.fromJson(Map<String, dynamic> j) =>
      JourDErreurs(DateTime.parse('${j['jour']}'), _entier(j['erreurs']), _entier(j['alertes']));
}

class Occurrence {
  final DateTime? quand;
  final String? qui;
  final String? plateforme;
  final String? version;
  final String message;
  final String? details;

  const Occurrence({this.quand, this.qui, this.plateforme, this.version, required this.message, this.details});

  factory Occurrence.fromJson(Map<String, dynamic> j) => Occurrence(
        quand: _date(j['quand']),
        qui: j['qui'] as String?,
        plateforme: j['plateforme'] as String?,
        version: j['version'] as String?,
        message: '${j['message'] ?? ''}',
        details: j['details'] as String?,
      );
}

class VersionInstallee {
  final String plateforme;
  final String version;
  final int personnes;
  final DateTime? derniere;
  final String qui;

  const VersionInstallee({
    required this.plateforme,
    required this.version,
    required this.personnes,
    this.derniere,
    required this.qui,
  });

  factory VersionInstallee.fromJson(Map<String, dynamic> j) => VersionInstallee(
        plateforme: '${j['plateforme'] ?? '?'}',
        version: '${j['version'] ?? '?'}',
        personnes: _entier(j['personnes']),
        derniere: _date(j['derniere']),
        qui: '${j['qui'] ?? ''}',
      );

  /// Le numéro de build (« 1.6.0+76 » → 76), pour repérer qui est en retard.
  int? get build {
    final plus = version.lastIndexOf('+');
    if (plus < 0) return null;
    return int.tryParse(version.substring(plus + 1).split(RegExp(r'[^0-9]')).first);
  }
}
