// La page invité légère (V2.3 · F2) : rejoindre une table Chatmelier depuis un navigateur.
//
// Sans dépendance : quelques appels `fetch` à l'API Supabase remplacent supabase-js
// (~110 Ko), pour une page qui pèse quelques dizaines de kilo-octets au lieu des 16,5 Mo
// de l'app Flutter. L'hôte calcule le classement et le publie (F1, `lire_etat_table`) :
// cette page n'a rien à recalculer, donc rien à dupliquer du moteur de consensus.
//
// Le code de la table voyage dans `?t=` et non `?code=` : le client Supabase prendrait un
// `code` pour un retour de connexion OAuth.

const CFG = window.CHATMELIER_CONFIG || {};
const API = (CFG.supabaseUrl || '').replace(/\/$/, '');
const CLE = CFG.supabaseKey || '';
const PLAY_STORE = 'https://play.google.com/store/apps/details?id=com.chatmelier.chatmelier';

// ---------------------------------------------------------------------------
// Langue : celle du navigateur, parmi celles de l'app.
// ---------------------------------------------------------------------------
const LANGUE = (() => {
  // `?lang=es` force une langue : pour relire une traduction sans changer de navigateur.
  const forcee = new URLSearchParams(location.search).get('lang');
  for (const l of [forcee, ...(navigator.languages || [navigator.language || 'en'])].filter(Boolean)) {
    const c = String(l).slice(0, 2).toLowerCase();
    if (c === 'fr' || c === 'en' || c === 'es' || c === 'it') return c;
  }
  return 'en';
})();
document.documentElement.lang = LANGUE;

