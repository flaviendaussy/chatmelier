import 'dart:math' as math;

import '../../../shared/utils/langue.dart';
import '../../auth/domain/palais.dart';
import '../../sommelier/domain/profil_du_vin.dart';
import 'vins_connus/vins_connus.dart';
import 'wine.dart';

/// Les grands styles de vin (23/10) : de quoi dire qu'une cave n'a « que du rouge
/// méditerranéen » et qu'un vin jaune, un porto ou un riesling de Moselle en seraient très
/// loin.
///
/// Flavien, 23/10 : « Opportunités de cave : c'est pour proposer des types de vins très
/// différents de ceux que l'utilisateur a ». La couleur ne suffisait pas (« 70 % de
/// rouges ») : un Bandol et un Beaujolais sont deux rouges, et ne se ressemblent en rien.
///
/// Chaque style a une place sur neuf dimensions (sur 10) : les six axes du palais, plus
/// l'aromatique, la bulle et l'oxydation, qui séparent un vin jaune d'un blanc de Loire ou
/// un champagne d'un chablis bien mieux que l'acidité. Les distances entre styles se
/// mesurent là.
class StyleDeVin {
  final String id;

  /// 'red', 'white', 'rose', 'orange', 'sparkling', 'sweet', 'fortified'.
  final String couleur;

  /// Les neuf dimensions, sur 10 : [AxesDuPalais] et 'aromatic', 'bubbles', 'oxidative'.
  final Map<String, double> axes;

  /// Les appellations de la base des vins connus ([AppellationConnue.nom]) qui en relèvent,
  /// pour la couleur du style.
  final Set<String> appellations;

  /// Les cépages qui le désignent quand ils dominent un vin (le premier de sa liste).
  final Set<String> cepages;

  /// Des mots du nom ou de l'appellation qui le désignent à eux seuls (« vin jaune »,
  /// « amarone », « ripasso »), sans accents, en minuscules.
  final Set<String> mots;

  /// Trois vins de la base qui l'incarnent : (nom, domaine).
  final List<(String, String?)> exemples;

  const StyleDeVin(
    this.id,
    this.couleur, {
    required this.axes,
    this.appellations = const {},
    this.cepages = const {},
    this.mots = const {},
    required this.exemples,
  });

  /// Les styles singuliers — voile, macération, mutage, liqueur, bulles sucrées, raisins
  /// séchés : une proposition sur trois au plus, sans quoi une cave classique ne recevait
  /// que des curiosités (vin jaune, porto, vin orange) et aucun grand vin de table.
  bool get singulier => const {'blanc_voile', 'vin_orange', 'vin_mute', 'liquoreux', 'bulles_fruitees', 'rouge_amarone'}.contains(id);

  static const aromatique = 'aromatic';
  static const bulles = 'bubbles';
  static const oxydatif = 'oxidative';

  /// La famille du palais qu'il renseigne ; nulle pour un muté.
  String? get famille => switch (couleur) {
        'red' => FamillesDeVins.rouge,
        'fortified' => null,
        _ => FamillesDeVins.blanc,
      };

  /// La couleur telle qu'on la regroupe à l'écran.
  String get groupe => switch (couleur) {
        'red' => 'red',
        'white' || 'orange' => 'white',
        'rose' => 'rose',
        'sparkling' => 'sparkling',
        _ => 'sweet',
      };

  String get nom => switch (id) {
        'rouge_leger' => tr('Rouge léger et fruité', 'Light, fruity red'),
        'rouge_pinot' => tr('Pinot noir, rouge de finesse', 'Pinot noir, a red of finesse'),
        'rouge_loire' => tr('Cabernet franc de Loire', 'Loire cabernet franc'),
        'rouge_syrah_nord' => tr('Syrah du Rhône nord', 'Northern Rhône syrah'),
        'rouge_mediterraneen' => tr('Rouge solaire (grenache)', 'Sun-drenched red (grenache)'),
        'rouge_garrigue' => tr('Rouge de garrigue (mourvèdre)', 'Garrigue red (mourvèdre)'),
        'rouge_bordelais' => tr('Rouge de cabernet, structuré', 'Structured cabernet red'),
        'rouge_merlot' => tr('Rouge rond (merlot)', 'Round red (merlot)'),
        'rouge_nebbiolo' => tr('Rouge de grande garde (nebbiolo)', 'Long-lived red (nebbiolo)'),
        'rouge_toscan' => tr('Rouge italien acidulé (sangiovese)', 'Tangy Italian red (sangiovese)'),
        'rouge_tempranillo' => tr('Rouge espagnol (tempranillo)', 'Spanish red (tempranillo)'),
        'rouge_puissant' => tr('Rouge opulent du Nouveau Monde', 'Opulent New World red'),
        'rouge_amarone' => tr('Rouge de raisins séchés (amarone)', 'Dried-grape red (amarone)'),
        'rouge_tannat' => tr('Rouge noir et tannique (tannat, Cahors)', 'Dark, tannic red (tannat, Cahors)'),
        'rouge_evolue' => tr('Rouge patiné par l\'âge', 'Aged, mature red'),
        'blanc_vif' => tr('Blanc vif et minéral', 'Crisp, mineral white'),
        'blanc_aromatique' => tr('Blanc aromatique', 'Aromatic white'),
        'blanc_riesling' => tr('Riesling', 'Riesling'),
        'blanc_chenin' => tr('Chenin de Loire', 'Loire chenin'),
        'blanc_boise' => tr('Blanc ample et boisé', 'Rich, oaked white'),
        'blanc_rhone' => tr('Blanc solaire (viognier, marsanne)', 'Sun-drenched white (viognier, marsanne)'),
        'blanc_voile' => tr('Vin de voile (vin jaune, fino)', 'Flor-aged wine (vin jaune, fino)'),
        'vin_orange' => tr('Vin orange', 'Orange wine'),
        'rose_pale' => tr('Rosé pâle de Provence', 'Pale Provence rosé'),
        'rose_gastronomique' => tr('Rosé de gastronomie (Bandol, Tavel)', 'Food rosé (Bandol, Tavel)'),
        'bulles_tradition' => tr('Bulles de méthode traditionnelle', 'Traditional-method sparkling'),
        'bulles_fruitees' => tr('Bulles légères (prosecco, moscato)', 'Light sparkling (prosecco, moscato)'),
        'liquoreux' => tr('Liquoreux', 'Botrytised sweet wine'),
        'vin_mute' => tr('Vin muté (porto, banyuls)', 'Fortified wine (port, banyuls)'),
        _ => id,
      };

