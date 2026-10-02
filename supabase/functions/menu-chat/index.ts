import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0'

// Le sommelier de la carte : une question, la carte scannée, une réponse.
//
// Jusqu'au 28/09, l'app appelait Gemini directement avec la clé embarquée dans le build.
// Cette clé a été retirée le 14/09 (S0) : depuis, chaque question échouait en silence et
// l'écran affichait « impossible de joindre le sommelier IA » (incident du 23/09, 19h07).
// La clé reste ici, côté serveur, comme pour `scan-menu`.
//
// Ce n'est pas un relais Gemini générique : les consignes sont fixées ici, la carte et la
// question sont plafonnées, et chaque personne a un quota du jour (V2.3 · B2).

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function json(body: unknown, status = 200, extra: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json', ...extra },
  })
}

const GEMINI_BASE = Deno.env.get('GEMINI_BASE_URL') ?? 'https://generativelanguage.googleapis.com'

// ─── Garde commune (V2.3 · B2) ───────────────────────────────────────────────────
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
    if (strict) return json({ error: 'session_requise' }, 401)
    const ip = (req.headers.get('x-forwarded-for') ?? 'anon').split(',')[0].trim()
    const { allowed, retryAfterMs } = checkRateLimit(`${fonction}:${ip}`, 12, 60_000)
    if (!allowed) {
      return json({ error: 'Trop de questions à la suite. Patientez quelques secondes.' }, 429,
        { 'Retry-After': String(Math.ceil(retryAfterMs / 1000)) })
    }
    return null
  }
  try {
    const { data, error } = await supabase.rpc('consommer_quota_ia', { p_fonction: fonction })
    if (!error && data && data.autorise === false && data.raison === 'limite') {
      return json({ error: 'limite_du_jour', limite: data.limite, anonyme: data.anonyme === true }, 429)
    }
  } catch (_) { /* migration 052 absente : pas de quota */ }
  return null
}

// ─── Modèles ─────────────────────────────────────────────────────────────────────
// Réglable dans app_config.modeles_ia.question_carte (nom exact choisi par le banc d'essai).
// Par défaut : le plus récent Flash stable.
const REGLAGE_PAR_DEFAUT: Reglage = { modele: 'flash', reflexion: 'low' }

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

type Reglage = { modele: string; reflexion: string | null }
type AppelReussi = { data: any; modele: string; reflexion: string | null }

const FAMILLES_GEMINI = ['flash-lite', 'flash', 'pro']
const NIVEAUX_DE_REFLEXION = ['minimal', 'low', 'medium', 'high']
const MODELES_ESSAYES_AU_PLUS = 3
let catalogueDesModeles: { quand: number; modeles: string[] } | null = null
const niveauxRetenus = new Map<string, string | null>()

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
  if (catalogueDesModeles && Date.now() - catalogueDesModeles.quand < 6 * 3600_000) return catalogueDesModeles.modeles
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
  const premier = (f: string) => stables.find((m) => familleDe(m) === f && !dejaEssayes.has(m))
  const relais = [premier(famille), premier(autre)].filter((m): m is string => !!m)
  if (relais.length > 0) return relais
  return [`gemini-${famille}-latest`].filter((m) => !dejaEssayes.has(m))
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
  let derniereErreur: unknown = null
  const famille = estUneFamille(reglage.modele)
  let candidats = famille ? await modelesDeRelais(apiKey, reglage.modele, essayes) : [reglage.modele]
  let relaisAjoutes = famille
  for (let i = 0; i < candidats.length && essayes.size < MODELES_ESSAYES_AU_PLUS; i++) {
    const modele = candidats[i]
    essayes.add(modele)
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
          return { data, modele: servi, reflexion: niveau }
        }
        const texte = await res.text()
        console.warn(`Model ${modele} (réflexion ${niveau ?? 'par défaut'}) returned ${res.status}: ${texte.slice(0, 300)}`)
        derniereErreur = new Error(`Model ${modele} error (${res.status})`)
        // Un niveau de réflexion refusé : le cran au-dessus, puis sans réglage.
        niveau = res.status === 400 && niveau !== null && /thinking/i.test(texte) ? niveauAuDessus(niveau) : undefined
      } catch (e) {
        console.warn(`Model ${modele} failed:`, e instanceof Error ? e.message : e)
        derniereErreur = e
        niveau = undefined
      }
    }
    if (!relaisAjoutes && i === candidats.length - 1) {
      relaisAjoutes = true
      candidats = [...candidats, ...(await modelesDeRelais(apiKey, reglage.modele, essayes))]
    }
  }
  throw derniereErreur || new Error('All Gemini models failed')
}

// Le texte d'une réponse, sans les pensées du modèle.
function texteDeLaReponse(data: any): string {
  return data?.candidates?.[0]?.content?.parts?.filter((p: any) => !p.thought).map((p: any) => p.text ?? '').join('') ?? ''
}
// <<< Modèles Gemini <<<

// Une réponse de sommelier tient en quelques secondes ; au-delà, on essaie le suivant.
const DELAI_PAR_MODELE_MS = 25_000

