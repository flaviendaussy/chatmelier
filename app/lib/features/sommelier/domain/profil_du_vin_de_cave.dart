import '../../../shared/utils/sans_accents.dart';
import '../../auth/domain/wine_taste_radar.dart';
import '../../cellar/domain/vins_connus/vins_connus.dart';
import '../../cellar/domain/wine.dart';
import '../../cellar/domain/wine_world/wine_world.dart';
import '../../journal/domain/questionnaire_de_degustation.dart';

/// Le profil sur huit axes (0–10) d'un vin de cave, estimé d'après sa fiche (V2.3 · J8).
///
/// L'accord multi-palais à la maison ne connaissait d'un vin que sa couleur, sa région
/// et deux ou trois cépages : trois Bourgognes recevaient le même profil, donc le même
/// score — les ex æquo à 72 % du 29/09. La fiche en dit davantage : les cépages (ceux de
/// l'appellation quand elle n'en dit rien), l'élevage, le degré, l'âge du vin et les mots
/// de sa note de dégustation. Chaque signal déplace le profil de la couleur ; aucun ne
/// l'invente quand la fiche se tait.
class ProfilDuVinDeCave {
  static WineTasteRadarMetrics estimer(Wine wine, {int? annee}) {
    final couleur = couleurDuQuestionnaire(wine.type);
    final p = _Axes.pourLaCouleur(couleur);
    // L'appellation de la fiche, sinon celle que porte le nom dans son propre pays
    // (« Chambolle-Musigny », région « Bourgogne ») : sans elle, un premier cru de la
    // Côte de Nuits passait pour un bourgogne régional élevé en cuve.
    final appellation = wine.appellation ??
        (WineWorld.appellationDansLeNom(wine.name, pays: wine.country) ? wine.name : null);

    // 1. Les cépages : ceux de la fiche, sinon ceux de l'appellation — de la couleur du
    // vin seulement : la Côte de Beaune plante pinot noir et chardonnay, un Meursault
    // n'est pas fait de pinot.
    final deLaCouleur = switch (couleur) {
      'red' || 'rose' => const [_rouges],
      'white' || 'dessert' => const [_blancs],
      _ => const <Map<String, Map<String, double>>>[],
    };
    // Le cépage écrit dans le nom passe avant ceux de la région : « Ungrafted Cinsault » de
    // la Maipo n'est pas un cabernet, ni « Finca Notables Tannat » un malbec de Salta. Le
    // 22/10, un vin bu dehors arrivait sans cépages, et le Cinsault était lu tannique à
    // 0,83 et boisé à 0,67.
    final nomNormalise = ' ${_norm('${wine.name} ${wine.cuveeParcel ?? ''}')} ';
    final dansLeNom = [
      for (final t in deLaCouleur)
        for (final c in t.keys)
          if (!_lieuxPlutotQueCepages.contains(c) && nomNormalise.contains(' $c ')) c,
    ];
    final deLaFiche = [for (final g in wine.grapes) _norm(g.name)].where((c) => c.isNotEmpty).toList();
    // La base des vins connus (23/10) : la cuvée d'abord quand elle fixe ses cépages
    // (Château Margaux, Gran Reserva 904, Koonunga Hill), puis le cépage du nom, puis
    // l'encépagement de l'appellation pour la couleur du vin, et la région en dernier.
    // Ses listes vont du dominant au moindre.
    final connu = deLaFiche.isNotEmpty
        ? null
        : VinsConnus.trouver(
            nom: wine.name,
            producteur: wine.producer,
            cuvee: wine.cuveeParcel,
            appellation: wine.appellation,
            region: wine.region,
            pays: wine.country,
            type: wine.type,
          );
    final deLaCuvee = connu != null && connu.cepagesDeLaCuvee ? [for (final c in connu.cepages) _norm(c)] : const <String>[];
    final deLaBase = deLaFiche.isNotEmpty || deLaCuvee.isNotEmpty || dansLeNom.isNotEmpty
        ? const <String>[]
        : [
            for (final c in connu?.cepages ??
                VinsConnus.cepagesPour(
                    nom: wine.name, appellation: wine.appellation, region: wine.region, pays: wine.country, type: wine.type))
              _norm(c),
          ];
    final cepages = deLaFiche.isNotEmpty
        ? deLaFiche
        : deLaCuvee.isNotEmpty
            ? deLaCuvee
            : dansLeNom.isNotEmpty
                ? dansLeNom
                : deLaBase.isNotEmpty
                    ? deLaBase
                    : (WineWorld.region(pays: wine.country, region: wine.region, appellation: appellation)?.cepages ??
                            const <String>[])
                        .map(_norm)
                        .toList();
    // Les cépages d'une cuvée connue se lisent d'abord dans la table de sa couleur : le
    // grenache blanc d'un Châteauneuf blanc n'est pas le grenache d'un rouge.
    final tables = deLaFiche.isNotEmpty
        ? const [_rouges, _blancs]
        : deLaCuvee.isNotEmpty
            ? (couleur == 'red' || couleur == 'rose' ? const [_rouges, _blancs] : const [_blancs, _rouges])
            : deLaCouleur;
    final connus = [
      for (final c in cepages)
        if ([for (final t in tables) ...t.entries].where((e) => c.contains(e.key)).firstOrNull case final e?) e.value,
    ];
    if (connus.isNotEmpty) {
      // Un assemblage pèse chaque cépage à parts égales : sans les proportions, on ne
      // prétend pas savoir lequel domine. Les listes de la base, elles, vont du dominant
      // au moindre : le premier pèse le plus (1, 1/2, 1/3…), et le petit verdot d'un
      // Château Margaux ne compte plus autant que son cabernet.
      final ordonnes = deLaFiche.isEmpty && (deLaCuvee.isNotEmpty || deLaBase.isNotEmpty);
      final rangs = [for (var i = 0; i < connus.length; i++) ordonnes ? 1 / (i + 1) : 1.0];
      final total = rangs.fold(0.0, (s, r) => s + r);
      for (var i = 0; i < connus.length; i++) {
        p.ajouter(connus[i], rangs[i] / total);
      }
    }

    // 2. Le lieu, quand il dit plus que le cépage : un chardonnay de Chablis n'est pas
    // un chardonnay de Meursault.
    final lieu = _norm('${appellation ?? ''} ${wine.subRegion ?? ''} ${wine.region} ${wine.name}');
    for (final e in _parLieu.entries) {
      if (lieu.contains(e.key)) p.ajouter(e.value, 1);
    }

    // 3. L'élevage : celui de la fiche, sinon celui de l'appellation (contenant et durée).
    final duReferentiel = WineWorld.elevage(
      pays: wine.country,
      region: wine.region,
      appellation: appellation,
      nom: wine.name,
      producteur: wine.producer,
      type: wine.type,
      cepages: cepages,
    );
    final deLaFicheContenant = _contenantDeLaFiche(wine);
    final contenant = deLaFicheContenant ?? duReferentiel?.contenant;
    final mois = wine.elevageMois ?? (deLaFicheContenant == null ? duReferentiel?.mois : null);
    if (contenant == ContenantElevage.barrique) {
      p.oak = _max(p.oak, 5.0 + ((mois ?? 12).clamp(0, 24) / 24) * 2.5);
    } else if (contenant == ContenantElevage.foudre) {
      p.oak = _max(p.oak, 3.5);
    } else if (contenant != null && contenant != ContenantElevage.bouteille) {
      p.oak = _min(p.oak, 1.0);
    }

    // 4. Le degré : la chaleur et l'ampleur.
    final degre = wine.alcoholPct;
    if (degre != null) {
      if (degre >= 14.5) {
        p.body += 1.0;
        p.ripeFruit += 0.5;
      } else if (degre >= 13.5) {
        p.body += 0.4;
      } else if (degre <= 12.0) {
        p.body -= 0.7;
        p.acidity += 0.3;
      }
    }

    // 5. L'âge : les tanins se fondent, le fruit cède la place aux notes d'évolution.
    final millesime = wine.vintage;
    if (millesime != null) {
      final age = (annee ?? DateTime.now().year) - millesime;
      if (couleur == 'red') {
        // Les tanins se fondent lentement : un Cornas de sept ans reste ferme.
        if (age >= 15) {
          p.tannin -= 1.5;
          p.freshFruit -= 1.0;
          p.ripeFruit -= 0.5;
          p.spice += 1.0;
        } else if (age >= 10) {
          p.tannin -= 0.8;
          p.freshFruit -= 0.5;
          p.spice += 0.5;
        } else if (age >= 6) {
          p.tannin -= 0.3;
        } else if (age <= 3) {
          p.tannin += 0.5;
        }
      } else if (couleur == 'white' && age >= 8) {
        p.body += 0.5;
        p.freshFruit -= 1.0;
        p.spice += 0.5;
      }
    }

    // 6. La note de dégustation de la fiche : ce qu'elle dit du vin, en français ou en
    // anglais. Un mot ne déplace un axe qu'une fois.
    final note = _norm(wine.tastingNotes ?? '');
    if (note.isNotEmpty) {
      for (final m in _parMot) {
        if (m.mots.any(note.contains)) p.ajouter(m.delta, 1);
      }
    }

    return p.borne();
  }

