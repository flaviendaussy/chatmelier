import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0'

// Les petites tâches IA de l'app, côté serveur (V2.3 · C2). Fichier autonome : il se déploie
// d'un seul fichier depuis l'éditeur du Dashboard.
//
// Jusqu'ici ces tâches appelaient Google depuis le téléphone, avec une clé embarquée dans
// l'app. Cette clé a été retirée le 14/09 (S0) : depuis, l'import Excel rendait une liste
// vide, et les notes dictées, le récit de la bouteille, la synthèse de table et la lecture
// d'un meuble en photo retombaient en silence sur des heuristiques.
//
// Ce n'est pas un relais Gemini générique : chaque tâche a ses consignes, fixées ici, et
// ses entrées sont bornées. L'app n'envoie que des données.

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
}

const GEMINI_BASE = Deno.env.get('GEMINI_BASE_URL') ?? 'https://generativelanguage.googleapis.com'
const REPLIS = ['gemini-3.8-flash', 'gemini-3.7-flash', 'gemini-3.6-flash', 'gemini-flash-latest', 'gemini-3.1-flash-lite']

// Réglage par défaut de chaque tâche ; app_config.modeles_ia.<tâche> le remplace. Les
// tâches d'extraction partent sur Flash-Lite, comme avant côté app.
const REGLAGES: Record<string, { modele: string; reflexion: string }> = {
  notes_degustation: { modele: 'gemini-3.1-flash-lite', reflexion: 'minimal' },
  recit: { modele: 'gemini-3.8-flash', reflexion: 'low' },
  synthese_table: { modele: 'gemini-3.8-flash', reflexion: 'low' },
  meuble: { modele: 'gemini-3.8-flash', reflexion: 'low' },
  import_cave: { modele: 'gemini-3.1-flash-lite', reflexion: 'minimal' },
  fiche_texte: { modele: 'gemini-3.1-flash-lite', reflexion: 'minimal' },
  enrichir_fiche: { modele: 'gemini-3.8-flash', reflexion: 'low' },
  vin_depuis_texte: { modele: 'gemini-3.1-flash-lite', reflexion: 'minimal' },
}

// Le quota de chaque tâche (consommer_quota_ia) : l'import d'une grande cave compte à part.
const QUOTAS: Record<string, string> = { import_cave: 'import_cave' }

type Langue = 'fr' | 'en' | 'es'
function langueDe(code: unknown): Langue {
  const c = String(code ?? 'fr').toLowerCase()
  if (c.startsWith('fr')) return 'fr'
  if (c.startsWith('es')) return 'es'
  return 'en'
}
const EN_LANGUE: Record<Langue, string> = { fr: 'en français', en: 'in English', es: 'en español' }

function texte(v: unknown, max: number): string {
  return typeof v === 'string' ? v.trim().slice(0, max) : ''
}
function liste(v: unknown, n: number, max: number): string[] {
  return Array.isArray(v) ? v.filter((x) => typeof x === 'string').slice(0, n).map((x: string) => x.trim().slice(0, max)) : []
}
function entier(v: unknown): number | null {
  return typeof v === 'number' && Number.isInteger(v) ? v : null
}

function niveauPour(modele: string, souhaite: string): string {
  if (souhaite === 'minimal' && /3\.[78]-flash|flash-latest/.test(modele) && !modele.includes('lite')) return 'low'
  return souhaite
}

function lireJson(raw: string): any {
  let t = raw
  if (t.includes('```json')) t = t.split('```json')[1].split('```')[0].trim()
  else if (t.includes('```')) t = t.split('```')[1].split('```')[0].trim()
  try {
    return JSON.parse(t)
  } catch {
    const r = t.replace(/,\s*([\}\]])/g, '$1')
    const debutObjet = r.indexOf('{')
    const debutTableau = r.indexOf('[')
    const tableau = debutTableau !== -1 && (debutObjet === -1 || debutTableau < debutObjet)
    const debut = tableau ? debutTableau : debutObjet
    const fin = tableau ? r.lastIndexOf(']') : r.lastIndexOf('}')
    if (debut !== -1 && fin > debut) return JSON.parse(r.substring(debut, fin + 1))
    throw new Error('Réponse non JSON')
  }
}

