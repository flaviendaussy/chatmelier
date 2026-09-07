#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR/app"

SUPABASE_URL="https://fvnybncauhbpsnikzeeq.supabase.co"
SUPABASE_ANON_KEY="sb_publishable_P3P36VFswbjyOXxplwniPg_D_NuGYNF"

VERSION=$(grep '^version: ' "$DIR/app/pubspec.yaml" | awk '{print $2}')

echo "🌐 Building Chatmelier Web (v$VERSION)..."
flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

echo "📦 Syncing web build artifacts to repository root..."
cp -r build/web/* "$DIR/"

echo "✅ Webapp successfully synchronized with APK (v$VERSION)!"