  static ContenantElevage? _contenantDeLaFiche(Wine wine) {
    final t = _norm('${wine.elevageType ?? ''} ${wine.barrelAging ?? ''}');
    if (t.isEmpty) return null;
    if (t.contains('foudre') || t.contains('demi muid') || t.contains('grand fut')) return ContenantElevage.foudre;
    if (t.contains('barrique') || t.contains('fut') || t.contains('chene') || t.contains('oak') || t.contains('barrel')) {
      return ContenantElevage.barrique;
    }
    if (t.contains('amphore') || t.contains('amphora') || t.contains('jarre')) return ContenantElevage.amphore;
    if (t.contains('oeuf') || t.contains('egg')) return ContenantElevage.oeuf;
    if (t.contains('beton') || t.contains('concrete')) return ContenantElevage.beton;
    if (t.contains('inox') || t.contains('steel') || t.contains('cuve')) return ContenantElevage.inox;
    if (t.contains('bouteille') || t.contains('bottle')) return ContenantElevage.bouteille;
    return null;
  }

  static String _norm(String s) => sansAccents(s).replaceAll('-', ' ');

  /// Des cépages qui sont aussi des lieux : dans un nom, « Vino Nobile di Montepulciano »
  /// est un sangiovese, et « país » se lit sur bien des étiquettes qui n'en contiennent pas.
  static const _lieuxPlutotQueCepages = {'montepulciano', 'pais'};
  static double _max(double a, double b) => a > b ? a : b;
  static double _min(double a, double b) => a < b ? a : b;

