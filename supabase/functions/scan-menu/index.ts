import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { checkRateLimit, getRateLimitHeaders } from '../_shared/rate_limit.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const GEMINI_MODELS = [
  'gemini-3.8-flash',
  'gemini-3.7-flash',
  'gemini-3.6-flash',
  'gemini-3.5-flash',
  'gemini-flash-latest',
]

async function callGeminiWithFallback(apiKey: string, contents: any[]): Promise<any> {
  let lastError = null
  for (const model of GEMINI_MODELS) {
    try {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents,
          generationConfig: {
            responseMimeType: 'application/json',
          },
        }),
      })

      if (res.ok) {
        const data = await res.json()
        let raw = data.candidates?.[0]?.content?.parts?.[0]?.text || '{}'
        if (raw.includes('```json')) {
          raw = raw.split('```json')[1].split('```')[0].trim()
        } else if (raw.includes('```')) {
          raw = raw.split('```')[1].split('```')[0].trim()
        }
        try {
          return JSON.parse(raw)
        } catch {
          // Attempt basic JSON sanitization
          const repaired = raw.replace(/,\s*([\}\]])/g, '$1')
          const start = repaired.indexOf('{')
          const end = repaired.lastIndexOf('}')
          if (start !== -1 && end !== -1 && end > start) {
            return JSON.parse(repaired.substring(start, end + 1))
          }
        }
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
    const clientIp = req.headers.get('x-forwarded-for') || 'anon'
    const { allowed, retryAfterMs } = checkRateLimit(`scan-menu:${clientIp}`, 20, 60_000)
    if (!allowed) {
      return new Response(JSON.stringify({ error: 'Trop de requêtes. Veuillez patienter.' }), {
        headers: { ...corsHeaders, ...getRateLimitHeaders(retryAfterMs), 'Content-Type': 'application/json' },
        status: 429,
      })
    }

    const body = await req.json()
    const {
      imageBase64,
      imagesBase64,
      mimeType = 'image/jpeg',
      languageCode = 'fr',
      restaurantNameHint,
    } = body

    const imageParts: any[] = []

    if (Array.isArray(imagesBase64) && imagesBase64.length > 0) {
      for (const b64 of imagesBase64) {
        if (b64 && typeof b64 === 'string') {
          imageParts.push({
            inlineData: {
              data: b64,
              mimeType: mimeType || 'image/jpeg',
            },
          })
        }
      }
    } else if (imageBase64 && typeof imageBase64 === 'string') {
      imageParts.push({
        inlineData: {
          data: imageBase64,
          mimeType: mimeType || 'image/jpeg',
        },
      })
    }

    if (imageParts.length === 0) {
      return new Response(JSON.stringify({ error: 'Aucune image valide fournie' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    const apiKey = Deno.env.get('GEMINI_API_KEY')
    if (!apiKey) {
      return new Response(JSON.stringify({ error: 'GEMINI_API_KEY non configurée' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      })
    }

    const isEn = languageCode.toLowerCase().startsWith('en')
    const langInstructions = isEn
      ? `- "tags": Array of relevant keywords in English from: ["mineral", "buttery", "tannic", "fruity", "light", "bold", "oaky", "floral", "spicy", "fresh", "round", "savory"].
- "sommelier_comment": 1 sharp sentence in English describing the style and dining occasion.
- "food_pairings": Array of 3 specific restaurant dish pairings in English.
- "is_gem": boolean. True if this wine is from an acclaimed artisan domain, biodynamic star, cult producer, or exceptional hidden gem.
- "gem_reason": Short reason in English why this is a gem, or null.
- "is_deal": boolean. True if this bottle represents an outstanding value / bargain.
- "deal_reason": Short reason in English why this is a deal, or null.`
      : `- "tags": Array of relevant keywords in French from: ["minéral", "beurré", "tannique", "fruité", "léger", "puissant", "boisé", "floral", "épicé", "frais", "rond", "gourmand"].
- "sommelier_comment": 1 sharp sentence in French describing the style and dining occasion.
- "food_pairings": Array of 3 specific restaurant dish pairings.
- "is_gem": boolean. True if this wine is from an acclaimed artisan domain, biodynamic star, cult producer, or exceptional hidden gem.
- "gem_reason": Short reason in French why this is a gem, or null.
- "is_deal": boolean. True if this bottle represents an outstanding value / bargain.
- "deal_reason": Short reason in French why this is a deal, or null.`

    const systemPrompt = `You are Chatmelier, the world's most capable sommelier and OCR wine recognition AI.
You are given one or multiple photos of pages from a restaurant's wine menu (carte des vins).
Extract EVERY single wine listed across all provided pages.

For each wine, output a JSON object with:
- "name": Official wine cuvée or name (e.g. "Château Smith Haut Lafitte", "Chablis Premier Cru Fourchaume", "Côtes du Rhône Belleruche").
- "producer": Winery, Domaine, Château, or House.
- "vintage": Integer year (e.g. 2019, 2020) or null if non-vintage (NV/NM).
- "wine_type": "red", "white", "rose", "sparkling", "dessert", or "fortified".
- "appellation": AOC/AOP/DOC or sub-appellation.
- "region": Broad wine region (e.g. "Bordeaux", "Bourgogne", "Vallée du Rhône", "Loire", "Alsace", "Toscane").
- "country": Country of origin (e.g. "France", "Italie", "Espagne").
- "grapes": Array of strings of grape varieties.
- "bottle_price": Numeric price for the whole bottle as written on the menu (e.g. 45.0), or null if not available.
- "glass_prices": Array of objects [{"format": "125ml", "price": 7.5}] for glass sizes, or [].
- "metrics": Object with ratings 1.0 to 10.0:
    - "tannins": 0.0 for white/rosé/sparkling, 1.0 to 10.0 for red.
    - "acidity": 1.0 to 10.0.
    - "body": 1.0 to 10.0.
    - "fruit": 1.0 to 10.0.
    - "oak": 1.0 to 10.0.
    - "minerality": 1.0 to 10.0.
    - "butteriness": 0.0 to 10.0.
    - "sweetness": 1.0 to 10.0.
${langInstructions}
- "estimated_retail_price": Estimated typical retail price in euros (e.g. 18.0) or null.

Also extract the restaurant name if visible on headers/cover, else return null.
Return STRICTLY a JSON object with:
{
  "restaurant_name": "Name of restaurant if detected or null",
  "wines": [ ... ]
}`

    const contents = [
      {
        role: 'user',
        parts: [...imageParts, { text: systemPrompt }],
      },
    ]

    const result = await callGeminiWithFallback(apiKey, contents)

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error: any) {
    console.error('Scan menu error:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})
