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

    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=${apiKey}`
    const results = []

    for (const wine of winesToUpdate.slice(0, 10)) {
      const prompt = `Search current market listings for this wine:
Estate / Producer: ${wine.producer || 'Unknown'}
Wine: ${wine.wine_name}
Cuvée/Parcel: ${wine.cuvee_parcel || 'Standard'}
Vintage: ${wine.vintage || 'NV'}
Previous estimated value: ${wine.estimated_market_value || 'None'} EUR

Return strictly JSON:
{
  "current_market_value": number,
  "currency": "EUR"
}`

      const response = await fetch(geminiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ role: 'user', parts: [{ text: prompt }] }],
          generationConfig: { responseMimeType: 'application/json' }
        })
      })

      if (response.ok) {
        const valRes = await response.json()
        const valData = JSON.parse(valRes.candidates?.[0]?.content?.parts?.[0]?.text || '{}')
        if (valData.current_market_value) {
          await supabase.rpc('record_wine_valuation', {
            p_wine_id: wine.wine_id,
            p_new_value: valData.current_market_value,
            p_currency: valData.currency || 'EUR',
            p_source: 'Semi-annual market index update'
          })
          results.push({
            wine_id: wine.wine_id,
            name: wine.wine_name,
            vintage: wine.vintage,
            old_value: wine.estimated_market_value,
            new_value: valData.current_market_value
          })
        }
      }
    }

    return new Response(JSON.stringify({ updated_count: results.length, updates: results }), {
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
