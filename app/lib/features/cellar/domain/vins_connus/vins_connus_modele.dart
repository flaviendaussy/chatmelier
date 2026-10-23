// La base des vins connus (23/10) : les grandes appellations du monde, et dans chacune
// les vins qu'un amateur croise — leurs cépages, leur couleur.
//
// Flavien, 23/10 : « Itérer toutes les appellations très connues, et dedans tous les vins
// très connus, et populate ceux-ci ». Le catalogue partagé comptait ce jour-là 225 fiches
// sans cépages sur 294 : un Château Margaux, un Pontet-Canet, un Gran Reserva 904, un
// Cloudy Bay. Le palais les apprenait avec les cépages de la région, ou sans rien.
//
// **Ce que la base dit, et ce qu'elle tait.** Un vin n'a ses propres cépages que lorsque
// sa cuvée les fixe et qu'on les connaît sans hésiter (Pétrus : merlot ; Rayas : grenache ;
// Cristal : pinot noir et chardonnay). Sinon sa liste reste vide, et ce sont ceux de son
// appellation, pour sa couleur, qui s'appliquent : on ne prête pas à un domaine un
// assemblage qu'on devine. L'ordre des cépages est celui de leur part, le dominant en tête,
// sans pourcentages — ils changent avec chaque millésime.
//
// Elle complète `WineWorld` sans le doubler : `WineWorld` dit combien de temps un vin
// tient et comment il s'élève ; cette base-ci dit qui fait quoi, et avec quels raisins.

/// Les couleurs de la base : 'red', 'white', 'rose', 'sparkling', 'sweet', 'fortified',
/// 'orange'. Les bulles rosées restent 'sparkling' : ce sont les bulles qui les distinguent.
class VinConnu {
  final String nom;

  /// Le domaine ou la maison, quand le nom seul ne suffit pas à reconnaître le vin
  /// (« Bin 389 », « Grange » : Penfolds). Il doit alors figurer lui aussi sur l'étiquette.
  final String? de;
  final List<String> alias;
  final String couleur;

  /// Les cépages propres à la cuvée, du dominant au moindre ; vide : ceux de l'appellation.
  final List<String> cepages;

  const VinConnu.rouge(this.nom, this.cepages, {this.de, this.alias = const []}) : couleur = 'red';
  const VinConnu.blanc(this.nom, this.cepages, {this.de, this.alias = const []}) : couleur = 'white';
  const VinConnu.rose(this.nom, this.cepages, {this.de, this.alias = const []}) : couleur = 'rose';
  const VinConnu.bulles(this.nom, this.cepages, {this.de, this.alias = const []}) : couleur = 'sparkling';
  const VinConnu.doux(this.nom, this.cepages, {this.de, this.alias = const []}) : couleur = 'sweet';
  const VinConnu.mute(this.nom, this.cepages, {this.de, this.alias = const []}) : couleur = 'fortified';
  const VinConnu.orange(this.nom, this.cepages, {this.de, this.alias = const []}) : couleur = 'orange';
}

/// Une appellation (ou une indication géographique) et ses vins connus.
class AppellationConnue {
  final String nom;
  final String pays;
  final List<String> alias;

  /// L'encépagement de l'appellation par couleur, du dominant au moindre. La clé `'*'`
  /// vaut pour une couleur que l'appellation ne précise pas.
  final Map<String, List<String>> cepages;

  /// Une mention régionale large (Bordeaux, Bourgogne, Côtes du Rhône, Vin de France) :
  /// un vin d'une appellation plus précise y est souvent rangé par erreur, elle ne
  /// contredit donc jamais un vin connu.
  final bool generique;
  final List<VinConnu> vins;

  const AppellationConnue(
    this.nom,
    this.pays, {
    this.alias = const [],
    required this.cepages,
    this.generique = false,
    this.vins = const [],
  });

  List<String> cepagesPour(String? couleur) => cepages[couleur] ?? cepages['*'] ?? const [];
}

/// Les cépages, écrits une fois : une faute de frappe dans la base devient une erreur de
/// compilation plutôt qu'un cépage que personne ne reconnaît.
abstract final class Cep {
  // Bordeaux et Sud-Ouest
  static const cs = 'Cabernet Sauvignon';
  static const merlot = 'Merlot';
  static const cf = 'Cabernet Franc';
  static const pv = 'Petit Verdot';
  static const malbec = 'Malbec';
  static const carmenere = 'Carménère';
  static const sb = 'Sauvignon Blanc';
  static const sg = 'Sauvignon Gris';
  static const semillon = 'Sémillon';
  static const muscadelle = 'Muscadelle';
  static const tannat = 'Tannat';
  static const petitManseng = 'Petit Manseng';
  static const grosManseng = 'Gros Manseng';
  static const courbu = 'Petit Courbu';
  static const negrette = 'Négrette';
  static const ferServadou = 'Fer Servadou';
  static const duras = 'Duras';
  static const mauzac = 'Mauzac';
  static const lenDeLel = 'Len de l\'El';
  static const colombard = 'Colombard';
  static const ugni = 'Ugni Blanc';

