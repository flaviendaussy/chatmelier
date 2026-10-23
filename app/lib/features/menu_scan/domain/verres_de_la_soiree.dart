import 'menu_wine.dart';

/// Un verre commandé sur la carte, et ce qu'il est devenu : à déguster, commencé (sa
/// dégustation est au journal), noté.
///
/// Le 22/10 au Vagabond, la carte scannée savait tout des onze verres commandés — nom,
/// domaine, millésime, cépages, lieu — et il a fallu photographier chaque étiquette pour les
/// déguster (Flavien : « je veux sélectionner les vins qui m'intéressent, et les déguster »).
class VerreDeLaSoiree {
  /// L'identifiant du vin sur la carte (`MenuWine.id`).
  final String id;
  final String nom;
  final String? producteur;
  final int? millesime;

  /// `red`, `white`, `rose`, `sparkling`… comme sur la carte.
  final String couleur;
  final String? region;
  final String? pays;
  final List<String> cepages;

  /// La dégustation écrite au journal pour ce verre, dès qu'on l'a commencé : la reprendre
  /// la complète au lieu d'en écrire une seconde.
  final String? tastingId;

  /// Les amis qui ont l'app ont reçu ce verre à noter.
  final bool invites;
  final double? note;
  final String? defaut;
  final bool termine;

  const VerreDeLaSoiree({
    required this.id,
    required this.nom,
    this.producteur,
    this.millesime,
    required this.couleur,
    this.region,
    this.pays,
    this.cepages = const [],
    this.tastingId,
    this.invites = false,
    this.note,
    this.defaut,
    this.termine = false,
  });

  factory VerreDeLaSoiree.deLaCarte(MenuWine w) => VerreDeLaSoiree(
        id: w.id,
        nom: w.name,
        producteur: w.producer.trim().isEmpty ? null : w.producer.trim(),
        millesime: w.vintage,
        couleur: w.wineType,
        region: (w.appellation ?? '').trim().isNotEmpty ? w.appellation : w.region,
        pays: w.country,
        cepages: [for (final c in w.grapes) if (c.trim().isNotEmpty) c.trim()],
      );

  /// Commencé : au journal, pas encore noté.
  bool get commence => tastingId != null && !termine;

  VerreDeLaSoiree copyWith({String? tastingId, bool? invites, double? note, String? defaut, bool? termine}) => VerreDeLaSoiree(
        id: id,
        nom: nom,
        producteur: producteur,
        millesime: millesime,
        couleur: couleur,
        region: region,
        pays: pays,
        cepages: cepages,
        tastingId: tastingId ?? this.tastingId,
        invites: invites ?? this.invites,
        note: note ?? this.note,
        defaut: defaut ?? this.defaut,
        termine: termine ?? this.termine,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        if (producteur != null) 'producteur': producteur,
        if (millesime != null) 'millesime': millesime,
        'couleur': couleur,
        if (region != null) 'region': region,
        if (pays != null) 'pays': pays,
        if (cepages.isNotEmpty) 'cepages': cepages,
        if (tastingId != null) 'tasting_id': tastingId,
        if (invites) 'invites': true,
        if (note != null) 'note': note,
        if (defaut != null) 'defaut': defaut,
        if (termine) 'termine': true,
      };

  static VerreDeLaSoiree? fromJson(dynamic j) {
    if (j is! Map || j['id'] == null || j['nom'] == null) return null;
    return VerreDeLaSoiree(
      id: j['id'].toString(),
      nom: j['nom'].toString(),
      producteur: j['producteur']?.toString(),
      millesime: (j['millesime'] as num?)?.toInt(),
      couleur: j['couleur']?.toString() ?? 'red',
      region: j['region']?.toString(),
      pays: j['pays']?.toString(),
      cepages: [for (final c in (j['cepages'] as List? ?? const [])) c.toString()],
      tastingId: j['tasting_id']?.toString(),
      invites: j['invites'] == true,
      note: (j['note'] as num?)?.toDouble(),
      defaut: j['defaut']?.toString(),
      termine: j['termine'] == true,
    );
  }
}

/// Les verres d'une soirée, sur une carte : le lieu, avec qui, et les verres dans l'ordre
/// où on les a choisis.
class SoireeDeVerres {
  final String menuId;

  /// Le lieu de la carte : chaque dégustation le reprend (le 22/10, les lieux devinés
  /// donnaient « Dawson House » et « Moyses Stevens » au lieu du Vagabond).
  final String lieu;

  /// Avec qui, choisi une fois pour la soirée : les noms des convives.
  final List<String> convives;
  final List<VerreDeLaSoiree> verres;

  const SoireeDeVerres({required this.menuId, required this.lieu, this.convives = const [], this.verres = const []});

  bool contient(String idDuVin) => verres.any((v) => v.id == idDuVin);

  int get notes => verres.where((v) => v.termine).length;

  /// Ajouter le verre s'il n'y est pas ; le retirer s'il y est et n'a pas été commencé —
  /// un verre déjà au journal reste dans la liste.
  SoireeDeVerres basculer(MenuWine w) {
    final present = verres.where((v) => v.id == w.id).firstOrNull;
    if (present == null) return _avec([...verres, VerreDeLaSoiree.deLaCarte(w)]);
    if (present.tastingId != null) return this;
    return _avec([for (final v in verres) if (v.id != w.id) v]);
  }

  SoireeDeVerres remplacer(VerreDeLaSoiree verre) => _avec([for (final v in verres) v.id == verre.id ? verre : v]);

  SoireeDeVerres avecConvives(List<String> noms) =>
      SoireeDeVerres(menuId: menuId, lieu: lieu, convives: List.unmodifiable(noms), verres: verres);

  SoireeDeVerres _avec(List<VerreDeLaSoiree> v) =>
      SoireeDeVerres(menuId: menuId, lieu: lieu, convives: convives, verres: List.unmodifiable(v));

  Map<String, dynamic> toJson() => {
        'menu_id': menuId,
        'lieu': lieu,
        'convives': convives,
        'verres': [for (final v in verres) v.toJson()],
      };

  static SoireeDeVerres? fromJson(dynamic j) {
    if (j is! Map || j['menu_id'] == null) return null;
    return SoireeDeVerres(
      menuId: j['menu_id'].toString(),
      lieu: j['lieu']?.toString() ?? '',
      convives: [for (final c in (j['convives'] as List? ?? const [])) c.toString()],
      verres: [
        for (final v in (j['verres'] as List? ?? const []))
          if (VerreDeLaSoiree.fromJson(v) case final verre?) verre,
      ],
    );
  }
}
