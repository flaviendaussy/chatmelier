// envoyer-push — une notification de la boîte, poussée sur les téléphones (lot N, version 86).
//
// Appelée par la base (migration 075, pg_net) à chaque notification écrite par le SERVEUR,
// avec { notification_id }. Déployer avec « Enforce JWT verification » DÉCOCHÉ : la base
// appelle sans jeton. Elle ne fait rien d'autre qu'envoyer, une seule fois
// (`reserver_le_push`), une notification déjà écrite en base par une fonction du serveur :
// un appel extérieur ne peut ni choisir le texte, ni le destinataire, ni renvoyer.
//
// Secrets : FCM_SERVICE_ACCOUNT (le JSON du compte de service Firebase, posé par Flavien),
// SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY (fournis par Supabase).
//
// Pour chaque appareil du destinataire : le texte dans SA langue, rien pendant SES heures
// calmes ni pour ce qu'il a coupé, le nombre de notifications non lues en pastille (iPhone).
// Un jeton que Firebase ne connaît plus est effacé.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0'

const FCM_BASE = Deno.env.get('FCM_BASE_URL') ?? 'https://fcm.googleapis.com'

type Notification = {
  id: string
  user_id: string
  actor_id: string | null
  type: string
  title: string
  body: string
  data: Record<string, unknown> | null
}

type Appareil = {
  jeton: string
  plateforme: 'android' | 'ios'
  langue: string
  decalage_min: number
  preferences: Record<string, unknown> | null
}

type Langue = 'fr' | 'en' | 'es' | 'it'

// ─── Les textes ────────────────────────────────────────────────────────────────────────
// {nom} : qui a agi ; {vin} ; {cave} ; {n}. Le titre et le texte rangés en base (en français)
// ne servent qu'aux types inconnus d'ici.
const TEXTES: Record<string, Record<Langue, [string, string]>> = {
  friend_request: {
    fr: ['Nouvelle demande d\'ami', '{nom} souhaite vous ajouter en ami.'],
    en: ['New friend request', '{nom} wants to add you as a friend.'],
    es: ['Nueva solicitud de amistad', '{nom} quiere añadirte como amigo.'],
    it: ['Nuova richiesta di amicizia', '{nom} vuole aggiungerti come amico.'],
  },
  friend_accepted: {
    fr: ['Demande d\'ami acceptée', '{nom} a accepté votre demande.'],
    en: ['Friend request accepted', '{nom} accepted your request.'],
    es: ['Solicitud de amistad aceptada', '{nom} ha aceptado tu solicitud.'],
    it: ['Richiesta di amicizia accettata', '{nom} ha accettato la tua richiesta.'],
  },
  cellar_request: {
    fr: ['Une demande d\'accès à votre cave', '{nom} aimerait voir « {cave} ».'],
    en: ['A request to see your cellar', '{nom} would like to see "{cave}".'],
    es: ['Una solicitud para ver tu bodega', '{nom} quiere ver «{cave}».'],
    it: ['Una richiesta per la tua cantina', '{nom} vorrebbe vedere «{cave}».'],
  },
  degustation_a_accepter: {
    fr: ['Une dégustation pour votre journal', '{nom} a noté « {vin} » pour vous.'],
    en: ['A tasting for your journal', '{nom} noted "{vin}" for you.'],
    es: ['Una cata para tu diario', '{nom} ha anotado «{vin}» para ti.'],
    it: ['Una degustazione per il tuo diario', '{nom} ha annotato «{vin}» per te.'],
  },
  invitation_a_noter: {
    fr: ['Un vin à noter', '{nom} aimerait votre avis sur « {vin} ».'],
    en: ['A wine to rate', '{nom} would like your take on "{vin}".'],
    es: ['Un vino para puntuar', '{nom} quiere tu opinión sobre «{vin}».'],
    it: ['Un vino da valutare', '{nom} vorrebbe il tuo parere su «{vin}».'],
  },
  activite_cave: {
    fr: ['Votre cave partagée', '{nom} a ajouté {n} {bouteilles} à « {cave} ».'],
    en: ['Your shared cellar', '{nom} added {n} {bouteilles} to "{cave}".'],
    es: ['Tu bodega compartida', '{nom} ha añadido {n} {bouteilles} a «{cave}».'],
    it: ['La tua cantina condivisa', '{nom} ha aggiunto {n} {bouteilles} a «{cave}».'],
  },
}

