import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0'
import { checkRateLimit, getRateLimitHeaders } from '../_shared/rate_limit.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { message, cellarId } = await req.json()
    
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    // Get user
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 401,
      })
    }

    const { allowed, retryAfterMs } = checkRateLimit(`chat_${user.id}`, 10, 60_000)
    if (!allowed) {
      return new Response(JSON.stringify({ error: 'Too many requests' }), {
        status: 429,
        headers: { ...corsHeaders, 'Content-Type': 'application/json', ...getRateLimitHeaders(retryAfterMs) },
      })
    }

    // Get full bottle inventory for this cellar
    const { data: bottles } = await supabase
      .from('bottles')
      .select('id, quantity, purchase_price, currency, status, rack, shelf, wines(*)')
      .eq('cellar_id', cellarId)
      .eq('status', 'in_cellar')

    // Get stats & drink soon
    const { data: stats } = await supabase.rpc('get_cellar_stats', { p_cellar_id: cellarId })
    const { data: drinkSoon } = await supabase.rpc('get_drink_soon_bottles', { p_cellar_id: cellarId })
    
    // Get chat history
    const { data: history } = await supabase
        .from('chat_messages')
        .select('role, content')
        .eq('cellar_id', cellarId)
        .order('created_at', { ascending: false })
        .limit(10)
        
    const contents = (history || []).reverse().map(m => ({
      role: m.role === 'assistant' ? 'model' : 'user',
      parts: [{ text: m.content }]
    }))
    contents.push({ role: 'user', parts: [{ text: message }] })

    // Save user message
    await supabase.from('chat_messages').insert({
        cellar_id: cellarId,
        user_id: user.id,
        role: 'user',
        content: message
    })

    const apiKey = Deno.env.get('GEMINI_API_KEY')
    if (!apiKey) throw new Error("GEMINI_API_KEY is not configured")

    const systemInstruction = `You are Chatmelier, the world's most knowledgeable wine companion and cellar expert.
Always introduce yourself simply as "Chatmelier" (never say "Chatmelier Sommelier", "your sommelier", or "sommelier IA").
You have direct, real-time access to the user's private wine cellar inventory:

CELLAR INVENTORY:
${JSON.stringify(bottles || [], null, 2)}

CELLAR OVERVIEW:
- Stats: ${JSON.stringify(stats || {})}
- Drink Soon Window: ${JSON.stringify(drinkSoon || [])}

EXPERT & CRITICAL NEUTRALITY INSTRUCTIONS:
1. Always introduce yourself simply as Chatmelier.
2. Ground your advice directly in the actual bottles the user possesses whenever they ask what to drink, food pairings, or cellar recommendations.
3. Recommend specific bottles by exact Estate, Cuvée, Vintage, and physical Rack/Shelf location when available.
4. Provide precise serving temperatures, decanting times, and optimal drinking status.
5. CRITICAL NEUTRALITY: Be completely objective, candid, and neutral. NEVER use hyperbolic or flattering language ('ce nectar sublime', 'ce vin exceptionnel') for ordinary, mass-market, or poorly-rated bottles. If a wine is modest or past its peak, state it honestly and recommend culinary repurposing (sauces, stews, marinades).
6. Respond warmly, concisely, and eloquently in the language the user speaks (French by default if asked in French).`

    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=${apiKey}`
    const geminiRes = await fetch(geminiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: systemInstruction }] },
        contents: contents
      })
    })

    if (!geminiRes.ok) {
      const errText = await geminiRes.text()
      throw new Error(`Gemini API error (${geminiRes.status}): ${errText}`)
    }

    const geminiData = await geminiRes.json()
    const reply = geminiData.candidates?.[0]?.content?.parts?.[0]?.text || "Je suis à votre service pour vous guider dans votre cave."

    // Save AI message
    await supabase.from('chat_messages').insert({
        cellar_id: cellarId,
        user_id: user.id,
        role: 'assistant',
        content: reply
    })

    return new Response(JSON.stringify({ reply }), {
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