const TEXTES = {
  fr: {
    codeTitre: 'Rejoindre une table',
    codeAide: 'Le code à six caractères affiché sur le téléphone de l\'hôte.',
    codeOk: 'Rejoindre',
    introuvable: 'Cette table est introuvable ou terminée. Vérifiez le code auprès de l\'hôte.',
    reseau: 'Pas de réseau pour l\'instant : réessayez dans un moment.',
    tropDeConnexions: 'Trop de nouvelles connexions depuis ce réseau (Wi-Fi d\'hôtel, d\'avion…) : réessayez dans quelques minutes, ou en 4G.',
    serveurIndisponible: 'Le serveur n\'a pas répondu ({cause}) : réessayez dans un moment.',
    reessayer: 'Réessayer',
    titrePage: 'Chatmelier — À table',
    tableDe: 'Table {code} — {restaurant}',
    tableSeule: 'Table {code}',
    aTable: 'À table',
    auComptoir: 'Au comptoir',
    vosGoutsAideComptoir: 'Facultatif : vos goûts s\'affichent à côté de votre prénom.',
    rejoindreComptoir: 'Rejoindre le comptoir avec mes goûts',
    assisComptoir: 'Vous êtes au comptoir, {nom}.',
    personne: 'Personne n\'est encore assis.',
    nePasBoire: 'ne boit pas',
    prenom: 'Votre prénom',
    vosGouts: 'Vos goûts, en vingt secondes',
    vosGoutsAide: 'Facultatif : la table en tiendra compte pour choisir la bouteille.',
    couleurs: 'Couleurs que vous aimez',
    aversions: 'Ce que vous n\'aimez pas',
    rejoindre: 'Rejoindre la table avec mes goûts',
    justeMonPrenom: 'Juste mon prénom — je préciserai plus tard',
    jeNeBoisPas: 'Je ne bois pas ce soir',
    assis: 'Vous êtes à table, {nom}.',
    assisSansGouts: 'Sans préférences : le classement ne tient pas compte de vos goûts.',
    assisSansBoire: 'Vous ne buvez pas ce soir : les bouteilles se choisissent pour les autres.',
    modifier: 'Préciser mes goûts',
    podiumTitre: 'Les trois bouteilles qui vont le mieux à la table',
    podiumAttente: 'L\'hôte prépare le classement : il apparaîtra ici dès qu\'il l\'aura publié.',
    accord: '{n} % d\'accord',
    devineUn: '≈ : palais encore deviné, {liste}. Ses accords restent prudents et se précisent à chaque vin noté.',
    devinePlusieurs: '≈ : palais encore devinés, {liste}. Leurs accords restent prudents et se précisent à chaque vin noté.',
    connuA: '{nom} (connu à {pct} %)',
    deuxBouteilles: 'À deux bouteilles',
    choixTitre: 'Ce soir, la table a choisi',
    noter: 'Le noter d\'un geste',
    note: 'noté',
    noterTitre: '{vin}, ce soir',
    noterAide: 'Un geste suffit : votre palais en tiendra compte.',
    reprendriez: 'Vous en reprendriez ?',
    oui: 'Oui', peutEtre: 'Peut-être', non: 'Non',
    racheter: { yes: 'Je le reprendrais.', maybe: 'Je le reprendrais peut-être.', no: 'Je ne le reprendrais pas.' },
    enregistrer: 'Enregistrer',
    noteEchec: 'La note n\'a pas pu être enregistrée : réessayez.',
    garderTitre: 'Garder cette soirée',
    garderAide: 'Vos goûts et vos notes de ce soir vous attendent 30 jours. Gardez-les avec un code, à saisir dans l\'app : Ce soir → Rejoindre une table → « J\'ai un code de reprise ».',
    garderBouton: 'Obtenir mon code de reprise',
    codeReprise: 'Votre code de reprise',
    installer: 'Installer l\'app',
    iphone: 'L\'app arrive bientôt sur iPhone. D\'ici là, gardez votre soirée avec le code de reprise.',
    connexionPerdue: 'Connexion perdue avec la table.',
    versionComplete: 'Vous avez un compte Chatmelier ? Ouvrir la version complète',
    comptoirTitre: 'Les verres de l\'ardoise',
    comptoirAide: 'Notez chaque verre d\'un geste : à la fin, on saura qui a aimé quoi.',
    quiAimeQuoi: 'Qui a aimé quoi',
    prefere: 'Le préféré du comptoir : {vin} ({visages}).',
    divise: 'Celui qui divise : {vin} ({visages}).',
    chacun: 'Le préféré de chacun : {liste}.',
    changer: 'changer',
    exemples: {
      tanins: 'Ce qui assèche la bouche, comme un thé trop infusé. Marqués dans un Madiran, discrets dans un Beaujolais.',
      corps: 'Le poids du vin en bouche : léger comme du lait écrémé, ou ample comme de la crème.',
      acidite: 'Ce qui fait saliver et donne de la fraîcheur, comme un zeste de citron. Vive dans un Chablis.',
      boise: 'La vanille, le toasté ou le fumé que donne l\'élevage en fût de chêne.',
      fruit: 'L\'intensité des arômes de fruits : cerise, cassis, pêche…',
      mineralite: 'Une sensation saline, de pierre mouillée ou de craie, typique d\'un Chablis ou d\'un Sancerre.',
    },
    axes: { tanins: 'Tanins', corps: 'Corps', acidite: 'Acidité', boise: 'Boisé', fruit: 'Fruit', mineralite: 'Minéralité' },
    couleursNoms: { Rouge: 'Rouge', Blanc: 'Blanc', 'Rosé': 'Rosé', Bulles: 'Bulles' },
    aversionsNoms: { tanin: 'Tanins durs', 'boisé': 'Boisé marqué', acide: 'Acidité vive' },
  },
  en: {
    codeTitre: 'Join a table',
    codeAide: 'The six-character code shown on the host\'s phone.',
    codeOk: 'Join',
    introuvable: 'This table can\'t be found or has ended. Check the code with the host.',
    reseau: 'No network right now: try again in a moment.',
    tropDeConnexions: 'Too many new connections from this network (hotel or plane Wi-Fi…): try again in a few minutes, or on mobile data.',
    serveurIndisponible: 'The server didn\'t answer ({cause}): try again in a moment.',
    reessayer: 'Try again',
    titrePage: 'Chatmelier — At the table',
    tableDe: 'Table {code} — {restaurant}',
    tableSeule: 'Table {code}',
    aTable: 'At the table',
    auComptoir: 'At the bar',
    vosGoutsAideComptoir: 'Optional: your taste shows next to your name.',
    rejoindreComptoir: 'Join the bar with my taste',
    assisComptoir: 'You\'re at the bar, {nom}.',
    personne: 'Nobody has sat down yet.',
    nePasBoire: 'not drinking',
    prenom: 'Your first name',
    vosGouts: 'Your taste, in twenty seconds',
    vosGoutsAide: 'Optional: the table will take it into account when choosing the bottle.',
    couleurs: 'Colours you enjoy',
    aversions: 'What you dislike',
    rejoindre: 'Join the table with my taste',
    justeMonPrenom: 'Just my name — I\'ll add my taste later',
    jeNeBoisPas: 'I\'m not drinking tonight',
    assis: 'You\'re at the table, {nom}.',
    assisSansGouts: 'No preferences given: the ranking ignores your taste.',
    assisSansBoire: 'You\'re not drinking tonight: the bottles are chosen for the others.',
    modifier: 'Describe my taste',
    podiumTitre: 'The three bottles that suit the table best',
    podiumAttente: 'The host is preparing the ranking: it will show up here once published.',
    accord: '{n}% match',
    devineUn: '≈: palate still guessed, {liste}. Its matches stay cautious and sharpen with every wine rated.',
    devinePlusieurs: '≈: palates still guessed, {liste}. Their matches stay cautious and sharpen with every wine rated.',
    connuA: '{nom} ({pct}% known)',
    deuxBouteilles: 'With two bottles',
    choixTitre: 'Tonight, the table chose',
    noter: 'Rate it in one tap',
    note: 'rated',
    noterTitre: '{vin}, tonight',
    noterAide: 'One tap is enough: your palate will learn from it.',
    reprendriez: 'Would you have it again?',
    oui: 'Yes', peutEtre: 'Maybe', non: 'No',
    racheter: { yes: 'I would have it again.', maybe: 'I might have it again.', no: 'I would not have it again.' },
    enregistrer: 'Save',
    noteEchec: 'The rating could not be saved: try again.',
    garderTitre: 'Keep this evening',
    garderAide: 'Your taste and tonight\'s ratings are kept for 30 days. Keep them with a code, to enter in the app: Tonight → Join a table → “I have a recovery code”.',
    garderBouton: 'Get my recovery code',
    codeReprise: 'Your recovery code',
    installer: 'Install the app',
    iphone: 'The iPhone app is coming soon. Until then, keep your evening with the recovery code.',
    connexionPerdue: 'Lost the connection to the table.',
    versionComplete: 'Have a Chatmelier account? Open the full version',
    comptoirTitre: 'The glasses on the board',
    comptoirAide: 'Rate each glass in one tap: at the end, we\'ll know who liked what.',
    quiAimeQuoi: 'Who liked what',
    prefere: 'The bar\'s favourite: {vin} ({visages}).',
    divise: 'The one that divides: {vin} ({visages}).',
    chacun: 'Everyone\'s favourite: {liste}.',
    changer: 'change',
    exemples: {
      tanins: 'What dries your mouth, like over-brewed tea. Firm in a Madiran, soft in a Beaujolais.',
      corps: 'The weight in your mouth: skimmed milk, or cream.',
      acidite: 'What makes your mouth water, like a squeeze of lemon. Lively in a Chablis.',
      boise: 'Vanilla, toast or smoky notes from ageing in oak barrels.',
      fruit: 'How much fruit you taste: cherry, blackcurrant, peach…',
      mineralite: 'A salty, wet-stone or chalky feel, typical of a Chablis or a Sancerre.',
    },
    axes: { tanins: 'Tannins', corps: 'Body', acidite: 'Acidity', boise: 'Oak', fruit: 'Fruit', mineralite: 'Minerality' },
    couleursNoms: { Rouge: 'Red', Blanc: 'White', 'Rosé': 'Rosé', Bulles: 'Sparkling' },
    aversionsNoms: { tanin: 'Firm tannins', 'boisé': 'Heavy oak', acide: 'Sharp acidity' },
  },
  es: {
    codeTitre: 'Unirse a una mesa',
    codeAide: 'El código de seis caracteres que aparece en el teléfono del anfitrión.',
    codeOk: 'Unirse',
    introuvable: 'No se encuentra esta mesa o ya ha terminado. Comprueba el código con el anfitrión.',
    reseau: 'Sin red por ahora: inténtalo de nuevo en un momento.',
    tropDeConnexions: 'Demasiadas conexiones nuevas desde esta red (wifi de hotel, de avión…): inténtalo de nuevo en unos minutos, o con datos móviles.',
    serveurIndisponible: 'El servidor no ha respondido ({cause}): inténtalo de nuevo en un momento.',
    reessayer: 'Reintentar',
    titrePage: 'Chatmelier — En la mesa',
    tableDe: 'Mesa {code} — {restaurant}',
    tableSeule: 'Mesa {code}',
    aTable: 'En la mesa',
    auComptoir: 'En la barra',
    vosGoutsAideComptoir: 'Opcional: tus gustos aparecen junto a tu nombre.',
    rejoindreComptoir: 'Unirme a la barra con mis gustos',
    assisComptoir: 'Estás en la barra, {nom}.',
    personne: 'Todavía no se ha sentado nadie.',
    nePasBoire: 'no bebe',
    prenom: 'Tu nombre',
    vosGouts: 'Tus gustos, en veinte segundos',
    vosGoutsAide: 'Opcional: la mesa los tendrá en cuenta para elegir la botella.',
    couleurs: 'Colores que te gustan',
    aversions: 'Lo que no te gusta',
    rejoindre: 'Unirme a la mesa con mis gustos',
    justeMonPrenom: 'Solo mi nombre — ya diré mis gustos',
    jeNeBoisPas: 'Esta noche no bebo',
    assis: 'Estás en la mesa, {nom}.',
    assisSansGouts: 'Sin preferencias: la clasificación no tiene en cuenta tus gustos.',
    assisSansBoire: 'Esta noche no bebes: las botellas se eligen para los demás.',
    modifier: 'Indicar mis gustos',
    podiumTitre: 'Las tres botellas que mejor van a la mesa',
    podiumAttente: 'El anfitrión prepara la clasificación: aparecerá aquí en cuanto la publique.',
    accord: '{n} % de acuerdo',
    devineUn: '≈: paladar aún estimado, {liste}. Sus afinidades siguen siendo prudentes y se afinan con cada vino valorado.',
    devinePlusieurs: '≈: paladares aún estimados, {liste}. Sus afinidades siguen siendo prudentes y se afinan con cada vino valorado.',
    connuA: '{nom} (conocido al {pct} %)',
    deuxBouteilles: 'Con dos botellas',
    choixTitre: 'Esta noche, la mesa eligió',
    noter: 'Anotarlo con un gesto',
    note: 'anotado',
    noterTitre: '{vin}, esta noche',
    noterAide: 'Un gesto basta: tu paladar lo tendrá en cuenta.',
    reprendriez: '¿Repetirías?',
    oui: 'Sí', peutEtre: 'Quizás', non: 'No',
    racheter: { yes: 'Lo repetiría.', maybe: 'Quizás lo repetiría.', no: 'No lo repetiría.' },
    enregistrer: 'Guardar',
    noteEchec: 'No se pudo guardar la nota: inténtalo de nuevo.',
    garderTitre: 'Guardar esta velada',
    garderAide: 'Tus gustos y tus notas de esta noche se guardan 30 días. Consérvalos con un código, para introducir en la app: Esta noche → Unirse a una mesa → «Tengo un código de recuperación».',
    garderBouton: 'Obtener mi código de recuperación',
    codeReprise: 'Tu código de recuperación',
    installer: 'Instalar la app',
    iphone: 'La app llegará pronto al iPhone. Mientras tanto, guarda tu velada con el código de recuperación.',
    connexionPerdue: 'Se perdió la conexión con la mesa.',
    versionComplete: '¿Tienes una cuenta de Chatmelier? Abrir la versión completa',
    comptoirTitre: 'Las copas de la pizarra',
    comptoirAide: 'Puntúa cada copa con un gesto: al final sabremos a quién le gustó qué.',
    quiAimeQuoi: 'A quién le gustó qué',
    prefere: 'El favorito de la barra: {vin} ({visages}).',
    divise: 'El que divide: {vin} ({visages}).',
    chacun: 'El favorito de cada uno: {liste}.',
    changer: 'cambiar',
    exemples: {
      tanins: 'Lo que seca la boca, como un té demasiado infusionado. Marcados en un Madiran, discretos en un Beaujolais.',
      corps: 'El peso del vino en boca: ligero como leche desnatada, o amplio como la nata.',
      acidite: 'Lo que hace salivar y da frescura, como un toque de limón. Viva en un Chablis.',
      boise: 'La vainilla, el tostado o el ahumado que da la crianza en barrica de roble.',
      fruit: 'La intensidad de los aromas de fruta: cereza, casis, melocotón…',
      mineralite: 'Una sensación salina, de piedra mojada o de tiza, típica de un Chablis o de un Sancerre.',
    },
    axes: { tanins: 'Taninos', corps: 'Cuerpo', acidite: 'Acidez', boise: 'Madera', fruit: 'Fruta', mineralite: 'Mineralidad' },
    couleursNoms: { Rouge: 'Tinto', Blanc: 'Blanco', 'Rosé': 'Rosado', Bulles: 'Espumoso' },
    aversionsNoms: { tanin: 'Taninos duros', 'boisé': 'Madera marcada', acide: 'Acidez viva' },
  },
  it: {
    codeTitre: 'Unisciti a un tavolo',
    codeAide: 'Il codice di sei caratteri mostrato sul telefono di chi ospita.',
    codeOk: 'Unisciti',
    introuvable: 'Questo tavolo non esiste o è terminato. Controlla il codice con chi ospita.',
    reseau: 'Nessuna rete per ora: riprova tra un momento.',
    tropDeConnexions: 'Troppe nuove connessioni da questa rete (wifi d\'hotel, d\'aereo…): riprova tra qualche minuto, o con i dati mobili.',
    serveurIndisponible: 'Il server non ha risposto ({cause}): riprova tra un momento.',
    reessayer: 'Riprova',
    titrePage: 'Chatmelier — A tavola',
    tableDe: 'Tavolo {code} — {restaurant}',
    tableSeule: 'Tavolo {code}',
    aTable: 'A tavola',
    auComptoir: 'Al bancone',
    vosGoutsAideComptoir: 'Facoltativo: i tuoi gusti compaiono accanto al tuo nome.',
    rejoindreComptoir: 'Unisciti al bancone con i miei gusti',
    assisComptoir: 'Sei al bancone, {nom}.',
    personne: 'Non si è ancora seduto nessuno.',
    nePasBoire: 'non beve',
    prenom: 'Il tuo nome',
    vosGouts: 'I tuoi gusti, in venti secondi',
    vosGoutsAide: 'Facoltativo: il tavolo ne terrà conto per scegliere la bottiglia.',
    couleurs: 'I colori che ami',
    aversions: 'Quello che non ti piace',
    rejoindre: 'Unisciti al tavolo con i miei gusti',
    justeMonPrenom: 'Solo il mio nome — i gusti li dirò dopo',
    jeNeBoisPas: 'Stasera non bevo',
    assis: 'Sei a tavola, {nom}.',
    assisSansGouts: 'Nessuna preferenza: la classifica non tiene conto dei tuoi gusti.',
    assisSansBoire: 'Stasera non bevi: le bottiglie si scelgono per gli altri.',
    modifier: 'Indica i miei gusti',
    podiumTitre: 'Le tre bottiglie più adatte al tavolo',
    podiumAttente: 'Chi ospita sta preparando la classifica: comparirà qui appena pubblicata.',
    accord: '{n}% di affinità',
    devineUn: '≈: palato ancora stimato, {liste}. Le sue affinità restano prudenti e si precisano a ogni vino votato.',
    devinePlusieurs: '≈: palati ancora stimati, {liste}. Le loro affinità restano prudenti e si precisano a ogni vino votato.',
    connuA: '{nom} (conosciuto al {pct}%)',
    deuxBouteilles: 'Con due bottiglie',
    choixTitre: 'Stasera il tavolo ha scelto',
    noter: 'Votalo con un gesto',
    note: 'votato',
    noterTitre: '{vin}, stasera',
    noterAide: 'Basta un gesto: il tuo palato ne terrà conto.',
    reprendriez: 'Lo riprenderesti?',
    oui: 'Sì', peutEtre: 'Forse', non: 'No',
    racheter: { yes: 'Lo riprenderei.', maybe: 'Forse lo riprenderei.', no: 'Non lo riprenderei.' },
    enregistrer: 'Salva',
    noteEchec: 'Non è stato possibile salvare il voto: riprova.',
    garderTitre: 'Conserva questa serata',
    garderAide: 'I tuoi gusti e i voti di stasera ti aspettano per 30 giorni. Conservali con un codice da inserire nell\'app: Stasera → Unisciti a un tavolo → «Ho un codice di recupero».',
    garderBouton: 'Ottieni il mio codice di recupero',
    codeReprise: 'Il tuo codice di recupero',
    installer: 'Installa l\'app',
    iphone: 'L\'app arriverà presto su iPhone. Nel frattempo, conserva la serata con il codice di recupero.',
    connexionPerdue: 'Connessione con il tavolo persa.',
    versionComplete: 'Hai un account Chatmelier? Apri la versione completa',
    comptoirTitre: 'I calici della lavagna',
    comptoirAide: 'Vota ogni calice con un gesto: alla fine sapremo a chi è piaciuto cosa.',
    quiAimeQuoi: 'A chi è piaciuto cosa',
    prefere: 'Il preferito del bancone: {vin} ({visages}).',
    divise: 'Quello che divide: {vin} ({visages}).',
    chacun: 'Il preferito di ciascuno: {liste}.',
    changer: 'cambia',
    exemples: {
      tanins: 'Ciò che asciuga la bocca, come un tè lasciato in infusione troppo a lungo. Marcati in un Madiran, discreti in un Beaujolais.',
      corps: 'Il peso del vino in bocca: leggero come il latte scremato, o ampio come la panna.',
      acidite: 'Ciò che fa salivare e dà freschezza, come una scorza di limone. Vivace in uno Chablis.',
      boise: 'La vaniglia, il tostato o l\'affumicato che dà l\'affinamento in botti di rovere.',
      fruit: 'L\'intensità dei profumi di frutta: ciliegia, ribes nero, pesca…',
      mineralite: 'Una sensazione sapida, di pietra bagnata o di gesso, tipica di uno Chablis o di un Sancerre.',
    },
    axes: { tanins: 'Tannini', corps: 'Corpo', acidite: 'Acidità', boise: 'Legno', fruit: 'Frutto', mineralite: 'Mineralità' },
    couleursNoms: { Rouge: 'Rosso', Blanc: 'Bianco', 'Rosé': 'Rosato', Bulles: 'Bollicine' },
    aversionsNoms: { tanin: 'Tannini duri', 'boisé': 'Legno marcato', acide: 'Acidità spiccata' },
  },
};
const T = TEXTES[LANGUE];
document.title = T.titrePage;

