import 'bottle.dart';
import 'wine.dart';

enum FoodMatchLevel {
  ideal('Accord Idéal', 0xFFD4AF37),
  harmonious('Accord Harmonieux', 0xFF4CAF50),
  gourmet('Accord Gourmand', 0xFF2196F3),
  subtle('Accord Délicat', 0xFF9C27B0);

  final String label;
  final int colorValue;
  const FoodMatchLevel(this.label, this.colorValue);

  String localizedLabel([dynamic lang]) {
    final langCode = (lang is String && lang.isNotEmpty)
        ? lang
        : (lang != null && lang is Object && lang.runtimeType.toString().contains('Locale') ? (lang as dynamic).languageCode as String : 'fr');
    switch (this) {
      case FoodMatchLevel.ideal:
        switch (langCode) {
          case 'en': return 'Ideal Match 🌟';
          case 'es': return 'Maridaje Ideal 🌟';
          case 'it': return 'Abbinamento ideale 🌟';
          case 'ca': return 'Maridatge Ideal 🌟';
          case 'la': return 'Harmonia Optima 🌟';
          default: return 'Accord Idéal 🌟';
        }
      case FoodMatchLevel.harmonious:
        switch (langCode) {
          case 'en': return 'Harmonious Match ✨';
          case 'es': return 'Maridaje Armonioso ✨';
          case 'it': return 'Abbinamento armonioso ✨';
          case 'ca': return 'Maridatge Harmoniós ✨';
          case 'la': return 'Harmonia Concordans ✨';
          default: return 'Accord Harmonieux ✨';
        }
      case FoodMatchLevel.gourmet:
        switch (langCode) {
          case 'en': return 'Gourmet Match 🍷';
          case 'es': return 'Maridaje Gourmet 🍷';
          case 'it': return 'Abbinamento goloso 🍷';
          case 'ca': return 'Maridatge Gourmet 🍷';
          case 'la': return 'Harmonia Lauta 🍷';
          default: return 'Accord Gourmand 🍷';
        }
      case FoodMatchLevel.subtle:
        switch (langCode) {
          case 'en': return 'Delicate Match 🥂';
          case 'es': return 'Maridaje Delicado 🥂';
          case 'it': return 'Abbinamento delicato 🥂';
          case 'ca': return 'Maridatge Delicat 🥂';
          case 'la': return 'Harmonia Subtilis 🥂';
          default: return 'Accord Délicat 🥂';
        }
    }
  }
}

class FoodPairingCategory {
  final String id;
  final String label;
  final String icon;
  final List<String> sampleDishes;
  final List<String> keywords;

  const FoodPairingCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.sampleDishes,
    required this.keywords,
  });

  String localizedLabel([dynamic lang]) {
    final langCode = _codeDeLangue(lang);
    if (langCode == 'fr') return label;
    return _noms[id]?[langCode] ?? _noms[id]?['en'] ?? label;
  }

  List<String> getSampleDishes([dynamic lang]) {
    final langCode = _codeDeLangue(lang);
    if (langCode == 'fr') return sampleDishes;
    return _plats[id]?[langCode] ?? _plats[id]?['en'] ?? sampleDishes;
  }

  static String _codeDeLangue(dynamic lang) => (lang is String && lang.isNotEmpty)
      ? lang
      : (lang != null && lang.runtimeType.toString().contains('Locale') ? (lang as dynamic).languageCode as String : 'fr');

  /// Le nom de chaque catégorie hors du français ([label]). Une langue absente : l'anglais.
  static const Map<String, Map<String, String>> _noms = {
    'red_meat': {
      'en': 'Red Meat & Grills',
      'es': 'Carnes Rojas y Parrilla',
      'it': 'Carni rosse e grigliate',
      'ca': 'Carns Vermelles i Graella',
      'la': 'Carnes Rubrae & Assaturae',
    },
    'game_stew': {
      'en': 'Game & Stews',
      'es': 'Caza y Guisos',
      'it': 'Selvaggina e stufati',
      'ca': 'Caça i Guisats',
      'la': 'Venatio & Cibaria Cocta',
    },
    'poultry_veal': {
      'en': 'Noble Poultry & Veal',
      'es': 'Aves Nobles y Ternera',
      'it': 'Pollame pregiato e vitello',
      'ca': 'Aus Nobles i Vedella',
      'la': 'Aves Nobiles & Vitulina',
    },
    'delicate_fish': {
      'en': 'Delicate Fish & White Butter',
      'es': 'Pescados Finos y Mantequilla',
      'it': 'Pesci delicati e burro bianco',
      'ca': 'Peixos Fins i Mantega Blanca',
      'la': 'Pisces Subtiles & Butyrum',
    },
    'fatty_fish_sushi': {
      'en': 'Fatty Fish, Sushi & Ceviche',
      'es': 'Pescados Grasos, Sushi y Ceviche',
      'it': 'Pesci grassi, sushi e ceviche',
      'ca': 'Peixos Grassos, Sushi i Ceviche',
      'la': 'Pisces Pingues, Sushi & Ceviche',
    },
    'seafood_shellfish': {
      'en': 'Seafood, Oysters & Shellfish',
      'es': 'Mariscos, Ostras y Crustáceos',
      'it': 'Frutti di mare, ostriche e crostacei',
      'ca': 'Marisc i Ostres',
      'la': 'Ostrea & Fructus Marini',
    },
    'goat_sheep_cheese': {
      'en': 'Goat & Sheep Cheeses',
      'es': 'Quesos de Cabra y Oveja',
      'it': 'Formaggi di capra e di pecora',
      'ca': 'Formatges de Cabra i Ovelles',
      'la': 'Casei Caprini & Ovinici',
    },
    'cow_pressed_cheese': {
      'en': 'Cow\'s Milk & Aged Cheeses',
      'es': 'Quesos de Vaca y Curados',
      'it': 'Formaggi vaccini e stagionati',
      'ca': 'Formatges Curats',
      'la': 'Casei Vetusti',
    },
    'winter_melted_cheese': {
      'en': 'Raclette, Fondue & Winter Dishes',
      'es': 'Raclette, Fondue y Platos de Invierno',
      'it': 'Raclette, fonduta e piatti invernali',
      'ca': 'Raclet, Fondue i Plats d\'Hivern',
      'la': 'Raclette & Fondue',
    },
    'mushrooms_truffle': {
      'en': 'Mushrooms, Risottos & Truffles',
      'es': 'Setas, Risottos y Trufas',
      'it': 'Funghi, risotti e tartufi',
      'ca': 'Bolets, Risottos i Tòfones',
      'la': 'Fungi, Risotto & Tubera',
    },
    'italian_pasta_pizza': {
      'en': 'Pasta, Pizza & Italian Flavors',
      'es': 'Pastas, Pizzas y Sabores Italianos',
      'it': 'Pasta, pizza e sapori italiani',
      'ca': 'Pastes, Pizzes i Sabors Italians',
      'la': 'Pasta, Pizza & Sapores Italici',
    },
    'french_terroir': {
      'en': 'French Terroir & Tradition',
      'es': 'Tradición y Terruño Francés',
      'it': 'Tradizione e terroir francesi',
      'ca': 'Tradició i Terroir Francès',
      'la': 'Traditio Gallica & Rusticitas',
    },
    'spicy_oriental': {
      'en': 'Spicy Dishes, Couscous & Curries',
      'es': 'Cocina Picante, Cuscús y Tajines',
      'it': 'Cucina speziata, couscous e tajine',
      'ca': 'Cuina Picant, Cuscus i Tagins',
      'la': 'Cibaria Condita & Tajine',
    },
    'asian_street_food': {
      'en': 'Asian Cuisine, Wok & Street Food',
      'es': 'Cocina Asiática, Wok y Street Food',
      'it': 'Cucina asiatica, wok e street food',
      'ca': 'Cuina Asiàtica, Wok i Street Food',
      'la': 'Cibaria Asiatica & Wok',
    },
    'tapas_aperitif': {
      'en': 'Tapas, Cured Meats & Foie Gras',
      'es': 'Tapas, Embutidos y Foie Gras',
      'it': 'Tapas, salumi e foie gras',
    },
    'dessert': {
      'en': 'Desserts, Tarts & Chocolate',
      'es': 'Postres, Tartas y Chocolate',
      'it': 'Dessert, crostate e cioccolato',
    },
    'salads': {
      'en': 'Main-Course Salads',
      'es': 'Ensaladas completas',
      'it': 'Insalate composte',
    },
    'vegetarian': {
      'en': 'Vegetables & Vegetarian Dishes',
      'es': 'Verduras y cocina vegetariana',
      'it': 'Verdure e cucina vegetariana',
    },
    'soups': {
      'en': 'Soups, Bisques & Veloutés',
      'es': 'Sopas, cremas y bisques',
      'it': 'Zuppe, vellutate e bisque',
    },
    'eggs_savoury_tarts': {
      'en': 'Eggs, Quiches & Savoury Tarts',
      'es': 'Huevos, quiches y tartas saladas',
      'it': 'Uova, quiche e torte salate',
    },
  };

  /// Les plats d'exemple hors du français ([sampleDishes]). Une langue absente : l'anglais.
  static const Map<String, Map<String, List<String>>> _plats = {
    'red_meat': {
      'en': ['Grilled Prime Rib', 'Ribeye steak', 'Duck breast', 'Tournedos Rossini', 'Beef Tartare', 'Roast leg of lamb with thyme', 'BBQ Picanha', 'Bavette steak with shallots', 'Seven-hour slow-roasted leg of lamb', 'Herb-crusted rack of lamb', 'Beef burger with cheddar', 'Grilled lamb chops with rosemary'],
      'es': ['Chuletón de buey a la brasa', 'Entrecot', 'Magret de pato', 'Tournedos Rossini', 'Tartar de buey', 'Pierna de cordero al tomillo', 'Picanha a la barbacoa', 'Bavette con chalotas', 'Pierna de cordero a las siete horas', 'Costillar de cordero en costra de hierbas', 'Hamburguesa de ternera con cheddar', 'Chuletas de cordero a la parrilla con romero'],
      'it': ['Costata di manzo alla griglia', 'Entrecôte al prezzemolo', 'Petto d\'anatra', 'Tournedos Rossini', 'Tartare di manzo', 'Cosciotto d\'agnello al timo', 'Picanha al barbecue', 'Bavetta allo scalogno', 'Cosciotto d\'agnello cotto sette ore', 'Carré d\'agnello in crosta di erbe', 'Hamburger di manzo al cheddar', 'Costolette d\'agnello alla griglia con rosmarino'],
      'ca': ['Mitjana de bou a la brasa', 'Entrecot', 'Magret d\'ànec', 'Tournedos Rossini', 'Tàrtar de vedella', 'Cuixa de xai amb farigola', 'Picanha a la barbacoa', 'Bavette amb escalunyes'],
      'la': ['Costa bubula assa', 'Entrecot', 'Magret anatis', 'Tournedos Rossini', 'Tartare bubulum', 'Crus agninum thymo conditum', 'Assatura Picanha', 'Bavette cepis condita'],
    },
    'game_stew': {
      'en': ['Beef Bourguignon', 'Provençal beef stew', 'Wild boar stew', 'Hare à la Royale', 'Venison with lingonberries', 'Pot-au-feu', 'Flemish carbonnade', 'Hungarian Goulash', 'Spring lamb navarin', 'Beef cheeks braised in red wine', 'Venison haunch with grand veneur sauce'],
      'es': ['Ternera a la borgoñona', 'Estofado provenzal', 'Civet de jabalí', 'Liebre a la royale', 'Venado con arándanos', 'Pot-au-feu', 'Carbonada flamenca', 'Gulash húngaro', 'Navarin de cordero primaveral', 'Estofado de carrillera de ternera al vino tinto', 'Pierna de venado con salsa grand veneur'],
      'it': ['Manzo alla borgognona', 'Stufato alla provenzale', 'Civet di cinghiale', 'Lepre alla royale', 'Capriolo ai mirtilli rossi', 'Pot-au-feu', 'Carbonade fiamminga', 'Gulasch ungherese', 'Navarin d\'agnello primaverile', 'Guancia di manzo brasata al vino rosso', 'Cosciotto di capriolo in salsa grand veneur'],
      'ca': ['Vedella a la borgonyona', 'Guisat provençal', 'Civet de senglar', 'Llebre a la royale', 'Cérvol amb nabius', 'Pot-au-feu', 'Carbonada flamenca', 'Gulaix hongarès'],
      'la': ['Bubula Burgundica', 'Daube Provincialis', 'Aper conditus', 'Lepus regalis', 'Cervina vaccinium', 'Pot-au-feu', 'Carbonnade Flandrica', 'Goulash Hungaricum'],
    },
    'poultry_veal': {
      'en': ['Roast farm chicken', 'Veal blanquette', 'Capon with chestnuts', 'Veal roast with morels', 'Veal Milanese', 'Guinea fowl with herbs', 'Duck à l\'orange', 'Coq au vin', 'Basque-style chicken', 'Chicken supreme in cream sauce', 'Roast veal with carrots'],
      'es': ['Pollo asado de granja', 'Blanqueta de ternera', 'Capón con castañas', 'Ternera lechal con colmenillas', 'Milanesa de ternera', 'Pintada con hierbas', 'Pato a la naranja', 'Gallo al vino (Coq au vin)', 'Pollo a la vasca', 'Pechuga de pollo a la crema', 'Ternera lechal asada con zanahorias'],
      'it': ['Pollo ruspante arrosto', 'Blanquette di vitello', 'Cappone alle castagne', 'Arrosto di vitello alle spugnole', 'Cotoletta alla milanese', 'Faraona alle erbe', 'Anatra all\'arancia', 'Coq au vin', 'Pollo alla basca', 'Petto di pollo alla crema', 'Arrosto di vitello alle carote'],
      'ca': ['Pollastre rostit de pagès', 'Blanqueta de vedella', 'Capó amb castanyes', 'Vedella amb múrgoles', 'Milanesa de vedella', 'Pintada amb herbes', 'Ànec a la taronja', 'Gall al vi (Coq au vin)'],
      'la': ['Pullus rusticus assus', 'Vitulina alba', 'Capo castaneis', 'Vitulina morchellis', 'Escalopa Mediolanensis', 'Gallina Numidica', 'Anas aurantio condita', 'Gallus vino coctus'],
    },
    'delicate_fish': {
      'en': ['Sole meunière', 'Baked sea bass', 'Turbot in white butter sauce', 'Steamed cod loin', 'Pan-seared John Dory', 'Grilled sea bream', 'Monkfish armoricaine', 'Trout with almonds', 'Salt cod brandade', 'Skate wing with brown butter and capers', 'Salt-crusted sea bass'],
      'es': ['Lenguado meunière', 'Lubina al horno', 'Rodaballo con mantequilla blanca', 'Lomo de bacalao al vapor', 'San Pedro a la plancha', 'Dorada a la plancha', 'Rape a la armoricana', 'Trucha a la almendra', 'Brandada de bacalao', 'Raya con mantequilla avellana y alcaparras', 'Lubina a la sal'],
      'it': ['Sogliola alla mugnaia', 'Branzino al forno', 'Rombo al burro bianco', 'Filetto di merluzzo al vapore', 'Pesce San Pietro in padella', 'Orata alla griglia', 'Rana pescatrice all\'armoricana', 'Trota alle mandorle', 'Brandade di baccalà', 'Razza al burro nocciola e capperi', 'Branzino al sale'],
      'ca': ['Llenguado meunière', 'Llobarro al forn', 'Rèmol amb mantega blanca', 'Llom de bacallà al vapor', 'Sant Pere a la planxa', 'Orada a la graella', 'Rap a l\'armoricana', 'Truita amb ametlles'],
      'la': ['Solea meuniere', 'Lupus marinus assus', 'Turbot butyro albo', 'Asellus vaporatus', 'Zeus faber frictus', 'Aurata assa', 'Lophius Armoricus', 'Trutta amygdalis'],
    },
    'fatty_fish_sushi': {
      'en': ['Grilled salmon', 'Bluefin tuna tataki', 'Assorted sushi & sashimi', 'Peruvian ceviche', 'Salmon tartare with avocado', 'Grilled mackerel', 'Poké bowl', 'Eel teriyaki', 'Salmon gravlax with dill', 'Grilled mackerel with lemon', 'Salmon chirashi bowl'],
      'es': ['Salmón a la plancha', 'Tataki de atún rojo', 'Sushi y sashimi variados', 'Ceviche peruano', 'Tartar de salmón y aguacate', 'Caballa a la parrilla', 'Poké bowl', 'Anguila teriyaki', 'Gravlax de salmón al eneldo', 'Caballa a la parrilla con limón', 'Chirashi de salmón'],
      'it': ['Salmone alla griglia', 'Tataki di tonno rosso', 'Sushi e sashimi misti', 'Ceviche peruviano', 'Tartare di salmone e avocado', 'Sgombro alla griglia', 'Poke bowl', 'Anguilla teriyaki', 'Gravlax di salmone all\'aneto', 'Sgombro alla griglia al limone', 'Chirashi al salmone'],
      'ca': ['Salmó a la planxa', 'Tataki de tonyina vermella', 'Sushi i sashimi variats', 'Ceviche peruà', 'Tàrtar de salmó i alvocat', 'Seitó a la graella', 'Poké bowl', 'Anguila teriyaki'],
      'la': ['Salmo assus', 'Tataki thunni rubri', 'Sushi & sashimi varia', 'Ceviche Peruvianum', 'Tartare salmonis', 'Scomber assus', 'Poke bowl', 'Anguilla teriyaki'],
    },
    'seafood_shellfish': {
      'en': ['Fine Brittany oysters', 'Pan-seared sea scallops', 'Blue lobster with butter', 'Roasted Dublin Bay prawns', 'Garlic butter razor clams', 'Moules marinières', 'Seafood platter', 'Spider crab', 'Fines de claire oysters', 'Seafood platter', 'Seafood paella', 'Grilled squid'],
      'es': ['Ostras de Bretaña', 'Vieiras a la plancha', 'Bogavante con mantequilla', 'Cigalas asadas', 'Navajas al ajillo', 'Mejillones a la marinera', 'Bandeja de marisco', 'Centollo', 'Ostras fines de claire', 'Bandeja de mariscos', 'Paella de marisco', 'Calamares a la plancha'],
      'it': ['Ostriche di Bretagna', 'Capesante scottate', 'Astice al burro', 'Scampi arrosto', 'Cannolicchi aglio e burro', 'Cozze alla marinara', 'Plateau di frutti di mare', 'Grancevola', 'Ostriche fines de claire', 'Plateau di frutti di mare', 'Paella ai frutti di mare', 'Calamari alla piastra'],
      'ca': ['Ostres de Bretanya', 'Vieires a la planxa', 'Llamàntol amb mantega', 'Escamarlans rostits', 'Navalles a l\'all', 'Musclos a la marinera', 'Plat de marisc', 'Cranc'],
      'la': ['Ostreae Armoricae', 'Pectines fricti', 'Astacus butyro', 'Nephrops assus', 'Solenes allio', 'Mytili marinarii', 'Fructus marini varii', 'Maja squinado'],
    },
    'goat_sheep_cheese': {
      'en': ['Warm Chavignol goat cheese', 'Sainte-Maure-de-Touraine', 'Rocamadour with honey', 'Valençay pyramid', 'Selles-sur-Cher', 'Artisan sheep cheese', 'Ossau-Iraty with cherry jam', 'Greek feta', 'Pélardon goat cheese from the Cévennes', 'Ossau-Iraty with black cherry jam', 'Tuscan pecorino'],
      'es': ['Queso de cabra Chavignol caliente', 'Sainte-Maure-de-Touraine', 'Rocamadour con miel', 'Pirámide de Valençay', 'Selles-sur-Cher', 'Queso artesano de oveja', 'Ossau-Iraty con mermelada', 'Feta griega', 'Pélardon de las Cevenas', 'Ossau-Iraty con mermelada de cereza negra', 'Pecorino toscano'],
      'it': ['Crottin de Chavignol caldo', 'Sainte-Maure-de-Touraine', 'Rocamadour al miele', 'Piramide di Valençay', 'Selles-sur-Cher', 'Pecorino artigianale', 'Ossau-Iraty con confettura di ciliegie', 'Feta greca', 'Pélardon delle Cevenne', 'Ossau-Iraty con confettura di ciliegie nere', 'Pecorino toscano'],
      'ca': ['Formatge de cabra Chavignol calent', 'Sainte-Maure-de-Touraine', 'Rocamadour amb mel', 'Piràmide de Valençay', 'Selles-sur-Cher', 'Formatge artesanal d\'ovella', 'Ossau-Iraty amb melmelada', 'Feta grega'],
      'la': ['Caseus caprinus Chavignol', 'Sainte-Maure-de-Touraine', 'Rocamadour melle', 'Valençay', 'Selles-sur-Cher', 'Caseus ovinus', 'Ossau-Iraty cerasis', 'Caseus Graecus Feta'],
    },
    'cow_pressed_cheese': {
      'en': ['Comté aged 24 months', 'Beaufort d\'alpage', 'Aged Parmigiano Reggiano', 'Farmhouse Cantal', 'Swiss Gruyère reserve', 'Saint-Nectaire fermier', 'Aged Cheddar', 'Manchego curado', 'Alpine summer Beaufort', 'Extra-aged Mimolette', '24-month Parmigiano Reggiano'],
      'es': ['Comté curado 24 meses', 'Beaufort de pasto alpino', 'Parmesano curado', 'Cantal de granja', 'Gruyer suizo reserva', 'Saint-Nectaire artesano', 'Cheddar curado', 'Manchego curado', 'Beaufort de alpage', 'Mimolette extra vieja', 'Parmigiano Reggiano 24 meses'],
      'it': ['Comté stagionato 24 mesi', 'Beaufort d\'alpeggio', 'Parmigiano Reggiano stravecchio', 'Cantal di fattoria', 'Gruyère svizzero riserva', 'Saint-Nectaire fermier', 'Cheddar stagionato', 'Manchego curado', 'Beaufort d\'alpeggio', 'Mimolette stravecchia', 'Parmigiano Reggiano 24 mesi'],
      'ca': ['Comté curat 24 mesos', 'Beaufort d\'alta muntanya', 'Parmesà curat', 'Cantal de granja', 'Gruyère suís reserva', 'Saint-Nectaire artesanal', 'Cheddar curat', 'Manxego curat'],
      'la': ['Caseus Comté 24 mensium', 'Beaufort alpinus', 'Parmigiano Reggiano vetustum', 'Cantal rusticum', 'Gruyere Helvetium', 'Saint-Nectaire rusticum', 'Cheddar vetustum', 'Manchego curatum'],
    },
    'winter_melted_cheese': {
      'en': ['Traditional Savoyard raclette', 'Swiss cheese fondue', 'Tartiflette with Reblochon', 'Mont d\'Or chaud with potatoes', 'Croziflette with bacon', 'Aligot with Aveyron sausage', 'Fondue bourguignonne', 'Baked Mont d\'Or', 'Aubrac aligot (cheesy mashed potatoes)', 'Auvergne truffade'],
      'es': ['Raclette saboyana tradicional', 'Fondue de quesos suizos', 'Tartiflette con Reblochon', 'Mont d\'Or caliente con patatas', 'Croziflette con panceta', 'Aligot con salchicha de Aveyron', 'Fondue bourguignonne', 'Mont d\'Or al horno', 'Aligot de Aubrac', 'Truffade de Auvernia'],
      'it': ['Raclette savoiarda tradizionale', 'Fonduta di formaggi svizzeri', 'Tartiflette al Reblochon', 'Mont d\'Or caldo con patate', 'Croziflette con pancetta', 'Aligot con salsiccia dell\'Aveyron', 'Fondue bourguignonne', 'Mont d\'Or al forno', 'Aligot dell\'Aubrac', 'Truffade alverniate'],
      'ca': ['Raclet savoiarda tradicional', 'Fondue de formatges suïssos', 'Tartiflette amb Reblochon', 'Mont d\'Or calent amb patates', 'Croziflette amb cansalada', 'Aligot amb salsitxa de l\'Aveyron', 'Fondue bourguignonne'],
      'la': ['Raclette Sabaudica', 'Fondue Helvetica', 'Tartiflette Reblochon', 'Mont d\'Or calidum', 'Croziflette', 'Aligot farcimine', 'Fondue Burgundica'],
    },
    'mushrooms_truffle': {
      'en': ['Creamy porcini risotto', 'Fresh black truffle pasta', 'Pan-seared fresh morels', 'Truffle omelette', 'Sautéed chanterelles with parsley', 'Chestnut and porcini soup', 'Saffron and morel risotto', 'Baked egg with morels', 'Tagliatelle with chanterelles', 'Mushroom vol-au-vent'],
      'es': ['Risotto cremoso de boletus', 'Pasta fresca con trufa negra', 'Salteado de colmenillas frescas', 'Tortilla de trufas', 'Rebozuelos salteados al perejil', 'Crema de castañas y boletus', 'Risotto al azafrán con colmenillas', 'Huevo en cocotte con colmenillas', 'Tallarines con rebozuelos', 'Volován de setas'],
      'it': ['Risotto cremoso ai porcini', 'Pasta fresca al tartufo nero', 'Spugnole fresche in padella', 'Frittata al tartufo', 'Finferli saltati al prezzemolo', 'Vellutata di castagne e porcini', 'Risotto allo zafferano e spugnole', 'Uovo in cocotte alle spugnole', 'Tagliatelle ai finferli', 'Vol-au-vent ai funghi'],
      'ca': ['Risotto cremós de ceps', 'Pasta fresca amb tòfona negra', 'Saltejat de múrgoles fresques', 'Truita de tòfona', 'Rossinyols saltejats al julivert', 'Crema de castanyes i ceps', 'Risotto al safrà amb múrgoles'],
      'la': ['Risotto boletis edulibus', 'Pasta tuberibus nigris', 'Morchellae frictae', 'Omelette tuberibus', 'Cantharelli fricti', 'Iusculum castaneis & boletis', 'Risotto croco et morchellis'],
    },
    'italian_pasta_pizza': {
      'en': ['Wood-fired Pizza Margherita', 'Homemade lasagne bolognese', 'Spaghetti Carbonara tradizionale', 'Spaghetti alle Vongole', 'Beef carpaccio with parmesan', 'Burrata di Bufala & sundried tomatoes', 'Sicilian arancini', 'Penne all\'arrabbiata', 'Gnocchi with Genovese pesto', 'Ricotta and spinach ravioli'],
      'es': ['Pizza Margherita al horno de leña', 'Lasaña boloñesa casera', 'Spaghetti Carbonara tradizionale', 'Spaghetti alle Vongole', 'Carpaccio de buey al parmesano', 'Burrata di Bufala con tomates confitados', 'Arancini sicilianos', 'Penne all\'arrabbiata', 'Ñoquis al pesto genovés', 'Raviolis de ricotta y espinacas'],
      'it': ['Pizza Margherita cotta a legna', 'Lasagne alla bolognese fatte in casa', 'Spaghetti alla carbonara', 'Spaghetti alle vongole', 'Carpaccio di manzo al parmigiano', 'Burrata di bufala e pomodori secchi', 'Arancini siciliani', 'Penne all\'arrabbiata', 'Gnocchi al pesto genovese', 'Ravioli ricotta e spinaci'],
      'ca': ['Pizza Margherita al forn de llenya', 'Lasanya bolonyesa casolana', 'Spaghetti Carbonara tradizionale', 'Spaghetti alle Vongole', 'Carpaccio de vedella al parmesà', 'Burrata di Bufala amb tomàquets confitats', 'Arancini sicilians'],
      'la': ['Pizza Margherita camino assa', 'Lasagna Bononiensis', 'Spaghetti Carbonara tradizionale', 'Spaghetti conchis (alle Vongole)', 'Carpaccio bubulum caseo Parmensi', 'Burrata di Bufala & lycopersica', 'Arancini Siculi'],
    },
    'french_terroir': {
      'en': ['Castelnaudary Cassoulet', 'Royal garnie sauerkraut', 'Pork belly with Puy green lentils', 'Black pudding with caramelized apples', 'Grilled Troyes andouillette', 'Alsatian Baeckeoffe', 'Caen-style tripe', 'Morteau sausage with lentils', 'Hachis parmentier (French shepherd\'s pie)', 'Auvergne pork and cabbage potée'],
      'es': ['Cassoulet de Castelnaudary', 'Chucrut real garnie', 'Lentejas verdes del Puy con cerdo', 'Morcilla con manzanas caramelizadas', 'Andouillette de Troyes a la parrilla', 'Baeckeoffe alsaciano', 'Callos a la moda de Caen', 'Salchicha de Morteau con lentejas', 'Hachis parmentier', 'Potée de Auvernia'],
      'it': ['Cassoulet di Castelnaudary', 'Choucroute reale guarnita', 'Pancetta con lenticchie verdi di Puy', 'Sanguinaccio con mele caramellate', 'Andouillette di Troyes alla griglia', 'Baeckeoffe alsaziano', 'Trippa alla moda di Caen', 'Salsiccia di Morteau con lenticchie', 'Hachis parmentier', 'Potée alverniate'],
      'ca': ['Caçolet de Castelnaudary', 'Choucroute reial guarnida', 'Llenties verdes del Puy amb porc', 'Botifarra negra amb pomes caramel·litzades', 'Andouillette de Troyes a la graella', 'Baeckeoffe alsacià', 'Tripes a la moda de Caen'],
      'la': ['Cassoulet Castelnaudariense', 'Caulis acidus regalis', 'Lenticulae Podienses porco conditae', 'Fartum nigrum malis', 'Andouillette assa', 'Baeckeoffe Alsaticum', 'Fiscellus Cadomensis'],
    },
    'spicy_oriental': {
      'en': ['Royal Couscous with 3 meats', 'Chicken tagine with preserved lemons', 'Indian Butter Chicken', 'Lamb Madras curry', 'Creole Colombo chicken', 'Reunion Island sausage rougail', 'Chili con carne', 'Chicken pastilla with almonds', 'Lamb kofta with mint', 'Red lentil dahl', 'Vegetable coconut curry'],
      'es': ['Cuscús real 3 carnes', 'Tajine de pollo con limones confitados', 'Butter Chicken indio', 'Curry de cordero Madrás', 'Pollo Colombo antillano', 'Rougail criollo de salchicha', 'Chili con carne', 'Pastela de pollo con almendras', 'Kefta de cordero con menta', 'Dahl de lentejas rojas', 'Curry de verduras con leche de coco'],
      'it': ['Couscous reale con 3 carni', 'Tajine di pollo ai limoni confit', 'Butter chicken indiano', 'Curry di agnello Madras', 'Pollo Colombo creolo', 'Rougail di salsiccia creolo', 'Chili con carne', 'Pastilla di pollo alle mandorle', 'Kofta d\'agnello alla menta', 'Dahl di lenticchie rosse', 'Curry di verdure al latte di cocco'],
      'ca': ['Cuscús reial 3 carns', 'Tagin de pollastre amb llimones confitades', 'Butter Chicken indi', 'Curri de xai Madràs', 'Pollastre Colombo antillà', 'Rougail crioll de salsitxes', 'Chili con carne'],
      'la': ['Couscous regale 3 carnibus', 'Tajine pulli citris conditis', 'Butter Chicken Indicum', 'Curry agnini Madras', 'Pullus Colombo Antillanus', 'Rougail farciminis', 'Chili con carne'],
    },
    'asian_street_food': {
      'en': ['Peking duck', 'Shrimp Pad Thai', 'Vietnamese Beef Bo Bun', 'Steamed Pork & Prawn Dim Sum', 'Japanese Tonkotsu Ramen', 'Chicken Yakitori skewers', 'Chicken Gyoza', 'Crispy spring rolls (nems) with mint', 'Korean bibimbap', 'Japanese pan-fried gyozas'],
      'es': ['Pato laqueado a la pequinesa', 'Pad Thai con gambas', 'Bo Bun vietnamita de buey', 'Dim Sum al vapor cerdo y gambas', 'Ramen Tonkotsu japonés', 'Brochetas Yakitori de pollo', 'Gyozas crujientes de pollo', 'Nems crujientes con menta', 'Bibimbap coreano', 'Gyozas a la plancha'],
      'it': ['Anatra laccata alla pechinese', 'Pad Thai ai gamberi', 'Bo Bun vietnamita al manzo', 'Dim sum al vapore di maiale e gamberi', 'Ramen Tonkotsu giapponese', 'Spiedini yakitori di pollo', 'Gyoza di pollo', 'Nem croccanti alla menta', 'Bibimbap coreano', 'Gyoza alla piastra'],
      'ca': ['Ànec laquejat a la pequinesa', 'Pad Thai amb gambes', 'Bo Bun vietnamita de vedella', 'Dim Sum al vapor porc i gambes', 'Ramen Tonkotsu japonès', 'Broquetes Yakitori de pollastre', 'Gyoza cruixent de pollastre'],
      'la': ['Anas Pekinensis laqueata', 'Pad Thai squillis', 'Bo Bun bubulum Vietnamense', 'Dim Sum vapore coctum', 'Tonkotsu Ramen Iaponicum', 'Yakitori assatum pulli', 'Gyoza fricta'],
    },
    'tapas_aperitif': {
      'en': ['Pata Negra ham platter', 'Foie gras mi-cuit on toast', 'Provençal tapenade & anchoïade', 'Warm cheese gougères', 'Assorted Basque pintxos', 'Argentinian empanadas', 'Niçoise pissaladière', 'Rillettes from Le Mans', 'Iberian ham croquetas', 'Dry-cured saucisson with gherkins', 'Garlic prawns (gambas al ajillo)'],
      'es': ['Tabla de jamón Pata Negra', 'Foie gras mi-cuit sobre tostada', 'Tapenade y anchoïade provenzales', 'Gougères de queso calientes', 'Pintxos vascos variados', 'Empanadas argentinas', 'Pissaladière nizarda', 'Rillettes de Le Mans', 'Croquetas de jamón ibérico', 'Embutidos: salchichón y pepinillos', 'Gambas al ajillo'],
      'it': ['Tagliere di prosciutto Pata Negra', 'Foie gras mi-cuit su crostino', 'Tapenade e anchoïade provenzali', 'Gougères calde al formaggio', 'Pintxos baschi misti', 'Empanadas argentine', 'Pissaladière nizzarda', 'Rillettes di Le Mans', 'Crocchette di prosciutto iberico', 'Salame stagionato e cetriolini', 'Gamberi all\'aglio'],
    },
    'dessert': {
      'en': ['Molten chocolate cake', 'Warm tarte Tatin with cream', 'Lemon meringue tart', 'Bourbon vanilla crème brûlée', 'Italian coffee tiramisu', 'Grand Marnier soufflé', 'Profiteroles with hot chocolate', 'Vanilla mille-feuille', 'Praline Paris-Brest', 'Red berry pavlova', 'Rum baba', 'Crêpes Suzette'],
      'es': ['Coulant de chocolate', 'Tarta Tatin tibia con nata', 'Tarta de limón merengada', 'Crème brûlée de vainilla Bourbon', 'Tiramisú italiano al café', 'Soufflé al Grand Marnier', 'Profiteroles con chocolate caliente', 'Milhojas de vainilla', 'Paris-Brest de praliné', 'Pavlova de frutos rojos', 'Baba al ron', 'Crepes Suzette'],
      'it': ['Tortino al cioccolato dal cuore fondente', 'Tarte Tatin tiepida con panna', 'Crostata al limone meringata', 'Crème brûlée alla vaniglia Bourbon', 'Tiramisù al caffè', 'Soufflé al Grand Marnier', 'Profiteroles al cioccolato caldo', 'Millefoglie alla vaniglia', 'Paris-Brest al pralinato', 'Pavlova ai frutti rossi', 'Babà al rum', 'Crêpes Suzette'],
    },
    'salads': {
      'en': ['Warm goat cheese salad', 'Niçoise salad', 'Chicken Caesar salad', 'Lyonnaise salad with bacon and a poached egg', 'Greek salad with feta', 'Lebanese herb tabbouleh', 'Heirloom tomato and burrata salad', 'Périgord salad with confit gizzards', 'Thai beef salad with lime', 'Lentil salad with shallots', 'Quinoa and crunchy vegetable salad', 'Shrimp and grapefruit salad'],
      'es': ['Ensalada de queso de cabra caliente', 'Ensalada nizarda', 'Ensalada César con pollo', 'Ensalada lionesa con panceta y huevo escalfado', 'Ensalada griega con feta', 'Tabulé libanés con hierbas', 'Ensalada de tomates antiguos y burrata', 'Ensalada perigordina con mollejas', 'Ensalada tailandesa de ternera con lima', 'Ensalada de lentejas con chalotas', 'Ensalada de quinoa y verduras crujientes', 'Ensalada de gambas y pomelo'],
      'it': ['Insalata di caprino caldo', 'Insalata nizzarda', 'Insalata Caesar con pollo', 'Insalata lionese con pancetta e uovo in camicia', 'Insalata greca con feta', 'Tabbouleh libanese alle erbe', 'Insalata di pomodori antichi e burrata', 'Insalata del Périgord con ventrigli', 'Insalata thai di manzo al lime', 'Insalata di lenticchie allo scalogno', 'Insalata di quinoa e verdure croccanti', 'Insalata di gamberi e pompelmo'],
    },
    'vegetarian': {
      'en': ['Provençal ratatouille', 'Mediterranean vegetable tian', 'Grilled vegetables with olive oil', 'Eggplant parmigiana', 'Green asparagus risotto', 'Falafel with hummus', 'Butternut squash gratin', 'Gratin dauphinois (creamy potato bake)', 'Veggie burger', 'Rice and herb stuffed peppers'],
      'es': ['Ratatouille provenzal', 'Tian de verduras mediterráneas', 'Verduras a la parrilla con aceite de oliva', 'Berenjenas a la parmesana', 'Risotto de espárragos verdes', 'Faláfel con hummus', 'Gratinado de calabaza', 'Gratén dauphinois de patatas', 'Hamburguesa vegetariana', 'Pimientos rellenos de arroz y hierbas'],
      'it': ['Ratatouille provenzale', 'Tian di verdure mediterranee', 'Verdure grigliate all\'olio d\'oliva', 'Parmigiana di melanzane', 'Risotto agli asparagi verdi', 'Falafel con hummus', 'Gratin di zucca', 'Gratin dauphinois di patate', 'Burger vegetariano', 'Peperoni ripieni di riso ed erbe'],
    },
    'soups': {
      'en': ['Marseille bouillabaisse', 'French onion soup au gratin', 'Red kuri squash velouté', 'Andalusian gazpacho', 'Vegetable minestrone', 'Lobster bisque', 'Provençal pistou soup', 'Béarn garbure (ham and cabbage soup)', 'Vietnamese beef pho'],
      'es': ['Bullabesa marsellesa', 'Sopa de cebolla gratinada', 'Crema de calabaza', 'Gazpacho andaluz', 'Minestrone de verduras', 'Bisque de bogavante', 'Sopa al pistou', 'Garbure bearnesa', 'Pho vietnamita de ternera'],
      'it': ['Bouillabaisse marsigliese', 'Zuppa di cipolle gratinata', 'Vellutata di zucca', 'Gazpacho andaluso', 'Minestrone di verdure', 'Bisque d\'astice', 'Zuppa al pistou', 'Garbure del Béarn', 'Pho vietnamita di manzo'],
    },
    'eggs_savoury_tarts': {
      'en': ['Quiche Lorraine', 'Eggs en meurette (poached in red wine)', 'Eggs Benedict', 'Alsatian tarte flambée (flammekueche)', 'Onion tart', 'Complete Breton buckwheat galette (ham and egg)', 'Spanish tortilla', 'Fine herbs omelette', 'Cheese soufflé'],
      'es': ['Quiche lorena', 'Huevos en salsa meurette', 'Huevos Benedict', 'Flammekueche alsaciana', 'Tarta de cebolla', 'Galette bretona completa', 'Tortilla española', 'Tortilla francesa a las finas hierbas', 'Suflé de queso'],
      'it': ['Quiche lorraine', 'Uova in meurette', 'Uova alla Benedict', 'Flammekueche alsaziana', 'Torta salata alle cipolle', 'Galette bretone completa', 'Tortilla spagnola', 'Omelette alle erbe fini', 'Soufflé al formaggio'],
    },
  };
}

