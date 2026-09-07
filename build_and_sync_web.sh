#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR/app"

SUPABASE_URL="https://fvnybncauhbpsnikzeeq.supabase.co"
SUPABASE_ANON_KEY="sb_publishable_P3P36VFswbjyOXxplwniPg_D_NuGYNF"

VERSION=$(grep '^version: ' "$DIR/app/pubspec.yaml" | awk '{print $2}')
BUILD_TIME=$(date +%s)

echo "🌐 Building Chatmelier Web (v$VERSION)..."
flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

echo "⚡ Applying cache-busting to flutter_bootstrap.js..."
sed -i "s|\"mainJsPath\":\"main.dart.js\"|\"mainJsPath\":\"main.dart.js?v=${VERSION}-${BUILD_TIME}\"|g" build/web/flutter_bootstrap.js

echo "📦 Syncing web build artifacts to repository root..."
cp -r build/web/* "$DIR/"
cp "$DIR/index.html" "$DIR/404.html"
cp "$DIR/index.html" "$DIR/app/build/web/404.html"

# Ensure legal and store docs are in place
if [ -f "$DIR/privacy.html" ]; then
  cp "$DIR/privacy.html" "$DIR/app/build/web/privacy.html"
fi
if [ -f "$DIR/terms.html" ]; then
  cp "$DIR/terms.html" "$DIR/app/build/web/terms.html"
fi
if [ -f "$DIR/app-ads.txt" ]; then
  cp "$DIR/app-ads.txt" "$DIR/app/build/web/app-ads.txt"
fi

echo "🚀 Syncing to Chatmelier/chatmelier.github.io (org)..."
TMP_DIR=$(mktemp -d)
git clone --depth 1 --branch main git@github.com:Chatmelier/chatmelier.github.io.git "$TMP_DIR"
cp -r "$DIR"/app/build/web/* "$TMP_DIR/"
cp -f "$DIR"/privacy.html "$TMP_DIR/" 2>/dev/null || true
cp -f "$DIR"/terms.html "$TMP_DIR/" 2>/dev/null || true
cp -f "$DIR"/app-ads.txt "$TMP_DIR/" 2>/dev/null || true
touch "$TMP_DIR/.nojekyll"

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
