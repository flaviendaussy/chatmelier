/// Le type d'un vin : ce qui est enregistré prime sur ce que suggère son nom (V2.5 · Q4).
///
/// Jusqu'au 18/10, le type enregistré cédait à une sous-chaîne du nom, du domaine ou de
/// l'appellation : « rum » dans Valtellina Superiore « Grumello » ou dans le Fronton
/// « Brumaire » en faisait du rhum, « porto » dans l'AOC Corse Porto-Vecchio et « maury »
/// dans « Clos du Maury » (Côtes du Roussillon Villages) en faisaient des mutés. Un rouge
/// partait dans « Spiritueux », sortait des goûts, et la fiche à modifier enregistrait
/// l'erreur.
///
/// Désormais :
/// - un type de vin enregistré (rouge, blanc, rosé, effervescent, moelleux, orange) reste
///   ce qu'il est, sauf un degré qu'aucun vin n'atteint ;
/// - le rouge mis d'office avant que le scan ne sache lire les spiritueux cède à un nom
///   sans ambiguïté (« Chartreuse Verte », « Tawny Porto »), en mots entiers ;
/// - un vin doux naturel se reconnaît à son appellation, jamais au nom du domaine.
class TypeDeVin {
  TypeDeVin._();

  /// Les types d'un vin tranquille ou effervescent, clés de l'app et libellés qu'un scan
  /// peut rendre tels quels : son nom ne les change jamais.
  static const vins = {
    'red', 'white', 'rose', 'rosé', 'sparkling', 'dessert', 'orange', 'sweet',
    'rouge', 'blanc', 'effervescent', 'moelleux', 'liquoreux',
  };

  static bool estUnVin(String type) => vins.contains(type.toLowerCase().trim());

  /// Le type à afficher et à compter, à partir de ce qui est enregistré.
  static String resoudre({
    String? stocke,
    required String nom,
    String? producteur,
    String? appellation,
    double? alcool,
  }) {
    final texte = _texte(nom, producteur, appellation);
    final enregistre = stocke?.trim() ?? '';
    if (enregistre.isEmpty) return spiritueuxNomme(texte) ?? 'red';
    if (estUnVin(enregistre)) {
      // Aucun vin n'atteint 25 % : l'étiquette lue l'emporte sur le type.
      if (alcool != null && alcool >= 25) return spiritueuxNomme(texte) ?? 'spirit';
      if (enregistre.toLowerCase() == 'red') {
        final sansAmbiguite = spiritueuxNomme(texte, sansAmbiguite: true);
        if (sansAmbiguite != null) return sansAmbiguite;
      }
      return enregistre;
    }
    // Un spiritueux, une liqueur ou un muté : le nom en précise la famille (un gin rangé
    // parmi les mutés redevient un gin), sans jamais faire d'un vin un spiritueux.
    return spiritueuxNomme(texte) ?? enregistre;
  }

  /// Le spiritueux, la liqueur ou le muté que le nom désigne, en mots entiers, ou nul.
  ///
  /// [sansAmbiguite] écarte les mots qui sont aussi des lieux de vins tranquilles
  /// (Cognac, Jerez, Marsala, Banyuls…) : seul un nom qui ne peut être que celui d'un
  /// spiritueux corrige un type déjà enregistré.
  static String? spiritueuxNomme(String texte, {bool sansAmbiguite = false}) {
    final t = texte.toLowerCase();
    for (final (type, mots) in _familles) {
      for (final mot in mots) {
        if (sansAmbiguite && _ambigus.contains(mot)) continue;
        if (!_contient(t, mot)) continue;
        final exclusions = _exclusions[mot];
        if (exclusions != null && exclusions.any(t.contains)) continue;
        return type;
      }
    }
    return null;
  }

  /// Une appellation de vin muté (vin doux naturel, porto, xérès, madère, marsala) :
  /// rouge ou blanc, le vin est muté. « Maury sec » est un rouge sec.
  static bool appellationMutee(String? appellation) {
    final a = (appellation ?? '').toLowerCase().trim();
    if (a.isEmpty) return false;
    if (a.contains('vin doux naturel') || _contient(a, 'vdn')) return true;
    if (a.startsWith('maury')) return !_contient(a, 'sec');
    const mutes = ['banyuls', 'rivesaltes', 'muscat de rivesaltes', 'porto', 'port', 'xérès', 'xeres', 'jerez', 'sherry', 'madeira', 'madère', 'marsala'];
    return mutes.any((m) => a == m || a.startsWith('$m ') || a.startsWith('$m-'));
  }

  static String _texte(String nom, String? producteur, String? appellation) =>
      '$nom ${producteur ?? ''} ${appellation ?? ''}'.toLowerCase();

  /// Un mot entier : ni lettre ni chiffre de part et d'autre, accents compris.
  static bool _contient(String texte, String mot) =>
      RegExp('(?<![\\p{L}\\p{N}])${RegExp.escape(mot)}(?![\\p{L}\\p{N}])', unicode: true).hasMatch(texte);

  /// Dans l'ordre : « vin de liqueur » (Pineau, Floc, Macvin) est un muté avant d'être
  /// une liqueur.
  static const _familles = <(String, List<String>)>[
    ('fortified', ['vin de liqueur', 'pineau des charentes', 'floc de gascogne', 'macvin']),
    ('liqueur', [
      'italicus', 'rosolio', 'bénédictine', 'benedictine', 'chartreuse', 'cointreau',
      'grand marnier', 'amaretto', 'disaronno', 'kahlúa', 'kahlua', 'limoncello', 'sambuca',
      'chambord', 'pimm', 'fleur de lavande', 'liqueur', 'crème de', 'creme de',
    ]),
    ('gin', ['gin']),
    ('vodka', ['vodka']),
    ('whisky', ['whisky', 'whiskey', 'bourbon', 'scotch']),
    ('rhum', ['rhum', 'rum']),
    ('cognac', ['cognac', 'armagnac', 'calvados', 'brandy']),
    ('tequila', ['tequila', 'mezcal']),
    ('grappa', ['grappa']),
    ('spirit', ['pisco', 'aguardente', 'eau-de-vie', 'eau de vie', 'pastis', 'ricard', 'absinthe']),
    ('fortified', [
      'porto', 'port wine', 'sherry', 'xérès', 'xeres', 'jerez', 'madère', 'madeira',
      'marsala', 'vermouth', 'vin doux naturel', 'banyuls', 'maury', 'rivesaltes',
    ]),
  ];

  /// Des lieux, ou des noms que portent aussi des vins tranquilles.
  static const _ambigus = {
    'cognac', 'armagnac', 'calvados', 'brandy', 'jerez', 'marsala', 'banyuls', 'maury',
    'rivesaltes', 'chambord', 'fleur de lavande', 'aguardente',
  };

  /// Des vins tranquilles qui portent le mot.
  static const _exclusions = {
    'porto': ['porto-vecchio', 'porto vecchio'],
    'chartreuse': ['chartreuse de valbonne', 'la chartreuse'],
    'maury': ['maury sec', 'clos du maury'],
  };
}