class FoodPairingMatch {
  final Bottle bottle;
  final int score; // 0 to 100
  final FoodMatchLevel matchLevel;
  final String sommelierComment;
  final String servingAdvice;

  const FoodPairingMatch({
    required this.bottle,
    required this.score,
    required this.matchLevel,
    required this.sommelierComment,
    required this.servingAdvice,
  });
}

class WineFoodMatcher {
  static const _parDefaut = 'Accord équilibré selon le profil aromatique du vin.';

  static const List<FoodPairingCategory> categories = [
    // 1. Red meat
    FoodPairingCategory(
      id: 'red_meat',
      label: 'Viandes Rouges & Grillades',
      icon: '🥩',
      sampleDishes: [
        'Côte de bœuf grillée',
        'Entrecôte persillée',
        'Magret de canard',
        'Tournedos Rossini',
        'Tartare de bœuf',
        'Gigot d\'agneau au thym',
        'Picanha au barbecue',
        'Bavette à l\'échalote',
        'Gigot d\'agneau de sept heures',
        'Carré d\'agneau en croûte d\'herbes',
        'Burger de bœuf au cheddar',
        'Côtes d\'agneau grillées au romarin',
      ],
      keywords: [
        'boeuf', 'bœuf', 'cote de boeuf', 'côte de bœuf', 'entrecote', 'entrecôte',
        'magret', 'canard', 'grillade', 'steak', 'agneau', 'bavette', 'tartare',
        'tournedos', 'picanha', 'onglet', 'brochette', 'faux-filet', 'chateaubriand',
        'rumsteak', 'carré d\'agneau', 't-bone', 'ribeye', 'barbecue', 'bbq', 'filet mignon de boeuf',
        'beef', 'steak', 'prime rib', 'lamb', 'flank', 'meat', 'chuleton', 'cordero', 'buey',
        'roast', 'roti', 'rôti', 'gigot', 'thyme', 'thym', 'tomillo', 'farigola', 'rosemary',
        'romarin', 'leg of lamb', 'lamb chops', 'rack of lamb', 'asado', 'parrilla', 'costillas',
        'xai', 'anyell', 'cuixa de xai', 'bubula', 'agnus', 'agninus',
      ],
    ),

    // 2. Game & Stew
    FoodPairingCategory(
      id: 'game_stew',
      label: 'Gibier & Plats Mijotés',
      icon: '🦌',
      sampleDishes: [
        'Bœuf Bourguignon',
        'Daube provençale',
        'Civet de sanglier',
        'Lièvre à la royale',
        'Chevreuil aux airelles',
        'Pot-au-feu',
        'Carbonnade flamande',
        'Goulash hongrois',
        'Navarin d\'agneau printanier',
        'Joue de bœuf braisée au vin rouge',
        'Cuissot de chevreuil sauce grand veneur',
      ],
      keywords: [
        'bourguignon', 'daube', 'gibier', 'sanglier', 'chevreuil', 'civet',
        'tajine agneau', 'lièvre', 'lievre', 'biche', 'goulash', 'goulasch',
        'pot-au-feu', 'pot au feu', 'carbonnade', 'joue de boeuf', 'joue de bœuf',
        'cerf', 'faisan', 'palombe', 'ragoût', 'ragout', 'navarin', 'mijoté', 'stew', 'game', 'boar', 'venison', 'hare', 'deer', 'goulash', 'caza', 'jabalí', 'venado', 'guisat',
      ],
    ),

    // 3. Poultry & Veal
    FoodPairingCategory(
      id: 'poultry_veal',
      label: 'Volailles Nobles & Veau',
      icon: '🍗',
      sampleDishes: [
        'Poulet rôti fermier',
        'Blanquette de veau',
        'Chapon aux marrons',
        'Quasi de veau aux morilles',
        'Escalope milanaise',
        'Pintade aux herbes',
        'Canard à l\'orange',
        'Coq au vin',
        'Poulet basquaise',
        'Suprême de volaille à la crème',
        'Rôti de veau aux carottes',
      ],
      keywords: [
        'poulet', 'volaille', 'chapon', 'dinde', 'veau', 'quasi de veau', 'quasi',
        'pintade', 'caille', 'roti', 'rôti', 'ris de veau', 'blanquette', 'escalope',
        'coq au vin', 'canard a l\'orange', 'poularde', 'supreme de volaille', 'suprême de volaille',
        'caille farcie', 'foie de veau', 'chicken', 'poultry', 'veal', 'turkey', 'quail', 'pollo', 'ternera', 'pollastre', 'vedella',
      ],
    ),

    // 4. Delicate Fish & Butter sauce
    FoodPairingCategory(
      id: 'delicate_fish',
      label: 'Poissons Fins & Beurre Blanc',
      icon: '🐟',
      sampleDishes: [
        'Sole meunière',
        'Bar de ligne au four',
        'Turbot au beurre blanc',
        'Dos de cabillaud vapeur',
        'Saint-Pierre poêlé',
        'Dorade royale grillée',
        'Lotte à l\'armoricaine',
        'Truite aux amandes',
        'Brandade de morue',
        'Raie au beurre noisette et aux câpres',
        'Bar en croûte de sel',
      ],
      keywords: [
        'sole', 'meuniere', 'meunière', 'bar', 'loup de mer', 'turbot', 'cabillaud',
        'saint-pierre', 'dorade', 'daurade', 'lotte', 'beurre blanc', 'truite',
        'lieu jaune', 'merlan', 'poisson blanc', 'papillote', 'poisson vapeur', 'flétan',
        'poisson au four', 'poisson', 'lotte à l\'armoricaine', 'fish', 'sole', 'sea bass', 'bass', 'cod', 'turbot', 'halibut', 'trout', 'pescado', 'lubina', 'bacalao', 'peix', 'llobarro',
      ],
    ),

    // 5. Fatty fish, Sushi & Ceviche
    FoodPairingCategory(
      id: 'fatty_fish_sushi',
      label: 'Poissons Gras, Sushis & Ceviche',
      icon: '🍣',
      sampleDishes: [
        'Saumon grillé unilatéral',
        'Tataki de thon rouge',
        'Sushis & Sashimis variés',
        'Ceviche péruvien',
        'Saumon fumé d\'Écosse',
        'Sardines grillées',
        'Poke bowl au saumon',
        'Tartare de thon avocat',
        'Gravlax de saumon à l\'aneth',
        'Maquereaux grillés au citron',
        'Chirashi au saumon',
      ],
      keywords: [
        'saumon', 'thon', 'tataki', 'sushi', 'sashimi', 'ceviche', 'poke bowl',
        'saumon fume', 'saumon fumé', 'maquereau', 'sardine', 'anchois', 'tartare de saumon',
        'thon mi-cuit', 'hareng', 'anguille', 'tartare de thon', 'gravlax', 'saumon gravlax',
      ],
    ),

    // 6. Seafood & Shellfish
    FoodPairingCategory(
      id: 'seafood_shellfish',
      label: 'Fruits de Mer, Huîtres & Crustacés',
      icon: '🦞',
      sampleDishes: [
        'Plateau d\'huîtres fraîches',
        'Homard breton grillé',
        'Noix de Saint-Jacques snackées',
        'Langoustines rôties',
        'Gambas flambées à l\'ail',
        'Moules marinières',
        'Tourteau mayonnaise',
        'Couteaux persillés',
        'Huîtres fines de claire',
        'Plateau de fruits de mer',
        'Paella aux fruits de mer',
        'Calamars à la plancha',
      ],
      keywords: [
        'huitre', 'huître', 'crevette', 'homard', 'langouste', 'langoustine',
        'saint-jacques', 'st-jacques', 'fruits de mer', 'crustaces', 'crustacés',
        'gambas', 'moule', 'moules marinières', 'coquillage', 'bulot', 'bigorneau',
        'tourteau', 'crabe', 'couteau', 'palourde', 'ecrevisse', 'écrevisse',
        'plateau de fruits de mer', 'coquilles saint-jacques',
      ],
    ),

    // Salades Composées (19/10)
    FoodPairingCategory(
      id: 'salads',
      label: 'Salades Composées',
      icon: '🥗',
      sampleDishes: [
        'Salade de chèvre chaud',
        'Salade niçoise',
        'Salade César au poulet',
        'Salade lyonnaise aux lardons et œuf poché',
        'Salade grecque à la feta',
        'Taboulé libanais aux herbes',
        'Salade de tomates anciennes et burrata',
        'Salade périgourdine aux gésiers',
        'Salade thaïe de bœuf au citron vert',
        'Salade de lentilles aux échalotes',
        'Salade de quinoa et légumes croquants',
        'Salade de crevettes et pamplemousse',
      ],
      keywords: [
        'salade', 'salad', 'ensalada', 'insalata', 'taboulé', 'tabbouleh', 'césar', 'caesar', 'niçoise', 'lyonnaise', 'chèvre chaud', 'burrata', 'feta',
      ],
    ),

    // Légumes & Cuisine Végétarienne (19/10)
    FoodPairingCategory(
      id: 'vegetarian',
      label: 'Légumes & Cuisine Végétarienne',
      icon: '🥦',
      sampleDishes: [
        'Ratatouille provençale',
        'Tian de légumes du soleil',
        'Légumes grillés à l\'huile d\'olive',
        'Aubergines à la parmigiana',
        'Risotto aux asperges vertes',
        'Falafels et houmous',
        'Gratin de courge butternut',
        'Gratin dauphinois',
        'Burger végétarien',
        'Poivrons farcis au riz et aux herbes',
      ],
      keywords: [
        'légumes', 'végétarien', 'vegetarian', 'vegetables', 'ratatouille', 'tian', 'aubergine', 'asperges', 'falafel', 'houmous', 'gratin', 'courge',
      ],
    ),

    // Soupes & Veloutés (19/10)
    FoodPairingCategory(
      id: 'soups',
      label: 'Soupes & Veloutés',
      icon: '🍲',
      sampleDishes: [
        'Bouillabaisse marseillaise',
        'Soupe à l\'oignon gratinée',
        'Velouté de potimarron',
        'Gaspacho andalou',
        'Minestrone aux légumes',
        'Bisque de homard',
        'Soupe au pistou',
        'Garbure béarnaise',
        'Pho vietnamien au bœuf',
      ],
      keywords: [
        'soupe', 'soup', 'velouté', 'bouillabaisse', 'bisque', 'gaspacho', 'gazpacho', 'minestrone', 'pistou', 'garbure', 'pho', 'sopa', 'zuppa',
      ],
    ),

    // Œufs, Quiches & Tartes Salées (19/10)
    FoodPairingCategory(
      id: 'eggs_savoury_tarts',
      label: 'Œufs, Quiches & Tartes Salées',
      icon: '🥚',
      sampleDishes: [
        'Quiche lorraine',
        'Œufs en meurette',
        'Œufs Bénédicte',
        'Flammekueche alsacienne',
        'Tarte à l\'oignon',
        'Galette bretonne complète',
        'Tortilla española',
        'Omelette aux fines herbes',
        'Soufflé au fromage',
      ],
      keywords: [
        'quiche', 'œuf', 'oeuf', 'egg', 'omelette', 'tortilla', 'flammekueche', 'tarte flambée', 'tarte salée', 'galette', 'meurette', 'bénédicte',
      ],
    ),

    // 7. Goat & Sheep Cheese
    FoodPairingCategory(
      id: 'goat_sheep_cheese',
      label: 'Fromages de Chèvre & Brebis',
      icon: '🐐',
      sampleDishes: [
        'Crottin de Chavignol',
        'Sainte-Maure de Touraine',
        'Banon en feuille de châtaignier',
        'Roquefort AOP',
        'Ossau-Iraty au piment d\'Espelette',
        'Manchego affiné',
        'Feta grecque',
        'Pélardon des Cévennes',
        'Ossau-Iraty et confiture de cerises noires',
        'Pecorino toscano',
      ],
      keywords: [
        'chevre', 'chèvre', 'crottin', 'chavignol', 'sainte-maure', 'valençay',
        'valencay', 'banon', 'pelardon', 'pélardon', 'rocamadour', 'brebis',
        'ossau-iraty', 'ossau iraty', 'manchego', 'feta', 'brocciu', 'pecorino',
        'roquefort', 'bleu', 'fromage persille', 'fourme d\'ambert', 'gorgonzola',
      ],
    ),

    // 8. Cow Milk & Pressed Cheese
    FoodPairingCategory(
      id: 'cow_pressed_cheese',
      label: 'Fromages de Vache & Pâtes Affinées',
      icon: '🧀',
      sampleDishes: [
        'Comté 18-24 mois',
        'Beaufort d\'alpage',
        'Brie de Meaux fermier',
        'Camembert de Normandie',
        'Saint-Nectaire fermier',
        'Époisses au marc de Bourgogne',
        'Reblochon de Savoie',
        'Munster alsacien',
        'Beaufort d\'alpage',
        'Mimolette extra-vieille',
        'Parmigiano Reggiano 24 mois',
      ],
      keywords: [
        'comte', 'comté', 'beaufort', 'gruyere', 'gruyère', 'brie', 'camembert',
        'saint-nectaire', 'saint nectaire', 'epoisses', 'époisses', 'reblochon',
        'munster', 'maroilles', 'morbier', 'cantal', 'salers', 'gouda', 'parmesan',
        'parmigiano', 'fromage', 'plateau de fromages', 'chaource', 'livarot', 'pont-l\'évêque',
      ],
    ),

    // 9. Winter melted cheese
    FoodPairingCategory(
      id: 'winter_melted_cheese',
      label: 'Raclette, Fondue & Plats d\'Hiver',
      icon: '🫕',
      sampleDishes: [
        'Raclette traditionnelle',
        'Fondue savoyarde aux 3 fromages',
        'Tartiflette au Reblochon',
        'Mont d\'Or chaud au four',
        'Croziflette aux lardons',
        'Aligot saucisse de l\'Aveyron',
        'Fondue bourguignonne',
        'Mont d\'Or chaud au four',
        'Aligot de l\'Aubrac',
        'Truffade auvergnate',
      ],
      keywords: [
        'raclette', 'fondue', 'fondue savoyarde', 'tartiflette', 'croziflette',
        'mont d\'or', 'mont-d\'or', 'boite chaude', 'aligot', 'truffade',
        'fondue bourguignonne', 'fondue vigneronne', 'fromage fondu', 'hiver',
        'repas savoyard', 'reblochonade', 'berthoud',
      ],
    ),

    // 10. Mushrooms & Truffle
    FoodPairingCategory(
      id: 'mushrooms_truffle',
      label: 'Champignons, Risottos & Truffes',
      icon: '🍄',
      sampleDishes: [
        'Risotto crémeux aux cèpes',
        'Pâtes fraîches à la truffe noire',
        'Poêlée de morilles fraîches',
        'Omelette aux truffes',
        'Girolles sautées au persil',
        'Velouté de châtaignes et cèpes',
        'Risotto au safran et morilles',
        'Œuf cocotte aux morilles',
        'Tagliatelles aux girolles',
        'Vol-au-vent aux champignons',
      ],
      keywords: [
        'champignon', 'truffe', 'cepe', 'cèpe', 'morille', 'risotto', 'girolle',
        'sous-bois', 'pates aux truffes', 'pâtes aux truffes', 'omelette truffe',
        'trompette de la mort', 'chanterelle', 'bolet', 'pleurote', 'champignons',
        'risotto aux morilles', 'truffe noire', 'truffe blanche',
      ],
    ),

    // 11. Italian Pasta & Pizza
    FoodPairingCategory(
      id: 'italian_pasta_pizza',
      label: 'Pâtes, Pizzas & Saveurs Italiennes',
      icon: '🍕',
      sampleDishes: [
        'Pizza Margherita au feu de bois',
        'Lasagnes bolognaises maison',
        'Spaghetti Carbonara tradizionale',
        'Spaghetti alle Vongole',
        'Carpaccio de bœuf au parmesan',
        'Burrata di Bufala & tomates confites',
        'Arancini siciliens',
        'Penne all\'arrabbiata',
        'Gnocchi au pesto genovese',
        'Raviolis ricotta et épinards',
      ],
      keywords: [
        'pizza', 'margherita', 'lasagne', 'bolognaise', 'carbonara', 'vongole',
        'amatriciana', 'carpaccio', 'burrata', 'mozzarella', 'pesto', 'gnocchi',
        'ravioli', 'osso buco', 'italien', 'arancini', 'tortellini', 'cannelloni',
        'pasta', 'pâtes', 'spaghetti', 'tagliatelle', 'penne', 'calzone',
      ],
    ),

    // 12. French Terroir & Tradition
    FoodPairingCategory(
      id: 'french_terroir',
      label: 'Terroir Français & Tradition',
      icon: '🥘',
      sampleDishes: [
        'Cassoulet de Castelnaudary',
        'Choucroute royale garnie',
        'Petit salé aux lentilles du Puy',
        'Boudin noir aux pommes caramélisées',
        'Andouillette de Troyes grillée',
        'Baeckeoffe alsacien',
        'Tripes à la mode de Caen',
        'Saucisse de Morteau aux lentilles',
        'Hachis parmentier',
        'Potée auvergnate',
      ],
      keywords: [
        'cassoulet', 'choucroute', 'petit sale', 'petit salé', 'lentilles', 'boudin',
        'boudin noir', 'boudin blanc', 'andouillette', 'baeckeoffe', 'tripes',
        'poule au pot', 'garbure', 'tripoux', 'saucisse de toulouse', 'saucisse de morteau',
        'terroir', 'quenelles', 'bouchée à la reine', 'hachis parmentier',
      ],
    ),

    // 13. Spicy & Oriental
    FoodPairingCategory(
      id: 'spicy_oriental',
      label: 'Cuisine Épicée, Couscous & Tajines',
      icon: '🌶️',
      sampleDishes: [
        'Couscous royal 3 viandes',
        'Tajine de poulet aux citrons confits',
        'Butter Chicken indien',
        'Curry d\'agneau madras',
        'Poulet Colombo antillais',
        'Rougail saucisse réunionnais',
        'Chili con carne',
        'Pastilla au poulet et aux amandes',
        'Keftas d\'agneau à la menthe',
        'Dahl de lentilles corail',
        'Curry de légumes au lait de coco',
      ],
      keywords: [
        'couscous', 'tajine', 'curry', 'butter chicken', 'tikka masala', 'colombo',
        'rougail', 'chili', 'chili con carne', 'epice', 'épice', 'indien', 'oriental',
        'harissa', 'tandoori', 'masala', 'dahl', 'samossa', 'samoussa', 'massale',
        'cuisine mexicaine', 'fajitas', 'tacos', 'pastilla',
      ],
    ),

    // 14. Asian, Wok & Street Food
    FoodPairingCategory(
      id: 'asian_street_food',
      label: 'Cuisine Asiatique, Wok & Canard Laqué',
      icon: '🥢',
      sampleDishes: [
        'Canard laqué pékinois',
        'Pad Thaï aux crevettes',
        'Bo Bun vietnamien au bœuf',
        'Ramen japonais au porc chashu',
        'Dim Sum & Gyozas vapeur',
        'Porc aigre-doux',
        'Wok de bœuf aux oignons',
        'Nems croustillants à la menthe',
        'Bibimbap coréen',
        'Gyozas grillés à la japonaise',
      ],
      keywords: [
        'canard laque', 'canard laqué', 'pad thai', 'pad thaï', 'bo bun', 'ramen',
        'dim sum', 'gyoza', 'porc aigre-doux', 'wok', 'nem', 'vietnamien', 'chinois',
        'japonais', 'coreen', 'coréen', 'bibimbap', 'poulet kung pao', 'yakitori',
        'bao', 'bao burger', 'street food', 'rouleau de printemps', 'tom yum',
      ],
    ),

    // 15. Tapas, Aperitif & Foie Gras
    FoodPairingCategory(
      id: 'tapas_aperitif',
      label: 'Tapas, Charcuterie & Foie Gras',
      icon: '🌮',
      sampleDishes: [
        'Planche de jambon Pata Negra',
        'Foie gras mi-cuit sur toast',
        'Tapenade & anchoïade provençale',
        'Gougères chaudes au fromage',
        'Pintxos basques variés',
        'Empanadas argentins',
        'Pissaladière niçoise',
        'Rillettes du Mans',
        'Croquetas de jamón ibérico',
        'Saucisson sec et cornichons',
        'Gambas al ajillo',
      ],
      keywords: [
        'charcuterie', 'jambon ibérique', 'jambon iberique', 'jambon de parme',
        'pata negra', 'foie gras', 'tapenade', 'anchoiade', 'anchoïade', 'gougere',
        'gougère', 'tapas', 'pintxos', 'empanadas', 'aperitif', 'apéritif', 'rillettes',
        'pate en croute', 'pâté en croûte', 'saucisson', 'pissaladiere', 'pissaladière',
        'planche aurore', 'amuse-bouche',
      ],
    ),

    // 16. Desserts & Chocolate
    FoodPairingCategory(
      id: 'dessert',
      label: 'Desserts, Tartes & Chocolat',
      icon: '🍰',
      sampleDishes: [
        'Fondant au chocolat cœur coulant',
        'Tarte Tatin tiède à la crème',
        'Tarte au citron meringuée',
        'Crème brûlée vanille bourbon',
        'Tiramisu italien au café',
        'Soufflé au Grand Marnier',
        'Profiteroles au chocolat chaud',
        'Mille-feuille à la vanille',
        'Paris-Brest praliné',
        'Pavlova aux fruits rouges',
        'Baba au rhum',
        'Crêpes Suzette',
      ],
      keywords: [
        'dessert', 'chocolat', 'fondant', 'moelleux chocolat', 'tarte tatin',
        'tarte', 'tarte citron', 'creme brulee', 'crème brûlée', 'tiramisu',
        'fruit', 'fraise', 'framboise', 'pomme', 'poire', 'souffle', 'soufflé',
        'profiteroles', 'eclair', 'éclair', 'île flottante', 'ile flottante',
        'opera', 'millefeuille', 'baba au rhum', 'paris-brest',
      ],
    ),
  ];

