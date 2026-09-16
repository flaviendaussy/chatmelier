import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'taste_profile.dart';

/// L'état d'un palais à un mois donné.
class TasteProfileSnapshot {
  /// Le mois décrit, au format `AAAA-MM`. C'est aussi la clé d'unicité.
  final String mois;
  final Map<String, double> axes;
  final Map<String, int> observations;
  final double confiance;
  final int degustations;

  const TasteProfileSnapshot({
    required this.mois,
    required this.axes,
    required this.observations,
    required this.confiance,
    required this.degustations,
  });

  Map<String, dynamic> toJson() => {
        'mois': mois,
        'axes': axes,
        'observations': observations,
        'confiance': confiance,
        'degustations': degustations,
      };

  factory TasteProfileSnapshot.fromJson(Map<String, dynamic> j) => TasteProfileSnapshot(
        mois: j['mois']?.toString() ?? '',
        axes: (j['axes'] as Map?)?.map(
                (k, v) => MapEntry(k.toString(), (v as num?)?.toDouble() ?? 0)) ??
            const {},
        observations: (j['observations'] as Map?)
                ?.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0)) ??
            const {},
        confiance: (j['confiance'] as num?)?.toDouble() ?? 0,
        degustations: (j['degustations'] as num?)?.toInt() ?? 0,
      );
}

/// Instantanés mensuels du profil — la condition pour parler de **dérive**.
///
/// Un palais change. La moyenne exponentielle du modèle le suit désormais (α = 0,25,
/// soit huit dégustations pour basculer), mais elle ne garde AUCUNE mémoire de ce qui
/// précède : elle montre où vous en êtes, jamais d'où vous venez. Or « votre goût s'est
/// déplacé vers la tension cette année » est précisément ce qu'on ne peut dire qu'avec
/// un historique.
///
/// C'est la fonctionnalité qui doit être posée **le plus tôt possible et affichée le
/// plus tard** : elle ne montre rien avant d'avoir accumulé plusieurs mois. La poser
/// aujourd'hui, c'est décider que dans un an on aura quelque chose à montrer.
///
/// Local, comme le profil et le registre qu'il accompagne — les trois déménageront
/// ensemble quand les comptes anonymes rendront la synchronisation utile.
class TasteProfileHistory {
  static const String _cle = 'chatmelier_taste_history_v1';

  /// Trois ans de mémoire. Au-delà, la comparaison n'apprend plus grand-chose et le
  /// stockage local n'a pas à grossir indéfiniment.
  static const int moisConserves = 36;

  final SharedPreferences _prefs;
  TasteProfileHistory(this._prefs);

  static Future<TasteProfileHistory> ouvrir() async =>
      TasteProfileHistory(await SharedPreferences.getInstance());

  static String moisDe(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  /// Du plus ancien au plus récent — c'est l'ordre dans lequel on lit une évolution.
  List<TasteProfileSnapshot> lire() {
    final brut = _prefs.getString(_cle);
    if (brut == null || brut.isEmpty) return const [];
    try {
      final liste = jsonDecode(brut);
      if (liste is! List) return const [];
      final snaps = liste
          .whereType<Map<String, dynamic>>()
          .map(TasteProfileSnapshot.fromJson)
          .toList();
      snaps.sort((a, b) => a.mois.compareTo(b.mois));
      return snaps;
    } catch (_) {
      return const [];
    }
  }

  /// Fige l'état du mois courant.
  ///
  /// **Idempotent par mois** : rappeler la méthode remplace l'instantané du mois au lieu
  /// d'en empiler un second. C'est indispensable, puisque la capture se déclenche à
  /// chaque ouverture de l'écran de profil — et c'est le bon comportement : ce qui
  /// intéresse, c'est où en était le palais à la fin du mois, pas à chaque consultation.
  Future<void> capturer(TasteProfile profile, {DateTime? maintenant}) async {
    final mois = moisDe(maintenant ?? DateTime.now());

    final axes = <String, double>{};
    for (final k in TasteProfile.axisKeys) {
      final v = profile.valeurAxe(k);
      if (v != null) axes[k] = v;
    }

    // Un profil encore vide n'a rien à figer : on ne veut pas d'une année de zéros
    // devant la première vraie mesure.
    if (axes.isEmpty && profile.questionnairesCompleted == 0) return;

    final snap = TasteProfileSnapshot(
      mois: mois,
      axes: axes,
      observations: Map<String, int>.from(profile.axisObservations),
      confiance: profile.overallConfidence,
      degustations: profile.questionnairesCompleted,
    );

    final tous = lire().where((s) => s.mois != mois).toList()..add(snap);
    tous.sort((a, b) => a.mois.compareTo(b.mois));
    final conserves =
        tous.length > moisConserves ? tous.sublist(tous.length - moisConserves) : tous;

    await _prefs.setString(
      _cle,
      jsonEncode(conserves.map((s) => s.toJson()).toList()),
    );
  }

  /// De combien un axe a bougé depuis le premier instantané disponible.
  ///
  /// Nul tant qu'il n'y a pas deux mois distincts à comparer : une dérive sur un seul
  /// point n'existe pas.
  double? derive(String axe) {
    final snaps = lire().where((s) => s.axes.containsKey(axe)).toList();
    if (snaps.length < 2) return null;
    return snaps.last.axes[axe]! - snaps.first.axes[axe]!;
  }

  Future<void> vider() => _prefs.remove(_cle);
}