  /// Ce qu'il a de singulier, en une phrase.
  String get portrait => switch (id) {
        'rouge_leger' => tr('Peu de tanins, beaucoup de fruit, il se boit frais.', 'Low tannin, plenty of fruit, served cool.'),
        'rouge_pinot' => tr('Tout en finesse : fruits rouges, sous-bois, tanins de soie.', 'All finesse: red fruit, forest floor, silky tannins.'),
        'rouge_loire' => tr('Fruits rouges croquants, notes de graphite et de poivron, fraîcheur.', 'Crunchy red fruit, graphite and leafy notes, freshness.'),
        'rouge_syrah_nord' => tr('Poivre, violette, olive noire : de la tension malgré la puissance.', 'Pepper, violet, black olive: tension despite the power.'),
        'rouge_mediterraneen' => tr('Généreux et chaleureux : fruits mûrs, épices douces, tanins arrondis.', 'Generous and warm: ripe fruit, sweet spice, rounded tannins.'),
        'rouge_garrigue' => tr('Garrigue, cuir, tanins fermes : des vins de caractère qui gagnent à attendre.', 'Garrigue, leather, firm tannins: characterful wines that reward patience.'),
        'rouge_bordelais' => tr('Cassis, cèdre, tanins serrés : la charpente du cabernet, bâtie pour la garde.', 'Blackcurrant, cedar, tight tannins: cabernet structure built to age.'),
        'rouge_merlot' => tr('Rond et velouté : prune, chocolat, tanins fondus.', 'Round and velvety: plum, chocolate, soft tannins.'),
        'rouge_nebbiolo' => tr('Robe claire mais tanins puissants et grande acidité : rose, goudron, cerise.', 'Pale colour but powerful tannins and high acidity: rose, tar, cherry.'),
        'rouge_toscan' => tr('Cerise acidulée, herbes sèches, une acidité faite pour la table.', 'Sour cherry, dried herbs, an acidity made for food.'),
        'rouge_tempranillo' => tr('Fruits rouges, vanille et cuir : souvent un long élevage en fût.', 'Red fruit, vanilla and leather: often a long time in barrel.'),
        'rouge_puissant' => tr('Très mûr, très concentré : fruits noirs, chocolat, alcool généreux.', 'Very ripe and concentrated: black fruit, chocolate, generous alcohol.'),
        'rouge_amarone' => tr('Des raisins séchés avant d\'être pressés : figue, cerise confite, ampleur immense.', 'Grapes dried before pressing: fig, candied cherry, huge body.'),
        'rouge_tannat' => tr('Noir, tannique, profond : parmi les rouges les plus charpentés qui soient.', 'Dark, tannic, deep: among the most structured reds there are.'),
        'rouge_evolue' => tr('Au bout de sa garde : sous-bois, truffe, cuir — le temps a pris la place du fruit.', 'At the end of its ageing: forest floor, truffle, leather — time has taken the place of fruit.'),
        'blanc_vif' => tr('Tranchant, salin, sans bois : agrumes et coquillages.', 'Sharp, saline, unoaked: citrus and shellfish.'),
        'blanc_aromatique' => tr('Le nez explose : fruits exotiques, rose, litchi, buis.', 'An explosive nose: tropical fruit, rose, lychee, boxwood.'),
        'blanc_riesling' => tr('Acidité vive, souvent une pointe de sucre ; il vieillit vers des notes pétrolées.', 'Racy acidity, often a touch of sweetness; it ages towards petrol notes.'),
        'blanc_chenin' => tr('Coing, miel, acidité sans fin : du sec au moelleux, il traverse les décennies.', 'Quince, honey, endless acidity: dry to sweet, it lasts for decades.'),
        'blanc_boise' => tr('Beurre, noisette, vanille : un blanc ample élevé en fût.', 'Butter, hazelnut, vanilla: a full white aged in barrel.'),
        'blanc_rhone' => tr('Abricot, fleurs blanches, peu d\'acidité : un blanc solaire et onctueux.', 'Apricot, white flowers, low acidity: a sunny, unctuous white.'),
        'blanc_voile' => tr('Élevé sous un voile de levures : noix, curry, épices — rien d\'autre ne lui ressemble.', 'Aged under a veil of yeast: walnut, curry, spice — nothing else tastes like it.'),
        'vin_orange' => tr('Un blanc vinifié comme un rouge : tanins, écorce d\'orange, thé.', 'A white made like a red: tannin, orange peel, tea.'),
        'rose_pale' => tr('Pâle, sec et frais : l\'apéritif d\'été.', 'Pale, dry and fresh: the summer aperitif.'),
        'rose_gastronomique' => tr('Un rosé de repas : couleur soutenue, du corps, il tient tête à la cuisine.', 'A rosé for food: deeper colour, more body, it stands up to cooking.'),
        'bulles_tradition' => tr('Fines bulles, brioche, craie : la seconde fermentation en bouteille.', 'Fine bubbles, brioche, chalk: second fermentation in the bottle.'),
        'bulles_fruitees' => tr('Bulles légères, fruit frais, parfois une douceur : la fête sans façons.', 'Light bubbles, fresh fruit, sometimes a touch of sweetness: easy celebration.'),
        'liquoreux' => tr('Sucre et acidité en équilibre : abricot confit, miel, safran.', 'Sugar and acidity in balance: candied apricot, honey, saffron.'),
        'vin_mute' => tr('L\'alcool ajouté garde le sucre du raisin : cacao, fruits secs, une garde presque sans fin.', 'Added spirit keeps the grape\'s sugar: cocoa, dried fruit, almost endless ageing.'),
        _ => '',
      };