  /// Ce qu'un cépage change au profil de sa couleur. Chaque clé est cherchée telle quelle
  /// dans le nom normalisé du cépage ; « cabernet sauvignon » passe avant le « sauvignon »
  /// des blancs parce que les rouges sont lus d'abord.
  static const Map<String, Map<String, double>> _rouges = {
    'syrah': {'spice': 4.0, 'body': 1.0, 'tannin': 1.0, 'ripeFruit': 0.5},
    'shiraz': {'spice': 3.5, 'body': 1.5, 'tannin': 1.0, 'ripeFruit': 1.0},
    'grenache': {'ripeFruit': 1.5, 'body': 1.0, 'spice': 1.5, 'tannin': -0.5, 'acidity': -0.5},
    'garnacha': {'ripeFruit': 1.5, 'body': 1.0, 'spice': 1.5, 'tannin': -0.5, 'acidity': -0.5},
    'mourvedre': {'tannin': 1.5, 'body': 1.0, 'spice': 2.0, 'ripeFruit': 0.5},
    'monastrell': {'tannin': 1.5, 'body': 1.0, 'spice': 2.0, 'ripeFruit': 0.5},
    'pinot noir': {'tannin': -1.5, 'freshFruit': 2.5, 'acidity': 1.3, 'minerality': 1.5, 'body': -1.0},
    'gamay': {'tannin': -2.5, 'freshFruit': 3.0, 'body': -2.0, 'acidity': 1.0},
    'cabernet sauvignon': {'tannin': 1.8, 'body': 1.3, 'ripeFruit': 0.5},
    'merlot': {'tannin': 0.3, 'ripeFruit': 1.5, 'body': 0.8, 'acidity': -0.5},
    'cabernet franc': {'freshFruit': 1.5, 'tannin': 0.5, 'spice': 0.5, 'body': -0.5},
    'nebbiolo': {'tannin': 2.5, 'acidity': 2.0, 'body': 0.5, 'freshFruit': 0.5},
    'sangiovese': {'acidity': 1.5, 'tannin': 1.0, 'freshFruit': 1.0},
    'tempranillo': {'tannin': 0.8, 'body': 0.5, 'ripeFruit': 0.5, 'spice': 0.5},
    'malbec': {'ripeFruit': 2.0, 'body': 1.5, 'tannin': 1.0},
    'cot': {'ripeFruit': 1.5, 'body': 1.5, 'tannin': 1.5},
    'tannat': {'tannin': 3.0, 'body': 1.5},
    'carignan': {'tannin': 1.0, 'spice': 1.0, 'acidity': 0.5},
    'cinsault': {'tannin': -1.5, 'freshFruit': 1.5, 'body': -1.0},
    'zinfandel': {'ripeFruit': 2.5, 'body': 1.5, 'spice': 1.0},
    'primitivo': {'ripeFruit': 2.5, 'body': 1.5, 'spice': 1.0},
    // Les cépages que la base des vins connus apporte (23/10).
    'tinta roriz': {'tannin': 0.8, 'body': 0.5, 'ripeFruit': 0.5, 'spice': 0.5},
    'aragonez': {'tannin': 0.8, 'body': 0.5, 'ripeFruit': 0.5, 'spice': 0.5},
    'tinta de toro': {'tannin': 1.5, 'body': 1.5, 'ripeFruit': 1.0},
    'touriga': {'tannin': 1.5, 'body': 1.5, 'ripeFruit': 1.0, 'spice': 0.5},
    'aglianico': {'tannin': 2.5, 'acidity': 1.5, 'body': 1.0},
    'sagrantino': {'tannin': 3.0, 'body': 1.5},
    'nero d avola': {'ripeFruit': 1.5, 'body': 1.0, 'tannin': 0.5},
    'nerello': {'acidity': 1.5, 'tannin': 1.0, 'freshFruit': 1.0, 'body': -0.5, 'minerality': 1.0},
    'frappato': {'tannin': -2.0, 'freshFruit': 2.5, 'body': -1.5},
    'montepulciano': {'ripeFruit': 1.0, 'tannin': 1.0, 'body': 1.0},
    'corvina': {'acidity': 1.0, 'freshFruit': 1.5, 'tannin': -0.5, 'body': -0.5},
    'barbera': {'acidity': 2.0, 'tannin': -1.0, 'freshFruit': 1.0},
    'dolcetto': {'tannin': 0.3, 'freshFruit': 1.0, 'acidity': -0.5},
    'mencia': {'freshFruit': 1.5, 'acidity': 0.5, 'tannin': -0.3},
    'blaufrankisch': {'acidity': 1.5, 'spice': 1.5, 'freshFruit': 1.0},
    'kekfrankos': {'acidity': 1.5, 'spice': 1.5, 'freshFruit': 1.0},
    'zweigelt': {'tannin': -1.0, 'freshFruit': 2.0, 'body': -0.5},
    'saperavi': {'tannin': 1.5, 'acidity': 1.5, 'body': 1.0, 'ripeFruit': 1.0},
    'pinotage': {'ripeFruit': 1.5, 'body': 1.0, 'tannin': 0.5, 'spice': 0.5},
    'carmenere': {'spice': 1.5, 'ripeFruit': 1.0, 'tannin': 0.5},
    'petit verdot': {'tannin': 2.0, 'body': 1.5, 'spice': 1.0},
    'petite sirah': {'tannin': 2.5, 'body': 2.0, 'ripeFruit': 1.0},
    'xinomavro': {'tannin': 2.5, 'acidity': 2.0, 'freshFruit': 0.5},
    'agiorgitiko': {'ripeFruit': 1.5, 'tannin': 0.3},
    'baga': {'tannin': 2.5, 'acidity': 2.0},
    'alicante bouschet': {'tannin': 1.5, 'body': 1.5, 'ripeFruit': 1.0},
    'trincadeira': {'acidity': 1.0, 'spice': 1.0, 'freshFruit': 0.5},
    'castelao': {'freshFruit': 1.0, 'ripeFruit': 0.5},
    'trousseau': {'tannin': -1.0, 'freshFruit': 1.5, 'body': -0.5, 'acidity': 0.5},
    'poulsard': {'tannin': -2.5, 'freshFruit': 2.0, 'body': -2.0, 'acidity': 0.5},
    'mondeuse': {'spice': 2.0, 'acidity': 1.0, 'freshFruit': 1.0},
    'negrette': {'freshFruit': 1.0, 'spice': 1.0, 'tannin': -0.5},
    'teroldego': {'ripeFruit': 1.0, 'acidity': 1.0},
    'lagrein': {'tannin': 1.0, 'body': 1.0, 'ripeFruit': 1.0},
    'schiava': {'tannin': -2.0, 'body': -1.5, 'freshFruit': 1.5},
    'nielluccio': {'acidity': 1.5, 'tannin': 1.0, 'freshFruit': 1.0},
    'sciaccarellu': {'tannin': -1.0, 'spice': 1.5, 'freshFruit': 1.0, 'body': -0.5},
    'cannonau': {'ripeFruit': 1.5, 'body': 1.0, 'spice': 1.5, 'tannin': -0.5, 'acidity': -0.5},
    'graciano': {'acidity': 1.0, 'tannin': 1.0, 'spice': 0.5},
    'mazuelo': {'tannin': 1.0, 'spice': 1.0, 'acidity': 0.5},
    'bobal': {'tannin': 1.0, 'freshFruit': 1.0, 'acidity': 0.5},
    'listan negro': {'tannin': -0.5, 'spice': 1.0, 'freshFruit': 1.0, 'minerality': 1.0},
    'pais': {'tannin': -0.5, 'freshFruit': 1.0, 'body': -1.0},
  };