/** Un texte de la langue, avec ses {marques} remplies. */
function t(cle, valeurs = {}) {
  const brut = T[cle] ?? TEXTES.en[cle] ?? cle;
  return String(brut).replace(/\{(\w+)\}/g, (_, k) => (k in valeurs ? String(valeurs[k]) : `{${k}}`));
}

// Les archétypes sont rangés en français (la valeur du moteur de consensus) et lus dans la
// langue du lecteur.
const ARCHETYPES = {
  'Curieux & Éclectique': { en: 'Curious & eclectic', es: 'Curioso y ecléctico', it: 'Curioso ed eclettico' },
  // Les étiquettes de l'app : un hôte peut les porter, un invité doit les lire dans sa langue.
  'Amateur de Grands Rouges Puissants': { en: 'Lover of big, powerful reds', es: 'Amante de los grandes tintos potentes', it: 'Amante dei grandi rossi potenti' },
  'Adepte de Minéralité & Fraîcheur Droite': { en: 'Mineral & crisp lover', es: 'Adepto de la mineralidad y el frescor recto', it: 'Fan di mineralità e freschezza dritta' },
  'Palais Friand & Fruit Croquant': { en: 'Crunchy-fruit lover', es: 'Paladar goloso y de fruta crujiente', it: 'Palato goloso e frutto croccante' },
  'Amateur de Vins Épicés & Singuliers': { en: 'Spicy & singular wines lover', es: 'Amante de los vinos especiados y singulares', it: 'Amante dei vini speziati e singolari' },
  'Amateur de Rouges': { en: 'Red wine lover', es: 'Amante de los tintos', it: 'Amante dei rossi' },
  'Amateur de Blancs': { en: 'White wine lover', es: 'Amante de los blancos', it: 'Amante dei bianchi' },
  'Amateur de Rosés': { en: 'Rosé lover', es: 'Amante de los rosados', it: 'Amante dei rosati' },
  'Amateur de Bulles': { en: 'Sparkling wine lover', es: 'Amante de los espumosos', it: 'Amante delle bollicine' },
  'Grands Rouges Puissants': { en: 'Big, powerful reds', es: 'Grandes tintos potentes', it: 'Grandi rossi potenti' },
  'Blancs Minéraux & Tendus': { en: 'Taut, mineral whites', es: 'Blancos minerales y tensos', it: 'Bianchi minerali e tesi' },
  'Rouges Fruits Croquants': { en: 'Crunchy fruity reds', es: 'Tintos de fruta crujiente', it: 'Rossi dal frutto croccante' },
  'Aversion aux tanins durs': { en: 'Dislikes firm tannins', es: 'Aversión a los taninos duros', it: 'Avversione ai tannini duri' },
  'Sans préférences déclarées': { en: 'No stated preferences', es: 'Sin preferencias indicadas', it: 'Nessuna preferenza indicata' },
  'Ne boit pas ce soir': { en: 'Not drinking tonight', es: 'No bebe esta noche', it: 'Stasera non beve' },
};
const archetypeLu = (a) => (LANGUE === 'fr' ? a : ARCHETYPES[a]?.[LANGUE] ?? a);

