import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// D'où vient une conviction du modèle de goût.
///
/// Sans registre, le profil est une affirmation sans preuve : il dit « vous aimez la
/// minéralité » et personne, pas même nous, ne peut dire pourquoi. C'est la condition de
/// la lisibilité — un modèle qu'on ne peut pas interroger n'est pas compréhensible, il
/// est seulement affiché.
class TasteEvidenceEntry {
  final DateTime quand;

  /// Ce qui a produit la conviction : 'degustation', 'gorgee', 'rachat', 'cave'.
  final String source;

  /// Ce qui a bougé : un axe ('acidity'), une région ('region:Jura'), un cépage
  /// ('cepage:Syrah').
  final String cible;

  /// L'effet, en clair et lisible par la personne concernée.
  final String effet;

  /// Le vin qui en est à l'origine, quand il y en a un.
  final String? vin;

  /// La dégustation d'origine, quand la contribution en vient d'une.
  ///
  /// C'est ce qui permet de retrouver toutes les traces d'une dégustation qu'on
  /// supprime — sans lui, on saurait qu'un axe a bougé mais pas à cause de quoi.
  final String? tastingId;

  /// Valeur de l'axe AVANT et APRÈS la contribution, quand il s'agit d'un axe.
  ///
  /// Ces deux nombres sont ce qui rend une suppression honnête possible. La moyenne
  /// exponentielle est **irréversible** : connaître 0,83 ne dit pas d'où l'on venait, et
  /// aucun calcul ne le retrouve. Les noter au moment du changement est le seul moyen de
  /// pouvoir revenir en arrière — et seulement si rien n'a bougé l'axe depuis.
  final double? avant;
  final double? apres;

  const TasteEvidenceEntry({
    required this.quand,
    required this.source,
    required this.cible,
    required this.effet,
    this.vin,
    this.tastingId,
    this.avant,
    this.apres,
  });

  Map<String, dynamic> toJson() => {
        'quand': quand.toIso8601String(),
        'source': source,
        'cible': cible,
        'effet': effet,
        if (vin != null) 'vin': vin,
        if (tastingId != null) 'tasting_id': tastingId,
        if (avant != null) 'avant': avant,
        if (apres != null) 'apres': apres,
      };

  factory TasteEvidenceEntry.fromJson(Map<String, dynamic> j) => TasteEvidenceEntry(
        quand: DateTime.tryParse(j['quand']?.toString() ?? '') ?? DateTime.now(),
        source: j['source']?.toString() ?? 'inconnu',
        cible: j['cible']?.toString() ?? '',
        effet: j['effet']?.toString() ?? '',
        vin: j['vin']?.toString(),
        tastingId: j['tasting_id']?.toString(),
        avant: (j['avant'] as num?)?.toDouble(),
        apres: (j['apres'] as num?)?.toDouble(),
      );
}

/// Registre des contributions au profil de goût.
///
/// **Pourquoi local et non en base**, contrairement à ce que prévoyait le plan : le
/// profil de goût lui-même est purement local (`SharedPreferences`), aucune ligne n'en
/// part vers Supabase. Écrire ses preuves côté serveur produirait une traçabilité pour
/// un profil que le serveur ne détient pas — les deux doivent déménager ensemble, au
/// moment où les comptes anonymes rendront la synchronisation utile.
///
/// Le registre est **borné** : une cave active produit plusieurs entrées par
/// dégustation, et un journal sans limite finirait par peser sur le démarrage de l'app.
class TasteEvidenceLedger {
  static const String _cle = 'chatmelier_taste_evidence_v1';

  /// Au-delà, les plus anciennes entrées sont oubliées. Deux cents couvre largement ce
  /// qu'on peut vouloir expliquer — « pourquoi ce profil » regarde le récent — sans
  /// laisser le stockage croître indéfiniment.
  static const int tailleMax = 200;

  final SharedPreferences _prefs;
  TasteEvidenceLedger(this._prefs);

  static Future<TasteEvidenceLedger> ouvrir() async =>
      TasteEvidenceLedger(await SharedPreferences.getInstance());

  List<TasteEvidenceEntry> lire() {
    final brut = _prefs.getString(_cle);
    if (brut == null || brut.isEmpty) return const [];
    try {
      final liste = jsonDecode(brut);
      if (liste is! List) return const [];
      return liste
          .whereType<Map<String, dynamic>>()
          .map(TasteEvidenceEntry.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> ajouter(List<TasteEvidenceEntry> entrees) async {
    if (entrees.isEmpty) return;
    // Les plus récentes d'abord : c'est l'ordre dans lequel on les lit.
    final toutes = [...entrees, ...lire()].take(tailleMax).toList();
    await _prefs.setString(
      _cle,
      jsonEncode(toutes.map((e) => e.toJson()).toList()),
    );
  }

  /// Ce qui explique une cible précise — « pourquoi pensez-vous que j'aime le Jura ? ».
  List<TasteEvidenceEntry> pour(String cible) =>
      lire().where((e) => e.cible == cible).toList();

  /// Tout ce qu'une dégustation a changé.
  List<TasteEvidenceEntry> pourDegustation(String tastingId) =>
      lire().where((e) => e.tastingId == tastingId).toList();

  /// La contribution la plus récente sur une cible, s'il y en a une.
  ///
  /// Sert à savoir si une annulation est exacte : ne peut être défait que ce que rien
  /// n'a modifié depuis.
  TasteEvidenceEntry? derniereSur(String cible) {
    for (final e in lire()) {
      if (e.cible == cible) return e; // la liste est du plus récent au plus ancien
    }
    return null;
  }

  Future<void> retirer(String tastingId) async {
    final restantes =
        lire().where((e) => e.tastingId != tastingId).toList();
    await _prefs.setString(
      _cle,
      jsonEncode(restantes.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> vider() => _prefs.remove(_cle);
}
