#!/usr/bin/env python3
"""Faux Supabase + faux Gemini, pour essayer `scan-label` et `taches-ia` sans rien payer.

    python3 tool/essai_scan/faux_serveurs.py 9877

Supabase : la session (auth/v1/user), le quota (consommer_quota_ia), le catalogue
(find_cached_wine : « Clos Connu » y a une fiche riche), l'écriture d'une fiche serveur
(wines), le cache des cépages (cepages_des_vins). Gemini : la liste des modèles et
generateContent — la lecture d'une étiquette quand la requête porte une image, une
description sinon ; les cépages quand la consigne les demande, avec une recherche Google
quand l'outil est joint. Chaque appel attend un peu, comme Google : la lecture 0,6 s, la
description 1,5 s. Tout ce qui arrive est rangé dans /journal (GET).
"""
import base64
import json
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

PORT = int(sys.argv[1])
etat = {'journal': [], 'cache_cepages': {}}

FICHE_RICHE = {
    'id': 'fiche-clos-connu', 'name': 'Clos Connu', 'producer': 'Domaine Témoin', 'vintage': 2019,
    'grapes': [{'name': 'Syrah', 'pct': 100}], 'tasting_notes': 'Fruits noirs, poivre, tanins fins et frais.',
    'peak_drinking_start': 2024, 'ideal_drinking_start': 2022, 'decrite_par_serveur': True,
}


def gemini_texte(texte, recherche=False):
    corps = {'candidates': [{'content': {'parts': [{'text': texte}]}}],
             'usageMetadata': {'promptTokenCount': 400, 'candidatesTokenCount': 120}, 'modelVersion': 'gemini-9.9-flash'}
    if recherche:
        corps['candidates'][0]['groundingMetadata'] = {
            'webSearchQueries': ['cépages Ungrafted Cinsault De Martino'],
            'groundingChunks': [{'web': {'uri': 'https://demartino.cl/ungrafted-cinsault', 'title': 'De Martino'}}],
        }
    return corps


