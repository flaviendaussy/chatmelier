import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0'

// Fichier autonome : il se déploie d'un seul fichier depuis l'éditeur du Dashboard.

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function reponse(obj: unknown, status = 200, entetes: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(obj), { status, headers: { ...corsHeaders, ...entetes, 'Content-Type': 'application/json' } })
}

// Remplaçable pour les essais en local contre un faux serveur ; Google en production.
const GEMINI_BASE = Deno.env.get('GEMINI_BASE_URL') ?? 'https://generativelanguage.googleapis.com'

// ─── Garde commune (V2.3 · B2) ───────────────────────────────────────────────────
// Avec une session : le quota du jour, tenu en base (consommer_quota_ia, migration 052).
// Sans session : refus si app_config.ia_session_obligatoire est vrai (après le build 72),
// sinon la limite par adresse en mémoire, comme avant.
const requestCounts = new Map<string, { count: number; resetAt: number }>()

function checkRateLimit(identifier: string, maxRequests = 10, windowMs = 60_000) {
  const now = Date.now()
  const entry = requestCounts.get(identifier)
  if (!entry || now >= entry.resetAt) {
    requestCounts.set(identifier, { count: 1, resetAt: now + windowMs })
    return { allowed: true, retryAfterMs: 0 }
  }
  entry.count++
  if (entry.count > maxRequests) return { allowed: false, retryAfterMs: entry.resetAt - now }
  return { allowed: true, retryAfterMs: 0 }
}

async function lireConfig(supabase: any, cles: string[]): Promise<Record<string, any>> {
  const config: Record<string, any> = {}
  try {
    const { data } = await supabase.from('app_config').select('cle, valeur').in('cle', cles)
    for (const ligne of data ?? []) config[ligne.cle] = ligne.valeur
  } catch (_) { /* configuration absente : valeurs par défaut */ }
  return config
}

async function garder(req: Request, supabase: any, fonction: string, strict: boolean): Promise<Response | null> {
  let utilisateur = null
  try {
    const { data } = await supabase.auth.getUser()
    utilisateur = data?.user ?? null
  } catch (_) { /* jeton absent ou clé publique seule */ }
  if (!utilisateur) {
    if (strict) return reponse({ error: 'session_requise' }, 401)
    const ip = (req.headers.get('x-forwarded-for') ?? 'anon').split(',')[0].trim()
    const { allowed, retryAfterMs } = checkRateLimit(`${fonction}:${ip}`, 20, 60_000)
    if (!allowed) {
      return reponse({ error: 'Trop de requêtes. Veuillez patienter.' }, 429,
        { 'Retry-After': String(Math.ceil(retryAfterMs / 1000)) })
    }
    return null
  }
  try {
    const { data, error } = await supabase.rpc('consommer_quota_ia', { p_fonction: fonction })
    if (!error && data && data.autorise === false && data.raison === 'limite') {
      return reponse({ error: 'limite_du_jour', limite: data.limite, anonyme: data.anonyme === true }, 429)
    }
  } catch (_) { /* migration 052 absente : pas de quota */ }
  return null
}

// ─── Modèles ─────────────────────────────────────────────────────────────────────
// Le modèle se règle dans app_config.modeles_ia.scan_carte (nom exact choisi par le banc
// d'essai), sans redéploiement. Par défaut : le plus récent Flash stable.
const REGLAGE_PAR_DEFAUT: Reglage = { modele: 'flash', reflexion: 'minimal' }

// Un modèle bloqué ne doit pas consommer tout le budget de la fonction (150 s) : au-delà
// de ce délai on passe au suivant. Une page dense se lit en 15 à 25 s.
const DELAI_PAR_MODELE_MS = 75_000

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
  let texte = raw
  if (texte.includes('```json')) texte = texte.split('```json')[1].split('```')[0].trim()
  else if (texte.includes('```')) texte = texte.split('```')[1].split('```')[0].trim()
  try {
    return JSON.parse(texte)
  } catch {
    const repare = texte.replace(/,\s*([\}\]])/g, '$1')
    const debut = repare.indexOf('{')
    const fin = repare.lastIndexOf('}')
    if (debut !== -1 && fin > debut) return JSON.parse(repare.substring(debut, fin + 1))
    throw new Error('Réponse non JSON')
  }
}


// ─── La carte, en format court ───────────────────────────────────────────────────
// Le modèle rendait 19 clés longues par vin, commentaires compris : l'essentiel de la
// sortie, facturée cinq fois l'entrée. Il rend maintenant des clés courtes, des métriques
// entières et des codes de goût ; le serveur reconstruit le JSON que l'app connaît, si bien
// que la version installée ne voit aucune différence. Le « prix de détail estimé » n'est
// plus demandé : il était inventé.
type Langue = 'fr' | 'en' | 'es' | 'it'

