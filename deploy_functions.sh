#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR/supabase"

PROJECT_ID="fvnybncauhbpsnikzeeq"
GEMINI_KEY="${GEMINI_API_KEY:-}"

echo "⚡ Linking Supabase project: $PROJECT_ID..."
npx supabase link --project-ref "$PROJECT_ID"

if [ -n "$GEMINI_KEY" ]; then
  echo "🔑 Setting Gemini API Key secret..."
  npx supabase secrets set GEMINI_API_KEY="$GEMINI_KEY"
else
  echo "ℹ️ GEMINI_API_KEY environment variable not passed, keeping existing Supabase secret."
fi

echo "🚀 Deploying Edge Functions (scan-label, chat, visual-match, update-wine-values)..."
npx supabase functions deploy

echo "✅ Edge functions deployed successfully!"