  static const int minQualityScore = 60;

  static List<FoodPairingMatch> findMatches({
    required List<Bottle> bottles,
    required String dishQuery,
    int minScore = minQualityScore,
    dynamic lang,
  }) {
    if (bottles.isEmpty) return [];
    final query = _normalize(dishQuery);
    if (query.isEmpty) return [];

    final List<FoodPairingMatch> matches = [];

    for (final bottle in bottles) {
      final wine = bottle.wine;
      if (wine == null) continue;

      final match = _evaluatePairing(bottle, wine, query, minScore: minScore);
      if (match != null && match.score >= minScore) {
        matches.add(match);
      }
    }

    // Sort matches by descending score
    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches;
  }

  static FoodPairingMatch? _evaluatePairing(Bottle bottle, Wine wine, String query, {int minScore = minQualityScore}) {
    final type = _normalize(wine.type);
    final region = _normalize(wine.region);
    final appellation = _normalize(wine.appellation ?? '');
    final grapes = wine.grapes.map((g) => _normalize(g.name)).toList();
    final isMature = wine.windowStatus == DrinkWindowStatus.inPeak || wine.windowStatus == DrinkWindowStatus.drinkSoon;

    int score = 0;
    String comment = '';
    String serving = 'Servir à bonne température selon le cépage.';

    // Specific sub-modifiers for food preparation & seasoning
    final hasThymeOrHerbs = _matchesKeywords(query, [
      'thym', 'thyme', 'tomillo', 'farigola', 'thymo',
      'romarin', 'rosemary', 'romero',
      'garrigue', 'herbes', 'herbs', 'ail', 'garlic', 'echalote', 'shallot',
      'poivre', 'pepper', 'sarments', 'provence',
      'timo', 'rosmarino', 'erbe', 'aglio', 'scalogno'
    ]);
    final isLamb = _matchesKeywords(query, [
      'agneau', 'lamb', 'gigot', 'cordero', 'xai', 'agnus', 'mouton', 'mutton',
      'carre d agneau', 'cotelette d agneau', 'lamb chops', 'rack of lamb', 'leg of lamb',
      'agnello', 'abbacchio'
    ]);
    // « Ternera » est du bœuf ou du veau selon le plat : une blanquette ou une milanaise, c'est du veau.
    final isVeal = _matchesKeywords(query, [
      'veau', 'veal', 'vitello', 'blanquette', 'blanqueta', 'milanesa', 'escalope', 'cotoletta', 'lechal',
      'osso buco', 'ossobuco', 'saltimbocca', 'scaloppin'
    ]);
    final isBeef = !isVeal && _matchesKeywords(query, [
      'boeuf', 'bœuf', 'beef', 'steak', 'entrecote', 'entrecôte', 'ribeye',
      'tournedos', 'picanha', 'chateaubriand', 'bavette', 'onglet', 't-bone', 'prime rib',
      'buey', 'ternera', 'bubula', 'faux-filet', 'rumsteak', 'chuleton',
      'manzo', 'costata', 'bistecca', 'fiorentina', 'tagliata', 'bavetta', 'fondue bourguignonne'
    ]);
    final isDuck = _matchesKeywords(query, [
      'canard', 'magret', 'duck', 'pato', 'anec', 'anas', 'anatra'
    ]);
    // Un plat mijoté (bœuf bourguignon, daube, civet) se juge comme tel, même s'il est de bœuf.
    final isStew = _matchesKeywords(query, [
      'bourguignon', 'daube', 'gibier', 'sanglier', 'chevreuil', 'civet',
      'tajine agneau', 'lièvre', 'lievre', 'biche', 'goulash', 'goulasch',
      'pot-au-feu', 'pot au feu', 'carbonnade', 'joue de boeuf', 'joue de bœuf',
      'cerf', 'faisan', 'palombe', 'ragoût', 'ragout', 'navarin', 'mijoté',
      'stew', 'game', 'boar', 'wild boar', 'venison', 'hare', 'deer',
      'caza', 'jabalí', 'jabali', 'venado', 'guisat', 'estofado', 'guiso',
      'conill', 'carn de caça', 'venatio',
      'cinghiale', 'capriolo', 'cervo', 'lepre', 'selvaggina', 'stufato', 'brasato', 'spezzatino', 'gulasch', 'fagiano',
      'cassoulet', 'borgognona', 'borgoñona', 'carbonade', 'carbonada', 'gulash', 'liebre', 'braise', 'brasat'
    ]);
    // Un couscous, un tajine ou un curry se jugent à leurs épices, avant la viande ou la volaille.
    final isSpicyDish = _matchesKeywords(query, [
      'couscous', 'cuscus', 'tajine', 'tagine', 'curry', 'butter chicken', 'tikka masala', 'colombo', 'rougail',
      'tandoori', 'madras', 'harissa', 'pastilla', 'pastela', 'kefta', 'kofta', 'dahl', 'daal'
    ]);
    // Les mots de cuisson (« rôti », « barbecue », « tartare ») ne font pas d'un poulet, d'un
    // poisson ou de langoustines une viande rouge.
    final isPoultryOrSea = isVeal || _matchesKeywords(query, [
      'poulet', 'volaille', 'chapon', 'dinde', 'pintade', 'caille', 'veau', 'chicken', 'poultry', 'turkey', 'veal',
      'pollo', 'pavo', 'pollastre', 'pollame', 'cappone', 'faraona', 'tacchino', 'quaglia', 'vitello',
      'poisson', 'saumon', 'thon', 'fish', 'salmon', 'tuna', 'pescado', 'salmon', 'atun', 'pesce', 'salmone', 'tonno',
      'crevette', 'langoustine', 'homard', 'saint-jacques', 'prawn', 'shrimp', 'lobster', 'scallop', 'gambas', 'cigala',
      'gamberi', 'scampi', 'astice', 'capesante',
      'sardine', 'maquereau', 'mackerel', 'caballa', 'sardina', 'sgombro', 'sarde', 'capon', 'pintada',
    ]);

    // Deterministic bottle tie-breaker to avoid identical scores across cellar bottles
    final bottleDifferentiator = (wine.name.hashCode.abs() % 3) - 1; // -1, 0, or +1
    // Le Gewurztraminer, aromatique et souvent tendre, n'est pas un blanc « à tout faire » :
    // il garde ses accords (épices, Asie, foie gras, desserts), pas les autres (19/10).
    final gewurz = grapes.any((g) => g.contains('gewurz'));
    // Un blanc d'Alsace n'est doux qu'en vendanges tardives ou en grains nobles : un Riesling
    // sec n'accompagne pas une pavlova (19/10).
    final alsaceDoux = region.contains('alsace') &&
        _matchesKeywords(_normalize('${wine.name} ${wine.appellation ?? ''}'), ['vendanges tardives', 'selection de grains nobles', 'sgn', 'vt']);

    // =========================================================================
    // 1. Foie Gras (Special Highlight)
    // =========================================================================
    if (_matchesKeywords(query, ['foie gras', 'foie-gras', 'duck liver', 'goose liver', 'foie gras poele', 'foie gras mi-cuit'])) {
      if (type.contains('dessert') || type.contains('moell') || type.contains('sauternes') || appellation.contains('sauternes') || appellation.contains('monbazillac') || type.contains('sweet')) {
        score = 96 + (appellation.contains('sauternes') ? 2 : 0) + bottleDifferentiator;
        comment = 'L\'accord noble par excellence : la texture fondante du foie gras et la richesse d\'un grand liquoreux s\'épousent dans une harmonie parfaite.';
        serving = 'Servir frais entre 8°C et 10°C.';
      } else if (type.contains('champ') || type.contains('sparkling')) {
        score = 88 + (appellation.contains('grand cru') ? 2 : 0) + bottleDifferentiator;
        comment = 'Accord moderne et vivifiant : les fines bulles et la fraîcheur du vin tranchent avec le gras onctueux du foie gras.';
        serving = 'Servir en flûte rafraîchie à 8-9°C.';
      } else if (grapes.contains('gewurztraminer') || region.contains('alsace')) {
        score = 90 + bottleDifferentiator;
        comment = grapes.contains('gewurztraminer')
            ? 'L\'exubérance épicée et la rondeur du Gewurztraminer subliment le foie gras mi-cuit avec éclat.'
            : 'La rondeur et le parfum des blancs d\'Alsace accompagnent le foie gras mi-cuit.';
        serving = 'Servir à 10°C.';
      } else if (grapes.contains('pinot noir') && isMature) {
        score = 83 + bottleDifferentiator;
        comment = 'Accord d\'esthète : un vieux Pinot Noir aux tanins fondus apporte des notes de sous-bois et de truffe idéales sur un foie gras poêlé.';
        serving = 'Servir chambré à 15-16°C.';
      }
    }

    // =========================================================================
    // 2. Raclette, Fondue & Plats Fromage Fondu
    // =========================================================================
    else if (_matchesKeywords(query, [
      'raclette', 'fondue', 'tartiflette', 'croziflette', 'mont d\'or', 'mont-d\'or',
      'aligot', 'truffade', 'fromage fondu', 'reblochonade', 'cheese fondue', 'melted cheese',
      'fonduta', 'formaggio fuso'
    ]) && !_matchesKeywords(query, ['bourguignonne'])) {
      if (type.contains('blanc') || type.contains('white')) {
        if (region.contains('savoie') || region.contains('jura') || appellation.contains('apremont') || appellation.contains('chignin') || appellation.contains('arbois')) {
          score = 96 + (appellation.contains('apremont') || appellation.contains('chignin') ? 2 : 0) + bottleDifferentiator;
          comment = 'Accord régional roi : la vivacité minérale et la fraîcheur alpine (Jacquère, Altesse, Savagnin) coupent le gras du fromage fondu et favorisent la digestion.';
          serving = 'Servir très frais à 8-10°C.';
        } else if (!gewurz && (region.contains('alsace') || region.contains('loire') || appellation.contains('riesling') || appellation.contains('sancerre') || appellation.contains('chablis'))) {
          score = 86 + bottleDifferentiator;
          comment = 'Un blanc sec et tendu avec une belle acidité nettoie le palais face à l\'onctuosité du fromage et des charcuteries.';
          serving = 'Servir à 9-11°C.';
        } else {
          score = 77 + bottleDifferentiator;
          comment = 'Un vin blanc sec est le compagnon idéal des fromages fondus pour conserver légèreté et gourmandise.';
          serving = 'Servir frais à 9-10°C.';
        }
      } else if (type.contains('red') || type.contains('rouge')) {
        if (grapes.contains('gamay') || grapes.contains('pinot noir') || region.contains('beaujolais') || region.contains('jura')) {
          score = 69 + bottleDifferentiator;
          comment = 'Pour les amateurs de rouge sur la raclette : ce rouge léger, fruité et peu tannique n\'alourdit pas le fromage et accompagne bien la charcuterie.';
          serving = 'Servir légèrement rafraîchi à 14-15°C.';
        }
      }
    }

    // =========================================================================
    // 2 bis. Salades composées (19/10, Flavien : « il n'y a pas de salades »)
    // =========================================================================
    // Avant les viandes et les poissons : une salade se juge à sa vinaigrette et à sa
    // fraîcheur, qui durcissent les tanins d'un grand rouge, plus qu'à ce qu'elle porte
    // (une salade thaïe au bœuf n'appelle pas un Pauillac).
    else if (_matchesKeywords(query, ['salade', 'salad', 'ensalada', 'insalata', 'taboule', 'tabbouleh', 'tabule'])) {
      final blanc = type == 'white' || type == 'blanc';
      final rose = type.contains('rose');
      final rouge = type == 'red' || type == 'rouge';
      final bulles = type.contains('champ') || type.contains('sparkling');
      final sauvignon = grapes.any((g) => g.contains('sauvignon')) || appellation.contains('sancerre') ||
          appellation.contains('pouilly') || appellation.contains('menetou') || appellation.contains('quincy') || appellation.contains('reuilly');
      final vifEtSalin = region.contains('loire') || appellation.contains('muscadet') || appellation.contains('chablis') ||
          appellation.contains('picpoul') ||
          grapes.any((g) => g.contains('albarino') || g.contains('vermentino') || g.contains('gruner') || g.contains('assyrtiko') || g.contains('melon'));
      final aromatique = region.contains('alsace') || grapes.any((g) => g.contains('riesling') || g.contains('gewurz') || g.contains('muscat'));
      final provence = region.contains('provence') || appellation.contains('bandol') || appellation.contains('cassis') || appellation.contains('bellet');
      final rougeGamay = rouge && (region.contains('beaujolais') || grapes.any((g) => g.contains('gamay')));
      final rougeLeger = rougeGamay || (rouge && grapes.any((g) => g.contains('pinot noir')));
      if (_matchesKeywords(query, ['chevre', 'goat', 'cabra', 'capra', 'caprino'])) {
        if (blanc && (sauvignon || region.contains('loire'))) {
          score = (sauvignon ? 96 : 92) + bottleDifferentiator;
          comment = 'Le grand classique de la salade de chèvre chaud : la vivacité d\'agrumes d\'un blanc de Loire répond au fromage fondant et à la vinaigrette.';
          serving = 'Servir à 9-11°C.';
        } else if (blanc && !gewurz) {
          score = 82 + bottleDifferentiator;
          comment = 'Un blanc sec et frais garde la salade légère et respecte le chèvre chaud.';
          serving = 'Servir frais à 9-10°C.';
        } else if (rose) {
          score = 80 + bottleDifferentiator;
          comment = 'Un rosé sec et frais accompagne la salade sans alourdir le fromage.';
          serving = 'Servir frais à 8-10°C.';
        }
      } else if (_matchesKeywords(query, ['nicoise', 'nizarda', 'nizzarda', 'thon', 'tuna', 'atun', 'tonno', 'anchois', 'anchov', 'anchoa', 'acciug'])) {
        if (rose) {
          score = (provence ? 95 : 88) + bottleDifferentiator;
          comment = 'La salade niçoise appelle un rosé sec, idéalement de Provence : sa fraîcheur saline tient tête à l\'anchois, au thon et aux olives.';
          serving = 'Servir frais à 8-10°C.';
        } else if (blanc && !gewurz) {
          score = (provence || vifEtSalin ? 86 : 80) + bottleDifferentiator;
          comment = 'Un blanc sec et salin épouse les saveurs iodées de l\'anchois et du thon.';
          serving = 'Servir frais à 9-10°C.';
        }
      } else if (_matchesKeywords(query, ['cesar', 'caesar', 'poulet', 'chicken', 'pollo'])) {
        if (blanc && !gewurz) {
          final chardonnay = region.contains('bourgogne') || grapes.any((g) => g.contains('chardonnay'));
          score = (chardonnay ? 90 : 84) + bottleDifferentiator;
          comment = 'Un blanc frais et rond répond à la sauce César, au parmesan et au poulet.';
          serving = 'Servir à 10-11°C.';
        } else if (bulles) {
          score = 84 + bottleDifferentiator;
          comment = 'Les bulles allègent la sauce crémeuse et le parmesan.';
          serving = 'Servir à 8-10°C.';
        } else if (rose) {
          score = 80 + bottleDifferentiator;
          comment = 'Un rosé sec et frais accompagne la salade sans alourdir le fromage.';
          serving = 'Servir frais à 8-10°C.';
        }
      } else if (_matchesKeywords(query, [
        'lyonnaise', 'lionesa', 'lionese', 'lardon', 'bacon', 'panceta', 'pancetta', 'gesier', 'gizzard', 'molleja',
        'ventrigli', 'perigourdine', 'perigord', 'perigordina', 'lentille', 'lentil', 'lenteja', 'lenticchi'
      ])) {
        if (rougeLeger) {
          score = (rougeGamay ? 92 : 85) + bottleDifferentiator;
          comment = 'Un rouge léger et fruité, servi frais, accompagne lardons, gésiers ou lentilles sans durcir sous la vinaigrette.';
          serving = 'Servir légèrement rafraîchi à 14-15°C.';
        } else if (rose) {
          score = 84 + bottleDifferentiator;
          comment = 'Un rosé sec et frais s\'accommode de la vinaigrette et des herbes.';
          serving = 'Servir frais à 8-10°C.';
        } else if (rouge && (region.contains('sud ouest') || appellation.contains('cahors') || appellation.contains('bergerac') ||
            appellation.contains('madiran') || appellation.contains('marcillac'))) {
          score = 80 + bottleDifferentiator;
          comment = 'Un rouge du Sud-Ouest, servi un peu frais, pour les gésiers et le magret de la salade périgourdine.';
          serving = 'Servir à 15-16°C.';
        } else if (blanc && !gewurz) {
          score = 78 + bottleDifferentiator;
          comment = 'Un blanc sec et frais, sans boisé, pour ne pas lutter avec la vinaigrette.';
          serving = 'Servir frais à 9-10°C.';
        }
      } else if (_matchesKeywords(query, ['thai', 'tailandes', 'papaye', 'papaya', 'citronnelle', 'lemongrass', 'asiatique', 'asian', 'asiatic'])) {
        if (blanc && aromatique) {
          score = 93 + bottleDifferentiator;
          comment = 'Un blanc aromatique, à la manière d\'un Riesling ou d\'un Gewurztraminer, répond au citron vert, à la coriandre et au piment.';
          serving = 'Servir à 9-10°C.';
        } else if (blanc || rose) {
          score = 82 + bottleDifferentiator;
          comment = 'Un vin frais et sec, sans tanins, pour le citron vert et le piment.';
          serving = 'Servir frais à 8-10°C.';
        } else if (rougeLeger) {
          score = 74 + bottleDifferentiator;
          comment = 'À défaut de blanc aromatique, un rouge très léger servi frais.';
          serving = 'Servir légèrement rafraîchi à 14-15°C.';
        }
      } else if (_matchesKeywords(query, ['grecque', 'greek', 'griega', 'greca', 'feta'])) {
        if (rose) {
          score = 88 + bottleDifferentiator;
          comment = 'Un rosé sec et frais pour la feta, les olives et les tomates gorgées de soleil.';
          serving = 'Servir frais à 8-10°C.';
        } else if (blanc && !gewurz) {
          score = (vifEtSalin || sauvignon ? 90 : 82) + bottleDifferentiator;
          comment = 'Un blanc vif et salin répond à la feta, aux olives et au concombre.';
          serving = 'Servir frais à 9-10°C.';
        }
      } else if (_matchesKeywords(query, ['burrata', 'mozzarella', 'caprese', 'tomate', 'tomato', 'pomodor'])) {
        final italien = region.contains('ital') || region.contains('tosc') || region.contains('sicil') || region.contains('piemont') ||
            region.contains('venet') || grapes.any((g) => g.contains('vermentino') || g.contains('pinot grigio') || g.contains('garganega'));
        if (blanc && !gewurz) {
          score = (italien ? 92 : 84) + bottleDifferentiator;
          comment = 'Un blanc sec et frais respecte la douceur de la burrata et l\'acidité des tomates.';
          serving = 'Servir frais à 9-10°C.';
        } else if (rose) {
          score = (provence ? 90 : 86) + bottleDifferentiator;
          comment = 'Un rosé sec et frais pour les tomates mûres, le basilic et la mozzarella.';
          serving = 'Servir frais à 8-10°C.';
        }
      } else {
        // Une salade verte, de crudités, de crustacés ou de céréales : la vinaigrette décide.
        if (blanc && !gewurz) {
          score = (sauvignon || vifEtSalin ? 90 : 80) + bottleDifferentiator;
          comment = 'Un blanc vif et sec ne craint pas la vinaigrette, ennemie des grands vins : il lui répond par sa propre acidité.';
          serving = 'Servir frais à 9-10°C.';
        } else if (rose) {
          score = 86 + bottleDifferentiator;
          comment = 'Un rosé sec et frais s\'accommode de la vinaigrette et des herbes.';
          serving = 'Servir frais à 8-10°C.';
        } else if (bulles) {
          score = 84 + bottleDifferentiator;
          comment = 'Les bulles d\'un brut gardent la salade légère et ne craignent pas la vinaigrette.';
          serving = 'Servir à 8-10°C.';
        }
      }
    }

    // =========================================================================
    // 2 ter. Soupes & veloutés
    // =========================================================================
    // Avant les poissons et les viandes : une bouillabaisse n'est pas une sole, un pho n'est
    // pas une côte de bœuf. Une soupe aux champignons reste aux champignons.
    else if (_matchesKeywords(query, [
          'soupe', 'soup', 'veloute', 'potage', 'bouillabaisse', 'bullabesa', 'bisque', 'gaspacho', 'gazpacho',
          'salmorejo', 'minestrone', 'garbure', 'pho', 'sopa', 'crema de', 'zuppa', 'vellutata', 'chowder', 'consomme'
        ]) &&
        !_matchesKeywords(query, [
          'champignon', 'cepe', 'morille', 'girolle', 'truffe', 'mushroom', 'truffle', 'porcini', 'funghi', 'setas',
          'tartufo', 'zuppa inglese'
        ])) {
      final blanc = type == 'white' || type == 'blanc';
      final rose = type.contains('rose');
      final rouge = type == 'red' || type == 'rouge';
      final bulles = type.contains('champ') || type.contains('sparkling');
      final provence = region.contains('provence') || appellation.contains('bandol') || appellation.contains('cassis') || appellation.contains('bellet');
      final chardonnayOuViognier = region.contains('bourgogne') || appellation.contains('condrieu') ||
          grapes.any((g) => g.contains('chardonnay') || g.contains('viognier'));
      final aromatique = region.contains('alsace') ||
          grapes.any((g) => g.contains('riesling') || g.contains('gewurz') || g.contains('muscat') || g.contains('pinot gris'));
      if (_matchesKeywords(query, ['bouillabaisse', 'bullabesa', 'poisson', 'fish', 'pescado', 'pesce', 'rouille', 'cacciucco'])) {
        if (rose || (blanc && provence)) {
          score = (provence ? 95 : 88) + bottleDifferentiator;
          comment = 'La bouillabaisse appelle la Provence : un rosé ou un blanc de Bandol ou de Cassis, sec et salin, répond au safran, au fenouil et à la rouille.';
          serving = 'Servir frais à 9-10°C.';
        } else if (blanc && !gewurz) {
          score = 84 + bottleDifferentiator;
          comment = 'Un blanc sec et salin pour les poissons de roche, le safran et l\'ail.';
          serving = 'Servir frais à 9-10°C.';
        }
      } else if (_matchesKeywords(query, ['bisque', 'homard', 'lobster', 'bogavante', 'astice', 'langoustine', 'crustace', 'shellfish'])) {
        if (blanc && chardonnayOuViognier) {
          score = 94 + (appellation.contains('meursault') ? 2 : 0) + bottleDifferentiator;
          comment = 'La texture beurrée d\'un grand Chardonnay épouse le velouté et la douceur iodée de la bisque.';
          serving = 'Servir à 11-12°C.';
        } else if (bulles) {
          score = 88 + bottleDifferentiator;
          comment = 'Les bulles fines d\'un Champagne allègent la crème de la bisque et prolongent ses saveurs de crustacé.';
          serving = 'Servir à 8-10°C.';
        } else if (blanc && !gewurz) {
          score = 82 + bottleDifferentiator;
          comment = 'Un blanc ample et frais accompagne la douceur iodée de la bisque.';
          serving = 'Servir à 10-11°C.';
        }
      } else if (_matchesKeywords(query, ['gaspacho', 'gazpacho', 'salmorejo'])) {
        final xeres = type.contains('fortified') && (region.contains('jerez') || appellation.contains('xeres') ||
            appellation.contains('jerez') || appellation.contains('manzanilla') || appellation.contains('fino'));
        if (xeres) {
          score = 95 + bottleDifferentiator;
          comment = 'L\'accord andalou : un Fino ou une Manzanilla, secs et salins, épousent la tomate, le poivron et le vinaigre de Xérès.';
          serving = 'Servir très frais à 7-9°C.';
        } else if (rose) {
          score = 90 + bottleDifferentiator;
          comment = 'Un rosé sec et frais pour la tomate, le concombre et le poivron du gaspacho.';
          serving = 'Servir frais à 8-10°C.';
        } else if (blanc && !gewurz) {
          score = 84 + bottleDifferentiator;
          comment = 'Un blanc sec et vif répond à la fraîcheur acidulée du gaspacho.';
          serving = 'Servir frais à 8-10°C.';
        }
      } else if (_matchesKeywords(query, ['oignon', 'onion', 'cebolla', 'cipoll'])) {
        if (blanc && (region.contains('savoie') || region.contains('jura'))) {
          score = 92 + bottleDifferentiator;
          comment = 'Un blanc de Savoie ou du Jura, vif et franc, tranche le fromage gratiné et la douceur des oignons.';
          serving = 'Servir à 9-11°C.';
        } else if (blanc && !gewurz) {
          score = (region.contains('bourgogne') || region.contains('alsace') ? 88 : 80) + bottleDifferentiator;
          comment = 'Un blanc sec et frais tranche le fromage gratiné et la douceur des oignons confits.';
          serving = 'Servir à 10-11°C.';
        } else if (rouge && (region.contains('beaujolais') || grapes.any((g) => g.contains('gamay')))) {
          score = 84 + bottleDifferentiator;
          comment = 'Un Beaujolais fruité, servi frais, comme dans les bouchons et les brasseries.';
          serving = 'Servir légèrement rafraîchi à 14-15°C.';
        }
      } else if (_matchesKeywords(query, [
        'potimarron', 'potiron', 'citrouille', 'butternut', 'courge', 'pumpkin', 'squash', 'calabaza', 'zucca',
        'chataigne', 'chestnut', 'castana', 'castagn', 'carotte', 'carrot', 'zanahoria', 'carot'
      ])) {
        if (blanc && chardonnayOuViognier) {
          // Un Chablis, tendu et maigre, moins qu'un Chardonnay ample de la Côte de Beaune.
          score = (appellation.contains('chablis') ? 86 : 92) + bottleDifferentiator;
          comment = 'Un Chardonnay ou un Viognier, ronds et beurrés, épousent la douceur veloutée de la courge ou de la châtaigne.';
          serving = 'Servir à 11-12°C.';
        } else if (blanc && aromatique) {
          score = 88 + bottleDifferentiator;
          comment = 'Un blanc d\'Alsace, rond et parfumé, répond à la douceur épicée du velouté.';
          serving = 'Servir à 10°C.';
        } else if (blanc && !gewurz) {
          score = 80 + bottleDifferentiator;
          comment = 'Un blanc rond et souple pour la douceur du velouté.';
          serving = 'Servir à 10-11°C.';
        }
      } else if (_matchesKeywords(query, ['minestrone', 'pistou', 'legume', 'vegetable', 'verdura', 'verdure'])) {
        final italienLeger = rouge && (region.contains('tosc') || region.contains('ital') ||
            grapes.any((g) => g.contains('sangiovese') || g.contains('barbera')));
        if (rose) {
          score = (provence ? 90 : 86) + bottleDifferentiator;
          comment = 'Un rosé sec et frais pour les légumes du potager et le basilic.';
          serving = 'Servir frais à 8-10°C.';
        } else if (italienLeger) {
          score = 86 + bottleDifferentiator;
          comment = 'Un rouge italien fruité et digeste, à la manière d\'un Chianti, pour le minestrone et son parmesan.';
          serving = 'Servir à 15-16°C.';
        } else if (blanc && !gewurz) {
          score = 82 + bottleDifferentiator;
          comment = 'Un blanc sec et frais pour les légumes du potager et le basilic.';
          serving = 'Servir frais à 9-10°C.';
        }
      } else if (_matchesKeywords(query, ['garbure', 'potee', 'paysanne', 'chou', 'cabbage'])) {
        if (rouge && (region.contains('sud ouest') || appellation.contains('cahors') || appellation.contains('madiran') ||
            appellation.contains('irouleguy') || appellation.contains('bearn'))) {
          score = 92 + bottleDifferentiator;
          comment = 'La garbure appelle un rouge du Sud-Ouest, charpenté et franc, pour le confit, le jambon et le chou.';
          serving = 'Servir à 16-17°C.';
        } else if (rouge) {
          score = 82 + bottleDifferentiator;
          comment = 'Un rouge franc et rustique pour une soupe de terroir.';
          serving = 'Servir à 16°C.';
        }
      } else if (_matchesKeywords(query, ['pho', 'thai', 'tom yum', 'tom kha', 'miso', 'vietnam', 'asiat', 'asian'])) {
        if (blanc && aromatique) {
          score = 92 + bottleDifferentiator;
          comment = 'Un blanc aromatique, à la manière d\'un Riesling, répond au bouillon parfumé, au gingembre et aux herbes fraîches.';
          serving = 'Servir à 9-10°C.';
        } else if (blanc || rose) {
          score = 80 + bottleDifferentiator;
          comment = 'Un vin frais et sec, sans tanins, pour le bouillon parfumé et les herbes.';
          serving = 'Servir frais à 8-10°C.';
        }
      } else if ((blanc && !gewurz) || rose) {
        score = 80 + bottleDifferentiator;
        comment = 'Un vin frais et sec, sans tanins, accompagne la soupe sans l\'écraser.';
        serving = 'Servir frais à 9-10°C.';
      }
    }

    // =========================================================================
    // 2 quater. Légumes & cuisine végétarienne
    // =========================================================================
    // Sans viande ni poisson dans le nom (un magret aux légumes reste un magret), et sans
    // les épices d'un curry ou d'un tajine, qui se jugent plus bas à leurs épices.
    else if (!isSpicyDish && !isLamb && !isBeef && !isDuck && !isPoultryOrSea && _matchesKeywords(query, [
      'ratatouille', 'tian', 'legume', 'vegetable', 'verdura', 'verdure', 'vegetar', 'vegan', 'veggie',
      'aubergine', 'eggplant', 'berenjena', 'melanzan', 'parmigiana', 'courgette', 'zucchin', 'calabacin',
      'poivron', 'pimiento', 'peperon', 'stuffed pepper', 'falafel', 'houmous', 'hummus', 'ganoush', 'ganouj',
      'asperge', 'asparag', 'esparrago', 'butternut', 'courge', 'squash', 'potimarron', 'potiron', 'pumpkin',
      'calabaza', 'zucca', 'dauphinois', 'tofu', 'seitan', 'quinoa', 'boulgour', 'bulgur'
    ])) {
      final blanc = type == 'white' || type == 'blanc';
      final rose = type.contains('rose');
      final rouge = type == 'red' || type == 'rouge';
      final bulles = type.contains('champ') || type.contains('sparkling');
      final sudiste = region.contains('provence') || region.contains('rhone') || region.contains('languedoc') ||
          region.contains('roussillon') || appellation.contains('bandol');
      final rougeDuSud = rouge && sudiste &&
          grapes.any((g) => g.contains('grenache') || g.contains('cinsault') || g.contains('mourvedre') || g.contains('carignan'));
      final rougeGamay = rouge && (region.contains('beaujolais') || grapes.any((g) => g.contains('gamay')));
      final rougeLeger = rougeGamay || (rouge && grapes.any((g) => g.contains('pinot noir')));
      if (_matchesKeywords(query, ['asperge', 'asparag', 'esparrago'])) {
        final sauvignonOuMuscat = grapes.any((g) => g.contains('sauvignon') || g.contains('muscat')) ||
            appellation.contains('sancerre') || appellation.contains('pouilly') || appellation.contains('menetou');
        if (blanc && sauvignonOuMuscat) {
          score = 94 + bottleDifferentiator;
          comment = 'L\'asperge, si difficile à marier, trouve son vin dans un Sauvignon ou un Muscat sec, dont les notes végétales lui répondent.';
          serving = 'Servir à 9-11°C.';
        } else if (blanc && region.contains('alsace') && !gewurz) {
          score = 88 + bottleDifferentiator;
          comment = 'Un blanc d\'Alsace, sec et parfumé, répond à l\'amertume délicate de l\'asperge.';
          serving = 'Servir à 10°C.';
        } else if (bulles) {
          score = 82 + bottleDifferentiator;
          comment = 'Les bulles d\'un brut accompagnent l\'asperge sans durcir.';
          serving = 'Servir à 8-10°C.';
        } else if (blanc && !gewurz) {
          score = 78 + bottleDifferentiator;
          comment = 'Un blanc sec et frais, sans boisé, pour ne pas heurter l\'asperge.';
          serving = 'Servir frais à 9-10°C.';
        }
      } else if (_matchesKeywords(query, ['falafel', 'houmous', 'hummus', 'ganoush', 'ganouj', 'mezze', 'meze'])) {
        if (rose) {
          score = 90 + bottleDifferentiator;
          comment = 'Un rosé sec et frais pour les pois chiches, le sésame et les herbes des mezze.';
          serving = 'Servir frais à 8-10°C.';
        } else if (blanc && !gewurz) {
          score = 84 + bottleDifferentiator;
          comment = 'Un blanc sec et frais pour le citron, le sésame et les herbes.';
          serving = 'Servir frais à 9-10°C.';
        }
      } else if (_matchesKeywords(query, [
        'butternut', 'courge', 'squash', 'potimarron', 'potiron', 'pumpkin', 'calabaza', 'zucca', 'dauphinois', 'gratin'
      ])) {
        if (blanc && (region.contains('bourgogne') || grapes.any((g) => g.contains('chardonnay') || g.contains('viognier')))) {
          score = (appellation.contains('chablis') ? 86 : 90) + bottleDifferentiator;
          comment = 'Un blanc rond et beurré, à la manière d\'un Chardonnay, épouse la douceur crémeuse du gratin.';
          serving = 'Servir à 11-12°C.';
        } else if (blanc && !gewurz) {
          score = 82 + bottleDifferentiator;
          comment = 'Un blanc rond et souple pour la douceur du gratin.';
          serving = 'Servir à 10-11°C.';
        } else if (rougeLeger) {
          score = 80 + bottleDifferentiator;
          comment = 'Un rouge léger et fruité, servi frais, pour accompagner le gratin.';
          serving = 'Servir légèrement rafraîchi à 14-15°C.';
        }
      } else if (_matchesKeywords(query, ['parmigiana', 'aubergine', 'eggplant', 'berenjena', 'melanzan'])) {
        final italien = rouge && (region.contains('tosc') || region.contains('ital') || region.contains('sicil') ||
            grapes.any((g) => g.contains('sangiovese') || g.contains('nero d') || g.contains('barbera')));
        if (italien) {
          score = 92 + bottleDifferentiator;
          comment = 'Un rouge italien, fruité et vif, répond à la tomate, à l\'aubergine et au parmesan.';
          serving = 'Servir à 15-16°C.';
        } else if (rose) {
          score = 86 + bottleDifferentiator;
          comment = 'Un rosé sec et frais pour la tomate, l\'aubergine et le basilic.';
          serving = 'Servir frais à 8-10°C.';
        } else if (rougeDuSud) {
          score = 86 + bottleDifferentiator;
          comment = 'Un rouge du Sud, fruité et souple, pour l\'aubergine fondante et la tomate.';
          serving = 'Servir à 15-16°C.';
        }
      } else {
        // Ratatouille, tian, légumes grillés, burger végétarien : le soleil du Sud.
        if (rose) {
          score = (sudiste ? 92 : 86) + bottleDifferentiator;
          comment = 'Un rosé sec et fruité, comme en Provence, pour les légumes du soleil, l\'huile d\'olive et les herbes.';
          serving = 'Servir frais à 8-10°C.';
        } else if (rougeDuSud) {
          score = 88 + bottleDifferentiator;
          comment = 'Un rouge du Sud, fruité et souple, aux tanins doux, pour les légumes confits et les herbes de Provence.';
          serving = 'Servir à 15-16°C.';
        } else if (rougeLeger) {
          score = (rougeGamay ? 82 : 78) + bottleDifferentiator;
          comment = 'Un rouge léger et fruité, servi frais, pour ne pas écraser les légumes.';
          serving = 'Servir légèrement rafraîchi à 14-15°C.';
        } else if (blanc && sudiste) {
          score = 86 + bottleDifferentiator;
          comment = 'Un blanc du Sud, ample et parfumé, pour les légumes du soleil.';
          serving = 'Servir à 10-11°C.';
        } else if (blanc && !gewurz) {
          score = 80 + bottleDifferentiator;
          comment = 'Un blanc sec et frais pour les légumes et les herbes.';
          serving = 'Servir frais à 9-10°C.';
        }
      }
    }

    // =========================================================================
    // 3. Red Meat, Lamb, Steaks & Grillades
    // =========================================================================
    else if (!isStew && !isSpicyDish && (isLamb || isBeef || isDuck || (!isPoultryOrSea && _matchesKeywords(query, [
      'boeuf', 'bœuf', 'cote de boeuf', 'côte de bœuf', 'entrecote', 'entrecôte',
      'magret', 'canard', 'grillade', 'steak', 'agneau', 'bavette', 'tartare',
      'tournedos', 'picanha', 'onglet', 'brochette', 'faux-filet', 'chateaubriand',
      'rumsteak', 'carré d\'agneau', 't-bone', 'ribeye', 'barbecue', 'bbq',
      'beef', 'lamb', 'mutton', 'sirloin', 'tenderloin', 'filet mignon', 'prime rib',
      'leg of lamb', 'lamb chops', 'roast lamb', 'flank steak', 'meat', 'roast beef',
      'buey', 'ternera', 'chuleta', 'chuleton', 'entrecot', 'cordero', 'pierna de cordero',
      'asado', 'costillas', 'carne', 'carne roja', 'vedella',
      'mitjana', 'xai', 'anyell', 'cuixa de xai', 'costelles', 'graellada', 'bubula',
      'agnus', 'agninus', 'assatura', 'crus agninum', 'roast', 'roti', 'rôti'
    ])))) {
      if (type == 'red' || type == 'rouge') {
        int baseScore = 78;
        int grapeBonus = 0;
        int terroirBonus = 0;
        int herbBonus = 0;

        final isBordeaux = region.contains('bordeaux') || region.contains('medoc') || region.contains('graves') || region.contains('saint emilion') || region.contains('pomerol') || appellation.contains('margaux') || appellation.contains('pauillac') || appellation.contains('saint julien');
        final isRhone = region.contains('rhone') || appellation.contains('hermitage') || appellation.contains('cornas') || appellation.contains('chateauneuf') || appellation.contains('saint joseph') || appellation.contains('cote rotie') || appellation.contains('gigondas');
        final isProvence = region.contains('provence') || appellation.contains('bandol');
        final isSpain = region.contains('espagne') || region.contains('spain') || region.contains('ribera') || region.contains('rioja') || region.contains('jumilla') || region.contains('priorat');
        final isSouthWest = region.contains('sud ouest') || region.contains('cahors') || region.contains('madiran');
        final isBurgundy = region.contains('bourgogne') || region.contains('burgundy');

        if (isBordeaux) {
          baseScore = 86;
          terroirBonus = (appellation.contains('pauillac') || appellation.contains('margaux') || appellation.contains('saint julien') || appellation.contains('pomerol')) ? 4 : 2;
        } else if (isRhone) {
          baseScore = 86;
          terroirBonus = (appellation.contains('hermitage') || appellation.contains('cote rotie') || appellation.contains('cornas') || appellation.contains('chateauneuf')) ? 4 : 2;
        } else if (isProvence) {
          baseScore = 85;
          terroirBonus = appellation.contains('bandol') ? 4 : 2;
        } else if (isSpain) {
          baseScore = 84;
          terroirBonus = (region.contains('ribera') || region.contains('priorat') || appellation.contains('gran reserva')) ? 3 : 2;
        } else if (isSouthWest) {
          baseScore = 84;
          terroirBonus = 2;
        } else if (isBurgundy) {
          baseScore = 78;
          terroirBonus = appellation.contains('grand cru') ? 3 : (appellation.contains('premier cru') ? 2 : 1);
        } else {
          baseScore = 75;
        }

        // Dish-specific grape affinities
        if (isLamb) {
          if (grapes.any((g) => g.contains('cabernet'))) {
            grapeBonus += 5; // Cabernet + Lamb is world-famous
          } else if (grapes.any((g) => g.contains('syrah') || g.contains('shiraz'))) {
            grapeBonus += 5;
          } else if (grapes.any((g) => g.contains('mourvedre') || g.contains('mourvèdre'))) {
            grapeBonus += 5;
          } else if (grapes.any((g) => g.contains('tempranillo'))) {
            grapeBonus += 4;
          } else if (grapes.any((g) => g.contains('merlot'))) {
            grapeBonus += 3;
          } else if (grapes.any((g) => g.contains('pinot noir') || g.contains('gamay'))) {
            grapeBonus -= 2;
          }
        } else if (isBeef) {
          if (grapes.any((g) => g.contains('cabernet'))) grapeBonus += 5;
          if (grapes.any((g) => g.contains('malbec') || g.contains('tannat'))) grapeBonus += 5;
          if (grapes.any((g) => g.contains('syrah'))) grapeBonus += 4;
          if (grapes.any((g) => g.contains('merlot'))) grapeBonus += 3;
        } else if (isDuck) {
          if (grapes.any((g) => g.contains('pinot noir'))) grapeBonus += 6;
          if (grapes.any((g) => g.contains('syrah'))) grapeBonus += 4;
          if (grapes.any((g) => g.contains('malbec'))) grapeBonus += 4;
        } else {
          if (grapes.any((g) => g.contains('cabernet') || g.contains('syrah') || g.contains('mourvedre'))) grapeBonus += 4;
        }

        // Herbal / Thyme synergy
        if (hasThymeOrHerbs) {
          if (isProvence || isRhone) {
            herbBonus = 4;
          } else if (isBordeaux) {
            herbBonus = 3;
          } else if (isSpain) {
            herbBonus = 2;
          } else {
            herbBonus = 1;
          }
        }

        score = baseScore + grapeBonus + terroirBonus + herbBonus + bottleDifferentiator;

        // Vintage & maturity peak adjustment
        if (isMature) {
          score += 3;
        } else if (wine.windowStatus == DrinkWindowStatus.tooYoung || wine.windowStatus == DrinkWindowStatus.aging) {
          score -= 1;
        }

        // Sommelier narrative
        if (isLamb && hasThymeOrHerbs) {
          if (isBordeaux) {
            comment = 'Accord royal et légendaire : la trame tannique noble et les notes de cèdre et fruits noirs de ce Bordeaux subliment la chair fondante de l\'agneau rôti, tandis que les arômes toastés répondent avec majesté au parfum sauvage du thym.';
            serving = isMature ? 'Déboucher 1h avant sans carafage brusque (16-17°C).' : 'Carafer 2 heures pour assouplir les tanins jeunes (16-18°C).';
          } else if (isProvence || isRhone) {
            comment = 'Accord sommelier d\'anthologie : la rondeur solaire, le poivre noir et les accents de garrigue et d\'épices du Sud s\'unissent divinement au thym et aux sucs grillés du gigot d\'agneau.';
            serving = 'Servir à 16-17°C en grand verre tulipe.';
          } else if (isSpain) {
            comment = 'L\'accord ibérique par excellence : le rôti d\'agneau au thym s\'accorde à merveille avec les tanins veloutés, le cuir noble et la vanille de ce grand rouge espagnol.';
            serving = 'Servir chambré à 16-17°C.';
          } else {
            comment = 'Ce vin rouge structuré possède la matière et la vivacité nécessaires pour accompagner la richesse de l\'agneau et les herbes aromatiques.';
            serving = 'Servir à 16-17°C.';
          }
        } else if (isBordeaux) {
          comment = 'La structure tannique noble et les notes de cèdre / cassis de ce Bordeaux s\'harmonisent superbement avec les sucs et le persillé de la viande.';
          serving = isMature ? 'Déboucher 1h avant sans carafage brusque (16-17°C).' : 'Carafer 2 heures pour assouplir les tanins jeunes (16-18°C).';
        } else if (isRhone) {
          comment = 'La générosité solaire et les notes poivrées / épicées de la Syrah et du Grenache subliment la viande grillée ou rôtie avec puissance.';
          serving = 'Servir entre 16°C et 17°C en grand verre tulipe.';
        } else if (isProvence) {
          comment = 'La race du Mourvèdre et ses arômes de garrigue, cuir et fruits noirs créent un accord magistral sur une belle viande grillée aux sarments.';
          serving = 'Servir à 16-17°C après une légère aération.';
        } else if (isSpain) {
          comment = 'L\'intensité chaleureuse, les tanins mûrs et les notes grillées du vin résonnent parfaitement avec les saveurs du barbecue et de la viande saisie.';
          serving = 'Servir à 16-17°C.';
        } else if (isBurgundy) {
          comment = 'Pour une pièce tendre (filet de bœuf, magret poêlé), le soyeux et la cerise noire du Pinot Noir offrent un accord raffiné.';
          serving = 'Servir à 15-16°C dans un verre ballon.';
        } else {
          comment = 'Ce vin rouge possède la vivacité et la charpente nécessaires pour soutenir ce plat.';
          serving = 'Servir chambré à 16-17°C.';
        }
      }
    }

    // =========================================================================
    // 4. Game & Stew (Bourguignon, Daube, Cassoulet, etc.)
    // =========================================================================
    else if (isStew) {
      if (type == 'red' || type == 'rouge') {
        if (_matchesKeywords(query, ['bourguignon', 'borgoñona', 'borgognona']) && (region.contains('bourgogne') || grapes.contains('pinot noir'))) {
          score = 96 + bottleDifferentiator;
          comment = 'Accord régional par symbiose : le Pinot Noir cuit dans la sauce et sublimé dans le verre crée une continuité aromatique exceptionnelle.';
          serving = 'Servir à 16°C en grand verre Bourgogne.';
        } else if (_matchesKeywords(query, ['cassoulet']) && (region.contains('sud ouest') || region.contains('languedoc') || region.contains('cahors') || region.contains('madiran'))) {
          score = 96 + bottleDifferentiator;
          comment = 'Accord terrien magistral : les tanins vigoureux et le fruité noir franc contrebalancent la richesse confite des haricots et du canard.';
          serving = 'Servir chambré à 17°C.';
        } else if (isMature) {
          score = 92 + (grapes.contains('syrah') || region.contains('bordeaux') ? 2 : 0) + bottleDifferentiator;
          comment = 'Un vin rouge patiné par l\'âge aux notes de sous-bois, truffe et cuir se fond à merveille dans les sauces longues et le gibier.';
          serving = 'Déboucher délicatement sans brusquer les sédiments (16-17°C).';
        } else {
          score = 83 + bottleDifferentiator;
          comment = 'La concentration et les épices de ce vin rouge enveloppent les saveurs denses de ce plat mijoté.';
          serving = 'Carafer 1h pour ouvrir le bouquet.';
        }
      }
    }

    // =========================================================================
    // 5. Poultry & Veal
    // =========================================================================
    else if (!isSpicyDish && _matchesKeywords(query, [
      'poulet', 'volaille', 'chapon', 'dinde', 'veau', 'quasi', 'pintade', 'caille',
      'ris de veau', 'blanquette', 'escalope', 'coq au vin', 'poularde', 'supreme de volaille',
      'chicken', 'poultry', 'veal', 'turkey', 'quail', 'guinea fowl', 'roast chicken',
      'pollo', 'ternera', 'pollastre', 'vedella', 'pavo', 'gallina', 'gallus',
      'pollame', 'vitello', 'cappone', 'faraona', 'tacchino', 'quaglia', 'cotoletta', 'scaloppin', 'galletto',
      'capon', 'pintada'
    ])) {
      if (type == 'white' || type == 'blanc') {
        if (region.contains('bourgogne') || region.contains('rhone') || grapes.contains('chardonnay') || appellation.contains('meursault')) {
          score = 94 + (appellation.contains('meursault') ? 3 : 1) + bottleDifferentiator;
          comment = 'Un blanc ample et rond enrobe magnifiquement la chair délicate et les sauces crémées (morilles, blanquette, poularde).';
          serving = 'Servir à 11-13°C sans excès de fraîcheur.';
        } else {
          score = 81 + bottleDifferentiator;
          comment = 'La rondeur de ce blanc accompagne avec finesse la tendreté de la viande blanche.';
          serving = 'Servir à 10-12°C.';
        }
      } else if (type == 'red' || type == 'rouge') {
        if (region.contains('bourgogne') || region.contains('loire') || grapes.contains('pinot noir') || grapes.contains('gamay')) {
          score = 92 + (grapes.contains('pinot noir') ? 2 : 0) + bottleDifferentiator;
          comment = 'Des tanins soyeux et un fruit croquant (framboise, cerise) valorisent parfaitement le rôti de veau ou le poulet du dimanche sans dominer.';
          serving = 'Servir frais à 15-16°C.';
        } else {
          score = 75 + bottleDifferentiator;
          comment = 'Un vin rouge équilibré et fondu pour accompagner la volaille rôtie.';
          serving = 'Servir à 15-16°C.';
        }
      }
    }

    // =========================================================================
    // 6. Delicate Fish (Sole, Bar, Turbot, Beurre blanc)
    // =========================================================================
    else if (_matchesKeywords(query, [
      'sole', 'meuniere', 'meunière', 'bar', 'loup de mer', 'turbot', 'cabillaud',
      'saint-pierre', 'dorade', 'daurade', 'lotte', 'beurre blanc', 'truite',
      'lieu jaune', 'merlan', 'poisson blanc', 'papillote', 'poisson', 'flétan',
      'fish', 'white fish', 'sea bass', 'bass', 'cod', 'halibut', 'flounder', 'trout',
      'pescado', 'lubina', 'bacalao', 'lenguado', 'peix', 'llobarro', 'piscis',
      'pesce', 'branzino', 'spigola', 'rombo', 'sogliola', 'orata', 'merluzzo', 'baccala', 'trota', 'rana pescatrice', 'san pietro', 'nasello', 'dentice', 'cernia',
      'bream', 'john dory', 'monkfish', 'dorada', 'rodaballo', 'san pedro', 'trucha', 'armoricana', 'merluza',
      'morue', 'raie', 'skate', 'raya', 'razza'
    ])) {
      if (type == 'white' || type == 'blanc') {
        if (appellation.contains('chablis') || region.contains('loire') || appellation.contains('sancerre') || appellation.contains('pouilly') || appellation.contains('muscadet')) {
          score = 96 + (appellation.contains('grand cru') ? 2 : 0) + bottleDifferentiator;
          comment = 'La pureté minérale, la vivacité saline et la tension d\'agrumes subliment la chair nacrée du poisson sans jamais la saturer.';
          serving = 'Servir frais à 9-11°C.';
        } else if (region.contains('bourgogne') || appellation.contains('meursault') || grapes.contains('chardonnay')) {
          score = 94 + (appellation.contains('meursault') ? 3 : 1) + bottleDifferentiator;
          comment = 'La rondeur et la texture satinée du vin font écho à la sauce au beurre blanc ou à la sole meunière poêlée.';
          serving = 'Servir à 11-12°C.';
        } else {
          score = 78 + bottleDifferentiator;
          comment = 'Fraîcheur et équilibre pour respecter la délicatesse des saveurs marines.';
          serving = 'Servir bien frais (8-10°C).';
        }
      } else if (type.contains('champ') || type.contains('sparkling')) {
        score = 90 + bottleDifferentiator;
        comment = 'L\'effervescence crémeuse et la droiture des bulles exaltent les poissons nobles au beurre blanc.';
        serving = 'Servir à 8-10°C.';
      }
    }

    // =========================================================================
    // 7. Fatty Fish, Sushi & Ceviche (Saumon, Thon, Tataki)
    // =========================================================================
    else if (_matchesKeywords(query, [
      'saumon', 'thon', 'tataki', 'sushi', 'sashimi', 'ceviche', 'poke bowl',
      'saumon fume', 'saumon fumé', 'maquereau', 'sardine', 'anchois', 'tartare de saumon',
      'thon mi-cuit', 'hareng', 'anguille', 'tartare de thon', 'gravlax',
      'salmon', 'tuna', 'mackerel', 'sardines', 'salmón', 'atún', 'salmo', 'thunnus',
      'salmone', 'tonno', 'sgombro', 'sarde', 'alici', 'acciughe', 'anguilla', 'pesce spada', 'aringa',
      'caballa', 'sardina', 'boquerones', 'anguila'
    ])) {
      if (type == 'white' || type == 'blanc') {
        if (_matchesKeywords(query, ['ceviche']) && (grapes.contains('sauvignon') || region.contains('loire') || region.contains('alsace') || grapes.contains('riesling'))) {
          score = 95 + bottleDifferentiator;
          comment = 'La vivacité tranchante et les notes de citron vert du vin s\'accordent à merveille avec l\'acidité de la marinade du ceviche.';
          serving = 'Servir à 8-10°C.';
        } else if (appellation.contains('chablis') || grapes.contains('riesling')) {
          score = 90 + bottleDifferentiator;
          comment = 'La droiture minérale coupe le gras savoureux du saumon ou du thon cru tout en respectant les sauces soja et wasabi.';
          serving = 'Servir frais à 9-11°C.';
        } else {
          score = 77 + bottleDifferentiator;
          comment = 'Ce vin blanc offre la fraîcheur requise pour équilibrer le poisson gras.';
          serving = 'Servir frais à 9-10°C.';
        }
      } else if (type == 'rose' || type == 'rosé') {
        score = 83 + (region.contains('provence') || appellation.contains('bandol') ? 3 : 0) + bottleDifferentiator;
        comment = 'Un rosé gastronomique offre le compromis rêvé entre fraîcheur iodée et rondeur fruitée sur les sushis et le thon mi-cuit.';
        serving = 'Servir à 9-10°C.';
      } else if (type == 'red' || type == 'rouge') {
        if (grapes.contains('pinot noir') || region.contains('bourgogne')) {
          score = 79 + bottleDifferentiator;
          comment = 'Accord d\'audace plébiscité par les sommeliers : la souplesse et le fruit rouge frais du Pinot Noir sur un pavé de thon rouge ou un saumon grillé.';
          serving = 'Servir légèrement frais à 14°C.';
        }
      }
    }

    // =========================================================================
    // 8. Seafood & Shellfish (Huîtres, Homard, Saint-Jacques)
    // =========================================================================
    else if (_matchesKeywords(query, [
      'huitre', 'huître', 'crevette', 'homard', 'langouste', 'langoustine',
      'saint-jacques', 'st-jacques', 'fruits de mer', 'crustaces', 'crustacés',
      'gambas', 'moule', 'moules marinières', 'coquillage', 'bulot', 'bigorneau',
      'tourteau', 'crabe', 'couteau', 'palourde', 'ecrevisse', 'écrevisse',
      'oyster', 'oysters', 'lobster', 'shrimp', 'prawns', 'scallops', 'seafood',
      'mussels', 'crab', 'clams', 'marisco', 'ostras', 'gambas', 'vieiras', 'mejillones',
      'ostres', 'ostrea',
      'ostriche', 'capesante', 'astice', 'aragosta', 'scampi', 'gamberi', 'gamberoni', 'cozze', 'vongole',
      'frutti di mare', 'crostacei', 'granchio', 'grancevola', 'cannolicchi',
      'bogavante', 'centollo', 'cigala', 'navaja', 'razor clam', 'langosta',
      'calamar', 'calmar', 'squid', 'encornet', 'seiche', 'sepia', 'seppi', 'poulpe', 'pulpo', 'polpo', 'octopus', 'ostric', 'frutti di mare'
    ])) {
      if (type == 'white' || type == 'blanc') {
        if (_matchesKeywords(query, ['huitre', 'oyster', 'ostra', 'ostriche'])) {
          if (appellation.contains('chablis') || appellation.contains('muscadet')) {
            score = 98 + (appellation.contains('grand cru') ? 1 : 0) + bottleDifferentiator;
            comment = 'L\'accord absolu de la mer : la salinité éclatante et la vivacité iodée s\'unissent divinement aux huîtres.';
            serving = 'Servir très frais à 8-10°C sans attendre.';
          } else if (appellation.contains('sancerre') || appellation.contains('picpoul')) {
            score = 92 + bottleDifferentiator;
            comment = 'La vivacité tranchante et les notes d\'agrumes apportent une belle fraîcheur sur les huîtres.';
            serving = 'Servir à 8-10°C.';
          } else {
            score = 79 + bottleDifferentiator;
            comment = 'Fraîcheur désaltérante idéale sur un plateau de fruits de mer.';
            serving = 'Servir à 9-10°C.';
          }
        } else if (_matchesKeywords(query, ['saint-jacques', 'homard', 'langoust', 'lobster', 'scallop', 'vieira', 'bogavante', 'cigala', 'capesant', 'astice', 'aragost', 'scampi'])) {
          if (region.contains('bourgogne') || grapes.contains('chardonnay') || region.contains('rhone')) {
            score = 96 + bottleDifferentiator;
            comment = 'La texture et la minéralité de ce grand blanc subliment la douceur iodée et la chair noble des crustacés et coquilles Saint-Jacques.';
            serving = 'Servir à 10-12°C.';
          } else {
            score = 81 + bottleDifferentiator;
            comment = 'Belle élégance et équilibre pour respecter la texture fine des crustacés.';
            serving = 'Servir à 10°C.';
          }
        } else if (appellation.contains('muscadet') || appellation.contains('chablis') || appellation.contains('picpoul') ||
            appellation.contains('sancerre') || appellation.contains('entre deux mers') || region.contains('loire') ||
            grapes.any((g) => g.contains('albarino') || g.contains('vermentino') || g.contains('melon'))) {
          final classique = appellation.contains('muscadet') || appellation.contains('picpoul') || grapes.any((g) => g.contains('melon'));
          score = (classique ? 95 : 93) + bottleDifferentiator;
          comment = 'Le grand classique des fruits de mer : un blanc vif et iodé, à la manière d\'un Muscadet, d\'un Chablis ou d\'un Picpoul, prolonge la mer.';
          serving = 'Servir très frais à 8-10°C sans attendre.';
        } else if (!gewurz) {
          score = 77 + bottleDifferentiator;
          comment = 'Fraîcheur désaltérante idéale sur un plateau de fruits de mer.';
          serving = 'Servir à 9-10°C.';
        }
      } else if (type.contains('champ') || type.contains('sparkling')) {
        // Les bulles pour les huîtres, le homard et le plateau ; moins pour l'ail et la plancha.
        final festif = _matchesKeywords(query, [
          'huitre', 'oyster', 'ostra', 'ostric', 'homard', 'lobster', 'langouste', 'bogavante', 'astice', 'plateau',
          'platter', 'bandeja', 'saint-jacques', 'scallop', 'vieira', 'capesant', 'caviar'
        ]);
        score = (festif ? 96 : 86) + bottleDifferentiator;
        comment = festif
            ? 'L\'effervescence pure et vive des bulles réveille les papilles et magnifie la chair raffinée du homard et des huîtres.'
            : 'Les fines bulles d\'un brut accompagnent les fruits de mer avec fraîcheur.';
        serving = 'Servir à 8-9°C en verre tulipe.';
      } else if (type.contains('rose')) {
        final plancha = _matchesKeywords(query, [
          'plancha', 'paella', 'ajillo', 'aglio', 'garlic', 'calamar', 'squid', 'gambas', 'gamberi', 'grill', 'parrilla', 'griglia', 'piastra'
        ]);
        score = (plancha ? 88 : 78) + bottleDifferentiator;
        comment = plancha
            ? 'Un rosé sec et frais pour la plancha, l\'ail et le safran.'
            : 'Un rosé sec et frais accompagne les fruits de mer avec simplicité.';
        serving = 'Servir frais à 8-10°C.';
      }
    }

    // =========================================================================
    // 9. Goat & Sheep Cheese
    // =========================================================================
    else if (_matchesKeywords(query, [
      'chevre', 'chèvre', 'crottin', 'chavignol', 'sainte-maure', 'valençay',
      'banon', 'pelardon', 'rocamadour', 'brebis', 'ossau-iraty', 'manchego',
      'feta', 'roquefort', 'bleu', 'gorgonzola', 'fourme', 'goat cheese', 'sheep cheese',
      'blue cheese', 'pecorino',
      'caprino', 'formaggio di capra', 'formaggi di capra', 'erborinato',
      'selles-sur-cher', 'cabra', 'oveja'
    ])) {
      if (_matchesKeywords(query, ['roquefort', 'bleu', 'fourme', 'blue cheese', 'gorgonzola', 'erborinat', 'stilton', 'queso azul'])) {
        if (type.contains('dessert') || type.contains('moell') || type.contains('sauternes') || type.contains('sweet')) {
          score = 97 + bottleDifferentiator;
          comment = 'Accord légendaire de contraste : le sel puissant et le piquant du fromage bleu sont magnifiés par l\'onctuosité liquoreuse du grand vin blanc moelleux.';
          serving = 'Servir à 8-10°C.';
        } else if (region.contains('rhone') || region.contains('banyuls') || region.contains('porto')) {
          score = 87 + bottleDifferentiator;
          comment = 'Un vin rouge doux ou puissant épicé tient tête au caractère affirmé du persillé.';
          serving = 'Servir à 15°C.';
        }
      } else if ((type == 'white' || type == 'blanc') &&
          _matchesKeywords(query, ['ossau', 'iraty', 'brebis', 'sheep', 'pecorino', 'oveja', 'pecora', 'manchego'])) {
        score = (gewurz ? 70 : 78) + bottleDifferentiator;
        comment = 'La fraîcheur du vin blanc respecte les ferments du fromage sans laisser d\'amertume.';
        serving = 'Servir à 10°C.';
      } else if (type == 'white' || type == 'blanc') {
        final sauvignon = grapes.contains('sauvignon') || appellation.contains('sancerre') || appellation.contains('pouilly fume');
        if (region.contains('loire') || sauvignon) {
          score = 96 + (appellation.contains('sancerre') ? 2 : 0) + bottleDifferentiator;
          // Le Sauvignon n'est nommé que s'il est dans le verre : un Vouvray passe aussi ici.
          comment = sauvignon
              ? 'L\'accord parfait : les notes de buis et la vivacité d\'agrumes du Sauvignon épousent intimement le gras caprin du Crottin de Chavignol ou du Sainte-Maure.'
              : 'L\'accord parfait : la vivacité d\'agrumes de ce blanc épouse intimement le gras caprin du Crottin de Chavignol ou du Sainte-Maure.';
          serving = 'Servir à 9-11°C.';
        } else {
          score = 79 + bottleDifferentiator;
          comment = 'La fraîcheur du vin blanc respecte les ferments du fromage sans laisser d\'amertume.';
          serving = 'Servir à 10°C.';
        }
      } else if ((type == 'red' || type == 'rouge') && _matchesKeywords(query, ['ossau', 'brebis', 'sheep', 'pecorino', 'oveja', 'pecora', 'manchego'])) {
        if (region.contains('sud ouest') || region.contains('madiran') || region.contains('bordeaux') || region.contains('rioja') ||
            region.contains('espagne') || region.contains('spain') || region.contains('ribera') || region.contains('navarr')) {
          score = 90 + bottleDifferentiator;
          comment = 'La douceur de la pâte de brebis et la confiture de cerises noires s\'accordent merveilleusement avec ce rouge.';
          serving = 'Servir à 16°C.';
        }
      }
    }

    // =========================================================================
    // 10. Cow milk & Pressed Cheese (Comté, Beaufort, Brie)
    // =========================================================================
    else if (_matchesKeywords(query, [
      'comte', 'comté', 'beaufort', 'gruyere', 'gruyère', 'brie', 'camembert',
      'saint-nectaire', 'epoisses', 'époisses', 'reblochon', 'munster', 'morbier',
      'cantal', 'parmesan', 'parmigiano', 'fromage', 'cheese', 'cheddar', 'gouda', 'manchego', 'chaource',
      'formaggi', 'grana padano', 'fontina', 'taleggio', 'asiago', 'queso', 'gruyer',
      'mimolette'
    ])) {
      if (type == 'white' || type == 'blanc') {
        if (region.contains('jura') || region.contains('bourgogne') || grapes.contains('savagnin') || grapes.contains('chardonnay')) {
          score = 96 + (grapes.contains('savagnin') ? 2 : 0) + bottleDifferentiator;
          comment = 'L\'accord absolu du Comté ou Beaufort : les arômes de noisette, de beurre et la minéralité d\'un grand blanc de gastronomie créent une harmonie sublime.';
          serving = 'Servir à 11-13°C.';
        } else {
          score = 81 + bottleDifferentiator;
          comment = 'Les grands blancs secs sont les meilleurs alliés des fromages à pâte pressée pour révéler toute leur complexité.';
          serving = 'Servir à 10-12°C.';
        }
      } else if (type == 'red' || type == 'rouge') {
        if (region.contains('bourgogne') || grapes.contains('pinot noir') || region.contains('loire')) {
          score = 75 + bottleDifferentiator;
          comment = 'Un rouge délicat et peu tannique comme un Pinot Noir respecte le crémeux du Saint-Nectaire ou du Brie de Meaux.';
          serving = 'Servir à 15-16°C.';
        }
      }
    }

    // =========================================================================
    // 11. Mushrooms & Truffle
    // =========================================================================
    else if (_matchesKeywords(query, [
      'champignon', 'truffe', 'cepe', 'cèpe', 'morille', 'risotto', 'girolle',
      'sous-bois', 'pates aux truffes', 'pâtes aux truffes', 'omelette truffe',
      'mushroom', 'mushrooms', 'truffle', 'truffles', 'porcini', 'morels', 'chanterelles', 'setas', 'bolets', 'fungi',
      'funghi', 'fungo', 'tartufo', 'finferli', 'spugnole', 'trufa', 'boletus', 'colmenillas', 'rebozuelo'
    ])) {
      if (type == 'red' || type == 'rouge') {
        if (region.contains('bourgogne') || grapes.contains('pinot noir') || region.contains('piemont') || region.contains('barolo') || region.contains('italie')) {
          score = 98 + bottleDifferentiator;
          comment = 'Les notes de sous-bois et de truffe de ce rouge résonnent magistralement avec les champignons.';
          serving = 'Servir à 15-16°C en grand verre ballon.';
        } else if (region.contains('bordeaux') && isMature) {
          score = 93 + bottleDifferentiator;
          comment = 'Un grand Bordeaux parvenu à maturité déploie des notes de cèdre et de truffe noire idéales sur ce plat.';
          serving = 'Déboucher avec soin à 16-17°C.';
        } else {
          score = 79 + bottleDifferentiator;
          comment = 'L\'élégance du vin rouge accompagne bien la texture charnue des champignons.';
          serving = 'Servir chambré à 16°C.';
        }
      } else if (type == 'white' || type == 'blanc') {
        if (region.contains('jura') || region.contains('bourgogne') || appellation.contains('meursault') || grapes.contains('savagnin') || grapes.contains('chardonnay')) {
          score = 96 + bottleDifferentiator;
          comment = 'L\'onctuosité et les notes de fruits secs / noisette grillée d\'un grand blanc de gastronomie subliment un risotto aux morilles ou cèpes.';
          serving = 'Servir à 12-13°C.';
        }
      }
    }

    // =========================================================================
    // 11 bis. Œufs, quiches & tartes salées
    // =========================================================================
    // Avant les desserts : une tarte à l'oignon ou une tarte flambée ne sont pas des tartes
    // aux fruits. Les œufs à la neige, l'omelette norvégienne et la galette des rois, si.
    else if (_matchesKeywords(query, [
          'quiche', 'oeuf', 'egg', 'huevo', 'uovo', 'uova', 'omelette', 'omelet', 'tortilla', 'frittata',
          'flammekueche', 'flammkuchen', 'tarte flambee', 'tarte a l oignon', 'tarte salee', 'onion tart',
          'tarta de cebolla', 'tarta salada', 'torta salata', 'galette complete', 'galette bretonne',
          'galette de sarrasin', 'buckwheat galette', 'breton buckwheat', 'galette bretona', 'galette bretone',
          'meurette', 'benedict'
        ]) &&
        !_matchesKeywords(query, [
          'galette des rois', 'eggplant', 'oeufs a la neige', 'oeuf a la neige', 'ile flottante', 'norvegienne',
          'huevos nevados', 'uova di neve'
        ])) {
      final blanc = type == 'white' || type == 'blanc';
      final rose = type.contains('rose');
      final rouge = type == 'red' || type == 'rouge';
      final bulles = type.contains('champ') || type.contains('sparkling');
      final chardonnay = region.contains('bourgogne') || region.contains('jura') || grapes.any((g) => g.contains('chardonnay'));
      final rougeLeger = rouge && (region.contains('beaujolais') || grapes.any((g) => g.contains('gamay')));
      if (_matchesKeywords(query, ['meurette'])) {
        if (rouge && (region.contains('bourgogne') || grapes.any((g) => g.contains('pinot noir')))) {
          score = 95 + bottleDifferentiator;
          comment = 'Les œufs en meurette sont pochés dans le vin rouge de Bourgogne : un Pinot Noir de la même région en est l\'accord naturel.';
          serving = 'Servir à 15-16°C.';
        } else if (rougeLeger) {
          score = 86 + bottleDifferentiator;
          comment = 'Un rouge fruité et souple, aux tanins légers, pour la sauce au vin rouge et les lardons.';
          serving = 'Servir légèrement rafraîchi à 14-15°C.';
        }
      } else if (_matchesKeywords(query, ['flammekueche', 'flammkuchen', 'tarte flambee', 'oignon', 'onion', 'cebolla', 'cipoll'])) {
        if (blanc && region.contains('alsace') && !gewurz) {
          score = 94 + bottleDifferentiator;
          comment = 'L\'accord alsacien : un Riesling, un Sylvaner ou un Pinot Blanc, secs et vifs, pour la crème, les oignons et les lardons.';
          serving = 'Servir à 9-10°C.';
        } else if (blanc && !gewurz) {
          score = 84 + bottleDifferentiator;
          comment = 'Un blanc sec et vif tranche la crème et la douceur des oignons.';
          serving = 'Servir frais à 9-10°C.';
        } else if (rouge && grapes.any((g) => g.contains('pinot noir'))) {
          score = 80 + bottleDifferentiator;
          comment = 'Un Pinot Noir léger, servi frais, comme en Alsace.';
          serving = 'Servir légèrement rafraîchi à 14-15°C.';
        }
      } else if (_matchesKeywords(query, ['quiche'])) {
        if (blanc && region.contains('alsace') && !gewurz) {
          score = 94 + bottleDifferentiator;
          comment = 'La quiche lorraine trouve son vin en Alsace : un Riesling ou un Pinot Blanc, secs et ronds, répondent à la crème et aux lardons.';
          serving = 'Servir à 10°C.';
        } else if (blanc && chardonnay) {
          score = 88 + bottleDifferentiator;
          comment = 'Un Chardonnay rond et frais répond à la crème et à l\'œuf.';
          serving = 'Servir à 10-11°C.';
        } else if (bulles) {
          score = 84 + bottleDifferentiator;
          comment = 'Les bulles allègent la crème et l\'œuf.';
          serving = 'Servir à 8-10°C.';
        } else if (blanc && !gewurz) {
          score = 82 + bottleDifferentiator;
          comment = 'Un blanc sec et frais pour les œufs et les herbes.';
          serving = 'Servir frais à 9-10°C.';
        }
      } else if (_matchesKeywords(query, ['benedict', 'brunch'])) {
        if (bulles) {
          score = 92 + bottleDifferentiator;
          comment = 'Les bulles d\'un Champagne, l\'accord du brunch, allègent la sauce hollandaise et le jaune coulant.';
          serving = 'Servir à 8-10°C.';
        } else if (blanc && chardonnay) {
          score = 88 + bottleDifferentiator;
          comment = 'Un Chardonnay rond et frais répond à la sauce hollandaise.';
          serving = 'Servir à 10-11°C.';
        } else if (blanc && !gewurz) {
          score = 80 + bottleDifferentiator;
          comment = 'Un blanc sec et frais pour les œufs et les herbes.';
          serving = 'Servir frais à 9-10°C.';
        }
      } else if (_matchesKeywords(query, ['galette', 'buckwheat', 'sarrasin'])) {
        if (blanc && (region.contains('loire') || appellation.contains('muscadet'))) {
          final muscadet = appellation.contains('muscadet') || grapes.any((g) => g.contains('melon'));
          score = (muscadet ? 92 : 88) + bottleDifferentiator;
          comment = 'Un Muscadet ou un blanc de Loire, sec et salin, accompagne la galette de sarrasin comme en Bretagne.';
          serving = 'Servir frais à 9-10°C.';
        } else if (blanc && !gewurz) {
          score = 82 + bottleDifferentiator;
          comment = 'Un blanc sec et frais pour le sarrasin, le jambon et le fromage.';
          serving = 'Servir frais à 9-10°C.';
        } else if (rougeLeger) {
          score = 80 + bottleDifferentiator;
          comment = 'Un rouge léger et fruité, servi frais, pour le jambon et le fromage fondu.';
          serving = 'Servir légèrement rafraîchi à 14-15°C.';
        }
      } else if (_matchesKeywords(query, ['tortilla', 'frittata'])) {
        if (rose) {
          score = 88 + bottleDifferentiator;
          comment = 'Un rosé sec et fruité pour l\'œuf, la pomme de terre et l\'huile d\'olive.';
          serving = 'Servir frais à 8-10°C.';
        } else if (blanc && !gewurz) {
          score = 84 + bottleDifferentiator;
          comment = 'Un blanc sec et frais pour l\'œuf, la pomme de terre et l\'huile d\'olive.';
          serving = 'Servir frais à 9-10°C.';
        }
      } else {
        // Omelette, œufs brouillés ou mollets : un blanc frais, ou des bulles.
        final vifEtFrais = region.contains('loire') || appellation.contains('chablis') ||
            appellation.contains('sancerre') || grapes.any((g) => g.contains('sauvignon'));
        if (blanc && (vifEtFrais || chardonnay)) {
          score = 88 + bottleDifferentiator;
          comment = 'Un blanc sec et frais, à la manière d\'un Chablis ou d\'un Sauvignon, pour l\'œuf et les herbes.';
          serving = 'Servir frais à 9-10°C.';
        } else if (bulles) {
          score = 86 + bottleDifferentiator;
          comment = 'Les bulles allègent la crème et l\'œuf.';
          serving = 'Servir à 8-10°C.';
        } else if (blanc && !gewurz) {
          score = 82 + bottleDifferentiator;
          comment = 'Un blanc sec et frais pour les œufs et les herbes.';
          serving = 'Servir frais à 9-10°C.';
        } else if (rose) {
          score = 78 + bottleDifferentiator;
          comment = 'Un rosé sec et frais accompagne les œufs sans les écraser.';
          serving = 'Servir frais à 8-10°C.';
        }
      }
    }

    // =========================================================================
    // 12. Italian Pasta & Pizza
    // =========================================================================
    else if (_matchesKeywords(query, [
      'pizza', 'margherita', 'lasagne', 'lasagna', 'bolognaise', 'bolognese',
      'carbonara', 'vongole', 'amatriciana', 'carpaccio', 'burrata', 'mozzarella',
      'pesto', 'gnocchi', 'pasta', 'pâtes', 'spaghetti', 'tagliatelle', 'penne', 'ravioli',
      'ragu', 'pappardelle', 'tortellini', 'orecchiette', 'rigatoni', 'fettuccine', 'arancini', 'lasana'
    ])) {
      if (_matchesKeywords(query, ['vongole', 'pesto', 'burrata'])) {
        if (type == 'white' || type == 'blanc' || type == 'rose' || type == 'rosé') {
          score = 87 + bottleDifferentiator;
          comment = 'La fraîcheur vive d\'un blanc sec ou d\'un rosé méditerranéen équilibre l\'iode des palourdes ou le crémeux de la Burrata.';
          serving = 'Servir à 9-11°C.';
        }
      } else if (type == 'red' || type == 'rouge') {
        final italien = region.contains('ital') || region.contains('tosc') || region.contains('tusc') || region.contains('piem') ||
            region.contains('pied') || grapes.contains('sangiovese') || grapes.contains('nebbiolo') || grapes.contains('barbera');
        if (italien || region.contains('rhone') || region.contains('languedoc') || region.contains('provence')) {
          score = 89 + (italien ? 4 : 0) + bottleDifferentiator;
          comment = 'L\'acidité naturelle et les arômes de cerise et d\'herbes méditerranéennes coupent la richesse du fromage fondu et de la sauce tomate.';
          serving = 'Servir à 15-16°C.';
        } else {
          score = 77 + bottleDifferentiator;
          comment = 'Un vin rouge convivial et gourmand parfait pour les saveurs transalpines.';
          serving = 'Servir à 16°C.';
        }
      }
    }

    // =========================================================================
    // 13. French Terroir (Choucroute, Boudin noir, Andouillette, Baeckeoffe)
    // =========================================================================
    else if (!isSpicyDish && _matchesKeywords(query, [
      'choucroute', 'petit sale', 'petit salé', 'boudin', 'boudin noir', 'boudin blanc',
      'andouillette', 'baeckeoffe', 'tripes', 'poule au pot', 'sauerkraut',
      'crauti', 'sanguinaccio', 'trippa', 'lenticchie', 'cotechino', 'zampone', 'chucrut', 'morcilla', 'callos',
      'black pudding', 'pork belly', 'tripe', 'lentils', 'lentejas',
      'morteau', 'lentille', 'hachis', 'parmentier', 'potee'
    ])) {
      if (_matchesKeywords(query, ['choucroute', 'baeckeoffe', 'sauerkraut', 'chucrut', 'crauti'])) {
        if (region.contains('alsace') || grapes.contains('riesling') || grapes.contains('pinot blanc') || grapes.contains('sylvaner')) {
          score = 95 + bottleDifferentiator;
          comment = 'Accord alsacien traditionnel incontournable : la droiture tranchante du Riesling ou du Pinot Blanc nettoie les graisses de la charcuterie et du chou fermenté.';
          serving = 'Servir frais à 9-11°C.';
        }
      } else if (_matchesKeywords(query, ['boudin noir', 'andouillette', 'black pudding', 'morcilla', 'sanguinaccio'])) {
        if (type == 'red' || type == 'rouge') {
          if (region.contains('loire') || region.contains('beaujolais') || grapes.contains('gamay') || grapes.contains('cabernet franc')) {
            score = 89 + bottleDifferentiator;
            comment = 'La fraîcheur gouleyante et le fruit croquant du Gamay ou Cabernet Franc de Loire épousent à merveille le moelleux du boudin et des pommes.';
            serving = 'Servir frais à 14-15°C.';
          }
        }
      } else if (_matchesKeywords(query, [
            'morteau', 'saucisse', 'lentille', 'lentil', 'lenteja', 'lenticchi', 'petit sale', 'hachis', 'parmentier',
            'potee', 'poule au pot', 'salsiccia', 'salchicha', 'cotechino', 'zampone'
          ]) &&
          (type == 'red' || type == 'rouge' || ((type == 'white' || type == 'blanc') && (region.contains('alsace') || region.contains('jura')) && !gewurz))) {
        if (type == 'red' || type == 'rouge') {
          final gouleyant = region.contains('beaujolais') || region.contains('jura') || region.contains('loire') ||
              grapes.any((g) => g.contains('gamay') || g.contains('pinot noir') || g.contains('poulsard') || g.contains('trousseau') || g.contains('cabernet franc'));
          final gamayOuJura = region.contains('beaujolais') || region.contains('jura') || grapes.any((g) => g.contains('gamay'));
          score = (gamayOuJura ? 90 : gouleyant ? 86 : 78) + bottleDifferentiator;
          comment = gouleyant
              ? 'Un rouge fruité et gouleyant, à la manière d\'un Beaujolais ou d\'un rouge du Jura, pour la saucisse, les lentilles ou le hachis.'
              : 'Un rouge franc pour ce plat de terroir généreux.';
          serving = gouleyant ? 'Servir légèrement rafraîchi à 14-15°C.' : 'Servir à 16°C.';
        } else {
          score = 84 + bottleDifferentiator;
          comment = 'Un blanc sec et franc, d\'Alsace ou du Jura, tranche le gras de la charcuterie.';
          serving = 'Servir à 10°C.';
        }
      } else if (type == 'white' || type == 'blanc') {
        score = 76 + bottleDifferentiator;
        comment = 'Un blanc sec structuré apporte l\'acidité requise face aux plats traditionnels riches.';
        serving = 'Servir à 10°C.';
      }
    }

    // =========================================================================
    // 14. Spicy & Oriental (Couscous, Tajines, Curry, Butter Chicken)
    // =========================================================================
    else if (_matchesKeywords(query, [
      'couscous', 'tajine', 'curry', 'butter chicken', 'tikka masala', 'colombo',
      'rougail', 'chili', 'epice', 'épice', 'indien', 'oriental', 'harissa', 'tandoori',
      'spicy', 'curry',
      'speziat', 'piccante', 'indiano', 'picante', 'especiad', 'tagine', 'cuscus', 'madras',
      'pastilla', 'pastela', 'kefta', 'kofta', 'dahl', 'daal'
    ])) {
      if (grapes.contains('gewurztraminer') || region.contains('alsace') || grapes.contains('viognier')) {
        score = 89 + bottleDifferentiator;
        comment = 'Le fruit et la texture soyeuse de ce blanc aromatique domptent le piment et valorisent les currys et tajines.';
        serving = 'Servir frais à 9-11°C.';
      } else if (type == 'rose' || type == 'rosé') {
        score = 83 + (region.contains('rhone') || appellation.contains('tavel') ? 3 : 0) + bottleDifferentiator;
        comment = 'Un rosé apporte une fraîcheur bienvenue face aux plats très épicés et au couscous ; plus il est vineux (Tavel, Bandol), mieux il tient.';
        serving = 'Servir à 9-10°C.';
      } else if (type == 'red' || type == 'rouge') {
        if (region.contains('rhone') || region.contains('languedoc') || region.contains('provence') || grapes.contains('syrah') || grapes.contains('grenache')) {
          score = 79 + bottleDifferentiator;
          comment = 'Les tanins enrobés et les notes de garrigue et poivre noir du Sud complètent harmonieusement l\'agneau et les épices orientales.';
          serving = 'Servir à 16°C.';
        }
      }
    }

    // =========================================================================
    // 15. Asian Street Food & Wok (Canard laqué, Pad Thaï, Ramen, Bo Bun)
    // =========================================================================
    else if (_matchesKeywords(query, [
      'canard laque', 'canard laqué', 'pad thai', 'pad thaï', 'bo bun', 'ramen',
      'dim sum', 'gyoza', 'porc aigre-doux', 'wok', 'nem', 'asiatique', 'chinois',
      'coreen', 'peking duck', 'yakitori', 'teriyaki',
      'agrodolce', 'giapponese', 'cinese', 'vietnamita', 'thailandese', 'pechinese',
      'bibimbap'
    ])) {
      if (_matchesKeywords(query, ['canard laque', 'peking duck', 'pato laqueado', 'anatra laccata'])) {
        if (grapes.contains('pinot noir') || region.contains('bourgogne') || grapes.contains('gamay')) {
          score = 95 + bottleDifferentiator;
          comment = 'Accord sommelier exceptionnel : la douceur caramélisée de la sauce hoisin et la peau croustillante du canard s\'accordent divinement au fruit soyeux de ce rouge léger.';
          serving = 'Servir à 15-16°C.';
        } else if (grapes.contains('riesling') || region.contains('alsace')) {
          score = 91 + bottleDifferentiator;
          comment = 'Un blanc d\'Alsace, surtout avec une pointe de sucre résiduel, fait scintiller les épices douces et le laquage du canard.';
          serving = 'Servir à 10°C.';
        }
      } else if (type == 'white' || type == 'blanc') {
        if (grapes.contains('riesling') || grapes.contains('chenin') || region.contains('alsace') || region.contains('loire')) {
          score = 87 + bottleDifferentiator;
          comment = 'La minéralité ciselée et le fruit blanc éclatant répondent parfaitement aux herbes fraîches (coriandre, menthe), au gingembre et à la citronnelle.';
          serving = 'Servir à 9-10°C.';
        } else {
          score = 76 + bottleDifferentiator;
          comment = 'Un blanc sec et frais pour désaltérer sur la cuisine au wok.';
          serving = 'Servir à 9°C.';
        }
      } else if (type == 'rose' || type == 'rosé') {
        score = 77 + bottleDifferentiator;
        comment = 'Un rosé fruité et gouleyant apporte légèreté et gourmandise aux dim sums et nouilles sautées.';
        serving = 'Servir à 9°C.';
      }
    }

    // =========================================================================
    // 16. Tapas, Charcuterie & Aperitif (Pata Negra, Tapenade, Rillettes)
    // =========================================================================
    else if (_matchesKeywords(query, [
      'charcuterie', 'jambon', 'pata negra', 'tapenade', 'anchoiade', 'anchoïade',
      'gougere', 'gougère', 'tapas', 'pintxos', 'empanadas', 'aperitif', 'apéritif',
      'rillettes', 'saucisson', 'ham', 'pissaladiere',
      'salumi', 'prosciutto', 'affettati', 'salame', 'aperitivo', 'tagliere', 'crostini', 'bruschetta', 'jamon', 'embutidos'
    ])) {
      if (type.contains('champ') || type.contains('sparkling')) {
        score = 87 + bottleDifferentiator;
        comment = 'L\'apéritif par excellence : les bulles fines aiguisent l\'appétit et contrastent avec la texture fondante des gougères et charcuteries nobles.';
        serving = 'Servir frais à 8-9°C.';
      } else if (type == 'rose' || type == 'rosé') {
        score = 83 + bottleDifferentiator;
        comment = 'L\'âme de l\'apéritif estival : un rosé frais, floral et croquant sublime la tapenade et les tapas.';
        serving = 'Servir à 8-10°C.';
      } else if (type == 'red' || type == 'rouge') {
        if (region.contains('beaujolais') || region.contains('loire') || grapes.contains('gamay') || region.contains('espagne') || region.contains('ribera') || region.contains('rioja')) {
          score = 81 + bottleDifferentiator;
          comment = 'Un rouge digeste et fruité ou un beau vin espagnol pour mettre en valeur le gras noble du jambon Pata Negra et des rillettes.';
          serving = 'Servir à 14-16°C.';
        }
      }
    }

    // =========================================================================
    // 17. Desserts & Chocolate
    // =========================================================================
    else if (_matchesKeywords(query, [
      'dessert', 'chocolat', 'tarte', 'fruit', 'fraise', 'framboise', 'tiramisu',
      'creme brulee', 'crème brûlée', 'pomme', 'poire', 'fondant', 'moelleux chocolat',
      'souffle', 'soufflé', 'profiteroles', 'chocolate', 'cake', 'apple pie', 'crumble', 'brownie', 'cheesecake', 'pastry', 'tart', 'meringue',
      'cioccolat', 'crostata', 'torta', 'tortino', 'panna cotta', 'cannoli', 'semifreddo', 'gelato', 'dolce', 'postre', 'tarta',
      'mille-feuille', 'millefeuille', 'milhojas', 'millefoglie', 'paris-brest', 'pavlova', 'baba', 'crepe', 'oeufs a la neige', 'oeuf a la neige', 'ile flottante', 'floating island', 'huevos nevados', 'isla flotante', 'uova di neve', 'isola galleggiante', 'omelette norvegienne', 'baked alaska', 'galette des rois'
    ])) {
      if (_matchesKeywords(query, ['chocolat', 'cacao', 'cioccolat'])) {
        if (region.contains('banyuls') || region.contains('maury') || region.contains('porto') || region.contains('roussillon') || type.contains('fortified') || (type == 'red' && grapes.contains('grenache') && isMature)) {
          score = 95 + bottleDifferentiator;
          comment = 'Accord magique au sommet : les notes de cacao, cerise noire confite et pruneau d\'un Vin Doux Naturel ou Porto subliment le chocolat noir corsé.';
          serving = 'Servir à 14-16°C.';
        }
      } else {
        if (type.contains('dessert') || type.contains('moell') || type.contains('liquor') || type.contains('sauternes') || region.contains('sauternes') || region.contains('layon') || alsaceDoux || type.contains('sweet')) {
          score = 96 + bottleDifferentiator;
          comment = 'L\'onctuosité confite, les notes de miel, d\'abricot sec et de vanille épousent admirablement les tartes aux fruits, la Tatin et la crème brûlée.';
          serving = 'Servir frais à 8-10°C.';
        } else if (type.contains('champ') || type.contains('sparkling')) {
          score = 81 + bottleDifferentiator;
          comment = 'Les fines bulles apportent une conclusion festive et légère sur des desserts aux fruits frais ou fraises.';
          serving = 'Servir à 8-9°C.';
        }
      }
    }

    // Final score clamping
    score = score.clamp(0, 99);

    // Quality Gate: Drop anything below threshold (e.g. 60%)
    if (score < minScore) {
      return null;
    }

    final matchLevel = score >= 85
        ? FoodMatchLevel.ideal
        : (score >= 72 ? FoodMatchLevel.harmonious : FoodMatchLevel.gourmet);

    return FoodPairingMatch(
      bottle: bottle,
      score: score,
      matchLevel: matchLevel,
      sommelierComment: comment.isNotEmpty ? comment : _parDefaut,
      servingAdvice: serving,
    );
  }

