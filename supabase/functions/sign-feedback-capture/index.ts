// =============================================================================
// sign-feedback-capture — ouvrir une capture de retour, sans bucket public
// =============================================================================
// Les captures d'écran jointes aux rapports vivent désormais dans un bucket privé
// (migration 036). Le dépouillement a besoin de les voir ; il ne doit pas pour autant
// rouvrir la lecture à qui connaît une URL.
//
// Cette fonction signe une URL de courte durée, après avoir vérifié `profiles.is_admin`
// CÔTÉ SERVEUR (migration 029). Le drapeau est lisible par le client mais ne peut être
// écrit que par le service_role : le privilège ne peut donc pas être revendiqué depuis
// l'app.
// =============================================================================
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  const authHeader = req.headers.get('Authorization') ?? ''
  if (!authHeader.startsWith('Bearer ')) {
    return json({ error: 'Unauthorized' }, 401)
  }

  const url = Deno.env.get('SUPABASE_URL') ?? ''
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  if (!url || !serviceKey) return json({ error: 'Server misconfigured' }, 500)

  // 1. Qui appelle ? Le JWT est vérifié par Supabase, pas par nous.
  const asCaller = createClient(url, Deno.env.get('SUPABASE_ANON_KEY') ?? '', {
    global: { headers: { Authorization: authHeader } },
  })
  const { data: { user }, error: authErr } = await asCaller.auth.getUser()
  if (authErr || !user) return json({ error: 'Unauthorized' }, 401)

  // 2. Est-il administrateur ? La réponse vient de la base, jamais de la requête.
  const admin = createClient(url, serviceKey)
  const { data: profile } = await admin
    .from('profiles')
    .select('is_admin')
    .eq('id', user.id)
    .maybeSingle()
  if (!profile?.is_admin) return json({ error: 'Forbidden' }, 403)

  // 3. Le chemin demandé.
  let path = ''
  let expiresIn = 300
  try {
    const body = await req.json()
    path = String(body?.path ?? '')
    if (typeof body?.expiresIn === 'number') expiresIn = body.expiresIn
  } catch {
    return json({ error: 'Invalid body' }, 400)
  }

  // Refuser tout ce qui sort du bucket : une remontée de chemin (`../`) signerait
  // n'importe quel objet du projet, y compris les photos d'étiquette d'autrui.
  if (!path || path.includes('..') || path.startsWith('/')) {
    return json({ error: 'Invalid path' }, 400)
  }
  // Cinq minutes suffisent pour ouvrir une image ; une URL signée pour la journée
  // recréerait exactement le lien permanent qu'on vient de supprimer.
  expiresIn = Math.min(Math.max(expiresIn, 30), 900)

  const { data, error } = await admin.storage
    .from('feedback')
    .createSignedUrl(path, expiresIn)
  if (error || !data) return json({ error: error?.message ?? 'Not found' }, 404)

  return json({ url: data.signedUrl, expiresIn })
})
