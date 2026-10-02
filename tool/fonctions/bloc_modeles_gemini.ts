// >>> Modèles Gemini : bloc commun aux fonctions (source : tool/fonctions/bloc_modeles_gemini.ts) >>>
// Recopié dans chaque fonction par `python3 tool/fonctions/synchroniser.py` : le déploiement
// par le Dashboard demande un fichier unique. Ne pas le modifier ici, mais dans la source.
//
// Aucun numéro de version de Gemini n'est écrit dans ce code (V2.3 · K8). Le réglage d'une
// tâche vient de app_config.modeles_ia : soit un nom exact (« gemini-3.1-flash-lite »),
// choisi par le banc d'essai, soit une famille (« flash », « flash-lite », « pro ») : le plus
// récent modèle stable de cette famille que Google publie. Si le modèle réglé échoue (retiré,
// saturé), le plus récent de sa famille prend le relais, puis celui de l'autre famille, trois
// modèles au plus. Un niveau de réflexion refusé par un modèle monte d'un cran. Gemini 3.9,
// 4.0… arrivent sans toucher au code : le banc les essaie d'office, et une ligne de
// app_config les adopte.

type Reglage = { modele: string; reflexion: string | null }
type AppelReussi = { data: any; modele: string; reflexion: string | null }

const FAMILLES_GEMINI = ['flash-lite', 'flash', 'pro']
const NIVEAUX_DE_REFLEXION = ['minimal', 'low', 'medium', 'high']
const MODELES_ESSAYES_AU_PLUS = 3
let catalogueDesModeles: { quand: number; modeles: string[] } | null = null
const niveauxRetenus = new Map<string, string | null>()

function familleDe(nom: string): string {
  return FAMILLES_GEMINI.find((f) => nom === f || nom.includes(`-${f}`)) ?? 'flash'
}

function versionDe(nom: string): number[] {
  const m = /^gemini-(\d+(?:\.\d+)*)-/.exec(nom)
  return m ? m[1].split('.').map(Number) : []
}

function plusRecentDabord(a: string, b: string): number {
  const va = versionDe(a)
  const vb = versionDe(b)
  for (let i = 0; i < Math.max(va.length, vb.length); i++) {
    const d = (vb[i] ?? 0) - (va[i] ?? 0)
    if (d !== 0) return d
  }
  return 0
}

// Stable : « gemini-<version>-<famille> », sans préversion, ni date, ni variante (tts, live…).
function estUnModeleStable(nom: string): boolean {
  return /^gemini-\d+(?:\.\d+)*-(flash-lite|flash|pro)$/.test(nom)
}

// Une famille (« flash ») se résout par la liste ; un nom (« gemini-… ») se prend tel quel.
function estUneFamille(reglage: string): boolean {
  return FAMILLES_GEMINI.includes(reglage)
}

