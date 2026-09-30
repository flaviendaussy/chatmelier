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
// Le modèle se règle dans app_config.modeles_ia.scan_carte, sans redéploiement. Les replis
// vont vers moins cher : gemini-3.5-flash (1,50 $ / 9 $ le million) n'y figure plus.
const REPLIS = ['gemini-3.8-flash', 'gemini-3.7-flash', 'gemini-3.6-flash', 'gemini-flash-latest', 'gemini-3.1-flash-lite']
const REGLAGE_PAR_DEFAUT = { modele: 'gemini-3.8-flash', reflexion: 'minimal' }

// Un modèle bloqué ne doit pas consommer tout le budget de la fonction (150 s) : au-delà
// de ce délai on passe au suivant. Une page dense se lit en 15 à 25 s.
const DELAI_PAR_MODELE_MS = 75_000

function niveauPour(modele: string, souhaite: string): string {
  // 3.7 et 3.8 Flash n'acceptent pas « minimal » (doc du 30/09) : le plus bas est « low ».
  if (souhaite === 'minimal' && /3\.[78]-flash|flash-latest/.test(modele) && !modele.includes('lite')) return 'low'
  return souhaite
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

async function appelerGemini(apiKey: string, contents: any[], reglage: { modele: string; reflexion: string }) {
  let derniereErreur: unknown = null
  const chaine = [reglage.modele, ...REPLIS].filter((m, i, t) => m && t.indexOf(m) === i)
  for (const model of chaine) {
    const niveau = niveauPour(model, reglage.reflexion)
    // Avec le réglage de réflexion d'abord ; si Google le refuse (400), le même modèle sans.
    for (const avecReglage of [true, false]) {
      try {
        const generationConfig: Record<string, unknown> = { responseMimeType: 'application/json' }
        if (avecReglage) generationConfig.thinkingConfig = { thinkingLevel: niveau }
        const res = await fetch(`${GEMINI_BASE}/v1beta/models/${model}:generateContent?key=${apiKey}`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ contents, generationConfig }),
          signal: AbortSignal.timeout(DELAI_PAR_MODELE_MS),
        })
        if (res.ok) {
          const data = await res.json()
          const raw = data.candidates?.[0]?.content?.parts?.filter((p: any) => !p.thought).map((p: any) => p.text ?? '').join('') || '{}'
          return { resultat: lireJson(raw), modele: model, usage: data.usageMetadata ?? null, reflexion: avecReglage ? niveau : null }
        }
        const texte = await res.text()
        console.warn(`Model ${model} (réflexion ${avecReglage ? niveau : 'par défaut'}) returned ${res.status}: ${texte.slice(0, 300)}`)
        derniereErreur = new Error(`Model ${model} error (${res.status})`)
        if (!(avecReglage && res.status === 400)) break
      } catch (e) {
        console.warn(`Model ${model} failed:`, e)
        derniereErreur = e
        break
      }
    }
  }
  throw derniereErreur || new Error('All Gemini models failed')
}

// ─── La carte, en format court ───────────────────────────────────────────────────
// Le modèle rendait 19 clés longues par vin, commentaires compris : l'essentiel de la
// sortie, facturée cinq fois l'entrée. Il rend maintenant des clés courtes, des métriques
// entières et des codes de goût ; le serveur reconstruit le JSON que l'app connaît, si bien
// que la version installée ne voit aucune différence. Le « prix de détail estimé » n'est
// plus demandé : il était inventé.
type Langue = 'fr' | 'en' | 'es'

const GOUTS: Record<string, Record<Langue, string>> = {
  mineral: { fr: 'minéral', en: 'mineral', es: 'mineral' },
  buttery: { fr: 'beurré', en: 'buttery', es: 'mantecoso' },
  tannic: { fr: 'tannique', en: 'tannic', es: 'tánico' },
  fruity: { fr: 'fruité', en: 'fruity', es: 'afrutado' },
  light: { fr: 'léger', en: 'light', es: 'ligero' },
  bold: { fr: 'puissant', en: 'bold', es: 'potente' },
  oaky: { fr: 'boisé', en: 'oaky', es: 'con madera' },
  floral: { fr: 'floral', en: 'floral', es: 'floral' },
  spicy: { fr: 'épicé', en: 'spicy', es: 'especiado' },
  fresh: { fr: 'frais', en: 'fresh', es: 'fresco' },
  round: { fr: 'rond', en: 'round', es: 'redondo' },
  savory: { fr: 'gourmand', en: 'savory', es: 'sabroso' },
}
const TYPES: Record<string, string> = { r: 'red', w: 'white', p: 'rose', s: 'sparkling', d: 'dessert', f: 'fortified' }
const NOMS_DE_LANGUE: Record<Langue, string> = { fr: 'French', en: 'English', es: 'Spanish' }

