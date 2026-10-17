import '../../../shared/utils/sans_accents.dart';
import '../../cellar/domain/wine.dart';
import 'scan_result.dart';

/// Un vin que l'étiquette ne suffit pas à trouver, cherché sur le web (17/10).
///
/// Le 16/10, deux vins scannés par Flavien sont restés presque vides (« La Rosa Mayor »
/// 2019 : ni région, ni appellation, ni cépages) : « pourquoi est-ce qu'on ne trouve pas ce
/// vin ? quand je vais sur Google, je le trouve !! ». La lecture de l'étiquette ne savait que
/// ce que le modèle connaissait déjà. Quand la fiche reste incomplète, l'app cherche le vin
/// sur le web (`vin_depuis_texte`, avec la recherche Google) à partir de ce que l'étiquette
/// dit, et ne complète que ce qui manque.
class CompletionParLeWeb {
  /// D'où vient le vin (une appellation ou une région) et ce qu'il est (des cépages et une
  /// description) : sans l'un ou l'autre, la fiche n'a pas trouvé le vin. Encore faut-il que
  /// l'étiquette donne de quoi chercher : « Gran Reserva » seul ne désigne aucun vin.
  static bool aCompleter(ScanResult r) {
    if (_motsQuiComptent('${r.name} ${r.producer ?? ''} ${r.cuveeParcel ?? ''}').isEmpty) return false;
    final lieu = _rempli(r.appellation) || _rempli(r.region);
    final fiche = r.grapes.isNotEmpty && _rempli(r.tastingNotes);
    return !lieu || !fiche;
  }

  /// Ce qu'on cherche : ce que l'étiquette a lu (ou ce que la personne a corrigé), sans
  /// répétition et sans rien de deviné. « La Rosa Mayor 2019, Spain, red wine ». La couleur
  /// lève l'ambiguïté d'un nom court : « Menudo 2021 » seul est aussi un plat et un groupe.
  static String requete({
    required String nom,
    String? producteur,
    String? cuvee,
    int? millesime,
    String? appellation,
    String? region,
    String? pays,
    String? type,
  }) {
    final vin = <String>[];
    final origine = <String>[];
    bool dejaDit(String t) => [...vin, ...origine].any((m) => m.toLowerCase().contains(t.toLowerCase()));
    void ajouter(List<String> ou, String? morceau) {
      final t = (morceau ?? '').trim();
      if (t.isNotEmpty && !dejaDit(t)) ou.add(t);
    }

    ajouter(vin, producteur);
    ajouter(vin, nom);
    ajouter(vin, cuvee);
    if (millesime != null) vin.add('$millesime');
    ajouter(origine, appellation);
    ajouter(origine, region);
    ajouter(origine, pays);
    final nature = _natures[(type ?? '').trim().toLowerCase()];
    return [vin.join(' '), ...origine, if (nature != null) nature].where((m) => m.isNotEmpty).join(', ');
  }

  /// La nature du vin, en anglais comme la consigne de `vin_depuis_texte`.
  static const _natures = {
    'red': 'red wine', 'white': 'white wine', 'rosé': 'rosé wine', 'rose': 'rosé wine',
    'sparkling': 'sparkling wine', 'dessert': 'sweet wine', 'fortified': 'fortified wine', 'orange': 'orange wine',
  };

  /// Le web a-t-il répondu pour ce vin-là ? Au moins un mot qui compte (le nom, le domaine)
  /// en commun avec l'étiquette : un vin au nom voisin trouvé à sa place serait une
  /// hallucination présentée comme un fait.
  static bool memeVin(ScanResult lu, ScanResult web) {
    final etiquette = _motsQuiComptent('${lu.name} ${lu.producer ?? ''} ${lu.cuveeParcel ?? ''}');
    final trouve = _motsQuiComptent('${web.name} ${web.producer ?? ''} ${web.cuveeParcel ?? ''}');
    return etiquette.intersection(trouve).isNotEmpty;
  }

