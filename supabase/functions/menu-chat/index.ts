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
// Réglable dans app_config.modeles_ia.question_carte ; les replis vont vers moins cher.
const REPLIS = ['gemini-3.8-flash', 'gemini-3.7-flash', 'gemini-3.6-flash', 'gemini-flash-latest', 'gemini-3.1-flash-lite']
const REGLAGE_PAR_DEFAUT = { modele: 'gemini-3.8-flash', reflexion: 'low' }

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

function niveauPour(modele: string, souhaite: string): string {
  if (souhaite === 'minimal' && /3\.[78]-flash|flash-latest/.test(modele) && !modele.includes('lite')) return 'low'
  return souhaite
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

    const erreurs: string[] = []
    const chaine = [reglage.modele, ...REPLIS].filter((m, i, t) => m && t.indexOf(m) === i)
    for (const modele of chaine) {
      const niveau = niveauPour(modele, reglage.reflexion)
      for (const avecReglage of [true, false]) {
        try {
          const corps: Record<string, unknown> = { contents: [{ role: 'user', parts: [{ text: prompt }] }] }
          if (avecReglage) corps.generationConfig = { thinkingConfig: { thinkingLevel: niveau } }
          // La clé voyage dans l'en-tête, pas dans l'adresse : un message d'erreur réseau cite l'adresse.
          const res = await fetch(`${GEMINI_BASE}/v1beta/models/${modele}:generateContent`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'x-goog-api-key': apiKey },
            body: JSON.stringify(corps),
            signal: AbortSignal.timeout(DELAI_PAR_MODELE_MS),
          })
          if (!res.ok) {
            erreurs.push(`${modele}${avecReglage ? '' : ' (sans réglage)'} : HTTP ${res.status}`)
            if (avecReglage && res.status === 400) continue
            break
          }
          const data = await res.json()
          const reponse = (data.candidates?.[0]?.content?.parts ?? [])
            .filter((p: { thought?: boolean }) => !p.thought)
            .map((p: { text?: string }) => p.text ?? '')
            .join('')
            .trim()
          if (!reponse) {
            erreurs.push(`${modele} : réponse vide`)
            break
          }
          const usage = data.usageMetadata ?? null
          return json({
            reponse, modele, usageMetadata: usage,
            couts: [{ fonction: 'menu_chat_assistant', modele, usageMetadata: usage, recherche: false, reflexion: avecReglage ? niveau : null }],
          })
        } catch (e) {
          const err = e as Error
          erreurs.push(`${modele} : ${err.name === 'TimeoutError' ? 'délai dépassé' : err.message}`)
          break
        }
      }
    }

    console.error('menu-chat : aucun modèle n\'a répondu', erreurs)
    return json({ error: 'Aucun modèle n\'a répondu', details: erreurs }, 502)
  } catch (error) {
    console.error('menu-chat error:', error)
    return json({ error: (error as Error).message }, 500)
  }
})
