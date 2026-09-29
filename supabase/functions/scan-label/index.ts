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

const GEMINI_MODELS = [
  'gemini-3.8-flash',
  'gemini-3.7-flash',
  'gemini-3.6-flash',
  'gemini-3.5-flash',
  'gemini-flash-latest',
  'gemini-3.1-flash-lite',
  'gemini-flash-lite-latest',
]

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

async function appelerGemini(apiKey: string, contents: any[], avecRecherche = false): Promise<AppelGemini> {
  let derniereErreur: unknown = null
  for (const model of GEMINI_MODELS) {
    try {
      const url = `${GEMINI_BASE}/v1beta/models/${model}:generateContent?key=${apiKey}`
      // L'outil de recherche et la sortie JSON imposée ne se combinent pas : avec la
      // recherche, on lit le JSON dans le texte.
      const corps = avecRecherche
        ? { contents, tools: [{ google_search: {} }] }
        : { contents, generationConfig: { responseMimeType: 'application/json' } }
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(corps),
        signal: AbortSignal.timeout(avecRecherche ? DELAI_RECHERCHE_MS : DELAI_LECTURE_MS),
      })
      if (res.ok) {
        const data = await res.json()
        const candidat = data.candidates?.[0]
        const raw = candidat?.content?.parts?.map((p: any) => p.text ?? '').join('') || '{}'
        const requetes = candidat?.groundingMetadata?.webSearchQueries
        return {
          resultat: lireJson(raw),
          modele: model,
          usage: data.usageMetadata ?? null,
          recherche: avecRecherche && Array.isArray(requetes) && requetes.length > 0,
        }
      }
      const texte = await res.text()
      console.warn(`Model ${model} returned ${res.status}: ${texte}`)
      derniereErreur = new Error(`Model ${model} error (${res.status})`)
    } catch (e) {
      console.warn(`Model ${model} failed:`, e)
      derniereErreur = e
    }
  }
  throw derniereErreur || new Error('All Gemini models failed')
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

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const body = await req.json()
    const { photoUrls, imageBase64, mimeType = 'image/jpeg', forceRefresh = false } = body

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } } },
    )

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
  "wine_type": "red" | "white" | "rosé" | "sparkling" | "dessert" | "fortified" | "orange",
  "country": string,
  "region": string,
  "sub_region": string | null,
  "appellation": string | null,
  "classification": string | null,
  "alcohol_pct": number | null
}`
    const lecture = await appelerGemini(apiKey, [{ role: 'user', parts: [...imageParts, { text: extractPrompt }] }])
    const extracted = lecture.resultat
    couts.push({ fonction: 'scan_vision', modele: lecture.modele, usageMetadata: lecture.usage, recherche: false })

    // 2. Le catalogue d'abord : un vin déjà décrit ne se redécrit pas. C'est une économie,
    //    et c'est surtout la cohérence — deux personnes qui scannent le même vin lisent la
    //    même fenêtre de garde, au lieu de deux inventions différentes.
    if (!forceRefresh && extracted?.name) {
      try {
        const { data: lignes } = await supabase.rpc('find_cached_wine', {
          p_producer: extracted.producer ?? null,
          p_name: extracted.name,
          p_vintage: extracted.vintage ?? null,
          p_cuvee: extracted.cuvee_parcel ?? null,
        })
        const fiche = Array.isArray(lignes) ? lignes[0] : null
        if (ficheRiche(fiche)) {
          const verifiee = fiche.is_verified_online === true
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
            estimated_market_value: fiche.estimated_market_value,
            estimated_value_currency: fiche.estimated_value_currency ?? 'EUR',
            last_valuation_date: fiche.last_valuation_date,
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
    //    l'a activée (app_config.scan_etiquette_recherche) — elle coûte environ 3 c€, mais
    //    une seule fois par vin puisque la fiche rejoint ensuite le catalogue.
    let avecRecherche = false
    try {
      const { data } = await supabase.from('app_config').select('valeur').eq('cle', 'scan_etiquette_recherche').maybeSingle()
      avecRecherche = data?.valeur === true
    } catch (_) { /* configuration absente : pas de recherche */ }

    const identite = `Producer: ${extracted.producer || 'Unknown'}
Name: ${extracted.name}
Cuvée/Parcel: ${extracted.cuvee_parcel || 'Standard'}
Vintage: ${extracted.vintage ? extracted.vintage : 'Non-Vintage (NV)'}
Region: ${extracted.region}, ${extracted.country}`

    // Sans recherche, on ne demande ni notes de critiques ni sources : le modèle les
    // inventerait, et elles étaient renvoyées marquées « vérifiées » (29/09).
    const enrichPrompt = avecRecherche
      ? `Search the web for this specific wine and extract factual data from trusted sources (producer site, Guide Hachette, RVF, Wine Spectator, Decanter, Jancis Robinson).
${identite}
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
  "estimated_value_currency": "EUR",
  "critic_scores": [{"source": string, "score": string, "reviewer": string | null, "year": number | null, "notes": string | null}],
  "sources_verified": [string]
}
Only include a critic score or a source you actually found. Leave arrays empty rather than guessing.`
      : `Describe this wine as a sommelier would, from general knowledge of its appellation, producer and vintage.
${identite}
If you are unsure about a value, give the typical value for the appellation rather than a precise-looking guess.
Return strictly a valid JSON object matching this schema:
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
  "estimated_value_currency": "EUR"
}`

    let enriched: any = {}
    let verifiee = false
    try {
      const description = await appelerGemini(apiKey, [{ role: 'user', parts: [{ text: enrichPrompt }] }], avecRecherche)
      enriched = description.resultat
      verifiee = description.recherche
      couts.push({ fonction: 'scan_enrichment', modele: description.modele, usageMetadata: description.usage, recherche: description.recherche })
    } catch (enrichErr) {
      console.warn('Enrichment step warning:', enrichErr)
    }

    const finalResult = {
      ...extracted,
      ...enriched,
      critic_scores: verifiee ? (enriched.critic_scores ?? []) : [],
      sources_verified: verifiee ? (enriched.sources_verified ?? []) : [],
      is_verified_online: verifiee,
      last_valuation_date: new Date().toISOString(),
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
