import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0'

// Les petites tâches IA de l'app, côté serveur (V2.3 · C2). Fichier autonome : il se déploie
// d'un seul fichier depuis l'éditeur du Dashboard.
//
// Jusqu'ici ces tâches appelaient Google depuis le téléphone, avec une clé embarquée dans
// l'app. Cette clé a été retirée le 14/09 (S0) : depuis, l'import Excel rendait une liste
// vide, et les notes dictées, le récit de la bouteille, la synthèse de table et la lecture
// d'un meuble en photo retombaient en silence sur des heuristiques.
//
// Ce n'est pas un relais Gemini générique : chaque tâche a ses consignes, fixées ici, et
// ses entrées sont bornées. L'app n'envoie que des données.

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
}

const GEMINI_BASE = Deno.env.get('GEMINI_BASE_URL') ?? 'https://generativelanguage.googleapis.com'

// Réglage par défaut de chaque tâche, en famille de modèles ; app_config.modeles_ia.<tâche>
// le remplace (nom exact choisi par le banc d'essai). Les tâches d'extraction partent sur
// Flash-Lite, comme avant côté app.
const REGLAGES: Record<string, Reglage> = {
  notes_degustation: { modele: 'flash-lite', reflexion: 'minimal' },
  recit: { modele: 'flash', reflexion: 'low' },
  synthese_table: { modele: 'flash', reflexion: 'low' },
  meuble: { modele: 'flash', reflexion: 'low' },
  import_cave: { modele: 'flash-lite', reflexion: 'minimal' },
  // Identifier un vin depuis un nom : Flash, pas Flash-Lite (V2.4 · R1).
  fiche_texte: { modele: 'flash', reflexion: 'low' },
  enrichir_fiche: { modele: 'flash', reflexion: 'low' },
  // Flash, pas Flash-Lite : le 07/10, Flash-Lite a fait d'un vin marocain un Côtes du Rhône (V2.4 · R1).
  vin_depuis_texte: { modele: 'flash', reflexion: 'low' },
  // Traduire une fiche lue dans une autre langue (V2.4 · R6) : une traduction, pas une
  // création, Flash-Lite suffit.
  traduire_fiche: { modele: 'flash-lite', reflexion: 'minimal' },
}

// Le quota de chaque tâche (consommer_quota_ia) : l'import d'une grande cave compte à part.
const QUOTAS: Record<string, string> = { import_cave: 'import_cave', traduire_fiche: 'traduction' }

type Langue = 'fr' | 'en' | 'es' | 'it'
function langueDe(code: unknown): Langue {
  const c = String(code ?? 'fr').toLowerCase()
  if (c.startsWith('fr')) return 'fr'
  if (c.startsWith('es')) return 'es'
  if (c.startsWith('it')) return 'it'
  return 'en'
}
const EN_LANGUE: Record<Langue, string> = { fr: 'en français', en: 'in English', es: 'en español', it: 'in italiano' }
const VERS_LA_LANGUE: Record<Langue, string> = { fr: 'into French', en: 'into English', es: 'into Spanish', it: 'into Italian' }

function texte(v: unknown, max: number): string {
  return typeof v === 'string' ? v.trim().slice(0, max) : ''
}
function liste(v: unknown, n: number, max: number): string[] {
  return Array.isArray(v) ? v.filter((x) => typeof x === 'string').slice(0, n).map((x: string) => x.trim().slice(0, max)) : []
}
function entier(v: unknown): number | null {
  return typeof v === 'number' && Number.isInteger(v) ? v : null
}