const BOUTEILLES: Record<Langue, [string, string]> = {
  fr: ['bouteille', 'bouteilles'],
  en: ['bottle', 'bottles'],
  es: ['botella', 'botellas'],
  it: ['bottiglia', 'bottiglie'],
}

// Quel réglage de l'appareil coupe quel type.
const FAMILLE: Record<string, string> = {
  friend_request: 'amis',
  friend_accepted: 'amis',
  cellar_request: 'amis',
  degustation_a_accepter: 'degustations',
  invitation_a_noter: 'degustations',
  activite_cave: 'activite_cave',
}

export function langueDe(code: string | null | undefined): Langue {
  const l = (code ?? '').toLowerCase().slice(0, 2)
  return l === 'en' || l === 'es' || l === 'it' ? l : l === 'fr' ? 'fr' : 'en'
}

function texte(v: unknown): string {
  return typeof v === 'string' ? v.trim() : ''
}

export function rediger(n: Notification, nomActeur: string, langue: Langue): { titre: string; corps: string } {
  const modele = TEXTES[n.type]?.[langue]
  if (!modele) return { titre: n.title, corps: n.body }
  const d = n.data ?? {}
  const vinBrut = d['vin']
  const vin = typeof vinBrut === 'object' && vinBrut !== null ? texte((vinBrut as Record<string, unknown>)['nom']) : texte(vinBrut)
  const nombre = Number(d['nombre'] ?? 1) || 1
  const valeurs: Record<string, string> = {
    nom: nomActeur || texte(d['actor_name']) || texte(d['requester_name']) || texte(d['friend_name']) || 'Chatmelier',
    vin: vin || '…',
    cave: texte(d['cellar_name']) || (langue === 'fr' ? 'votre cave' : langue === 'es' ? 'tu bodega' : langue === 'it' ? 'la tua cantina' : 'your cellar'),
    n: String(nombre),
    bouteilles: BOUTEILLES[langue][nombre > 1 ? 1 : 0],
  }
  const remplir = (s: string) => s.replace(/\{(\w+)\}/g, (_, k) => valeurs[k] ?? '')
  return { titre: remplir(modele[0]), corps: remplir(modele[1]) }
}

// Ce que l'app ouvre au toucher : l'écran indiqué, sinon la boîte de notifications.
export function destination(n: Notification): string {
  const route = texte(n.data?.['route'])
  if (route.startsWith('/')) return route
  return n.type.startsWith('friend_') ? '/friends' : 'boite'
}

// Heures calmes : par défaut de 22 h à 8 h, à l'heure de l'appareil. Coupables dans l'app.
export function enHeuresCalmes(a: Appareil, maintenant = new Date()): boolean {
  const p = a.preferences ?? {}
  if (p['heures_calmes'] === false) return false
  const debut = Number(p['calme_debut'] ?? 22)
  const fin = Number(p['calme_fin'] ?? 8)
  const minutes = (maintenant.getUTCHours() * 60 + maintenant.getUTCMinutes() + (a.decalage_min ?? 0) + 1440 * 2) % 1440
  const heure = minutes / 60
  return debut > fin ? heure >= debut || heure < fin : heure >= debut && heure < fin
}

export function voulu(n: Notification, a: Appareil): boolean {
  const p = a.preferences ?? {}
  if (p['push'] === false) return false
  const famille = FAMILLE[n.type]
  return !(famille && p[famille] === false)
}

