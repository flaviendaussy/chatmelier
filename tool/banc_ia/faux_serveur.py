"""Faux Gemini + faux Supabase, pour essayer les fonctions edge en local sans rien payer.

    python3 tool/banc_ia/faux_serveur.py <mode> <journal>

Modes :
  catalogue          find_cached_wine rend une fiche riche
  pauvre             find_cached_wine rend une fiche d'utilisateur sans cépage
  serveur_pauvre     find_cached_wine rend une fiche du serveur sans cépage (à compléter)
  inconnu            aucune fiche ; recherche Google allumée
  refuse_reflexion   comme « inconnu », mais Google refuse thinkingConfig (400)
  session            un utilisateur connecté, quota disponible
  limite             un utilisateur connecté, quota du jour épuisé
  strict             sans session, avec app_config.ia_session_obligatoire = true
  banc               pour le banc d'essai : session, aucun catalogue, quota libre ; le réglage
                     des modèles vient de la variable FAUX_MODELES_IA (JSON) et Gemini est le
                     vrai (GEMINI_BASE_URL non défini dans le conteneur)

Chaque requête reçue est écrite dans le journal (une ligne JSON), pour que l'essai vérifie
ce que la fonction a réellement envoyé.
"""
import json
import os
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer

MODE = sys.argv[1]
journal = open(sys.argv[2], 'a')

RICHE = {"id": "11111111-1111-1111-1111-111111111111", "name": "Bandol Rouge", "producer": "Domaine de Terrebrune",
         "vintage": 2019, "region": "Provence", "grapes": [{"name": "Mourvèdre", "pct": 85}],
         "tasting_notes": "Cuir, garrigue, cerise noire, tanins serrés et droits.", "ai_food_pairings": ["Gigot d'agneau"],
         "peak_drinking_start": 2027, "peak_drinking_end": 2035, "ideal_drinking_start": 2024, "ideal_drinking_end": 2040,
         "is_verified_online": False, "critic_scores": [{"source": "Inventé", "score": "99"}],
         "estimated_market_value": 30, "external_links": {}, "decrite_par_serveur": False}
PAUVRE = dict(RICHE, grapes=[], id="22222222-2222-2222-2222-222222222222")
SERVEUR_PAUVRE = dict(PAUVRE, decrite_par_serveur=True, id="33333333-3333-3333-3333-333333333333")


# Ce que Google publie (GET /v1beta/models), avec du bruit : préversions, voix, images.
MODELES_PUBLIES = ['gemini-3.8-flash', 'gemini-3.7-flash', 'gemini-3.6-flash', 'gemini-3.5-flash', 'gemini-3.5-flash-lite',
                   'gemini-3.1-flash-lite', 'gemini-3.1-pro-preview', 'gemini-3.8-flash-tts', 'gemini-3.1-flash-live-preview',
                   'gemini-3-pro-image-preview', 'gemini-flash-latest', 'gemini-flash-lite-latest']
# Un modèle retiré : Google répond 404, comme le jour où un modèle réglé disparaîtra.
MODELE_RETIRE = 'gemini-2.0-flash'


def noter(**kw):
    journal.write(json.dumps(kw, ensure_ascii=False) + '\n')
    journal.flush()


