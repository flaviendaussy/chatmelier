import '../../../shared/utils/sans_accents.dart';
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
  static String _norm(String? s) => sansAccents(s ?? '');

  /// Le rang déduit des mentions portées par le vin.
  ///
  /// L'ordre compte : on cherche d'abord le sommet, puis on redescend. « Gran Reserva »
  /// contient « reserva », donc tester « reserva » d'abord classerait tous les Gran
  /// Reserva en supérieur.
  static WineTier rangDe({
    String? nom,
    String? classification,
    String? appellation,
    String? producteur,
  }) {
    // Les mots du producteur ne disent rien du rang de la cuvée : « Réserve des
    // Hospitaliers » est une cave coopérative, pas une réserve. Son Cairanne recevait la
    // garde d'une cuvée de réserve (× 1,35), 01/10.
    var n = _norm(nom);
    final p = _norm(producteur).trim();
    if (p.length >= 4 && n.contains(p)) n = n.replaceAll(p, ' ');
    final t = '$n ${_norm(classification)} ${_norm(appellation)}';

    // « Saint-Émilion grand cru » est une APPELLATION, pas un classement : sans ce cas,
    // tout Saint-Émilion grand cru passait au rang des grands crus classés (× 1,9).
    if ((t.contains('saint-emilion grand cru') || t.contains('saint emilion grand cru')) &&
        !t.contains('classe') &&
        !t.contains('premier grand cru')) {
      return WineTier.superieur;
    }

    // Un second vin se boit AVANT le grand vin, pas après : il est vinifié pour être
    // accessible. Sans cette détection, « Les Hauts de Lynch-Moussas » héritait des
    // vingt-deux ans d'un Haut-Médoc de garde.
    //
    // Cherché avant le sommet : sa classification dit souvent « Second vin de Grand Cru
    // Classé », et « grand cru classe » le rangeait au sommet — trente-huit ans de garde
    // pour Sarget de Gruaud Larose (01/10).
    const secondVin = [
      'les hauts de', 'le petit', 'la petite', 'esprit de', 'second vin',
      'reserve de la', 'pagodes de', 'clarence de', 'carruades',
      'chapelle de', 'fleur de', 'moulin de', 'alter ego',
      // Relevé le 30/09 : « Sarget de Gruaud Larose » recevait la garde d'un grand vin.
      'sarget de', 'pavillon rouge', 'forts de latour', 'dame de montrose',
      'fiefs de lagrange', 'tourelles de longueville', 'croix de beaucaillou',
      'petit lion', 'blason d\'issan', 'segla', 'connetable', 'marquis de calon',
      'la parde de', 'benjamin de', 'petit chablis',
    ];
    for (final m in secondVin) {
      if (t.contains(m)) return WineTier.entree;
    }

    const sommet = [
      'grand cru', 'gran reserva', 'premier grand cru', '1er grand cru',
      'grand cru classe', 'cru classe', 'riserva', 'gran seleccion', 'gran selezione',
      'premier cru', '1er cru', 'vendanges tardives', 'selection de grains',
      'trockenbeerenauslese', 'beerenauslese', 'auslese', 'vintage port',
      'garrafeira', 'vin jaune', 'chateau-chalon', 'chateau chalon',
    ];
    for (final m in sommet) {
      if (t.contains(m)) return WineTier.sommet;
    }

    // « DOCG » est une mention d'appellation, pas de rang : un Chianti DOCG de base se
    // boit dans ses cinq ans. Elle était classée au sommet (× 1,9) jusqu'au 30/09.
    const superieur = [
      'reserva', 'reserve', 'vieilles vignes', 'old vine', 'superiore',
      'superior', 'spatlese', 'kabinett', 'classico',
      'vieille vigne', 'grande cuvee', 'tete de cuvee', 'docg',
    ];

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
    final couleur = _couleurDe(type);

    // La base de régions est la seule table de longévité.
    //
    // Une seconde table vivait ici, franco-centrée, gardée « en second rideau ». Mesuré
    // ensuite : sur 144 alias, elle ne répondait JAMAIS — la base la masquait
    // intégralement. Quatre cents lignes de données mortes qui auraient divergé à la
    // première correction, sans que rien ne le signale. Retirée.
    //
    // Le vrai dernier recours n'est pas ici mais dans `computeDrinkingWindow`, qui
    // estime par couleur quand plus rien ne correspond.
    final region0 = WineWorld.region(
      pays: pays,
      region: '${region ?? ''} ${sousRegion ?? ''}',
      appellation: appellation,
      cepages: cepages,
    );
    // Pas de profil pour cette couleur dans la région (un rosé du Languedoc), ou aucune
    // région reconnue : la couleur sert d'enveloppe. Sans elle, la fenêtre donnée par
    // l'IA passait telle quelle, sans rien à quoi la confronter — un rosé « à garder
    // quatorze ans » s'affichait sans broncher (30/09).
    return region0?.longevitePour(couleur) ?? _parCouleur[couleur];
  }

  /// La longévité d'un vin ordinaire de chaque couleur, faute de mieux.
  static const Map<String, AgingProfile> _parCouleur = {
    'red': AgingProfile(id: 'generique_rouge', libelle: 'Rouge', debut: 1, picDebut: 2, picFin: 6, fin: 9),
    'white': AgingProfile(id: 'generique_blanc', libelle: 'Blanc', debut: 0, picDebut: 1, picFin: 3, fin: 5),
    'rose': AgingProfile(id: 'generique_rose', libelle: 'Rosé', debut: 0, picDebut: 1, picFin: 2, fin: 3),
    'sparkling': AgingProfile(id: 'generique_bulles', libelle: 'Effervescent', debut: 0, picDebut: 1, picFin: 3, fin: 5),
    'sweet': AgingProfile(id: 'generique_doux', libelle: 'Vin doux', debut: 1, picDebut: 3, picFin: 10, fin: 15),
  };

  /// La couleur d'un vin telle que la base la décrit : 'red', 'white', 'rose',
  /// 'sparkling', 'sweet' ou 'fortified'.
  static String couleurDe(String? type) => _couleurDe(type);

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

}
