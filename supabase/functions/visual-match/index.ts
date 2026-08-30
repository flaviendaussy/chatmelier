import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { photoUrl, cellarId } = await req.json()
    if (!photoUrl || !cellarId) {
      return new Response(JSON.stringify({ error: 'photoUrl and cellarId required' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    // Mock embedding generation for input photo
    const mockEmbedding = Array.from({ length: 768 }, () => Math.random() - 0.5)

    const { data: matches, error } = await supabase.rpc('find_similar_photos', {
        p_embedding: `[${mockEmbedding.join(',')}]`,
        p_cellar_id: cellarId,
        p_threshold: 0.7,
        p_limit: 5
    })

    if (error) throw error

    return new Response(JSON.stringify({ matches }), {
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