const LIMITES = { question: 1_000, carte: 40_000, profil: 3_000, restaurant: 120 }

function texte(valeur: unknown, max: number): string {
  return typeof valeur === 'string' ? valeur.trim().slice(0, max) : ''
}

type Langue = 'fr' | 'en' | 'es'
function langueDe(code: unknown): Langue {
  const c = String(code ?? 'fr').toLowerCase()
  if (c.startsWith('fr')) return 'fr'
  if (c.startsWith('es')) return 'es'
  return 'en'
}

function redigerPrompt(langue: Langue, restaurant: string, carte: string, profil: string, question: string): string {
  if (langue === 'fr') {
    return `Tu es Chatmelier, le maître sommelier du restaurant « ${restaurant} ».
Voici la carte des vins exacte disponible à table :
${carte}
${profil ? `\nProfil de goût du client :\n${profil}\n` : ''}
Question du client :
« ${question} »

Consignes absolues :
1. Réponds en français, de façon chaleureuse, précise et experte, comme un sommelier à table.
2. Recommande EXCLUSIVEMENT des vins figurant sur la carte ci-dessus. N'invente aucun vin.
3. Mentionne toujours le prix (à la bouteille ou au verre) tel qu'affiché sur la carte.
4. Explique l'accord ou la raison de ton conseil par le caractère du vin (tanins, minéralité, vivacité, boisé).
5. Sois concis (2 à 3 paragraphes courts au maximum).`
  }
  if (langue === 'es') {
    return `Eres Chatmelier, el sumiller jefe del restaurante «${restaurant}».
Esta es la carta de vinos exacta disponible en la mesa:
${carte}
${profil ? `\nPerfil de gusto del cliente:\n${profil}\n` : ''}
El cliente pregunta:
«${question}»

Reglas absolutas:
1. Responde en español, con calidez y precisión, como un sumiller en la mesa.
2. Recomienda SOLO vinos de la carta anterior. Nunca inventes un vino que no esté en ella.
3. Indica siempre el precio (botella o copa) exactamente como aparece en la carta.
4. Explica el maridaje o el motivo de tu consejo por el carácter del vino (taninos, mineralidad, frescura, madera).
5. Sé conciso (2 o 3 párrafos cortos como máximo).`
  }
  return `You are Chatmelier, the head sommelier of "${restaurant}".
Here is the exact wine list available at the table:
${carte}
${profil ? `\nThe guest's taste profile:\n${profil}\n` : ''}
The guest asks:
"${question}"

Absolute rules:
1. Answer in English, warmly and precisely, like a sommelier at the table.
2. Recommend ONLY wines from the list above. Never invent a wine that is not on it.
3. Always quote the price (bottle or glass) exactly as shown on the list.
4. Explain the pairing or the reason for your advice from the wine's character (tannins, minerality, freshness, oak).
5. Be concise (2 to 3 short paragraphs at most).`
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
    const refus = await garder(req, supabase, 'question_carte', config.ia_session_obligatoire === true)
    if (refus) return refus

    const body = await req.json()
    const question = texte(body.question, LIMITES.question)
    const carte = texte(body.carte, LIMITES.carte)
    const profil = texte(body.profil, LIMITES.profil)
    const restaurant = texte(body.restaurantName, LIMITES.restaurant) || 'ce restaurant'
    const langue = langueDe(body.languageCode)

    if (!question) return json({ error: 'Question vide' }, 400)
    if (!carte) return json({ error: 'Carte vide' }, 400)

    const apiKey = Deno.env.get('GEMINI_API_KEY')
    if (!apiKey) return json({ error: 'GEMINI_API_KEY non configurée' }, 500)

    const r = config.modeles_ia?.question_carte
    const reglage = r && typeof r.modele === 'string'
      ? { modele: r.modele, reflexion: typeof r.reflexion === 'string' ? r.reflexion : REGLAGE_PAR_DEFAUT.reflexion }
      : REGLAGE_PAR_DEFAUT
    const prompt = redigerPrompt(langue, restaurant, carte, profil, question)

    let appel: AppelReussi
    try {
      appel = await appelerGemini(apiKey, reglage, (niveau) => ({
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        ...(niveau ? { generationConfig: { thinkingConfig: { thinkingLevel: niveau } } } : {}),
      }), DELAI_PAR_MODELE_MS, (data) => texteDeLaReponse(data).trim().length > 0)
    } catch (e) {
      const detail = e instanceof Error ? (e.name === 'TimeoutError' ? 'délai dépassé' : e.message) : String(e)
      console.error('menu-chat : aucun modèle n\'a répondu', detail)
      return json({ error: 'Aucun modèle n\'a répondu', details: [detail] }, 502)
    }
    const reponse = texteDeLaReponse(appel.data).trim()
    const usage = appel.data.usageMetadata ?? null
    return json({
      reponse, modele: appel.modele, usageMetadata: usage,
      couts: [{ fonction: 'menu_chat_assistant', modele: appel.modele, usageMetadata: usage, recherche: false, reflexion: appel.reflexion }],
    })
  } catch (error) {
    console.error('menu-chat error:', error)
    return json({ error: (error as Error).message }, 500)
  }
})