  /// La distance entre deux styles : les neuf dimensions, pondérées, et la couleur.
  double distance(StyleDeVin autre) {
    var somme = 0.0;
    for (final e in _poids.entries) {
      final d = (axes[e.key] ?? 0) - (autre.axes[e.key] ?? 0);
      somme += e.value * d * d;
    }
    final c = _ecartDeCouleur(couleur, autre.couleur);
    return math.sqrt(somme + c * c);
  }

  static const _poids = {
    AxesDuPalais.fraicheur: 1.0,
    AxesDuPalais.douceur: 1.2,
    AxesDuPalais.corps: 1.0,
    AxesDuPalais.tanins: 1.0,
    AxesDuPalais.boise: 0.8,
    AxesDuPalais.evolution: 0.8,
    aromatique: 0.6,
    bulles: 1.2,
    oxydatif: 1.0,
  };

  /// La couleur sépare ce que les axes ne séparent pas : un rosé et un blanc de même
  /// corps ne se boivent pas de la même façon. Les bulles, le sucre et le mutage ont leurs
  /// propres dimensions.
  static double _ecartDeCouleur(String a, String b) {
    String t(String c) => c == 'orange' ? 'white' : c;
    final x = t(a);
    final y = t(b);
    if (x == y) return a == b ? 0 : 1.0;
    const teintes = {'red', 'white', 'rose'};
    if (!teintes.contains(x) || !teintes.contains(y)) return 0;
    if ({x, y}.containsAll(const {'red', 'white'})) return 3.0;
    if ({x, y}.containsAll(const {'red', 'rose'})) return 2.0;
    return 1.5;
  }
}

/// Les styles, et le classement d'une bouteille parmi eux.
class StylesDeVin {
  StylesDeVin._();