  /// La lecture complétée par le web. Ce que l'étiquette a lu reste tel quel ; le web ne
  /// remplit que ce qui manque. Le millésime et le degré ne viennent que de l'étiquette :
  /// ceux d'une autre année seraient faux pour cette bouteille. Une description sans source
  /// (le vin n'était ni au catalogue ni vérifié en ligne) cède la place à celle que le web
  /// confirme.
  static ScanResult fusionner(ScanResult lu, ScanResult web, {List<String> sources = const []}) {
    final sourcee = lu.fromCache || lu.sourcesVerified.isNotEmpty;
    // Un domaine identique au nom n'a pas été lu : le modèle a recopié le nom faute de voir
    // le domaine, souvent au dos (« La Rosa Mayor », de Bodegas Valtravieso, 16/10).
    final domaineLu = _memeTexte(lu.producer, lu.name) ? null : lu.producer;
    bool prendre(bool luVide, bool webPlein) => webPlein && (luVide || !sourcee);
    String? texte(String? l, String? w) => _rempli(l) ? l : (_rempli(w) ? w!.trim() : l);

    final fenetreWeb = web.idealDrinkingStart != null || web.peakDrinkingStart != null;
    final fenetreLue = lu.idealDrinkingStart != null || lu.peakDrinkingStart != null;
    final fenetre = prendre(!fenetreLue, fenetreWeb) ? web : lu;
    return ScanResult(
      name: lu.name,
      producer: texte(domaineLu, web.producer) ?? lu.producer,
      cuveeParcel: texte(lu.cuveeParcel, web.cuveeParcel),
      vintage: lu.vintage,
      wineType: lu.wineType.trim().isNotEmpty ? lu.wineType : web.wineType,
      country: texte(lu.country, web.country) ?? '',
      region: texte(lu.region, web.region) ?? '',
      subRegion: texte(lu.subRegion, web.subRegion),
      appellation: texte(lu.appellation, web.appellation),
      classification: texte(lu.classification, web.classification),
      alcoholPct: lu.alcoholPct,
      grapes: prendre(lu.grapes.isEmpty, web.grapes.isNotEmpty) ? web.grapes : lu.grapes,
      tastingNotes: prendre(!_rempli(lu.tastingNotes), _rempli(web.tastingNotes)) ? web.tastingNotes : lu.tastingNotes,
      idealDrinkingStart: fenetre.idealDrinkingStart,
      idealDrinkingEnd: fenetre.idealDrinkingEnd,
      peakDrinkingStart: fenetre.peakDrinkingStart,
      peakDrinkingEnd: fenetre.peakDrinkingEnd,
      foodPairings: prendre(lu.foodPairings.isEmpty, web.foodPairings.isNotEmpty) ? web.foodPairings : lu.foodPairings,
      summary: prendre(!_rempli(lu.summary), _rempli(web.summary)) ? web.summary : lu.summary,
      criticScores: lu.criticScores,
      estimatedMarketValue: lu.estimatedMarketValue,
      estimatedValueCurrency: lu.estimatedValueCurrency,
      sourcesVerified: {...lu.sourcesVerified, ...sources}.toList(),
      fromCache: lu.fromCache,
      detectedQuantity: lu.detectedQuantity,
      packagingType: lu.packagingType,
    );
  }

  /// Ce que le web a ajouté à la fiche, pour le dire à l'écran et au journal.
  static List<String> champsCompletes(ScanResult avant, ScanResult apres) => [
        if (!_rempli(avant.appellation) && _rempli(apres.appellation)) 'appellation',
        if (!_rempli(avant.region) && _rempli(apres.region)) 'region',
        if (!_rempli(avant.country) && _rempli(apres.country)) 'pays',
        if (!_rempli(avant.producer) && _rempli(apres.producer)) 'domaine',
        if (!_listeEgale(avant.grapes, apres.grapes)) 'cepages',
        if (avant.tastingNotes != apres.tastingNotes) 'notes',
        if (avant.idealDrinkingStart != apres.idealDrinkingStart || avant.peakDrinkingStart != apres.peakDrinkingStart)
          'garde',
      ];

  static bool _listeEgale(List<Grape> a, List<Grape> b) =>
      a.length == b.length && [for (var i = 0; i < a.length; i++) a[i].name == b[i].name].every((x) => x);

  /// Des mots qui désignent tout vin, et ne disent pas lequel.
  static const _motsCommuns = {
    'vino', 'vin', 'wine', 'vinho', 'wein', 'domaine', 'chateau', 'bodega', 'bodegas', 'cave', 'caves', 'clos',
    'tinto', 'blanco', 'rosado', 'rouge', 'blanc', 'rose', 'rosso', 'bianco', 'red', 'white', 'reserva',
    'reserve', 'gran', 'grand', 'crianza', 'cuvee', 'vieilles', 'vignes', 'estate', 'winery', 'cellars',
    'tenuta', 'cantina', 'quinta', 'weingut', 'de', 'del', 'la', 'le', 'les', 'el', 'los', 'las', 'di',
  };

  static Set<String> _motsQuiComptent(String texte) => sansAccents(texte)
      .split(RegExp(r'[^a-z0-9]+'))
      .where((m) => m.length >= 3 && !_motsCommuns.contains(m) && int.tryParse(m) == null)
      .toSet();

  static bool _rempli(String? v) => v != null && v.trim().isNotEmpty;

  static bool _memeTexte(String? a, String? b) =>
      _rempli(a) && _rempli(b) && sansAccents(a!.trim()) == sansAccents(b!.trim());
}