// ---------------------------------------------------------------------------
// Session anonyme, ouverte au premier geste (rejoindre), gardée dans ce navigateur.
// ---------------------------------------------------------------------------
const CLE_SESSION = 'chatmelier.table.session.v1';

function lireSession() {
  try { return JSON.parse(localStorage.getItem(CLE_SESSION) || 'null'); } catch { return null; }
}
function garderSession(s) {
  try { localStorage.setItem(CLE_SESSION, JSON.stringify(s)); } catch { /* navigation privée */ }
}

function depuisReponseAuth(r) {
  return {
    access_token: r.access_token,
    refresh_token: r.refresh_token,
    expires_at: r.expires_at || Math.floor(Date.now() / 1000) + (r.expires_in || 3600),
    user_id: r.user?.id,
  };
}

async function auth(chemin, corps) {
  const res = await fetch(`${API}/auth/v1/${chemin}`, {
    method: 'POST',
    headers: { apikey: CLE, 'Content-Type': 'application/json' },
    body: JSON.stringify(corps),
  });
  if (!res.ok) throw new Error(`auth ${res.status}`);
  return depuisReponseAuth(await res.json());
}

/** Une session valide, anonyme au besoin. */
async function session() {
  let s = lireSession();
  const maintenant = Math.floor(Date.now() / 1000);
  if (s && s.expires_at - 60 > maintenant) return s;
  if (s?.refresh_token) {
    try {
      s = await auth('token?grant_type=refresh_token', { refresh_token: s.refresh_token });
      garderSession(s);
      return s;
    } catch { /* jeton périmé : nouvelle session */ }
  }
  s = await auth('signup', { data: {} });
  garderSession(s);
  return s;
}

class ErreurServeur extends Error {
  constructor(statut, message) { super(message); this.statut = statut; }
}

