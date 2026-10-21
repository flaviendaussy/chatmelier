#!/usr/bin/env python3
"""Faux Supabase + faux Google + faux Firebase, pour essayer `envoyer-push` sans rien envoyer.

    python3 tool/essai_push/faux_serveurs.py 9876 /chemin/cle_publique.pem

Supabase (service_role) : la réservation (`reserver_le_push`, une seule fois), les appareils
du destinataire, le nom de l'acteur, le nombre de non lues, l'effacement d'un jeton mort.
Google : vérifie la signature RS256 du jeton du compte de service avec la clé publique.
Firebase : refuse le jeton « jeton-mort… » (UNREGISTERED), accepte les autres.
Tout ce qui arrive est rangé dans /journal (GET), pour que l'essai le relise.
"""
import base64
import datetime
import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding

PORT = int(sys.argv[1])
CLE = serialization.load_pem_public_key(open(sys.argv[2], 'rb').read())

NOTIF = {
    'id': '11111111-2222-3333-4444-555555555555', 'user_id': 'u-flavien', 'actor_id': 'u-caro',
    'type': 'activite_cave', 'title': 'Votre cave partagée', 'body': 'Caro a ajouté 3 bouteilles à « London ».',
    'data': {'cellar_id': 'c1', 'cellar_name': 'London', 'nombre': 3, 'route': '/cellar'},
}
# L'heure UTC du moment : un appareil réglé pour être à 23 h chez lui (heures calmes).
maintenant = datetime.datetime.now(datetime.timezone.utc)
decalage_23h = ((23 * 60) - (maintenant.hour * 60 + maintenant.minute)) % 1440
if decalage_23h > 840:
    decalage_23h -= 1440
APPAREILS = [
    {'jeton': 'jeton-android-fr-0123456789', 'plateforme': 'android', 'langue': 'fr', 'decalage_min': decalage_23h - 9 * 60 if decalage_23h - 9 * 60 >= -840 else decalage_23h + 15 * 60, 'preferences': {}},
    {'jeton': 'jeton-ios-en-0123456789', 'plateforme': 'ios', 'langue': 'en', 'decalage_min': decalage_23h - 9 * 60 if decalage_23h - 9 * 60 >= -840 else decalage_23h + 15 * 60, 'preferences': {}},
    {'jeton': 'jeton-calme-0123456789', 'plateforme': 'android', 'langue': 'fr', 'decalage_min': decalage_23h, 'preferences': {}},
    {'jeton': 'jeton-coupe-0123456789', 'plateforme': 'android', 'langue': 'fr', 'decalage_min': 0, 'preferences': {'activite_cave': False}},
    {'jeton': 'jeton-mort-0123456789', 'plateforme': 'android', 'langue': 'it', 'decalage_min': decalage_23h - 9 * 60 if decalage_23h - 9 * 60 >= -840 else decalage_23h + 15 * 60, 'preferences': {}},
]
etat = {'reservee': False, 'journal': []}


def b64d(s):
    return base64.urlsafe_b64decode(s + '=' * (-len(s) % 4))


class Gestion(BaseHTTPRequestHandler):
    def log_message(self, *_):
        pass

    def _repondre(self, statut, corps=None, entetes=None):
        donnees = b'' if corps is None else json.dumps(corps).encode()
        self.send_response(statut)
        self.send_header('Content-Type', 'application/json')
        for k, v in (entetes or {}).items():
            self.send_header(k, v)
        self.send_header('Content-Length', str(len(donnees)))
        self.end_headers()
        if self.command != 'HEAD':
            self.wfile.write(donnees)

    def _corps(self):
        n = int(self.headers.get('Content-Length') or 0)
        return self.rfile.read(n).decode() if n else ''

    def do_GET(self):
        u = urlparse(self.path)
        if u.path == '/journal':
            return self._repondre(200, etat['journal'])
        if u.path == '/rest/v1/appareils_push':
            return self._repondre(200, APPAREILS)
        if u.path == '/rest/v1/profiles':
            return self._repondre(200, {'display_name': 'Caro'})
        return self._repondre(404, {'message': u.path})

    def do_HEAD(self):
        u = urlparse(self.path)
        if u.path == '/rest/v1/user_notifications':
            return self._repondre(200, None, {'Content-Range': '0-4/5'})
        return self._repondre(404)

    def do_DELETE(self):
        u = urlparse(self.path)
        etat['journal'].append({'efface': u.path, 'requete': parse_qs(u.query)})
        return self._repondre(204)

    def do_POST(self):
        u = urlparse(self.path)
        corps = self._corps()
        if u.path == '/rest/v1/rpc/reserver_le_push':
            if self.headers.get('Authorization') != 'Bearer cle-service-de-test':
                return self._repondre(401, {'message': 'service_role attendu'})
            if etat['reservee']:
                return self._repondre(200, [])
            etat['reservee'] = True
            return self._repondre(200, [NOTIF])
        if u.path == '/token':
            assertion = parse_qs(corps)['assertion'][0]
            entete, charge, signature = assertion.split('.')
            try:
                CLE.verify(b64d(signature), f'{entete}.{charge}'.encode(), padding.PKCS1v15(), hashes.SHA256())
            except Exception:
                return self._repondre(400, {'error': 'invalid_grant', 'error_description': 'signature'})
            revendications = json.loads(b64d(charge))
            etat['journal'].append({'jeton_google': revendications})
            return self._repondre(200, {'access_token': 'jeton-acces-de-test', 'expires_in': 3599})
        if u.path.endswith('/messages:send'):
            if self.headers.get('Authorization') != 'Bearer jeton-acces-de-test':
                return self._repondre(401, {'error': 'auth'})
            m = json.loads(corps)['message']
            etat['journal'].append({'fcm': u.path, 'message': m})
            if m['token'].startswith('jeton-mort'):
                return self._repondre(404, {'error': {'status': 'NOT_FOUND', 'details': [{'errorCode': 'UNREGISTERED'}]}})
            return self._repondre(200, {'name': 'projects/p/messages/1'})
        return self._repondre(404, {'message': u.path})


ThreadingHTTPServer(('127.0.0.1', PORT), Gestion).serve_forever()
