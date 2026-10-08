import '../../../shared/utils/langue.dart';
import '../../cellar/domain/wine.dart';

class SommelierStory {
  final String title;
  final String subtitle;
  final String act1Terroir;
  final String act2Vinification;
  final String act3Degustation;
  final int estimatedSeconds;

  const SommelierStory({
    required this.title,
    required this.subtitle,
    required this.act1Terroir,
    required this.act2Vinification,
    required this.act3Degustation,
    this.estimatedSeconds = 45,
  });

  String get fullText => '$act1Terroir\n\n$act2Vinification\n\n$act3Degustation';
}

/// Le récit du sommelier en trois actes : terroir, vinification, dégustation.
///
/// Il ne raconte que ce que la fiche permet de dire. L'ancien récit était figé : tout
/// effervescent naissait « au cœur des terroirs crayeux de Champagne » (un Prosecco
/// aussi), tout rouge était « élevé sous bois » (un Beaujolais aussi), un rosé recevait
/// « fruits noirs et velours », et sans millésime on lisait « millésime les plus beaux
/// millésimes » (29/09).
class SommelierStorytellerEngine {
  /// Génère une capsule audio-sommelier de ~45 secondes.
  static SommelierStory generateStory(Wine wine) {
    final v = _Vin(wine);
    return SommelierStory(
      title: wine.name,
      subtitle: [
        if (v.appellation.isNotEmpty) v.appellation else if (v.region.isNotEmpty) v.region,
        if (wine.vintage != null) '${wine.vintage}',
      ].join(' • '),
      act1Terroir: _terroir(v),
      act2Vinification: _vinification(v),
      act3Degustation: _degustation(v),
      estimatedSeconds: 45,
    );
  }

  static String _terroir(_Vin v) {
    final nom = v.wine.name;
    final millesime = v.wine.vintage == null ? '' : tr(', millésime {vintage}', ', {vintage} vintage', {'vintage': v.wine.vintage});
    // Le lieu en liste (« Margaux, Bordeaux ») : une phrase sur un nom de lieu bute sur
    // ses articles (« de la Vallée du Rhône », « d'Alsace »).
    final lieu = [
      if (v.appellation.isNotEmpty) v.appellation,
      if (v.region.isNotEmpty && !v.appellation.toLowerCase().contains(v.region.toLowerCase())) v.region,
    ].join(', ');
    // « Château Margaux cultive… pour donner naissance à Château Margaux » : on tait le
    // producteur quand il est déjà dans le nom.
    final p = v.producteur;
    final producteur = p.isEmpty || nom.toLowerCase().contains(p.toLowerCase()) || p.toLowerCase().contains(nom.toLowerCase()) ? '' : p;

    if (v.bulles && v.champagne) {
      return tr('Bienvenue sur les terres crayeuses de Champagne. La craie garde l\'eau et la fraîcheur, et donne aux vins leur tension. {nom}{millesime} en est le fruit.', 'Welcome to the chalk of Champagne. The chalk holds water and coolness, and gives the wines their tension. {nom}{millesime} is its fruit.', {'nom': nom, 'millesime': millesime});
    }
    final String origine;
    if (producteur.isNotEmpty && v.cepages.isNotEmpty) {
      origine = tr('{producteur} y cultive {cepages} pour donner naissance à {nom}{millesime}.', '{producteur} grows {cepages} there to make {nom}{millesime}.', {'producteur': producteur, 'cepages': v.cepages, 'nom': nom, 'millesime': millesime});
    } else if (v.cepages.isNotEmpty) {
      origine = tr('C\'est là que naît {nom}{millesime}, issu de {cepages}.', 'This is where {nom}{millesime} is born, from {cepages}.', {'nom': nom, 'millesime': millesime, 'cepages': v.cepages});
    } else if (producteur.isNotEmpty) {
      origine = tr('{producteur} y élabore {nom}{millesime}.', '{producteur} makes {nom}{millesime} there.', {'producteur': producteur, 'nom': nom, 'millesime': millesime});
    } else {
      origine = tr('C\'est là que naît {nom}{millesime}.', 'This is where {nom}{millesime} is born.', {'nom': nom, 'millesime': millesime});
    }
    if (lieu.isEmpty) {
      return v.cepages.isEmpty
          ? tr('Voici {nom}{millesime}.', 'Here is {nom}{millesime}.', {'nom': nom, 'millesime': millesime})
          : tr('Voici {nom}{millesime}, issu de {cepages}.', 'Here is {nom}{millesime}, made from {cepages}.', {'nom': nom, 'millesime': millesime, 'cepages': v.cepages});
    }
    return tr('Tout commence par un lieu : {lieu}. {origine}', 'It all starts with a place: {lieu}. {origine}', {'lieu': lieu, 'origine': origine});
  }