interface Consigne {
  parts: any[]
  enJson: boolean
  // Recherche Google : seulement pour la vérification d'une fiche contradictoire, que l'app
  // borne elle-même (GroundedVerificationBudget : jamais deux fois le même vin, 5 par jour).
  recherche?: boolean
}

// ─── Les consignes, tâche par tâche (reprises de l'app, V2.2) ─────────────────────
function consigne(tache: string, e: any, langue: Langue): Consigne | string {
  switch (tache) {
    case 'notes_degustation': {
      const parole = texte(e.texte, 4000)
      if (!parole) return 'texte vide'
      const noms = liste(e.degustateurs, 12, 40)
      const type = texte(e.type_vin, 40).toLowerCase()
      const rouge = type.includes('rouge') || type.includes('red') || type.includes('tinto')
      const aromes = liste(e.aromes, 80, 40)
      return {
        enJson: true,
        parts: [{ text: `Tu es le sommelier de Chatmelier.
L'utilisateur te transmet une retranscription vocale ou des notes libres de dégustation saisies à table :
"${parole}"

Le vin dégusté est : "${texte(e.nom_vin, 200)}" (Type : ${type}).
Les dégustateurs présents sont : ${noms.join(', ')}.

TÂCHE :
Analyse le texte et extrais pour chaque personne mentionnée (ou pour le dégustateur principal si une seule personne est évoquée) :
1. "profile_name" : nom du dégustateur (au plus proche de l'un de : ${noms.join(', ')}).
2. "note" : note sur 10 (1.0 à 10.0). Si elle n'est pas dite, déduis-la du sentiment ("adoré" → 8.5, "correct" → 6.5, "moyen" → 5.0).
3. "emoji_impression" : entier de 0 à 4 (0=😖, 1=😕, 2=😐, 3=😊, 4=😍).
4. "aromas" : identifiants d'arômes UNIQUEMENT parmi : ${JSON.stringify(aromes)}.
5. "acidity" : 0.0 (mou) à 1.0 (vif). Défaut 0.5.
6. ${rouge ? '"tannins" : 0.0 (soyeux) à 1.0 (très tannique). Défaut 0.5.' : '"mineralite" : 0.0 à 1.0 (minéralité et tension). Défaut 0.5.'}
7. "body" : 0.0 (léger) à 1.0 (puissant). Défaut 0.5.
8. "length" : 0.0 (court) à 1.0 (persistant). Défaut 0.5.
9. "raw_comment" : une phrase qui résume le commentaire de cette personne, ${EN_LANGUE[langue]}.

Fournis aussi un "summary" global d'une phrase, ${EN_LANGUE[langue]}.

Réponds STRICTEMENT par un objet JSON :
{"summary": "...", "tasters": [{"profile_name": "...", "note": 8.5, "emoji_impression": 3, "aromas": [], "acidity": 0.5, ${rouge ? '"tannins": 0.6' : '"mineralite": 0.7'}, "body": 0.6, "length": 0.7, "raw_comment": "..."}]}` }],
      }
    }
    case 'recit': {
      const nom = texte(e.nom, 200)
      if (!nom) return 'nom vide'
      return {
        enJson: true,
        parts: [{ text: `Tu es un sommelier érudit et conteur passionné.
Pour le vin suivant servi à table :
- Vin : ${nom}
- Domaine / Producteur : ${texte(e.producteur, 120) || 'Inconnu'}
- Millésime : ${entier(e.millesime) ?? 'Non millésimé'}
- Région / Appellation : ${texte(e.region, 80)} ${texte(e.appellation, 80)}
- Cépages : ${liste(e.cepages, 8, 40).join(', ') || 'Non spécifiés'}
- Type : ${texte(e.type, 30) || 'Rouge'}

Écris ${EN_LANGUE[langue]} de courtes anecdotes captivantes et élégantes, pour le maître de maison qui raconte la bouteille à ses invités :
1. "terroir_and_grape" : le terroir et la typicité des cépages (1 à 2 phrases).
2. "vintage_climate" : le millésime et son contexte climatique marquant (1 à 2 phrases). Si tu ne connais pas ce millésime, dis ce qui caractérise en général les millésimes de cette région, sans inventer de chiffres.
3. "sommelier_tip" : le conseil du sommelier pour l'apprécier à table.
4. "fun_fact" : une anecdote historique ou insolite sur le domaine, la région ou ce style de vin. N'invente pas de fait précis sur le domaine si tu n'en es pas sûr : parle alors de la région.

Réponds STRICTEMENT par un objet JSON :
{"terroir_and_grape": "...", "vintage_climate": "...", "sommelier_tip": "...", "fun_fact": "..."}` }],
      }
    }
    case 'synthese_table': {
      const avis = liste(e.avis, 12, 300)
      if (avis.length === 0) return 'aucun avis'
      return {
        enJson: false,
        parts: [{ text: `Tu es un sommelier qui anime une table d'amis.
Voici les avis enregistrés pour la dégustation de "${texte(e.nom_vin, 200)}" :
${avis.join('; ')}

Rédige ${EN_LANGUE[langue]} la synthèse de la table en 1 ou 2 phrases vivantes et élégantes :
- dis si le vin a fait l'unanimité ou a créé un débat ;
- mets en lumière les accords ou les contrastes de perception (notes, fraîcheur, arômes) ;
- donne la note moyenne de la table.
Reste concis et chaleureux. Pas de puces, pas de JSON : juste le texte.` }],
      }
    }
    case 'meuble': {
      const image = texte(e.imageBase64, 7_000_000)
      if (!image) return 'image vide'
      return {
        enJson: true,
        parts: [
          { inlineData: { mimeType: texte(e.mimeType, 30) || 'image/jpeg', data: image } },
          { text: `Tu es un architecte et sommelier expert en aménagement de cave à vin.
Analyse cette photo de meuble, casier, étagère ou croisillon de rangement de vin.

Détecte la géométrie exacte du meuble :
1. "shape_type" : "rectangle" (grille complète), "triangle" (casier pyramide), "staggered_4_2" (rangées décalées) ou "custom" (disposition irrégulière).
2. "columns" : nombre de colonnes (bouteilles en largeur), 15 au plus.
3. "rows" : nombre de rangées en hauteur, 15 au plus.
4. "name" : un nom concis ${EN_LANGUE[langue]} (ex. « Casier chêne 6×6 »).
5. "slots_matrix" : matrice booléenne [rows][columns], true là où une bouteille peut être posée.

Retourne STRICTEMENT un objet JSON :
{"name": "...", "shape_type": "rectangle", "columns": 6, "rows": 6, "slots_matrix": [[true, true]]}` },
        ],
      }
    }
    case 'import_cave': {
      const lignes = liste(e.lignes, 60, 400)
      if (lignes.length === 0) return 'aucune ligne'
      return {
        enJson: true,
        parts: [{ text: `Tu es un sommelier expert et ingénieur de données vinicoles.
Voici des lignes extraites d'un tableur de cave à vin :

${lignes.join('\n')}

Identifie chaque vin et extrais :
- "name" : nom du vin ou de la cuvée (requis)
- "producer" : domaine, maison ou château
- "vintage" : millésime (entier) ou null
- "type" : "red", "white", "rosé", "sparkling", "dessert", "fortified" ou "spirit"
- "region" : région viticole ; "country" : pays ; "appellation" : AOC, AOP, DOCG ou AVA si identifiable
- "quantity" : nombre de bouteilles sur la ligne (entier ≥ 1, défaut 1)
- "bottle_size" : "37.5cl", "50cl", "75cl", "1.5L", "3L" ou "6L" (défaut "75cl")
- "purchase_price" : prix unitaire d'achat, ou null
- "currency" : "EUR" par défaut, sinon celle de la ligne
- "rack" et "shelf" : casier et étagère s'ils sont indiqués, sinon null

Règles : ignore les lignes d'en-tête, les totaux et les métadonnées ; déduis la couleur de l'appellation (Meursault → white, Pomerol → red, Champagne → sparkling) ; un millésime dans le nom va dans "vintage".

Retourne STRICTEMENT un tableau JSON d'objets vin.` }],
      }
    }
    case 'fiche_texte': {
      const nom = texte(e.nom, 200)
      if (!nom) return 'nom vide'
      const millesime = entier(e.millesime)
      return {
        enJson: true,
        parts: [{ text: `Tu es un sommelier expert. Identifie ce vin : "${nom}"${millesime ? ` (millésime ${millesime})` : ''}.
Renvoie STRICTEMENT un objet JSON :
{"name": "Nom complet du vin", "producer": "Domaine", "vintage": ${millesime ?? 'null'}, "wine_type": "red|white|rosé|sparkling|dessert|fortified|orange", "country": "Pays", "region": "Région", "appellation": "Appellation", "grapes": ["Cépage"], "ideal_drinking_start": 2024, "ideal_drinking_end": 2032}
Si tu n'es pas sûr d'une valeur, donne la valeur typique de l'appellation plutôt qu'un chiffre précis inventé.` }],
      }
    }
    case 'enrichir_fiche': {
      const nom = texte(e.nom, 200)
      if (!nom) return 'nom vide'
      const recherche = e.recherche === true
      return {
        enJson: !recherche,
        recherche,
        parts: [{ text: `You are Chatmelier, a sommelier and oenology reference.
Give reliable sommelier data for:
- Wine name: ${nom}
- Producer / domaine: ${texte(e.producteur, 120) || 'Unknown'}
- Vintage: ${entier(e.millesime) ?? 'Non-vintage'}
- Region: ${texte(e.region, 80) || 'Unknown'}
- Appellation: ${texte(e.appellation, 80) || 'Unknown'}
- Wine type: ${texte(e.type, 30) || 'red'}
${recherche ? 'Search trusted wine references (producer site, Guide Hachette, RVF, Wine Spectator, Decanter) and use what you find.\n' : ''}
Return strictly one JSON object with:
"grapes": [{"name": "...", "pct": number | null}] — the real blend of this appellation or cuvée;
"appellation": official appellation (AOC, DOC, AOP); "region": main wine region; "sub_region": sub-region, commune or cru, or null;
"classification": official classification (Grand Cru Classé, Premier Cru…) or null;
"tasting_notes": aromas, texture, acidity and structure, ${EN_LANGUE[langue]};
"food_pairings": 3 to 5 pairings, ${EN_LANGUE[langue]};
"ideal_drinking_start", "ideal_drinking_end", "peak_drinking_start", "peak_drinking_end": years, or null;
"alcohol_pct": number or null;
"ai_summary": 1 or 2 sentences ${EN_LANGUE[langue]}, naming the grape varieties.
If you are unsure of a value, give the typical value of the appellation rather than a precise-looking guess. Do not give any price.` }],
      }
    }
    case 'vin_depuis_texte': {
      const description = texte(e.texte, 600)
      if (!description) return 'texte vide'
      return {
        enJson: true,
        parts: [{ text: `You are Chatmelier, a master sommelier.
Analyse this wine description, wine-list entry or chalkboard line:
"${description}"

Return strictly one JSON object with:
"name": wine or spirit name / cuvée; "producer": estate, winery or distillery, or null;
"vintage": integer or null; "cuvee_parcel": parcel or cuvée, or null;
"wine_type": one of red, white, rosé, sparkling, dessert, fortified, orange, liqueur, spirit, grappa, eau-de-vie, whisky, gin, rum, vodka, tequila, cognac, vermouth.
Spirits, grappas, digestifs and herbal liqueurs (Grappa, Marc, Bénédictine, Chartreuse, Cointreau, Amaretto, Gin, Rum, Whisky, Vodka, Pastis…) take their spirit type or "liqueur" / "spirit", never red, white, fortified or dessert. "fortified" is only for true fortified wines (Port, Sherry, Banyuls, Madeira, Marsala);
"country" (France by default for a French appellation), "region", "sub_region", "appellation", "classification": or null;
"alcohol_pct": typical ABV, or null;
"grapes": [{"name": "...", "pct": number | null}];
"tasting_notes": aromas, palate and structure, ${EN_LANGUE[langue]};
"food_pairings": 3 to 5 pairings, ${EN_LANGUE[langue]};
"ideal_drinking_start", "ideal_drinking_end", "peak_drinking_start", "peak_drinking_end": years, or null;
"ai_summary": 1 or 2 sentences ${EN_LANGUE[langue]}, naming the grape varieties;
"detected_quantity": 1; "packaging_type": "single".
Do not give any price.` }],
      }
    }
  }
  return 'tâche inconnue'
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } } },
    )
    // Ces tâches servent des comptes ou des sessions de l'app : pas d'accès sans session.
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return json({ error: 'session_requise' }, 401)

    const corps = await req.json()
    const tache = texte(corps.tache, 40)
    if (!REGLAGES[tache]) return json({ error: 'tâche inconnue' }, 400)
    const c = consigne(tache, corps, langueDe(corps.langue))
    if (typeof c === 'string') return json({ error: c }, 400)

    try {
      const { data, error } = await supabase.rpc('consommer_quota_ia', { p_fonction: QUOTAS[tache] ?? 'taches' })
      if (!error && data && data.autorise === false && data.raison === 'limite') {
        return json({ error: 'limite_du_jour', limite: data.limite, anonyme: data.anonyme === true }, 429)
      }
    } catch (_) { /* migration 052 absente : pas de quota */ }

    const apiKey = Deno.env.get('GEMINI_API_KEY')
    if (!apiKey) return json({ error: 'GEMINI_API_KEY non configurée' }, 500)

    let reglage = REGLAGES[tache]
    try {
      const { data } = await supabase.from('app_config').select('valeur').eq('cle', 'modeles_ia').maybeSingle()
      const r = data?.valeur?.[tache]
      if (r && typeof r.modele === 'string') reglage = { modele: r.modele, reflexion: typeof r.reflexion === 'string' ? r.reflexion : reglage.reflexion }
    } catch (_) { /* réglage par défaut */ }

    const erreurs: string[] = []
    const chaine = [reglage.modele, ...REPLIS].filter((m, i, t) => m && t.indexOf(m) === i)
    for (const modele of chaine) {
      const niveau = niveauPour(modele, reglage.reflexion)
      for (const avecReglage of [true, false]) {
        try {
          const generationConfig: Record<string, unknown> = {}
          if (c.enJson) generationConfig.responseMimeType = 'application/json'
          if (avecReglage) generationConfig.thinkingConfig = { thinkingLevel: niveau }
          const envoi: Record<string, unknown> = { contents: [{ role: 'user', parts: c.parts }], generationConfig }
          if (c.recherche) envoi.tools = [{ google_search: {} }]
          const res = await fetch(`${GEMINI_BASE}/v1beta/models/${modele}:generateContent?key=${apiKey}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(envoi),
            signal: AbortSignal.timeout(tache === 'import_cave' ? 60_000 : 30_000),
          })
          if (!res.ok) {
            erreurs.push(`${modele} : HTTP ${res.status}`)
            if (avecReglage && res.status === 400) continue
            break
          }
          const data = await res.json()
          const brut = (data.candidates?.[0]?.content?.parts ?? [])
            .filter((p: any) => !p.thought).map((p: any) => p.text ?? '').join('').trim()
          if (!brut) {
            erreurs.push(`${modele} : réponse vide`)
            break
          }
          const usage = data.usageMetadata ?? null
          const requetes = data.candidates?.[0]?.groundingMetadata?.webSearchQueries
          const n = Array.isArray(requetes) ? requetes.length : 0
          return json({
            tache,
            resultat: c.enJson || c.recherche ? (tache === 'synthese_table' ? brut : lireJson(brut)) : brut,
            modele,
            couts: [{ fonction: tache, modele, usageMetadata: usage, recherche: n > 0, requetes: n, reflexion: avecReglage ? niveau : null }],
          })
        } catch (err) {
          erreurs.push(`${modele} : ${(err as Error).message}`)
          break
        }
      }
    }
    console.error(`taches-ia (${tache}) : aucun modèle n'a répondu`, erreurs)
    return json({ error: 'Aucun modèle n\'a répondu', details: erreurs }, 502)
  } catch (error) {
    return json({ error: (error as Error).message }, 500)
  }
})
