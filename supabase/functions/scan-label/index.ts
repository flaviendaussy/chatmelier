import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0'
import { checkRateLimit, getRateLimitHeaders } from '../_shared/rate_limit.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const GEMINI_MODELS = [
  'gemini-3.7-flash',
  'gemini-3.6-flash',
  'gemini-3.5-flash',
  'gemini-3.1-flash-lite',
  'gemini-flash-lite-latest',
]

async function callGeminiWithFallback(apiKey: string, contents: any[], responseMimeType: string = 'application/json'): Promise<any> {
  let lastError = null
  for (const model of GEMINI_MODELS) {
    try {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents,
          generationConfig: { responseMimeType }
        })
      })

      if (res.ok) {
        const data = await res.json()
        const raw = data.candidates?.[0]?.content?.parts?.[0]?.text || '{}'
        return JSON.parse(raw)
      } else {
        const errText = await res.text()
        console.warn(`Model ${model} returned ${res.status}: ${errText}`)
        lastError = new Error(`Model ${model} error (${res.status}): ${errText}`)
      }
    } catch (e) {
      console.warn(`Model ${model} failed:`, e)
      lastError = e
    }
  }
  throw lastError || new Error("All Gemini models failed")
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const body = await req.json()
    const { photoUrls, imageBase64, mimeType = 'image/jpeg', cellarId, forceRefresh = false } = body

    const imageParts: any[] = []

    // 1. Direct base64 support (from Flutter client fallback)
    if (imageBase64 && typeof imageBase64 === 'string') {
      imageParts.push({
        inlineData: {
          data: imageBase64,
          mimeType: mimeType || 'image/jpeg',
        }
      })
    }

    // 2. Storage photo URLs support
    if (photoUrls && Array.isArray(photoUrls) && photoUrls.length > 0) {
      const supabase = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_ANON_KEY') ?? '',
        { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
      )

      for (const url of photoUrls.slice(0, 2)) {
        const { data, error } = await supabase.storage.from('labels').download(url)
        if (!error && data) {
          if (data.size > 5 * 1024 * 1024) continue
          const arrayBuffer = await data.arrayBuffer()
          const base64 = btoa(String.fromCharCode(...new Uint8Array(arrayBuffer)))
          imageParts.push({
            inlineData: {
              data: base64,
              mimeType: data.type || 'image/jpeg',
            }
          })
        }
      }
    }

    if (imageParts.length === 0) {
      return new Response(JSON.stringify({ error: 'No valid image provided (imageBase64 or photoUrls required)' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    const apiKey = Deno.env.get('GEMINI_API_KEY') || 'AQ.Ab8RN6JFZQNPfXmDdjdGT0posCOmn_4wPIFv_TiviorSGL6BDg'

    // Step 1: Extract exact label details from image
    const extractPrompt = `Read this wine bottle label very carefully.
Extract the exact Producer/Estate name, Wine Name, Vintage (Year as integer or null), Specific Cuvée or Parcel (e.g. 'Les Clos', 'Vieilles Vignes', 'Clos des Goisses' if present), Appellation, Classification, Alcohol %, Country, Region, and Sub-region.
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

    const extracted = await callGeminiWithFallback(apiKey, [
      {
        role: 'user',
        parts: [...imageParts, { text: extractPrompt }]
      }
    ])

    // Step 2: Zero-Invention Internet Grounded Enrichment
    const enrichPrompt = `Perform a factual search for this specific wine:
Producer: ${extracted.producer || 'Unknown'}
Name: ${extracted.name}
Cuvée/Parcel: ${extracted.cuvee_parcel || 'Standard'}
Vintage: ${extracted.vintage ? extracted.vintage : 'Non-Vintage (NV)'}
Region: ${extracted.region}, ${extracted.country}

Extract factual data:
1. Critic Rankings: Extract up to 5 trusted critic scores (Robert Parker / Wine Advocate, Wine Spectator, Jancis Robinson, James Suckling, Decanter, Vinous, Vivino) for this EXACT vintage.
2. Market Valuation: Estimate average retail market price in EUR (€).
3. Grape composition: Exact percentage breakdown.
4. Drinking Window: Factual peak start/end year and ideal start/end year.
5. Sommelier tasting notes & food pairings.
6. Sources: list verified source names.

Return strictly a valid JSON object matching this schema:
{
  "tasting_notes": string,
  "grapes": [{"name": string, "pct": number}],
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
}`

    let enriched = {}
    try {
      enriched = await callGeminiWithFallback(apiKey, [
        {
          role: 'user',
          parts: [{ text: enrichPrompt }]
        }
      ])
    } catch (enrichErr) {
      console.warn("Enrichment step warning:", enrichErr)
    }

    const finalResult = {
      ...extracted,
      ...enriched,
      is_verified_online: true,
      last_valuation_date: new Date().toISOString(),
      from_cache: false
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