  /// L'acte 2 ne dit que ce qu'imposent les règles de l'appellation (prise de mousse en
  /// bouteille en Champagne, vendange tardive à Sauternes) ou ce que la fiche dit de
  /// l'élevage. Sinon il se tait : « les raisins ont été cueillis mûrs » se disait de tout
  /// rouge, « concentrés sur pied » d'un porto (08/10).
  static String _vinification(_Vin v) {
    if (v.wine.isFortified || v.wine.isSpirit) return '';
    if (v.bulles) {
      if (v.methodeTraditionnelle) {
        return tr('La seconde fermentation a lieu en bouteille. Le vin repose ensuite sur ses lies, qui lui donnent son crémeux et la finesse de sa bulle.',
            'The second fermentation happens in the bottle. The wine then rests on its lees, which give it creaminess and fine bubbles.');
      }
      if (v.cuveClose) {
        return tr('Ici, la mousse se prend le plus souvent en cuve close, sous pression : une méthode rapide qui garde au fruit tout son croquant.',
            'Here the bubbles usually form in a sealed tank, under pressure: a quick method that keeps the fruit crisp.');
      }
      return '';
    }
    if (v.vendangeTardive) {
      return tr('Les raisins ont été cueillis tard, concentrés sur pied, souvent grain par grain : tout le sucre et l\'éclat du vin viennent de là.',
          'The grapes were picked late, concentrated on the vine, often berry by berry: that is where the wine\'s sweetness and brightness come from.');
    }
    if (v.doux) return '';
    if (v.bois) {
      return v.rouge
          ? tr('Un élevage sous bois patine les tanins.', 'Oak ageing polishes the tannins.')
          : tr('Un élevage sous bois lui donne son ampleur.', 'Oak ageing gives it breadth.');
    }
    if (v.cuve) return tr('Un élevage en cuve préserve l\'éclat du fruit.', 'Ageing in tank keeps the fruit bright.');
    if (v.rose) {
      return tr('Un rosé tient sa couleur d\'un bref contact avec la peau des raisins noirs.',
          'A rosé gets its colour from brief contact with the skins of black grapes.');
    }
    return '';
  }

  /// L'acte 3 dit ce que le cépage ou le style donne le plus souvent, en le disant comme
  /// tel ; sans cépage ni style connu, il se tait plutôt que de décrire « les fruits mûrs »
  /// de n'importe quel rouge.
  static String _degustation(_Vin v) {
    if (v.wine.isFortified || v.wine.isSpirit) return '';
    final c = v.cepagePrincipal;
    bool a(List<String> mots) => mots.any(c.contains);
    final String? nez;
    if (v.bulles) {
      nez = v.methodeTraditionnelle
          ? tr('une bulle fine, des agrumes et, avec l\'âge, des notes de brioche', 'fine bubbles, citrus and, with age, notes of brioche')
          : v.cuveClose
              ? tr('une bulle légère, des notes de poire et de fleurs blanches', 'light bubbles, notes of pear and white flowers')
              : null;
    } else if (v.vendangeTardive) {
      nez = tr('le miel, l\'abricot confit et une fraîcheur qui équilibre le sucre', 'honey, candied apricot and a freshness that balances the sweetness');
    } else if (v.doux) {
      nez = null;
    } else if (v.rose) {
      nez = tr('les petits fruits rouges et les agrumes, tout en fraîcheur', 'small red berries and citrus, all freshness');
    } else if (v.rouge) {
      // Le cépage principal : un Châteauneuf à dominante de grenache n'a pas le poivre
      // d'une syrah, ni un nebbiolo le cassis d'un cabernet (08/10).
      nez = a(['pinot', 'gamay', 'grolleau', 'poulsard', 'trousseau'])
          ? tr('les fruits rouges, la cerise, des tanins tout en souplesse', 'red fruit, cherry, and supple tannins')
          : a(['nebbiolo'])
              ? tr('la rose, la cerise et le goudron, sur des tanins serrés', 'roses, cherry and tar, over firm tannins')
              : a(['syrah', 'shiraz'])
                  ? tr('les fruits noirs et les épices, le poivre en signature', 'dark fruit and spice, with pepper as a signature')
                  : a(['grenache', 'garnacha', 'cannonau'])
                      ? tr('les fruits rouges mûrs, le kirsch et les épices douces', 'ripe red fruit, kirsch and sweet spice')
                      : a(['mourv', 'monastrell'])
                          ? tr('les fruits noirs, le cuir et la garrigue', 'dark fruit, leather and garrigue')
                          : a(['cabernet', 'malbec', 'tannat', 'petit verdot'])
                              ? tr('le cassis, les fruits noirs et une trame tannique serrée', 'blackcurrant, dark fruit and firm tannins')
                              : null;
    } else {
      nez = a(['gewurz', 'muscat', 'viognier'])
          ? tr('la rose, le litchi ou l\'abricot : un nez qui explose', 'rose, lychee or apricot: an exuberant nose')
          : a(['sauvignon', 'riesling', 'melon', 'aligot', 'albariño', 'albarino'])
              ? tr('les agrumes et les fleurs blanches, et une belle vivacité', 'citrus and white flowers, with lovely crispness')
              : v.bois
                  ? tr('les fruits mûrs, des notes beurrées et toastées', 'ripe fruit, buttery and toasty notes')
                  : null;
    }
    if (nez == null) return '';
    return tr('Ce qu\'on y trouve le plus souvent : {nez}. Prenez le temps de le laisser s\'ouvrir.',
        'What you usually find in it: {nez}. Give it time to open up.', {'nez': nez});
  }
}