// >>> Modèles Gemini : bloc commun aux fonctions (source : tool/fonctions/bloc_modeles_gemini.ts) >>>
// Recopié dans chaque fonction par `python3 tool/fonctions/synchroniser.py` : le déploiement
// par le Dashboard demande un fichier unique. Ne pas le modifier ici, mais dans la source.
//
// Aucun numéro de version de Gemini n'est écrit dans ce code (V2.3 · K8). Le réglage d'une
// tâche vient de app_config.modeles_ia : soit un nom exact (« gemini-3.1-flash-lite »),
// choisi par le banc d'essai, soit une famille (« flash », « flash-lite », « pro ») : le plus
// récent modèle stable de cette famille que Google publie. Si le modèle réglé échoue (retiré,
// saturé), le plus récent de sa famille prend le relais, puis celui de l'autre famille, trois
// modèles au plus. Un niveau de réflexion refusé par un modèle monte d'un cran. Gemini 3.9,
// 4.0… arrivent sans toucher au code : le banc les essaie d'office, et une ligne de
// app_config les adopte.
//
// Un modèle que Google ne connaît plus (404 : retiré, ou nom mal écrit dans app_config) est
// écarté six heures sans être rappelé à chaque requête, et signalé au journal des erreurs de
// la console (« IA_MODELE ») : le relais sert, mais le réglage est à changer.

type Reglage = { modele: string; reflexion: string | null }
type AppelReussi = { data: any; modele: string; reflexion: string | null }

const FAMILLES_GEMINI = ['flash-lite', 'flash', 'pro']
const NIVEAUX_DE_REFLEXION = ['minimal', 'low', 'medium', 'high']
const MODELES_ESSAYES_AU_PLUS = 3
const SIX_HEURES = 6 * 3600_000
let catalogueDesModeles: { quand: number; modeles: string[] } | null = null
const niveauxRetenus = new Map<string, string | null>()
const modelesIntrouvables = new Map<string, number>()

function estIntrouvable(modele: string): boolean {
  const quand = modelesIntrouvables.get(modele)
  return quand !== undefined && Date.now() - quand < SIX_HEURES
}

function familleDe(nom: string): string {
  return FAMILLES_GEMINI.find((f) => nom === f || nom.includes(`-${f}`)) ?? 'flash'
}

function versionDe(nom: string): number[] {
  const m = /^gemini-(\d+(?:\.\d+)*)-/.exec(nom)
  return m ? m[1].split('.').map(Number) : []
}

function plusRecentDabord(a: string, b: string): number {
  const va = versionDe(a)
  const vb = versionDe(b)
  for (let i = 0; i < Math.max(va.length, vb.length); i++) {
    const d = (vb[i] ?? 0) - (va[i] ?? 0)
    if (d !== 0) return d
  }
  return 0
}

// Stable : « gemini-<version>-<famille> », sans préversion, ni date, ni variante (tts, live…).
function estUnModeleStable(nom: string): boolean {
  return /^gemini-\d+(?:\.\d+)*-(flash-lite|flash|pro)$/.test(nom)
}

// Une famille (« flash ») se résout par la liste ; un nom (« gemini-… ») se prend tel quel.
function estUneFamille(reglage: string): boolean {
  return FAMILLES_GEMINI.includes(reglage)
}

