#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR/app"

SUPABASE_URL="https://fvnybncauhbpsnikzeeq.supabase.co"
SUPABASE_ANON_KEY="sb_publishable_P3P36VFswbjyOXxplwniPg_D_NuGYNF"

VERSION=$(grep '^version: ' "$DIR/app/pubspec.yaml" | awk '{print $2}')
BUILD_TIME=$(date +%s)

echo "🌐 Building Chatmelier Web (v$VERSION)..."
# Build vidé d'abord : `flutter build web` n'efface pas ce qu'il ne produit plus. Le 29/09,
# une console admin retirée du code en S0 dormait encore dans build/web, avec la clé
# service_role, et ce script l'a republiée sur le site public.
rm -rf build/web
flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=CHATMELIER_VERSION="$VERSION"

echo "⚡ Applying cache-busting to flutter_bootstrap.js..."
sed -i "s|\"mainJsPath\":\"main.dart.js\"|\"mainJsPath\":\"main.dart.js?v=${VERSION}-${BUILD_TIME}\"|g" build/web/flutter_bootstrap.js

# La page invité légère (web/table/, V2.3 · F2) : HTML et JS sans Flutter, copiés tels
# quels par `flutter build web`. Elle lit l'adresse du projet et sa clé publiable dans ce
# fichier, écrit ici depuis les mêmes variables que l'app : aucun fichier suivi n'en porte
# de copie.
if [ ! -f build/web/table/index.html ]; then
  echo "❌ build/web/table/ absent : la page invité ne serait pas publiée." >&2
  exit 1
fi
printf "window.CHATMELIER_CONFIG = { supabaseUrl: '%s', supabaseKey: '%s' };\n" \
  "$SUPABASE_URL" "$SUPABASE_ANON_KEY" > build/web/table/config.js
# GitHub Pages garde chaque fichier dix minutes en cache : sans version dans leur adresse,
# une page neuve pouvait charger l'ancien table.js après une publication.
sed -i -E "s#(href|src)=\"(table\.css|config\.js|table\.js)\"#\1=\"\2?v=${VERSION}-${BUILD_TIME}\"#g" build/web/table/index.html
grep -q "table.js?v=" build/web/table/index.html || { echo "❌ version absente des adresses de la page invité." >&2; exit 1; }

# Plus de copie à la racine du dépôt (08/10, PROD_MIGRATION.md · Nettoyage) : le site est
# servi depuis Chatmelier/chatmelier.github.io, et le Pages de ce dépôt par son workflow.
# La racine recevait main.dart.js (10 Mo) et le reste à chaque publication, pour rien.
# privacy.html, terms.html et app-ads.txt viennent d'app/web/, déjà dans build/web.
cp build/web/index.html build/web/404.html
for f in privacy.html terms.html app-ads.txt; do
  [ -f "build/web/$f" ] || { echo "❌ build/web/$f absent : il ne serait pas publié." >&2; exit 1; }
done
# ⚠️  La console admin n'est plus déployée : elle embarquait un JWT service_role Supabase
#     en clair, lisible par quiconque ouvrait le code source de la page publique.
#     Le `cp -r` vers une cible existante ajoutait en prime un niveau d'imbrication à chaque
#     déploiement (7 copies empilées au moment du retrait).
#     À reconstruire avec une authentification serveur avant toute remise en ligne.

echo "🚀 Syncing to Chatmelier/chatmelier.github.io (org)..."
TMP_DIR=$(mktemp -d)
git clone --depth 1 --branch main git@github.com:Chatmelier/chatmelier.github.io.git "$TMP_DIR"
cp -r "$DIR"/app/build/web/* "$TMP_DIR/"
# Les liens d'une table s'ouvrent dans l'app installée (#25) : Android vérifie
# /.well-known/assetlinks.json, que le motif * ci-dessus ne copie pas (dossier caché).
if [ -d "$DIR/app/build/web/.well-known" ]; then
  cp -r "$DIR/app/build/web/.well-known" "$TMP_DIR/"
fi
rm -rf "$TMP_DIR/admin_console"
# (console admin volontairement non déployée — voir la note plus haut)
touch "$TMP_DIR/.nojekyll"

# Garde-fou : aucun jeton ne part sur le site public. Un JWT (eyJhbGciOi…) ou une clé
# secrète Supabase (sb_secret_…) dans ce qui va être publié annule tout.
if grep -rlE 'eyJhbGciOi[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.|sb_secret_[A-Za-z0-9]{10,}' "$TMP_DIR" \
     --include='*.html' --include='*.js' --include='*.json' --include='*.txt' > /dev/null 2>&1; then
  echo "❌ Jeton détecté dans le site à publier — publication ANNULÉE :" >&2
  grep -rlE 'eyJhbGciOi[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.|sb_secret_[A-Za-z0-9]{10,}' "$TMP_DIR" \
     --include='*.html' --include='*.js' --include='*.json' --include='*.txt' >&2
  rm -rf "$TMP_DIR"
  exit 1
fi

cd "$TMP_DIR"
git add -A
if ! git diff-index --quiet HEAD --; then
  git commit -m "deploy: update chatmelier.github.io to v$VERSION"
  git push origin main
  echo "✅ Chatmelier/chatmelier.github.io successfully updated to v$VERSION!"
else
  echo "ℹ️ Chatmelier/chatmelier.github.io is already up-to-date."
fi
rm -rf "$TMP_DIR"

cd "$DIR"
echo "✅ Webapp build and dual-domain synchronization complete (v$VERSION)!"
