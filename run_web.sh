#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR/app"

echo "🍷 Launching Chatmelier in Chrome..."
SUPABASE_URL="https://fvnybncauhbpsnikzeeq.supabase.co"
SUPABASE_ANON_KEY="sb_publishable_P3P36VFswbjyOXxplwniPg_D_NuGYNF"

flutter run -d chrome \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
