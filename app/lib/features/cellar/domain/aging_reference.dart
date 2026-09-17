import 'wine_world/wine_world.dart';

/// Rang d'un vin dans sa propre appellation.
///
/// Deux Margaux n'ont pas la même longévité : un cru classé tient trente ans là où un
/// second vin en tient douze. C'est la dimension qui manquait — l'ancienne table ne
/// reconnaissait que « grand cru » dans le NOM, et seulement pour Bordeaux et la
/// Bourgogne. Un Gran Reserva, un Riserva ou un Kabinett n'existaient pas.
enum WineTier {
  /// Entrée de gamme revendiquée : Joven, primeur, cuvée sans élevage.
  entree,

  /// Le cas courant, sans mention particulière.
  standard,

  /// Une mention qui engage : Réserve, Vieilles Vignes, Crianza, Superiore.
  superieur,

  /// Le haut de l'appellation : cru classé, grand cru, Gran Reserva, Riserva.
  sommet,
}

/// Fenêtre de garde d'une catégorie, en années depuis le millésime.
class AgingProfile {
  final String id;
  final String libelle;
  final int debut;
  final int picDebut;
  final int picFin;
  final int fin;

  const AgingProfile({
    required this.id,
    required this.libelle,
    required this.debut,
    required this.picDebut,
    required this.picFin,
    required this.fin,
  });

  /// Applique le rang du vin. Les facteurs sont volontairement modestes : le rang
  /// module une longévité, il ne la transforme pas. Un Bourgogne village de haut rang
  /// ne devient pas un grand cru.
  AgingProfile pourRang(WineTier rang) {
    final f = switch (rang) {
      WineTier.entree => 0.6,
      WineTier.standard => 1.0,
      WineTier.superieur => 1.35,
      WineTier.sommet => 1.9,
    };
    if (f == 1.0) return this;
    int e(int v) => (v * f).round();
    return AgingProfile(
      id: '$id:${rang.name}',
      libelle: libelle,
      debut: e(debut).clamp(0, 30),
      picDebut: e(picDebut).clamp(1, 60),
      picFin: e(picFin).clamp(2, 90),
      fin: e(fin).clamp(3, 120),
    );
  }
}

/// Critères de reconnaissance d'une catégorie.
class _Regle {
  final AgingProfile profil;
  final List<String> appellations;
  final List<String> regions;
  final List<String> pays;
  final List<String> cepages;

  /// Couleur exigée : 'red', 'white', 'rose', 'sparkling', 'sweet', 'fortified'.
  final String? couleur;

  const _Regle(
    this.profil, {
    this.appellations = const [],
    this.regions = const [],
    this.pays = const [],
    this.cepages = const [],
    this.couleur,
  });
}

/// Table de référence des longévités, par origine et par rang.
///
/// Remplace une chaîne de huit `if` qui ne couvrait que la France plus trois noms
/// italo-espagnols (Barolo, Brunello, Rioja, tous au même palier de trente ans), et
/// n'avait **aucune** catégorie pour les vins doux — un Sauternes y était traité comme
/// un Sancerre, sept ans, là où il en tient vingt à cent.
///
/// Les fenêtres visent le vin **représentatif** de sa catégorie, le rang se chargeant
/// de l'écart entre un village et un cru classé.
class AgingReference {
  static String _norm(String? s) => (s ?? '')
      .toLowerCase()
      .replaceAll(RegExp(r'[àâä]'), 'a')
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[îï]'), 'i')
      .replaceAll(RegExp(r'[ôö]'), 'o')
      .replaceAll(RegExp(r'[ùûü]'), 'u')
      .replaceAll('ç', 'c');

