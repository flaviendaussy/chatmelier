#!/usr/bin/env bash
# ==============================================================================
# Chatmelier — lire et piloter l'écran EN TEXTE plutôt qu'en images
# ==============================================================================
#
#   ./tool/screen.sh                    liste ce qui est affiché
#   ./tool/screen.sh tap "Tasting"      touche l'élément portant ce libellé
#   ./tool/screen.sh has "2028-2035"    code de sortie 0 si présent, 1 sinon
#   ./tool/screen.sh grep apogée        filtre les libellés
#   ./tool/screen.sh route              l'écran courant, en une ligne
#
# POURQUOI
# Flutter dessine dans un canevas : `uiautomator` n'y voyait rien, ce qui imposait une
# CAPTURE D'IMAGE pour vérifier quoi que ce soit, et une navigation à l'aveugle par
# coordonnées. Une image coûte des milliers de jetons ; se tromper de cible en coûte deux
# fois, puisqu'il faut une seconde capture pour comprendre où l'on a atterri.
#
# Le build de test publie désormais l'arbre sémantique (`--dart-define=CHATMELIER_SEMANTICS=on`,
# voir `main.dart`). L'écran devient du texte : lisible, filtrable, et surtout ASSERTABLE
# par un script au lieu d'un œil.
#
# Garder la capture d'écran pour ce qu'elle seule montre : une mise en page, un
# chevauchement, une couleur. Pas pour savoir où l'on est ni ce qui est écrit.
# ==============================================================================
set -euo pipefail

export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export PATH="$ANDROID_HOME/platform-tools:$PATH"

DUMP=/tmp/chatmelier-ui.xml

capture() {
  adb shell uiautomator dump /sdcard/ui.xml > /dev/null 2>&1 || {
    echo "❌ dump impossible — l'app tourne-t-elle ?" >&2; exit 1; }
  adb shell cat /sdcard/ui.xml 2>/dev/null > "$DUMP"
}

# Libellés visibles, un par ligne. Les emoji et retours ligne sont remis en clair.
libelles() {
  grep -o 'content-desc="[^"]*"' "$DUMP" \
    | sed 's/content-desc="//; s/"$//' \
    | grep -v '^$' \
    | python3 -c "
import sys, html
for l in sys.stdin:
    print(html.unescape(l.rstrip()).replace(chr(10), ' · '))
"
}

# Centre de l'élément dont le libellé contient l'argument.
centre_de() {
  python3 - "$DUMP" "$1" <<'PY'
import sys, re, html
xml = open(sys.argv[1], encoding='utf-8').read()
cible = sys.argv[2].lower()
def reduire(t):
    # On compare sur les seuls caracteres signifiants : les separateurs affiches
    # (retours ligne, points medians, emoji) varient selon le rendu et feraient
    # echouer une comparaison litterale.
    return re.sub(r'[^a-z0-9]', '', t.lower())

besoin = reduire(cible)
candidats = []
for m in re.finditer(r'content-desc="([^"]*)"[^>]*?bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', xml):
    desc = html.unescape(m.group(1))
    if not desc:
        continue
    r = reduire(desc)
    if besoin not in r:
        continue
    x1, y1, x2, y2 = map(int, m.groups()[1:])
    candidats.append((r, (x1 + x2) // 2, (y1 + y2) // 2))

if not candidats:
    sys.exit(1)

# L'egalite exacte l'emporte, puis le debut de libelle, puis le plus court.
# Sans cette hierarchie, demander « Cellar » touchait « Cellar & Out-of-Cellar » :
# la sous-chaine seule choisit au hasard parmi tous les libelles qui la contiennent.
exact = [c for c in candidats if c[0] == besoin]
prefixe = [c for c in candidats if c[0].startswith(besoin)]
choix = (exact or prefixe or sorted(candidats, key=lambda c: len(c[0])))[0]
print(choix[1], choix[2])
PY
}

case "${1:-list}" in
  list) capture; libelles ;;

  grep)
    capture
    libelles | grep -i --color=never -e "${2:?motif attendu}" || {
      echo "(aucun libellé ne contient « $2 »)"; exit 1; }
    ;;

  has)
    capture
    if libelles | grep -qi -e "${2:?texte attendu}"; then
      echo "✅ « $2 » présent"; exit 0
    else
      echo "❌ « $2 » ABSENT"; exit 1
    fi
    ;;

  tap)
    capture
    coord=$(centre_de "${2:?libellé attendu}") || {
      echo "❌ aucun élément ne porte « $2 »" >&2
      echo "   visibles :" >&2; libelles | sed 's/^/     /' >&2
      exit 1; }
    adb shell input tap $coord
    echo "👆 « $2 » ($coord)"
    ;;

  route)
    capture
    n=$(libelles | wc -l)
    echo "$(libelles | head -3 | paste -sd' | ') — $n éléments"
    ;;

  *) sed -n '3,16p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'; exit 1 ;;
esac
