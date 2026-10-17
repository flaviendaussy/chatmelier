import 'dart:convert';

import '../../../shared/utils/sans_accents.dart';
import '../../cellar/domain/bottle.dart';

/// Les bouteilles de la cave que le sommelier nomme sans leur carte (V2.5 · F5).
///
/// 13/10, Flavien : « tu me parles de "cette rioja", "ce bourgogne aligoté". il manque la
/// carte de ces bouteilles afin de pouvoir cliquer dessus et arriver sur les détails du
/// vin ». Le modèle ne pose pas toujours la carte qu'on lui demande. On la pose après lui,
/// mais seulement quand le nom ne laisse aucun doute : une cave à deux riojas n'a pas de
/// carte pour « cette rioja » — une carte vers le mauvais vin serait pire qu'aucune.
class BouteillesCitees {
  /// Au-delà, la réponse parle de la cave en général plus que de bouteilles précises.
  static const maximum = 3;

  /// Des mots qui désignent tout vin, et ne disent pas lequel.
  static const _motsCommuns = {
    'vin', 'vino', 'wine', 'domaine', 'chateau', 'bodega', 'bodegas', 'cave', 'caves', 'clos', 'maison',
    'cuvee', 'reserve', 'reserva', 'gran', 'grand', 'crianza', 'rouge', 'blanc', 'rose', 'red', 'white',
    'tinto', 'blanco', 'brut', 'vieilles', 'vignes', 'estate', 'winery', 'tenuta', 'cantina', 'quinta',
    'weingut', 'de', 'du', 'des', 'la', 'le', 'les', 'el', 'los', 'di', 'del', 'et', 'and', 'cru', 'premier',
  };

  /// Les titres qu'on omet en parlant d'un domaine : « Ponsot » pour « Domaine Ponsot ».
  static const _titres = {
    'domaine', 'domaines', 'chateau', 'bodega', 'bodegas', 'maison', 'weingut', 'tenuta', 'cantina',
    'quinta', 'cave', 'caves', 'famille', 'vignobles',
  };

  static String _norme(String texte) =>
      ' ${sansAccents(texte).replaceAll(RegExp(r"[^a-z0-9]+"), ' ').trim()} ';

  /// Les noms par lesquels on peut désigner ce vin : son nom, son domaine, son
  /// appellation — chacun seulement s'il porte un mot qui compte.
  static Set<String> _noms(Bottle b) {
    final w = b.wine!;
    final sortie = <String>{};
    void ajouter(String? brut) {
      final n = _norme(brut ?? '').trim();
      if (n.isEmpty) return;
      final mots = n.split(' ');
      if (!mots.any((m) => m.length >= 4 && !_motsCommuns.contains(m) && int.tryParse(m) == null)) return;
      sortie.add(n);
    }

    ajouter(w.name);
    ajouter(w.producer);
    final domaine = _norme(w.producer ?? '').trim().split(' ');
    var i = 0;
    while (i < domaine.length && _titres.contains(domaine[i])) {
      i++;
    }
    if (i > 0 && i < domaine.length) ajouter(domaine.sublist(i).join(' '));
    ajouter(w.appellation);
    return sortie;
  }

  /// Les bouteilles que [reponse] nomme sans ambiguïté, sauf celles qui ont déjà leur carte.
  static List<Bottle> dans(String reponse, List<Bottle> cave) {
    final texte = _norme(reponse);
    final dejaCartees = {for (final m in RegExp(r'"id"\s*:\s*"([^"]+)"').allMatches(reponse)) m.group(1)!};
    final enCave = [for (final b in cave) if (b.wine != null && b.quantity > 0) b];

    // Un nom ne désigne un vin que s'il n'en désigne qu'un : deux bouteilles du même vin
    // comptent pour un.
    final parNom = <String, Set<String>>{};
    final bouteilleDuVin = <String, Bottle>{};
    for (final b in enCave) {
      final vin = b.wineId.isNotEmpty ? b.wineId : b.id;
      bouteilleDuVin.putIfAbsent(vin, () => b);
      for (final n in _noms(b)) {
        parNom.putIfAbsent(n, () => {}).add(vin);
      }
    }
    // Dans l'ordre où la réponse les nomme.
    final premiereMention = <String, int>{};
    for (final MapEntry(key: nom, value: vins) in parNom.entries) {
      if (vins.length != 1) continue;
      final ou = texte.indexOf(' $nom ');
      if (ou < 0) continue;
      final avant = premiereMention[vins.single];
      if (avant == null || ou < avant) premiereMention[vins.single] = ou;
    }
    final cites = premiereMention.keys.toList()..sort((a, b) => premiereMention[a]!.compareTo(premiereMention[b]!));
    return [
      for (final vin in cites)
        if (!dejaCartees.contains(bouteilleDuVin[vin]!.id)) bouteilleDuVin[vin]!,
    ].take(maximum).toList();
  }

  /// La réponse, suivie de la carte de chaque bouteille nommée qui n'en avait pas.
  static String avecLeursCartes(String reponse, List<Bottle> cave) {
    final cites = dans(reponse, cave);
    if (cites.isEmpty) return reponse;
    final cartes = [
      for (final b in cites)
        '[WINE_CARD: ${jsonEncode({
          'id': b.id,
          'name': b.wine!.name,
          if (b.wine!.vintage != null) 'vintage': b.wine!.vintage,
          if ((b.wine!.producer ?? '').isNotEmpty) 'producer': b.wine!.producer,
          if (b.wine!.region.isNotEmpty) 'region': b.wine!.region,
          if ((b.wine!.appellation ?? '').isNotEmpty) 'appellation': b.wine!.appellation,
          'wine_type': b.wine!.type,
          if ((b.rack ?? '').isNotEmpty) 'location': b.rack,
          'citee': true,
        })}]',
    ];
    return '${reponse.trimRight()}\n\n${cartes.join('\n')}';
  }
}