const GOUTS: Record<string, Record<Langue, string>> = {
  mineral: { fr: 'minéral', en: 'mineral', es: 'mineral', it: 'minerale' },
  buttery: { fr: 'beurré', en: 'buttery', es: 'mantecoso', it: 'burroso' },
  tannic: { fr: 'tannique', en: 'tannic', es: 'tánico', it: 'tannico' },
  fruity: { fr: 'fruité', en: 'fruity', es: 'afrutado', it: 'fruttato' },
  light: { fr: 'léger', en: 'light', es: 'ligero', it: 'leggero' },
  bold: { fr: 'puissant', en: 'bold', es: 'potente', it: 'potente' },
  oaky: { fr: 'boisé', en: 'oaky', es: 'con madera', it: 'legnoso' },
  floral: { fr: 'floral', en: 'floral', es: 'floral', it: 'floreale' },
  spicy: { fr: 'épicé', en: 'spicy', es: 'especiado', it: 'speziato' },
  fresh: { fr: 'frais', en: 'fresh', es: 'fresco', it: 'fresco' },
  round: { fr: 'rond', en: 'round', es: 'redondo', it: 'rotondo' },
  savory: { fr: 'gourmand', en: 'savory', es: 'sabroso', it: 'goloso' },
}
const TYPES: Record<string, string> = { r: 'red', w: 'white', p: 'rose', s: 'sparkling', d: 'dessert', f: 'fortified' }
const NOMS_DE_LANGUE: Record<Langue, string> = { fr: 'French', en: 'English', es: 'Spanish', it: 'Italian' }

function langueDe(code: unknown): Langue {
  const c = String(code ?? 'fr').toLowerCase()
  if (c.startsWith('fr')) return 'fr'
  if (c.startsWith('es')) return 'es'
  if (c.startsWith('it')) return 'it'
  return 'en'
}

// L'ardoise d'un bar à vins (V2.3 · J4) : même lecture que la carte, mais les prix d'une
// ardoise sont le plus souvent au verre, et l'écriture à la main.
type Mode = 'carte' | 'ardoise'

function modeDe(v: unknown): Mode {
  return String(v ?? '').toLowerCase() === 'ardoise' ? 'ardoise' : 'carte'
}

function consigne(langue: Langue, mode: Mode = 'carte'): string {
  const l = NOMS_DE_LANGUE[langue]
  // Le mot qui suit le prix à l'écran (« 7 €/verre ») : dans la langue de la personne.
  const verre = langue === 'fr' ? 'verre' : langue === 'es' ? 'copa' : langue === 'it' ? 'calice' : 'glass'
  const ouverture = mode === 'ardoise'
    ? `You are Chatmelier, a sommelier reading the by-the-glass board of a wine bar (a chalkboard, a slate or a short printed list).
You are given one or several photos of the board. Extract EVERY wine written on it.
On such a board, a single price next to a wine is a GLASS price unless the board clearly says it is for the bottle: put it in "gl" (with the format if written, e.g. ["12cl", 7], else ["${verre}", 7]) and leave "b" null. Use "b" only for prices marked as bottle prices.
The writing may be by hand: keep what you can read, and never invent a wine or a price.
`
    : `You are Chatmelier, a sommelier reading a restaurant wine list.
You are given one or several photos of the pages of the wine list. Extract EVERY wine listed across all pages.
`
  return `${ouverture}
Return STRICTLY one JSON object, with these short keys:
{"r": restaurant name if printed on the pages, else null,
 "c": ISO 4217 code of the prices ("EUR", "GBP", "USD", "CHF"...) from the symbols on the list, or from its country and language; null only if no price is shown,
 "ex": 1 if the list itself is exceptional (deep in cult, rare or mature bottles), else 0,
 "v": [one object per wine]}

Each wine object:
"n": official wine or cuvée name, as printed
"p": producer (domaine, château, house), or null
"y": vintage as an integer, or null if non-vintage
"t": type, one letter: r red, w white, p rosé, s sparkling, d dessert, f fortified
"a": appellation, or null
"rg": broad region, in French (Bordeaux, Bourgogne, Vallée du Rhône, Loire, Alsace, Champagne, Toscane...)
"co": country, in French (France, Italie, Espagne...)
"g": grape varieties, array of strings (typical ones for the appellation if not printed; [] if the appellation is unknown)
"b": bottle price as printed (number), or null
"gl": glass prices as [[format, price]], e.g. [["12cl", 8]], or []
"m": 8 integers from 0 to 10, in this order: tannins (0 for white, rosé, sparkling), acidity, body, fruit, oak, minerality, butteriness, sweetness
"tg": up to 3 codes among mineral, buttery, tannic, fruity, light, bold, oaky, floral, spicy, fresh, round, savory
"sc": one short sentence in ${l} (at most 14 words) on the style and when to drink it
"fp": 3 restaurant dishes in ${l}, at most 4 words each
"ge": gem: 0 for almost every wine, 1 for a true find of this list, 2 for an exceptional one (see Gems)
"gr": if ge is above 0, why, in ${l}, at most 8 words; else ""
"de": bargain: 0 for almost every wine, 1 for a clear bargain on this list, 2 for an exceptional one (see Bargains)
"dr": if de is above 0, why, in ${l}, at most 8 words; else ""

Gems are rare. A gem is the bottle a sommelier would point at on THIS list: a cult or hard-to-find cuvée, a producer far above the level of the rest of the list, a mature vintage rarely offered. A famous appellation, a well-known house or a good producer is not enough. Most lists have no gem: mark at most two, unless the list itself is exceptional ("ex": 1), and even then about one wine in ten. When in doubt, 0.
Bargains are rare too: a bottle priced clearly below what it usually costs on a restaurant list. Never without a printed price. Most lists have none or one: mark at most three.

Never guess: for a wine you do not know, leave "p", "a", "rg" and "co" null rather than deducing them from the language of the list, a word or a style.
Do not add any other key. Do not invent wines that are not on the pages.`
}