  static const List<StyleDeVin> tous = [
    // ─────────── Rouges ───────────
    StyleDeVin('rouge_leger', 'red',
        axes: {'acidity': 6.5, 'sweetness': 0.5, 'body': 3.5, 'tannin': 3, 'oak': 1, 'evolution': 2, 'aromatic': 5},
        appellations: {'Morgon', 'Fleurie', 'Moulin-à-Vent', 'Côte de Brouilly', 'Crus du Beaujolais', 'Beaujolais', 'Bardolino', 'Valpolicella', 'Bourgogne Passetoutgrains'},
        cepages: {Cep.gamay, Cep.poulsard, Cep.trousseau, Cep.frappato, Cep.schiava, Cep.zweigelt, Cep.pais, Cep.cinsault, Cep.grolleau, Cep.pineauDAunis},
        exemples: [('Marcel Lapierre', null), ('Château Thivin', null), ('Clos de la Roilette', null)]),
    StyleDeVin('rouge_pinot', 'red',
        axes: {'acidity': 6.5, 'sweetness': 0.5, 'body': 4.5, 'tannin': 4, 'oak': 3.5, 'evolution': 3, 'aromatic': 5},
        appellations: {
          'Marsannay', 'Fixin', 'Gevrey-Chambertin', 'Morey-Saint-Denis', 'Chambolle-Musigny', 'Vougeot', 'Vosne-Romanée',
          'Nuits-Saint-Georges', 'Côte de Nuits-Villages', 'Hautes-Côtes de Nuits', 'Corton', 'Pernand-Vergelesses',
          'Savigny-lès-Beaune', 'Chorey-lès-Beaune', 'Beaune', 'Pommard', 'Volnay', 'Monthelie', 'Santenay', 'Mercurey',
          'Bourgogne', 'Irancy', 'Sancerre', 'Menetou-Salon', 'Central Otago', 'Martinborough', 'Willamette Valley', 'Baden',
          'Hemel-en-Aarde', 'Patagonie',
        },
        cepages: {Cep.pn},
        exemples: [('Domaine Michel Lafarge', null), ('Felton Road', null), ('Domaine Drouhin Oregon', null)]),
    StyleDeVin('rouge_loire', 'red',
        axes: {'acidity': 7, 'sweetness': 0.5, 'body': 4.5, 'tannin': 5.5, 'oak': 2, 'evolution': 3, 'aromatic': 4},
        appellations: {'Chinon', 'Bourgueil', 'Saumur-Champigny', 'Saumur', 'Anjou', 'Touraine'},
        exemples: [('Charles Joguet', null), ('Château Yvonne', null), ('Catherine et Pierre Breton', null)]),
    StyleDeVin('rouge_syrah_nord', 'red',
        axes: {'acidity': 6, 'sweetness': 0.5, 'body': 6, 'tannin': 6.5, 'oak': 4, 'evolution': 3, 'aromatic': 6},
        appellations: {'Côte-Rôtie', 'Cornas', 'Saint-Joseph', 'Crozes-Hermitage', 'Hermitage', 'Collines Rhodaniennes', 'Vin de Savoie'},
        cepages: {Cep.syrah, Cep.mondeuse},
        exemples: [('Domaine Alain Graillot', null), ('Domaine Gonon', null), ('Domaine Auguste Clape', null)]),
    StyleDeVin('rouge_mediterraneen', 'red',
        axes: {'acidity': 4.5, 'sweetness': 0.5, 'body': 7.5, 'tannin': 5.5, 'oak': 3, 'evolution': 3, 'aromatic': 5},
        appellations: {
          'Châteauneuf-du-Pape', 'Gigondas', 'Vacqueyras', 'Rasteau', 'Cairanne', 'Beaumes-de-Venise', 'Vinsobres', 'Lirac',
          'Côtes du Rhône', 'Costières de Nîmes', 'Duché d\'Uzès', 'Côtes du Roussillon', 'Languedoc', 'Cannonau di Sardegna',
          'Campo de Borja', 'Vinos de Madrid', 'Navarra', 'Priorat', 'Montsant', 'Sicilia', "Montepulciano d'Abruzzo", 'Vin de Corse',
        },
        cepages: {Cep.grenache, Cep.garnacha, Cep.cannonau, Cep.nerodAvola, Cep.montepulciano},
        exemples: [('Domaine du Vieux Télégraphe', null), ('Domaine Santa Duc', null), ('Coudoulet de Beaucastel', null)]),
    StyleDeVin('rouge_garrigue', 'red',
        axes: {'acidity': 5, 'sweetness': 0.5, 'body': 7, 'tannin': 7.5, 'oak': 3.5, 'evolution': 3.5, 'aromatic': 5},
        appellations: {
          'Bandol', 'Pic Saint-Loup', 'Terrasses du Larzac', 'Faugères', 'Saint-Chinian', 'Minervois', 'Corbières', 'La Clape',
          'Collioure', 'Jumilla', 'Palette', 'Les Baux-de-Provence', 'Provence (IGP)', 'Côtes de Provence', "Pays d'Hérault",
          'Coteaux d\'Aix-en-Provence',
        },
        cepages: {Cep.mourvedre, Cep.monastrell, Cep.carignan, Cep.mataro},
        exemples: [('Domaine Tempier', null), ("Domaine de l'Hortus", null), ('Domaine Léon Barral', null)]),
    StyleDeVin('rouge_bordelais', 'red',
        axes: {'acidity': 5.5, 'sweetness': 0.5, 'body': 7, 'tannin': 7.5, 'oak': 6, 'evolution': 4, 'aromatic': 4},
        appellations: {
          'Pauillac', 'Margaux', 'Saint-Julien', 'Saint-Estèphe', 'Haut-Médoc', 'Médoc', 'Moulis-en-Médoc', 'Listrac-Médoc',
          'Pessac-Léognan', 'Graves', 'Napa Valley', 'Washington', 'Coonawarra', 'Margaret River', 'Bolgheri', 'Valle Central',
          'Aconcagua', 'Stellenbosch', "Hawke's Bay", 'Bekaa', 'Santa Cruz Mountains',
        },
        cepages: {Cep.cs, Cep.carmenere},
        exemples: [('Château Lynch-Bages', null), ('Château Sociando-Mallet', null), ('Don Melchor', null)]),
    StyleDeVin('rouge_merlot', 'red',
        axes: {'acidity': 4.5, 'sweetness': 0.5, 'body': 7, 'tannin': 5.5, 'oak': 5, 'evolution': 3.5, 'aromatic': 4},
        appellations: {'Saint-Émilion', 'Satellites de Saint-Émilion', 'Pomerol', 'Lalande-de-Pomerol', 'Fronsac', 'Côtes de Bordeaux', 'Bordeaux', 'Bergerac', 'Buzet', 'Ticino'},
        cepages: {Cep.merlot},
        exemples: [('Château Gazin', null), ('Château La Fleur de Boüard', null), ("Château d'Aiguilhe", null)]),
    StyleDeVin('rouge_nebbiolo', 'red',
        axes: {'acidity': 8, 'sweetness': 0.5, 'body': 6, 'tannin': 9, 'oak': 4, 'evolution': 4.5, 'aromatic': 6},
        appellations: {'Barolo', 'Barbaresco', 'Langhe', 'Gattinara', 'Valtellina', 'Naoussa', 'Taurasi', 'Aglianico del Vulture', 'Bairrada'},
        cepages: {Cep.nebbiolo, Cep.xinomavro, Cep.aglianico, Cep.baga},
        exemples: [('Produttori del Barbaresco', null), ('G.D. Vajra', null), ('Thymiopoulos', null)]),
    StyleDeVin('rouge_toscan', 'red',
        axes: {'acidity': 7.5, 'sweetness': 0.5, 'body': 6, 'tannin': 6.5, 'oak': 4, 'evolution': 3.5, 'aromatic': 5},
        appellations: {
          'Chianti Classico', 'Chianti', 'Brunello di Montalcino', 'Vino Nobile di Montepulciano', 'Morellino di Scansano',
          'Carmignano', 'Patrimonio', "Barbera d'Alba", "Dolcetto d'Alba", 'Toscana',
        },
        cepages: {Cep.sangiovese, Cep.nielluccio, Cep.barbera, Cep.dolcetto},
        exemples: [('Fèlsina', null), ('Il Poggione', null), ('Fontodi', null)]),
    StyleDeVin('rouge_tempranillo', 'red',
        axes: {'acidity': 5.5, 'sweetness': 0.5, 'body': 6.5, 'tannin': 6, 'oak': 7, 'evolution': 5.5, 'aromatic': 4, 'oxidative': 0.5},
        appellations: {'Rioja', 'Ribera del Duero', 'Toro', 'La Mancha', 'Castilla y León'},
        cepages: {Cep.tempranillo, Cep.tintaDeToro},
        exemples: [('Viña Ardanza', null), ('Viña Tondonia', null), ('Tinto Pesquera', null)]),
    StyleDeVin('rouge_puissant', 'red',
        axes: {'acidity': 4, 'sweetness': 1, 'body': 8.5, 'tannin': 7, 'oak': 6, 'evolution': 2.5, 'aromatic': 5},
        appellations: {
          'Mendoza', 'Salta', 'Barossa', 'McLaren Vale', 'Primitivo di Manduria', 'Salice Salentino', 'Californie', 'Douro',
          'Alentejo', 'Western Cape', 'South Eastern Australia', 'Sonoma', 'Central Coast',
        },
        cepages: {Cep.malbec, Cep.shiraz, Cep.zinfandel, Cep.primitivo, Cep.pinotage, Cep.tourigaNacional, Cep.petiteSirah, Cep.negroamaro},
        exemples: [('Catena Zapata', null), ('Torbreck', null), ('Lytton Springs', 'Ridge')]),
    StyleDeVin('rouge_amarone', 'red',
        axes: {'acidity': 5, 'sweetness': 1.5, 'body': 9, 'tannin': 6.5, 'oak': 5, 'evolution': 4.5, 'aromatic': 6, 'oxidative': 1},
        appellations: {'Amarone della Valpolicella'},
        mots: {'amarone', 'ripasso', 'ripassa'},
        exemples: [('Costasera', 'Masi'), ('Allegrini', null), ('Bertani', null)]),
    StyleDeVin('rouge_tannat', 'red',
        axes: {'acidity': 5.5, 'sweetness': 0.5, 'body': 8, 'tannin': 9, 'oak': 5.5, 'evolution': 3.5, 'aromatic': 3},
        appellations: {'Madiran', 'Cahors', 'Irouléguy', 'Saint-Mont', 'Uruguay', 'Montefalco Sagrantino', 'Marcillac', 'Fronton'},
        cepages: {Cep.tannat, Cep.sagrantino, Cep.ferServadou},
        exemples: [('Château Montus', null), ('Château du Cèdre', null), ('Bodega Garzón', null)]),
    StyleDeVin('rouge_evolue', 'red',
        axes: {'acidity': 5.5, 'sweetness': 0.5, 'body': 5.5, 'tannin': 4, 'oak': 4, 'evolution': 9, 'aromatic': 6, 'oxidative': 2},
        exemples: [('Viña Tondonia', null), ('Château Musar', null), ('Gran Reserva 904', null)]),

    // ─────────── Blancs ───────────
    StyleDeVin('blanc_vif', 'white',
        axes: {'acidity': 8, 'sweetness': 0.5, 'body': 3.5, 'oak': 1, 'evolution': 2, 'aromatic': 4},
        appellations: {
          'Chablis', 'Petit Chablis', 'Muscadet', 'Sancerre', 'Pouilly-Fumé', 'Menetou-Salon', 'Pouilly-sur-Loire', 'Touraine',
          'Entre-Deux-Mers', 'Picpoul de Pinet', 'Rías Baixas', 'Txakoli', 'Vinho Verde', 'Santorin', 'Gavi', 'Etna',
          'Verdicchio', 'Vernaccia di San Gimignano', 'Vin de Savoie', 'Roussette de Savoie', 'Saint-Bris', 'Bourgogne Aligoté',
          'Bouzeron', 'Cassis', 'Bellet', 'Lugana', 'Soave', 'Kamptal', 'Wachau', 'Steiermark', 'Valais', 'Vaud', 'Rueda',
          'Casablanca', 'Patrimonio', 'Vermentino di Gallura', 'Côtes de Gascogne', 'Ribeiro', 'Österreich', 'Saint-Pourçain',
        },
        cepages: {
          Cep.melon, Cep.aligote, Cep.albarino, Cep.alvarinho, Cep.assyrtiko, Cep.picpoul, Cep.chasselas, Cep.gruner,
          Cep.verdejo, Cep.vermentino, Cep.rolle, Cep.cortese, Cep.garganega, Cep.verdicchio, Cep.jacquere, Cep.loureiro,
          Cep.arinto, Cep.ugni, Cep.colombard, Cep.sb, Cep.carricante, Cep.petiteArvine, Cep.godello, Cep.sylvaner, Cep.silvaner,
          Cep.viura, Cep.macabeo, Cep.trebbiano, Cep.clairette,
        },
        exemples: [('Domaine William Fèvre', null), ("Domaine de l'Écu", null), ('Sigalas', null)]),
    StyleDeVin('blanc_aromatique', 'white',
        axes: {'acidity': 5.5, 'sweetness': 1.5, 'body': 5, 'oak': 1, 'evolution': 1.5, 'aromatic': 9},
        appellations: {'Marlborough', 'Salta'},
        cepages: {Cep.gewurz, Cep.muscat, Cep.muscatPetitsGrains, Cep.moscatel, Cep.torrontes, Cep.malvasia, Cep.moschofilero, Cep.malagousia, Cep.scheurebe, Cep.bacchus, Cep.zibibbo},
        exemples: [('Cloudy Bay', null), ('Colomé', null), ('Nussbaumer', 'Tramin')]),
    StyleDeVin('blanc_riesling', 'white',
        axes: {'acidity': 9, 'sweetness': 2.5, 'body': 3.5, 'oak': 0.5, 'evolution': 3, 'aromatic': 7},
        appellations: {'Mosel', 'Rheingau', 'Nahe', 'Pfalz', 'Rheinhessen', 'Clare Valley', 'Finger Lakes'},
        cepages: {Cep.riesling},
        exemples: [('Dr. Loosen', null), ('Cuvée Frédéric Émile', 'Trimbach'), ('Polish Hill', 'Grosset')]),
    StyleDeVin('blanc_chenin', 'white',
        axes: {'acidity': 8.5, 'sweetness': 2, 'body': 5.5, 'oak': 2, 'evolution': 3, 'aromatic': 5, 'oxidative': 0.5},
        appellations: {'Vouvray', 'Montlouis-sur-Loire', 'Savennières', 'Jasnières', 'Cour-Cheverny'},
        cepages: {Cep.chenin, Cep.romorantin},
        exemples: [('Domaine Huet', null), ('Domaine François Chidaine', null), ('Domaine du Closel', null)]),
    StyleDeVin('blanc_boise', 'white',
        axes: {'acidity': 5.5, 'sweetness': 0.5, 'body': 7.5, 'oak': 7, 'evolution': 3, 'aromatic': 4},
        appellations: {
          'Meursault', 'Puligny-Montrachet', 'Chassagne-Montrachet', 'Corton-Charlemagne', 'Saint-Aubin', 'Pessac-Léognan',
          'Graves', 'Napa Valley', 'Sonoma', 'Margaret River', 'Pouilly-Fuissé',
        },
        exemples: [('Château de Meursault', null), ('Domaine de Chevalier', null), ('Art Series Chardonnay', 'Leeuwin')]),
    StyleDeVin('blanc_rhone', 'white',
        axes: {'acidity': 4, 'sweetness': 0.5, 'body': 7.5, 'oak': 3, 'evolution': 3, 'aromatic': 7},
        appellations: {
          'Condrieu', 'Château-Grillet', 'Saint-Péray', 'Hermitage', 'Crozes-Hermitage', 'Saint-Joseph', 'Châteauneuf-du-Pape',
          'Côtes du Rhône', 'Languedoc', 'Côtes du Roussillon', 'Chignin-Bergeron', 'Collines Rhodaniennes', 'Duché d\'Uzès',
          'La Clape', 'Lirac', 'Vinsobres', 'Costières de Nîmes', "Pays d'Hérault",
        },
        cepages: {Cep.viognier, Cep.marsanne, Cep.roussanne, Cep.grenacheBlanc, Cep.garnachaBlanca, Cep.fiano, Cep.encruzado},
        exemples: [('Domaine Georges Vernay', null), ('Chante-Alouette', 'Chapoutier'), ('Château de Beaucastel', null)]),
    StyleDeVin('blanc_voile', 'white',
        axes: {'acidity': 6.5, 'sweetness': 0.5, 'body': 6, 'oak': 2, 'evolution': 7, 'aromatic': 6, 'oxidative': 10},
        appellations: {'Château-Chalon'},
        mots: {'vin jaune', 'fino', 'manzanilla', 'amontillado', 'palo cortado', 'oloroso', 'sous voile'},
        exemples: [('Jean Macle', null), ('Tío Pepe', null), ('La Gitana', null)]),
    StyleDeVin('vin_orange', 'orange',
        axes: {'acidity': 6, 'sweetness': 0.5, 'body': 6.5, 'tannin': 4, 'oak': 2, 'evolution': 4, 'aromatic': 6, 'oxidative': 5},
        mots: {'orange wine', 'vin orange', 'qvevri', 'kvevri', 'ramato', 'skin contact', 'macere', 'maceration'},
        exemples: [('Gravner', null), ('Radikon', null), ("Pheasant's Tears", null)]),

    // ─────────── Rosés ───────────
    StyleDeVin('rose_pale', 'rose',
        axes: {'acidity': 6.5, 'sweetness': 0.5, 'body': 3.5, 'tannin': 0.5, 'oak': 0.5, 'evolution': 1.5, 'aromatic': 4},
        appellations: {'Côtes de Provence', 'Coteaux d\'Aix-en-Provence', 'Provence (IGP)', 'Languedoc', 'Pic Saint-Loup', 'Bordeaux', 'Vinsobres', 'Costières de Nîmes'},
        exemples: [('Whispering Angel', null), ('Château Minuty', null), ('Miraval', null)]),
    StyleDeVin('rose_gastronomique', 'rose',
        axes: {'acidity': 5.5, 'sweetness': 0.5, 'body': 6, 'tannin': 2, 'oak': 1.5, 'evolution': 2.5, 'aromatic': 4},
        appellations: {'Bandol', 'Tavel', 'Palette', "Montepulciano d'Abruzzo", 'Rioja', 'Navarra'},
        mots: {'clairet', 'cerasuolo'},
        exemples: [('Domaine Tempier', null), ("Château d'Aqueria", null), ('Clos Cibonne', null)]),

    // ─────────── Bulles ───────────
    StyleDeVin('bulles_tradition', 'sparkling',
        axes: {'acidity': 8.5, 'sweetness': 1, 'body': 4, 'oak': 1.5, 'evolution': 3.5, 'aromatic': 4, 'bubbles': 10, 'oxidative': 1},
        exemples: [('Pol Roger', null), ('Larmandier-Bernier', null), ('Nyetimber', null)]),
    StyleDeVin('bulles_fruitees', 'sparkling',
        axes: {'acidity': 6, 'sweetness': 3.5, 'body': 3, 'oak': 0, 'evolution': 1, 'aromatic': 7, 'bubbles': 8},
        appellations: {'Prosecco', "Moscato d'Asti", 'Lambrusco', "Brachetto d'Acqui"},
        cepages: {Cep.glera, Cep.moscato, Cep.lambrusco, Cep.brachetto},
        mots: {'prosecco', 'moscato', 'lambrusco', 'asti'},
        exemples: [('Rustico', 'Nino Franco'), ('Saracco', null), ('Lini 910', null)]),

    // ─────────── Doux et mutés ───────────
    StyleDeVin('liquoreux', 'sweet',
        axes: {'acidity': 7, 'sweetness': 9, 'body': 8, 'oak': 3.5, 'evolution': 4, 'aromatic': 7, 'oxidative': 1},
        exemples: [('Château Suduiraut', null), ('Royal Tokaji', null), ('Domaine des Baumard', null)]),
    StyleDeVin('vin_mute', 'fortified',
        axes: {'acidity': 4.5, 'sweetness': 8.5, 'body': 9, 'tannin': 5, 'oak': 3, 'evolution': 5, 'aromatic': 6, 'oxidative': 3},
        appellations: {'Porto', 'Banyuls', 'Muscat de Rivesaltes', 'Muscat de Beaumes-de-Venise', 'Madère', 'Marsala', 'Rutherglen', 'Rasteau'},
        exemples: [("Graham's", null), ('Mas Amiel', null), ("Blandy's", null)]),
  ];

