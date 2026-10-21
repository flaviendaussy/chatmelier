#!/usr/bin/env python3
"""Le JSON du compte de service tel qu'un copier-coller peut le laisser (21/10).

    python3 tool/essai_push/abimer.py '<json>' base64|guillemets|retours

base64 : le fichier joliment indenté, encodé ; guillemets : entouré d'apostrophes ;
retours : de vrais retours à la ligne dans la clé privée, à la place des « \\n ».
"""
import base64
import json
import sys

compte, forme = sys.argv[1], sys.argv[2]
if forme == 'base64':
    print(base64.b64encode(json.dumps(json.loads(compte), indent=2).encode()).decode())
elif forme == 'guillemets':
    print("'" + compte + "'")
elif forme == 'retours':
    print(compte.replace('\\n', '\n'))
else:
    raise SystemExit(f'forme inconnue : {forme}')