  /// Le rang déduit des mentions portées par le vin.
  ///
  /// L'ordre compte : on cherche d'abord le sommet, puis on redescend. « Gran Reserva »
  /// contient « reserva », donc tester « reserva » d'abord classerait tous les Gran
  /// Reserva en supérieur.
  static WineTier rangDe({String? nom, String? classification, String? appellation}) {
    final t = _norm('${nom ?? ''} ${classification ?? ''} ${appellation ?? ''}');

    const sommet = [
      'grand cru', 'gran reserva', 'premier grand cru', '1er grand cru',
      'grand cru classe', 'cru classe', 'riserva', 'gran seleccion',
      'premier cru', '1er cru', 'vendanges tardives', 'selection de grains',
      'trockenbeerenauslese', 'beerenauslese', 'auslese', 'vintage port',
      'garrafeira', 'docg',
    ];
    for (final m in sommet) {
      if (t.contains(m)) return WineTier.sommet;
    }

    const superieur = [
      'reserva', 'reserve', 'vieilles vignes', 'old vine', 'superiore',
      'superior', 'spatlese', 'kabinett', 'classico',
      'vieille vigne', 'grande cuvee', 'tete de cuvee',
    ];

    // Un second vin se boit AVANT le grand vin, pas après : il est vinifié pour être
    // accessible. Sans cette détection, « Les Hauts de Lynch-Moussas » héritait des
    // vingt-deux ans d'un Haut-Médoc de garde.
    const secondVin = [
      'les hauts de', 'le petit', 'la petite', 'esprit de', 'second vin',
      'reserve de la', 'pagodes de', 'clarence de', 'carruades',
      'chapelle de', 'fleur de', 'moulin de', 'alter ego',
    ];
    for (final m in secondVin) {
      if (t.contains(m)) return WineTier.entree;
    }
    for (final m in superieur) {
      if (t.contains(m)) return WineTier.superieur;
    }

    // « Crianza » n'est PAS un rang supérieur : c'est le premier échelon de
    // vieillissement espagnol, sous Reserva et Gran Reserva. Le classer en supérieur
    // donnait vingt-sept ans à un Ribera del Duero Crianza, qui en tient cinq à douze.
    const entree = [
      'joven', 'primeur', 'nouveau', 'novello', 'vin de soif', 'glou',
      'crianza',
    ];
    for (final m in entree) {
      if (t.contains(m)) return WineTier.entree;
    }

    return WineTier.standard;
  }

  /// La catégorie qui correspond, ou nul si rien ne colle.
  ///
  /// L'ordre des règles vaut priorité : du plus spécifique au plus général. Une
  /// appellation nommée l'emporte sur une région, qui l'emporte sur un pays.
  static AgingProfile? chercher({
    String? pays,
    String? region,
    String? sousRegion,
    String? appellation,
    String? type,
    List<String> cepages = const [],
  }) {
    final app = _norm(appellation);
    final reg = _norm('${region ?? ''} ${sousRegion ?? ''}');
    final pay = _norm(pays);
    final couleur = _couleurDe(type);
    final ceps = cepages.map(_norm).toList();

    // La base de régions fait autorité : elle est plus fine et couvre quinze pays, là où
    // les règles ci-dessous sont l'ancienne table franco-centrée. Celles-ci restent en
    // second rideau pour les cas qu'elle ne connaît pas encore.
    final depuisBase = WineWorld.region(
      pays: pays,
      region: '${region ?? ''} ${sousRegion ?? ''}',
      appellation: appellation,
      cepages: cepages,
    )?.longevitePour(couleur);
    if (depuisBase != null) return depuisBase;

    for (final r in _regles) {
      if (r.couleur != null && r.couleur != couleur) continue;
      final okApp = r.appellations.any((a) => app.contains(a));
      final okReg = r.regions.any((x) => reg.contains(x) || app.contains(x));
      final okPays = r.pays.any((p) => pay.contains(p));
      final okCep = r.cepages.any((c) => ceps.any((x) => x.contains(c)));
      if (okApp || okReg || okPays || okCep) return r.profil;
    }
    return null;
  }