// ─── Firebase : jeton d'accès (compte de service, JWT RS256) ──────────────────────────
type CompteDeService = { project_id: string; client_email: string; private_key: string; token_uri?: string }
let jetonEnCache: { valeur: string; expire: number } | null = null

function b64url(octets: Uint8Array | string): string {
  const b = typeof octets === 'string' ? new TextEncoder().encode(octets) : octets
  let s = ''
  for (const o of b) s += String.fromCharCode(o)
  return btoa(s).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
}

async function jetonGoogle(sa: CompteDeService): Promise<string> {
  if (jetonEnCache && jetonEnCache.expire > Date.now() + 60_000) return jetonEnCache.valeur
  const tokenUri = Deno.env.get('GOOGLE_TOKEN_URL') ?? sa.token_uri ?? 'https://oauth2.googleapis.com/token'
  const maintenant = Math.floor(Date.now() / 1000)
  const entete = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))
  const corps = b64url(JSON.stringify({
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: tokenUri,
    iat: maintenant,
    exp: maintenant + 3600,
  }))
  const pem = sa.private_key.replace(/-----[^-]+-----/g, '').replace(/\s+/g, '')
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0))
  const cle = await crypto.subtle.importKey('pkcs8', der, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign'])
  const signature = new Uint8Array(await crypto.subtle.sign('RSASSA-PKCS1-v1_5', cle, new TextEncoder().encode(`${entete}.${corps}`)))
  const r = await fetch(tokenUri, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: `${entete}.${corps}.${b64url(signature)}`,
    }),
  })
  if (!r.ok) throw new Error(`jeton Google refusé (${r.status}) : ${(await r.text()).slice(0, 200)}`)
  const j = await r.json()
  jetonEnCache = { valeur: j.access_token, expire: Date.now() + (Number(j.expires_in ?? 3600) * 1000) }
  return jetonEnCache.valeur
}

// Le JSON du compte de service, tel que le Dashboard l'a gardé (21/10 : « illisible » au
// premier déploiement). On accepte les maladresses courantes du copier-coller : guillemets
// autour, JSON encodé en base64, retours à la ligne réels dans la clé. Sinon, la cause part
// dans les journaux de la fonction (forme et longueur seulement, jamais le contenu).
export function lireLeCompteDeService(brut: string): CompteDeService | null {
  const t = brut.trim()
  const bases = [t]
  if (t.length > 1 && (t[0] === "'" || t[0] === '"') && t[t.length - 1] === t[0]) bases.push(t.slice(1, -1).trim())
  const essais: (() => string)[] = []
  for (const b of bases) {
    essais.push(() => b, () => b.replace(/\r?\n/g, ' '), () => atob(b.replace(/\s+/g, '')))
  }
  for (const essai of essais) {
    try {
      let v = JSON.parse(essai())
      if (typeof v === 'string') v = JSON.parse(v) // JSON rangé comme une chaîne
      if (v && typeof v.client_email === 'string' && typeof v.private_key === 'string' && typeof v.project_id === 'string') {
        return v as CompteDeService
      }
    } catch (_) { /* essai suivant */ }
  }
  console.error('envoyer-push : FCM_SERVICE_ACCOUNT illisible —',
    `longueur ${brut.length}, commence par « ${brut.trim().slice(0, 1)} », finit par « ${brut.trim().slice(-1)} »,`,
    `${brut.includes('\n') ? 'sur plusieurs lignes' : 'sur une ligne'}.`,
    'Attendu : tout le contenu du fichier JSON du compte de service, de « { » à « } ».')
  return null
}

function json(corps: unknown, statut = 200): Response {
  return new Response(JSON.stringify(corps), { status: statut, headers: { 'Content-Type': 'application/json' } })
}

