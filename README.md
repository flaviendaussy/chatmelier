# 🍷 Chatmelier — Smart Wine Cellar Manager

A cross-platform wine cellar management app with AI-powered label recognition, zero-hallucination web-verified enrichment, top critic rankings, semi-annual valuation tracking, multi-cellar support, and Model Context Protocol (MCP) integration.

---

## 🚀 Key Features

- 📸 **Label Scanner & OCR**: Snap 1–2 photos (front and back label) — AI extracts precise estate, cuvée/parcel, vintage, AOC, and classification.
- ⚡ **Zero Re-billing / Smart Cache**: Instant match against your shared wine catalog. If a wine was already enriched, it reuses the verified knowledge without paying for new internet search API calls.
- 🌐 **Zero-Invention Web-Grounded Enrichment**: Searches verified internet sources for factual technical data, accurate grape % blends, optimal drinking windows, and verified citations.
- ⭐ **Top 5 Critic Rankings**: Gathers scores and reviews from trusted sources (Robert Parker / Wine Advocate, Wine Spectator, Decanter, James Suckling, Jancis Robinson, Vinous).
- 💰 **Valuation Tracking & 6-Month Revaluation**:
  - Optional user-entered purchase price paid.
  - Current estimated market price in EUR (€) from real listings.
  - Automated cron Edge Function revaluing your cellar every 6 months with price history logging.
- 🏡 **Multi-Cellar Support**: Add and nickname multiple cellars (e.g. *"Home Cave"*, *"Dad's Basement"*, *"Country House"*), with optional geographic locations.
- 👥 **Granular Multi-User Sharing**:
  - Passwordless Magic Link (OTP), Email/Password, or Google OAuth.
  - View-only (`viewer`) or Full Write (`editor`) access per shared cellar.
  - Invite by email or one-tap shareable link with accept/decline inbox.
  - Real-time instant sync across phones, tablets, and computers.
- 🥂 **Visual Checkout**: Snap a photo to open a bottle — matches existing cellar label embeddings with instant vintage confirmation.
- 💬 **AI Sommelier Chat**: Chat directly with *Chatmelier*, who has full context of your cellar, suggests food pairings, and alerts you to bottles nearing peak.
- 🔌 **MCP Server**: Query your cellar natively inside Claude Desktop, Cursor, or AI coding agents.

---

## 🏗️ Architecture

```
chatmelier/
├── app/          # Flutter application (Android, iOS, Web, macOS, Windows)
├── supabase/     # Supabase backend (PostgreSQL 15+, pgvector, Edge Functions)
└── mcp-server/   # Model Context Protocol Server (TypeScript)
```

---

## 🛠️ Quick Start

### 1. Supabase Backend
```bash
cd supabase
# Install Supabase CLI if needed: npm install -g supabase
supabase start

# Apply all migrations (001_initial_schema to 005_advanced_enrichment_and_multi_cellar)
supabase db push

# Set required Edge Function secrets
supabase secrets set GEMINI_API_KEY=your-gemini-api-key
```

### 2. Flutter Mobile & Web App
```bash
cd app
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Run on Android
flutter run -d android \
  --dart-define=SUPABASE_URL=http://localhost:54321 \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key

# Run on Chrome / Web
flutter run -d chrome \
  --dart-define=SUPABASE_URL=http://localhost:54321 \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

### 3. MCP Server (Claude Desktop / Cursor)
```bash
cd mcp-server
npm install
npm run build
```

Add to `claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "chatmelier": {
      "command": "node",
      "args": ["/path/to/chatmelier/mcp-server/dist/index.js"],
      "env": {
        "SUPABASE_URL": "https://your-project.supabase.co",
        "SUPABASE_SERVICE_ROLE_KEY": "your-service-role-key",
        "CELLAR_ID": "your-default-cellar-uuid"
      }
    }
  }
}
```

---

## 🗄️ Database Migrations

| Migration | Focus |
|---|---|
| [`001_initial_schema.sql`](file:///home/flavien-daussy/.gemini/antigravity/scratch/chatmelier/supabase/migrations/001_initial_schema.sql) | Core tables (`profiles`, `cellars`, `cellar_members`, `wines`, `bottles`, `bottle_photos`, `tasting_log`, `chat_messages`), pgvector extension, HNSW index |
| [`002_rls_policies.sql`](file:///home/flavien-daussy/.gemini/antigravity/scratch/chatmelier/supabase/migrations/002_rls_policies.sql) | Comprehensive Row Level Security (RLS) policies |
| [`003_functions.sql`](file:///home/flavien-daussy/.gemini/antigravity/scratch/chatmelier/supabase/migrations/003_functions.sql) | RPC functions: `search_bottles`, `find_similar_photos`, `get_drink_soon_bottles`, `get_monthly_consumption` |
| [`004_invites.sql`](file:///home/flavien-daussy/.gemini/antigravity/scratch/chatmelier/supabase/migrations/004_invites.sql) | Complete cellar invitation system with `accept_invite`, `decline_invite`, link codes, and role management |
| [`005_advanced_enrichment_and_multi_cellar.sql`](file:///home/flavien-daussy/.gemini/antigravity/scratch/chatmelier/supabase/migrations/005_advanced_enrichment_and_multi_cellar.sql) | Multi-cellar locations/nicknames, `critic_scores`, `cuvee_parcel`, `estimated_market_value`, `valuation_history`, 6-month revaluation RPCs, deduplication cache |

---

## ⚡ Edge Functions (TypeScript / Deno)

- [`scan-label`](file:///home/flavien-daussy/.gemini/antigravity/scratch/chatmelier/supabase/functions/scan-label/index.ts): 2-image front+back OCR, deduplication cache check, zero-hallucination web research, top 5 critic rankings extraction, market price estimation.
- [`generate-embedding`](file:///home/flavien-daravity/scratch/chatmelier/supabase/functions/generate-embedding/index.ts): Image to 768-dim vector embedding.
- [`visual-match`](file:///home/flavien-daussy/.gemini/antigravity/scratch/chatmelier/supabase/functions/visual-match/index.ts): Fast pgvector cosine similarity search.
- [`chat`](file:///home/flavien-daussy/.gemini/antigravity/scratch/chatmelier/supabase/functions/chat/index.ts): AI Sommelier with live cellar context.
- [`update-wine-values`](file:///home/flavien-daussy/.gemini/antigravity/scratch/chatmelier/supabase/functions/update-wine-values/index.ts): Semi-annual market valuation refresh.
- [`drinking-window-alerts`](file:///home/flavien-daussy/.gemini/antigravity/scratch/chatmelier/supabase/functions/drinking-window-alerts/index.ts): Peak drinking window status scanner.
