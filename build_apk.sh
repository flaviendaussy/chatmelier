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

VERSION=$(grep '^version: ' "$DIR/app/pubspec.yaml" | awk '{print $2}')

flutter build apk --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

cp "$DIR/app/build/app/outputs/flutter-apk/app-release.apk" "$DIR/app/build/app/outputs/flutter-apk/chatmelier-v$VERSION.apk"
cp "$DIR/app/build/app/outputs/flutter-apk/app-release.apk" "$DIR/app/build/app/outputs/flutter-apk/chatmelier-latest.apk"
cp "$DIR/app/build/app/outputs/flutter-apk/app-release.apk" "$DIR/Chatmelier-release.apk"
cp "$DIR/app/build/app/outputs/flutter-apk/app-release.apk" "$DIR/chatmelier-latest.apk"

if [ -d "/home/flavien-daussy/Téléchargements" ]; then
  cp "$DIR/app/build/app/outputs/flutter-apk/app-release.apk" "/home/flavien-daussy/Téléchargements/Chatmelier-release.apk"
  cp "$DIR/app/build/app/outputs/flutter-apk/app-release.apk" "/home/flavien-daussy/Téléchargements/chatmelier-v$VERSION.apk"
  cp "$DIR/app/build/app/outputs/flutter-apk/app-release.apk" "/home/flavien-daussy/Téléchargements/chatmelier-latest.apk"
  echo "✅ Copied to /home/flavien-daussy/Téléchargements/Chatmelier-release.apk"
fi

echo "✅ Build complete! APK is located at: $DIR/Chatmelier-release.apk"
echo "✅ Also in Downloads: /home/flavien-daussy/Téléchargements/Chatmelier-release.apk"
echo "✅ Version: $VERSION"