  // Bourgogne, Champagne, Beaujolais, Jura, Savoie
  static const pn = 'Pinot Noir';
  static const ch = 'Chardonnay';
  static const meunier = 'Meunier';
  static const gamay = 'Gamay';
  static const aligote = 'Aligoté';
  static const savagnin = 'Savagnin';
  static const poulsard = 'Poulsard';
  static const trousseau = 'Trousseau';
  static const jacquere = 'Jacquère';
  static const altesse = 'Altesse';
  static const mondeuse = 'Mondeuse';
  static const roussanne = 'Roussanne';
  static const chasselas = 'Chasselas';

  // Loire, Alsace
  static const chenin = 'Chenin Blanc';
  static const melon = 'Melon de Bourgogne';
  static const grolleau = 'Grolleau';
  static const pineauDAunis = 'Pineau d\'Aunis';
  static const romorantin = 'Romorantin';
  static const riesling = 'Riesling';
  static const gewurz = 'Gewurztraminer';
  static const pinotGris = 'Pinot Gris';
  static const pinotBlanc = 'Pinot Blanc';
  static const auxerrois = 'Auxerrois';
  static const sylvaner = 'Sylvaner';
  static const muscat = 'Muscat';
  static const muscatPetitsGrains = 'Muscat à Petits Grains';
  static const muscatAlexandrie = 'Muscat d\'Alexandrie';

  // Rhône, Provence, Languedoc, Corse
  static const syrah = 'Syrah';
  static const viognier = 'Viognier';
  static const marsanne = 'Marsanne';
  static const grenache = 'Grenache';
  static const grenacheBlanc = 'Grenache Blanc';
  static const grenacheGris = 'Grenache Gris';
  static const mourvedre = 'Mourvèdre';
  static const cinsault = 'Cinsault';
  static const carignan = 'Carignan';
  static const counoise = 'Counoise';
  static const vaccarese = 'Vaccarèse';
  static const terretNoir = 'Terret Noir';
  static const muscardin = 'Muscardin';
  static const clairette = 'Clairette';
  static const bourboulenc = 'Bourboulenc';
  static const picpoul = 'Picpoul';
  static const picardan = 'Picardan';
  static const rolle = 'Rolle';
  static const tibouren = 'Tibouren';
  static const braquet = 'Braquet';
  static const folleNoire = 'Folle Noire';
  static const nielluccio = 'Nielluccio';
  static const sciaccarellu = 'Sciaccarellu';
  static const vermentino = 'Vermentino';
  static const macabeu = 'Macabeu';

  // Italie
  static const nebbiolo = 'Nebbiolo';
  static const barbera = 'Barbera';
  static const dolcetto = 'Dolcetto';
  static const arneis = 'Arneis';
  static const cortese = 'Cortese';
  static const moscato = 'Moscato Bianco';
  static const brachetto = 'Brachetto';
  static const ruche = 'Ruchè';
  static const sangiovese = 'Sangiovese';
  static const canaiolo = 'Canaiolo';
  static const colorino = 'Colorino';
  static const montepulciano = 'Montepulciano';
  static const trebbiano = 'Trebbiano';
  static const verdicchio = 'Verdicchio';
  static const pecorino = 'Pecorino';
  static const vernaccia = 'Vernaccia';
  static const corvina = 'Corvina';
  static const corvinone = 'Corvinone';
  static const rondinella = 'Rondinella';
  static const molinara = 'Molinara';
  static const oseleta = 'Oseleta';
  static const garganega = 'Garganega';
  static const glera = 'Glera';
  static const ribolla = 'Ribolla Gialla';
  static const friulano = 'Friulano';
  static const refosco = 'Refosco';
  static const lambrusco = 'Lambrusco';
  static const lagrein = 'Lagrein';
  static const schiava = 'Schiava';
  static const teroldego = 'Teroldego';
  static const aglianico = 'Aglianico';
  static const fiano = 'Fiano';
  static const greco = 'Greco';
  static const falanghina = 'Falanghina';
  static const primitivo = 'Primitivo';
  static const negroamaro = 'Negroamaro';
  static const nerelloMascalese = 'Nerello Mascalese';
  static const nerelloCappuccio = 'Nerello Cappuccio';
  static const carricante = 'Carricante';
  static const nerodAvola = 'Nero d\'Avola';
  static const frappato = 'Frappato';
  static const grillo = 'Grillo';
  static const catarratto = 'Catarratto';
  static const zibibbo = 'Zibibbo';
  static const cannonau = 'Cannonau';
  static const carignano = 'Carignano';
  static const lacrima = 'Lacrima';
  static const sagrantino = 'Sagrantino';
  static const grecanico = 'Grecanico';

