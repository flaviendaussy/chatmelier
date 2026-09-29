/// Les fiches de terroir en anglais, texte français → texte anglais.
///
/// Les fiches (`terroir_geo_data.dart`) restent écrites en français et constantes ; l'écran
/// passe par les accesseurs `…Affiche` de [TerroirGeoProfile], qui consultent cette table
/// quand l'app est en anglais. Un texte absent d'ici s'affiche en français : le test
/// `terroir_geo_data_en_test.dart` veille à ce qu'il n'en manque aucun.
const Map<String, String> terroirEnAnglais = {
  'Croupes de graves garonnaises profondes, alios et sables':
      'Deep Garonne gravel mounds over iron-pan (alios) and sand',
  'Graves fines très calcaires et caillouteuses, sables quartzeux':
      'Fine, very chalky, stony gravel with quartz sand',
  'Graves garonnaises sédimentaires sur socle marneux':
      'Sedimentary Garonne gravel over marl bedrock',
  'Graves mêlées d\'argiles denses retenant la fraîcheur':
      'Gravel mixed with dense clay that keeps the vines cool',
  'Graves galets quartzeux, sables, argiles et calcaire coquillier':
      'Quartz pebbles and gravel, sand, clay and shelly limestone',
  'Graves sur calcaires argileux et marnes miocènes':
      'Gravel over clay-limestone and Miocene marl',
  'Plateau calcaire à astéries, argiles blanches et crasse de fer':
      'Starfish-limestone plateau, white clay and iron-rich \'crasse de fer\'',
  'Boutonnière d\'argiles bleues smectites sur crasse de fer':
      'A dome of blue smectite clay over iron-rich \'crasse de fer\'',
  'Calcaires bajociens et marnes oxfordiennes riches en fer':
      'Bajocian limestone and iron-rich Oxfordian marl',
  'Cône de déjection de la Combe Lavaux, calcaires caillouteux et marnes':
      'Alluvial fan of the Combe Lavaux: stony limestone and marl',
  'Calcaires très fissurés du Bathonien, sol mince et pierreux':
      'Deeply fissured Bathonian limestone, thin stony soil',
  'Marnes blanches oxfordiennes, calcaires bathoniens friables':
      'White Oxfordian marl and crumbly Bathonian limestone',
  'Marnes kimméridgiennes fossilisées de minuscules huîtres (Exogyra virgula)':
      'Kimmeridgian marl full of tiny fossil oysters (Exogyra virgula)',
  'Craie campanienne pure affleurante, bélemnites et nodules de silex':
      'Pure Campanian chalk at the surface, belemnites and flint nodules',
  'Micaschistes feuilletés (Côte Brune) et calcaires sableux (Côte Blonde)':
      'Flaky mica-schist (Côte Brune) and sandy limestone (Côte Blonde)',
  'Galets roulés quartzeux du Rhône sur socle d\'argiles rouges et sables':
      'Rounded Rhône quartz pebbles over red clay and sand',
  'Terres blanches (marnes kimméridgiennes), caillottes et silex':
      '\'Terres blanches\' (Kimmeridgian marl), \'caillottes\' limestone and flint',
  'Mosaïque géologique unique : granites, grès roses des Vosges, calcaires et marnes':
      'A unique geological mosaic: granite, pink Vosges sandstone, limestone and marl',
  'Restanques d\'argiles et de grès triasiques très calcaires':
      'Terraces (\'restanques\') of very chalky clay and Triassic sandstone',
  'Éboulis calcaires jurassiques et marnes au pied de la falaise':
      'Jurassic limestone scree and marl at the foot of the cliff',
  'Argilo-calcaire sur terrasses alluviales de l\'Èbre, grès ferreux':
      'Clay-limestone on the Ebro\'s alluvial terraces, ferrous sandstone',
  'Calcaires tertiaires, couches limoneuses et craie de plateau':
      'Tertiary limestone, silty layers and plateau chalk',
  'Sols bruns calcaires encroûtés très perméables retenant l\'eau en profondeur':
      'Brown, crusted, very free-draining limestone soils that hold water deep down',
  'Llicorella : schistes ardoisiers noirs et cuivreux du Paléozoïque':
      'Llicorella: black and copper-tinged Palaeozoic slate',
  'Marnes de Sant\'Agata (argiles et sables fins) et grès d\'Helvétien':
      'Sant\'Agata marl (clay and fine sand) and Helvetian sandstone',
  'Galestro (schistes friables) et Alberese (calcaire compact toscan)':
      'Galestro (crumbly schist) and Alberese (compact Tuscan limestone)',
  'Cône alluvionnaire de Rutherford, bancs de graviers et cendres volcaniques':
      'The Rutherford alluvial fan: gravel beds and volcanic ash',
  'Alluvions sableuses caillouteuses incrustées de calcaire blanc pur':
      'Sandy, stony alluvium studded with pure white limestone',
  'Argiles rouges profondes fertiles mêlées de sables et de fer':
      'Deep, fertile red clay mixed with sand and iron',
  'Schistes verticaux fracturés permettant aux racines de boire à 10m':
      'Vertical, fractured schist that lets roots drink 10 m down',
  'Campanien calcaire crayeux friable (Terres blanches de Grande Champagne)':
      'Crumbly, chalky Campanian limestone (the \'terres blanches\' of Grande Champagne)',
  'Sables fauves siliceux et boulbènes typiques du Bas-Armagnac':
      'Tawny siliceous sand and \'boulbènes\', typical of Bas-Armagnac',
  'Marnes argilo-calcaires jurassiques et silex des vallons normands':
      'Jurassic clay-limestone marl and flint in the Normandy valleys',
  'Massif préalpin calcaire urgonien et forêts d\'altitude':
      'Urgonian limestone of the Pre-Alps and mountain forests',
  'Falaise de craie blanche sénonienne du pays de Caux':
      'White Senonian chalk cliffs of the Pays de Caux',
  'Tourbières épaisses gorgées d\'eau de bruyère et quartz précambrien':
      'Thick, waterlogged peat bogs, heather and Precambrian quartz',
  'Socle granitique calédonien et alluvions glaciaires de la rivière Spey':
      'Caledonian granite bedrock and glacial alluvium of the River Spey',
  'Plaines calcaires herbeuses et tourbières alluvionnaires irlandaises':
      'Grassy limestone plains and Irish alluvial peat',
  'Plateau calcaire ordovicien filtrant une eau de source exempte de fer':
      'Ordovician limestone plateau filtering iron-free spring water',
  'Sols volcaniques andosols riches et fertiles de la Montagne Pelée':
      'Rich, fertile volcanic andosols of Mount Pelée',
  'Terres volcaniques rouges riches en fer et minéraux du volcan de Tequila':
      'Red volcanic soils rich in iron and minerals from the Tequila volcano',
  'Bassin alluvionnaire de la Tamise et sources d\'eau pures':
      'The Thames alluvial basin and pure water springs',
  'Plaines fertiles de Tchernoziom et terres sablo-limoneuses de céréales nobles':
      'Fertile chernozem plains and sandy-silty soils for fine cereals',
  'Océanique tempéré régulé par l\'estuaire de la Gironde':
      'Temperate oceanic, moderated by the Gironde estuary',
  'Océanique doux et tempéré':
      'Mild, temperate oceanic',
  'Océanique maritime protecteur':
      'Protective maritime oceanic',
  'Océanique maritime septentrional':
      'Northern maritime oceanic',
  'Océanique adouci par la forêt des Landes':
      'Oceanic, softened by the Landes forest',
  'Microclimat brumeux matinal unique né de la confluence Ciron-Garonne':
      'A unique misty morning microclimate, born where the Ciron meets the Garonne',
  'Océanique à influence continentale marquée':
      'Oceanic with a marked continental influence',
  'Océanique tempéré continentalisé':
      'Temperate oceanic turning continental',
  'Semi-continental aux nuits fraîches et étés chauds':
      'Semi-continental, with cool nights and hot summers',
  'Semi-continental septentrional':
      'Northern semi-continental',
  'Semi-continental tempéré par la combe d\'Ambin':
      'Semi-continental, tempered by the Combe d\'Ambin',
  'Semi-continental ensoleillé':
      'Sunny semi-continental',
  'Semi-continental frais exposé aux gelées de printemps':
      'Cool semi-continental, exposed to spring frosts',
  'Double influence océanique et continentale froide':
      'Both oceanic and cold continental influences',
  'Continental tempéré balayé par le vent du Nord (Mistral)':
      'Temperate continental, swept by the north wind (Mistral)',
  'Méditerranéen chaud et très sec, assaini par le Mistral vigoureux':
      'Hot and very dry Mediterranean, kept healthy by a strong Mistral',
  'Océanique dégradé à tonalité continentale':
      'Degraded oceanic with a continental tone',
  'Semi-continental très abrité et sec (effet de foehn des Vosges)':
      'Very sheltered, dry semi-continental (Vosges foehn effect)',
  'Méditerranéen maritime avec plus de 3000 heures de soleil/an':
      'Maritime Mediterranean with over 3,000 hours of sun a year',
  'Méditerranéen d\'altitude aux amplitudes thermiques jour/nuit marquées':
      'Upland Mediterranean with wide day/night temperature swings',
  'Continental tempéré par l\'influence atlantique de la Sierra Cantabria':
      'Continental, tempered by the Atlantic influence of the Sierra Cantabria',
  'Continental extrême : hivers rigoureux et étés torrides à nuits fraîches':
      'Extreme continental: harsh winters and scorching summers with cool nights',
  'Méditerranéen semi-aride avec plus de 300 jours d\'ensoleillement':
      'Semi-arid Mediterranean with over 300 days of sun',
  'Méditerranéen aride de montagne':
      'Arid mountain Mediterranean',
  'Continental tempéré aux brumes automnales mythiques (Nebbia)':
      'Temperate continental with legendary autumn fogs (nebbia)',
  'Méditerranéen chaud tempéré par la brise marine thyrrhénienne':
      'Hot Mediterranean, tempered by the Tyrrhenian sea breeze',
  'Méditerranéen tempéré par les brouillards matinaux de la baie de San Pablo':
      'Mediterranean, tempered by morning fogs from San Pablo Bay',
  'Désertique d\'altitude (soleil permanent et eau de fonte des glaciers des Andes)':
      'High-altitude desert (constant sun and Andean glacier meltwater)',
  'Méditerranéen chaud et ensoleillé':
      'Hot, sunny Mediterranean',
  'Méditerranéen très sec et torride protégé par la Serra do Marão':
      'Very dry, torrid Mediterranean, sheltered by the Serra do Marão',
  'Océanique doux et tempéré à forte hygrométrie favorisant la part des anges':
      'Mild, temperate and humid oceanic, generous to the angels\' share',
  'Subatlantique tempéré sous influence pyrénéenne et océanique':
      'Temperate sub-Atlantic, under Pyrenean and oceanic influence',
  'Océanique humide, doux et tempéré favorisant la pomologie':
      'Humid, mild, temperate oceanic, ideal for orchards',
  'Alpin rigoureux et tempéré par les vallées':
      'Harsh Alpine, tempered by the valleys',
  'Océanique vivifiant balayé par les vents de la Manche':
      'Bracing oceanic, swept by Channel winds',
  'Océanique sauvage, pluvieux et balayé par les embruns atlantiques':
      'Wild, rainy oceanic, swept by Atlantic spray',
  'Subpolaire océanique tempéré, eau de source cristalline des monts Cairngorms':
      'Temperate sub-polar oceanic, crystal-clear spring water from the Cairngorms',
  'Océanique doux et tempéré à fortes précipitations':
      'Mild, temperate oceanic with heavy rainfall',
  'Continental humide à variations thermiques saisonnières extrêmes':
      'Humid continental with extreme seasonal temperature swings',
  'Tropical maritime chaud et humide rythmé par les alizés':
      'Hot, humid maritime tropical, paced by the trade winds',
  'Semi-aride subtropical avec saisons sèche et pluvieuse bien marquées':
      'Semi-arid subtropical with clear dry and rainy seasons',
  'Océanique tempéré maritime':
      'Temperate maritime oceanic',
  'Continental tempéré aux hivers glaciaux':
      'Temperate continental with icy winters',
  'Coteaux en pente douce orientés Est / Sud-Est vers le fleuve':
      'Gentle slopes facing east / south-east towards the river',
  'Croupes ondulées douces face au fleuve':
      'Gently rolling mounds facing the river',
  'Plateau légèrement incliné vers l\'Est':
      'A plateau sloping slightly east',
  'Coteaux bordant l\'estuaire de la Gironde':
      'Slopes along the Gironde estuary',
  'Croupes de graves bien drainées':
      'Well-drained gravel mounds',
  'Coteaux orientés Nord/Nord-Est protégés des vents':
      'North / north-east-facing slopes sheltered from the wind',
  'Amphithéâtre naturel exposé plein Sud':
      'A natural amphitheatre facing due south',
  'Plateau doux culminant à 40 mètres':
      'A gentle plateau topping out at 40 metres',
  'Coteau pentu plein Levant (Est)':
      'A steep slope facing due east',
  'Est et Sud-Est à flanc de coteau':
      'East and south-east hillsides',
  'Plein Est recevant le soleil dès l\'aube':
      'Due east, catching the sun from dawn',
  'Est et Sud-Est à mi-coteau':
      'East and south-east, mid-slope',
  'Coteau abrupt exposé Sud-Ouest dominant le Serein':
      'A steep south-west-facing slope above the Serein',
  'Falaise de craie orientée plein Est':
      'Chalk cliff facing due east',
  'Pentes vertigineuses terrassées en cheys jusqu\'à 60% face au Sud-Est':
      'Dizzying slopes terraced into \'cheys\', up to 60%, facing south-east',
  'Plateaux et terrasses ouvertes baignées de soleil':
      'Open, sun-drenched plateaus and terraces',
  'Piton rocheux et collines escarpées dominant la Loire':
      'A rocky spur and steep hills above the Loire',
  'Coteaux abrupts exposés Est à Sud-Est':
      'Steep slopes facing east to south-east',
  'Amphithéâtre naturel ouvert sur la mer Méditerranée':
      'A natural amphitheatre opening onto the Mediterranean',
  'Contreforts sud et est du massif calcaire':
      'South and east foothills of the limestone massif',
  'Terrasses et versants orientés Sud':
      'South-facing terraces and slopes',
  'Plateaux arides et coteaux bordant le fleuve Douro':
      'Arid plateaus and slopes along the Douro river',
  'Plateaux d\'altitude et vallées entourées de massifs':
      'High plateaus and valleys ringed by mountains',
  'Costerets (pentes vertigineuses jusqu\'à 50%) en terrasses':
      '\'Costers\' (dizzying slopes up to 50%) in terraces',
  'Coteaux sinueux (Sorì) orientés plein Sud':
      'Winding south-facing slopes (\'sorì\')',
  'Collines douces toscanes culminant face au mont Amiata':
      'Gentle Tuscan hills facing Monte Amiata',
  'Fond de vallée et coteaux des monts Mayacamas et Vaca':
      'Valley floor and slopes of the Mayacamas and Vaca ranges',
  'Piémont andin sous le mont Tupungato':
      'Andean foothills below Mount Tupungato',
  'Vallée vallonnée protégée par les collines de Barossa Ranges':
      'A rolling valley sheltered by the Barossa Ranges',
  'Terrasses escarpées vertigineuses (Socalcos et Patamares)':
      'Dizzyingly steep terraces (\'socalcos\' and \'patamares\')',
  'Coteaux ouverts et vallonnés le long du fleuve Charente':
      'Open, rolling slopes along the Charente river',
  'Pentes douces boisées de chênes pédonculés gascons':
      'Gentle slopes wooded with Gascon pedunculate oak',
  'Vergers traditionnels haute-tige enherbés et pâturés':
      'Traditional grassy, grazed standard-tree orchards',
  'Coteaux alpins abrités de la combe d\'Isère':
      'Alpine slopes sheltered in the Isère valley',
  'Vallée maritime de Fécamp ouverte sur le littoral':
      'The maritime valley of Fécamp, open to the coast',
  'Rivages côtiers sauvages du Loch Indaal et du Sound of Islay':
      'Wild shores of Loch Indaal and the Sound of Islay',
  'Vallons protégés de la Spey bordés de forêts de pins calédoniens':
      'Sheltered Spey glens lined with Caledonian pine forest',
  'Verdoyantes vallées côtières tempérées du sud et du nord':
      'Green, temperate coastal valleys, south and north',
  'Collines ondulantes de la région Bluegrass et vallées de la Kentucky River':
      'Rolling Bluegrass hills and the Kentucky River valleys',
  'Versants volcaniques et plaines cannières ensoleillées':
      'Volcanic slopes and sunny sugar-cane plains',
  'Plateaux arides et pentes volcaniques sous le volcan Tequila':
      'Arid plateaus and volcanic slopes below the Tequila volcano',
  'Cœur historique de la distillation urbaine britannique':
      'The historic heart of British urban distilling',
  'Grands plateaux céréaliers d\'Europe centrale':
      'The great cereal plateaus of Central Europe',
  '12 - 30 mètres':
      '12 - 30 m',
  '10 - 24 mètres':
      '10 - 24 m',
  '15 - 22 mètres':
      '15 - 22 m',
  '14 - 28 mètres':
      '14 - 28 m',
  '25 - 60 mètres':
      '25 - 60 m',
  '30 - 80 mètres':
      '30 - 80 m',
  '40 - 100 mètres':
      '40 - 100 m',
  '25 - 42 mètres':
      '25 - 42 m',
  '250 - 310 mètres':
      '250 - 310 m',
  '260 - 380 mètres':
      '260 - 380 m',
  '250 - 350 mètres':
      '250 - 350 m',
  '230 - 320 mètres':
      '230 - 320 m',
  '130 - 250 mètres':
      '130 - 250 m',
  '120 - 240 mètres':
      '120 - 240 m',
  '180 - 340 mètres':
      '180 - 340 m',
  '40 - 120 mètres':
      '40 - 120 m',
  '150 - 310 mètres':
      '150 - 310 m',
  '200 - 450 mètres':
      '200 - 450 m',
  '50 - 250 mètres':
      '50 - 250 m',
  '150 - 400 mètres':
      '150 - 400 m',
  '400 - 700 mètres':
      '400 - 700 m',
  '720 - 880 mètres (Vignoble d\'altitude)':
      '720 - 880 m (high-altitude vineyard)',
  '400 - 900 mètres':
      '400 - 900 m',
  '300 - 750 mètres':
      '300 - 750 m',
  '250 - 450 mètres':
      '250 - 450 m',
  '200 - 550 mètres':
      '200 - 550 m',
  '50 - 450 mètres':
      '50 - 450 m',
  '900 - 1450 mètres (Vignoble très haut)':
      '900 - 1450 m (very high vineyard)',
  '250 - 400 mètres':
      '250 - 400 m',
  '100 - 600 mètres':
      '100 - 600 m',
  '20 - 160 mètres':
      '20 - 160 m',
  '80 - 200 mètres':
      '80 - 200 m',
  '40 - 150 mètres':
      '40 - 150 m',
  '280 - 1000 mètres':
      '280 - 1000 m',
  '10 - 80 mètres':
      '10 - 80 m',
  '0 - 150 mètres':
      '0 - 150 m',
  '150 - 500 mètres':
      '150 - 500 m',
  '20 - 120 mètres':
      '20 - 120 m',
  '150 - 300 mètres':
      '150 - 300 m',
  '20 - 450 mètres':
      '20 - 450 m',
  '1200 - 2100 mètres (Haute altitude)':
      '1200 - 2100 m (high altitude)',
  '15 - 40 mètres':
      '15 - 40 m',
  'Cabernet Sauvignon, Merlot (forte proportion)':
      'Cabernet Sauvignon, Merlot (a high share)',
  'Syrah (dominant), co-fermentée avec jusqu\'à 20% de Viognier':
      'Syrah (dominant), co-fermented with up to 20% Viognier',
  'Grenache Noir (dominant), Mourvèdre, Syrah, Cinsault (13 cépages autorisés)':
      'Grenache Noir (dominant), Mourvèdre, Syrah, Cinsault (13 permitted grapes)',
  'Mourvèdre (minimum 50% en rouge), Grenache, Cinsault':
      'Mourvèdre (at least 50% in the reds), Grenache, Cinsault',
  'Tinto Fino (Tempranillo local 95%), Cabernet Sauvignon':
      'Tinto Fino (local Tempranillo, 95%), Cabernet Sauvignon',
  'Monastrell (Mourvèdre 80%), Syrah, Garnacha Tintorera':
      'Monastrell (Mourvèdre, 80%), Syrah, Garnacha Tintorera',
  'Garnacha Peluda, Cariñena (Carignan centenaire), Syrah':
      'Garnacha Peluda, Cariñena (century-old Carignan), Syrah',
  'Sangiovese Grosso (Brunello 100%)':
      'Sangiovese Grosso (Brunello, 100%)',
  'Shiraz (Syrah centenaire préphylloxérique), Cabernet Sauvignon, Grenache':
      'Shiraz (century-old, pre-phylloxera vines), Cabernet Sauvignon, Grenache',
  'Pommes à cidre douces-amères (Bisquet, Bédan) et acidulées, Poires':
      'Bittersweet (Bisquet, Bédan) and sharp cider apples, pears',
  'Alcool de grain infusé et distillé avec 130 plantes et herbes alpines':
      'Grain spirit infused and distilled with 130 Alpine plants and herbs',
  '27 plantes et épices du monde (angélique, hysope, safran, genièvre, cannelle)':
      '27 plants and spices from around the world (angelica, hyssop, saffron, juniper, cinnamon)',
  'Orge maltée séchée à la fumée de tourbe locale (Peat)':
      'Malted barley dried over local peat smoke',
  '100% Orge maltée (malt non tourbé ou délicatement toasté)':
      '100% malted barley (unpeated or lightly toasted malt)',
  'Orge maltée et orge crue non maltée (Single Pot Still)':
      'Malted and unmalted raw barley (single pot still)',
  'Au moins 51% Maïs jaune, Seigle (Rye), Orge maltée, Blé':
      'At least 51% yellow corn, rye, malted barley, wheat',
  'Pur jus frais de canne à sucre broyée (Vesou non raffiné)':
      'Fresh pressed sugar-cane juice (unrefined \'vesou\')',
  '100% Agave Tequilana Weber Variedad Azul (cœurs d\'agave / piñas)':
      '100% Agave Tequilana Weber, blue variety (agave hearts, \'piñas\')',
  'Alcool neutre redistillé avec baies de genièvre (Juniperus communis), coriandre, angélique, agrumes':
      'Neutral spirit redistilled with juniper berries (Juniperus communis), coriander, angelica, citrus',
  'Seigle d\'or Dankowskie, Blé tendre d\'hiver, Pommes de terre Stobrawa':
      'Dankowskie golden rye, soft winter wheat, Stobrawa potatoes',
  'Premiers Grands Crus Classés 1855 (Latour, Lafite, Mouton)':
      'First Growths, 1855 classification (Latour, Lafite, Mouton)',
  'Premier Grand Cru Classé 1855 (Château Margaux)':
      'First Growth, 1855 classification (Château Margaux)',
  'Crus Classés 1855 (Léoville, Ducru-Beaucaillou)':
      'Classified Growths, 1855 (Léoville, Ducru-Beaucaillou)',
  'Deuxièmes Crus Classés (Cos d\'Estournel, Montrose)':
      'Second Growths (Cos d\'Estournel, Montrose)',
  'Cru Classé de Graves (Château Haut-Brion 1855)':
      'Graves Classified Growth (Château Haut-Brion, 1855)',
  'Premier Cru Supérieur 1855 (Château d\'Yquem)':
      'Superior First Growth, 1855 (Château d\'Yquem)',
  'Premiers Grands Crus Classés A (Figeac, Pavie — classement 2022)':
      'Premiers Grands Crus Classés A (Figeac, Pavie — 2022 classification)',
  'AOC Communale d\'élite (Petrus, Le Pin, Lafleur)':
      'An elite village appellation (Petrus, Le Pin, Lafleur)',
  'Grands Crus (Romanée-Conti et La Tâche, monopoles ; Richebourg)':
      'Grands Crus (Romanée-Conti and La Tâche, monopoles; Richebourg)',
  '7 Climats de Chablis Grand Cru (Les Clos, Valmur, Vaudésir)':
      '7 Chablis Grand Cru \'climats\' (Les Clos, Valmur, Vaudésir)',
  '17 Villages classés 100% Grand Cru':
      '17 villages rated 100% Grand Cru',
  'AOC Crus du Rhône Nord (Côte-Rôtie, Hermitage, Cornas, Condrieu)':
      'Northern Rhône cru appellations (Côte-Rôtie, Hermitage, Cornas, Condrieu)',
  'Pionnière des appellations d\'origine (AOC 1936)':
      'A pioneer of French appellations (AOC 1936)',
  'AOC Vignobles du Centre-Loire':
      'Centre-Loire appellations',
  '51 Terroirs d\'Alsace Grand Cru':
      '51 Alsace Grand Cru terroirs',
  'Cru Majeur de Provence (AOC 1941)':
      'Provence\'s leading cru (AOC 1941)',
  'Cru du Languedoc (AOC Communale)':
      'A Languedoc cru (village appellation)',
  'Vignoble classé Patrimoine Mondial UNESCO':
      'A UNESCO World Heritage vineyard',
  'AOC Cognac (Cru Grande Champagne / Petite Champagne)':
      'AOC Cognac (Grande Champagne / Petite Champagne crus)',
  'AOC Calvados Pays d\'Auge (Double distillation)':
      'AOC Calvados Pays d\'Auge (double distillation)',
  'Liqueur monastique historique (Manuscrit 1605)':
      'A historic monastic liqueur (1605 manuscript)',
  'Élixir monastique né, selon la légende, en 1510':
      'A monastic elixir born, legend has it, in 1510',
  'GI Irish Whiskey (Triple Distillation)':
      'GI Irish Whiskey (triple distillation)',
  'AOC Rhum de Martinique (Seule AOC mondiale du rhum)':
      'AOC Rhum de Martinique (the world\'s only rum AOC)',
  'Denominación de Origen Tequila (CRT certifié)':
      'Denominación de Origen Tequila (CRT certified)',
  'Catégorie Réglementaire Européenne London Dry Gin':
      'EU regulatory category: London Dry Gin',
  'Les graves pauvres et filtrantes forcent la vigne à plonger ses racines jusqu\'à 6 mètres pour puiser l\'eau, conférant aux vins une structure tannique royale et un potentiel de garde de plusieurs décennies.':
      'The poor, free-draining gravel forces the vine to send its roots down as far as 6 metres for water, giving the wines a regal tannic structure and decades of ageing potential.',
  'Les graves les plus fines du Médoc offrent un soyeux de tanins inimitable et un bouquet floral délicat de violette et de cèdre.':
      'The finest gravel in the Médoc gives inimitably silky tannins and a delicate floral bouquet of violet and cedar.',
  'L\'équilibre parfait du Médoc : la force et la charpente de Pauillac mariées à l\'élégance et la finesse de Margaux.':
      'The Médoc\'s perfect balance: the power and structure of Pauillac wed to the elegance and finesse of Margaux.',
  'Les sous-sols argileux confèrent une fraîcheur minérale et une trame compacte résistant magistralement aux millésimes chauds.':
      'The clay subsoils bring mineral freshness and a compact frame that stands up brilliantly to hot vintages.',
  'Berceau historique du vin de Bordeaux depuis l\'Antiquité romaine. Minéralité fumée légendaire en rouge comme en blanc.':
      'The historic cradle of Bordeaux wine since Roman times. Legendary smoky minerality, in red and white alike.',
  'Les brumes matinales favorisent l\'apparition du Botrytis Cinerea (pourriture noble) tandis que les après-midis chauds concentrent les sucres et les arômes d\'abricot confit et de safran.':
      'Morning mists encourage Botrytis cinerea (noble rot), while warm afternoons concentrate the sugars and the aromas of candied apricot and saffron.',
  'Le socle calcaire à astéries agit comme une éponge régulatrice d\'eau, offrant aux Merlots une opulence veloutée et une fraîcheur calcaire vibrante.':
      'The starfish-limestone bedrock acts as a sponge that regulates water, giving Merlot a velvety opulence and a vibrant limestone freshness.',
  'La légendaire boutonnière d\'argile bleue de Petrus retient l\'humidité et confère aux vins une texture soyeuse, de la truffe noire et une intensité aromatique inégalée.':
      'Petrus\'s legendary dome of blue clay holds moisture and gives the wines a silky texture, black truffle and unmatched aromatic intensity.',
  'La perle de la Côte d\'Or. Un équilibre aristocratique entre dentelle florale (rose fanée, pivoine), épices d\'Orient et tension minérale incomparable.':
      'The jewel of the Côte d\'Or. An aristocratic balance of floral lace (faded rose, peony), oriental spice and incomparable mineral tension.',
  'Le "Roi des Vins". Vigueur, puissance musculaire, tanins fermes et arômes de cerise noire sauvage, de réglisse et de sous-bois.':
      'The \'King of Wines\'. Vigour, muscular power, firm tannins and aromas of wild black cherry, liquorice and forest floor.',
  'La quintessence de la délicatesse. Évoqué comme "le vin le plus soyeux de Bourgogne", d\'une grâce féminine et aérienne.':
      'The quintessence of delicacy. Called \'the silkiest wine of Burgundy\', with an airy grace.',
  'Le sommet mondial du vin blanc sec. Minéralité tranchante comme un scalpel, arômes de noisette grillée, silex frotté et beurré noble.':
      'The world summit of dry white wine. Scalpel-sharp minerality, aromas of toasted hazelnut, struck flint and noble butteriness.',
  'L\'empreinte iodée de l\'ancienne mer jurassique confère au vin une pureté cristalline, une salinité minérale et une vivacité électrique.':
      'The iodine imprint of the ancient Jurassic sea gives the wine crystalline purity, mineral salinity and electric freshness.',
  'La craie poreuse agit comme un régulateur thermique et hydrique parfait, apportant une effervescence fine, de la craie broyée et une allonge saline remarquable.':
      'The porous chalk regulates heat and water perfectly, bringing fine bubbles, crushed chalk and a remarkable saline length.',
  'Les terrasses en vertige surplombant le Rhône captent la chaleur solaire. La Syrah y exhale des notes d\'olive noire, de lard fumé, de violette et de poivre blanc.':
      'The dizzying terraces above the Rhône catch the sun\'s heat. Syrah gives off notes of black olive, smoked bacon, violet and white pepper.',
  'Les galets roulés emmagasinent la chaleur du soleil le jour et la restituent aux grappes la nuit, menant les Grenaches à une plénitude charnue et épicée de garrigue.':
      'The rounded pebbles store the sun\'s heat by day and give it back to the grapes at night, taking Grenache to a fleshy, spicy, garrigue-scented fullness.',
  'Les sols de silex confèrent cette fameuse touche de "pierre à fusil" et de zeste de pamplemousse, tandis que les caillottes apportent vivacité et dentelle.':
      'The flint soils give that famous \'gunflint\' touch and grapefruit zest, while the \'caillottes\' bring freshness and lace.',
  'La barrière vosgienne protège le vignoble, créant l\'une des régions les plus sèches de France où le Riesling exprime une minéralité de roche ciselée.':
      'The Vosges barrier shelters the vineyards, creating one of the driest regions in France, where Riesling shows chiselled, rocky minerality.',
  'Le Mourvèdre y trouve sa terre sacrée les pieds dans la mer. Vins de garde aux notes de cuir noble, cerise noire, sous-bois méditerranéen et épices.':
      'Mourvèdre\'s sacred ground, with its feet in the sea. Wines for ageing, with notes of fine leather, black cherry, Mediterranean undergrowth and spice.',
  'L\'air frais descendant du causse la nuit préserve une fraîcheur aromatique et une finesse tannique qui tranchent avec la chaleur méridionale.':
      'Cool air flowing down from the causse at night keeps an aromatic freshness and a tannic finesse that stand out in the southern heat.',
  'Les fûts de chêne et la maturité lente confèrent au Tempranillo ses arômes emblématiques de vanille, cuir, tabac blond et fruits rouges macérés.':
      'Oak barrels and slow ripening give Tempranillo its signature aromas of vanilla, leather, blond tobacco and macerated red fruit.',
  'L\'altitude extrême préserve une acidité vibrante malgré la concentration solaire formidable de baies noires et de réglisse.':
      'The extreme altitude keeps a vibrant acidity despite the formidable sun-driven concentration of black berries and liquorice.',
  'Le royaume des vieilles vignes de Monastrell franches de pied. Concentration de fruits noirs confits, garrigue sauvage et finale chocolatée.':
      'The kingdom of old, ungrafted Monastrell vines. Concentrated candied black fruit, wild garrigue and a chocolatey finish.',
  'La roche schisteuse llicorella donne des rendements minuscules (10 hl/ha) produisant des vins d\'une intensité minérale, fumée et graphite renversante.':
      'Llicorella slate gives tiny yields (10 hl/ha) and wines of stunning mineral, smoky, graphite intensity.',
  'Le Nebbiolo y livre son éclat translucide grenat orné d\'arômes de goudron noble, de pétale de rose séchée, de truffe blanche et d\'une acidité magistrale.':
      'Nebbiolo gives its translucent garnet brilliance here, with aromas of noble tar, dried rose petal, white truffle and masterful acidity.',
  'Le Sangiovese trouve sur le Galestro sa plus noble expression : cerise griotte, thé noir, cuir de Russie et tanins denses et vibrants.':
      'On galestro, Sangiovese finds its noblest expression: morello cherry, black tea, Russian leather and dense, vibrant tannins.',
  'Le célèbre "Rutherford Dust". Cabernets cossus et opulents aux notes de cassis mûr, moka, bois de cèdre et tanins veloutés à grains très fins.':
      'The famous \'Rutherford dust\'. Rich, opulent Cabernets with notes of ripe blackcurrant, mocha, cedar and velvety, very fine-grained tannins.',
  'L\'ensoleillement UV intense épaissit la peau du Malbec tandis que les nuits glaciales des Andes fixent l\'acidité, créant des vins violets profonds aux notes de myrtille et de violette.':
      'Intense UV light thickens Malbec\'s skins while icy Andean nights lock in acidity, making deep purple wines with notes of blueberry and violet.',
  'Certaines des plus vieilles vignes franches de pied de Shiraz au monde (plantées en 1843). Fruits noirs confiturés, pruneau, eucalyptus et chocolat noir.':
      'Some of the world\'s oldest ungrafted Shiraz vines (planted in 1843). Jammy black fruit, prune, eucalyptus and dark chocolate.',
  'L\'une des plus anciennes régions délimitées au monde (1756). Terroir héroïque sculpté par la main de l\'homme produisant les grands Vintages de Porto et de somptueux vins secs.':
      'One of the world\'s oldest demarcated regions (1756). A heroic terroir, carved by hand, making great vintage Ports and superb dry wines.',
  'Double distillation au repasse dans l\'alambic charentais en cuivre, puis long vieillissement sous fûts de chêne français du Limousin développant le rancio mythique.':
      'Double distillation in the copper Charentais still, then long ageing in French Limousin oak, developing the legendary \'rancio\'.',
  'Plus ancienne eau-de-vie de France (1310). Distillation continue sur alambic armagnacais et élevage sous chêne noir de Gascogne : eau-de-vie rustique, puissante, aux notes de pruneau, vanille et épices.':
      'France\'s oldest brandy (1310). Continuous distillation in the Armagnac still and ageing in black Gascon oak: a rustic, powerful brandy with notes of prune, vanilla and spice.',
  'Nectar né de la distillation du cidre normand pur jus vieilli en fûts de chêne. Arômes intenses de pomme rôtie au beurre, de tarte tatin, de caramel au beurre salé et d\'épices douces.':
      'Distilled from pure-juice Normandy cider and aged in oak. Intense aromas of butter-roasted apple, tarte Tatin, salted-butter caramel and sweet spice.',
  'La seule liqueur au monde entièrement naturelle à vieillir et se bonifier en bouteille pendant des décennies. Complexe symphonie végétale de menthe poivrée, d\'anis, de thym serpolet, de génépi et de safran.':
      'Said to be the only liqueur that keeps ageing and improving in the bottle for decades. A complex herbal symphony of peppermint, anise, wild thyme, génépi and saffron.',
  'Distillation quadruple sous alambics martelés en cuivre de 1888 et vieillissement en foudres de chêne centenaires. Texture soyeuse, miel épicé, écorces d\'oranges confites et notes orientales.':
      'Quadruple distillation in hammered copper stills from 1888 and ageing in century-old oak casks. Silky texture, spiced honey, candied orange peel and oriental notes.',
  'Le sanctuaire mondial des whiskies tourbés et iodés. Notes intenses de fumée de feu de bois, goudron médical, algues salines, huître, et tourbe sauvage tempérée par des fûts de Bourbon ou Sherry.':
      'The world\'s sanctuary of peated, iodine-laden whiskies. Intense notes of wood smoke, medicinal tar, salty seaweed, oyster and wild peat, softened by Bourbon or Sherry casks.',
  'Le cœur historique et prestigieux du whisky écossais. Élégance, rondeur, notes miellées de pomme verte, poire mûre, malt toasté, vanille et fûts de Sherry Oloroso somptueux.':
      'The historic, prestigious heart of Scotch whisky. Elegance, roundness, honeyed notes of green apple, ripe pear, toasted malt, vanilla and lavish Oloroso Sherry casks.',
  'La tradition de la triple distillation en pot still apporte une onctuosité beurrée incomparable, sans aucune agressivité fumée, aux notes d\'épices de cuisson, pêche jaune, fudge et bois noble.':
      'The tradition of triple pot-still distillation gives an incomparable buttery smoothness, with no smoky edge, and notes of baking spice, yellow peach, fudge and fine wood.',
  'Les étés caniculaires et hivers glacés du Kentucky font respirer les fûts neufs de chêne américain brûlé (char #4), extrayant de puissants arômes de vanille, caramel, érable, maïs toasté et cuir.':
      'Kentucky\'s scorching summers and icy winters make the new, charred American oak barrels (char #4) breathe, drawing out powerful aromas of vanilla, caramel, maple, toasted corn and leather.',
  'Contrairement aux rhums industriels de mélasse, le rhum agricole est distillé à partir du vesou frais. Explosion aromatique de canne fraîche, zeste de lime, fleurs blanches en blanc, et boisé vanillé noble en vieux.':
      'Unlike industrial molasses rums, agricole rum is distilled from fresh cane juice. An aromatic burst of fresh cane, lime zest and white flowers when young, noble vanilla oak when aged.',
  'Les piñas d\'agave bleu mûrissent 7 à 10 ans sous le soleil mexicain avant d\'être cuites lentement en fours maçonnés. Arômes végétaux frais, poivre blanc, agave confit, herbes sauvages et minéralité volcanique.':
      'Blue agave piñas ripen 7 to 10 years under the Mexican sun before slow cooking in masonry ovens. Fresh green aromas, white pepper, candied agave, wild herbs and volcanic minerality.',
  'Distillation pure sans aucun arôme ni sucre ajouté après alambic. Dominance résineuse et piquante du genièvre, fraîcheur de zeste de citron jaune, racine d\'iris et graines de coriandre.':
      'Pure distillation, with no flavouring or sugar added after the still. Resinous, piquant juniper up front, fresh lemon zest, orris root and coriander seed.',
  'Pureté absolue issue de multiples distillations en colonnes et filtrations au charbon de bois. Texture grasse, crémeuse, notes de pain de seigle frais, vanille douce et poivre blanc délicat.':
      'Absolute purity from multiple column distillations and charcoal filtration. Oily, creamy texture, notes of fresh rye bread, soft vanilla and delicate white pepper.',
  'Vallée du Rhône Septentrionale (Côte-Rôtie & Hermitage)':
      'Northern Rhône Valley (Côte-Rôtie & Hermitage)',
  'Châteauneuf-du-Pape & Rhône Sud':
      'Châteauneuf-du-Pape & Southern Rhône',
  'Vallée du Douro (Cima Corgo)':
      'Douro Valley (Cima Corgo)',
  'Liqueur des Pères Chartreux (Voiron)':
      'Chartreuse, the Carthusian liqueur (Voiron)',
  'Rhum Agricole de la Martinique & Caraïbes':
      'Martinique & Caribbean Agricole Rum',
  'Tequila & Mezcal d\'Agave (Jalisco & Oaxaca)':
      'Agave Tequila & Mezcal (Jalisco & Oaxaca)',
  'Vodka de Tradition (Seigle, Blé & Pomme de terre)':
      'Traditional Vodka (Rye, Wheat & Potato)',
};
