import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0'

// Fichier autonome : il se déploie depuis l'éditeur du Dashboard, qui ne connaît pas
// `_shared/` (l'import inutilisé de rate_limit.ts y aurait fait échouer le déploiement).

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Remplaçable pour les essais en local contre un faux serveur ; Google en production.
const GEMINI_BASE = Deno.env.get('GEMINI_BASE_URL') ?? 'https://generativelanguage.googleapis.com'

// Le modèle de chaque tâche se règle dans app_config.modeles_ia (nom exact choisi par le
// banc d'essai), sans redéploiement (V2.3). Par défaut : le plus récent Flash stable.
const REGLAGES_PAR_DEFAUT: Record<string, Reglage> = {
  // Lire une étiquette ne demande pas de réfléchir : le 29/09, 552 des 663 jetons de sortie
  // de la lecture étaient de la réflexion, facturée au prix de la sortie.
  scan_etiquette_lecture: { modele: 'flash', reflexion: 'minimal' },
  scan_etiquette_description: { modele: 'flash', reflexion: 'low' },
}

// Un modèle bloqué ne doit pas consommer tout le budget de la fonction : au-delà, on
// passe au suivant (même leçon que scan-menu, 29/09). La recherche Google allonge
// l'appel, d'où un délai plus large quand elle est active.
const DELAI_LECTURE_MS = 25_000
const DELAI_RECHERCHE_MS = 40_000

interface AppelGemini {
  resultat: any
  modele: string
  usage: unknown
  // Vrai seulement si Gemini a réellement lancé des recherches : la présence de l'outil
  // dans la requête ne garantit pas qu'il s'en soit servi.
  recherche: boolean
  requetes: number
  reflexion: string | null
}

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

// La lecture ou la description d'une étiquette, avec ou sans recherche Google.
async function appelerPourLaFiche(
  apiKey: string, contents: any[], reglage: Reglage, avecRecherche = false,
): Promise<AppelGemini> {
  const appel = await appelerGemini(apiKey, reglage, (niveau) => {
    const generationConfig: Record<string, unknown> = {}
    // L'outil de recherche et la sortie JSON imposée ne se combinent pas : avec la
    // recherche, on lit le JSON dans le texte.
    if (!avecRecherche) generationConfig.responseMimeType = 'application/json'
    if (niveau) generationConfig.thinkingConfig = { thinkingLevel: niveau }
    const corps: Record<string, unknown> = { contents, generationConfig }
    if (avecRecherche) corps.tools = [{ google_search: {} }]
    return corps
  }, avecRecherche ? DELAI_RECHERCHE_MS : DELAI_LECTURE_MS)
  const requetes = appel.data?.candidates?.[0]?.groundingMetadata?.webSearchQueries
  const n = Array.isArray(requetes) ? requetes.length : 0
  return {
    resultat: lireJson(texteDeLaReponse(appel.data) || '{}'),
    modele: appel.modele,
    usage: appel.data.usageMetadata ?? null,
    recherche: avecRecherche && n > 0,
    requetes: n,
    reflexion: appel.reflexion,
  }
}

// ─── Garde commune (V2.3 · B2) ───────────────────────────────────────────────────
// Avec une session : le quota du jour, tenu en base (consommer_quota_ia, migration 052).
// Sans session : refus si app_config.ia_session_obligatoire est vrai (après le build 72),
// sinon une limite par adresse en mémoire. scan-label n'en avait aucune.
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

function reponse(obj: unknown, status = 200, entetes: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(obj), { status, headers: { ...corsHeaders, ...entetes, 'Content-Type': 'application/json' } })
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
    const { allowed, retryAfterMs } = checkRateLimit(`${fonction}:${ip}`, 10, 60_000)
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

// Une fiche du catalogue suffit si elle dit l'essentiel : de quoi le vin est fait, ce
// qu'on y sent, et quand le boire. Une fiche saisie à la main sans notes ne suffit pas.
function ficheRiche(f: any): boolean {
  if (!f) return false
  const cepages = Array.isArray(f.grapes) ? f.grapes.length : 0
  return !!(f.tasting_notes && String(f.tasting_notes).trim().length > 20) &&
    cepages > 0 &&
    (f.peak_drinking_start != null || f.ideal_drinking_start != null)
}

