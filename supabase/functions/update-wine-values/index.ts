import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-cron-secret',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const cronSecret = req.headers.get('x-cron-secret')
    if (cronSecret !== Deno.env.get('CRON_SECRET')) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    )

    const url = new URL(req.url)
    const monthsInterval = parseInt(url.searchParams.get('months') || '6')
    if (isNaN(monthsInterval)) {
      return new Response(JSON.stringify({ error: 'Invalid months parameter' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    // Find all active wines whose valuation is older than 6 months
    const { data: winesToUpdate, error } = await supabase.rpc('get_wines_needing_revaluation', {
      p_months_interval: monthsInterval
    })

    if (error) throw error
    if (!winesToUpdate || winesToUpdate.length === 0) {
      return new Response(JSON.stringify({ message: "All wine valuations are up to date (< 6 months)." }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })
    }

    const apiKey = Deno.env.get('GEMINI_API_KEY')
    if (!apiKey) throw new Error("GEMINI_API_KEY is not configured")

    // Une cote n'a de valeur que sourcée (V2.3 · B3). Jusqu'au 30/09, ce prompt demandait au
    // modèle de « chercher les annonces du marché » sans lui donner d'outil de recherche : il
    // inventait un prix, enregistré comme la valeur de la bouteille. Désormais la recherche
    // Google est active, et une valeur sans page source n'est pas enregistrée.
    const base = Deno.env.get('GEMINI_BASE_URL') ?? 'https://generativelanguage.googleapis.com'
    const geminiUrl = `${base}/v1beta/models/gemini-3.8-flash:generateContent?key=${apiKey}`
    const results = []
    const ignores = []

    for (const wine of winesToUpdate.slice(0, 10)) {
      const prompt = `Search current merchant or auction listings for this wine:
Estate / Producer: ${wine.producer || 'Unknown'}
Wine: ${wine.wine_name}
Cuvée/Parcel: ${wine.cuvee_parcel || 'Standard'}
Vintage: ${wine.vintage || 'NV'}

Return strictly a JSON object, and nothing else:
{"current_market_value": number | null, "currency": "EUR", "source_url": string | null}
"source_url" is the page where you found the price. If you found no listing, return nulls: never estimate.`

      const response = await fetch(geminiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ role: 'user', parts: [{ text: prompt }] }],
          tools: [{ google_search: {} }],
          generationConfig: { thinkingConfig: { thinkingLevel: 'low' } },
        }),
      })

      if (!response.ok) continue
      const valRes = await response.json()
      const candidat = valRes.candidates?.[0]
      const recherches = candidat?.groundingMetadata?.webSearchQueries
      let texte = (candidat?.content?.parts ?? []).filter((p: any) => !p.thought).map((p: any) => p.text ?? '').join('')
      if (texte.includes('```')) texte = texte.split('```json').pop()!.split('```')[0]
      let valData: any = {}
      try { valData = JSON.parse(texte.slice(texte.indexOf('{'), texte.lastIndexOf('}') + 1)) } catch (_) { /* illisible */ }
      const valeur = Number(valData.current_market_value)
      const source = typeof valData.source_url === 'string' && /^https?:\/\//.test(valData.source_url) ? valData.source_url : null
      if (!Array.isArray(recherches) || recherches.length === 0 || !source || !Number.isFinite(valeur) || valeur <= 0) {
        ignores.push({ wine_id: wine.wine_id, name: wine.wine_name, raison: 'aucune cote sourcée' })
        continue
      }
      await supabase.rpc('record_wine_valuation', {
        p_wine_id: wine.wine_id,
        p_new_value: valeur,
        p_currency: valData.currency || 'EUR',
        p_source: source,
      })
      const { data: fiche } = await supabase.from('wines').select('external_links').eq('id', wine.wine_id).maybeSingle()
      await supabase.from('wines')
        .update({ external_links: { ...(fiche?.external_links ?? {}), valeur_source: source } })
        .eq('id', wine.wine_id)
      results.push({
        wine_id: wine.wine_id,
        name: wine.wine_name,
        vintage: wine.vintage,
        old_value: wine.estimated_market_value,
        new_value: valeur,
        source,
      })
    }

    return new Response(JSON.stringify({ updated_count: results.length, updates: results, ignores }), {
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
