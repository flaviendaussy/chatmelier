/// Les accords inversés (« quel plat pour ce vin ») en anglais, texte français → anglais.
///
/// `wine_reverse_pairing_engine.dart` rédige en français ; l'écran passe par [trDonnee]
/// avec cette table. Le test `wine_reverse_pairing_en_test.dart` veille à ce qu'aucun
/// texte n'y manque.
const Map<String, String> accordsInversesEnAnglais = {
  'L\'acidité vive et la salinité de la craie tranchent avec l\'iode et subliment la texture soyeuse des coquillages.':
      'The lively acidity and chalky salinity cut through the brine and lift the silky texture of the shellfish.',
  'Plateau d\'Huîtres Gillardeau & Carpaccio de Saint-Jacques au Citron Caviar':
      'Gillardeau oyster platter & scallop carpaccio with finger lime',
  'Servir cru à 8-10°C avec une émulsion d\'huile d\'olive et zestes d\'agrumes sans vinaigre excessif.':
      'Serve raw at 8-10°C with an olive oil emulsion and citrus zest, without too much vinegar.',
  'L\'acidité vive et la fraîcheur saline des bulles tranchent avec l\'iode et subliment la texture soyeuse des coquillages.':
      'The bubbles\' lively acidity and saline freshness cut through the brine and lift the silky texture of the shellfish.',
  'Ris de Veau Croustillant aux Morilles et Crème Réduite':
      'Crispy veal sweetbreads with morels and reduced cream',
  'Braiser au beurre moussant pour obtenir un extérieur doré et croquant et un cœur fondant.':
      'Baste in foaming butter for a golden, crisp outside and a melting centre.',
  'L\'effervescence fine et les notes briochées (autolyse des levures) nettoient le palais du gras noble des morilles et de la crème.':
      'Fine bubbles and brioche notes (yeast autolysis) cleanse the palate of the rich morels and cream.',
  'Comté Affiné 24 Mois & Gougères au Beurre AOP':
      '24-month Comté & butter gougères',
  'Servir les gougères tièdes au sortir du four avec des lamelles de Comté chambré.':
      'Serve the gougères warm from the oven with slivers of room-temperature Comté.',
  'Les cristaux de tyrosine du Comté résonnent avec la bulle crémeuse et la complexité oxydative.':
      'The tyrosine crystals of Comté echo the creamy bubbles and the wine\'s oxidative complexity.',
  'Foie Gras de Canard Mi-Cuit & Chutney de Figues':
      'Duck foie gras mi-cuit & fig chutney',
  'Servir frais, en tranches épaisses, avec un pain brioché à peine toasté.':
      'Serve chilled, in thick slices, with lightly toasted brioche.',
  'Le sucre et l\'acidité du vin répondent à la texture fondante du foie gras ; l\'acidité évite l\'écœurement.':
      'The wine\'s sugar and acidity answer the melting texture of foie gras; the acidity keeps it from cloying.',
  'Roquefort & Poire Rôtie au Miel':
      'Roquefort & honey-roasted pear',
  'Sortir le fromage 30 minutes avant ; rôtir la poire 15 minutes au four.':
      'Take the cheese out 30 minutes ahead; roast the pear for 15 minutes.',
  'Accord de contraste : le sel et le piquant du bleu sont apaisés par la douceur du vin.':
      'A pairing of contrast: the salt and bite of the blue are soothed by the wine\'s sweetness.',
  'Tarte Fine aux Abricots & Crème Vanillée':
      'Thin apricot tart & vanilla cream',
  'Choisir un dessert moins sucré que le vin, sinon il paraîtra plat.':
      'Choose a dessert less sweet than the wine, or the wine will taste flat.',
  'Les notes d\'abricot et de miel du vin prolongent celles du dessert.':
      'The wine\'s apricot and honey notes carry on those of the dessert.',
  'Moelleux au Chocolat Noir & Cerises Confites':
      'Dark chocolate fondant & candied cherries',
  'Servir tiède, cœur coulant, sans crème trop sucrée.':
      'Serve warm, with a molten centre, without an over-sweet cream.',
  'Le fruit confit et la douceur du vin tiennent tête à l\'amertume du cacao.':
      'The wine\'s candied fruit and sweetness stand up to the bitterness of cocoa.',
  'Stilton ou Fourme d\'Ambert & Noix':
      'Stilton or Fourme d\'Ambert & walnuts',
  'Servir le fromage à température ambiante.':
      'Serve the cheese at room temperature.',
  'L\'alcool et le sucre du vin équilibrent le sel et le gras du bleu.':
      'The wine\'s alcohol and sugar balance the salt and fat of the blue.',
  'Côte de Bœuf Maturée 45 jours au Feu de Bois & Beurre Maître d\'Hôtel':
      '45-day aged rib of beef over wood fire & maître d\'hôtel butter',
  'Saisir à feu très vif pour caraméliser la surface (réaction de Maillard), cœur saignant à 52°C.':
      'Sear over very high heat to caramelise the surface (Maillard reaction), rare at 52°C in the centre.',
  'Les protéines et le persillage de la viande désactivent l\'astringence des tannins en se liant à la proline salivaire, libérant le fruit.':
      'The meat\'s proteins and marbling tame the tannins by binding with salivary proline, releasing the fruit.',
  'Gigot d\'Agneau de 7 Heures Confit au Romarin, Ail Noir et Jus Corsé':
      '7-hour leg of lamb with rosemary, black garlic and a rich jus',
  'Cuire à couvert à 120°C pendant 7h. La gélatine fondue enrobe le palais.':
      'Cook covered at 120°C for 7 hours. The melted gelatine coats the palate.',
  'Les notes épicées et herbacées du vin épousent à la perfection les arômes de la garrigue et du romarin.':
      'The wine\'s spicy, herbal notes marry perfectly with the aromas of garrigue and rosemary.',
  'Magret de Canard Rôti aux Cerises Noires et Réduction de Poivre de Sichuan':
      'Roast duck breast with black cherries and a Sichuan pepper reduction',
  'Quadriller la peau, dégraisser à feu moyen, puis cuire côté chair 3 minutes.':
      'Score the skin, render at medium heat, then cook flesh side down for 3 minutes.',
  'L\'acidité naturelle du fruit noir équilibre la richesse lipidique du canard.':
      'The natural acidity of black fruit balances the richness of duck.',
  'Pigeon Rôti sur Coffre, Mousseline de Céleri-Rave et Jus à la Truffe':
      'Pigeon roasted on the crown, celeriac mousseline and truffle jus',
  'Cuisson rosée précise. Glacer au jus réduit monté au beurre.':
      'Cook precisely to pink. Glaze with the reduced jus mounted with butter.',
  'La délicatesse soyeuse des tanins et les notes de sous-bois exaltent la chair noble du gibier à plumes.':
      'Silky tannins and forest-floor notes lift the fine flesh of game birds.',
  'Filet Mignon de Porc Fermier aux Girolles Sautées et Noisettes Torréfiées':
      'Farm pork tenderloin with sautéed girolles and roasted hazelnuts',
  'Cuisson douce à 58°C à cœur, poêler les girolles à sec puis beurrer en fin de cuisson.':
      'Cook gently to 58°C in the centre; dry-fry the girolles, then add butter at the end.',
  'Les notes de sous-bois et de fruits rouges acidulés s\'harmonisent sans écraser la finesse de la viande blanche.':
      'Forest-floor notes and tangy red fruit blend in without overpowering the delicate meat.',
  'Tataki de Thon Rouge au Sésame Noir & Jus de Canard aux Baies Roses':
      'Bluefin tuna tataki with black sesame & duck jus with pink peppercorns',
  'Aller-retour de 30 secondes par face sur plancha brûlante. Cœur cru et soyeux.':
      '30 seconds per side on a scorching plancha. Raw, silky centre.',
  'Un rouge fluide sans tannins excessifs permet un accord audacieux terre-mer sans goût métallique.':
      'A supple red without heavy tannins makes a bold surf-and-turf pairing with no metallic taste.',
  'Dos de Bar Sauvage Rôti, Fenouil Braisé et Beurre Blanc Émulsionné':
      'Roast wild sea bass, braised fennel and whisked beurre blanc',
  'Cuisson sur peau croustillante. Monter le beurre blanc hors du feu au fouet.':
      'Cook skin side down until crisp. Whisk the beurre blanc off the heat.',
  'L\'acide tartrique vif tranche la richesse onctueuse du beurre blanc tout en révélant la minéralité iodée du poisson.':
      'Lively tartaric acidity cuts through the rich beurre blanc while bringing out the fish\'s briny minerality.',
  'Crottin de Chavignol Chaud sur Pain de Campagne & Salade de Mâche aux Noix':
      'Warm Crottin de Chavignol on country bread & lamb\'s lettuce with walnuts',
  'Gratiner 4 minutes sous le grill jusqu\'à ce que le dôme du fromage dore.':
      'Grill for 4 minutes until the top of the cheese turns golden.',
  'La fraîcheur végétale et minérale du vin sublime la texture lactique du chèvre.':
      'The wine\'s green, mineral freshness lifts the lactic texture of the goat\'s cheese.',
  'Tartare de Bar aux Fruits de la Passion et Coriandre Fraîche':
      'Sea bass tartare with passion fruit and fresh coriander',
  'Dresser minute très frais pour conserver le croquant et la vivacité.':
      'Plate at the last minute, very cold, to keep crunch and freshness.',
  'La vivacité et les notes d\'agrumes du vin entrent en résonance avec l\'acidité du fruit de la passion.':
      'The wine\'s freshness and citrus notes echo the acidity of passion fruit.',
  'Homard Bleu Rôti au Beurre de Noisette & Émulsion aux Morilles':
      'Roast blue lobster in brown butter & morel emulsion',
  'Poêler la chair du homard délicatement et napper d\'un jus corsé de carcasse crémé.':
      'Pan-fry the lobster meat gently and coat with a rich, creamy shell jus.',
  'La rondeur et l\'ampleur du vin enveloppent la sucrosité naturelle du crustacé.':
      'The wine\'s roundness and breadth wrap the natural sweetness of the lobster.',
  'Poularde de Bresse Rôtie au Vin Jaune et Morilles':
      'Roast Bresse chicken with vin jaune and morels',
  'Pocher puis rôtir doucement pour une chair ultra-moelleuse.':
      'Poach, then roast gently for very tender meat.',
  'La puissance et la trame grasse du vin soutiennent la sauce riche sans faiblir.':
      'The wine\'s power and rich texture hold up to the creamy sauce.',
  'Ravioles de Langoustines au Bouillon Thaï Citronnelle et Lait de Coco':
      'Langoustine ravioli in a Thai lemongrass and coconut milk broth',
  'Servir le bouillon fumant autour des ravioles délicates.':
      'Serve the steaming broth around the delicate ravioli.',
  'Les notes florales et fruitées du vin répondent aux arômes de la citronnelle et du coco.':
      'The wine\'s floral and fruity notes answer the lemongrass and coconut.',
  'Rougets Barbets Grillés au Romarin et Écrasé de Pommes de Terre à l\'Huile d\'Olive':
      'Grilled red mullet with rosemary and crushed potatoes in olive oil',
  'Cuisson ultra-rapide côté peau sur plancha très chaude.':
      'Cook very quickly, skin side down, on a very hot plancha.',
  'La texture phénolique légère et la salinité du rosé soutiennent le goût prononcé et iodé du rouget.':
      'The rosé\'s light phenolic texture and salinity support the strong, briny flavour of red mullet.',
  'Petits Farcis Provençaux Traditionnels & Agneau Haché aux Herbes':
      'Traditional Provençal stuffed vegetables & minced lamb with herbs',
  'Confir au four à 160°C pendant 45 minutes pour concentrer les sucs.':
      'Slow-bake at 160°C for 45 minutes to concentrate the juices.',
  'L\'acidité fruitée désaltère le palais après chaque bouchée de légumes fondants et de farce.':
      'The fruity acidity refreshes the palate after each bite of soft vegetables and stuffing.',
  'Tataki de Bœuf aux Graines de Coriandre et Huile Pimentée Douce':
      'Beef tataki with coriander seeds and mild chilli oil',
  'Servir frais en fines lamelles avec une vinaigrette légère aux agrumes.':
      'Serve cool in thin slices with a light citrus dressing.',
  'Le caractère épicé du rosé s\'associe à la fraîcheur de la viande crue sans l\'alourdir.':
      'The rosé\'s spicy side goes with the freshness of raw beef without weighing it down.',
  'Planche de Charcuteries Artisanales & Fromages Affinés du Terroir':
      'Board of artisan charcuterie & aged local cheeses',
  'Sortir les fromages et charcuteries 30 minutes avant dégustation à température ambiante.':
      'Take the cheeses and charcuterie out 30 minutes before serving, to reach room temperature.',
  'L\'équilibre entre le sel, le gras et la texture résonne avec la structure du vin.':
      'The balance of salt, fat and texture echoes the wine\'s structure.',
  'Huîtres spéciales':
      'Speciality oysters',
  'Noix de Saint-Jacques':
      'Scallops',
  'Citron caviar':
      'Finger lime',
  'Ris de veau':
      'Veal sweetbreads',
  'Morilles fraîches':
      'Fresh morels',
  'Crème crue':
      'Raw cream',
  'Beurre noisette':
      'Brown butter',
  'Comté 24 mois':
      '24-month Comté',
  'Pâte à choux':
      'Choux pastry',
  'Gruyère suisse':
      'Swiss Gruyère',
  'Poivre de Sichuan':
      'Sichuan pepper',
  'Foie gras de canard':
      'Duck foie gras',
  'Figues':
      'Figs',
  'Pain brioché':
      'Brioche',
  'Poire':
      'Pear',
  'Miel':
      'Honey',
  'Noix':
      'Walnuts',
  'Abricots':
      'Apricots',
  'Pâte feuilletée':
      'Puff pastry',
  'Vanille':
      'Vanilla',
  'Amandes':
      'Almonds',
  'Chocolat noir 70 %':
      '70% dark chocolate',
  'Cerises':
      'Cherries',
  'Beurre':
      'Butter',
  'Cacao':
      'Cocoa',
  'Fromage bleu':
      'Blue cheese',
  'Pain aux raisins':
      'Raisin bread',
  'Bœuf de race Simmental ou Black Angus':
      'Simmental or Black Angus beef',
  'Sel de Guérande':
      'Guérande salt',
  'Thym frais':
      'Fresh thyme',
  'Moelle':
      'Bone marrow',
  'Agneau de Sisteron':
      'Sisteron lamb',
  'Romarin frais':
      'Fresh rosemary',
  'Ail noir confit':
      'Candied black garlic',
  'Fond brun réduit':
      'Reduced brown stock',
  'Magret du Sud-Ouest':
      'South-West duck breast',
  'Cerises griottes':
      'Morello cherries',
  'Poivre concassé':
      'Cracked pepper',
  'Vinaigre balsamique vieux':
      'Aged balsamic vinegar',
  'Pigeon fermier':
      'Farm pigeon',
  'Céleri-rave':
      'Celeriac',
  'Beurre doux':
      'Unsalted butter',
  'Truffe noire du Périgord':
      'Périgord black truffle',
  'Filet mignon':
      'Pork tenderloin',
  'Girolles fraîches':
      'Fresh girolles',
  'Persil plat':
      'Flat-leaf parsley',
  'Noisettes concassées':
      'Crushed hazelnuts',
  'Thon rouge frais':
      'Fresh bluefin tuna',
  'Graines de sésame':
      'Sesame seeds',
  'Sauce soja réduite':
      'Reduced soy sauce',
  'Baie rose':
      'Pink peppercorn',
  'Bar de ligne':
      'Line-caught sea bass',
  'Fenouil sauvage':
      'Wild fennel',
  'Échalote grise':
      'Grey shallot',
  'Vin blanc sec':
      'Dry white wine',
  'Chavignol affiné':
      'Aged Chavignol',
  'Pain au levain':
      'Sourdough bread',
  'Mâche fraîche':
      'Fresh lamb\'s lettuce',
  'Huile de noix':
      'Walnut oil',
  'Chair de bar':
      'Sea bass flesh',
  'Fruit de la passion':
      'Passion fruit',
  'Coriandre':
      'Coriander',
  'Échalote':
      'Shallot',
  'Homard breton':
      'Breton lobster',
  'Beurre salé':
      'Salted butter',
  'Crème double':
      'Double cream',
  'Poularde fermière AOP':
      'PDO farm-raised poularde',
  'Morilles':
      'Morels',
  'Crème d\'Isigny':
      'Isigny cream',
  'Échalotes':
      'Shallots',
  'Lait de coco':
      'Coconut milk',
  'Citronnelle':
      'Lemongrass',
  'Gingembre doux':
      'Mild ginger',
  'Rougets frais':
      'Fresh red mullet',
  'Romarin':
      'Rosemary',
  'Huile d\'olive AOP':
      'PDO olive oil',
  'Courgettes rondes':
      'Round courgettes',
  'Tomates':
      'Tomatoes',
  'Chair d\'agneau':
      'Lamb',
  'Sarriette':
      'Summer savory',
  'Filet de bœuf':
      'Beef fillet',
  'Piment doux d\'Espelette':
      'Mild Espelette pepper',
  'Ciboulette':
      'Chives',
  'Jambon affiné':
      'Cured ham',
  'Fromage au lait cru':
      'Raw-milk cheese',
  'Cornichons':
      'Gherkins',
};
