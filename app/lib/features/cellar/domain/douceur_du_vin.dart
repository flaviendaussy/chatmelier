import '../../../shared/utils/sans_accents.dart';

/// La douceur d'un vin — son sucre résiduel — de 0 (sec) à 1 (liquoreux) (V2.6 · P3).
///
/// **Sûre** quand l'étiquette la dit (« demi-sec », « brut nature », « Spätlese »,
/// « moelleux ») ou que l'appellation n'existe qu'en vin doux (Sauternes, Bonnezeaux,
/// Banyuls) ; sinon l'usage le plus courant de l'appellation, puis de la couleur, et la
/// douceur n'est que devinée : un Vouvray peut être sec, tendre ou moelleux.
class DouceurDuVin {
  final double valeur;
  final bool sure;
  const DouceurDuVin(this.valeur, {this.sure = false});

  static DouceurDuVin estimer({
    String? type,
    String? nom,
    String? appellation,
    String? region,
    String? pays,
    String? classification,
    List<String> cepages = const [],
  }) {
    final texte = ' ${_norm('${nom ?? ''} ${appellation ?? ''} ${classification ?? ''}')} ';
    final genre = _norm(type ?? '');
    final lieu = ' ${_norm('${appellation ?? ''} ${region ?? ''} ${nom ?? ''}')} ';
    bool dit(String mot) => texte.contains(' $mot ');
    bool dans(String mot) => lieu.contains(' $mot ');
    final bulles = genre.contains('sparkling') || genre.contains('champ') || genre.contains('effervescent') ||
        genre.contains('bulles') || genre.contains('cremant') ||
        const ['champagne', 'cremant', 'cava', 'franciacorta', 'prosecco', 'spumante', 'sekt'].any(dans);

    // 1. Ce que dit l'étiquette, du plus précis au plus général : « brut nature » avant
    // « brut », « spätlese trocken » avant « spätlese », « demi-sec » avant « sec ».
    for (final (mots, valeur) in _mentions) {
      final mot = mots.where(dit).firstOrNull;
      if (mot == null) continue;
      // Sur une bulle, « sec » et « dry » disent un vin tendre : un Champagne Sec est plus
      // doux qu'un Brut, un Prosecco Dry plus doux qu'un Extra Dry.
      if (bulles && (mot == 'sec' || mot == 'dry')) return const DouceurDuVin(0.3, sure: true);
      return DouceurDuVin(valeur, sure: true);
    }

    // 2. Les vins doux par nature : le type de la fiche, ou une appellation qui n'existe
    // qu'en doux. « Maury sec » et « Jurançon sec » ont été lus à l'étape 1.
    if (genre.contains('dessert') || genre.contains('sweet') || genre.contains('liquoreux') || genre.contains('moelleux')) {
      return const DouceurDuVin(0.85, sure: true);
    }
    final secs = _homonymesSecs.any(dans);
    if (!secs) {
      for (final (mots, valeur) in _appellationsDouces) {
        if (mots.any(dans)) return DouceurDuVin(valeur, sure: true);
      }
    }

    // 3. L'usage de l'appellation ou du cépage, deviné.
    for (final (mots, valeur) in _usages) {
      if (mots.any(dans)) return DouceurDuVin(valeur);
    }
    final p = _norm(pays ?? '');
    final allemand = p.contains('allem') || p.contains('german') || p.contains('deutsch');
    if (allemand && (cepages.any((c) => _norm(c).contains('riesling')) || dans('riesling'))) {
      return const DouceurDuVin(0.3);
    }
    if (cepages.any((c) => _norm(c).contains('gewurz')) || dans('gewurztraminer')) return const DouceurDuVin(0.3);

    // 4. La couleur : une bulle sans mention est un brut, un Prosecco un extra dry ; un vin
    // tranquille est sec.
    if (dans('prosecco')) return const DouceurDuVin(0.2);
    if (bulles) return const DouceurDuVin(0.12);
    if (genre.contains('rouge') || genre == 'red') return const DouceurDuVin(0.03);
    return const DouceurDuVin(0.08);
  }

  static String _norm(String s) =>
      sansAccents(s.toLowerCase()).replaceAll(RegExp(r"[-'’/(),.]"), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Les mentions de l'étiquette et la douceur qu'elles disent, dans l'ordre de lecture.
  static const List<(List<String>, double)> _mentions = [
    (['brut nature', 'pas dose', 'non dose', 'zero dosage', 'dosage zero', 'brut zero'], 0.02),
    (['extra brut'], 0.05),
    (['kabinett trocken', 'spatlese trocken', 'auslese trocken', 'grosses gewachs'], 0.05),
    (['trockenbeerenauslese', 'beerenauslese', 'eiswein', 'ice wine', 'icewine', 'selection de grains nobles', 'sgn',
      'passito', 'vin santo', 'recioto', 'aszu', 'pedro ximenez', 'liquoreux', 'vino dulce'], 0.9),
    (['vin doux naturel', 'vdn'], 0.8),
    (['auslese', 'late harvest', 'vendange tardive', 'vendanges tardives'], 0.65),
    (['moelleux', 'dolce', 'dulce', 'doux'], 0.7),
    (['spatlese', 'lieblich', 'semi dulce'], 0.55),
    (['demi sec', 'halbtrocken', 'semi seco', 'semisecco', 'off dry', 'feinherb', 'abboccato', 'amabile'], 0.45),
    (['kabinett'], 0.35),
    (['extra dry', 'extra sec'], 0.2),
    (['brut'], 0.1),
    (['trocken', 'seco', 'secco', 'szaraz', 'dry', 'sec', 'fino', 'manzanilla', 'amontillado', 'sercial'], 0.05),
  ];

  /// Des vins secs qui portent le nom d'un vin doux.
  static const _homonymesSecs = ['clos du maury', 'cadillac cotes de bordeaux', 'port vendres'];

  /// Les appellations qui n'existent qu'en vin doux.
  static const List<(List<String>, double)> _appellationsDouces = [
    (['sauternes', 'barsac', 'loupiac', 'cadillac', 'sainte croix du mont', 'monbazillac', 'saussignac', 'bonnezeaux',
      'quarts de chaume', 'coteaux du layon', 'coteaux de l aubance', 'muscat de beaumes de venise',
      'muscat de rivesaltes', 'banyuls', 'maury', 'rivesaltes', 'porto', 'ruby port', 'tawny port', 'vintage port',
      'lbv', 'tawny', 'pineau des charentes'], 0.85),
    (['moscato d asti', 'asti spumante', 'brachetto'], 0.65),
  ];

  /// L'usage le plus courant, quand l'étiquette se tait.
  static const List<(List<String>, double)> _usages = [
    (['tokaji'], 0.7),
    (['jurancon', 'pacherenc'], 0.6),
    (['madere', 'madeira', 'marsala'], 0.6),
    (['rose d anjou', 'cabernet d anjou', 'white zinfandel', 'blush'], 0.4),
    (['vouvray', 'montlouis', 'lambrusco'], 0.25),
  ];
}