class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def rep(self, obj, code=200):
        b = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(b)))
        self.end_headers()
        self.wfile.write(b)

    def corps(self):
        n = int(self.headers.get('Content-Length', 0))
        return json.loads(self.rfile.read(n) or b'{}')

    def do_GET(self):
        noter(methode='GET', chemin=self.path)
        if self.path.startswith('/v1beta/models'):
            return self.rep({"models": [{"name": f"models/{m}", "supportedGenerationMethods": ["generateContent", "countTokens"]}
                                        for m in MODELES_PUBLIES]})
        if '/auth/v1/user' in self.path:
            if MODE in ('session', 'limite', 'banc'):
                return self.rep({"id": "00000000-0000-0000-0000-00000000a11c", "aud": "authenticated", "role": "authenticated"})
            return self.rep({"msg": "invalid JWT"}, 401)
        if '/rest/v1/chat_messages' in self.path:
            # Du plus récent au plus ancien, comme la requête de la fonction ; la question en
            # cours vient d'être enregistrée par l'app.
            return self.rep([{"role": "user", "content": "Et avec un agneau ?"},
                             {"role": "assistant", "content": "Un Bandol serait parfait."},
                             {"role": "user", "content": "Quel vin ce soir ?"}])
        if '/rest/v1/bottles' in self.path:
            return self.rep([{"id": "b0000000-0000-0000-0000-000000000001", "quantity": 2, "rack": "B", "shelf": "3",
                              "wines": {"name": "Bandol Rouge", "producer": "Domaine de Terrebrune", "vintage": 2019,
                                        "wine_type": "red", "region": "Provence", "appellation": "Bandol",
                                        "ideal_drinking_start": 2024, "ideal_drinking_end": 2040}}])
        if '/rest/v1/app_config' in self.path:
            if MODE == 'banc':
                return self.rep([{"cle": "modeles_ia", "valeur": json.loads(os.environ.get('FAUX_MODELES_IA', '{}'))},
                                 {"cle": "scan_etiquette_recherche", "valeur": False}])
            modeles = {"scan_etiquette_lecture": {"modele": "gemini-3.1-flash-lite", "reflexion": "minimal"}}
            modeles.update(json.loads(os.environ.get('FAUX_MODELES_IA', '{}')))
            lignes = [{"cle": "ia_session_obligatoire", "valeur": MODE == 'strict'},{"cle": "scan_etiquette_recherche", "valeur": MODE in ('inconnu', 'refuse_reflexion')},
                      {"cle": "modeles_ia", "valeur": modeles}]
            # Une seule clé demandée (eq.modeles_ia) : la ligne, comme maybeSingle l'attend.
            if 'cle=eq.modeles_ia' in self.path:
                return self.rep({"valeur": modeles})
            return self.rep(lignes)
        self.rep([])

    def do_PATCH(self):
        noter(methode='PATCH', chemin=self.path, corps=self.corps())
        self.rep([], 200)

    def do_POST(self):
        c = self.corps()
        noter(methode='POST', chemin=self.path, corps=c if 'generateContent' not in self.path else {
            'generationConfig': c.get('generationConfig'), 'tools': c.get('tools'),
            'systeme': ((c.get('systemInstruction') or {}).get('parts') or [{}])[0].get('text', '')[-400:],
            'tours': [(t['role'], len(t['parts'])) for t in c.get('contents', [])]})
        if '/rpc/consommer_quota_ia' in self.path:
            if MODE == 'limite':
                return self.rep({"autorise": False, "raison": "limite", "limite": 3, "anonyme": True, "restant": 0})
            return self.rep({"autorise": True, "limite": 15, "restant": 14})
        if '/rpc/get_cellar_stats' in self.path:
            return self.rep({"total": 2, "rouges": 2})
        if '/rpc/find_cached_wine' in self.path:
            fiche = {'catalogue': RICHE, 'pauvre': PAUVRE, 'serveur_pauvre': SERVEUR_PAUVRE}.get(MODE)
            return self.rep([fiche] if fiche else [])
        if '/rest/v1/wines' in self.path:
            return self.rep([], 201)
        if 'generateContent' in self.path:
            reglage = (c.get('generationConfig') or {}).get('thinkingConfig')
            modele = self.path.split('/models/')[1].split(':')[0]
            if modele == MODELE_RETIRE:
                return self.rep({"error": {"code": 404, "status": "NOT_FOUND",
                                           "message": f"models/{modele} is not found for API version v1beta"}}, 404)
            # Comme Google : les Flash 3.7 et 3.8 refusent la réflexion « minimal ».
            if reglage and reglage.get('thinkingLevel') == 'minimal' and any(v in modele for v in ('3.7-flash', '3.8-flash')) \
                    and 'lite' not in modele:
                return self.rep({"error": {"code": 400, "status": "INVALID_ARGUMENT", "message":
                                           "Thinking level MINIMAL is not supported for this model. Please retry with other thinking level."}}, 400)
            if MODE == 'refuse_reflexion' and reglage:
                return self.rep({"error": {"code": 400, "message": "Unknown name \"thinkingConfig\""}}, 400)
            if 'systemInstruction' in c:
                return self.rep({"candidates": [{"content": {"parts": [{"text": "Ouvrez le Bandol 2019 du casier B3."}]}}],
                                 "usageMetadata": {"promptTokenCount": 2100, "candidatesTokenCount": 180}})
            outils = 'tools' in c
            txt = c['contents'][0]['parts'][-1]['text']
            if txt.startswith('You are Chatmelier, a sommelier reading the by-the-glass board'):
                # L'ardoise d'un bar (V2.3 · J4) : des prix au verre, pas de bouteille.
                res = {"r": "Le Bar à Vins", "c": "EUR", "v": [
                    {"n": "Morgon Côte du Py", "p": "Jean Foillard", "y": 2022, "t": "r", "a": "Morgon", "rg": "Beaujolais",
                     "co": "France", "g": ["Gamay"], "b": None, "gl": [["verre", 9]], "m": [4, 6, 5, 8, 2, 4, 0, 1],
                     "tg": ["fruity"], "sc": "Croquant, à boire frais.", "fp": ["Charcuterie"], "ge": 0, "gr": "", "de": 0, "dr": ""},
                    {"n": "Muscadet sur lie", "p": "Domaine de l'Écu", "y": 2023, "t": "w", "a": "Muscadet Sèvre et Maine",
                     "rg": "Loire", "co": "France", "g": ["Melon de Bourgogne"], "b": None, "gl": [["12cl", 7]],
                     "m": [0, 8, 3, 5, 1, 8, 0, 1], "tg": ["mineral", "fresh"], "sc": "Salin et vif.", "fp": ["Huîtres"],
                     "ge": 0, "gr": "", "de": 0, "dr": ""}]}
                return self.rep({"candidates": [{"content": {"parts": [{"text": json.dumps(res)}]}}],
                                 "usageMetadata": {"promptTokenCount": 1800, "candidatesTokenCount": 400, "thoughtsTokenCount": 0}})
            if txt.startswith('You are Chatmelier, a sommelier reading a restaurant wine list') and os.environ.get('FAUX_PEPITES'):
                # Un modèle qui distribue pépites et bons plans à tout va (V2.3 · K9) : la fonction
                # n'en garde que les mieux notés, jamais sans raison, ni de bon plan sans prix.
                notes = [(1, 'a', 0, '', 40), (2, '', 0, '', 40), (1, 'b', 0, '', 40), (2, 'c', 0, '', 40), (1, 'd', 0, '', 40),
                         (0, '', 2, 'x', None), (0, '', 1, 'y', 40), (0, '', 1, 'z', 35), (0, '', 2, 'w', 50), (0, '', 1, 'v', 30),
                         (0, '', 1, '', 30), (0, '', 0, '', 30)]
                res = {"r": "La Grande Carte", "c": "EUR", "ex": 0, "v": [
                    {"n": f"Vin {i}", "p": f"Domaine {i}", "y": 2020, "t": "r", "a": None, "rg": "Bourgogne", "co": "France",
                     "g": ["Pinot Noir"], "b": b, "gl": [], "m": [5, 6, 5, 6, 3, 5, 0, 1], "tg": [], "sc": "", "fp": [],
                     "ge": ge, "gr": gr, "de": de, "dr": dr} for i, (ge, gr, de, dr, b) in enumerate(notes)]}
                return self.rep({"candidates": [{"content": {"parts": [{"text": json.dumps(res)}]}}],
                                 "usageMetadata": {"promptTokenCount": 3251, "candidatesTokenCount": 900, "thoughtsTokenCount": 0}})
            if txt.startswith('You are Chatmelier, a sommelier reading a restaurant wine list'):
                res = {"r": "Le Bistrot du Port", "c": "EUR", "v": [
                    {"n": "Bandol Rouge", "p": "Domaine de Terrebrune", "y": 2019, "t": "r", "a": "Bandol", "rg": "Provence",
                     "co": "France", "g": ["Mourvèdre", "Grenache"], "b": 68, "gl": [], "m": [8, 6, 8, 6, 4, 5, 0, 1],
                     "tg": ["tannic", "spicy", "inconnu"], "sc": "Un rouge solaire et structuré, pour l'agneau.",
                     "fp": ["Gigot d'agneau", "Daube provençale", "Tapenade"], "ge": 1, "gr": "Domaine de référence du mourvèdre", "de": 0, "dr": ""},
                    {"n": "Chablis 1er Cru Montmains", "p": "Domaine Laroche", "y": 2021, "t": "w", "a": "Chablis Premier Cru",
                     "rg": "Bourgogne", "co": "France", "g": ["Chardonnay"], "b": "54,5", "gl": [["12cl", 11]],
                     "m": [3, 8, 5, 5, 1, 9, 1, 1], "tg": ["mineral", "fresh"], "sc": "Tendu et salin, pour les huîtres.",
                     "fp": ["Huîtres", "Sole meunière", "Comté"], "ge": 0, "gr": "", "de": 1, "dr": "Premier cru sous 60 €"}]}
                return self.rep({"candidates": [{"content": {"parts": [{"text": json.dumps(res)}]}}],
                                 "usageMetadata": {"promptTokenCount": 3251, "candidatesTokenCount": 900, "thoughtsTokenCount": 0}})
            if ('sommelier' in txt or 'sumiller' in txt) and ('Question du client' in txt or 'The guest asks' in txt or 'El cliente pregunta' in txt):
                return self.rep({"candidates": [{"content": {"parts": [{"text": "Le Bandol, à 68 €, pour votre agneau."}]}}],
                                 "usageMetadata": {"promptTokenCount": 1203, "candidatesTokenCount": 120}})
            if txt.startswith('Read this wine bottle label'):
                res = {"producer": "Domaine de Terrebrune", "name": "Bandol Rouge", "vintage": 2019, "wine_type": "red",
                       "country": "France", "region": "Provence", "appellation": "Bandol"}
            else:
                res = {"tasting_notes": "Mourvèdre dominant : cuir, garrigue, fruits noirs, tanins serrés.",
                       "grapes": [{"name": "Mourvèdre", "pct": 85}, {"name": "Grenache", "pct": 10}, {"name": "Cinsault", "pct": 5}],
                       "peak_drinking_start": 2027, "ideal_drinking_start": 2024,
                       "estimated_market_value": 28 if outils else 45,
                       "valeur_source": "https://www.exemple-caviste.fr/terrebrune-2019" if outils else None,
                       "critic_scores": [{"source": "RVF", "score": "16/20"}] if outils else [],
                       "sources_verified": ["rvf.fr"] if outils else []}
            cand = {"content": {"parts": [{"text": ('```json\n' if outils else '') + json.dumps(res) + ('\n```' if outils else '')}]}}
            if outils:
                cand["groundingMetadata"] = {"webSearchQueries": ["Terrebrune Bandol 2019", "Terrebrune 2019 prix"]}
            return self.rep({"candidates": [cand], "usageMetadata": {"promptTokenCount": 100, "candidatesTokenCount": 50,
                                                                    "thoughtsTokenCount": 0 if reglage else 400}})
        self.rep({})


HTTPServer(('127.0.0.1', 8765), H).serve_forever()