  static final Map<String, StyleDeVin> _parId = {for (final s in tous) s.id: s};

  static StyleDeVin parId(String id) => _parId[id]!;

  /// Les styles d'une bouteille : son style, et « patiné par l'âge » en plus pour un rouge
  /// arrivé loin dans sa garde (l'évolution du palais, à 7 sur 10 au moins : un Morgon de
  /// onze ans l'est, un Rioja Reserva de vingt ans pas encore). Vide pour ce qui n'est pas
  /// du vin.
  static List<StyleDeVin> de(Wine w, {int? annee}) {
    final style = _style(w);
    if (style == null) return const [];
    final le = annee == null ? null : DateTime(annee, 6);
    final evolution = ProfilDuVin.deLaCave(w, le: le).sur10(AxesDuPalais.evolution);
    final patine = style.couleur == 'red' && evolution != null && evolution >= 7.0;
    return [style, if (patine && style.id != 'rouge_evolue') parId('rouge_evolue')];
  }

  static StyleDeVin? _style(Wine w) {
    final couleur = VinsConnus.couleurDe(w.type);
    if (couleur == null || couleur == 'autre') return null;
    final texte = ' ${VinsConnus.normaliser('${w.name} ${w.cuveeParcel ?? ''} ${w.appellation ?? ''} ${w.classification ?? ''}')} ';
    bool dit(Set<String> mots) => mots.any((m) => texte.contains(' $m '));
    final connu = VinsConnus.trouver(
        nom: w.name, producteur: w.producer, cuvee: w.cuveeParcel, appellation: w.appellation, region: w.region, pays: w.country, type: w.type);
    var appellation = connu?.appellationDeLaFiche ??
        VinsConnus.appellation(appellation: w.appellation, nom: w.name, region: w.region, pays: w.country) ??
        connu?.appellation;
    // « Vin de France » ne dit rien du vin : sa région en dit davantage (Provence, Var).
    if (appellation != null && appellation.generique && appellation.cepages.isEmpty) {
      appellation = VinsConnus.appellation(region: w.region, pays: w.country) ?? appellation;
    }
    final nomAppellation = appellation?.nom;

    // 1. Ce que la couleur et les mots disent à eux seuls.
    final voile = parId('blanc_voile');
    final orange = parId('vin_orange');
    if (couleur == 'orange' || connu?.vin.couleur == 'orange' || (couleur == 'white' && dit(orange.mots))) return orange;
    if (dit(voile.mots) && couleur != 'red' && couleur != 'rose' && couleur != 'sparkling' && !dit(const {'cream', 'pedro ximenez', 'px'})) {
      return voile;
    }
    if (couleur == 'white' && nomAppellation == 'Château-Chalon') return voile;
    switch (couleur) {
      case 'sparkling':
        final fruitees = parId('bulles_fruitees');
        return _releve(fruitees, nomAppellation, _cepages(w, connu, appellation).liste) || dit(fruitees.mots)
            ? fruitees
            : parId('bulles_tradition');
      case 'fortified':
        return parId('vin_mute');
      case 'sweet':
        return parId('vin_mute').appellations.contains(nomAppellation) ? parId('vin_mute') : parId('liquoreux');
    }
    if (couleur == 'red' && dit(parId('rouge_amarone').mots)) return parId('rouge_amarone');
    if (couleur == 'rose' && dit(parId('rose_gastronomique').mots)) return parId('rose_gastronomique');

    // 2. L'appellation, puis le cépage dominant, dans la couleur du vin.
    final candidats = [for (final s in tous) if (_memeCouleur(s.couleur, couleur)) s];
    final resolus = _cepages(w, connu, appellation);
    final cepages = resolus.liste;
    final dominant = cepages.isEmpty ? null : cepages.first;
    if (couleur == 'white' && dominant == Cep.ch) {
      // Un chardonnay se range par son lieu (Meursault, Chablis) ou, à défaut, par son bois.
      for (final s in candidats) {
        if (nomAppellation != null && s.appellations.contains(nomAppellation)) return s;
      }
      final boise = ProfilDuVin.deLaCave(w).sur10(AxesDuPalais.boise) ?? 0;
      return parId(boise >= 5.5 ? 'blanc_boise' : 'blanc_vif');
    }
    if (couleur == 'white' && dominant == Cep.sb && nomAppellation == 'Marlborough') return parId('blanc_aromatique');
    StyleDeVin? parLeLieu() {
      for (final s in candidats) {
        if (nomAppellation != null && s.appellations.contains(nomAppellation)) return s;
      }
      return null;
    }

    // En Europe, une appellation précise fait le style : un cabernet franc de Chinon est un
    // rouge de Loire, une syrah de Provence un rouge de garrigue. Ailleurs, et sous une
    // mention large (Bordeaux, Toscana, Pays d'Oc), le cépage le fait : un pinot de Sonoma
    // est un pinot, un merlot de Toscane (Masseto) un merlot — à condition d'être celui du
    // vin : l'encépagement moyen d'un « Languedoc » n'en fait pas une syrah du Rhône nord.
    final lieuQuiDefinit =
        appellation != null && ((!appellation.generique && !_nouveauMonde.contains(appellation.pays)) || !resolus.propres);
    if (lieuQuiDefinit) {
      final s = parLeLieu();
      if (s != null) return s;
    }
    for (final s in candidats) {
      if (dominant != null && s.cepages.contains(dominant)) return s;
    }
    final s = parLeLieu();
    if (s != null) return s;
    for (final s in candidats) {
      if (cepages.any(s.cepages.contains)) return s;
    }

    // 3. Le plus proche par le profil du vin.
    return _plusProche(w, candidats);
  }