  static const Map<String, Map<String, double>> _blancs = {
    'chardonnay': {'body': 1.0, 'ripeFruit': 0.5, 'acidity': -0.5},
    'sauvignon': {'acidity': 1.5, 'freshFruit': 1.0, 'minerality': 1.5},
    // Les cépages aromatiques se vinifient presque toujours sans bois : leur boisé descend
    // sous celui d'un blanc quelconque (un Riesling de Moselle lu boisé à 0,35, 22/10).
    'riesling': {'acidity': 2.0, 'minerality': 2.0, 'freshFruit': 1.0, 'oak': -2.5},
    'chenin': {'acidity': 1.5, 'minerality': 1.0, 'ripeFruit': 0.5},
    'viognier': {'body': 1.5, 'ripeFruit': 2.0, 'acidity': -1.5},
    'gewurztraminer': {'ripeFruit': 2.0, 'spice': 3.0, 'acidity': -2.0, 'body': 1.0, 'oak': -2.5},
    'muscat': {'ripeFruit': 2.0, 'acidity': -2.0, 'oak': -2.5},
    'moscatel': {'ripeFruit': 2.0, 'acidity': -2.0, 'oak': -2.5},
    'moscato': {'ripeFruit': 2.0, 'acidity': -2.0, 'oak': -2.5, 'body': -1.0},
    'albarino': {'acidity': 1.5, 'minerality': 1.5, 'freshFruit': 1.0, 'oak': -2.0},
    'alvarinho': {'acidity': 1.5, 'minerality': 1.5, 'freshFruit': 1.0, 'oak': -2.0},
    'melon': {'acidity': 1.5, 'minerality': 2.0, 'body': -1.0},
    'marsanne': {'body': 1.5, 'ripeFruit': 1.0, 'acidity': -1.0},
    'roussanne': {'body': 1.5, 'ripeFruit': 1.0, 'acidity': -1.0},
    'semillon': {'body': 1.0, 'ripeFruit': 1.0},
    'gruner': {'acidity': 1.0, 'spice': 1.5, 'minerality': 1.0},
    'pinot gris': {'body': 1.0, 'ripeFruit': 1.0, 'acidity': -0.5},
    'savagnin': {'acidity': 1.0, 'minerality': 1.0, 'spice': 0.5},
    'assyrtiko': {'acidity': 2.0, 'minerality': 2.5},
    // Les cépages que la base des vins connus apporte (23/10).
    'grenache blanc': {'body': 1.0, 'ripeFruit': 0.5, 'acidity': -1.0},
    'garnacha blanca': {'body': 1.0, 'ripeFruit': 0.5, 'acidity': -1.0},
    'pinot blanc': {'body': 0.5, 'acidity': -0.5},
    'chasselas': {'acidity': -1.0, 'body': -1.0, 'minerality': 1.0, 'oak': -2.0},
    'petite arvine': {'acidity': 1.5, 'minerality': 1.5, 'ripeFruit': 0.5},
    'vermentino': {'acidity': 0.5, 'freshFruit': 1.0, 'minerality': 1.0},
    'rolle': {'acidity': 0.5, 'freshFruit': 1.0, 'minerality': 1.0},
    'garganega': {'minerality': 1.0, 'freshFruit': 0.5},
    'verdejo': {'acidity': 1.0, 'freshFruit': 1.0},
    'godello': {'body': 0.5, 'minerality': 1.0},
    'furmint': {'acidity': 2.0, 'minerality': 1.5},
    'aligote': {'acidity': 2.0, 'body': -1.0},
    'palomino': {'body': -0.5, 'acidity': -1.0, 'minerality': 1.5},
    'torrontes': {'ripeFruit': 1.5, 'acidity': -1.0, 'oak': -2.0},
    'ugni': {'acidity': 1.0, 'body': -1.0},
    'trebbiano': {'acidity': 1.0, 'body': -1.0},
    'clairette': {'body': 0.5, 'acidity': -0.5},
    'picpoul': {'acidity': 2.0, 'minerality': 1.0},
    'arneis': {'ripeFruit': 0.5, 'acidity': -0.5},
    'cortese': {'acidity': 1.0, 'minerality': 0.5},
    'fiano': {'body': 1.0, 'ripeFruit': 0.5},
    'greco': {'acidity': 1.0, 'minerality': 1.0},
    'carricante': {'acidity': 2.0, 'minerality': 2.0},
    'verdicchio': {'acidity': 1.5, 'minerality': 1.0},
    'friulano': {'body': 0.5},
    'ribolla': {'acidity': 1.0, 'minerality': 0.5},
    'viura': {'acidity': 0.5},
    'macab': {'acidity': 0.5},
    'xarel': {'acidity': 0.5, 'body': 0.5},
    'encruzado': {'body': 1.0, 'minerality': 1.0},
    'arinto': {'acidity': 2.0, 'minerality': 1.0},
    'loureiro': {'acidity': 1.0, 'freshFruit': 1.0, 'body': -1.0},
    'silvaner': {'minerality': 1.0, 'acidity': 0.5, 'body': -0.5},
    'sylvaner': {'minerality': 1.0, 'acidity': 0.5, 'body': -0.5},
    'muller thurgau': {'body': -1.0, 'acidity': -0.5},
    'jacquere': {'acidity': 1.0, 'body': -1.5},
    'altesse': {'acidity': 1.0, 'minerality': 1.0},
    'petit manseng': {'acidity': 2.0, 'ripeFruit': 1.5, 'body': 1.0},
    'gros manseng': {'acidity': 1.5, 'ripeFruit': 1.0},
    'malvasia': {'ripeFruit': 1.5, 'body': 0.5, 'acidity': -0.5},
    'rkatsiteli': {'acidity': 1.5},
    'romorantin': {'acidity': 2.0, 'minerality': 1.0},
    'zibibbo': {'ripeFruit': 2.0, 'acidity': -2.0, 'oak': -2.5},
    'grillo': {'acidity': 0.5, 'freshFruit': 1.0},
    'pecorino': {'acidity': 1.0, 'minerality': 1.0},
    'glera': {'freshFruit': 1.0, 'body': -1.0},
    'bacchus': {'acidity': 1.0, 'freshFruit': 1.5},
  };

