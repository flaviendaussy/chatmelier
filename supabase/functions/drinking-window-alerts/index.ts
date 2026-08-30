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
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Example logic for alerts: query bottles that are drink soon
    // and group by owner_id to send notifications
    const { data: bottles, error } = await supabase
        .from('bottles')
        .select(`
            id, owner_id, cellar_id,
            wines ( name, ideal_drinking_end, peak_drinking_end )
        `)
        .eq('status', 'in_cellar')
        
    if (error) throw error

    const currentYear = new Date().getFullYear()
    const alerts = bottles.filter(b => {
        const endYear = b.wines?.ideal_drinking_end
        return endYear && currentYear >= endYear - 1
    })

    // In a real app, integrate with a push notification service here

    return new Response(JSON.stringify({ alerted: alerts.length, data: alerts }), {
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