  static const _nouveauMonde = {
    'États-Unis', 'Argentine', 'Chili', 'Australie', 'Nouvelle-Zélande', 'Afrique du Sud', 'Uruguay', 'Canada',
  };

  static bool _releve(StyleDeVin s, String? appellation, List<String> cepages) =>
      (appellation != null && s.appellations.contains(appellation)) || (cepages.isNotEmpty && s.cepages.contains(cepages.first));

  static bool _memeCouleur(String style, String vin) => switch (vin) {
        'red' => style == 'red',
        'rose' => style == 'rose',
        'white' => style == 'white',
        _ => style == vin,
      };

  /// Les cépages du vin, du dominant au moindre : ceux de la fiche, sinon ceux de la base
  /// (la cuvée, le cépage du nom, puis l'appellation).
  static ({List<String> liste, bool propres}) _cepages(Wine w, VinTrouve? connu, AppellationConnue? appellation) {
    if (w.grapes.isNotEmpty) return (liste: [for (final g in w.grapes) _canonique(g.name)], propres: true);
    if (connu != null && connu.cepagesDeLaCuvee) return (liste: connu.cepages, propres: true);
    // Le cépage écrit dans le nom, dans l'ordre où il est écrit : « Grenache Syrah » est
    // d'abord un grenache.
    final nom = ' ${VinsConnus.normaliser('${w.name} ${w.cuveeParcel ?? ''}')} ';
    final dansLeNom = [
      for (final c in _cepagesConnus.entries)
        if (c.key.length > 4 && nom.contains(' ${c.key} ')) (nom.indexOf(' ${c.key} '), c.value),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    if (dansLeNom.isNotEmpty) return (liste: [for (final c in dansLeNom) c.$2], propres: true);
    final couleur = VinsConnus.couleurDe(w.type);
    final typiques = connu?.cepages ?? appellation?.cepagesPour(couleur) ?? const <String>[];
    return (liste: typiques, propres: false);
  }

  /// Tous les cépages de la base, par leur nom normalisé.
  static final Map<String, String> _cepagesConnus = {
    for (final a in VinsConnus.appellations) ...{
      for (final cs in a.cepages.values)
        for (final c in cs) VinsConnus.normaliser(c): c,
      for (final v in a.vins)
        for (final c in v.cepages) VinsConnus.normaliser(c): c,
    },
  }..removeWhere((k, _) => const {'montepulciano', 'pais'}.contains(k));

  /// Un nom de fiche (« cabernet-sauvignon », « Syrah/Shiraz ») ramené à celui de la base.
  static String _canonique(String nom) => _cepagesConnus[VinsConnus.normaliser(nom)] ?? nom;

  static StyleDeVin _plusProche(Wine w, List<StyleDeVin> candidats) {
    final p = ProfilDuVin.deLaCave(w);
    StyleDeVin? meilleur;
    var plusPetite = double.infinity;
    for (final s in candidats) {
      if (s.id == 'rouge_evolue' || s.id == 'blanc_voile' || s.id == 'vin_orange' || s.id == 'rouge_amarone') continue;
      var somme = 0.0;
      for (final axe in AxesDuPalais.tous) {
        final v = p.sur10(axe);
        final c = s.axes[axe];
        if (v == null || c == null) continue;
        somme += (v - c) * (v - c);
      }
      if (somme < plusPetite) {
        plusPetite = somme;
        meilleur = s;
      }
    }
    return meilleur ?? candidats.first;
  }
}