  /// Les lieux qui disent plus que leur cépage.
  static const Map<String, Map<String, double>> _parLieu = {
    // Le kimméridgien : le blanc minéral par excellence.
    'chablis': {'minerality': 3.0, 'acidity': 1.0, 'body': -0.5},
    'muscadet': {'minerality': 1.0},
    'mosel': {'minerality': 1.0, 'acidity': 0.5},
    'santorin': {'minerality': 1.5},
    'meursault': {'body': 1.5, 'ripeFruit': 0.5},
    'sancerre': {'minerality': 1.0},
    'pouilly fume': {'minerality': 1.0},
    'pommard': {'tannin': 1.0, 'body': 0.5},
    'volnay': {'tannin': -0.5, 'freshFruit': 0.5},
    'chambolle': {'tannin': -0.5, 'freshFruit': 0.5},
    'gevrey': {'tannin': 0.8, 'body': 0.5},
    'pauillac': {'tannin': 1.0},
    'margaux': {'tannin': -0.3, 'freshFruit': 0.5},
    'pomerol': {'ripeFruit': 1.0, 'tannin': -0.3},
    'chateauneuf': {'body': 1.0, 'ripeFruit': 0.5},
    'cornas': {'tannin': 1.2, 'body': 0.5},
    'hermitage': {'tannin': 0.8, 'body': 0.5},
    'saint joseph': {'tannin': -0.3},
    'cote rotie': {'freshFruit': 0.5, 'spice': 0.5},
    'barolo': {'tannin': 0.5},
    'bandol': {'tannin': 0.5, 'spice': 0.5},
    'madiran': {'tannin': 0.5},
  };

