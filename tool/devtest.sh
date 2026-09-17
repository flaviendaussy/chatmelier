#!/usr/bin/env bash
# ==============================================================================
# Chatmelier — outillage de test en direct sur émulateur Android
# ==============================================================================
#
# Pourquoi ce script : l'environnement de ce poste n'exporte ni JAVA_HOME ni
# ANDROID_HOME, et l'AVD doit tourner AVEC fenêtre (Flavien veut voir l'app).
# Sans ça, chaque session recommence le même bricolage.
#
#   ./tool/devtest.sh up        démarre l'émulateur Pixel 7 (avec fenêtre)
#   ./tool/devtest.sh save      fige l'état courant (session connectée incluse)
#   ./tool/devtest.sh restore   redémarre sur l'état figé
#   ./tool/devtest.sh install   compile en profile et installe
#   ./tool/devtest.sh shot NOM  capture d'écran dans /tmp/chatmelier-shots/
#
# ⚠️  AVANT DE PRENDRE UNE CAPTURE, ESSAYER `./tool/screen.sh`.
#     L'écran s'y lit EN TEXTE — dix à quinze fois moins cher qu'une image — et se pilote
#     par libellé plutôt que par coordonnées. La capture ne sert qu'à ce qu'elle seule
#     montre : une mise en page, un chevauchement, une couleur.
#     Elle exige un build avec --dart-define=CHATMELIER_SEMANTICS=on (voir `install`).
#   ./tool/devtest.sh logs      erreurs Flutter et plantages natifs
#
# L'instantané « logged_in » contient une session d'authentification : il vit
# dans ~/.android/ et ne doit JAMAIS être copié dans le dépôt.
# ==============================================================================
set -euo pipefail

export JAVA_HOME="${JAVA_HOME:-/home/flavien-daussy/.jdk}"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
export DISPLAY="${DISPLAY:-:0}"

AVD="chatmelier_pixel7"
SNAPSHOT="logged_in"
PKG="com.chatmelier.chatmelier"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHOTS="/tmp/chatmelier-shots"

wait_boot() {
  echo "⏳ démarrage…"
  for _ in $(seq 1 90); do
    if [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; then
      echo "✅ $(adb shell getprop ro.product.model | tr -d '\r') prêt"; return 0
    fi
    sleep 5
  done
  echo "❌ délai dépassé"; return 1
}

case "${1:-}" in
  up)
    # JAMAIS -no-window : voir tool/devtest.sh en tête de fichier.
    nohup emulator -avd "$AVD" -no-audio -no-boot-anim \
      -gpu host -netdelay none -netspeed full \
      > /tmp/chatmelier-emulator.log 2>&1 &
    wait_boot
    ;;

  restore)
    nohup emulator -avd "$AVD" -snapshot "$SNAPSHOT" -no-audio -no-boot-anim \
      -gpu host -netdelay none -netspeed full \
      > /tmp/chatmelier-emulator.log 2>&1 &
    wait_boot
    echo "↩️  état restauré depuis l'instantané « $SNAPSHOT »"
    ;;

  save)
    adb emu avd snapshot save "$SNAPSHOT"
    echo "💾 état figé dans « $SNAPSHOT » — restaurable avec : $0 restore"
    ;;

  install)
    cd "$DIR/app"
    # La sémantique rend l'écran lisible en texte par ./tool/screen.sh.
    flutter build apk --profile --target-platform android-x64 \
      --dart-define=CHATMELIER_SEMANTICS=on 2>&1 | tail -2
    # -r préserve les données de l'app, donc la session connectée.
    adb install -r -t build/app/outputs/flutter-apk/app-profile.apk 2>&1 | tail -1
    ;;

  run)
    adb shell am force-stop "$PKG" || true
    adb shell am start -n "$PKG/.MainActivity" > /dev/null
    echo "▶️  $PKG lancé"
    ;;

  shot)
    mkdir -p "$SHOTS"
    name="${2:-capture_$(date +%H%M%S)}"
    adb exec-out screencap -p > "$SHOTS/$name.png"
    echo "📸 $SHOTS/$name.png"
    ;;

  logs)
    echo "=== erreurs Flutter et plantages natifs ==="
    adb logcat -d -s flutter:E AndroidRuntime:E 2>/dev/null | tail -30 || echo "  (aucune)"
    echo "=== ANR ==="
    adb logcat -d 2>/dev/null | grep -iE "ANR in|Reason:" | tail -5 || echo "  (aucun)"
    ;;

  *)
    sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'
    exit 1
    ;;
esac
