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
  };

  /// Les plats d'exemple hors du français ([sampleDishes]). Une langue absente : l'anglais.
  static const Map<String, Map<String, List<String>>> _plats = {
    'red_meat': {
      'en': ['Grilled Prime Rib', 'Ribeye steak', 'Duck breast', 'Tournedos Rossini', 'Beef Tartare', 'Roast leg of lamb with thyme', 'BBQ Picanha', 'Flank steak with shallots'],
      'es': ['Chuletón de buey a la brasa', 'Entrecot', 'Magret de pato', 'Tournedos Rossini', 'Tartar de buey', 'Pierna de cordero al tomillo', 'Picanha a la barbacoa', 'Bavette con chalotas'],
      'it': ['Costata di manzo alla griglia', 'Entrecôte al prezzemolo', 'Petto d\'anatra', 'Tournedos Rossini', 'Tartare di manzo', 'Cosciotto d\'agnello al timo', 'Picanha al barbecue', 'Bavetta allo scalogno'],
      'ca': ['Mitjana de bou a la brasa', 'Entrecot', 'Magret d\'ànec', 'Tournedos Rossini', 'Tàrtar de vedella', 'Cuixa de xai amb farigola', 'Picanha a la barbacoa', 'Bavette amb escalunyes'],
      'la': ['Costa bubula assa', 'Entrecot', 'Magret anatis', 'Tournedos Rossini', 'Tartare bubulum', 'Crus agninum thymo conditum', 'Assatura Picanha', 'Bavette cepis condita'],
    },
    'game_stew': {
      'en': ['Beef Bourguignon', 'Provençal beef stew', 'Wild boar stew', 'Hare à la Royale', 'Venison with lingonberries', 'Pot-au-feu', 'Flemish carbonnade', 'Hungarian Goulash'],
      'es': ['Ternera a la borgoñona', 'Estofado provenzal', 'Civet de jabalí', 'Liebre a la royale', 'Venado con arándanos', 'Pot-au-feu', 'Carbonada flamenca', 'Gulash húngaro'],
      'it': ['Manzo alla borgognona', 'Stufato alla provenzale', 'Civet di cinghiale', 'Lepre alla royale', 'Capriolo ai mirtilli rossi', 'Pot-au-feu', 'Carbonade fiamminga', 'Gulasch ungherese'],
      'ca': ['Vedella a la borgonyona', 'Guisat provençal', 'Civet de senglar', 'Llebre a la royale', 'Cérvol amb nabius', 'Pot-au-feu', 'Carbonada flamenca', 'Gulaix hongarès'],
      'la': ['Bubula Burgundica', 'Daube Provincialis', 'Aper conditus', 'Lepus regalis', 'Cervina vaccinium', 'Pot-au-feu', 'Carbonnade Flandrica', 'Goulash Hungaricum'],
    },
    'poultry_veal': {
      'en': ['Roast farm chicken', 'Veal blanquette', 'Capon with chestnuts', 'Veal roast with morels', 'Veal Milanese', 'Guinea fowl with herbs', 'Duck à l\'orange', 'Coq au vin'],
      'es': ['Pollo asado de granja', 'Blanqueta de ternera', 'Capón con castañas', 'Ternera lechal con colmenillas', 'Milanesa de ternera', 'Pintada con hierbas', 'Pato a la naranja', 'Gallo al vino (Coq au vin)'],
      'it': ['Pollo ruspante arrosto', 'Blanquette di vitello', 'Cappone alle castagne', 'Arrosto di vitello alle spugnole', 'Cotoletta alla milanese', 'Faraona alle erbe', 'Anatra all\'arancia', 'Coq au vin'],
      'ca': ['Pollastre rostit de pagès', 'Blanqueta de vedella', 'Capó amb castanyes', 'Vedella amb múrgoles', 'Milanesa de vedella', 'Pintada amb herbes', 'Ànec a la taronja', 'Gall al vi (Coq au vin)'],
      'la': ['Pullus rusticus assus', 'Vitulina alba', 'Capo castaneis', 'Vitulina morchellis', 'Escalopa Mediolanensis', 'Gallina Numidica', 'Anas aurantio condita', 'Gallus vino coctus'],
    },
    'delicate_fish': {
      'en': ['Sole meunière', 'Baked sea bass', 'Turbot in white butter sauce', 'Steamed cod loin', 'Pan-seared John Dory', 'Grilled sea bream', 'Monkfish armoricaine', 'Trout with almonds'],
      'es': ['Lenguado meunière', 'Lubina al horno', 'Rodaballo con mantequilla blanca', 'Lomo de bacalao al vapor', 'San Pedro a la plancha', 'Dorada a la plancha', 'Rape a la armoricana', 'Trucha a la almendra'],
      'it': ['Sogliola alla mugnaia', 'Branzino al forno', 'Rombo al burro bianco', 'Filetto di merluzzo al vapore', 'Pesce San Pietro in padella', 'Orata alla griglia', 'Rana pescatrice all\'armoricana', 'Trota alle mandorle'],
      'ca': ['Llenguado meunière', 'Llobarro al forn', 'Rèmol amb mantega blanca', 'Llom de bacallà al vapor', 'Sant Pere a la planxa', 'Orada a la graella', 'Rap a l\'armoricana', 'Truita amb ametlles'],
      'la': ['Solea meuniere', 'Lupus marinus assus', 'Turbot butyro albo', 'Asellus vaporatus', 'Zeus faber frictus', 'Aurata assa', 'Lophius Armoricus', 'Trutta amygdalis'],
    },
    'fatty_fish_sushi': {
      'en': ['Grilled salmon', 'Bluefin tuna tataki', 'Assorted sushi & sashimi', 'Peruvian ceviche', 'Salmon tartare with avocado', 'Grilled mackerel', 'Poké bowl', 'Eel teriyaki'],
      'es': ['Salmón a la plancha', 'Tataki de atún rojo', 'Sushi y sashimi variados', 'Ceviche peruano', 'Tartar de salmón y aguacate', 'Caballa a la parrilla', 'Poké bowl', 'Anguila teriyaki'],
      'it': ['Salmone alla griglia', 'Tataki di tonno rosso', 'Sushi e sashimi misti', 'Ceviche peruviano', 'Tartare di salmone e avocado', 'Sgombro alla griglia', 'Poke bowl', 'Anguilla teriyaki'],
      'ca': ['Salmó a la planxa', 'Tataki de tonyina vermella', 'Sushi i sashimi variats', 'Ceviche peruà', 'Tàrtar de salmó i alvocat', 'Seitó a la graella', 'Poké bowl', 'Anguila teriyaki'],
      'la': ['Salmo assus', 'Tataki thunni rubri', 'Sushi & sashimi varia', 'Ceviche Peruvianum', 'Tartare salmonis', 'Scomber assus', 'Poke bowl', 'Anguilla teriyaki'],
    },
    'seafood_shellfish': {
      'en': ['Fine Brittany oysters', 'Pan-seared sea scallops', 'Blue lobster with butter', 'Roasted Dublin Bay prawns', 'Garlic butter razor clams', 'Moules marinières', 'Seafood platter', 'Spider crab'],
      'es': ['Ostras de Bretaña', 'Vieiras a la plancha', 'Bogavante con mantequilla', 'Cigalas asadas', 'Navajas al ajillo', 'Mejillones a la marinera', 'Bandeja de marisco', 'Centollo'],
      'it': ['Ostriche di Bretagna', 'Capesante scottate', 'Astice al burro', 'Scampi arrosto', 'Cannolicchi aglio e burro', 'Cozze alla marinara', 'Plateau di frutti di mare', 'Grancevola'],
      'ca': ['Ostres de Bretanya', 'Vieires a la planxa', 'Llamàntol amb mantega', 'Escamarlans rostits', 'Navalles a l\'all', 'Musclos a la marinera', 'Plat de marisc', 'Cranc'],
      'la': ['Ostreae Armoricae', 'Pectines fricti', 'Astacus butyro', 'Nephrops assus', 'Solenes allio', 'Mytili marinarii', 'Fructus marini varii', 'Maja squinado'],
    },
    'goat_sheep_cheese': {
      'en': ['Warm Chavignol goat cheese', 'Sainte-Maure-de-Touraine', 'Rocamadour with honey', 'Valençay pyramid', 'Selles-sur-Cher', 'Artisan sheep cheese', 'Ossau-Iraty with cherry jam', 'Greek feta'],
      'es': ['Queso de cabra Chavignol caliente', 'Sainte-Maure-de-Touraine', 'Rocamadour con miel', 'Pirámide de Valençay', 'Selles-sur-Cher', 'Queso artesano de oveja', 'Ossau-Iraty con mermelada', 'Feta griega'],
      'it': ['Crottin de Chavignol caldo', 'Sainte-Maure-de-Touraine', 'Rocamadour al miele', 'Piramide di Valençay', 'Selles-sur-Cher', 'Pecorino artigianale', 'Ossau-Iraty con confettura di ciliegie', 'Feta greca'],
      'ca': ['Formatge de cabra Chavignol calent', 'Sainte-Maure-de-Touraine', 'Rocamadour amb mel', 'Piràmide de Valençay', 'Selles-sur-Cher', 'Formatge artesanal d\'ovella', 'Ossau-Iraty amb melmelada', 'Feta grega'],
      'la': ['Caseus caprinus Chavignol', 'Sainte-Maure-de-Touraine', 'Rocamadour melle', 'Valençay', 'Selles-sur-Cher', 'Caseus ovinus', 'Ossau-Iraty cerasis', 'Caseus Graecus Feta'],
    },
    'cow_pressed_cheese': {
      'en': ['Comté aged 24 months', 'Beaufort d\'alpage', 'Aged Parmigiano Reggiano', 'Farmhouse Cantal', 'Swiss Gruyère reserve', 'Saint-Nectaire fermier', 'Aged Cheddar', 'Manchego curado'],
      'es': ['Comté curado 24 meses', 'Beaufort de pasto alpino', 'Parmesano curado', 'Cantal de granja', 'Gruyer suizo reserva', 'Saint-Nectaire artesano', 'Cheddar curado', 'Manchego curado'],
      'it': ['Comté stagionato 24 mesi', 'Beaufort d\'alpeggio', 'Parmigiano Reggiano stravecchio', 'Cantal di fattoria', 'Gruyère svizzero riserva', 'Saint-Nectaire fermier', 'Cheddar stagionato', 'Manchego curado'],
      'ca': ['Comté curat 24 mesos', 'Beaufort d\'alta muntanya', 'Parmesà curat', 'Cantal de granja', 'Gruyère suís reserva', 'Saint-Nectaire artesanal', 'Cheddar curat', 'Manxego curat'],
      'la': ['Caseus Comté 24 mensium', 'Beaufort alpinus', 'Parmigiano Reggiano vetustum', 'Cantal rusticum', 'Gruyere Helvetium', 'Saint-Nectaire rusticum', 'Cheddar vetustum', 'Manchego curatum'],
    },
    'winter_melted_cheese': {
      'en': ['Traditional Savoyard raclette', 'Swiss cheese fondue', 'Tartiflette with Reblochon', 'Mont d\'Or chaud with potatoes', 'Croziflette with bacon', 'Aligot with Aveyron sausage', 'Fondue bourguignonne'],
      'es': ['Raclette saboyana tradicional', 'Fondue de quesos suizos', 'Tartiflette con Reblochon', 'Mont d\'Or caliente con patatas', 'Croziflette con panceta', 'Aligot con salchicha de Aveyron', 'Fondue bourguignonne'],
      'it': ['Raclette savoiarda tradizionale', 'Fonduta di formaggi svizzeri', 'Tartiflette al Reblochon', 'Mont d\'Or caldo con patate', 'Croziflette con pancetta', 'Aligot con salsiccia dell\'Aveyron', 'Fondue bourguignonne'],
      'ca': ['Raclet savoiarda tradicional', 'Fondue de formatges suïssos', 'Tartiflette amb Reblochon', 'Mont d\'Or calent amb patates', 'Croziflette amb cansalada', 'Aligot amb salsitxa de l\'Aveyron', 'Fondue bourguignonne'],
      'la': ['Raclette Sabaudica', 'Fondue Helvetica', 'Tartiflette Reblochon', 'Mont d\'Or calidum', 'Croziflette', 'Aligot farcimine', 'Fondue Burgundica'],
    },
    'mushrooms_truffle': {
      'en': ['Creamy porcini risotto', 'Fresh black truffle pasta', 'Pan-seared fresh morels', 'Truffle omelette', 'Sautéed chanterelles with parsley', 'Chestnut and porcini soup', 'Saffron and morel risotto'],
      'es': ['Risotto cremoso de boletus', 'Pasta fresca con trufa negra', 'Salteado de colmenillas frescas', 'Tortilla de trufas', 'Rebozuelos salteados al perejil', 'Crema de castañas y boletus', 'Risotto al azafrán con colmenillas'],
      'it': ['Risotto cremoso ai porcini', 'Pasta fresca al tartufo nero', 'Spugnole fresche in padella', 'Frittata al tartufo', 'Finferli saltati al prezzemolo', 'Vellutata di castagne e porcini', 'Risotto allo zafferano e spugnole'],
      'ca': ['Risotto cremós de ceps', 'Pasta fresca amb tòfona negra', 'Saltejat de múrgoles fresques', 'Truita de tòfona', 'Rossinyols saltejats al julivert', 'Crema de castanyes i ceps', 'Risotto al safrà amb múrgoles'],
      'la': ['Risotto boletis edulibus', 'Pasta tuberibus nigris', 'Morchellae frictae', 'Omelette tuberibus', 'Cantharelli fricti', 'Iusculum castaneis & boletis', 'Risotto croco et morchellis'],
    },
    'italian_pasta_pizza': {
      'en': ['Wood-fired Pizza Margherita', 'Homemade lasagne bolognese', 'Spaghetti Carbonara tradizionale', 'Spaghetti alle Vongole', 'Beef carpaccio with parmesan', 'Burrata di Bufala & sundried tomatoes', 'Sicilian arancini'],
      'es': ['Pizza Margherita al horno de leña', 'Lasaña boloñesa casera', 'Spaghetti Carbonara tradizionale', 'Spaghetti alle Vongole', 'Carpaccio de buey al parmesano', 'Burrata di Bufala con tomates confitados', 'Arancini sicilianos'],
      'it': ['Pizza Margherita cotta a legna', 'Lasagne alla bolognese fatte in casa', 'Spaghetti alla carbonara', 'Spaghetti alle vongole', 'Carpaccio di manzo al parmigiano', 'Burrata di bufala e pomodori secchi', 'Arancini siciliani'],
      'ca': ['Pizza Margherita al forn de llenya', 'Lasanya bolonyesa casolana', 'Spaghetti Carbonara tradizionale', 'Spaghetti alle Vongole', 'Carpaccio de vedella al parmesà', 'Burrata di Bufala amb tomàquets confitats', 'Arancini sicilians'],
      'la': ['Pizza Margherita camino assa', 'Lasagna Bononiensis', 'Spaghetti Carbonara tradizionale', 'Spaghetti conchis (alle Vongole)', 'Carpaccio bubulum caseo Parmensi', 'Burrata di Bufala & lycopersica', 'Arancini Siculi'],
    },
    'french_terroir': {
      'en': ['Castelnaudary Cassoulet', 'Royal garnie sauerkraut', 'Pork belly with Puy green lentils', 'Black pudding with caramelized apples', 'Grilled Troyes andouillette', 'Alsatian Baeckeoffe', 'Caen-style tripe'],
      'es': ['Cassoulet de Castelnaudary', 'Chucrut real garnie', 'Lentejas verdes del Puy con cerdo', 'Morcilla con manzanas caramelizadas', 'Andouillette de Troyes a la parrilla', 'Baeckeoffe alsaciano', 'Callos a la moda de Caen'],
      'it': ['Cassoulet di Castelnaudary', 'Choucroute reale guarnita', 'Pancetta con lenticchie verdi di Puy', 'Sanguinaccio con mele caramellate', 'Andouillette di Troyes alla griglia', 'Baeckeoffe alsaziano', 'Trippa alla moda di Caen'],
      'ca': ['Caçolet de Castelnaudary', 'Choucroute reial guarnida', 'Llenties verdes del Puy amb porc', 'Botifarra negra amb pomes caramel·litzades', 'Andouillette de Troyes a la graella', 'Baeckeoffe alsacià', 'Tripes a la moda de Caen'],
      'la': ['Cassoulet Castelnaudariense', 'Caulis acidus regalis', 'Lenticulae Podienses porco conditae', 'Fartum nigrum malis', 'Andouillette assa', 'Baeckeoffe Alsaticum', 'Fiscellus Cadomensis'],
    },
    'spicy_oriental': {
      'en': ['Royal Couscous with 3 meats', 'Chicken tagine with preserved lemons', 'Indian Butter Chicken', 'Lamb Madras curry', 'Creole Colombo chicken', 'Reunion Island sausage rougail', 'Chili con carne'],
      'es': ['Cuscús real 3 carnes', 'Tajine de pollo con limones confitados', 'Butter Chicken indio', 'Curry de cordero Madrás', 'Pollo Colombo antillano', 'Rougail criollo de salchicha', 'Chili con carne'],
      'it': ['Couscous reale con 3 carni', 'Tajine di pollo ai limoni confit', 'Butter chicken indiano', 'Curry di agnello Madras', 'Pollo Colombo creolo', 'Rougail di salsiccia creolo', 'Chili con carne'],
      'ca': ['Cuscús reial 3 carns', 'Tagin de pollastre amb llimones confitades', 'Butter Chicken indi', 'Curri de xai Madràs', 'Pollastre Colombo antillà', 'Rougail crioll de salsitxes', 'Chili con carne'],
      'la': ['Couscous regale 3 carnibus', 'Tajine pulli citris conditis', 'Butter Chicken Indicum', 'Curry agnini Madras', 'Pullus Colombo Antillanus', 'Rougail farciminis', 'Chili con carne'],
    },
    'asian_street_food': {
      'en': ['Peking duck', 'Shrimp Pad Thai', 'Vietnamese Beef Bo Bun', 'Steamed Pork & Prawn Dim Sum', 'Japanese Tonkotsu Ramen', 'Chicken Yakitori skewers', 'Chicken Gyoza'],
      'es': ['Pato laqueado a la pequinesa', 'Pad Thai con gambas', 'Bo Bun vietnamita de buey', 'Dim Sum al vapor cerdo y gambas', 'Ramen Tonkotsu japonés', 'Brochetas Yakitori de pollo', 'Gyozas crujientes de pollo'],
      'it': ['Anatra laccata alla pechinese', 'Pad Thai ai gamberi', 'Bo Bun vietnamita al manzo', 'Dim sum al vapore di maiale e gamberi', 'Ramen Tonkotsu giapponese', 'Spiedini yakitori di pollo', 'Gyoza di pollo'],
      'ca': ['Ànec laquejat a la pequinesa', 'Pad Thai amb gambes', 'Bo Bun vietnamita de vedella', 'Dim Sum al vapor porc i gambes', 'Ramen Tonkotsu japonès', 'Broquetes Yakitori de pollastre', 'Gyoza cruixent de pollastre'],
      'la': ['Anas Pekinensis laqueata', 'Pad Thai squillis', 'Bo Bun bubulum Vietnamense', 'Dim Sum vapore coctum', 'Tonkotsu Ramen Iaponicum', 'Yakitori assatum pulli', 'Gyoza fricta'],
    },
    'tapas_aperitif': {
      'en': ['Pata Negra ham platter', 'Foie gras mi-cuit on toast', 'Provençal tapenade & anchoïade', 'Warm cheese gougères', 'Assorted Basque pintxos', 'Argentinian empanadas', 'Niçoise pissaladière'],
      'es': ['Tabla de jamón Pata Negra', 'Foie gras mi-cuit sobre tostada', 'Tapenade y anchoïade provenzales', 'Gougères de queso calientes', 'Pintxos vascos variados', 'Empanadas argentinas', 'Pissaladière nizarda'],
      'it': ['Tagliere di prosciutto Pata Negra', 'Foie gras mi-cuit su crostino', 'Tapenade e anchoïade provenzali', 'Gougères calde al formaggio', 'Pintxos baschi misti', 'Empanadas argentine', 'Pissaladière nizzarda'],
    },
    'dessert': {
      'en': ['Molten chocolate cake', 'Warm tarte Tatin with cream', 'Lemon meringue tart', 'Bourbon vanilla crème brûlée', 'Italian coffee tiramisu', 'Grand Marnier soufflé', 'Profiteroles with hot chocolate'],
      'es': ['Coulant de chocolate', 'Tarta Tatin tibia con nata', 'Tarta de limón merengada', 'Crème brûlée de vainilla Bourbon', 'Tiramisú italiano al café', 'Soufflé al Grand Marnier', 'Profiteroles con chocolate caliente'],
      'it': ['Tortino al cioccolato dal cuore fondente', 'Tarte Tatin tiepida con panna', 'Crostata al limone meringata', 'Crème brûlée alla vaniglia Bourbon', 'Tiramisù al caffè', 'Soufflé al Grand Marnier', 'Profiteroles al cioccolato caldo'],
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
      ],
      keywords: [
        'huitre', 'huître', 'crevette', 'homard', 'langouste', 'langoustine',
        'saint-jacques', 'st-jacques', 'fruits de mer', 'crustaces', 'crustacés',
        'gambas', 'moule', 'moules marinières', 'coquillage', 'bulot', 'bigorneau',
        'tourteau', 'crabe', 'couteau', 'palourde', 'ecrevisse', 'écrevisse',
        'plateau de fruits de mer', 'coquilles saint-jacques',
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
      'cassoulet', 'borgognona', 'borgoñona', 'carbonade', 'carbonada', 'gulash', 'liebre'
    ]);
    // Un couscous, un tajine ou un curry se jugent à leurs épices, avant la viande ou la volaille.
    final isSpicyDish = _matchesKeywords(query, [
      'couscous', 'cuscus', 'tajine', 'tagine', 'curry', 'butter chicken', 'tikka masala', 'colombo', 'rougail',
      'tandoori', 'madras', 'harissa'
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
        } else if (region.contains('alsace') || region.contains('loire') || appellation.contains('riesling') || appellation.contains('sancerre') || appellation.contains('chablis')) {
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
      'bream', 'john dory', 'monkfish', 'dorada', 'rodaballo', 'san pedro', 'trucha', 'armoricana', 'merluza'
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
      'bogavante', 'centollo', 'cigala', 'navaja', 'razor clam', 'langosta'
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
        } else {
          score = 77 + bottleDifferentiator;
          comment = 'Fraîcheur désaltérante idéale sur un plateau de fruits de mer.';
          serving = 'Servir à 9-10°C.';
        }
      } else if (type.contains('champ') || type.contains('sparkling')) {
        score = 96 + bottleDifferentiator;
        comment = 'L\'effervescence pure et vive des bulles réveille les papilles et magnifie la chair raffinée du homard et des huîtres.';
        serving = 'Servir à 8-9°C en verre tulipe.';
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
      } else if ((type == 'red' || type == 'rouge') && _matchesKeywords(query, ['ossau', 'brebis', 'sheep', 'pecorino', 'oveja', 'pecora'])) {
        if (region.contains('sud ouest') || region.contains('madiran') || region.contains('bordeaux')) {
          score = 87 + bottleDifferentiator;
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
      'formaggi', 'grana padano', 'fontina', 'taleggio', 'asiago', 'queso', 'gruyer'
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
    else if (_matchesKeywords(query, [
      'choucroute', 'petit sale', 'petit salé', 'boudin', 'boudin noir', 'boudin blanc',
      'andouillette', 'baeckeoffe', 'tripes', 'poule au pot', 'sauerkraut',
      'crauti', 'sanguinaccio', 'trippa', 'lenticchie', 'cotechino', 'zampone', 'chucrut', 'morcilla', 'callos',
      'black pudding', 'pork belly', 'tripe', 'lentils', 'lentejas'
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
      'speziat', 'piccante', 'indiano', 'picante', 'especiad', 'tagine', 'cuscus', 'madras'
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
      'agrodolce', 'giapponese', 'cinese', 'vietnamita', 'thailandese', 'pechinese'
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
      'cioccolat', 'crostata', 'torta', 'tortino', 'panna cotta', 'cannoli', 'semifreddo', 'gelato', 'dolce', 'postre', 'tarta'
    ])) {
      if (_matchesKeywords(query, ['chocolat', 'cacao', 'cioccolat'])) {
        if (region.contains('banyuls') || region.contains('maury') || region.contains('porto') || region.contains('roussillon') || type.contains('fortified') || (type == 'red' && grapes.contains('grenache') && isMature)) {
          score = 95 + bottleDifferentiator;
          comment = 'Accord magique au sommet : les notes de cacao, cerise noire confite et pruneau d\'un Vin Doux Naturel ou Porto subliment le chocolat noir corsé.';
          serving = 'Servir à 14-16°C.';
        }
      } else {
        if (type.contains('dessert') || type.contains('moell') || type.contains('liquor') || type.contains('sauternes') || region.contains('sauternes') || region.contains('layon') || region.contains('alsace') || type.contains('sweet')) {
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