  /// Les mots d'une note de dégustation, en français et en anglais (sans accents).
  static const List<({List<String> mots, Map<String, double> delta})> _parMot = [
    (mots: ['boise', 'vanill', 'toast', 'oaky', 'oak'], delta: {'oak': 1.5}),
    (mots: ['mineral', 'silex', 'craie', 'crayeu', 'pierre a fusil', 'salin', 'iode', 'flint', 'chalk'], delta: {'minerality': 1.5}),
    (mots: ['tanins fermes', 'tanins serres', 'tannique', 'charpent', 'firm tannin', 'grippy'], delta: {'tannin': 1.0}),
    (mots: ['souple', 'soyeu', 'tanins fondus', 'velout', 'silky', 'supple'], delta: {'tannin': -1.0}),
    (mots: ['fruits noirs', 'cassis', 'mure', 'confitur', 'black fruit', 'blackberry', 'blackcurrant'], delta: {'ripeFruit': 1.0}),
    (mots: ['fruits rouges', 'cerise', 'framboise', 'groseille', 'red fruit', 'cherry', 'raspberry'], delta: {'freshFruit': 1.0}),
    (mots: ['agrume', 'citron', 'vif', 'tendu', 'tension', 'citrus', 'lemon', 'crisp'], delta: {'acidity': 1.0}),
    (mots: ['epice', 'poivre', 'reglisse', 'garrigue', 'spice', 'pepper', 'licorice'], delta: {'spice': 1.0}),
    (mots: ['ample', 'opulent', 'puissant', 'concentr', 'full bodied', 'rich'], delta: {'body': 1.0}),
    (mots: ['leger', 'delicat', 'light bodied', 'delicate'], delta: {'body': -0.7}),
  ];
}

