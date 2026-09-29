/// Le débrief de dégustation en anglais, texte français → anglais.
///
/// `tasting_pedagogy_engine.dart` rédige en français ; en fin d'analyse, le rapport passe
/// par cette table quand l'app est en anglais. Le test `tasting_pedagogy_en_test.dart`
/// veille à ce qu'aucun texte n'y manque.
const Map<String, String> pedagogieEnAnglais = {
  'Cépages & Concentration':
      'Grapes & concentration',
  'Cépages & Mutage':
      'Grapes & fortification',
  'Cépages':
      'Grapes',
  'Sucre, acidité et arômes de fruits confits.':
      'Sugar, acidity and candied-fruit aromas.',
  'Fruit concentré, douceur et chaleur de l\'alcool.':
      'Concentrated fruit, sweetness and the warmth of alcohol.',
  'Le caractère du raisin, avant l\'élevage.':
      'The character of the grape, before ageing.',
  'Doré éclatant aux reflets ambrés':
      'Bright gold with amber glints',
  'Or pâle cristallin à cordon de bulles très fin':
      'Crystal-clear pale gold with a very fine bead of bubbles',
  'Attaque vive et crémeuse, effervescence soyeuse, finale saline et crayeuse d\'une grande persistance.':
      'A lively, creamy attack, silky fizz, and a long saline, chalky finish.',
  'Attaque vive et fruitée, bulle légère, finale fraîche et désaltérante.':
      'A lively, fruity attack, light bubbles, a fresh, thirst-quenching finish.',
  'Attaque vive et crémeuse, bulle fine, finale fraîche et persistante.':
      'A lively, creamy attack, fine bubbles, a fresh and lasting finish.',
  'Poire & Fleurs blanches':
      'Pear & white flowers',
  'Prise de mousse en cuve close':
      'Tank-method fizz',
  'La mousse prise en cuve, sans long repos sur lies, garde au vin son fruit frais plutôt que des notes de brioche.':
      'Bubbles made in a tank, without long ageing on the lees, keep the wine\'s fresh fruit rather than brioche notes.',
  'Brioche tiède & Pain grillé':
      'Warm brioche & toast',
  'Autolyse des levures':
      'Yeast autolysis',
  'Pendant le repos sur lies en bouteille, les levures mortes se décomposent et libèrent des mannoprotéines et des acides aminés.':
      'While the wine rests on its lees in the bottle, the dead yeasts break down and release mannoproteins and amino acids.',
  'Touche iodée & Craie vive':
      'A briny touch & fresh chalk',
  'Sous-sol Crétacé':
      'Cretaceous subsoil',
  'Les racines plongent dans le calcaire actif de la craie champenoise, apportant cette fraîcheur saline inimitable.':
      'The roots dig into the active limestone of Champagne chalk, bringing that inimitable saline freshness.',
  'La Prise de Mousse en Cuve Close':
      'Tank-method bubbles',
  'Méthode Charmat • Esters de fermentation':
      'Charmat method • Fermentation esters',
  'Pourquoi ce vin garde-t-il un fruit si frais ?':
      'Why does this wine keep such fresh fruit?',
  'La seconde fermentation a lieu dans une cuve fermée, sous pression, en quelques semaines. Le vin passe peu de temps sur ses lies : il garde le fruit croquant du raisin plutôt que les notes de brioche des méthodes en bouteille.':
      'The second fermentation happens in a sealed tank, under pressure, in a few weeks. The wine spends little time on its lees: it keeps the grape\'s crunchy fruit rather than the brioche notes of bottle-fermented wines.',
  'Prise de mousse & Autolyse des Levures':
      'Second fermentation & yeast autolysis',
  'Mannoprotéines • Acides aminés':
      'Mannoproteins • Amino acids',
  'Pourquoi le Champagne sent la brioche et le pain grillé ?':
      'Why does Champagne smell of brioche and toast?',
  'Pourquoi un effervescent peut-il sentir la brioche ?':
      'Why can a sparkling wine smell of brioche?',
  'La seconde fermentation en bouteille emprisonne le gaz carbonique sous 5 à 6 bars de pression. Au fil des mois sur lies, les levures s\'autolysent et enrichissent le vin en acides aminés et en mannoprotéines : d\'où les notes briochées et une bulle plus fine.':
      'The second fermentation in the bottle traps carbon dioxide at 5 to 6 bars of pressure. Over months on the lees, the yeasts autolyse and enrich the wine with amino acids and mannoproteins: hence the brioche notes and finer bubbles.',
  'Terroir de Craie & Acidité Ciselée':
      'Chalk terroir & chiselled acidity',
  'Acide Tartrique • Carbonate de Calcium (CaCO3)':
      'Tartaric acid • Calcium carbonate (CaCO3)',
  'La sensation de pureté minérale et de fraîcheur tranchante.':
      'That feeling of mineral purity and sharp freshness.',
  'Le sous-sol calcaire régule parfaitement l\'eau et la température des racines. Il préserve une acidité élevée qui permet aux meilleures cuvées de vieillir longtemps sans lourdeur.':
      'The limestone subsoil regulates water and root temperature perfectly. It keeps acidity high, which lets the best cuvées age for a long time without heaviness.',
  'Du grenat profond (Porto, Banyuls) à l\'ambre (tawny, rancio) selon le style':
      'From deep garnet (Port, Banyuls) to amber (tawny, rancio), depending on the style',
  'Ambre doré aux reflets cuivrés':
      'Golden amber with copper glints',
  'Or intense et lumineux':
      'Deep, luminous gold',
  'Attaque chaleureuse et riche, alcool fondu dans le fruit, finale longue.':
      'A warm, rich attack, the alcohol blended into the fruit, a long finish.',
  'Attaque onctueuse et riche, sucre équilibré par une belle acidité, finale longue sur le miel et l\'abricot.':
      'A luscious, rich attack, sweetness balanced by lovely acidity, a long finish of honey and apricot.',
  'Noix & Amande':
      'Walnut & almond',
  'Voile de levures (flor)':
      'Yeast veil (flor)',
  'Sous un voile de levures, le vin s\'oxyde doucement et prend ses notes de noix et d\'amande.':
      'Under a veil of yeast, the wine oxidises gently and picks up its walnut and almond notes.',
  'Pruneau & Cacao':
      'Prune & cocoa',
  'Mutage':
      'Fortification',
  'L\'ajout d\'eau-de-vie arrête la fermentation : le vin garde une partie du sucre du raisin, d\'où sa rondeur et ses notes de fruits confits.':
      'Adding grape spirit stops the fermentation: the wine keeps some of the grape\'s sugar, hence its roundness and candied-fruit notes.',
  'Miel & Abricot confit':
      'Honey & candied apricot',
  'Concentration du raisin':
      'Concentrated grapes',
  'Pourriture noble ou passerillage : le raisin perd son eau sur pied, sucres et acides se concentrent, et naissent les notes de miel et d\'abricot confit.':
      'Noble rot or drying on the vine: the grape loses its water, sugars and acids concentrate, and notes of honey and candied apricot appear.',
  'Le Mutage & l\'Équilibre de l\'Alcool':
      'Fortification & the balance of alcohol',
  'L\'Équilibre du Sucre et de l\'Acidité':
      'The balance of sugar and acidity',
  'Éthanol • Sucres résiduels':
      'Ethanol • Residual sugar',
  'Glucose • Fructose • Acide tartrique':
      'Glucose • Fructose • Tartaric acid',
  'Pourquoi ce vin est-il à la fois doux et chaleureux ?':
      'Why is this wine both sweet and warming?',
  'Pourquoi un grand liquoreux n\'est-il pas écœurant ?':
      'Why isn\'t a great sweet wine cloying?',
  'On ajoute de l\'eau-de-vie au vin avant ou après la fermentation. Avant, elle l\'arrête et garde le sucre du raisin (Porto, Banyuls) ; après, le vin reste sec (Xérès). L\'alcool, plus élevé, se fond avec le temps.':
      'Grape spirit is added to the wine during or after fermentation. During, it stops it and keeps the grape\'s sugar (Port, Banyuls); after, the wine stays dry (Sherry). The higher alcohol mellows with time.',
  'Un vin liquoreux peut contenir plus de 100 grammes de sucre par litre. Ce qui le rend digeste, c\'est son acidité : elle équilibre le sucre et étire la finale. C\'est aussi elle qui permet aux plus grands de vieillir des décennies.':
      'A sweet wine can hold over 100 grams of sugar per litre. What keeps it fresh is its acidity: it balances the sugar and stretches the finish. It is also what lets the greatest ones age for decades.',
  'Grenat profond avec reflets tuilés / brique':
      'Deep garnet with brick-coloured glints',
  'Pourpre sombre et profond, reflets violacés':
      'Deep, dark purple with violet glints',
  'Attaque ample et charnue, tanins denses et structurés, finale puissante imprégnée d\'épices et de bois noble.':
      'A broad, fleshy attack, dense and structured tannins, a powerful finish of spice and fine oak.',
  'Poivre noir moulu & Garrigue':
      'Cracked black pepper & garrigue',
  'Molécule Rotundone':
      'Rotundone',
  'Présente dans la peau des cépages Syrah et Mourvèdre, la rotundone est détectable dès 16 nanogrammes par litre !':
      'Found in the skins of Syrah and Mourvèdre, rotundone can be detected at just 16 nanograms per litre!',
  'Cassis & Cèdre':
      'Blackcurrant & cedar',
  'Le cabernet sauvignon donne le cassis et, avec l\'âge, des notes de cèdre et de mine de crayon.':
      'Cabernet Sauvignon gives blackcurrant and, with age, notes of cedar and pencil lead.',
  'Fruits noirs mûrs & Épices douces':
      'Ripe black fruit & sweet spice',
  'Maturité du raisin':
      'Grape ripeness',
  'Des raisins cueillis bien mûrs donnent ces arômes de fruits noirs ; le temps y ajoute des épices douces.':
      'Grapes picked fully ripe give these black-fruit aromas; time adds sweet spice.',
  'Cuir noble & Sous-bois humide':
      'Fine leather & damp forest floor',
  'Évolution tertiaire':
      'Tertiary development',
  'La lente micro-oxydation polymérise les tanins et libère des lactones et arômes de boîte à cigares.':
      'Slow micro-oxidation polymerises the tannins and releases lactones and cigar-box aromas.',
  'Vanille bourbon & Cacao grillé':
      'Bourbon vanilla & roasted cocoa',
  'Élevage en fûts de chêne':
      'Oak ageing',
  'La chauffe du bois de chêne libère de la vanilline et du gaïacol fumé au contact du vin.':
      'Toasting the oak releases vanillin and smoky guaiacol into the wine.',
  'Fruit croquant & Violette':
      'Crunchy fruit & violet',
  'Élevage sans bois':
      'Unoaked ageing',
  'Sans bois, rien ne masque le fruit : il reste croquant, et la violette peut apparaître.':
      'Without oak, nothing masks the fruit: it stays crunchy, and violet can appear.',
  'L\'Extraction Polyphénolique & les Tanins':
      'Polyphenol extraction & tannins',
  'Anthocyanes • Proanthocyanidines • Rotundone':
      'Anthocyanins • Proanthocyanidins • Rotundone',
  'Anthocyanes • Proanthocyanidines':
      'Anthocyanins • Proanthocyanidins',
  'D\'où viennent la couleur sombre et la structure astringente ?':
      'Where do the dark colour and the grippy structure come from?',
  'Durant la cuvaison (pigeages et remontages), l\'alcool extrait les anthocyanes (pigments rouges) et les tanins concentrés dans la peau et les pépins. Les tanins se lient aux protéines de votre salive, créant cette sensation tactile d\'assèchement noble qui s\'assouplit avec le temps.':
      'During maceration (punch-downs and pump-overs), alcohol extracts the anthocyanins (red pigments) and the tannins held in the skins and seeds. Tannins bind to the proteins in your saliva, creating that drying feeling which softens with time.',
  'L\'Élevage en Fût de Chêne & Chauffe Toastée':
      'Oak ageing & barrel toast',
  'Vanilline (C8H8O3) • Eugénol • Gaïacol':
      'Vanillin (C8H8O3) • Eugenol • Guaiacol',
  'L\'alchimie entre le bois de chêne et le vin.':
      'The alchemy between oak and wine.',
  'Pour ces vins, le séjour en barrique dure souvent 12 à 24 mois et apporte une micro-oxygénation douce à travers les pores du bois. Le toastage de la barrique caramélise les sucres du chêne, infusant des molécules de vanilline (vanille), d\'eugénol (clou de girofle) et de gaïacol (notes de grillé, café, cacao).':
      'For these wines, barrel ageing often lasts 12 to 24 months and brings gentle micro-oxygenation through the pores of the wood. Toasting the barrel caramelises the sugars in the oak, infusing vanillin (vanilla), eugenol (clove) and guaiacol (toast, coffee, cocoa).',
  'La Polymérisation & les Arômes Tertiaires':
      'Polymerisation & tertiary aromas',
  'Le Potentiel de Garde & la Réduction d\'Astringence':
      'Ageing potential & softening tannins',
  'Polymérisation Anthocyane-Tanin • Éthers':
      'Anthocyanin-tannin polymerisation • Ethers',
  'Pourquoi le vin prend des notes de sous-bois et de cuir ?':
      'Why does wine develop notes of forest floor and leather?',
  'Pourquoi ce vin peut-il se bonifier en cave ?':
      'Why can this wine improve in the cellar?',
  'Avec les années de garde en bouteille, les molécules de tanins et d\'anthocyanes s\'agrègent en longues chaînes (polymères). Ce processus adoucit l\'amertume et fait émerger les arômes tertiaires de sous-bois, truffe, cuir et tabac blond.':
      'Over years in bottle, tannin and anthocyanin molecules link into long chains (polymers). This softens bitterness and brings out tertiary aromas of forest floor, truffle, leather and tobacco.',
  'Rubis évolué avec disque tuilé translucide':
      'Mature ruby with a translucent brick rim',
  'Rubis brillant et limpide, d\'intensité moyenne':
      'Bright, clear ruby of medium intensity',
  'Attaque soyeuse et dentelée, tanins fins comme de la soie, équilibre frais et finale saline très aérienne.':
      'A silky, lacy attack, tannins as fine as silk, a fresh balance and a light, saline finish.',
  'Cerise griotte & Framboise sauvage':
      'Morello cherry & wild raspberry',
  'Esters de fermentation':
      'Fermentation esters',
  'La fermentation douce à température contrôlée préserve les esters de fruits frais très volatils.':
      'A gentle, temperature-controlled fermentation keeps the very volatile fresh-fruit esters.',
  'Pétale de rose fanée & Violette':
      'Faded rose petal & violet',
  'β-damascénone & Terpènes':
      'β-damascenone & terpenes',
  'Molécules florales typiques des rouges délicats, de la Bourgogne à la Loire.':
      'Floral molecules typical of delicate reds, from Burgundy to the Loire.',
  'La Délicatesse du Cépage & Macération Douce':
      'A delicate grape & a gentle maceration',
  'β-Damascénone • Esters Éthyliques':
      'β-Damascenone • Ethyl esters',
  'Pourquoi le Pinot Noir / Gamay est si soyeux et aérien ?':
      'Why are Pinot Noir and Gamay so silky and light?',
  'Ces cépages possèdent une peau fine pauvre en tanins agressifs mais gorgée de précurseurs d\'arômes floraux et fruités. Une macération en vendange entière ou pré-fermentaire à froid permet de capturer la pureté du fruit sans extraire d\'amertume végétale.':
      'These grapes have thin skins, low in harsh tannins but full of floral and fruity aroma precursors. Whole-bunch or cold pre-fermentation maceration captures the purity of the fruit without extracting green bitterness.',
  'Le Rôle du Terroir':
      'The role of terroir',
  'Drainage Calcaire • Équilibre Acido-Basique':
      'Drainage • Acid-base balance',
  'La sensation de verticalité minérale en bouche.':
      'That vertical, mineral feeling on the palate.',
  'Des sols pauvres (calcaire, granite, schiste) limitent la vigueur de la vigne. L\'apport régulier en minéraux soutient une acidité naturelle éclatante qui étire la finale en bouche sans sensation de lourdeur alcoolique.':
      'Poor soils (limestone, granite, schist) limit the vine\'s vigour. A steady supply of minerals supports a bright natural acidity that stretches the finish without any alcoholic heaviness.',
  'Or pâle aux reflets verts scintillants':
      'Pale gold with sparkling green glints',
  'Attaque droite, ciselée et tranchante, tension saline magistrale, finale vibrante d\'agrumes et de pierre à fusil.':
      'A straight, chiselled, sharp attack, masterful saline tension, a vibrant finish of citrus and flint.',
  'Pierre à fusil & Coquille d\'huître':
      'Flint & oyster shell',
  'Kimméridgien / Terroir':
      'Kimmeridgian / terroir',
  'Présence de fossiles marins (Exogyra virgula) dans les marnes qui renforcent l\'impression saline et iodée.':
      'Marine fossils (Exogyra virgula) in the marl reinforce the saline, briny impression.',
  'Pierre mouillée & Agrumes':
      'Wet stone & citrus',
  'Climat frais':
      'Cool climate',
  'Un climat frais garde au raisin son acidité : de là viennent la tension et cette impression de pierre mouillée.':
      'A cool climate keeps the grape\'s acidity: that is where the tension and the wet-stone impression come from.',
  'Pamplemousse rose & Buis noble':
      'Pink grapefruit & boxwood',
  'Thiols Variétaux':
      'Varietal thiols',
  'Molécules 3-mercaptohexanol (3-MH) libérées par l\'action des levures durant la fermentation.':
      '3-mercaptohexanol (3-MH) molecules, released by the yeasts during fermentation.',
  'Citron vert & Pétrole':
      'Lime & petrol',
  'Riesling (TDN)':
      'Riesling (TDN)',
  'Avec l\'âge, le Riesling développe le TDN, une molécule aux notes de pétrole typique du cépage.':
      'With age, Riesling develops TDN, a molecule with the petrol notes typical of the grape.',
  'Agrumes & Fruits blancs':
      'Citrus & white fruit',
  'Fermentation au frais':
      'Cool fermentation',
  'Une fermentation à basse température préserve les arômes délicats d\'agrumes et de fruits blancs.':
      'A low-temperature fermentation keeps delicate citrus and white-fruit aromas.',
  'Les Précurseurs d\'Arômes':
      'Aroma precursors',
  'Précurseurs glycosylés • Esters':
      'Glycosylated precursors • Esters',
  'D\'où viennent les arômes de fruits d\'un vin blanc ?':
      'Where do a white wine\'s fruit aromas come from?',
  'Le raisin blanc contient des précurseurs d\'arômes, liés à des sucres ou à des acides aminés, qui ne sentent rien. La fermentation au frais les libère peu à peu : c\'est là que naissent les notes d\'agrumes et de fruits blancs.':
      'White grapes hold aroma precursors, bound to sugars or amino acids, that smell of nothing. A cool fermentation slowly releases them: that is where the citrus and white-fruit notes are born.',
  'Les Thiols Variétaux & Terpènes Vifs':
      'Varietal thiols & lively terpenes',
  '3-Mercaptohexanol (3-MH) • Linalol':
      '3-Mercaptohexanol (3-MH) • Linalool',
  'Le secret des arômes explosifs d\'agrumes et de fruits exotiques.':
      'The secret of explosive citrus and tropical-fruit aromas.',
  'Le raisin blanc contient des précurseurs aromatiques liés à des acides aminés (cystéine). Durant la vinification à basse température, l\'activité enzymatique des levures rompt ces liaisons, libérant les thiols volatils responsables des notes d\'agrumes et de zeste.':
      'White grapes hold aroma precursors bound to amino acids (cysteine). During a low-temperature fermentation, yeast enzymes break these bonds, releasing the volatile thiols behind the citrus and zest notes.',
  'La Salinité & la Tension de l\'Acide Malique/Tartrique':
      'Salinity & the tension of malic/tartaric acid',
  'Acide Malique • Acide Tartrique (C4H6O6)':
      'Malic acid • Tartaric acid (C4H6O6)',
  'Pourquoi le vin fait-il saliver avec une telle énergie ?':
      'Why does the wine make your mouth water so much?',
  'Dans les blancs septentrionaux, la fermentation malolactique est souvent évitée ou partielle pour préserver l\'acide malique vif. Cette acidité stimule directement les glandes salivaires et agit comme un exhausteur de goût naturel.':
      'In northern whites, malolactic fermentation is often blocked or partial to keep the sharp malic acid. That acidity directly stimulates the salivary glands and works as a natural flavour enhancer.',
  'Or doré brillant et profond':
      'Bright, deep gold',
  'Attaque ample et onctueuse, matière riche tapissant le palais, finale ronde et fruitée.':
      'A broad, luscious attack, rich texture coating the palate, a round and fruity finish.',
  'Attaque ample, grasse et onctueuse, matière riche tapissant le palais, rehaussée par un boisé fin et une finale vanillée.':
      'A broad, rich, luscious attack coating the palate, lifted by fine oak and a vanilla finish.',
  'Beurre frais & Noisette grillée':
      'Fresh butter & toasted hazelnut',
  'Fermentation Malolactique + Bâtonnage':
      'Malolactic fermentation + lees stirring',
  'Le remuage régulier des lies enrichit le vin en mannoprotéines onctueuses.':
      'Regular stirring of the lees enriches the wine with smooth mannoproteins.',
  'Le remuage régulier des lies en fût de chêne enrichit le vin en lipides et mannoprotéines onctueuses.':
      'Regular stirring of the lees in oak barrels enriches the wine with lipids and smooth mannoproteins.',
  'La Fermentation Malolactique & le Diacétyle':
      'Malolactic fermentation & diacetyl',
  'Oenococcus oeni • Diacétyle (C4H6O2)':
      'Oenococcus oeni • Diacetyl (C4H6O2)',
  'Comment un vin blanc devient-il beurré et velouté ?':
      'How does a white wine become buttery and velvety?',
  'Les bactéries lactiques transforment l\'acide malique pointu en acide lactique doux et crémeux. Ce métabolisme produit du diacétyle, le composé aromatique qui donne au beurre frais et à la brioche leur parfum gourmand.':
      'Lactic bacteria turn sharp malic acid into soft, creamy lactic acid. This produces diacetyl, the aroma compound that gives fresh butter its rich scent.',
  'L\'Élevage sur Lies Fines & le Bâtonnage':
      'Ageing on fine lees & stirring',
  'Mannoprotéines • Lactones de Chêne':
      'Mannoproteins • Oak lactones',
  'D\'où vient cette sensation de gras enveloppant ?':
      'Where does that rich, rounded feeling come from?',
  'Les lies fines sont remises en suspension périodiquement à l\'aide d\'une baguette de bois (bâtonnage). En se dégradant, les enveloppes des levures libèrent des macromolécules qui enrobent l\'acidité et protègent naturellement le vin de l\'oxydation.':
      'The fine lees are stirred back up from time to time with a wooden rod (bâtonnage). As they break down, the yeast cell walls release large molecules that round out the acidity and naturally protect the wine from oxidation.',
  'Robe rose saumonée, limpide et brillante':
      'Clear, bright salmon pink',
  'Bouche croquante et rafraîchissante, équilibre entre fruit acidulé et fine trame saline en finale.':
      'A crunchy, refreshing palate, balancing tangy fruit with a fine saline finish.',
  'Groseille & Zeste de pamplemousse':
      'Redcurrant & grapefruit zest',
  'Pressurage direct doux':
      'Gentle direct pressing',
  'Une extraction très courte limite le contact entre le jus et les peaux pour garder uniquement les arômes délicats.':
      'A very short extraction limits contact between juice and skins, keeping only the delicate aromas.',
  'Le Pressurage Pneumatique & la Maîtrise des Températures':
      'Pneumatic pressing & temperature control',
  'Anthocyanes libres • Esters de Fermentation':
      'Free anthocyanins • Fermentation esters',
  'Pourquoi le rosé est-il pâle et si expressif ?':
      'Why is rosé pale and so expressive?',
  'Les raisins sont pressés délicatement à froid sous atmosphère inerte pour éviter tout brunissement oxydatif. Seules les premières gouttes de jus claires sont conservées pour fermenter à 14-16°C.':
      'The grapes are pressed gently and cold, under inert gas, to avoid any browning. Only the first clear juice is kept, and fermented at 14-16°C.',
  'Robe à observer : couleur, intensité, reflets':
      'Look at the colour: hue, intensity, glints',
  'Équilibre entre acidité, sucrosité, tanins et alcool, puis longueur en bouche.':
      'Balance between acidity, sweetness, tannins and alcohol, then length on the palate.',
  'Nez d\'Or & Dégustateur Averti 🏆 Vous avez immédiatement identifié les marqueurs cardinaux de ce flacon.':
      'Golden nose, seasoned taster 🏆 You spotted this bottle\'s key markers straight away.',
  'Excellente acuité sensorielle ✨ Vous avez décelé les composantes majeures du vin et de sa structure.':
      'Excellent sensory acuity ✨ You picked up the wine\'s main components and its structure.',
  'Belle intuition sensorielle 🍷 Votre perception capte de jolis traits du vin ; explorez ci-dessous les nuances subtiles.':
      'Good sensory intuition 🍷 You caught some lovely traits of the wine; explore the subtler nuances below.',
  'Exploration sensorielle prometteuse 🍇 Laissez vos sens s\'aiguiser en découvrant les secrets moléculaires ci-dessous.':
      'A promising exploration 🍇 Sharpen your senses with the molecular secrets below.',
  'Élevage en Fût de Chêne (Temps en Tonneau)':
      'Oak ageing (time in barrel)',
  'Micro-oxygénation & Vanilline':
      'Micro-oxygenation & vanillin',
  'Assouplissement des tanins rugueux, apport d\'arômes de vanille bourbon, pain grillé, cacao et clou de girofle.':
      'Softer, rounder tannins, and aromas of bourbon vanilla, toast, cocoa and clove.',
  'Le temps passé en tonneau opère deux métamorphoses capitales :\n1. L\'assouplissement tactile : la porosité naturelle du chêne assure une micro-oxygénation lente qui polymérise les tanins, les rendant fondus au lieu d\'être agressifs.\n2. L\'empreinte aromatique : la chauffe du bois au feu de tonnelier libère de la vanilline (vanille), du gaïacol (notes grillées/fumées) et de l\'eugénol (épices douces).':
      'Time in barrel does two key things:\n1. It softens the texture: the natural porosity of oak allows slow micro-oxygenation, which polymerises the tannins and makes them supple rather than harsh.\n2. It leaves an aromatic imprint: the cooper\'s toasting of the wood releases vanillin (vanilla), guaiacol (toasty, smoky notes) and eugenol (sweet spice).',
  'Élevage en Cuve Inox (Sans contact boisé)':
      'Aged in stainless steel (no oak contact)',
  'Pureté du fruit':
      'Pure fruit',
  'Préservation intégrale du fruit frais, vivacité intacte et franchise absolue du terroir.':
      'Fresh fruit kept intact, undimmed freshness and a clear expression of terroir.',
  'La cuve thermo-régulée protège le vin de toute oxydation et n\'apporte aucun tanin extérieur, assurant une pureté cristalline des arômes primaires du raisin.':
      'The temperature-controlled tank protects the wine from oxidation and adds no outside tannin, keeping the grape\'s primary aromas crystal-clear.',
  'une durée que le cahier des charges ne fixe pas':
      'a length the appellation rules don\'t set',
  'Durée imposée par le cahier des charges de l\'appellation':
      'Length required by the appellation rules',
  'Élevage usuel de l\'appellation':
      'The appellation\'s usual ageing',
  'Cahier des charges':
      'Appellation rules',
  'Usage de l\'appellation':
      'Appellation custom',
  'Cuve Inox':
      'Stainless steel tank',
  'Cuve Béton':
      'Concrete tank',
  'Barrique de Chêne':
      'Oak barrel',
  'Foudre de Chêne':
      'Large oak cask',
  'Œuf Béton':
      'Concrete egg',
  'Bouteille (sur lattes)':
      'Bottle (on laths)',
  'Mourvèdre (Cépage Roi)':
      'Mourvèdre (the king grape)',
  'Structure & Cuir':
      'Structure & leather',
  'Structure tannique puissante, notes profondes de fruits noirs sauvages (mûre, myrtille), de cuir noble, de garrigue et de sous-bois.':
      'Powerful tannic structure, deep notes of wild black fruit (blackberry, blueberry), fine leather, garrigue and forest floor.',
  'Cépage phare de Bandol et de Méditerranée, le Mourvèdre mûrit lentement face à la mer. Sa peau très épaisse est gorgée de polyphénols nobles qui lui donnent cette mâche dense en bouche et son exceptionnel potentiel de garde.':
      'The flagship grape of Bandol and the Mediterranean, Mourvèdre ripens slowly facing the sea. Its very thick skin is full of polyphenols that give it a dense, chewy palate and exceptional ageing potential.',
  'Carignan (Cépage de Terroir)':
      'Carignan (a terroir grape)',
  'Fraîcheur & Épices':
      'Freshness & spice',
  'Robe sombre et éclatante, vivacité acide désaltérante, notes de petits fruits noirs acidulés, thym et romarin.':
      'Dark, bright colour, refreshing acidity, notes of tangy small black fruit, thyme and rosemary.',
  'Issu de vieilles vignes de schistes ou de calcaire, le Carignan apporte la fraîcheur acide indispensable qui équilibre la puissance solaire des vins du Sud, avec une trame épicée racée.':
      'From old vines on schist or limestone, Carignan brings the acidity that balances the sunny power of southern wines, with a classy spicy backbone.',
  'Syrah (Cépage Aromatique)':
      'Syrah (an aromatic grape)',
  'Couleur & Poivre (Rotundone)':
      'Colour & pepper (rotundone)',
  'Robe sombre aux reflets violacés intenses, arômes emblématiques de poivre noir moulu, violette fraîche, tapenade et fruits noirs.':
      'Dark colour with intense violet glints, signature aromas of cracked black pepper, fresh violet, tapenade and black fruit.',
  'La pellicule de la Syrah concentre de la rotundone, une molécule ultra-aromatique détectable dès 16 nanogrammes/L qui donne cette signature poivrée inimitable. Elle enrichit le vin en anthocyanes violettes et en tanins soyeux.':
      'Syrah\'s skin concentrates rotundone, a highly aromatic molecule detectable from 16 nanograms/L that gives its inimitable peppery signature. It also brings violet anthocyanins and silky tannins.',
  'Grenache (Cépage de Rondeur)':
      'Grenache (a grape of roundness)',
  'Rondeur & Cerise confite':
      'Roundness & candied cherry',
  'Attaque ronde et veloutée, chaleur gourmande en alcool, arômes séducteurs de cerise kirschée, pruneau confit et cannelle.':
      'A round, velvety attack, generous warmth, seductive aromas of kirsch cherry, candied prune and cinnamon.',
  'Gorgé de sucres naturels qui se transforment en alcool soyeux, le Grenache enrobe les tanins plus fermes de ses partenaires d\'assemblage et apporte cette générosité chaleureuse typique des grands rouges méditerranéens.':
      'Full of natural sugars that turn into silky alcohol, Grenache rounds out the firmer tannins of its blending partners and brings the warm generosity typical of great Mediterranean reds.',
  'Armature & Cassis':
      'Backbone & blackcurrant',
  'Armature tannique droite et ferme, cassis intense, boîte à cigares (cèdre) et fraîcheur mentholée.':
      'A straight, firm tannic backbone, intense blackcurrant, cigar box (cedar) and minty freshness.',
  'Ses petites baies à peau épaisse apportent une concentration polyphénolique hors du commun. Il bâtit la colonne vertébrale tannique du vin, qui peut traverser les décennies.':
      'Its small, thick-skinned berries bring remarkable polyphenol concentration. It builds the wine\'s tannic backbone, which can last for decades.',
  'Velouté & Cacao':
      'Velvet & cocoa',
  'Texture suave et veloutée, tanins fondus dès l\'attaque, arômes charmeurs de prune noire mûre, cerise burlat et chocolat.':
      'A smooth, velvety texture, supple tannins from the start, charming aromas of ripe black plum, cherry and chocolate.',
  'Mûrissant précocement sur des sols argileux frais, le Merlot apporte la chair et la gourmandise en milieu de bouche, rendant le vin caressant.':
      'Ripening early on cool clay soils, Merlot brings flesh and generosity to the mid-palate, making the wine caressing.',
  'Élégance & Graphite':
      'Elegance & graphite',
  'Finesse aérienne, croquant de framboise et groseille, iris floral et touche minérale de graphite/crayon.':
      'Airy finesse, crunchy raspberry and redcurrant, floral iris and a mineral touch of graphite / pencil lead.',
  'Père génétique du Cabernet Sauvignon et du Merlot, il privilégie l\'élégance aromatique et la fraîcheur végétale noble plutôt que l\'opulence brute.':
      'The genetic parent of Cabernet Sauvignon and Merlot, it favours aromatic elegance and fine green freshness over sheer opulence.',
  'Dentelle & Griotte':
      'Lace & morello cherry',
  'Robe rubis translucide, dentelle tannique ultra-fine, cerise griotte, framboise sauvage, rose fanée et sous-bois.':
      'Translucent ruby, ultra-fine lacy tannins, morello cherry, wild raspberry, faded rose and forest floor.',
  'Cépage de grande délicatesse, sa peau fine produit des tanins doux comme de la soie et une palette d\'esters aromatiques floraux d\'une pureté inégalée.':
      'A very delicate grape: its thin skin gives silky tannins and a palette of floral aromas of rare purity.',
  'Croquant & Fruit frais':
      'Crunch & fresh fruit',
  'Fruit rouge croquant et juteux (fraise, framboise), pivoine florale et acidité désaltérante sans tanins agressifs.':
      'Crunchy, juicy red fruit (strawberry, raspberry), peony and refreshing acidity without harsh tannins.',
  'Idéal en macération semi-carbonique, il exhale des arômes de fruits frais très friands avec une teneur en tanins faible et digeste.':
      'Often made by semi-carbonic maceration, it gives very moreish fresh-fruit aromas with low, easy tannins.',
  'Densité & Mûre':
      'Density & blackberry',
  'Robe d\'un pourpre presque noir, bouche dense et charnue, mûre sauvage, violette et cacao amer.':
      'An almost black purple, a dense, fleshy palate, wild blackberry, violet and bitter cocoa.',
  'Très riche en polyphénols, le Malbec donne des vins sombres à la trame serrée, d\'une grande concentration en bouche.':
      'Very rich in polyphenols, Malbec makes dark, tightly knit wines with great concentration.',
  'Légèreté & Pêche':
      'Lightness & peach',
  'Fraîcheur aérienne, faible astringence, notes de grenade, pêche de vigne et pétales de rose.':
      'Airy freshness, little astringency, notes of pomegranate, vine peach and rose petals.',
  'Cépage à gros grains peu coloré, il allège les assemblages rouges et constitue la base soyeuse des plus grands rosés de Provence.':
      'A large-berried, lightly coloured grape, it lightens red blends and is the silky base of the finest Provence rosés.',
  'Tension & Pomme verte':
      'Tension & green apple',
  'Acidité vive, pomme verte, citron, fleurs blanches et notes crayeuses.':
      'Lively acidity, green apple, lemon, white flowers and chalky notes.',
  'Cépage caméléon : en climat frais et sans bois, il ne fait pas de gras, il laisse parler le terroir.':
      'A chameleon grape: in a cool climate and without oak, it stays lean and lets the terroir speak.',
  'Gras & Beurre noisette':
      'Richness & brown butter',
  'Corps ample et crémeux, pomme golden, agrumes mûrs, beurre frais, noisette grillée et brioche.':
      'A broad, creamy body, golden apple, ripe citrus, fresh butter, toasted hazelnut and brioche.',
  'Caméléon de l\'œnologie, il absorbe admirablement le travail sur lies (bâtonnage) et l\'élevage en fûts pour gagner son opulence gourmande.':
      'The chameleon of winemaking: it takes beautifully to lees stirring and barrel ageing, gaining its rich opulence.',
  'Tension & Thiols vifs':
      'Tension & lively thiols',
  'Vivacité tranchante, pamplemousse rose, citron vert, buis noble, pierre à fusil et bourgeon de cassis.':
      'Sharp freshness, pink grapefruit, lime, boxwood, flint and blackcurrant bud.',
  'Extrêmement riche en thiols variétaux (3-mercaptohexanol), ses arômes jaillissent du verre dès l\'agitation avec une sensation de fraîcheur éclatante.':
      'Very rich in varietal thiols (3-mercaptohexanol), its aromas leap from the glass as soon as you swirl, with bright freshness.',
  'Minéralité & Coing':
      'Minerality & quince',
  'Acidité ciselée et vibrante, minéralité crayeuse, pomme reinette, coing mûr et miel d\'acacia.':
      'Chiselled, vibrant acidity, chalky minerality, russet apple, ripe quince and acacia honey.',
  'L\'un des cépages blancs les plus nobles et polyvalents au monde, son acidité exceptionnelle permet aux plus grands de vieillir très longtemps.':
      'One of the noblest and most versatile white grapes in the world, its exceptional acidity lets the greatest age for a very long time.',
  'Pureté & Ciselé':
      'Purity & precision',
  'Pureté cristalline, acidité tranchante, citron vert, fleurs blanches et notes minérales/pétrolées fascinantes en vieillissant.':
      'Crystalline purity, sharp acidity, lime, white flowers and fascinating mineral / petrol notes with age.',
  'Le Riesling retranscrit la géologie du sol avec une précision chirurgicale sans jamais être masqué par l\'élevage en bois neuf.':
      'Riesling translates the soil\'s geology with surgical precision, never masked by new oak.',
  'Abricot & Opulence':
      'Apricot & opulence',
  'Texture grasse et enveloppante, faible acidité, parfum capiteux d\'abricot mûr, pêche blanche et chèvrefeuille.':
      'A rich, enveloping texture, low acidity, a heady scent of ripe apricot, white peach and honeysuckle.',
  'Ses terpènes abondants s\'expriment à pleine maturité dans la Vallée du Rhône Nord (Condrieu), créant un velouté floral en bouche.':
      'Its abundant terpenes show at full ripeness in the northern Rhône (Condrieu), giving a floral, velvety palate.',
  'Litchi & Épices':
      'Lychee & spice',
  'Bouquet exubérant de litchi, eau de rose, gingembre, cannelle et zeste d\'orange confite.':
      'An exuberant bouquet of lychee, rosewater, ginger, cinnamon and candied orange peel.',
  'Ses baies rosées concentrent des précurseurs terpéniques et épicés d\'une intensité aromatique unique parmi tous les cépages blancs.':
      'Its pink berries concentrate terpene and spicy precursors of an aromatic intensity unique among white grapes.',
  'Cépages Rouges & Polyphénols':
      'Red grapes & polyphenols',
  'Cépages Blancs & Terpènes':
      'White grapes & terpenes',
  'Cépages & Pressurage Doux':
      'Grapes & gentle pressing',
  'Expression Variétale':
      'Varietal expression',
  'Fruit rouge ou noir, structure tannique et reflets pourpres.':
      'Red or black fruit, tannic structure and purple glints.',
  'Fraîcheur fruitée, éclat minéral et acidité ciselée.':
      'Fruity freshness, mineral brightness and chiselled acidity.',
  'Fraîcheur acidulée et robe saumonée délicate.':
      'Tangy freshness and a delicate salmon colour.',
  'Les composants aromatiques primaires du raisin sont préservés par la fermentation à température maîtrisée.':
      'The grape\'s primary aromas are kept by a temperature-controlled fermentation.',
  'Évolution & Garde en Cave (Arômes Tertiaires)':
      'Development & cellaring (tertiary aromas)',
  'Bouquet tertiaire':
      'Tertiary bouquet',
  'Teinte grenat aux nuances tuilées/brique, arômes patinés de sous-bois, truffe, cuir et tabac blond.':
      'A garnet hue with brick tints, mellow aromas of forest floor, truffle, leather and tobacco.',
  'Le vieillissement en bouteille sous bouchon scellé provoque une polymérisation lente en milieu réducteur. Les arômes fruités primaires se subliment en notes tertiaires de grande complexité.':
      'Ageing in a sealed bottle brings slow polymerisation in a reductive environment. The primary fruit aromas turn into complex tertiary notes.',
  'Équilibre subtil entre maturité solaire, concentration en sucre et fraîcheur minérale saline.':
      'A subtle balance of sunny ripeness, sugar concentration and saline mineral freshness.',
  'La composition du sol (calcaire, argiles, galets ou schistes) régule l\'alimentation en eau de la vigne, tandis que l\'ensoleillement et les nuits fraîches forgent la vivacité et la signature aromatique du cru.':
      'The soil (limestone, clay, pebbles or schist) regulates the vine\'s water supply, while sunshine and cool nights shape the freshness and aromatic signature of the wine.',
};