  // Espagne
  static const tempranillo = 'Tempranillo';
  static const garnacha = 'Garnacha';
  static const garnachaBlanca = 'Garnacha Blanca';
  static const graciano = 'Graciano';
  static const mazuelo = 'Mazuelo';
  static const carinena = 'Cariñena';
  static const viura = 'Viura';
  static const malvasia = 'Malvasía';
  static const albarino = 'Albariño';
  static const treixadura = 'Treixadura';
  static const loureira = 'Loureira';
  static const verdejo = 'Verdejo';
  static const godello = 'Godello';
  static const mencia = 'Mencía';
  static const monastrell = 'Monastrell';
  static const bobal = 'Bobal';
  static const xarello = 'Xarel·lo';
  static const macabeo = 'Macabeo';
  static const parellada = 'Parellada';
  static const palomino = 'Palomino';
  static const px = 'Pedro Ximénez';
  static const moscatel = 'Moscatel';
  static const tintaDeToro = 'Tinta de Toro';
  static const garnachaTintorera = 'Garnacha Tintorera';
  static const prieto = 'Prieto Picudo';
  static const listan = 'Listán Negro';

  // Portugal
  static const tourigaNacional = 'Touriga Nacional';
  static const tourigaFranca = 'Touriga Franca';
  static const tintaRoriz = 'Tinta Roriz';
  static const tintaBarroca = 'Tinta Barroca';
  static const tintoCao = 'Tinto Cão';
  static const sousao = 'Sousão';
  static const baga = 'Baga';
  static const jaen = 'Jaen';
  static const alfrocheiro = 'Alfrocheiro';
  static const trincadeira = 'Trincadeira';
  static const aragonez = 'Aragonez';
  static const alicante = 'Alicante Bouschet';
  static const castelao = 'Castelão';
  static const alvarinho = 'Alvarinho';
  static const loureiro = 'Loureiro';
  static const arinto = 'Arinto';
  static const trajadura = 'Trajadura';
  static const encruzado = 'Encruzado';
  static const antaoVaz = 'Antão Vaz';
  static const roupeiro = 'Roupeiro';
  static const rabigato = 'Rabigato';
  static const viosinho = 'Viosinho';
  static const gouveio = 'Gouveio';
  static const codega = 'Códega do Larinho';
  static const malvasiaFina = 'Malvasia Fina';
  static const sercial = 'Sercial';
  static const verdelho = 'Verdelho';
  static const boal = 'Boal';
  static const malvasiaMadeira = 'Malvasia';
  static const tintaNegra = 'Tinta Negra';
  static const moscatelSetubal = 'Moscatel de Setúbal';
  static const fernaoPires = 'Fernão Pires';
  static const bical = 'Bical';

  // Europe centrale et orientale, Méditerranée
  static const gruner = 'Grüner Veltliner';
  static const blaufrankisch = 'Blaufränkisch';
  static const zweigelt = 'Zweigelt';
  static const stLaurent = 'Sankt Laurent';
  static const welschriesling = 'Welschriesling';
  static const silvaner = 'Silvaner';
  static const mullerThurgau = 'Müller-Thurgau';
  static const scheurebe = 'Scheurebe';
  static const furmint = 'Furmint';
  static const harslevelu = 'Hárslevelű';
  static const sargamuskotaly = 'Sárgamuskotály';
  static const kadarka = 'Kadarka';
  static const kekfrankos = 'Kékfrankos';
  static const assyrtiko = 'Assyrtiko';
  static const athiri = 'Athiri';
  static const aidani = 'Aidani';
  static const mandilaria = 'Mandilaria';
  static const xinomavro = 'Xinomavro';
  static const agiorgitiko = 'Agiorgitiko';
  static const moschofilero = 'Moschofilero';
  static const malagousia = 'Malagousia';
  static const petiteArvine = 'Petite Arvine';
  static const cornalin = 'Cornalin';
  static const humagneRouge = 'Humagne Rouge';
  static const saperavi = 'Saperavi';
  static const rkatsiteli = 'Rkatsiteli';
  static const mtsvane = 'Mtsvane';
  static const kisi = 'Kisi';
  static const obaideh = 'Obaideh';
  static const merwah = 'Merwah';
  static const seyval = 'Seyval Blanc';
  static const bacchus = 'Bacchus';

  // Nouveau Monde
  static const shiraz = 'Shiraz';
  static const zinfandel = 'Zinfandel';
  static const petiteSirah = 'Petite Sirah';
  static const pinotage = 'Pinotage';
  static const torrontes = 'Torrontés';
  static const bonarda = 'Bonarda';
  static const pais = 'País';
  static const mataro = 'Mataro';
}