function nombre(v: unknown): number | null {
  const n = typeof v === 'number' ? v : typeof v === 'string' ? parseFloat(v.replace(',', '.')) : NaN
  return Number.isFinite(n) ? n : null
}

// Une pépite ou un bon plan ne veut rien dire s'il est partout (V2.3 · K9 : le banc du 02/10
// en comptait jusqu'à 26 sur 28 vins). Le modèle note chaque vin (0, 1 ou 2) ; on garde les
// mieux notés, à rang égal dans l'ordre de la carte, et jamais sans raison écrite.
function niveauDe(note: unknown, raison: unknown): number {
  if (typeof raison !== 'string' || !raison.trim()) return 0
  const n = note === true ? 1 : nombre(note) ?? 0
  return Math.max(0, Math.min(2, Math.round(n)))
}

function lesMieuxNotes(niveaux: number[], plafond: number): Set<number> {
  return new Set(niveaux
    .map((niveau, i) => ({ niveau, i }))
    .filter((x) => x.niveau > 0)
    .sort((a, b) => b.niveau - a.niveau || a.i - b.i)
    .slice(0, plafond)
    .map((x) => x.i))
}

// Deux pépites au plus ; sur une carte exceptionnelle, environ un vin sur dix, cinq au plus.
// Deux bons plans au plus sur une courte carte, trois sur une longue ; jamais sans prix.
function plafondDesPepites(nombreDeVins: number, exceptionnelle: boolean): number {
  return exceptionnelle ? Math.min(5, Math.max(2, Math.round(nombreDeVins / 10))) : 2
}

function plafondDesBonsPlans(nombreDeVins: number): number {
  return nombreDeVins < 12 ? 2 : 3
}

