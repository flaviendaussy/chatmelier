#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR/app"

export JAVA_HOME="/home/flavien-daussy/.jdk"
export ANDROID_HOME="/home/flavien-daussy/Android/Sdk"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

echo "📱 Building Chatmelier Android APK for Pixel 7 & Pixel 8 Pro..."
SUPABASE_URL="https://fvnybncauhbpsnikzeeq.supabase.co"
SUPABASE_ANON_KEY="sb_publishable_P3P36VFswbjyOXxplwniPg_D_NuGYNF"

flutter build apk --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

echo "✅ Build complete! APK is located at: $DIR/app/build/app/outputs/flutter-apk/app-release.apk"