  /// Normalise le type en une couleur connue de la table.
  static String _couleurDe(String? type) {
    final t = _norm(type);
    if (t.contains('fortifi') || t.contains('mute') || t.contains('vdn')) {
      return 'fortified';
    }
    if (t.contains('moelleux') ||
        t.contains('liquoreux') ||
        t.contains('sweet') ||
        t.contains('dessert')) {
      return 'sweet';
    }
    if (t.contains('bulle') || t.contains('sparkl') || t.contains('effervesc')) {
      return 'sparkling';
    }
    if (t.contains('ros')) return 'rose';
    if (t.contains('blanc') || t.contains('white')) return 'white';
    return 'red';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Les règles, du plus spécifique au plus général.
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<_Regle> _regles = [
    // ── Vins doux et mutés : la catégorie qui manquait entièrement ───────────
    _Regle(
      AgingProfile(
          id: 'sweet_botrytis',
          libelle: 'Liquoreux botrytisé',
          debut: 3,
          picDebut: 10,
          picFin: 30,
          fin: 50),
      appellations: ['sauternes', 'barsac', 'tokaj', 'aszu', 'monbazillac',
        'quarts de chaume', 'bonnezeaux', 'coteaux du layon', 'jurancon'],
    ),
    _Regle(
      AgingProfile(
          id: 'fortified_porto_vintage',
          libelle: 'Porto Vintage',
          debut: 8,
          picDebut: 20,
          picFin: 40,
          fin: 60),
      appellations: ['vintage port', 'porto vintage'],
    ),
    _Regle(
      AgingProfile(
          id: 'fortified_madere',
          libelle: 'Madère',
          debut: 2,
          picDebut: 15,
          picFin: 60,
          fin: 100),
      appellations: ['madeira', 'madere'],
    ),
    _Regle(
      AgingProfile(
          id: 'fortified_general',
          libelle: 'Vin muté',
          debut: 1,
          picDebut: 4,
          picFin: 20,
          fin: 35),
      appellations: ['porto', 'banyuls', 'maury', 'rivesaltes', 'rasteau',
        'muscat de', 'sherry', 'jerez', 'xeres'],
      couleur: 'fortified',
    ),
    _Regle(
      AgingProfile(
          id: 'sweet_general',
          libelle: 'Moelleux',
          debut: 2,
          picDebut: 5,
          picFin: 15,
          fin: 25),
      couleur: 'sweet',
    ),

    // ── France, rouges ──────────────────────────────────────────────────────
    _Regle(
      AgingProfile(
          id: 'fr_bordeaux_rouge',
          libelle: 'Bordeaux rouge',
          debut: 4,
          picDebut: 8,
          picFin: 16,
          fin: 22),
      appellations: ['margaux', 'pauillac', 'saint-julien', 'saint-estephe',
        'pessac', 'pomerol', 'saint-emilion', 'medoc', 'graves', 'fronsac',
        'puisseguin', 'lalande', 'listrac', 'moulis'],
      regions: ['bordeaux'],
      couleur: 'red',
    ),
    _Regle(
      AgingProfile(
          id: 'fr_beaujolais_cru',
          libelle: 'Cru du Beaujolais',
          debut: 2,
          picDebut: 4,
          picFin: 9,
          fin: 12),
      appellations: ['morgon', 'moulin-a-vent', 'fleurie', 'brouilly',
        'chenas', 'julienas', 'chiroubles', 'saint-amour', 'regnie',
        'cote de brouilly', 'lantignie', 'beaujolais'],
    ),
    // Les appellations régionales de Bourgogne se boivent bien avant les villages :
    // « Bourgogne », « Hautes Côtes », « Coteaux Bourguignons ». Sans cette règle, un
    // Hautes Côtes de Nuits recevait les vingt ans d'un Gevrey-Chambertin.
    _Regle(
      AgingProfile(
          id: 'fr_bourgogne_regionale',
          libelle: 'Bourgogne régional',
          debut: 1,
          picDebut: 3,
          picFin: 7,
          fin: 10),
      appellations: ['hautes cotes', 'coteaux bourguignons', 'bourgogne rouge',
        'bourgogne passetoutgrain'],
    ),
    _Regle(
      AgingProfile(
          id: 'fr_bourgogne_rouge',
          libelle: 'Bourgogne rouge',
          debut: 3,
          picDebut: 6,
          picFin: 14,
          fin: 20),
      appellations: ['gevrey', 'vosne', 'chambolle', 'pommard', 'volnay',
        'nuits-saint-georges', 'beaune', 'mercurey', 'givry', 'santenay',
        'marsannay', 'fixin'],
      regions: ['bourgogne', 'cote de nuits', 'cote de beaune'],
      couleur: 'red',
    ),
    _Regle(
      AgingProfile(
          id: 'fr_rhone_nord',
          libelle: 'Rhône septentrional',
          debut: 4,
          picDebut: 8,
          picFin: 18,
          fin: 25),
      appellations: ['cote-rotie', 'hermitage', 'cornas', 'saint-joseph',
        'crozes', 'condrieu'],
    ),
    _Regle(
      AgingProfile(
          id: 'fr_rhone_sud_cru',
          libelle: 'Cru du Rhône méridional',
          debut: 3,
          picDebut: 6,
          picFin: 14,
          fin: 20),
      appellations: ['chateauneuf', 'gigondas', 'vacqueyras', 'cairanne',
        'lirac'],
    ),
    // Tavel figurait parmi les crus du Rhône, qui n'ont pas de contrainte de couleur :
    // ce rosé y recevait vingt ans. Il en tient trois à huit.
    _Regle(
      AgingProfile(
          id: 'fr_tavel',
          libelle: 'Tavel',
          debut: 1,
          picDebut: 2,
          picFin: 6,
          fin: 8),
      appellations: ['tavel'],
    ),
    _Regle(
      AgingProfile(
          id: 'fr_rhone_sud_village',
          libelle: 'Rhône méridional',
          debut: 1,
          picDebut: 3,
          picFin: 7,
          fin: 10),
      appellations: ['cotes du rhone', 'uzes', 'ventoux', 'luberon',
        'costieres', 'grignan'],
      regions: ['rhone'],
    ),
    _Regle(
      AgingProfile(
          id: 'fr_bandol_rouge',
          libelle: 'Bandol rouge',
          debut: 4,
          picDebut: 8,
          picFin: 18,
          fin: 25),
      appellations: ['bandol'],
      couleur: 'red',
    ),
    // Le Bandol rosé est l'exception qui justifie de ne pas traiter « rosé » comme une
    // seule catégorie : porté par le mourvèdre, il tient 5 à 10 ans, et Terrebrune en
    // sert couramment des bouteilles de vingt ans. Sans cette règle il tombait dans le
    // rosé générique — trois ans — soit la pire erreur possible sur ce vin.
    _Regle(
      AgingProfile(
          id: 'fr_bandol_rose',
          libelle: 'Bandol rosé',
          debut: 1,
          picDebut: 3,
          picFin: 9,
          fin: 14),
      appellations: ['bandol'],
      couleur: 'rose',
    ),
    _Regle(
      AgingProfile(
          id: 'fr_bandol_blanc',
          libelle: 'Bandol blanc',
          debut: 1,
          picDebut: 3,
          picFin: 9,
          fin: 14),
      appellations: ['bandol'],
      couleur: 'white',
    ),
    _Regle(
      AgingProfile(
          id: 'fr_sud_ouest',
          libelle: 'Sud-Ouest',
          debut: 3,
          picDebut: 6,
          picFin: 14,
          fin: 20),
      appellations: ['madiran', 'cahors', 'irouleguy', 'fronton', 'gaillac',
        'bergerac', 'pecharmant'],
    ),
    _Regle(
      AgingProfile(
          id: 'fr_languedoc_provence_rouge',
          libelle: 'Languedoc & Provence rouge',
          debut: 2,
          picDebut: 4,
          picFin: 9,
          fin: 13),
      appellations: ['languedoc', 'corbieres', 'minervois', 'faugeres',
        'saint-chinian', 'pic saint-loup', 'cotes de provence', 'coteaux d\'aix',
        'les baux'],
      couleur: 'red',
    ),
    _Regle(
      AgingProfile(
          id: 'fr_loire_rouge',
          libelle: 'Loire rouge',
          debut: 2,
          picDebut: 5,
          picFin: 12,
          fin: 18),
      appellations: ['chinon', 'bourgueil', 'saumur-champigny', 'anjou rouge',
        'saint-nicolas'],
      couleur: 'red',
    ),

    // ── France, blancs ──────────────────────────────────────────────────────
    _Regle(
      AgingProfile(
          id: 'fr_aligote',
          libelle: 'Bourgogne Aligoté',
          debut: 1,
          picDebut: 2,
          picFin: 5,
          fin: 8),
      appellations: ['aligote'],
      cepages: ['aligote'],
    ),
    _Regle(
      AgingProfile(
          id: 'fr_bourgogne_blanc',
          libelle: 'Bourgogne blanc',
          debut: 2,
          picDebut: 4,
          picFin: 10,
          fin: 15),
      appellations: ['chablis', 'meursault', 'montrachet', 'corton-charlemagne',
        'saint-aubin', 'rully', 'macon', 'pouilly-fuisse'],
      regions: ['bourgogne'],
      couleur: 'white',
    ),
    _Regle(
      AgingProfile(
          id: 'fr_loire_chenin',
          libelle: 'Chenin de Loire',
          debut: 2,
          picDebut: 5,
          picFin: 14,
          fin: 20),
      appellations: ['vouvray', 'savennieres', 'montlouis', 'saumur blanc'],
      couleur: 'white',
    ),
    _Regle(
      AgingProfile(
          id: 'fr_loire_sauvignon',
          libelle: 'Sauvignon de Loire',
          debut: 1,
          picDebut: 2,
          picFin: 6,
          fin: 9),
      appellations: ['sancerre', 'pouilly-fume', 'menetou', 'quincy',
        'reuilly', 'muscadet'],
      regions: ['loire'],
      couleur: 'white',
    ),
    _Regle(
      AgingProfile(
          id: 'fr_alsace_blanc',
          libelle: 'Alsace',
          debut: 1,
          picDebut: 3,
          picFin: 10,
          fin: 16),
      regions: ['alsace'],
      couleur: 'white',
    ),
    _Regle(
      AgingProfile(
          id: 'fr_jura_blanc',
          libelle: 'Jura blanc',
          debut: 2,
          picDebut: 5,
          picFin: 15,
          fin: 25),
      appellations: ['chateau-chalon', 'arbois', 'cotes du jura', 'l\'etoile'],
      couleur: 'white',
    ),
    _Regle(
      AgingProfile(
          id: 'fr_bordeaux_blanc',
          libelle: 'Bordeaux blanc',
          debut: 1,
          picDebut: 3,
          picFin: 8,
          fin: 12),
      appellations: ['graves', 'pessac', 'entre-deux-mers'],
      regions: ['bordeaux'],
      couleur: 'white',
    ),

    // ── Effervescents ───────────────────────────────────────────────────────
    _Regle(
      AgingProfile(
          id: 'champagne',
          libelle: 'Champagne',
          debut: 2,
          picDebut: 5,
          picFin: 15,
          fin: 25),
      appellations: ['champagne'],
    ),
    _Regle(
      AgingProfile(
          id: 'cava_prosecco',
          libelle: 'Cava & Prosecco',
          debut: 0,
          picDebut: 1,
          picFin: 3,
          fin: 5),
      appellations: ['prosecco', 'cava', 'asti', 'lambrusco'],
    ),
    _Regle(
      AgingProfile(
          id: 'cremant',
          libelle: 'Effervescent',
          debut: 1,
          picDebut: 2,
          picFin: 6,
          fin: 9),
      couleur: 'sparkling',
    ),

    // ── Italie ──────────────────────────────────────────────────────────────
    _Regle(
      AgingProfile(
          id: 'it_nebbiolo',
          libelle: 'Nebbiolo du Piémont',
          debut: 6,
          picDebut: 12,
          picFin: 25,
          fin: 35),
      appellations: ['barolo', 'barbaresco', 'gattinara', 'ghemme'],
      cepages: ['nebbiolo'],
    ),
    _Regle(
      AgingProfile(
          id: 'it_brunello',
          libelle: 'Brunello & Sangiovese de garde',
          debut: 5,
          picDebut: 10,
          picFin: 22,
          fin: 30),
      appellations: ['brunello', 'vino nobile', 'montalcino'],
    ),
    _Regle(
      AgingProfile(
          id: 'it_chianti',
          libelle: 'Chianti & Toscane',
          debut: 2,
          picDebut: 5,
          picFin: 12,
          fin: 18),
      appellations: ['chianti', 'bolgheri', 'maremma', 'morellino'],
      regions: ['toscana', 'toscane', 'tuscany'],
      couleur: 'red',
    ),
    _Regle(
      AgingProfile(
          id: 'it_amarone',
          libelle: 'Amarone & Valpolicella',
          debut: 4,
          picDebut: 8,
          picFin: 20,
          fin: 28),
      appellations: ['amarone', 'valpolicella', 'recioto'],
    ),
    _Regle(
      AgingProfile(
          id: 'it_aglianico',
          libelle: 'Aglianico du Sud',
          debut: 4,
          picDebut: 8,
          picFin: 18,
          fin: 25),
      appellations: ['aglianico', 'taurasi', 'vulture'],
      cepages: ['aglianico'],
    ),
    _Regle(
      AgingProfile(
          id: 'it_etna',
          libelle: 'Etna',
          debut: 3,
          picDebut: 6,
          picFin: 15,
          fin: 22),
      appellations: ['etna'],
      cepages: ['nerello'],
    ),
    _Regle(
      AgingProfile(
          id: 'it_blanc',
          libelle: 'Blanc italien',
          debut: 1,
          picDebut: 2,
          picFin: 6,
          fin: 9),
      pays: ['itali', 'italy'],
      couleur: 'white',
    ),
    _Regle(
      AgingProfile(
          id: 'it_rouge',
          libelle: 'Rouge italien',
          debut: 2,
          picDebut: 4,
          picFin: 10,
          fin: 15),
      pays: ['itali', 'italy'],
      couleur: 'red',
    ),

    // ── Espagne ─────────────────────────────────────────────────────────────
    _Regle(
      AgingProfile(
          id: 'es_priorat',
          libelle: 'Priorat',
          debut: 4,
          picDebut: 8,
          picFin: 18,
          fin: 25),
      appellations: ['priorat', 'montsant'],
    ),
    // Le mourvèdre espagnol — même cépage que le Bandol, même aptitude à la garde.
    _Regle(
      AgingProfile(
          id: 'es_monastrell',
          libelle: 'Monastrell du Levant',
          debut: 2,
          picDebut: 5,
          picFin: 12,
          fin: 16),
      appellations: ['jumilla', 'yecla', 'alicante', 'bullas', 'almansa'],
      cepages: ['monastrell'],
    ),
    _Regle(
      AgingProfile(
          id: 'es_tempranillo',
          libelle: 'Rioja & Ribera',
          debut: 3,
          picDebut: 6,
          picFin: 14,
          fin: 20),
      appellations: ['rioja', 'ribera del duero', 'toro', 'bierzo'],
    ),
    _Regle(
      AgingProfile(
          id: 'es_albarino',
          libelle: 'Albariño & blancs atlantiques',
          debut: 1,
          picDebut: 2,
          picFin: 6,
          fin: 9),
      appellations: ['rias baixas', 'albarino', 'alvarinho', 'vinho verde',
        'godello', 'valdeorras'],
      cepages: ['albarino', 'alvarinho'],
    ),
    _Regle(
      AgingProfile(
          id: 'es_rouge',
          libelle: 'Rouge espagnol',
          debut: 2,
          picDebut: 4,
          picFin: 10,
          fin: 15),
      pays: ['espagn', 'spain'],
      couleur: 'red',
    ),

    // ── Portugal ────────────────────────────────────────────────────────────
    _Regle(
      AgingProfile(
          id: 'pt_douro',
          libelle: 'Douro & Dão',
          debut: 3,
          picDebut: 7,
          picFin: 16,
          fin: 22),
      appellations: ['douro', 'dao', 'bairrada', 'alentejo'],
      couleur: 'red',
    ),

    // ── Allemagne & Autriche ────────────────────────────────────────────────
    _Regle(
      AgingProfile(
          id: 'de_riesling',
          libelle: 'Riesling germanique',
          debut: 2,
          picDebut: 5,
          picFin: 15,
          fin: 25),
      appellations: ['mosel', 'rheingau', 'nahe', 'pfalz', 'wachau',
        'kamptal', 'kremstal'],
      cepages: ['riesling'],
      couleur: 'white',
    ),
    _Regle(
      AgingProfile(
          id: 'at_gruner',
          libelle: 'Grüner Veltliner',
          debut: 1,
          picDebut: 3,
          picFin: 9,
          fin: 14),
      cepages: ['gruner', 'veltliner'],
    ),

    // ── Nouveau Monde ───────────────────────────────────────────────────────
    _Regle(
      AgingProfile(
          id: 'us_napa_cab',
          libelle: 'Cabernet de Napa',
          debut: 4,
          picDebut: 8,
          picFin: 18,
          fin: 25),
      appellations: ['napa', 'oakville', 'rutherford', 'stags leap',
        'howell mountain'],
    ),
    _Regle(
      AgingProfile(
          id: 'us_pinot',
          libelle: 'Pinot de la côte Ouest',
          debut: 2,
          picDebut: 5,
          picFin: 12,
          fin: 17),
      appellations: ['willamette', 'sonoma coast', 'russian river',
        'santa barbara', 'anderson valley'],
    ),
    _Regle(
      AgingProfile(
          id: 'au_shiraz',
          libelle: 'Shiraz australien',
          debut: 3,
          picDebut: 6,
          picFin: 15,
          fin: 22),
      appellations: ['barossa', 'mclaren', 'hunter', 'coonawarra',
        'clare valley', 'eden valley'],
      couleur: 'red',
    ),
    _Regle(
      AgingProfile(
          id: 'au_rouge',
          libelle: 'Rouge australien',
          debut: 1,
          picDebut: 3,
          picFin: 8,
          fin: 12),
      appellations: ['south australia', 'south eastern'],
      pays: ['australi'],
      couleur: 'red',
    ),
    _Regle(
      AgingProfile(
          id: 'nz_sauvignon',
          libelle: 'Sauvignon néo-zélandais',
          debut: 0,
          picDebut: 1,
          picFin: 4,
          fin: 6),
      appellations: ['marlborough'],
    ),
    _Regle(
      AgingProfile(
          id: 'nz_pinot',
          libelle: 'Pinot néo-zélandais',
          debut: 2,
          picDebut: 4,
          picFin: 10,
          fin: 15),
      appellations: ['central otago', 'martinborough'],
    ),
    _Regle(
      AgingProfile(
          id: 'cl_rouge',
          libelle: 'Rouge chilien',
          debut: 2,
          picDebut: 5,
          picFin: 12,
          fin: 18),
      appellations: ['maipo', 'colchagua', 'cachapoal', 'aconcagua',
        'rapel', 'apalta'],
      pays: ['chil'],
      couleur: 'red',
    ),
    _Regle(
      AgingProfile(
          id: 'cl_blanc',
          libelle: 'Blanc chilien',
          debut: 1,
          picDebut: 2,
          picFin: 5,
          fin: 8),
      pays: ['chil'],
      couleur: 'white',
    ),
    _Regle(
      AgingProfile(
          id: 'ar_malbec',
          libelle: 'Malbec argentin',
          debut: 2,
          picDebut: 5,
          picFin: 13,
          fin: 18),
      appellations: ['mendoza', 'uco', 'lujan de cuyo', 'salta'],
      pays: ['argentin'],
      couleur: 'red',
    ),
    _Regle(
      AgingProfile(
          id: 'za_rouge',
          libelle: 'Rouge sud-africain',
          debut: 2,
          picDebut: 5,
          picFin: 12,
          fin: 18),
      appellations: ['stellenbosch', 'swartland', 'paarl', 'walker bay'],
      pays: ['afrique du sud', 'south africa'],
      couleur: 'red',
    ),
  ];
}