  /// Sommelier advice for dish when cellar has no matching bottle
  static String getSommelierAdviceForDish(String dishQuery, [dynamic lang]) {
    final langCode = FoodPairingCategory._codeDeLangue(lang);
    String dire(String fr, String en, String es, String it, {String? ca, String? la}) => switch (langCode) {
          'fr' => fr,
          'es' => es,
          'it' => it,
          'ca' => ca ?? en,
          'la' => la ?? en,
          _ => en,
        };
    final query = _normalize(dishQuery);
    if (query.isEmpty) {
      return dire(
        'Indiquez un mets ou choisissez une suggestion ci-dessus pour découvrir les accords conseillés par le sommelier.',
        'Enter a dish or pick a suggestion above to discover pairings recommended by the sommelier.',
        'Indica un plato o elige una sugerencia arriba para descubrir los maridajes recomendados por el sumiller.',
        'Indica un piatto o scegli un suggerimento qui sopra per scoprire gli abbinamenti consigliati dal sommelier.',
        ca: 'Indica un plat o tria un suggeriment a dalt per descobrir els maridatges recomanats pel sommelier.',
        la: 'Indica cibum aut elige categoriam supra ad videndum consilia sommelier.',
      );
    }

    // Les familles du 19/10 (salades, soupes, légumes, œufs et tartes salées), avant les
    // viandes et les desserts, comme dans les accords.
    if (_matchesKeywords(query, ['salade', 'salad', 'ensalada', 'insalata', 'taboule', 'tabbouleh', 'tabule'])) {
      return dire(
        'Pour une salade, la vinaigrette décide : elle durcit les tanins des rouges. Préférez un blanc vif et sec (Sauvignon de Loire, Muscadet, Picpoul) ou un rosé de Provence ; un Sancerre pour le chèvre chaud, un rouge léger servi frais (Beaujolais) pour une salade lyonnaise.',
        'With a salad, the dressing decides: vinaigrette hardens red-wine tannins. Choose a crisp dry white (Loire Sauvignon, Muscadet, Picpoul) or a Provence rosé; a Sancerre with warm goat cheese, a light chilled red (Beaujolais) with a Lyonnaise salad.',
        'Con una ensalada manda la vinagreta: endurece los taninos de los tintos. Elija un blanco seco y vivo (Sauvignon del Loira, Muscadet, Picpoul) o un rosado de Provenza; un Sancerre con el queso de cabra caliente, un tinto ligero y fresco (Beaujolais) con una ensalada lionesa.',
        'Con un\'insalata decide il condimento: l\'aceto indurisce i tannini dei rossi. Scegli un bianco secco e vivace (Sauvignon della Loira, Muscadet, Picpoul) o un rosato di Provenza; un Sancerre con il caprino caldo, un rosso leggero servito fresco (Beaujolais) con un\'insalata lionese.',
      );
    }

    if (_matchesKeywords(query, [
          'soupe', 'soup', 'veloute', 'potage', 'bouillabaisse', 'bullabesa', 'bisque', 'gaspacho', 'gazpacho',
          'minestrone', 'garbure', 'pho', 'sopa', 'crema de', 'zuppa', 'vellutata'
        ]) &&
        !_matchesKeywords(query, ['champignon', 'cepe', 'morille', 'truffe', 'mushroom', 'truffle', 'porcini', 'funghi', 'setas', 'zuppa inglese'])) {
      return dire(
        'Pour une soupe, un vin frais et sans tanins : un rosé ou un blanc de Provence pour la bouillabaisse, un Chardonnay pour une bisque ou un velouté de courge, un blanc de Savoie pour la soupe à l\'oignon, un Fino pour le gaspacho.',
        'With a soup, choose a fresh wine without tannins: a Provence rosé or white with bouillabaisse, a Chardonnay with a bisque or a squash velouté, a Savoie white with onion soup, a Fino sherry with gazpacho.',
        'Con una sopa, un vino fresco y sin taninos: un rosado o un blanco de Provenza con la bullabesa, un Chardonnay con una bisque o una crema de calabaza, un blanco de Saboya con la sopa de cebolla, un Fino con el gazpacho.',
        'Con una zuppa, un vino fresco e senza tannini: un rosato o un bianco di Provenza con la bouillabaisse, uno Chardonnay con una bisque o una vellutata di zucca, un bianco della Savoia con la zuppa di cipolle, un Fino con il gazpacho.',
      );
    }

    if (_matchesKeywords(query, [
          'ratatouille', 'tian', 'legume', 'vegetable', 'verdura', 'verdure', 'vegetar', 'vegan', 'veggie',
          'aubergine', 'eggplant', 'berenjena', 'melanzan', 'parmigiana', 'courgette', 'falafel', 'houmous', 'hummus',
          'asperge', 'asparag', 'esparrago', 'butternut', 'courge', 'squash', 'dauphinois', 'tofu', 'quinoa'
        ]) &&
        !_matchesKeywords(query, [
          'agneau', 'lamb', 'boeuf', 'beef', 'poulet', 'chicken', 'pollo', 'poisson', 'fish', 'curry', 'tajine', 'couscous'
        ])) {
      return dire(
        'Pour les légumes et la cuisine végétarienne : un rosé de Provence ou un rouge du Sud souple (Grenache, Cinsault) pour les légumes du soleil, un Sauvignon ou un Muscat sec d\'Alsace pour les asperges, un Chardonnay pour un gratin.',
        'For vegetables and vegetarian dishes: a Provence rosé or a supple southern red (Grenache, Cinsault) with Mediterranean vegetables, a Sauvignon or a dry Alsace Muscat with asparagus, a Chardonnay with a gratin.',
        'Para verduras y cocina vegetariana: un rosado de Provenza o un tinto del sur suave (Garnacha, Cinsault) para las verduras mediterráneas, un Sauvignon o un Muscat seco de Alsacia para los espárragos, un Chardonnay para un gratinado.',
        'Per verdure e cucina vegetariana: un rosato di Provenza o un rosso del Sud morbido (Grenache, Cinsault) per le verdure mediterranee, un Sauvignon o un Moscato secco d\'Alsazia per gli asparagi, uno Chardonnay per un gratin.',
      );
    }

    if (_matchesKeywords(query, [
          'quiche', 'oeuf', 'egg', 'huevo', 'uovo', 'uova', 'omelette', 'tortilla', 'flammekueche', 'flammkuchen',
          'tarte flambee', 'tarte a l oignon', 'tarte salee', 'onion tart', 'tarta de cebolla', 'torta salata',
          'galette complete', 'galette bretonne', 'meurette', 'benedict'
        ]) &&
        !_matchesKeywords(query, ['galette des rois', 'eggplant', 'oeufs a la neige', 'ile flottante', 'norvegienne', 'huevos nevados', 'uova di neve'])) {
      return dire(
        'Pour les œufs et les tartes salées : un blanc d\'Alsace (Riesling, Pinot Blanc) pour la quiche et la flammekueche, un Champagne pour les œufs Bénédicte, un Muscadet pour la galette de sarrasin, un Bourgogne rouge pour les œufs en meurette.',
        'For eggs and savoury tarts: an Alsace white (Riesling, Pinot Blanc) with quiche and tarte flambée, a Champagne with eggs Benedict, a Muscadet with a buckwheat galette, a red Burgundy with eggs en meurette.',
        'Para huevos y tartas saladas: un blanco de Alsacia (Riesling, Pinot Blanc) para la quiche y la flammekueche, un Champagne para los huevos Benedict, un Muscadet para la galette de trigo sarraceno, un Borgoña tinto para los huevos en salsa meurette.',
        'Per uova e torte salate: un bianco d\'Alsazia (Riesling, Pinot Blanc) per la quiche e la flammekueche, uno Champagne per le uova alla Benedict, un Muscadet per la galette di grano saraceno, un Borgogna rosso per le uova in meurette.',
      );
    }

    final isLambQuery = _matchesKeywords(query, ['agneau', 'lamb', 'gigot', 'cordero', 'xai', 'agnus', 'mouton', 'mutton', 'agnello', 'abbacchio']);
    final hasThymeOrHerbs = _matchesKeywords(query, ['thym', 'thyme', 'tomillo', 'farigola', 'rosemary', 'romarin', 'garrigue', 'herbes', 'timo', 'rosmarino', 'erbe']);

    if (isLambQuery) {
      const ca = 'Per a una cuixa de xai rostida amb farigola, trieu un vi negre noble i estructurat: un gran Bordeus (Cabernet Sauvignon), un Roine (Syrah) o un Priorat.';
      const la = 'Pro crure agnino thymo condito, elige vinum rubrum nobile: Burdigalense (Cabernet Sauvignon) aut Rhodaniacum generosum (Syrah).';
      if (hasThymeOrHerbs) {
        return dire(
          'Pour un gigot d\'agneau rôti au thym ou aux herbes, orientez-vous vers un grand rouge structuré aux tanins nobles et aux accents de garrigue : un grand Pauillac ou Médoc (Cabernet Sauvignon), un Rhône solaire (Syrah d\'Hermitage, Châteauneuf-du-Pape) ou un Bandol au Mourvèdre.',
          'For a roast leg of lamb with thyme or herbs, choose a structured red with noble tannins and garrigue notes: a classic Pauillac or Médoc (Cabernet Sauvignon), a bold Rhône (Syrah from Hermitage, Châteauneuf-du-Pape), or a Provençal Bandol (Mourvèdre).',
          'Para una pierna de cordero asada al tomillo, elija un tinto estructurado con taninos nobles y notas silvestres: un gran Burdeos (Cabernet Sauvignon), un Ródano (Syrah) o un vino de Rioja / Ribera del Duero.',
          'Per un cosciotto d\'agnello arrosto al timo o alle erbe, scegli un grande rosso strutturato dai tannini nobili e dai sentori di macchia mediterranea: un Pauillac o un Médoc (Cabernet Sauvignon), un Rodano solare (Syrah dell\'Hermitage, Châteauneuf-du-Pape) o un Bandol (Mourvèdre).',
          ca: ca,
          la: la,
        );
      }
      return dire(
        'Pour un agneau rôti ou des côtelettes, privilégiez un vin rouge charpenté aux tanins fondus : un grand Bordeaux (Médoc, Pauillac), un Rhône (Syrah) ou un beau vin espagnol (Rioja).',
        'For roasted lamb or lamb chops, choose a structured red wine with velvety tannins: a noble Bordeaux (Pauillac, Saint-Julien), a Northern Rhône Syrah, or a Spanish Rioja Gran Reserva.',
        'Para cordero asado o chuletillas, prefiera un vino tinto noble y estructurado: un Burdeos, un Ródano (Syrah) o un Tempranillo de Rioja / Ribera.',
        'Per un agnello arrosto o delle costolette, preferisci un rosso strutturato dai tannini setosi: un grande Bordeaux (Médoc, Pauillac), un Rodano (Syrah) o un Rioja.',
        ca: ca,
        la: la,
      );
    }

    if (_matchesKeywords(query, ['huitre', 'huître', 'fruits de mer', 'coquillage', 'crustace', 'crustacé', 'crevette', 'homard', 'saint-jacques', 'oyster', 'seafood', 'lobster', 'scallop',
        'ostras', 'marisco', 'gambas', 'vieiras', 'ostriche', 'frutti di mare', 'crostacei', 'gamberi', 'astice', 'capesante', 'cozze', 'vongole', 'scampi'])) {
      return dire(
        'Pour sublimer des huîtres ou fruits de mer, privilégiez un vin blanc très sec, minéral et salin : un Chablis, un Muscadet Sèvre-et-Maine sur lie, ou un Champagne brut.',
        'To enhance oysters or fresh seafood, choose a very dry, mineral, and saline white wine: a Chablis Premier Cru, a Muscadet Sèvre-et-Maine sur lie, or a crisp Brut Champagne.',
        'Para realzar ostras o mariscos, elija un blanco muy seco, mineral y salino: un Chablis, un Muscadet sur lie o un Champagne brut.',
        'Per esaltare ostriche o frutti di mare, scegli un bianco molto secco, minerale e sapido: uno Chablis, un Muscadet Sèvre-et-Maine sur lie o uno Champagne brut.',
      );
    }

    if (_matchesKeywords(query, ['raclette', 'fondue', 'tartiflette', 'mont d\'or', 'reblochonade', 'fromage fondu', 'cheese fondue', 'fonduta', 'formaggio fuso']) &&
        !_matchesKeywords(query, ['bourguignonne'])) {
      return dire(
        'Pour une raclette ou une fondue, l\'accord idéal est un vin blanc sec et vif des Alpes (Savoie Apremont, Chignin, ou Côtes du Jura) qui tranchera agréablement avec le gras du fromage fondu.',
        'For raclette or fondue, the ideal match is a crisp, vibrant alpine white wine (Savoie Apremont, Chignin, or Côtes du Jura) that cuts through the melted cheese richness.',
        'Para una raclette o fondue, el maridaje ideal es un blanco seco y fresco de los Alpes (Savoie Apremont, Chignin o Jura).',
        'Per una raclette o una fonduta, l\'abbinamento ideale è un bianco secco e vivace delle Alpi (Savoie Apremont, Chignin o Côtes du Jura), che taglia il grasso del formaggio fuso.',
      );
    }

    if (_matchesKeywords(query, ['boeuf', 'bœuf', 'cote de boeuf', 'entrecote', 'grillade', 'steak', 'barbecue', 'bbq', 'beef', 'prime rib',
        'buey', 'chuleton', 'entrecot', 'manzo', 'costata', 'bistecca', 'fiorentina', 'tagliata'])) {
      return dire(
        'Pour une belle viande rouge ou grillade, orientez-vous vers un rouge charpenté et structuré aux tanins mûrs : un grand Bordeaux (Médoc, Saint-Émilion), un Rhône (Syrah), ou un vin de la Rioja.',
        'For prime beef or grilled meats, look for a structured red wine with ripe tannins: a noble Bordeaux (Médoc, Saint-Émilion), a Rhône Syrah, or a Spanish Rioja / Ribera del Duero.',
        'Para carnes rojas y parrilla, busque un tinto estructurado con taninos maduros: un gran Burdeos, un Ródano (Syrah) o un Rioja.',
        'Per una bella carne rossa o una grigliata, punta su un rosso strutturato dai tannini maturi: un grande Bordeaux (Médoc, Saint-Émilion), un Rodano (Syrah) o un Rioja.',
      );
    }

    if (_matchesKeywords(query, ['bourguignon', 'daube', 'gibier', 'sanglier', 'chevreuil', 'civet', 'cassoulet', 'ragout', 'stew', 'venison',
        'guiso', 'estofado', 'jabali', 'venado', 'caza', 'stufato', 'brasato', 'spezzatino', 'cinghiale', 'capriolo', 'cervo', 'lepre', 'selvaggina'])) {
      return dire(
        'Pour un plat mijoté ou du gibier, cherchez un rouge de caractère patiné par les années : un grand Bourgogne Pinot Noir, un Cahors tannique, ou un Châteauneuf-du-Pape.',
        'For slow-cooked stews or venison, select a characterful red aged to perfection: a mature Burgundy Pinot Noir, a tannic Cahors, or a Châteauneuf-du-Pape.',
        'Para un guiso o caza, busque un tinto con carácter y algunos años: un gran Borgoña Pinot Noir, un Cahors tánico o un Châteauneuf-du-Pape.',
        'Per uno stufato o della selvaggina, cerca un rosso di carattere affinato dagli anni: un grande Borgogna Pinot Noir, un Cahors tannico o uno Châteauneuf-du-Pape.',
      );
    }

    if (_matchesKeywords(query, ['sole', 'bar', 'turbot', 'cabillaud', 'saint-pierre', 'dorade', 'beurre blanc', 'poisson', 'fish', 'sea bass',
        'pescado', 'lubina', 'bacalao', 'lenguado', 'dorada', 'pesce', 'branzino', 'spigola', 'rombo', 'sogliola', 'orata', 'merluzzo', 'trota'])) {
      return dire(
        'Pour un poisson délicat, l\'excellence réside dans un grand vin blanc ciselé : un Chablis Premier Cru, un Meursault élégant ou un Sancerre blanc.',
        'For delicate white fish, excellence lies in a chiselled white wine: a Chablis Premier Cru, an elegant Meursault, or a mineral Sancerre blanc.',
        'Para un pescado delicado, la excelencia está en un gran blanco cincelado: un Chablis Premier Cru, un Meursault elegante o un Sancerre blanco.',
        'Per un pesce delicato, l\'eccellenza sta in un grande bianco cesellato: uno Chablis Premier Cru, un Meursault elegante o un Sancerre bianco.',
      );
    }

    if (_matchesKeywords(query, ['saumon', 'thon', 'sushi', 'sashimi', 'ceviche', 'tataki', 'salmon', 'tuna', 'atun', 'salmone', 'tonno', 'sgombro'])) {
      return dire(
        'Pour du saumon, du thon ou des sushis, préférez un blanc sec minéral (Riesling, Chablis), un rosé vineux de Provence/Bandol, ou un Pinot Noir très souple.',
        'For salmon, tuna or sushi, prefer a mineral dry white (Riesling, Chablis), a gastronomic Provence rosé, or a silky, chilled Pinot Noir.',
        'Para salmón, atún o sushi, prefiera un blanco seco mineral (Riesling, Chablis), un rosado gastronómico de Provenza o Bandol, o un Pinot Noir muy ligero.',
        'Per salmone, tonno o sushi, preferisci un bianco secco minerale (Riesling, Chablis), un rosato gastronomico della Provenza o di Bandol, o un Pinot Noir molto morbido.',
      );
    }

    if (_matchesKeywords(query, ['chevre', 'chèvre', 'crottin', 'chavignol', 'sainte-maure', 'valençay', 'goat cheese', 'queso de cabra', 'caprino', 'formaggio di capra'])) {
      return dire(
        'L\'accord magistral avec les fromages de chèvre est un Sauvignon blanc de Loire vif et parfumé : Sancerre, Pouilly-Fumé ou Menetou-Salon.',
        'The quintessential pairing with goat cheeses is a vibrant Loire Sauvignon Blanc: Sancerre, Pouilly-Fumé, or Menetou-Salon.',
        'El maridaje magistral con los quesos de cabra es un Sauvignon Blanc del Loira, vivo y perfumado: Sancerre, Pouilly-Fumé o Menetou-Salon.',
        'L\'abbinamento magistrale con i formaggi di capra è un Sauvignon Blanc della Loira, vivace e profumato: Sancerre, Pouilly-Fumé o Menetou-Salon.',
      );
    }

    if (_matchesKeywords(query, ['comte', 'comté', 'beaufort', 'gruyere', 'saint-nectaire', 'cantal', 'fromage', 'cheese', 'queso', 'formaggi', 'parmigiano', 'grana padano'])) {
      return dire(
        'Pour des fromages affinés à pâte pressée comme le Comté ou le Beaufort, privilégiez un grand blanc de caractère (Jura Savagnin, Chardonnay de Bourgogne).',
        'For aged pressed cheeses such as Comté or Beaufort, choose a gastronomic white of great depth (Jura Savagnin, Burgundy Chardonnay).',
        'Para quesos curados de pasta prensada como el Comté o el Beaufort, prefiera un gran blanco con carácter (Savagnin del Jura, Chardonnay de Borgoña).',
        'Per formaggi stagionati a pasta pressata come il Comté o il Beaufort, preferisci un grande bianco di carattere (Savagnin del Jura, Chardonnay di Borgogna).',
      );
    }

    if (_matchesKeywords(query, ['champignon', 'truffe', 'cepe', 'morille', 'risotto', 'mushroom', 'truffle', 'setas', 'trufa', 'boletus', 'funghi', 'fungo', 'tartufo', 'porcini'])) {
      return dire(
        'Pour les champignons et la truffe, misez sur un rouge aux arômes de sous-bois et tertiaires (vieux Bourgogne Pinot Noir, Barolo italien) ou un grand blanc beurré.',
        'For wild mushrooms and black truffles, opt for a red wine with tertiary undergrowth aromas (mature Burgundy Pinot Noir, Piedmontese Barolo) or a rich buttery white.',
        'Para setas y trufa, apueste por un tinto con aromas terciarios de sotobosque (un Borgoña Pinot Noir maduro, un Barolo) o un gran blanco mantecoso.',
        'Per funghi e tartufo, punta su un rosso dai profumi terziari di sottobosco (un Borgogna Pinot Noir maturo, un Barolo) o un grande bianco burroso.',
      );
    }

    if (_matchesKeywords(query, ['foie gras', 'fegato grasso'])) {
      return dire(
        'Pour le foie gras, l\'accord noble traditionnel est un liquoreux onctueux (Sauternes, Monbazillac) ou un Champagne blanc de blancs vif pour trancher avec le gras.',
        'For foie gras, the classic noble pairing is a luscious sweet wine (Sauternes, Monbazillac), or a lively blanc de blancs Champagne to cut through the richness.',
        'Para el foie gras, el maridaje noble y tradicional es un vino dulce untuoso (Sauternes, Monbazillac) o un Champagne blanc de blancs vivo que corte la grasa.',
        'Per il foie gras, l\'abbinamento nobile e tradizionale è un vino dolce untuoso (Sauternes, Monbazillac) o uno Champagne blanc de blancs vivace che ne tagli il grasso.',
      );
    }

    if (_matchesKeywords(query, ['chocolat', 'cacao', 'chocolate', 'cioccolat'])) {
      return dire(
        'Face à l\'amertume du chocolat noir, évitez les vins secs. Privilégiez impérativement un Vin Doux Naturel rouge (Banyuls, Maury) ou un Porto.',
        'With dark chocolate, avoid dry wines. Pair exclusively with a fortified sweet red wine (Banyuls, Maury) or a vintage Port.',
        'Con chocolate negro, evite los vinos secos. Elija un vino dulce natural tinto (Banyuls, Maury) o un Oporto.',
        'Con il cioccolato fondente, evita i vini secchi. Scegli un vino dolce naturale rosso (Banyuls, Maury) o un Porto.',
      );
    }

    if (_matchesKeywords(query, ['dessert', 'tarte', 'fruit', 'fraise', 'tiramisu', 'creme brulee', 'postre', 'tarta', 'dolce', 'torta', 'crostata', 'frutta']) &&
        !_matchesKeywords(query, ['tartar'])) {
      return dire(
        'Pour un dessert aux fruits ou une tarte, préférez un vin blanc moelleux (Coteaux du Layon, Sauternes) ou un Champagne demi-sec/rosé.',
        'For a fruit dessert or a tart, choose a sweet white wine (Coteaux du Layon, Sauternes) or a demi-sec or rosé Champagne.',
        'Para un postre de frutas o una tarta, prefiera un blanco dulce (Coteaux du Layon, Sauternes) o un Champagne demi-sec o rosado.',
        'Per un dessert alla frutta o una crostata, preferisci un bianco dolce (Coteaux du Layon, Sauternes) o uno Champagne demi-sec o rosé.',
      );
    }

    if (_matchesKeywords(query, ['couscous', 'tajine', 'curry', 'epice', 'épice', 'indien', 'spicy', 'picante', 'especiad', 'speziat', 'piccante', 'indiano'])) {
      return dire(
        'Pour des plats épicés ou orientaux, choisissez un vin blanc aromatique (Gewurztraminer d\'Alsace, Viognier) ou un rosé charpenté de Tavel.',
        'For spicy or North African dishes, choose an aromatic white (Alsace Gewurztraminer, Viognier) or a full-bodied Tavel rosé.',
        'Para platos especiados u orientales, elija un blanco aromático (Gewurztraminer de Alsacia, Viognier) o un rosado con cuerpo de Tavel.',
        'Per piatti speziati o orientali, scegli un bianco aromatico (Gewürztraminer d\'Alsazia, Viognier) o un rosato strutturato di Tavel.',
      );
    }

    if (_matchesKeywords(query, ['pizza', 'pasta', 'lasagne', 'lasagna', 'bolognaise', 'bolognese', 'spaghetti', 'ragu'])) {
      return dire(
        'Pour les pâtes et pizzas, un vin rouge fruité et digeste d\'Italie (Chianti, Sangiovese) ou des Côtes-du-Rhône fera merveille.',
        'For pasta and pizza, a fruity, easy-drinking Italian red (Chianti, Sangiovese) or a Côtes-du-Rhône works wonders.',
        'Para pasta y pizza, un tinto italiano afrutado y fácil de beber (Chianti, Sangiovese) o un Côtes-du-Rhône será perfecto.',
        'Per pasta e pizza, un rosso italiano fruttato e beverino (Chianti, Sangiovese) o un Côtes-du-Rhône farà meraviglie.',
      );
    }

    return dire(
      'Pour ce mets, préférez un vin harmonieux et adapté au profil de cuisson plutôt qu\'un flacon dont les tanins ou l\'acidité entreraient en conflit avec le plat.',
      'For this dish, prefer a harmonious wine tailored to the cooking style rather than a bottle whose tannins or acidity would conflict with the meal.',
      'Para este plato, prefiera un vino armonioso y adaptado al tipo de cocción antes que una botella cuyos taninos o acidez entren en conflicto con la comida.',
      'Per questo piatto, preferisci un vino armonioso e adatto alla cottura, piuttosto che una bottiglia i cui tannini o la cui acidità entrerebbero in conflitto con il piatto.',
      ca: 'Per a aquest plat, preferiu un vi harmoniós i adaptat al tipus de cocció abans que una ampolla amb tanins o acidesa en conflicte.',
      la: 'Pro hoc cibo, vinum consonum et aptum praefer potius quam lagenam cuius tannina aut aciditas pugnent.',
    );
  }
  static bool _matchesKeywords(String query, List<String> keywords) {
    // Au début d'un mot : « lamb » n'est pas dans « flambées », ni « ham » dans « champignons ».
    final mots = ' $query';
    for (final kw in keywords) {
      if (mots.contains(' ${_normalize(kw)}')) return true;
    }
    return false;
  }

  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâäá]'), 'a')
        .replaceAll(RegExp(r'[îïíì]'), 'i')
        .replaceAll(RegExp(r'[ôöóò]'), 'o')
        .replaceAll(RegExp(r'[ûüùú]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[œ]'), 'oe')
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .trim();
  }
}
