import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'

// Limiteur de débit en mémoire (copie de `_shared/rate_limit.ts`, intégrée pour que la
// fonction se déploie d'un seul fichier depuis l'éditeur du Dashboard). Il repart à zéro à
// chaque démarrage à froid : c'est une protection de base, pas un quota.
const requestCounts = new Map<string, { count: number; resetAt: number }>()

function checkRateLimit(
  identifier: string,
  maxRequests = 10,
  windowMs = 60_000,
): { allowed: boolean; retryAfterMs: number } {
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

function getRateLimitHeaders(retryAfterMs: number): Record<string, string> {
  return {
    'Retry-After': String(Math.ceil(retryAfterMs / 1000)),
    'X-RateLimit-Reset': String(Math.ceil(retryAfterMs / 1000)),
  }
}

// Le sommelier de la carte : une question, la carte scannée, une réponse.
//
// Jusqu'au 28/09, l'app appelait Gemini directement avec la clé embarquée dans le build.
// Cette clé a été retirée le 14/09 (S0) : depuis, chaque question échouait en silence et
// l'écran affichait « impossible de joindre le sommelier IA » (incident du 23/09, 19h07).
// La clé reste ici, côté serveur, comme pour `scan-menu`.
//
// Ce n'est pas un relais Gemini générique : les consignes sont fixées ici, la carte et la
// question sont plafonnées, et le débit est limité par adresse.

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const MODELES = [
  'gemini-3.8-flash',
  'gemini-3.7-flash',
  'gemini-3.6-flash',
  'gemini-3.5-flash',
  'gemini-flash-latest',
]

// Une réponse de sommelier tient en quelques secondes ; au-delà, on essaie le suivant.
const DELAI_PAR_MODELE_MS = 25_000

const LIMITES = { question: 1_000, carte: 40_000, profil: 3_000, restaurant: 120 }

function json(body: unknown, status = 200, extra: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json', ...extra },
  })
}

function texte(valeur: unknown, max: number): string {
  return typeof valeur === 'string' ? valeur.trim().slice(0, max) : ''
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const clientIp = req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() || 'anon'
    const { allowed, retryAfterMs } = checkRateLimit(`menu-chat:${clientIp}`, 12, 60_000)
    if (!allowed) {
      return json({ error: 'Trop de questions à la suite. Patientez quelques secondes.' }, 429,
        getRateLimitHeaders(retryAfterMs))
    }

    const body = await req.json()
    const question = texte(body.question, LIMITES.question)
    const carte = texte(body.carte, LIMITES.carte)
    const profil = texte(body.profil, LIMITES.profil)
    const restaurant = texte(body.restaurantName, LIMITES.restaurant) || 'ce restaurant'
    const enAnglais = String(body.languageCode ?? 'fr').toLowerCase().startsWith('en')

    if (!question) return json({ error: 'Question vide' }, 400)
    if (!carte) return json({ error: 'Carte vide' }, 400)

    const apiKey = Deno.env.get('GEMINI_API_KEY')
    if (!apiKey) return json({ error: 'GEMINI_API_KEY non configurée' }, 500)

    const consignes = enAnglais
      ? `Absolute rules:
1. Answer in English, warmly and precisely, like a sommelier at the table.
2. Recommend ONLY wines from the list above. Never invent a wine that is not on it.
3. Always quote the price (bottle or glass) exactly as shown on the list.
4. Explain the pairing or the reason for your advice from the wine's character (tannins, minerality, freshness, oak).
5. Be concise (2 to 3 short paragraphs at most).`
      : `Consignes absolues :
1. Réponds en français, de façon chaleureuse, précise et experte, comme un sommelier à table.
2. Recommande EXCLUSIVEMENT des vins figurant sur la carte ci-dessus. N'invente aucun vin.
3. Mentionne toujours le prix (à la bouteille ou au verre) tel qu'affiché sur la carte.
4. Explique l'accord ou la raison de ton conseil par le caractère du vin (tanins, minéralité, vivacité, boisé).
5. Sois concis (2 à 3 paragraphes courts au maximum).`

    const prompt = enAnglais
      ? `You are Chatmelier, the head sommelier of "${restaurant}".
Here is the exact wine list available at the table:
${carte}
${profil ? `\nThe guest's taste profile:\n${profil}\n` : ''}
The guest asks:
"${question}"

${consignes}`
      : `Tu es Chatmelier, le maître sommelier du restaurant « ${restaurant} ».
Voici la carte des vins exacte disponible à table :
${carte}
${profil ? `\nProfil de goût du client :\n${profil}\n` : ''}
Question du client :
« ${question} »

${consignes}`

    const erreurs: string[] = []
    for (const modele of MODELES) {
      try {
        const res = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models/${modele}:generateContent?key=${apiKey}`,
          {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ contents: [{ role: 'user', parts: [{ text: prompt }] }] }),
            signal: AbortSignal.timeout(DELAI_PAR_MODELE_MS),
          },
        )
        if (!res.ok) {
          erreurs.push(`${modele} : HTTP ${res.status}`)
          continue
        }
        const data = await res.json()
        const reponse = (data.candidates?.[0]?.content?.parts ?? [])
          .map((p: { text?: string }) => p.text ?? '')
          .join('')
          .trim()
        if (!reponse) {
          erreurs.push(`${modele} : réponse vide`)
          continue
        }
        return json({ reponse, modele, usageMetadata: data.usageMetadata ?? null })
      } catch (e) {
        const err = e as Error
        erreurs.push(`${modele} : ${err.name === 'TimeoutError' ? 'délai dépassé' : err.message}`)
      }
    }

    console.error('menu-chat : aucun modèle n\'a répondu', erreurs)
    return json({ error: 'Aucun modèle n\'a répondu', details: erreurs }, 502)
  } catch (error) {
    console.error('menu-chat error:', error)
    return json({ error: (error as Error).message }, 500)
  }
})