class Gestion(BaseHTTPRequestHandler):
    def log_message(self, *_):
        pass

    def _repondre(self, statut, corps=None):
        donnees = b'' if corps is None else json.dumps(corps).encode()
        self.send_response(statut)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(donnees)))
        self.end_headers()
        self.wfile.write(donnees)

    def _corps(self):
        n = int(self.headers.get('Content-Length') or 0)
        return json.loads(self.rfile.read(n) or b'{}') if n else {}

    def do_GET(self):
        url = urlparse(self.path)
        if url.path == '/journal':
            return self._repondre(200, etat['journal'])
        if url.path == '/auth/v1/user':
            return self._repondre(200, {'id': 'u-flavien', 'aud': 'authenticated', 'role': 'authenticated', 'email': 'f@example.com'})
        if url.path == '/rest/v1/app_config':
            return self._repondre(200, [{'cle': 'scan_etiquette_recherche', 'valeur': False}])
        if url.path == '/rest/v1/cepages_des_vins':
            q = parse_qs(url.query)
            cle = (q.get('cle', [''])[0]).removeprefix('eq.')
            ligne = etat['cache_cepages'].get(cle)
            etat['journal'].append({'cache_lu': cle, 'trouve': ligne is not None})
            return self._repondre(200, [ligne] if ligne else [])
        if url.path == '/rest/v1/wines':
            etat['journal'].append({'catalogue_lu': url.query})
            q = parse_qs(url.query)
            nom = ' '.join(q.get('name', []))
            if 'Clos Connu' in nom:
                return self._repondre(200, [FICHE_RICHE])
            return self._repondre(200, [])
        if url.path == '/v1beta/models':
            return self._repondre(200, {'models': [
                {'name': 'models/gemini-9.9-flash', 'supportedGenerationMethods': ['generateContent']},
                {'name': 'models/gemini-9.9-flash-lite', 'supportedGenerationMethods': ['generateContent']},
            ]})
        return self._repondre(404, {'error': url.path})

    def do_POST(self):
        url = urlparse(self.path)
        corps = self._corps()
        if url.path == '/rest/v1/rpc/consommer_quota_ia':
            etat['journal'].append({'quota': corps.get('p_fonction')})
            return self._repondre(200, {'autorise': True, 'restant': 10})
        if url.path == '/rest/v1/rpc/find_cached_wine':
            etat['journal'].append({'catalogue': corps.get('p_name')})
            return self._repondre(200, [FICHE_RICHE] if corps.get('p_name') == 'Clos Connu' else [])
        if url.path == '/rest/v1/wines':
            etat['journal'].append({'fiche_ecrite': corps.get('name') if isinstance(corps, dict) else corps})
            return self._repondre(201, None)
        if url.path == '/rest/v1/cepages_des_vins':
            lignes = corps if isinstance(corps, list) else [corps]
            for l in lignes:
                etat['cache_cepages'][l['cle']] = l
                etat['journal'].append({'cache_ecrit': l['cle'], 'cepages': l.get('cepages'), 'methode': l.get('methode'), 'recherche_faite': l.get('recherche_faite')})
            return self._repondre(201, None)
        if url.path.startswith('/v1beta/models/') and url.path.endswith(':generateContent'):
            parts = corps['contents'][0]['parts']
            image = any('inlineData' in p for p in parts)
            consigne = ' '.join(p.get('text', '') for p in parts)
            recherche = bool(corps.get('tools'))
            if image:
                time.sleep(0.6)
                etat['journal'].append({'gemini': 'lecture'})
                images = [base64.b64decode(p['inlineData']['data']) for p in parts if 'inlineData' in p]
                nom = 'Clos Connu' if any(b'CONNU' in i for i in images) else 'Ungrafted Cinsault'
                return self._repondre(200, gemini_texte(json.dumps({
                    'producer': 'De Martino' if nom != 'Clos Connu' else 'Domaine Témoin', 'name': nom, 'vintage': 2025,
                    'cuvee_parcel': None, 'wine_type': 'red', 'country': 'Chile', 'region': 'Itata', 'sub_region': None,
                    'appellation': None, 'classification': None, 'alcohol_pct': 13.0})))
            if 'grape varieties' in consigne and '"cepages"' in consigne:
                time.sleep(0.8)
                etat['journal'].append({'gemini': 'cepages', 'recherche': recherche, 'insiste': 'You answered without searching' in consigne,
                                        'reflexion': (corps.get('generationConfig', {}).get('thinkingConfig') or {}).get('thinkingLevel')})
                insiste = 'You answered without searching' in consigne
                if 'Vin Introuvable' in consigne:
                    return self._repondre(200, gemini_texte(json.dumps({'trouve': False, 'cepages': [], 'source': None}), recherche=True))
                # Le modèle qui croit savoir (23/10, en production) : pas de recherche, les
                # cépages de la région.
                if 'Vinhas Velhas' in consigne:
                    return self._repondre(200, gemini_texte(json.dumps({'trouve': True, 'source': None,
                        'cepages': [{'name': 'Aragonez'}, {'name': 'Trincadeira'}, {'name': 'Baga'}]}), recherche=False))
                # Celui qui ne cherche qu'au second appel.
                if 'Bernate' in consigne:
                    if not insiste:
                        return self._repondre(200, gemini_texte(json.dumps({'trouve': True, 'cepages': [{'name': 'Malvasía Riojana'}], 'source': None})))
                    return self._repondre(200, gemini_texte(json.dumps({'trouve': True, 'cepages': [{'name': 'Viura', 'pct': 70}, {'name': 'Malvasía Riojana', 'pct': 30}],
                        'source': 'https://exopto.net/el-bernate'}), recherche=True))
                if 'Finca Notables Tannat' in consigne:
                    return self._repondre(200, gemini_texte(json.dumps({'trouve': True, 'cepages': [{'name': 'Tannat', 'pct': 100}], 'source': None})))
                return self._repondre(200, gemini_texte(json.dumps({
                    'trouve': True, 'cepages': [{'name': 'Cinsault', 'pct': 100}],
                    'source': 'https://demartino.cl/ungrafted-cinsault'}), recherche=recherche))
            time.sleep(1.5)
            etat['journal'].append({'gemini': 'description'})
            return self._repondre(200, gemini_texte(json.dumps({
                'tasting_notes': 'Fruits rouges croquants, tanins souples, finale fraîche.',
                'grapes': [{'name': 'Cinsault', 'pct': 100}], 'ideal_drinking_start': 2025, 'ideal_drinking_end': 2029,
                'peak_drinking_start': 2026, 'peak_drinking_end': 2028, 'food_pairings': ['Volaille rôtie'],
                'ai_summary': 'Un Cinsault de vieilles vignes, léger et frais.'})))
        return self._repondre(404, {'error': url.path})


ThreadingHTTPServer(('127.0.0.1', PORT), Gestion).serve_forever()
