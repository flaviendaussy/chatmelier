import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { photoUrl, bottleId, wineId } = await req.json()
    if (!photoUrl) {
      return new Response(JSON.stringify({ error: 'photoUrl required' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    // Download image from storage
    const { data: imgData, error: dlError } = await supabase.storage.from('labels').download(photoUrl)
    if (dlError) throw dlError

    // Generate 768-dim embedding
    const mockEmbedding = Array.from({ length: 768 }, () => Math.random() - 0.5)

    // Store in bottle_photos table
    const { error: insertError } = await supabase.from('bottle_photos').insert({
        bottle_id: bottleId || null,
        wine_id: wineId || null,
        storage_path: photoUrl,
        photo_type: 'front',
        embedding: `[${mockEmbedding.join(',')}]`
    })

    if (insertError) throw insertError

    return new Response(JSON.stringify({ success: true }), {
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