function vide(v: unknown): boolean {
  if (v === null || v === undefined) return true
  if (typeof v === 'string') return v.trim() === ''
  if (Array.isArray(v)) return v.length === 0
  return false
}

// Une valeur de marché n'est gardée que si une vraie recherche l'a trouvée, avec sa source.
// Sans recherche, le modèle l'inventait, et elle s'affichait comme une cote (30/09).
function valeurSourcee(enrichi: any, verifiee: boolean): { valeur: number | null; source: string | null } {
  const v = Number(enrichi?.estimated_market_value)
  const source = typeof enrichi?.valeur_source === 'string' && /^https?:\/\//.test(enrichi.valeur_source)
    ? enrichi.valeur_source : null
  if (!verifiee || !source || !Number.isFinite(v) || v <= 0) return { valeur: null, source: null }
  return { valeur: v, source }
}

// Le catalogue apprend de chaque description, une seule fois par vin (V2.3 · B1). La fiche
// du serveur (`decrite_par_serveur`) est complétée champ vide par champ vide, jamais
// réécrite ; les fiches des utilisateurs ne sont pas touchées. Sans la migration 052 (colonne
// absente), l'écriture échoue en silence et rien d'autre ne change.
async function enrichirLeCatalogue(ficheTrouvee: any, lue: any, enrichi: any, verifiee: boolean, valeur: { valeur: number | null; source: string | null }) {
  const cle = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (!cle || !lue?.name || !enrichi || vide(enrichi.tasting_notes)) return
  const serveur = createClient(Deno.env.get('SUPABASE_URL') ?? '', cle, { auth: { persistSession: false } })
  const description: Record<string, unknown> = {
    name: lue.name,
    producer: lue.producer ?? null,
    cuvee_parcel: lue.cuvee_parcel ?? null,
    vintage: lue.vintage ?? null,
    wine_type: lue.wine_type ?? null,
    country: lue.country ?? null,
    region: lue.region ?? null,
    sub_region: lue.sub_region ?? null,
    appellation: lue.appellation ?? null,
    classification: lue.classification ?? null,
    alcohol_pct: lue.alcohol_pct ?? null,
    grapes: Array.isArray(enrichi.grapes) ? enrichi.grapes : [],
    tasting_notes: enrichi.tasting_notes ?? null,
    ideal_drinking_start: enrichi.ideal_drinking_start ?? null,
    ideal_drinking_end: enrichi.ideal_drinking_end ?? null,
    peak_drinking_start: enrichi.peak_drinking_start ?? null,
    peak_drinking_end: enrichi.peak_drinking_end ?? null,
    ai_summary: enrichi.ai_summary ?? null,
    ai_food_pairings: Array.isArray(enrichi.food_pairings) ? enrichi.food_pairings : [],
  }
  if (verifiee) {
    description.critic_scores = Array.isArray(enrichi.critic_scores) ? enrichi.critic_scores : []
    description.sources_verified = Array.isArray(enrichi.sources_verified) ? enrichi.sources_verified : []
    description.is_verified_online = true
  }
  if (valeur.valeur !== null) {
    description.estimated_market_value = valeur.valeur
    description.estimated_value_currency = 'EUR'
    description.last_valuation_date = new Date().toISOString()
    description.external_links = { valeur_source: valeur.source }
  }
  try {
    if (ficheTrouvee?.decrite_par_serveur === true) {
      const complement: Record<string, unknown> = {}
      for (const [k, v] of Object.entries(description)) {
        if (!vide(v) && vide(ficheTrouvee[k])) complement[k] = v
      }
      if (Object.keys(complement).length === 0) return
      const { error } = await serveur.from('wines').update(complement).eq('id', ficheTrouvee.id)
      if (error) console.warn('Catalogue : complément refusé :', error.message)
    } else {
      const { error } = await serveur.from('wines').insert({ ...description, decrite_par_serveur: true, created_by: null })
      if (error) console.warn('Catalogue : fiche serveur refusée :', error.message)
    }
  } catch (e) {
    console.warn('Catalogue indisponible :', e)
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

    // Réglages : la recherche Google (048), les modèles et la session obligatoire (V2.3).
    let avecRecherche = false
    let sessionObligatoire = false
    const reglages: Record<string, Reglage> = { ...REGLAGES_PAR_DEFAUT }
    try {
      const { data } = await supabase.from('app_config').select('cle, valeur')
        .in('cle', ['scan_etiquette_recherche', 'modeles_ia', 'ia_session_obligatoire'])
      for (const ligne of data ?? []) {
        if (ligne.cle === 'scan_etiquette_recherche') avecRecherche = ligne.valeur === true
        if (ligne.cle === 'ia_session_obligatoire') sessionObligatoire = ligne.valeur === true
        if (ligne.cle === 'modeles_ia' && ligne.valeur && typeof ligne.valeur === 'object') {
          for (const tache of Object.keys(REGLAGES_PAR_DEFAUT)) {
            const r = (ligne.valeur as any)[tache]
            if (r && typeof r.modele === 'string') {
              reglages[tache] = { modele: r.modele, reflexion: typeof r.reflexion === 'string' ? r.reflexion : reglages[tache].reflexion }
            }
          }
        }
      }
    } catch (_) { /* configuration absente : valeurs par défaut, pas de recherche */ }

    const refus = await garder(req, supabase, 'scan_etiquette', sessionObligatoire)
    if (refus) return refus

    const body = await req.json()
    const { photoUrls, imageBase64, mimeType = 'image/jpeg', forceRefresh = false } = body
    // Langue des notes et des accords. Les versions de l'app antérieures à la V2.3 ne
    // l'envoyaient pas : le français, langue de la grande majorité des comptes.
    const codeLangue = String(body.languageCode ?? 'fr').toLowerCase()
    const langue = codeLangue.startsWith('fr') ? 'French' : codeLangue.startsWith('es') ? 'Spanish'
      : codeLangue.startsWith('it') ? 'Italian' : 'English'

    const imageParts: any[] = []
    if (imageBase64 && typeof imageBase64 === 'string') {
      imageParts.push({ inlineData: { data: imageBase64, mimeType: mimeType || 'image/jpeg' } })
    }
    if (photoUrls && Array.isArray(photoUrls) && photoUrls.length > 0) {
      for (const url of photoUrls.slice(0, 2)) {
        const { data, error } = await supabase.storage.from('labels').download(url)
        if (!error && data) {
          if (data.size > 5 * 1024 * 1024) continue
          const arrayBuffer = await data.arrayBuffer()
          const base64 = btoa(String.fromCharCode(...new Uint8Array(arrayBuffer)))
          imageParts.push({ inlineData: { data: base64, mimeType: data.type || 'image/jpeg' } })
        }
      }
    }
    if (imageParts.length === 0) {
      return new Response(JSON.stringify({ error: 'No valid image provided (imageBase64 or photoUrls required)' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    const apiKey = Deno.env.get('GEMINI_API_KEY')
    if (!apiKey) {
      return new Response(JSON.stringify({ error: 'GEMINI_API_KEY is not configured' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      })
    }

    // Chaque appel payant est rendu au client, qui l'enregistre dans ai_cost_events (P1) :
    // sans cela, les scans d'étiquette échappaient à la mesure.
    const couts: any[] = []

    // 1. Lire l'étiquette.
    const extractPrompt = `Read this wine bottle label very carefully.
Extract the exact Producer/Estate name, Wine Name, Vintage (Year as integer or null), Specific Cuvée or Parcel (e.g. 'Les Clos', 'Vieilles Vignes', 'Clos des Goisses' if present), Wine Type, Country, Region, Sub-region, Appellation, Classification and Alcohol percentage (%).
Return strictly a valid JSON object matching this schema:
{
  "producer": string,
  "name": string,
  "vintage": number | null,
  "cuvee_parcel": string | null,
  "wine_type": "red" | "white" | "rosé" | "sparkling" | "dessert" | "fortified" | "orange" | "liqueur" | "spirit" | "grappa" | "eau-de-vie" | "whisky" | "gin" | "rum" | "vodka" | "tequila" | "cognac" | "vermouth",
  "country": string | null,
  "region": string | null,
  "sub_region": string | null,
  "appellation": string | null,
  "classification": string | null,
  "alcohol_pct": number | null
}
Spirits, grappas, digestifs and herbal liqueurs (Grappa, Marc, Bénédictine, Chartreuse, Cointreau, Amaretto, Gin, Rum, Whisky, Vodka, Pastis…) take their spirit type, or "liqueur" / "spirit": never red, white, fortified or dessert. "fortified" is only for true fortified wines (Port, Sherry, Banyuls, Madeira, Marsala).
Never guess. Copy what the label shows. For country, region and appellation, use what the label states, or your certain knowledge of this exact producer; otherwise null. Never deduce them from the language of the label or the style of the wine.`
    const lecture = await appelerPourLaFiche(apiKey, [{ role: 'user', parts: [...imageParts, { text: extractPrompt }] }],
      reglages.scan_etiquette_lecture)
    const extracted = lecture.resultat
    couts.push({ fonction: 'scan_vision', modele: lecture.modele, usageMetadata: lecture.usage, recherche: false, reflexion: lecture.reflexion })

    // 2. Le catalogue d'abord : un vin déjà décrit ne se redécrit pas. C'est une économie,
    //    et c'est surtout la cohérence — deux personnes qui scannent le même vin lisent la
    //    même fenêtre de garde, au lieu de deux inventions différentes.
    let fiche: any = null
    if (extracted?.name) {
      try {
        const { data: lignes } = await supabase.rpc('find_cached_wine', {
          p_producer: extracted.producer ?? null,
          p_name: extracted.name,
          p_vintage: extracted.vintage ?? null,
          p_cuvee: extracted.cuvee_parcel ?? null,
        })
        fiche = Array.isArray(lignes) ? lignes[0] : null
        if (!forceRefresh && ficheRiche(fiche)) {
          const verifiee = fiche.is_verified_online === true
          const valeurConnue = verifiee || (fiche.external_links?.valeur_source ?? null) !== null
          return new Response(JSON.stringify({
            ...extracted,
            region: extracted.region || fiche.region,
            sub_region: extracted.sub_region ?? fiche.sub_region,
            appellation: extracted.appellation ?? fiche.appellation,
            classification: extracted.classification ?? fiche.classification,
            alcohol_pct: extracted.alcohol_pct ?? fiche.alcohol_pct,
            grapes: fiche.grapes,
            tasting_notes: fiche.tasting_notes,
            food_pairings: fiche.ai_food_pairings ?? [],
            ideal_drinking_start: fiche.ideal_drinking_start,
            ideal_drinking_end: fiche.ideal_drinking_end,
            peak_drinking_start: fiche.peak_drinking_start,
            peak_drinking_end: fiche.peak_drinking_end,
            ai_summary: fiche.ai_summary,
            // Une valeur de marché ne circule que si elle a une source.
            estimated_market_value: valeurConnue ? fiche.estimated_market_value : null,
            estimated_value_currency: fiche.estimated_value_currency ?? 'EUR',
            last_valuation_date: valeurConnue ? fiche.last_valuation_date : null,
            // Des notes de critiques et des sources ne se transmettent que si une vraie
            // recherche les a trouvées.
            critic_scores: verifiee ? (fiche.critic_scores ?? []) : [],
            sources_verified: verifiee ? (fiche.sources_verified ?? []) : [],
            is_verified_online: verifiee,
            from_cache: true,
            couts,
          }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 })
        }
      } catch (e) {
        console.warn('find_cached_wine indisponible, on enrichit :', e)
      }
    }

    // 3. Vin inconnu (ou fiche pauvre) : on le décrit. Avec la recherche Google si Flavien
    //    l'a activée (app_config.scan_etiquette_recherche) : pour les modèles 3.x, les 5 000
    //    premières requêtes du mois sont offertes, puis 0,014 $ chacune.
    const identite = `Producer: ${extracted.producer || 'Unknown'}
Name: ${extracted.name}
Cuvée/Parcel: ${extracted.cuvee_parcel || 'Standard'}
Vintage: ${extracted.vintage ? extracted.vintage : 'Non-Vintage (NV)'}
Region: ${[extracted.region, extracted.country].filter(Boolean).join(', ') || 'Unknown'}`

    // Sans recherche, on ne demande ni notes de critiques, ni sources, ni valeur de marché :
    // le modèle les inventait (29/09 pour les critiques, 30/09 pour la valeur).
    const enrichPrompt = avecRecherche
      ? `Search the web for this specific wine and extract factual data from trusted sources (producer site, Guide Hachette, RVF, Wine Spectator, Decanter, Jancis Robinson).
${identite}
Write "tasting_notes", "food_pairings" and "ai_summary" in ${langue}; "ai_summary" names the grape varieties.
Return strictly a valid JSON object, and nothing else:
{
  "tasting_notes": string,
  "grapes": [{"name": string, "pct": number | null}],
  "ideal_drinking_start": number | null,
  "ideal_drinking_end": number | null,
  "peak_drinking_start": number | null,
  "peak_drinking_end": number | null,
  "food_pairings": [string],
  "ai_summary": string,
  "estimated_market_value": number | null,
  "valeur_source": string | null,
  "estimated_value_currency": "EUR",
  "critic_scores": [{"source": string, "score": string, "reviewer": string | null, "year": number | null, "notes": string | null}],
  "sources_verified": [string]
}
"estimated_market_value" is a typical current retail price in EUR that you found on a merchant or auction page; "valeur_source" is the URL of that page. Leave both null if you did not find one.
Only include a critic score or a source you actually found. Leave arrays empty rather than guessing.`
      : `Describe this wine as a sommelier would, from general knowledge of its appellation, producer and vintage.
${identite}
If you are unsure about a value, give the typical value for the appellation rather than a precise-looking guess.
Write "tasting_notes", "food_pairings" and "ai_summary" in ${langue}; "ai_summary" names the grape varieties.
Return strictly a valid JSON object matching this schema:
{
  "tasting_notes": string,
  "grapes": [{"name": string, "pct": number | null}],
  "ideal_drinking_start": number | null,
  "ideal_drinking_end": number | null,
  "peak_drinking_start": number | null,
  "peak_drinking_end": number | null,
  "food_pairings": [string],
  "ai_summary": string
}`

    let enriched: any = {}
    let verifiee = false
    try {
      const description = await appelerPourLaFiche(apiKey, [{ role: 'user', parts: [{ text: enrichPrompt }] }],
        reglages.scan_etiquette_description, avecRecherche)
      enriched = description.resultat
      verifiee = description.recherche
      couts.push({
        fonction: 'scan_enrichment', modele: description.modele, usageMetadata: description.usage,
        recherche: description.recherche, requetes: description.requetes, reflexion: description.reflexion,
      })
    } catch (enrichErr) {
      console.warn('Enrichment step warning:', enrichErr)
    }

    const valeur = valeurSourcee(enriched, verifiee)
    await enrichirLeCatalogue(fiche, extracted, enriched, verifiee, valeur)

    const { valeur_source: _source, ...enrichedSansSource } = enriched ?? {}
    const finalResult = {
      ...extracted,
      ...enrichedSansSource,
      estimated_market_value: valeur.valeur,
      estimated_value_currency: 'EUR',
      valeur_source: valeur.source,
      critic_scores: verifiee ? (enriched.critic_scores ?? []) : [],
      sources_verified: verifiee ? (enriched.sources_verified ?? []) : [],
      is_verified_online: verifiee,
      last_valuation_date: valeur.valeur !== null ? new Date().toISOString() : null,
      from_cache: false,
      couts,
    }

    return new Response(JSON.stringify(finalResult), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})