serve(async (req) => {
  if (req.method !== 'POST') return json({ error: 'POST seulement' }, 405)
  const corps = await req.json().catch(() => ({}))
  const id = typeof corps?.notification_id === 'string' && /^[0-9a-f-]{36}$/i.test(corps.notification_id)
    ? corps.notification_id
    : null
  if (!id) return json({ error: 'notification_id manquant' }, 400)

  const brut = Deno.env.get('FCM_SERVICE_ACCOUNT')
  if (!brut) return json({ error: 'FCM_SERVICE_ACCOUNT non configuré' }, 500)
  const sa = lireLeCompteDeService(brut)
  if (!sa) return json({ error: 'FCM_SERVICE_ACCOUNT illisible' }, 500)

  const serveur = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '', {
    auth: { persistSession: false, autoRefreshToken: false },
  })

  // Réserver : une notification ne part qu'une fois, et seulement si le serveur l'a écrite.
  const { data: reservees, error: erreurReservation } = await serveur.rpc('reserver_le_push', { p_notification: id })
  if (erreurReservation) return json({ error: `réservation : ${erreurReservation.message}` }, 500)
  const n = (reservees as Notification[] | null)?.[0]
  if (!n) return json({ envoye: false, raison: 'deja_envoyee_ou_inconnue' })

  const { data: appareils } = await serveur.from('appareils_push')
    .select('jeton, plateforme, langue, decalage_min, preferences').eq('user_id', n.user_id)
  if (!appareils || appareils.length === 0) return json({ envoye: false, raison: 'aucun_appareil' })

  let nomActeur = ''
  if (n.actor_id) {
    const { data: p } = await serveur.from('profiles').select('display_name').eq('id', n.actor_id).maybeSingle()
    nomActeur = texte(p?.display_name)
  }
  const { count: nonLues } = await serveur.from('user_notifications')
    .select('id', { count: 'exact', head: true }).eq('user_id', n.user_id).eq('is_read', false)

  let jeton: string
  try {
    jeton = await jetonGoogle(sa)
  } catch (e) {
    return json({ error: String(e) }, 502)
  }

  const bilan = { envoyes: 0, calmes: 0, coupes: 0, oublies: 0, erreurs: [] as string[] }
  for (const a of appareils as Appareil[]) {
    if (!voulu(n, a)) { bilan.coupes++; continue }
    if (enHeuresCalmes(a)) { bilan.calmes++; continue }
    const { titre, corps: texteDuPush } = rediger(n, nomActeur, langueDe(a.langue))
    const message = {
      message: {
        token: a.jeton,
        notification: { title: titre, body: texteDuPush },
        data: {
          notification_id: n.id,
          type: n.type,
          ouvrir: destination(n),
          // La cave concernée : l'app l'ouvre elle, pas celle qui était à l'écran.
          ...(texte(n.data?.['cellar_id']) ? { cellar_id: texte(n.data?.['cellar_id']) } : {}),
        },
        // Les canaux que l'app crée déjà : l'activité d'une cave partagée a le sien.
        android: {
          priority: 'HIGH',
          notification: {
            channel_id: n.type === 'activite_cave' ? 'chatmelier_shared_cellar' : 'chatmelier_social',
            tag: `${n.type}:${n.id}`,
          },
        },
        apns: { payload: { aps: { sound: 'default', badge: nonLues ?? 0, 'thread-id': n.type } } },
      },
    }
    const r = await fetch(`${FCM_BASE}/v1/projects/${sa.project_id}/messages:send`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${jeton}` },
      body: JSON.stringify(message),
    })
    if (r.ok) { bilan.envoyes++; continue }
    const erreur = await r.text()
    // Jeton inconnu de Firebase (app désinstallée, jeton renouvelé) : on l'oublie.
    if (r.status === 404 || /UNREGISTERED|registration-token-not-registered/i.test(erreur)) {
      await serveur.from('appareils_push').delete().eq('jeton', a.jeton)
      bilan.oublies++
    } else {
      bilan.erreurs.push(`${r.status} ${erreur.slice(0, 160)}`)
    }
  }
  if (bilan.erreurs.length > 0) console.error('envoyer-push', n.id, bilan.erreurs)
  return json({ envoye: bilan.envoyes > 0, ...bilan })
})