function deplier(court: any, langue: Langue): any {
  // Le modèle a répondu dans l'ancien format : on le rend tel quel.
  if (court && Array.isArray(court.wines)) return court
  const vins = (Array.isArray(court?.v) ? court.v : []).filter((w: any) => w && typeof w.n === 'string' && w.n.trim())
  const aUnPrix = (w: any) => nombre(w.b) !== null || (Array.isArray(w.gl) && w.gl.some((x: any) => Array.isArray(x) && nombre(x[1]) !== null))
  const pepites = lesMieuxNotes(vins.map((w: any) => niveauDe(w.ge, w.gr)),
    plafondDesPepites(vins.length, court?.ex === 1 || court?.ex === true))
  const bonsPlans = lesMieuxNotes(vins.map((w: any) => (aUnPrix(w) ? niveauDe(w.de, w.dr) : 0)),
    plafondDesBonsPlans(vins.length))
  return {
    restaurant_name: typeof court?.r === 'string' && court.r.trim() ? court.r.trim() : null,
    currency: typeof court?.c === 'string' && /^[A-Z]{3}$/.test(court.c) ? court.c : null,
    wines: vins.map((w: any, i: number) => {
      const m = Array.isArray(w.m) ? w.m.map((x: unknown) => Math.max(0, Math.min(10, nombre(x) ?? 5))) : []
      const type = TYPES[String(w.t ?? '').toLowerCase()] ?? 'red'
      const blancOuBulles = type !== 'red'
      const millesime = Number.isInteger(w.y) ? w.y : null
      return {
        // Le millésime recopié à la fin du nom (« Camins del Priorat 2021 ») s'afficherait deux fois.
        name: millesime ? w.n.trim().replace(new RegExp(`[\\s,–—-]+${millesime}$`), '') || w.n.trim() : w.n.trim(),
        producer: w.p ?? null,
        vintage: millesime,
        wine_type: type,
        appellation: w.a ?? null,
        region: w.rg ?? null,
        country: w.co ?? null,
        grapes: Array.isArray(w.g) ? w.g.filter((x: unknown) => typeof x === 'string') : [],
        bottle_price: nombre(w.b),
        glass_prices: Array.isArray(w.gl)
          ? w.gl.filter((x: any) => Array.isArray(x) && nombre(x[1]) !== null)
              .map((x: any) => ({ format: String(x[0] ?? ''), price: nombre(x[1]) }))
          : [],
        metrics: {
          tannins: blancOuBulles ? 0.0 : (m[0] ?? 5),
          acidity: m[1] ?? 5,
          body: m[2] ?? 5,
          fruit: m[3] ?? 5,
          oak: m[4] ?? 3,
          minerality: m[5] ?? 5,
          butteriness: m[6] ?? 0,
          sweetness: m[7] ?? 1,
        },
        tags: (Array.isArray(w.tg) ? w.tg : [])
          .map((t: unknown) => GOUTS[String(t).toLowerCase()]?.[langue])
          .filter((t: unknown) => !!t),
        sommelier_comment: typeof w.sc === 'string' ? w.sc : '',
        food_pairings: Array.isArray(w.fp) ? w.fp.filter((x: unknown) => typeof x === 'string').slice(0, 3) : [],
        is_gem: pepites.has(i),
        gem_reason: pepites.has(i) ? w.gr.trim() : null,
        is_deal: bonsPlans.has(i),
        deal_reason: bonsPlans.has(i) ? w.dr.trim() : null,
        estimated_retail_price: null,
      }
    }),
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } } },
    )
    const config = await lireConfig(supabase, ['modeles_ia', 'ia_session_obligatoire'])
    const refus = await garder(req, supabase, 'scan_carte', config.ia_session_obligatoire === true)
    if (refus) return refus

    const body = await req.json()
    const { imageBase64, imagesBase64, mimeType = 'image/jpeg', languageCode = 'fr' } = body
    const mode = modeDe(body.mode)

    const imageParts: any[] = []
    if (Array.isArray(imagesBase64) && imagesBase64.length > 0) {
      for (const b64 of imagesBase64.slice(0, 6)) {
        if (b64 && typeof b64 === 'string') imageParts.push({ inlineData: { data: b64, mimeType: mimeType || 'image/jpeg' } })
      }
    } else if (imageBase64 && typeof imageBase64 === 'string') {
      imageParts.push({ inlineData: { data: imageBase64, mimeType: mimeType || 'image/jpeg' } })
    }
    if (imageParts.length === 0) return reponse({ error: 'Aucune image valide fournie' }, 400)

    const apiKey = Deno.env.get('GEMINI_API_KEY')
    if (!apiKey) return reponse({ error: 'GEMINI_API_KEY non configurée' }, 500)

    const r = config.modeles_ia?.scan_carte
    const reglage: Reglage = r && typeof r.modele === 'string'
      ? { modele: r.modele, reflexion: typeof r.reflexion === 'string' ? r.reflexion : REGLAGE_PAR_DEFAUT.reflexion }
      : REGLAGE_PAR_DEFAUT

    const langue = langueDe(languageCode)
    const contents = [{ role: 'user', parts: [...imageParts, { text: consigne(langue, mode) }] }]
    const appel = await appelerGemini(apiKey, reglage, (niveau) => ({
      contents,
      generationConfig: {
        responseMimeType: 'application/json',
        ...(niveau ? { thinkingConfig: { thinkingLevel: niveau } } : {}),
      },
    }), DELAI_PAR_MODELE_MS, (data) => {
      // Un JSON malformé (05/10, 16h30) passe au modèle suivant au lieu d'échouer.
      try { lireJson(texteDeLaReponse(data)); return true } catch { return false }
    }).catch((e) => { throw new ErreurDeLecture(e instanceof Error ? e.message : String(e)) })
    const resultat = lireJson(texteDeLaReponse(appel.data) || '{}')
    const { modele, reflexion } = appel
    const usage = appel.data.usageMetadata ?? null

    // `modele`, `usageMetadata` et `couts` : le client journalise quel modèle a lu la carte et
    // comptabilise le coût réel de l'appel.
    return reponse({
      ...deplier(resultat, langue),
      mode,
      modele,
      usageMetadata: usage,
      couts: [{ fonction: 'menu_scan_vision', modele, usageMetadata: usage, recherche: false, reflexion }],
    })
  } catch (error: any) {
    console.error('Scan menu error:', error)
    // Une cause nommée, que l'app traduit en message clair (05/10).
    const lecture = error instanceof ErreurDeLecture
    return reponse({ error: lecture ? 'lecture_illisible' : 'erreur_serveur', detail: String(error?.message ?? error).slice(0, 200) }, lecture ? 502 : 500)
  }
})

class ErreurDeLecture extends Error {}