/// Ce que la fiche dit du vin, lu une fois.
class _Vin {
  final Wine wine;
  _Vin(this.wine);

  String get _type => wine.type.toLowerCase();
  String get _lieu => '${wine.region} ${wine.appellation ?? ''} ${wine.subRegion ?? ''} ${wine.name}'.toLowerCase();
  String get _elevage => '${wine.elevageType ?? ''} ${wine.barrelAging ?? ''}'.toLowerCase();

  String get region => wine.region.trim();
  String get appellation => (wine.appellation ?? '').trim();
  String get producteur => (wine.producer ?? '').trim();

  /// Le cépage le plus représenté (le premier cité si la fiche ne donne pas de part).
  String get cepagePrincipal {
    if (wine.grapes.isEmpty) return '';
    var principal = wine.grapes.first;
    for (final g in wine.grapes) {
      if ((g.pct ?? 0) > (principal.pct ?? 0)) principal = g;
    }
    return principal.name.toLowerCase();
  }
  String get cepages {
    final noms = [for (final g in wine.grapes) if (g.name.trim().isNotEmpty) g.name.trim()];
    if (noms.length <= 1) return noms.join();
    return '${noms.sublist(0, noms.length - 1).join(', ')} ${tr('et', 'and')} ${noms.last}';
  }

  // Mots entiers : « cava » n'est pas dans « Château Cavalier », ni « asti » dans
  // « Castiglione Falletto » (08/10).
  static bool _unDe(String texte, List<String> mots) =>
      RegExp('(?<!\\p{L})(?:${mots.map(RegExp.escape).join('|')})(?!\\p{L})', unicode: true).hasMatch(texte);

  bool get bulles =>
      ['champ', 'efferv', 'sparkling', 'crémant', 'cremant', 'mousseux', 'prosecco', 'cava'].any(_type.contains) ||
      _unDe(_lieu, ['champagne', 'crémant', 'cremant', 'prosecco', 'cava', 'franciacorta', 'trentodoc']);
  bool get champagne => _unDe(_lieu, ['champagne']) || _type.contains('champagne');

  /// Prise de mousse en bouteille imposée par l'appellation, ou écrite sur la fiche.
  bool get methodeTraditionnelle =>
      _unDe(_lieu, ['champagne', 'crémant', 'cremant', 'cava', 'franciacorta', 'trentodoc']) ||
      _unDe('$_lieu $_elevage', ['méthode traditionnelle', 'methode traditionnelle', 'méthode champenoise', 'metodo classico']);

  /// Prosecco, Lambrusco, Asti : mousse le plus souvent prise en cuve.
  bool get cuveClose => _unDe(_lieu, ['prosecco', 'lambrusco', 'asti']);

  /// Vendange tardive par définition de l'appellation ou de la mention.
  bool get vendangeTardive => _unDe(_lieu, [
        'sauternes', 'barsac', 'loupiac', 'coteaux du layon', 'bonnezeaux', 'quarts de chaume', 'quarts-de-chaume',
        'vendanges tardives', 'sélection de grains nobles', 'selection de grains nobles', 'aszú', 'aszu',
      ]);

  bool get doux => vendangeTardive || ['doux', 'liquoreux', 'moelleux', 'sweet'].any(_type.contains);
  bool get rose => _type.contains('rosé') || _type.contains('rose');
  bool get rouge => !rose && (_type.contains('rouge') || _type.contains('red'));

  // « Sans bois, en cuve inox » n'est pas un élevage sous bois.
  bool get _sansBois => _unDe(_elevage, ['sans bois', 'sans fût', 'sans fut', 'unoaked', 'no oak', 'without oak', 'sin madera', 'senza legno']);
  bool get bois =>
      !_sansBois && _unDe(_elevage, ['barrique', 'barriques', 'fût', 'fûts', 'fut', 'futs', 'bois', 'oak', 'chêne', 'chene', 'foudre', 'foudres', 'barrel', 'barrels']);
  bool get cuve => _unDe(_elevage, ['inox', 'cuve', 'cuves', 'béton', 'beton', 'steel', 'amphore', 'amphores']);
}