async function modelesStables(apiKey: string): Promise<string[]> {
  if (catalogueDesModeles && Date.now() - catalogueDesModeles.quand < 6 * 3600_000) return catalogueDesModeles.modeles
  try {
    const res = await fetch(`${GEMINI_BASE}/v1beta/models?pageSize=1000`, {
      headers: { 'x-goog-api-key': apiKey },
      signal: AbortSignal.timeout(5_000),
    })
    if (!res.ok) throw new Error(`liste des modèles : ${res.status}`)
    const data = await res.json()
    const modeles = (Array.isArray(data.models) ? data.models : [])
      .filter((m: any) => Array.isArray(m.supportedGenerationMethods) && m.supportedGenerationMethods.includes('generateContent'))
      .map((m: any) => String(m.name ?? '').replace(/^models\//, ''))
      .filter(estUnModeleStable)
      .sort(plusRecentDabord)
    catalogueDesModeles = { quand: Date.now(), modeles }
    return modeles
  } catch (e) {
    console.warn('Liste des modèles indisponible :', e instanceof Error ? e.message : e)
    return []
  }
}

// Les relais, du plus proche au plus lointain : le plus récent de la famille, puis celui de
// l'autre famille ; sans liste, l'alias « -latest » que Google tient à jour.
async function modelesDeRelais(apiKey: string, reglage: string, dejaEssayes: Set<string>): Promise<string[]> {
  const famille = familleDe(reglage)
  const autre = famille === 'flash-lite' ? 'flash' : 'flash-lite'
  const stables = await modelesStables(apiKey)
  const premier = (f: string) => stables.find((m) => familleDe(m) === f && !dejaEssayes.has(m))
  const relais = [premier(famille), premier(autre)].filter((m): m is string => !!m)
  if (relais.length > 0) return relais
  return [`gemini-${famille}-latest`].filter((m) => !dejaEssayes.has(m))
}

// Le cran de réflexion au-dessus ; après « high », sans réglage ; sans réglage, plus rien.
function niveauAuDessus(niveau: string | null): string | null | undefined {
  if (niveau === null) return undefined
  const i = NIVEAUX_DE_REFLEXION.indexOf(niveau)
  return i >= 0 && i < NIVEAUX_DE_REFLEXION.length - 1 ? NIVEAUX_DE_REFLEXION[i + 1] : null
}

// Appelle Gemini pour une tâche : le modèle réglé, puis ses relais. `corpsPour(niveau)`
// construit le corps de la requête (niveau nul : sans thinkingConfig). `utilisable(data)`,
// s'il est donné, écarte une réponse vide ou illisible : le modèle suivant prend la main.
// Le modèle rendu est celui que Google a réellement servi (modelVersion), pour le tarif.
async function appelerGemini(
  apiKey: string,
  reglage: Reglage,
  corpsPour: (niveau: string | null) => Record<string, unknown>,
  delaiMs: number,
  utilisable?: (data: any) => boolean,
): Promise<AppelReussi> {
  const essayes = new Set<string>()
  let derniereErreur: unknown = null
  const famille = estUneFamille(reglage.modele)
  let candidats = famille ? await modelesDeRelais(apiKey, reglage.modele, essayes) : [reglage.modele]
  let relaisAjoutes = famille
  for (let i = 0; i < candidats.length && essayes.size < MODELES_ESSAYES_AU_PLUS; i++) {
    const modele = candidats[i]
    essayes.add(modele)
    let niveau: string | null | undefined = niveauxRetenus.has(modele) ? niveauxRetenus.get(modele)! : reglage.reflexion
    while (niveau !== undefined) {
      try {
        const res = await fetch(`${GEMINI_BASE}/v1beta/models/${modele}:generateContent`, {
          method: 'POST',
          // La clé voyage dans l'en-tête, pas dans l'adresse : un message d'erreur réseau cite l'adresse.
          headers: { 'Content-Type': 'application/json', 'x-goog-api-key': apiKey },
          body: JSON.stringify(corpsPour(niveau)),
          signal: AbortSignal.timeout(delaiMs),
        })
        if (res.ok) {
          const data = await res.json()
          if (utilisable && !utilisable(data)) {
            console.warn(`Model ${modele} : réponse vide ou illisible`)
            derniereErreur = new Error(`Model ${modele} : réponse vide`)
            niveau = undefined
            continue
          }
          niveauxRetenus.set(modele, niveau)
          const servi = typeof data.modelVersion === 'string' && data.modelVersion
            ? data.modelVersion.replace(/^models\//, '')
            : modele
          return { data, modele: servi, reflexion: niveau }
        }
        const texte = await res.text()
        console.warn(`Model ${modele} (réflexion ${niveau ?? 'par défaut'}) returned ${res.status}: ${texte.slice(0, 300)}`)
        derniereErreur = new Error(`Model ${modele} error (${res.status})`)
        // Un niveau de réflexion refusé : le cran au-dessus, puis sans réglage.
        niveau = res.status === 400 && niveau !== null && /thinking/i.test(texte) ? niveauAuDessus(niveau) : undefined
      } catch (e) {
        console.warn(`Model ${modele} failed:`, e instanceof Error ? e.message : e)
        derniereErreur = e
        niveau = undefined
      }
    }
    if (!relaisAjoutes && i === candidats.length - 1) {
      relaisAjoutes = true
      candidats = [...candidats, ...(await modelesDeRelais(apiKey, reglage.modele, essayes))]
    }
  }
  throw derniereErreur || new Error('All Gemini models failed')
}

// Le texte d'une réponse, sans les pensées du modèle.
function texteDeLaReponse(data: any): string {
  return data?.candidates?.[0]?.content?.parts?.filter((p: any) => !p.thought).map((p: any) => p.text ?? '').join('') ?? ''
}
// <<< Modèles Gemini <<<