async function modelesStables(apiKey: string): Promise<string[]> {
  if (catalogueDesModeles && Date.now() - catalogueDesModeles.quand < SIX_HEURES) return catalogueDesModeles.modeles
  try {
    const res = await fetch(`${GEMINI_BASE}/v1beta/models?pageSize=1000`, {
      headers: { 'x-goog-api-key': apiKey },
      signal: AbortSignal.timeout(5_000),
    })
    if (!res.ok) throw new Error(`liste des modèles : ${res.status}`)
    const data = await res.json()
    const modeles = (Array.isArray(data.models) ? data.models : [])
      .filter((m: any) => Array.isArray(m.supportedGenerationMethods) && m.supportedGenerationMethods.includes('generateContent'))
      .map((m: any) => String(m.name ?? '').replace(/^models\//, ''))
      .filter(estUnModeleStable)
      .sort(plusRecentDabord)
    catalogueDesModeles = { quand: Date.now(), modeles }
    return modeles
  } catch (e) {
    console.warn('Liste des modèles indisponible :', e instanceof Error ? e.message : e)
    return []
  }
}

// Les relais, du plus proche au plus lointain : le plus récent de la famille, puis celui de
// l'autre famille ; sans liste, l'alias « -latest » que Google tient à jour.
async function modelesDeRelais(apiKey: string, reglage: string, dejaEssayes: Set<string>): Promise<string[]> {
  const famille = familleDe(reglage)
  const autre = famille === 'flash-lite' ? 'flash' : 'flash-lite'
  const stables = await modelesStables(apiKey)
  const libre = (m: string) => !dejaEssayes.has(m) && !estIntrouvable(m)
  const premier = (f: string) => stables.find((m) => familleDe(m) === f && libre(m))
  const relais = [premier(famille), premier(autre)].filter((m): m is string => !!m)
  if (relais.length > 0) return relais
  return [`gemini-${famille}-latest`].filter(libre)
}

// Le cran de réflexion au-dessus ; après « high », sans réglage ; sans réglage, plus rien.
function niveauAuDessus(niveau: string | null): string | null | undefined {
  if (niveau === null) return undefined
  const i = NIVEAUX_DE_REFLEXION.indexOf(niveau)
  return i >= 0 && i < NIVEAUX_DE_REFLEXION.length - 1 ? NIVEAUX_DE_REFLEXION[i + 1] : null
}

// Appelle Gemini pour une tâche : le modèle réglé, puis ses relais. `corpsPour(niveau)`
// construit le corps de la requête (niveau nul : sans thinkingConfig). `utilisable(data)`,
// s'il est donné, écarte une réponse vide ou illisible : le modèle suivant prend la main.
// Le modèle rendu est celui que Google a réellement servi (modelVersion), pour le tarif.
async function appelerGemini(
  apiKey: string,
  reglage: Reglage,
  corpsPour: (niveau: string | null) => Record<string, unknown>,
  delaiMs: number,
  utilisable?: (data: any) => boolean,
): Promise<AppelReussi> {
  const essayes = new Set<string>()
  const introuvables: string[] = []
  let appels = 0
  let derniereErreur: unknown = null
  const famille = estUneFamille(reglage.modele)
  const candidats = famille ? await modelesDeRelais(apiKey, reglage.modele, essayes) : [reglage.modele]
  let relaisAjoutes = famille
  for (let i = 0; appels < MODELES_ESSAYES_AU_PLUS; i++) {
    if (i === candidats.length) {
      if (relaisAjoutes) break
      relaisAjoutes = true
      candidats.push(...(await modelesDeRelais(apiKey, reglage.modele, essayes)))
      if (i === candidats.length) break
    }
    const modele = candidats[i]
    essayes.add(modele)
    // Déjà introuvable dans cette instance : le relais, sans rappeler Google.
    if (estIntrouvable(modele)) continue
    appels++
    let niveau: string | null | undefined = niveauxRetenus.has(modele) ? niveauxRetenus.get(modele)! : reglage.reflexion
    while (niveau !== undefined) {
      try {
        const res = await fetch(`${GEMINI_BASE}/v1beta/models/${modele}:generateContent`, {
          method: 'POST',
          // La clé voyage dans l'en-tête, pas dans l'adresse : un message d'erreur réseau cite l'adresse.
          headers: { 'Content-Type': 'application/json', 'x-goog-api-key': apiKey },
          body: JSON.stringify(corpsPour(niveau)),
          signal: AbortSignal.timeout(delaiMs),
        })
        if (res.ok) {
          const data = await res.json()
          if (utilisable && !utilisable(data)) {
            console.warn(`Model ${modele} : réponse vide ou illisible`)
            derniereErreur = new Error(`Model ${modele} : réponse vide`)
            niveau = undefined
            continue
          }
          niveauxRetenus.set(modele, niveau)
          const servi = typeof data.modelVersion === 'string' && data.modelVersion
            ? data.modelVersion.replace(/^models\//, '')
            : modele
          await signalerDesModelesIntrouvables(introuvables, servi)
          return { data, modele: servi, reflexion: niveau }
        }
        const texte = await res.text()
        console.warn(`Model ${modele} (réflexion ${niveau ?? 'par défaut'}) returned ${res.status}: ${texte.slice(0, 300)}`)
        derniereErreur = new Error(`Model ${modele} error (${res.status})`)
        if (res.status === 404) {
          modelesIntrouvables.set(modele, Date.now())
          introuvables.push(modele)
        }
        // Un niveau de réflexion refusé : le cran au-dessus, puis sans réglage.
        niveau = res.status === 400 && niveau !== null && /thinking/i.test(texte) ? niveauAuDessus(niveau) : undefined
      } catch (e) {
        console.warn(`Model ${modele} failed:`, e instanceof Error ? e.message : e)
        derniereErreur = e
        niveau = undefined
      }
    }
  }
  await signalerDesModelesIntrouvables(introuvables, null)
  throw derniereErreur || new Error('All Gemini models failed')
}

// Une ligne au journal des erreurs de la console (admin_erreurs, tag IA_MODELE) : une fois
// par modèle et par instance, puisqu'il est ensuite écarté. Rien de personnel n'y figure.
async function signalerDesModelesIntrouvables(introuvables: string[], servi: string | null): Promise<void> {
  const url = Deno.env.get('SUPABASE_URL')
  const cle = Deno.env.get('SUPABASE_ANON_KEY')
  if (introuvables.length === 0 || !url || !cle) return
  const message = `Modèle réglé introuvable chez Google (retiré, ou mal écrit dans app_config.modeles_ia) : ${introuvables.join(', ')}. ` +
    (servi ? `Le relais ${servi} a répondu. ` : 'Aucun relais n\'a répondu. ') +
    'Relancer le banc d\'essai et appliquer sa ligne SQL.'
  try {
    const { error } = await createClient(url, cle, { auth: { persistSession: false } })
      .from('app_diagnostic_logs')
      .insert({ tag: 'IA_MODELE', level: servi ? 'warning' : 'error', message, platform: 'serveur',
                metadata: { introuvables, servi } })
      .abortSignal(AbortSignal.timeout(3_000))
    if (error) console.warn('Signalement non écrit :', error.message)
  } catch (e) {
    console.warn('Signalement non écrit :', e instanceof Error ? e.message : e)
  }
}

// Le texte d'une réponse, sans les pensées du modèle.
function texteDeLaReponse(data: any): string {
  return data?.candidates?.[0]?.content?.parts?.filter((p: any) => !p.thought).map((p: any) => p.text ?? '').join('') ?? ''
}
// <<< Modèles Gemini <<<

function lireJson(raw: string): any {
  let t = raw
  if (t.includes('```json')) t = t.split('```json')[1].split('```')[0].trim()
  else if (t.includes('```')) t = t.split('```')[1].split('```')[0].trim()
  try {
    return JSON.parse(t)
  } catch {
    const r = t.replace(/,\s*([\}\]])/g, '$1')
    const debutObjet = r.indexOf('{')
    const debutTableau = r.indexOf('[')
    const tableau = debutTableau !== -1 && (debutObjet === -1 || debutTableau < debutObjet)
    const debut = tableau ? debutTableau : debutObjet
    const fin = tableau ? r.lastIndexOf(']') : r.lastIndexOf('}')
    if (debut !== -1 && fin > debut) return JSON.parse(r.substring(debut, fin + 1))
    throw new Error('Réponse non JSON')
  }
}

interface Consigne {
  parts: any[]
  enJson: boolean
  // Recherche Google : seulement pour la vérification d'une fiche contradictoire, que l'app
  // borne elle-même (GroundedVerificationBudget : jamais deux fois le même vin, 5 par jour).
  recherche?: boolean
}

// ─── Les consignes, tâche par tâche (reprises de l'app, V2.2) ─────────────────────
function consigne(tache: string, e: any, langue: Langue): Consigne | string {
  switch (tache) {
    case 'notes_degustation': {
      const parole = texte(e.texte, 4000)
      if (!parole) return 'texte vide'
      const noms = liste(e.degustateurs, 12, 40)
      const type = texte(e.type_vin, 40).toLowerCase()
      const rouge = type.includes('rouge') || type.includes('red') || type.includes('tinto')
      const aromes = liste(e.aromes, 80, 40)
      return {
        enJson: true,
        parts: [{ text: `Tu es le sommelier de Chatmelier.
L'utilisateur te transmet une retranscription vocale ou des notes libres de dégustation saisies à table :
"${parole}"

Le vin dégusté est : "${texte(e.nom_vin, 200)}" (Type : ${type}).
Les dégustateurs présents sont : ${noms.join(', ')}.

TÂCHE :
Analyse le texte et extrais pour chaque personne mentionnée (ou pour le dégustateur principal si une seule personne est évoquée) :
1. "profile_name" : nom du dégustateur (au plus proche de l'un de : ${noms.join(', ')}).
2. "note" : note sur 10 (1.0 à 10.0). Si elle n'est pas dite, déduis-la du sentiment ("adoré" → 8.5, "correct" → 6.5, "moyen" → 5.0).
3. "emoji_impression" : entier de 0 à 4 (0=😖, 1=😕, 2=😐, 3=😊, 4=😍).
4. "aromas" : identifiants d'arômes UNIQUEMENT parmi : ${JSON.stringify(aromes)}.
5. "acidity" : 0.0 (mou) à 1.0 (vif). Défaut 0.5.
6. ${rouge ? '"tannins" : 0.0 (soyeux) à 1.0 (très tannique). Défaut 0.5.' : '"mineralite" : 0.0 à 1.0 (minéralité et tension). Défaut 0.5.'}
7. "body" : 0.0 (léger) à 1.0 (puissant). Défaut 0.5.
8. "length" : 0.0 (court) à 1.0 (persistant). Défaut 0.5.
9. "raw_comment" : une phrase qui résume le commentaire de cette personne, ${EN_LANGUE[langue]}.

Fournis aussi un "summary" global d'une phrase, ${EN_LANGUE[langue]}.

Réponds STRICTEMENT par un objet JSON :
{"summary": "...", "tasters": [{"profile_name": "...", "note": 8.5, "emoji_impression": 3, "aromas": [], "acidity": 0.5, ${rouge ? '"tannins": 0.6' : '"mineralite": 0.7'}, "body": 0.6, "length": 0.7, "raw_comment": "..."}]}` }],
      }
    }
    case 'recit': {
      const nom = texte(e.nom, 200)
      if (!nom) return 'nom vide'
      return {
        enJson: true,
        parts: [{ text: `Tu es un sommelier érudit et conteur passionné.
Pour le vin suivant servi à table :
- Vin : ${nom}
- Domaine / Producteur : ${texte(e.producteur, 120) || 'Inconnu'}
- Millésime : ${entier(e.millesime) ?? 'non précisé'}
- Région / Appellation : ${texte(e.region, 80)} ${texte(e.appellation, 80)}
- Cépages : ${liste(e.cepages, 8, 40).join(', ') || 'Non spécifiés'}
- Type : ${texte(e.type, 30) || 'non précisé'}

Écris ${EN_LANGUE[langue]} de courtes anecdotes captivantes et élégantes, pour le maître de maison qui raconte la bouteille à ses invités :
1. "terroir_and_grape" : le terroir et la typicité des cépages (1 à 2 phrases).
2. "vintage_climate" : le millésime et son contexte climatique marquant (1 à 2 phrases). Si tu ne connais pas ce millésime, dis ce qui caractérise en général les millésimes de cette région, sans inventer de chiffres.
3. "sommelier_tip" : le conseil du sommelier pour l'apprécier à table.
4. "fun_fact" : une anecdote historique ou insolite sur le domaine, la région ou ce style de vin. N'invente pas de fait précis sur le domaine si tu n'en es pas sûr : parle alors de la région.

Réponds STRICTEMENT par un objet JSON :
{"terroir_and_grape": "...", "vintage_climate": "...", "sommelier_tip": "...", "fun_fact": "..."}` }],
      }
    }
    case 'synthese_table': {
      const avis = liste(e.avis, 12, 300)
      if (avis.length === 0) return 'aucun avis'
      return {
        enJson: false,
        parts: [{ text: `Tu es un sommelier qui anime une table d'amis.
Voici les avis enregistrés pour la dégustation de "${texte(e.nom_vin, 200)}" :
${avis.join('; ')}

Rédige ${EN_LANGUE[langue]} la synthèse de la table en 1 ou 2 phrases vivantes et élégantes :
- dis si le vin a fait l'unanimité ou a créé un débat ;
- mets en lumière les accords ou les contrastes de perception (notes, fraîcheur, arômes) ;
- donne la note moyenne de la table.
Reste concis et chaleureux. Pas de puces, pas de JSON : juste le texte.` }],
      }
    }
    case 'meuble': {
      const image = texte(e.imageBase64, 7_000_000)
      if (!image) return 'image vide'
      return {
        enJson: true,
        parts: [
          { inlineData: { mimeType: texte(e.mimeType, 30) || 'image/jpeg', data: image } },
          { text: `Tu es un architecte et sommelier expert en aménagement de cave à vin.
Analyse cette photo de meuble, casier, étagère ou croisillon de rangement de vin.

Détecte la géométrie exacte du meuble :
1. "shape_type" : "rectangle" (grille complète), "triangle" (casier pyramide), "staggered_4_2" (rangées décalées) ou "custom" (disposition irrégulière).
2. "columns" : nombre de colonnes (bouteilles en largeur), 15 au plus.
3. "rows" : nombre de rangées en hauteur, 15 au plus.
4. "name" : un nom concis ${EN_LANGUE[langue]} (ex. « Casier chêne 6×6 »).
5. "slots_matrix" : matrice booléenne [rows][columns], true là où une bouteille peut être posée.

Retourne STRICTEMENT un objet JSON :
{"name": "...", "shape_type": "rectangle", "columns": 6, "rows": 6, "slots_matrix": [[true, true]]}` },
        ],
      }
    }
    case 'import_cave': {
      const lignes = liste(e.lignes, 60, 400)
      if (lignes.length === 0) return 'aucune ligne'
      return {
        enJson: true,
        parts: [{ text: `Tu es un sommelier expert et ingénieur de données vinicoles.
Voici des lignes extraites d'un tableur de cave à vin :

${lignes.join('\n')}

Identifie chaque vin et extrais :
- "name" : nom du vin ou de la cuvée (requis)
- "producer" : domaine, maison ou château
- "vintage" : millésime (entier) ou null
- "type" : "red", "white", "rosé", "sparkling", "dessert", "fortified" ou "spirit"
- "region" : région viticole ; "country" : pays ; "appellation" : AOC, AOP, DOCG ou AVA si identifiable
- "quantity" : nombre de bouteilles sur la ligne (entier ≥ 1, défaut 1)
- "bottle_size" : "37.5cl", "50cl", "75cl", "1.5L", "3L" ou "6L" (défaut "75cl")
- "purchase_price" : prix unitaire d'achat, ou null
- "currency" : "EUR" par défaut, sinon celle de la ligne
- "rack" et "shelf" : casier et étagère s'ils sont indiqués, sinon null

Règles : ignore les lignes d'en-tête, les totaux et les métadonnées ; déduis la couleur de l'appellation (Meursault → white, Pomerol → red, Champagne → sparkling) ; un millésime dans le nom va dans "vintage".

Retourne STRICTEMENT un tableau JSON d'objets vin.` }],
      }
    }
    case 'fiche_texte': {
      const nom = texte(e.nom, 200)
      if (!nom) return 'nom vide'
      const millesime = entier(e.millesime)
      return {
        enJson: true,
        parts: [{ text: `Tu es un sommelier expert. Identifie ce vin : "${nom}"${millesime ? ` (millésime ${millesime})` : ''}.
NE DEVINE JAMAIS : un vin faux affiché comme un fait est la pire réponse ; un champ vide vaut toujours mieux.
- Si tu ne reconnais pas ce vin précis avec certitude, renvoie {"reconnu": false} et rien d'autre.
- Ne remplis un champ que si le nom le dit ou si tu le sais avec certitude pour CE vin ; sinon null. Ne déduis jamais un pays, une région ou une appellation d'une langue, d'un mot ou d'un style.
Renvoie STRICTEMENT un objet JSON :
{"reconnu": true, "name": "Nom complet du vin", "producer": "Domaine ou null", "vintage": ${millesime ?? 'null'}, "wine_type": "red|white|rosé|sparkling|dessert|fortified|orange ou null", "country": "Pays ou null", "region": "Région ou null", "appellation": "Appellation ou null", "grapes": ["Cépage"], "ideal_drinking_start": 2024, "ideal_drinking_end": 2032}
Pour la seule fenêtre de consommation, quand l'appellation est certaine, sa valeur typique vaut mieux qu'une année précise inventée ; sinon null.` }],
      }
    }
    case 'enrichir_fiche': {
      const nom = texte(e.nom, 200)
      if (!nom) return 'nom vide'
      const recherche = e.recherche === true
      return {
        enJson: !recherche,
        recherche,
        parts: [{ text: `You are Chatmelier, a sommelier and oenology reference.
Give reliable sommelier data for:
- Wine name: ${nom}
- Producer / domaine: ${texte(e.producteur, 120) || 'Unknown'}
- Vintage: ${entier(e.millesime) ?? 'not stated'}
- Region: ${texte(e.region, 80) || 'Unknown'}
- Appellation: ${texte(e.appellation, 80) || 'Unknown'}
- Wine type: ${texte(e.type, 30) || 'not stated'}
${recherche ? 'Search trusted wine references (producer site, Guide Hachette, RVF, Wine Spectator, Decanter) and use what you find.\n' : ''}
Return strictly one JSON object with:
"grapes": [{"name": "...", "pct": number | null}] — the real blend of this appellation or cuvée;
"appellation": official appellation (AOC, DOC, AOP); "region": main wine region; "sub_region": sub-region, commune or cru, or null;
"classification": official classification (Grand Cru Classé, Premier Cru…) or null;
"tasting_notes": aromas, texture, acidity and structure, ${EN_LANGUE[langue]};
"food_pairings": 3 to 5 pairings, ${EN_LANGUE[langue]};
"ideal_drinking_start", "ideal_drinking_end", "peak_drinking_start", "peak_drinking_end": years, or null;
"alcohol_pct": number or null;
"ai_summary": 1 or 2 sentences ${EN_LANGUE[langue]}, naming the grape varieties.
If you are unsure of a value, give the typical value of the appellation rather than a precise-looking guess. Do not give any price.` }],
      }
    }
    case 'traduire_fiche': {
      // La fiche d'un vin lue dans une autre langue que celle de l'app : le catalogue garde la
      // langue de qui l'a écrite la première fois (Caro, en français, lisait des fiches
      // anglaises, 04/10). Une traduction fidèle : rien d'ajouté, rien de retiré.
      const notes = texte(e.notes, 2500)
      const accords = liste(e.accords, 8, 200)
      if (!notes && accords.length === 0) return 'rien à traduire'
      return {
        enJson: true,
        parts: [{ text: `Translate this wine description and these food pairings ${VERS_LA_LANGUE[langue]}, faithfully, in the words a sommelier would use.
Do not add, remove or change anything: same aromas, same structure, same dishes, same facts. Keep wine names, appellations, grape varieties, producers and dish names that have no common translation as they are.
Description: ${JSON.stringify(notes)}
Food pairings: ${JSON.stringify(accords)}
Return strictly one JSON object: {"notes": "<the translated description, or an empty string if none was given>", "accords": ["<each translated pairing, in the same order>"]}` }],
      }
    }
    case 'vin_depuis_texte': {
      const description = texte(e.texte, 600)
      if (!description) return 'texte vide'
      // Recherche Google : vérifier que ce vin existe, et d'où il vient, avant d'affirmer quoi
      // que ce soit (V2.4 · R1, « S de Siroua », vin marocain devenu Côtes du Rhône le 07/10).
      return {
        enJson: false,
        recherche: true,
        parts: [{ text: `You are Chatmelier, a master sommelier.
Analyse this wine description, wine-list entry or chalkboard line:
"${description}"

NEVER GUESS. A wrong wine shown as a fact is the worst possible answer: an empty field is always better.
- If you do not recognise this exact wine with certainty, answer {"reconnu": false, "name": <the text as written>} and nothing else.
- Fill a field only if the text states it or you know it for certain for THIS wine; otherwise null. Never deduce a country, region or appellation from a language, a word or a style.
- Use Google Search to check that this exact wine exists and where it comes from. If the search does not confirm it, answer {"reconnu": false, ...} as above.
Return strictly one JSON object, and nothing else, with:
"reconnu": true;
"name": wine or spirit name / cuvée; "producer": estate, winery or distillery, or null;
"vintage": integer or null; "cuvee_parcel": parcel or cuvée, or null;
"wine_type": one of red, white, rosé, sparkling, dessert, fortified, orange, liqueur, spirit, grappa, eau-de-vie, whisky, gin, rum, vodka, tequila, cognac, vermouth.
Spirits, grappas, digestifs and herbal liqueurs (Grappa, Marc, Bénédictine, Chartreuse, Cointreau, Amaretto, Gin, Rum, Whisky, Vodka, Pastis…) take their spirit type or "liqueur" / "spirit", never red, white, fortified or dessert. "fortified" is only for true fortified wines (Port, Sherry, Banyuls, Madeira, Marsala);
"country", "region", "sub_region", "appellation", "classification": or null;
"alcohol_pct": ABV if stated or known for this wine, else null;
"grapes": [{"name": "...", "pct": number | null}] — only grapes known for this wine, else [];
"tasting_notes": aromas, palate and structure, ${EN_LANGUE[langue]};
"food_pairings": 3 to 5 pairings, ${EN_LANGUE[langue]};
"ideal_drinking_start", "ideal_drinking_end", "peak_drinking_start", "peak_drinking_end": years, or null;
"ai_summary": 1 or 2 sentences ${EN_LANGUE[langue]}, naming the grape varieties;
"detected_quantity": 1; "packaging_type": "single".
Do not give any price.` }],
      }
    }
  }
  return 'tâche inconnue'
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } } },
    )
    // Ces tâches servent des comptes ou des sessions de l'app : pas d'accès sans session.
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return json({ error: 'session_requise' }, 401)

    const corps = await req.json()
    const tache = texte(corps.tache, 40)
    if (!REGLAGES[tache]) return json({ error: 'tâche inconnue' }, 400)
    const c = consigne(tache, corps, langueDe(corps.langue))
    if (typeof c === 'string') return json({ error: c }, 400)

    try {
      const { data, error } = await supabase.rpc('consommer_quota_ia', { p_fonction: QUOTAS[tache] ?? 'taches' })
      if (!error && data && data.autorise === false && data.raison === 'limite') {
        return json({ error: 'limite_du_jour', limite: data.limite, anonyme: data.anonyme === true }, 429)
      }
    } catch (_) { /* migration 052 absente : pas de quota */ }

    const apiKey = Deno.env.get('GEMINI_API_KEY')
    if (!apiKey) return json({ error: 'GEMINI_API_KEY non configurée' }, 500)

    let reglage = REGLAGES[tache]
    try {
      const { data } = await supabase.from('app_config').select('valeur').eq('cle', 'modeles_ia').maybeSingle()
      const r = data?.valeur?.[tache]
      if (r && typeof r.modele === 'string') reglage = { modele: r.modele, reflexion: typeof r.reflexion === 'string' ? r.reflexion : reglage.reflexion }
    } catch (_) { /* réglage par défaut */ }

    let appel: AppelReussi
    try {
      appel = await appelerGemini(apiKey, reglage, (niveau) => {
        const generationConfig: Record<string, unknown> = {}
        if (c.enJson) generationConfig.responseMimeType = 'application/json'
        if (niveau) generationConfig.thinkingConfig = { thinkingLevel: niveau }
        const envoi: Record<string, unknown> = { contents: [{ role: 'user', parts: c.parts }], generationConfig }
        if (c.recherche) envoi.tools = [{ google_search: {} }]
        return envoi
      }, tache === 'import_cave' ? 60_000 : 30_000, (data) => texteDeLaReponse(data).trim().length > 0)
    } catch (err) {
      const detail = err instanceof Error ? err.message : String(err)
      console.error(`taches-ia (${tache}) : aucun modèle n'a répondu`, detail)
      return json({ error: 'Aucun modèle n\'a répondu', details: [detail] }, 502)
    }
    const brut = texteDeLaReponse(appel.data).trim()
    const usage = appel.data.usageMetadata ?? null
    const requetes = appel.data.candidates?.[0]?.groundingMetadata?.webSearchQueries
    const n = Array.isArray(requetes) ? requetes.length : 0
    return json({
      tache,
      resultat: c.enJson || c.recherche ? (tache === 'synthese_table' ? brut : lireJson(brut)) : brut,
      modele: appel.modele,
      couts: [{ fonction: tache, modele: appel.modele, usageMetadata: usage, recherche: n > 0, requetes: n, reflexion: appel.reflexion }],
    })
  } catch (error) {
    return json({ error: (error as Error).message }, 500)
  }
})
