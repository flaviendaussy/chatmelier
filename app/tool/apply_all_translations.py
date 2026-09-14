# -*- coding: utf-8 -*-
"""Merges all translations into lib/l10n/app_*.arb files."""

import json
import os
import sys

from l10n_ja import JA_TRANSLATIONS
from l10n_zh import ZH_TRANSLATIONS
from l10n_ko import KO_TRANSLATIONS
from l10n_de import DE_TRANSLATIONS
from l10n_it import IT_TRANSLATIONS
from l10n_es import ES_TRANSLATIONS
from l10n_pt import PT_TRANSLATIONS
from l10n_nl import NL_TRANSLATIONS
from l10n_sv import SV_TRANSLATIONS
from l10n_ca import CA_TRANSLATIONS
from l10n_la import LA_TRANSLATIONS

LOCALE_MAP = {
    'ja': JA_TRANSLATIONS,
    'zh': ZH_TRANSLATIONS,
    'ko': KO_TRANSLATIONS,
    'de': DE_TRANSLATIONS,
    'it': IT_TRANSLATIONS,
    'es': ES_TRANSLATIONS,
    'pt': PT_TRANSLATIONS,
    'nl': NL_TRANSLATIONS,
    'sv': SV_TRANSLATIONS,
    'ca': CA_TRANSLATIONS,
    'la': LA_TRANSLATIONS,
}

def main():
    arb_dir = 'lib/l10n'
    en_path = os.path.join(arb_dir, 'app_en.arb')
    with open(en_path, 'r', encoding='utf-8') as f:
        en_data = json.load(f)

    en_keys = [k for k in en_data.keys() if not k.startswith('@') and k != '@@locale']
    print(f"Reference English has {len(en_keys)} translation keys.")

    for loc, trans_map in LOCALE_MAP.items():
        arb_path = os.path.join(arb_dir, f'app_{loc}.arb')
        if not os.path.exists(arb_path):
            print(f"File not found: {arb_path}")
            continue

        with open(arb_path, 'r', encoding='utf-8') as f:
            arb_content = json.load(f)

        # Ensure @@locale is preserved
        updated_count = 0
        added_count = 0

        for k, v in trans_map.items():
            if k in arb_content:
                if arb_content[k] != v:
                    arb_content[k] = v
                    updated_count += 1
            else:
                arb_content[k] = v
                added_count += 1

        # Check for any remaining missing keys from English
        still_missing = 0
        for k in en_keys:
            if k not in arb_content:
                print(f"  WARNING [{loc}]: Key still missing: {k}")
                still_missing += 1

        total_keys = len([k for k in arb_content.keys() if not k.startswith('@') and k != '@@locale'])
        print(f"Locale {loc}: updated {updated_count}, added {added_count} -> Total keys: {total_keys} (still missing: {still_missing})")

        with open(arb_path, 'w', encoding='utf-8') as f:
            json.dump(arb_content, f, indent=2, ensure_ascii=False)

    print("All ARB files updated successfully!")

if __name__ == '__main__':
    main()