function langueDe(code: unknown): Langue {
  const c = String(code ?? 'fr').toLowerCase()
  if (c.startsWith('fr')) return 'fr'
  if (c.startsWith('es')) return 'es'
  return 'en'
}

function consigne(langue: Langue): string {
  const l = NOMS_DE_LANGUE[langue]
  return `You are Chatmelier, a sommelier reading a restaurant wine list.
You are given one or several photos of the pages of the wine list. Extract EVERY wine listed across all pages.

Return STRICTLY one JSON object, with these short keys:
{"r": restaurant name if printed on the pages, else null,
 "c": ISO 4217 code of the prices ("EUR", "GBP", "USD", "CHF"...) from the symbols on the list, or from its country and language; null only if no price is shown,
 "v": [one object per wine]}

Each wine object:
"n": official wine or cuvée name, as printed
"p": producer (domaine, château, house), or null
"y": vintage as an integer, or null if non-vintage
"t": type, one letter: r red, w white, p rosé, s sparkling, d dessert, f fortified
"a": appellation, or null
"rg": broad region, in French (Bordeaux, Bourgogne, Vallée du Rhône, Loire, Alsace, Champagne, Toscane...)
"co": country, in French (France, Italie, Espagne...)
"g": grape varieties, array of strings (typical ones for the appellation if not printed)
"b": bottle price as printed (number), or null
"gl": glass prices as [[format, price]], e.g. [["12cl", 8]], or []
"m": 8 integers from 0 to 10, in this order: tannins (0 for white, rosé, sparkling), acidity, body, fruit, oak, minerality, butteriness, sweetness
"tg": up to 3 codes among mineral, buttery, tannic, fruity, light, bold, oaky, floral, spicy, fresh, round, savory
"sc": one short sentence in ${l} (at most 14 words) on the style and when to drink it
"fp": 3 restaurant dishes in ${l}, at most 4 words each
"ge": 1 if a genuine gem (acclaimed artisan, cult or biodynamic star, rare find), else 0
"gr": if ge is 1, why, in ${l}, at most 8 words; else ""
"de": 1 if outstanding value for this list, else 0
"dr": if de is 1, why, in ${l}, at most 8 words; else ""

Do not add any other key. Do not invent wines that are not on the pages.`
}

function nombre(v: unknown): number | null {
  const n = typeof v === 'number' ? v : typeof v === 'string' ? parseFloat(v.replace(',', '.')) : NaN
  return Number.isFinite(n) ? n : null
}

function deplier(court: any, langue: Langue): any {
  // Le modèle a répondu dans l'ancien format : on le rend tel quel.
  if (court && Array.isArray(court.wines)) return court
  const vins = Array.isArray(court?.v) ? court.v : []
  return {
    restaurant_name: typeof court?.r === 'string' && court.r.trim() ? court.r.trim() : null,
    currency: typeof court?.c === 'string' && /^[A-Z]{3}$/.test(court.c) ? court.c : null,
    wines: vins.filter((w: any) => w && typeof w.n === 'string' && w.n.trim()).map((w: any) => {
      const m = Array.isArray(w.m) ? w.m.map((x: unknown) => Math.max(0, Math.min(10, nombre(x) ?? 5))) : []
      const type = TYPES[String(w.t ?? '').toLowerCase()] ?? 'red'
      const blancOuBulles = type !== 'red'
      return {
        name: w.n.trim(),
        producer: w.p ?? null,
        vintage: Number.isInteger(w.y) ? w.y : null,
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
        is_gem: w.ge === 1 || w.ge === true,
        gem_reason: (w.ge === 1 || w.ge === true) && typeof w.gr === 'string' && w.gr.trim() ? w.gr.trim() : null,
        is_deal: w.de === 1 || w.de === true,
        deal_reason: (w.de === 1 || w.de === true) && typeof w.dr === 'string' && w.dr.trim() ? w.dr.trim() : null,
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
    const reglage = r && typeof r.modele === 'string'
      ? { modele: r.modele, reflexion: typeof r.reflexion === 'string' ? r.reflexion : REGLAGE_PAR_DEFAUT.reflexion }
      : REGLAGE_PAR_DEFAUT

    const langue = langueDe(languageCode)
    const { resultat, modele, usage, reflexion } = await appelerGemini(apiKey,
      [{ role: 'user', parts: [...imageParts, { text: consigne(langue) }] }], reglage)

    // `modele`, `usageMetadata` et `couts` : le client journalise quel modèle a lu la carte et
    // comptabilise le coût réel de l'appel.
    return reponse({
      ...deplier(resultat, langue),
      modele,
      usageMetadata: usage,
      couts: [{ fonction: 'menu_scan_vision', modele, usageMetadata: usage, recherche: false, reflexion }],
    })
  } catch (error: any) {
    console.error('Scan menu error:', error)
    return reponse({ error: error.message }, 500)
  }
})