/// Un profil qu'on déplace, axe par axe, avant de le borner.
class _Axes {
  double tannin, body, oak, ripeFruit, spice, freshFruit, minerality, acidity;

  _Axes(this.tannin, this.body, this.oak, this.ripeFruit, this.spice, this.freshFruit, this.minerality, this.acidity);

  /// Le point de départ de chaque couleur ; un type inconnu garde le milieu.
  factory _Axes.pourLaCouleur(String couleur) => switch (couleur) {
        'red' => _Axes(6.0, 6.5, 3.0, 6.5, 3.0, 5.0, 5.0, 5.5),
        'white' => _Axes(0.5, 4.5, 3.0, 5.0, 3.0, 7.0, 5.0, 7.0),
        'rose' => _Axes(1.0, 4.0, 1.5, 5.0, 2.5, 7.5, 5.5, 6.5),
        'sparkling' => _Axes(0.5, 4.0, 3.0, 5.0, 3.0, 7.2, 8.0, 8.5),
        'dessert' => _Axes(0.5, 7.0, 3.0, 8.0, 4.0, 4.0, 4.5, 6.5),
        _ => _Axes(3.0, 5.0, 3.0, 5.0, 3.0, 6.0, 5.0, 5.5),
      };

  void ajouter(Map<String, double> delta, double poids) {
    for (final e in delta.entries) {
      final d = e.value * poids;
      switch (e.key) {
        case 'tannin':
          tannin += d;
        case 'body':
          body += d;
        case 'oak':
          oak += d;
        case 'ripeFruit':
          ripeFruit += d;
        case 'spice':
          spice += d;
        case 'freshFruit':
          freshFruit += d;
        case 'minerality':
          minerality += d;
        case 'acidity':
          acidity += d;
      }
    }
  }

  WineTasteRadarMetrics borne() {
    double b(double v) => v.clamp(0.0, 10.0);
    return WineTasteRadarMetrics(
      tannin: b(tannin),
      body: b(body),
      oak: b(oak),
      ripeFruit: b(ripeFruit),
      spice: b(spice),
      freshFruit: b(freshFruit),
      minerality: b(minerality),
      acidity: b(acidity),
    );
  }
}
