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

  static String _vinification(_Vin v) {
    if (v.bulles) {
      return v.cuveClose
          ? tr('La mousse est prise en cuve close, sous pression : une méthode rapide qui garde au fruit tout son croquant.',
              'The bubbles form in a sealed tank, under pressure: a quick method that keeps the fruit crisp.')
          : tr('La seconde fermentation a lieu en bouteille. Le vin repose ensuite sur ses lies, qui lui donnent son crémeux et la finesse de sa bulle.',
              'The second fermentation happens in the bottle. The wine then rests on its lees, which give it creaminess and fine bubbles.');
    }
    if (v.doux) {
      return tr('Les raisins ont été cueillis tard, concentrés sur pied, souvent grain par grain : tout le sucre et l\'éclat du vin viennent de là.',
          'The grapes were picked late, concentrated on the vine, often berry by berry: that is where the wine\'s sweetness and brightness come from.');
    }
    if (v.rose) {
      return tr('Un contact bref avec les peaux lui a donné sa couleur, puis une fermentation au frais a gardé son fruit.',
          'A brief contact with the skins gave it its colour, then a cool fermentation kept its fruit.');
    }
    final elevage = v.bois
        ? (v.rouge
            ? tr('un élevage sous bois patine les tanins', 'oak ageing polishes the tannins')
            : tr('un élevage sous bois lui donne son ampleur', 'oak ageing gives it breadth'))
        : v.cuve
            ? tr('un élevage en cuve préserve l\'éclat du fruit', 'ageing in tank keeps the fruit bright')
            : '';
    if (v.rouge) {
      return elevage.isEmpty
          ? tr('Les raisins ont été cueillis mûrs, puis le vin a pris le temps de s\'assembler avant la mise en bouteille.',
              'The grapes were picked ripe, then the wine took its time to come together before bottling.')
          : tr('Les raisins ont été cueillis mûrs ; {elevage}.', 'The grapes were picked ripe; {elevage}.', {'elevage': elevage});
    }
    return elevage.isEmpty
        ? tr('Au chai, pressurage délicat et fermentation au frais : tout est fait pour garder la pureté du fruit.',
            'In the cellar, gentle pressing and a cool fermentation: everything aims to keep the fruit pure.')
        : tr('Au chai, pressurage délicat, puis {elevage}.', 'In the cellar, gentle pressing, then {elevage}.', {'elevage': elevage});
  }

  static String _degustation(_Vin v) {
    final c = v.cepagesMinuscules;
    bool a(List<String> mots) => mots.any(c.contains);
    final String nez;
    if (v.bulles) {
      nez = v.cuveClose
          ? tr('une bulle légère, des notes de poire et de fleurs blanches', 'light bubbles, notes of pear and white flowers')
          : tr('une bulle fine, des agrumes et, avec l\'âge, des notes de brioche', 'fine bubbles, citrus and, with age, notes of brioche');
    } else if (v.doux) {
      nez = tr('le miel, l\'abricot confit et une fraîcheur qui équilibre le sucre', 'honey, candied apricot and a freshness that balances the sweetness');
    } else if (v.rose) {
      nez = tr('les petits fruits rouges et les agrumes, tout en fraîcheur', 'small red berries and citrus, all freshness');
    } else if (v.rouge) {
      nez = a(['pinot', 'gamay', 'grolleau', 'poulsard', 'trousseau'])
          ? tr('les fruits rouges, la cerise, des tanins tout en souplesse', 'red fruit, cherry, and supple tannins')
          : a(['syrah', 'shiraz', 'mourv', 'grenache'])
              ? tr('les fruits noirs et les épices, le poivre en signature', 'dark fruit and spice, with pepper as a signature')
              : a(['cabernet', 'malbec', 'tannat', 'nebbiolo', 'petit verdot'])
                  ? tr('le cassis, les fruits noirs et une trame tannique serrée', 'blackcurrant, dark fruit and firm tannins')
                  : tr('les fruits mûrs, et des tanins qui donnent la structure', 'ripe fruit, and tannins that give structure');
    } else {
      nez = a(['gewurz', 'muscat', 'viognier'])
          ? tr('la rose, le litchi ou l\'abricot : un nez qui explose', 'rose, lychee or apricot: an exuberant nose')
          : a(['sauvignon', 'riesling', 'melon', 'aligot', 'albariño', 'albarino'])
              ? tr('les agrumes et les fleurs blanches, et une belle vivacité', 'citrus and white flowers, with lovely crispness')
              : v.bois
                  ? tr('les fruits mûrs, des notes beurrées et toastées', 'ripe fruit, buttery and toasty notes')
                  : tr('les fruits blancs, les fleurs, et de la fraîcheur', 'white fruit, flowers, and freshness');
    }
    return tr('Dans le verre : {nez}. Prenez le temps de le laisser s\'ouvrir. Bonne dégustation.', 'In the glass: {nez}. Give it time to open up. Enjoy.', {'nez': nez});
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

  String get cepagesMinuscules => wine.grapes.map((g) => g.name.toLowerCase()).join(' ');
  String get cepages {
    final noms = [for (final g in wine.grapes) if (g.name.trim().isNotEmpty) g.name.trim()];
    if (noms.length <= 1) return noms.join();
    return '${noms.sublist(0, noms.length - 1).join(', ')} ${tr('et', 'and')} ${noms.last}';
  }

  bool get bulles =>
      ['champ', 'efferv', 'sparkling', 'crémant', 'cremant', 'mousseux', 'prosecco', 'cava'].any(_type.contains) ||
      ['champagne', 'crémant', 'cremant', 'prosecco', 'cava', 'franciacorta'].any(_lieu.contains);
  bool get champagne => _lieu.contains('champagne') || _type.contains('champagne');

  /// Prosecco, Lambrusco, Asti : mousse prise en cuve, pas en bouteille.
  bool get cuveClose => ['prosecco', 'lambrusco', 'asti', 'moscato'].any(_lieu.contains);

  bool get doux =>
      ['doux', 'liquoreux', 'moelleux', 'sweet'].any(_type.contains) ||
      ['sauternes', 'barsac', 'loupiac', 'layon', 'bonnezeaux', 'quarts de chaume', 'tokaj', 'tokaji', 'vendanges tardives']
          .any(_lieu.contains);
  bool get rose => _type.contains('rosé') || _type.contains('rose');
  bool get rouge => !rose && (_type.contains('rouge') || _type.contains('red'));

  bool get bois => ['barrique', 'fût', 'fut ', 'bois', 'oak', 'chêne', 'chene'].any(_elevage.contains);
  bool get cuve => ['inox', 'cuve', 'béton', 'beton', 'steel', 'amphore'].any(_elevage.contains);
}