/** Appelle une fonction SQL. `connecte` : avec la session de l'invité. */
async function rpc(fonction, parametres = {}, { connecte = false } = {}) {
  const jeton = connecte ? (await session()).access_token : CLE;
  const res = await fetch(`${API}/rest/v1/rpc/${fonction}`, {
    method: 'POST',
    headers: { apikey: CLE, Authorization: `Bearer ${jeton}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(parametres),
  });
  const texte = await res.text();
  if (!res.ok) throw new ErreurServeur(res.status, texte);
  return texte ? JSON.parse(texte) : null;
}

/**
 * Pourquoi la page n'a pas pu rejoindre ou lire la table, en clair, et dans les journaux
 * de la console (05/10 : Gianpaolo voyait « pas de réseau », et rien n'était écrit nulle part).
 */
function causeDe(e) {
  const message = String(e?.message || e || '');
  if (message.includes('table_introuvable')) return { erreur: 'introuvable', detail: null };
  if (/^auth 429/.test(message)) return { erreur: 'tropDeConnexions', detail: 'auth 429' };
  if (/^auth \d+/.test(message)) return { erreur: 'serveurIndisponible', detail: message };
  if (e instanceof ErreurServeur) return { erreur: 'serveurIndisponible', detail: `HTTP ${e.statut}` };
  return { erreur: 'reseau', detail: message.slice(0, 120) || null };
}

function noterLEchec(etape, e, cause) {
  // Clé publique seule : la page peut journaliser même sans session (politique d'insertion anon).
  fetch(`${API}/rest/v1/app_diagnostic_logs`, {
    method: 'POST',
    headers: { apikey: CLE, Authorization: `Bearer ${CLE}`, 'Content-Type': 'application/json', Prefer: 'return=minimal' },
    body: JSON.stringify({
      tag: 'TABLE_WEB', level: 'warning', platform: 'web', app_version: 'page-table-1',
      message: `${etape} impossible (${etat.code || 'sans code'}) : ${cause.erreur}${cause.detail ? ` — ${cause.detail}` : ''}`,
      error_details: String(e?.message || e || '').slice(0, 500),
      metadata: { langue: LANGUE, en_ligne: navigator.onLine },
    }),
  }).catch(() => { /* sans réseau, rien ne part : c'est justement le cas à décrire */ });
}

async function inserer(table, ligne) {
  const s = await session();
  const res = await fetch(`${API}/rest/v1/${table}`, {
    method: 'POST',
    headers: {
      apikey: CLE,
      Authorization: `Bearer ${s.access_token}`,
      'Content-Type': 'application/json',
      Prefer: 'return=minimal',
    },
    body: JSON.stringify(ligne),
  });
  if (!res.ok) throw new ErreurServeur(res.status, await res.text());
}

/** Ce qui mène un invité web jusqu'à l'app (J6), sans donnée personnelle. */
function noterEvenement(type) {
  inserer('evenements_croissance', {
    type, source: 'page_invite', table_code: etat.code, plateforme: 'web', app_version: 'page-table-1',
  }).catch(() => { /* la mesure ne bloque jamais la soirée */ });
}

// ---------------------------------------------------------------------------
// L'état de la page
// ---------------------------------------------------------------------------
const params = new URLSearchParams(location.search);
const etat = {
  code: (params.get('t') || params.get('table') || '').trim().toUpperCase().replace(/[^A-Z0-9]/g, '').slice(0, 6),
  restaurant: '',
  convives: [],
  resultat: null,
  choix: [],
  erreur: null,
  detail: null,
  modeProfil: false,
  palais: { tanins: 5, corps: 5, acidite: 5, boise: 3, fruit: 5, mineralite: 5 },
  couleurs: new Set(),
  aversions: new Set(),
  noteEnCours: null,
  codeReprise: null,
  connexionPerdue: false,
  sansCarte: false,
  menu: null,
  prenomSaisi: '',
  empreinte: null,
};

const CLE_NOM = () => `chatmelier.table.${etat.code}.nom`;
const CLE_MODE = () => `chatmelier.table.${etat.code}.mode`;
const CLE_NOTES = () => `chatmelier.table.${etat.code}.notes`;
const CLE_PROFIL = () => `chatmelier.table.${etat.code}.profil`;
const lire = (cle, defaut) => { try { return JSON.parse(localStorage.getItem(cle)) ?? defaut; } catch { return defaut; } };
const ecrire = (cle, v) => { try { localStorage.setItem(cle, JSON.stringify(v)); } catch { /* rien */ } };

// ---------------------------------------------------------------------------
// Le petit DOM : des éléments construits, jamais du HTML assemblé avec des données
// (les prénoms et les noms de vins viennent d'ailleurs).
// ---------------------------------------------------------------------------
function el(balise, attributs = {}, ...enfants) {
  const n = document.createElement(balise);
  for (const [k, v] of Object.entries(attributs)) {
    if (v === undefined || v === null || v === false) continue;
    if (k.startsWith('on')) n.addEventListener(k.slice(2), v);
    else if (k === 'class') n.className = v;
    else n.setAttribute(k, v === true ? '' : String(v));
  }
  for (const e of enfants.flat()) {
    if (e === null || e === undefined || e === false) continue;
    n.append(e instanceof Node ? e : document.createTextNode(String(e)));
  }
  return n;
}

const racine = document.getElementById('app');
function afficher(...blocs) { racine.replaceChildren(...blocs.flat().filter(Boolean)); }
function remplacer(id, noeud) { document.getElementById(id)?.replaceWith(noeud); }

// ---------------------------------------------------------------------------
// Les écrans
// ---------------------------------------------------------------------------
function ecranCode() {
  const champ = el('input', { type: 'text', class: 'code', maxlength: 6, autocomplete: 'off', 'aria-label': t('codeTitre') });
  const aller = () => {
    const c = champ.value.trim().toUpperCase();
    if (c.length === 6) location.search = `?t=${encodeURIComponent(c)}`;
  };
  champ.addEventListener('keydown', (e) => { if (e.key === 'Enter') aller(); });
  afficher(
    el('h1', {}, t('codeTitre')),
    el('section', { class: 'carte' }, el('p', { class: 'discret' }, t('codeAide')), champ,
      el('button', { class: 'principal', onclick: aller }, t('codeOk'))),
  );
}

function ecranErreur() {
  afficher(
    el('h1', {}, t('codeTitre')),
    el('section', { class: 'carte' },
      el('p', {}, etat.erreur === 'introuvable' ? t('introuvable')
        : etat.erreur === 'tropDeConnexions' ? t('tropDeConnexions')
        : etat.erreur === 'serveurIndisponible' ? t('serveurIndisponible', { cause: etat.detail || '?' })
        : t('reseau')),
      el('button', { class: 'secondaire', onclick: () => location.reload() }, t('reessayer'))),
  );
}

function blocConvives() {
  const moi = lire(CLE_NOM(), '') || '';
  return el('section', { class: 'carte', id: 'convives' },
    el('h2', {}, t(estUnComptoir() ? 'auComptoir' : 'aTable')),
    etat.convives.length === 0
      ? el('p', { class: 'discret' }, t('personne'))
      : el('div', { class: 'convives' }, etat.convives.map((c) => el('span', {
          class: `convive${c.nom.toLowerCase() === moi.toLowerCase() ? ' moi' : ''}`,
        }, c.nom, c.neBoitPas ? ` · ${t('nePasBoire')}` : (c.archetype ? ` · ${archetypeLu(c.archetype)}` : '')))),
  );
}

/** Le radar des six curseurs, en SVG. */
function radar(p) {
  const axes = ['tanins', 'corps', 'acidite', 'boise', 'fruit', 'mineralite'];
  const cx = 90, cy = 90, r = 70;
  const point = (i, v) => {
    const a = (Math.PI * 2 * i) / axes.length - Math.PI / 2;
    return [cx + Math.cos(a) * r * (v / 10), cy + Math.sin(a) * r * (v / 10)];
  };
  const ns = 'http://www.w3.org/2000/svg';
  const svg = document.createElementNS(ns, 'svg');
  svg.setAttribute('viewBox', '0 0 180 180');
  svg.setAttribute('width', '180');
  svg.setAttribute('height', '180');
  svg.setAttribute('class', 'radar');
  svg.setAttribute('aria-hidden', 'true');
  for (const niveau of [10, 5]) {
    const g = document.createElementNS(ns, 'polygon');
    g.setAttribute('points', axes.map((_, i) => point(i, niveau).join(',')).join(' '));
    g.setAttribute('fill', 'none');
    g.setAttribute('stroke', 'rgba(255,255,255,0.15)');
    svg.append(g);
  }
  const forme = document.createElementNS(ns, 'polygon');
  forme.setAttribute('points', axes.map((a, i) => point(i, p[a]).join(',')).join(' '));
  forme.setAttribute('fill', 'rgba(212,175,55,0.3)');
  forme.setAttribute('stroke', '#D4AF37');
  forme.setAttribute('stroke-width', '2');
  svg.append(forme);
  return svg;
}

function archetype() {
  const p = etat.palais;
  if (etat.aversions.has('tanin')) return 'Aversion aux tanins durs';
  if (p.tanins >= 7 && p.corps >= 6) return 'Grands Rouges Puissants';
  if (p.acidite >= 7 && p.mineralite >= 6) return 'Blancs Minéraux & Tendus';
  if (p.fruit >= 7 && p.tanins <= 5) return 'Rouges Fruits Croquants';
  return 'Curieux & Éclectique';
}

/** Le profil envoyé à la table, au format que lit l'app (`GuestProfile.fromJson`). */
function profil(nom, { sansPreferences = false, neBoitPas = false } = {}) {
  const p = etat.palais;
  return {
    name: nom,
    archetype: neBoitPas ? 'Ne boit pas ce soir' : (sansPreferences ? 'Sans préférences déclarées' : archetype()),
    favorite_types: sansPreferences ? [] : [...etat.couleurs],
    favorite_grapes: [],
    disliked: sansPreferences ? [] : [...etat.aversions],
    ...(sansPreferences ? { sans_preferences: true } : {}),
    ...(neBoitPas ? { ne_boit_pas: true } : {}),
    radar: {
      tannin: p.tanins, body: p.corps, oak: p.boise, ripe_fruit: p.fruit,
      spice: 4, fresh_fruit: p.fruit, minerality: p.mineralite, acidity: p.acidite,
    },
  };
}

/** Un prénom libre à cette table : « Caro (2) » plutôt que d'écraser la Caro déjà assise. */
function nomLibre(nom) {
  const dejaMoi = (lire(CLE_NOM(), '') || '').toLowerCase();
  const pris = (n) => etat.convives.some((c) => c.nom.toLowerCase() === n.toLowerCase() && c.nom.toLowerCase() !== dejaMoi);
  if (!pris(nom)) return nom;
  let i = 2;
  while (pris(`${nom} (${i})`)) i++;
  return `${nom} (${i})`;
}

async function rejoindre(options) {
  const assis = lire(CLE_NOM(), '');
  const champ = document.getElementById('prenom');
  const saisi = (champ?.value || etat.prenomSaisi || assis || '').trim() || (LANGUE === 'fr' ? 'Invité' : LANGUE === 'es' ? 'Invitado' : LANGUE === 'it' ? 'Ospite' : 'Guest');
  const nom = assis || nomLibre(saisi);
  try {
    const envoye = { ...profil(nom, options), verres: lire(CLE_PROFIL(), {})?.verres || {} };
    const r = await rpc('join_table_session', { p_code: etat.code, p_guest_name: nom, p_profile: envoye }, { connecte: true });
    const ligne = Array.isArray(r) ? r[0] : r;
    if (ligne?.restaurant_name) etat.restaurant = ligne.restaurant_name;
    if (ligne?.menu) etat.menu = ligne.menu;
    ecrire(CLE_PROFIL(), envoye);
    if (!assis) noterEvenement('invite_web_arrivee');
    ecrire(CLE_NOM(), nom);
    ecrire(CLE_MODE(), options?.neBoitPas ? 'sans_boire' : options?.sansPreferences ? 'sans_gouts' : 'gouts');
    etat.modeProfil = false;
    await rafraichir();
    rendre();
    window.scrollTo({ top: 0 });
  } catch (e) {
    const cause = causeDe(e);
    etat.erreur = cause.erreur;
    etat.detail = cause.detail;
    noterLEchec('Jointure', e, cause);
    rendre();
  }
}

function blocProfil() {
  const assis = lire(CLE_NOM(), '');
  const curseurs = Object.keys(etat.palais).map((axe) => {
    const valeur = el('span', { class: 'valeur' }, etat.palais[axe]);
    const champ = el('input', {
      type: 'range', min: 0, max: 10, step: 1, value: etat.palais[axe], 'aria-label': T.axes[axe],
      oninput: (e) => { etat.palais[axe] = Number(e.target.value); valeur.textContent = e.target.value; dessin.replaceWith(dessin = radar(etat.palais)); },
    });
    return el('div', { class: 'curseur' },
      el('div', { class: 'ligne' }, el('label', {}, T.axes[axe]), valeur), champ, el('small', {}, T.exemples[axe]));
  });
  let dessin = radar(etat.palais);
  const puces = (ensemble, noms) => el('div', { class: 'puces' }, Object.entries(noms).map(([cle, libelle]) => el('button', {
    class: 'puce', 'aria-pressed': ensemble.has(cle) ? 'true' : 'false',
    onclick: (e) => { ensemble.has(cle) ? ensemble.delete(cle) : ensemble.add(cle); e.currentTarget.setAttribute('aria-pressed', ensemble.has(cle) ? 'true' : 'false'); },
  }, libelle)));
  return el('section', { class: 'carte' },
    assis ? null : el('label', { for: 'prenom' }, t('prenom')),
    assis ? null : el('input', {
      id: 'prenom', type: 'text', maxlength: 30, autocomplete: 'given-name', value: etat.prenomSaisi,
      oninput: (e) => { etat.prenomSaisi = e.target.value; },
    }),
    el('h2', {}, t('vosGouts')),
    el('p', { class: 'discret' }, t(estUnComptoir() ? 'vosGoutsAideComptoir' : 'vosGoutsAide')),
    dessin,
    curseurs,
    el('label', {}, t('couleurs')), puces(etat.couleurs, T.couleursNoms),
    el('label', {}, t('aversions')), puces(etat.aversions, T.aversionsNoms),
    el('button', { class: 'principal', onclick: () => rejoindre({}) }, t(estUnComptoir() ? 'rejoindreComptoir' : 'rejoindre')),
    assis ? null : el('button', { class: 'lien', onclick: () => rejoindre({ sansPreferences: true }) }, t('justeMonPrenom')),
    assis ? null : el('button', { class: 'lien', onclick: () => rejoindre({ sansPreferences: true, neBoitPas: true }) }, t('jeNeBoisPas')),
  );
}

function classeScore(s) { return s >= 80 ? 'bon' : s >= 60 ? 'moyen' : 'faible'; }

function blocPodium() {
  const moi = lire(CLE_NOM(), '');
  const podium = etat.resultat?.podium || [];
  if (podium.length === 0) {
    return el('div', { id: 'podium', class: 'pile' },
      el('section', { class: 'carte' }, el('h2', {}, t('podiumTitre')), el('p', { class: 'discret' }, t('podiumAttente'))));
  }
  const medailles = ['🥇', '🥈', '🥉'];
  // Un palais encore deviné (V2.3 · K5) : « ≈ » devant ses accords, et une ligne qui le dit.
  const devines = new Map((etat.resultat.convives || []).filter((c) => c.devine).map((c) => [c.nom, c.connu ?? 0]));
  const liste = [...devines].map(([nom, pct]) => t('connuA', { nom, pct })).join(', ');
  return el('div', { id: 'podium', class: 'pile' },
    el('section', { class: 'carte' },
      el('h2', {}, t('podiumTitre')),
      podium.map((v, i) => el('article', { class: 'vin' },
        el('div', { class: 'titre' },
          el('span', { class: 'nom' }, `${medailles[i] || ''} ${v.nom}${v.millesime ? ` ${v.millesime}` : ''}`),
          v.prix ? el('span', { class: 'prix' }, v.prix) : null),
        v.producteur ? el('span', { class: 'discret' }, v.producteur) : null,
        el('span', { class: 'accord' }, t('accord', { n: `${devines.size ? '≈' : ''}${v.accord}` })),
        el('p', {}, v.raisons?.[LANGUE] || v.raison || ''),
        el('div', { class: 'scores' }, Object.entries(v.scores || {}).map(([nom, s]) => el('span', {
          class: `score ${devines.has(nom) ? 'devine' : classeScore(s)}${nom === moi ? ' moi' : ''}`,
        }, `${nom} `, el('b', {}, `${devines.has(nom) ? '≈' : ''}${s}%`)))),
      )),
      devines.size ? el('p', { class: 'discret' }, t(devines.size === 1 ? 'devineUn' : 'devinePlusieurs', { liste })) : null),
    etat.resultat.paire ? el('section', { class: 'carte or' },
      el('h2', {}, `🍷🍷 ${t('deuxBouteilles')}`), el('p', {}, etat.resultat.paire.phrases?.[LANGUE] || etat.resultat.paire.phrase)) : null,
  );
}

function blocChoix() {
  if (!etat.choix.length || lire(CLE_MODE(), '') === 'sans_boire') return null;
  const notes = lire(CLE_NOTES(), {});
  const visages = ['😖', '😕', '😐', '😊', '😍'];
  const valeurs = [2.5, 4.5, 6.5, 8, 9.5];
  return el('section', { class: 'carte or' },
    el('h2', {}, t('choixTitre')),
    etat.choix.map((v) => {
      const libelle = `${v.nom}${v.millesime ? ` ${v.millesime}` : ''}`;
      if (notes[v.cle] !== undefined) {
        return el('p', {}, `${libelle} — ${visages[valeurs.indexOf(notes[v.cle])] || '✓'} ${t('note')}`);
      }
      if (etat.noteEnCours?.cle !== v.cle) {
        return el('div', { class: 'titre' }, el('span', { class: 'nom' }, libelle),
          el('button', { class: 'secondaire', onclick: () => { etat.noteEnCours = { cle: v.cle, visage: null, racheter: null }; rendre(); } }, t('noter')));
      }
      const n = etat.noteEnCours;
      return el('div', { class: 'vin' },
        el('span', { class: 'nom' }, t('noterTitre', { vin: libelle })),
        el('p', { class: 'discret' }, t('noterAide')),
        el('div', { class: 'visages' }, visages.map((f, i) => el('button', {
          class: 'visage', 'aria-pressed': n.visage === i ? 'true' : 'false', 'aria-label': `${valeurs[i]} / 10`,
          onclick: () => { n.visage = i; rendre(); },
        }, f))),
        n.visage === null ? null : el('label', {}, t('reprendriez')),
        n.visage === null ? null : el('div', { class: 'puces' }, [['yes', t('oui')], ['maybe', t('peutEtre')], ['no', t('non')]].map(([cle, lib]) => el('button', {
          class: 'puce', 'aria-pressed': n.racheter === cle ? 'true' : 'false', onclick: () => { n.racheter = n.racheter === cle ? null : cle; rendre(); },
        }, lib))),
        el('button', { class: 'principal', disabled: n.visage === null, onclick: () => enregistrerLaNote(v, valeurs[n.visage], n.racheter) }, t('enregistrer')),
      );
    }),
  );
}

/**
 * La bouteille notée entre au journal de l'invité, comme une dégustation hors cave.
 * « Vous en reprendriez ? » n'a pas de colonne : la réponse devient la note de dégustation,
 * que l'invité relira dans son journal s'il garde sa soirée.
 */
async function enregistrerAuJournal(vin, note, racheter) {
  const s = await session();
  const wineId = crypto.randomUUID();
  await inserer('wines', {
    id: wineId, name: vin.nom, producer: vin.producteur || null, vintage: vin.millesime || null,
    wine_type: vin.couleur || 'red', region: 'Autre',
  });
  const moi = lire(CLE_NOM(), '');
  await inserer('tasting_log', {
    id: crypto.randomUUID(), wine_id: wineId, user_id: s.user_id, rating: note,
    occasion: etat.restaurant || 'Restaurant', location_name: etat.restaurant || null,
    co_tasters: etat.convives.map((c) => c.nom).filter((n) => n !== moi),
    tasting_notes: racheter ? T.racheter[racheter] : null,
    is_external: true, rating_scale: 10, consumed_at: new Date().toISOString(),
  });
}

async function enregistrerLaNote(vin, note, racheter) {
  try {
    await enregistrerAuJournal(vin, note, racheter);
    const notes = lire(CLE_NOTES(), {});
    notes[vin.cle] = note;
    ecrire(CLE_NOTES(), notes);
    etat.noteEnCours = null;
    noterEvenement('invite_web_note');
    rendre();
  } catch {
    alert(t('noteEchec'));
  }
}

function blocGarder() {
  const ios = /iPhone|iPad|iPod/i.test(navigator.userAgent);
  const referrer = encodeURIComponent(`utm_source=page_invite&utm_campaign=${etat.code}`);
  const installer = el('a', {
    class: 'secondaire', href: `${PLAY_STORE}&referrer=${referrer}`, rel: 'noopener',
    onclick: () => noterEvenement('clic_installer'),
    style: 'display:block;text-align:center;text-decoration:none;padding:12px;border-radius:12px;border:1px solid var(--or);color:var(--or)',
  }, t('installer'));
  return el('section', { class: 'carte' },
    el('h2', {}, t('garderTitre')),
    el('p', { class: 'discret' }, t('garderAide')),
    (etat.codeReprise ||= codeDejaObtenu())
      ? [el('label', {}, t('codeReprise')), el('p', { class: 'code-reprise' }, etat.codeReprise)]
      : el('button', { class: 'principal', onclick: obtenirUnCode }, t('garderBouton')),
    ios ? el('p', { class: 'discret' }, t('iphone')) : installer,
  );
}

// Le code vaut pour le compte anonyme de ce navigateur, quelle que soit la table : il reste
// affiché d'une visite à l'autre plutôt que d'en tirer un nouveau.
const CLE_REPRISE = 'chatmelier.table.reprise.v1';
function codeDejaObtenu() {
  const r = lire(CLE_REPRISE, null);
  return r && r.user && r.user === lireSession()?.user_id && Date.now() < r.jusquA ? r.code : null;
}

async function obtenirUnCode() {
  try {
    etat.codeReprise = await rpc('creer_code_de_reprise', {}, { connecte: true });
    ecrire(CLE_REPRISE, { code: etat.codeReprise, user: lireSession()?.user_id, jusquA: Date.now() + 30 * 86400000 });
    noterEvenement('soiree_gardee');
  } catch {
    etat.codeReprise = null;
    alert(t('reseau'));
  }
  rendre();
}

// ---------------------------------------------------------------------------
// Le comptoir à plusieurs (V2.3 · J4) : autour d'une ardoise, chacun note chaque verre.
// ---------------------------------------------------------------------------
const estUnComptoir = () => etat.menu?.ardoise === true;
const VISAGES = ['😖', '😕', '😐', '😊', '😍'];
const NOTES_DES_VISAGES = [2.5, 4.5, 6.5, 8, 9.5];
// Les seuils de `TastingQuestionnaireResult.emojiIndexForRating`.
const visageDe = (n) => VISAGES[n >= 9 ? 4 : n >= 7.5 ? 3 : n >= 5.5 ? 2 : n >= 3.5 ? 1 : 0];
// La clé de `MenuWine.cacheKey` : la même chez l'hôte et chez chaque invité.
const cleDuVin = (w) => `${String(w.name || '').trim().toLowerCase()}__${String(w.producer || '').trim().toLowerCase()}__${w.vintage ?? 0}__${String(w.wine_type || '').trim().toLowerCase()}`;
const nomDuVin = (w) => `${w.name}${w.vintage ? ` ${w.vintage}` : ''}`;

function prixDuVerre(w) {
  const g = Array.isArray(w.glass_prices) ? w.glass_prices[0] : null;
  const devise = etat.menu?.currency;
  const f = (p) => (devise ? new Intl.NumberFormat(LANGUE, { style: 'currency', currency: devise, maximumFractionDigits: p % 1 ? 2 : 0 }).format(p) : String(p));
  if (g && g.price > 0) return `${f(g.price)}/${g.format}`;
  return w.bottle_price > 0 ? f(w.bottle_price) : '';
}

/** Prénom → note, pour chaque verre ; mes notes viennent d'ici, celles des autres du serveur. */
function notesDuComptoir() {
  const moi = lire(CLE_NOM(), '');
  const mesVerres = lire(CLE_PROFIL(), {})?.verres || {};
  const parVin = {};
  for (const w of etat.menu?.wines || []) {
    const cle = cleDuVin(w);
    const notes = {};
    for (const c of etat.convives) {
      if (c.neBoitPas || c.nom === moi) continue;
      const n = Number(c.verres?.[cle]);
      if (Number.isFinite(n)) notes[c.nom] = n;
    }
    if (moi && Number.isFinite(Number(mesVerres[cle]))) notes[moi] = Number(mesVerres[cle]);
    parVin[cle] = notes;
  }
  return parVin;
}

/** Le bilan, comme `BilanDuComptoir.phrases` dans l'app. */
function bilanDuComptoir(parVin) {
  const vins = (etat.menu?.wines || []).map((w) => ({ w, notes: parVin[cleDuVin(w)] || {} }))
    .filter((v) => Object.keys(v.notes).length > 0);
  const moyenne = (v) => { const n = Object.values(v.notes); return n.reduce((a, b) => a + b, 0) / n.length; };
  const ecart = (v) => { const n = Object.values(v.notes); return n.length < 2 ? 0 : Math.max(...n) - Math.min(...n); };
  const visages = (v) => Object.entries(v.notes).sort((a, b) => b[1] - a[1]).map(([nom, n]) => `${visageDe(n)} ${nom}`).join(', ');
  let prefere = null;
  for (const v of vins) {
    if (Object.keys(v.notes).length < 2) continue;
    if (!prefere || moyenne(v) > moyenne(prefere) || (moyenne(v) === moyenne(prefere) && Object.keys(v.notes).length > Object.keys(prefere.notes).length)) prefere = v;
  }
  let divise = null;
  for (const v of vins) if (ecart(v) >= 4 && (!divise || ecart(v) > ecart(divise))) divise = v;
  const chacun = {};
  for (const v of vins) for (const [nom, n] of Object.entries(v.notes)) if (!chacun[nom] || n > chacun[nom].n) chacun[nom] = { v, n };
  return [
    prefere ? t('prefere', { vin: nomDuVin(prefere.w), visages: visages(prefere) }) : null,
    divise && divise !== prefere ? t('divise', { vin: nomDuVin(divise.w), visages: visages(divise) }) : null,
    Object.keys(chacun).length >= 2
      ? t('chacun', { liste: Object.entries(chacun).map(([nom, { v }]) => `${nom}, ${nomDuVin(v.w)}`).join(' · ') })
      : null,
  ].filter(Boolean);
}

function blocComptoir() {
  const parVin = notesDuComptoir();
  const moi = lire(CLE_NOM(), '');
  const bilan = bilanDuComptoir(parVin);
  return [
    bilan.length ? el('section', { class: 'carte or' }, el('h2', {}, t('quiAimeQuoi')), bilan.map((p) => el('p', {}, p))) : null,
    el('section', { class: 'carte' },
      el('h2', {}, t('comptoirTitre')),
      el('p', { class: 'discret' }, t('comptoirAide')),
      (etat.menu?.wines || []).map((w) => {
        const cle = cleDuVin(w);
        const notes = parVin[cle] || {};
        const miens = notes[moi];
        const autres = Object.entries(notes).filter(([nom]) => nom !== moi);
        const enCours = etat.verreEnCours === cle;
        return el('article', { class: 'vin' },
          el('div', { class: 'titre' }, el('span', { class: 'nom' }, nomDuVin(w)), el('span', { class: 'prix' }, prixDuVerre(w))),
          w.producer ? el('span', { class: 'discret' }, w.producer) : null,
          autres.length ? el('div', { class: 'scores' }, autres.map(([nom, n]) => el('span', { class: 'score' }, `${visageDe(n)} ${nom}`))) : null,
          miens !== undefined && !enCours
            ? el('button', { class: 'lien', onclick: () => { etat.verreEnCours = cle; rendre(); } }, `${visageDe(miens)} ${t('note')} · ${t('changer')}`)
            : el('div', { class: 'visages' }, VISAGES.map((f, i) => el('button', {
                class: 'visage', 'aria-label': `${NOTES_DES_VISAGES[i]} / 10`,
                onclick: () => noterUnVerre(w, NOTES_DES_VISAGES[i]),
              }, f))),
        );
      }),
    ),
  ];
}

/** Un verre noté : au journal de l'invité, et dans son profil à table pour les autres. */
async function noterUnVerre(w, note) {
  try {
    await enregistrerAuJournal({ nom: w.name, producteur: w.producer, millesime: w.vintage, couleur: w.wine_type || 'red' }, note, null);
    const profilEnvoye = lire(CLE_PROFIL(), null) || profil(lire(CLE_NOM(), '') || 'Invité', { sansPreferences: true });
    const avecLaNote = { ...profilEnvoye, verres: { ...(profilEnvoye.verres || {}), [cleDuVin(w)]: note } };
    await rpc('join_table_session', { p_code: etat.code, p_guest_name: lire(CLE_NOM(), ''), p_profile: avecLaNote }, { connecte: true });
    ecrire(CLE_PROFIL(), avecLaNote);
    etat.verreEnCours = null;
    noterEvenement('invite_web_note');
    rendre();
    await rafraichir().catch(() => {});
  } catch {
    alert(t('noteEchec'));
  }
}

/**
 * La version complète (l'app Flutter sur le web) : pour se connecter à son compte, ou
 * départager la table au matchmaker. Elle reste en secours de cette page.
 */
function lienVersionComplete() {
  return el('p', { class: 'discret', style: 'text-align:center' },
    el('a', { href: `../table-consensus?table=${encodeURIComponent(etat.code)}`, style: 'color:inherit' }, t('versionComplete')));
}

function rendre() {
  if (!etat.code) return ecranCode();
  if (etat.erreur) return ecranErreur();
  const assis = lire(CLE_NOM(), '');
  const mode = lire(CLE_MODE(), '');
  const entete = el('h1', {}, etat.restaurant
    ? t('tableDe', { code: etat.code, restaurant: etat.restaurant })
    : t('tableSeule', { code: etat.code }));
  const bandeau = etat.connexionPerdue ? el('div', { class: 'bandeau' }, t('connexionPerdue'),
    el('button', { class: 'lien', onclick: () => { sondage.reprendre(); } }, t('reessayer'))) : null;
  if (!assis || etat.modeProfil) {
    return afficher(entete, bandeau, blocConvives(), blocProfil(),
      assis || estUnComptoir() ? null : blocPodium(), assis ? null : lienVersionComplete());
  }
  afficher(
    entete,
    bandeau,
    el('section', { class: 'carte' },
      el('p', {}, t(estUnComptoir() ? 'assisComptoir' : 'assis', { nom: assis })),
      mode === 'sans_boire' ? el('p', { class: 'discret' }, t('assisSansBoire'))
        // Au comptoir, pas de classement : la phrase n'aurait pas de sens.
        : mode === 'sans_gouts' && !estUnComptoir() ? el('p', { class: 'discret' }, t('assisSansGouts')) : null,
      el('button', { class: 'lien', onclick: () => { etat.modeProfil = true; rendre(); } }, t('modifier'))),
    estUnComptoir() ? blocComptoir() : [blocChoix(), blocPodium()],
    blocConvives(),
    blocGarder(),
    lienVersionComplete(),
  );
}

// ---------------------------------------------------------------------------
// Le sondage de la table : espacé quand le réseau manque, en pause en arrière-plan.
// ---------------------------------------------------------------------------
async function rafraichir() {
  const [carte, convives, etatTable] = await Promise.all([
    // `lire_carte_de_table` (054) ne sert qu'au nom du restaurant : sans elle, la page le
    // lit au moment de rejoindre. Une table inconnue se signale par la liste des convives.
    etat.restaurant || etat.sansCarte ? null : rpc('lire_carte_de_table', { p_code: etat.code }).catch((e) => {
      if (e instanceof ErreurServeur && e.statut === 404) etat.sansCarte = true;
      return null;
    }),
    rpc('read_table_session_guests', { p_code: etat.code }),
    // Absente tant que la migration 057 n'est pas appliquée : la page reste utilisable.
    rpc('lire_etat_table', { p_code: etat.code }).catch(() => null),
  ]);
  if (carte !== null) {
    const ligne = Array.isArray(carte) ? carte[0] : carte;
    if (!ligne) throw new ErreurServeur(404, 'table_introuvable');
    etat.restaurant = ligne.restaurant_name || ligne.menu?.restaurant_name || 'Restaurant';
    if (ligne.menu) etat.menu = ligne.menu;
  }
  etat.convives = (convives || []).map((g) => ({
    nom: g.guest_name,
    archetype: g.profile?.archetype || '',
    neBoitPas: g.profile?.ne_boit_pas === true,
    verres: g.profile?.verres && typeof g.profile.verres === 'object' ? g.profile.verres : {},
  }));
  const e = Array.isArray(etatTable) ? etatTable[0] : etatTable;
  etat.resultat = e?.resultat || null;
  etat.choix = Array.isArray(e?.choix) ? e.choix : [];

  const empreinte = JSON.stringify([etat.restaurant, etat.convives, etat.resultat, etat.choix, Boolean(etat.menu)]);
  if (empreinte === etat.empreinte) return;
  etat.empreinte = empreinte;
  if (!lire(CLE_NOM(), '') || etat.modeProfil) {
    // Le formulaire ne bouge pas sous les doigts de l'invité : seuls la table et le podium.
    if (estUnComptoir()) return remplacer('convives', blocConvives());
    remplacer('convives', blocConvives());
    remplacer('podium', blocPodium());
  } else {
    rendre();
  }
}

const sondage = {
  delais: [6000, 12000, 24000, 60000],
  echecs: 0,
  minuteur: null,
  async tour() {
    clearTimeout(this.minuteur);
    if (document.hidden) return;
    try {
      await rafraichir();
      if (this.echecs >= 5 || etat.connexionPerdue) { etat.connexionPerdue = false; rendre(); }
      this.echecs = 0;
    } catch (e) {
      if (String(e.message || '').includes('table_introuvable')) { etat.erreur = 'introuvable'; return rendre(); }
      this.echecs++;
      if (this.echecs === 5) { etat.connexionPerdue = true; rendre(); }
    }
    this.minuteur = setTimeout(() => this.tour(), this.delais[Math.min(this.echecs, this.delais.length - 1)]);
  },
  reprendre() { this.echecs = 0; etat.connexionPerdue = false; this.tour(); },
};
document.addEventListener('visibilitychange', () => { if (!document.hidden) sondage.tour(); });

// ---------------------------------------------------------------------------
async function demarrer() {
  if (!API || !CLE) { etat.erreur = 'reseau'; return rendre(); }
  if (!etat.code) return rendre();
  try {
    await rafraichir();
    rendre();
  } catch (e) {
    const cause = causeDe(e);
    etat.erreur = cause.erreur;
    etat.detail = cause.detail;
    noterLEchec('Lecture de la table', e, cause);
    return rendre();
  }
  sondage.minuteur = setTimeout(() => sondage.tour(), sondage.delais[0]);
}

demarrer();
