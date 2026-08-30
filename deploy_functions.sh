#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR/supabase"

PROJECT_ID="fvnybncauhbpsnikzeeq"
GEMINI_KEY="AQ.Ab8RN6JFZQNPfXmDdjdGT0posCOmn_4wPIFv_TiviorSGL6BDg"

echo "⚡ Linking Supabase project: $PROJECT_ID..."
npx supabase link --project-ref "$PROJECT_ID"

echo "🔑 Setting Gemini API Key secret..."
npx supabase secrets set GEMINI_API_KEY="$GEMINI_KEY"

echo "🚀 Deploying Edge Functions (scan-label, chat, visual-match, update-wine-values)..."
npx supabase functions deploy

echo "✅ Edge functions deployed successfully!"
