# Chatmelier MCP Server

This is an MCP (Model Context Protocol) server for Chatmelier, a wine cellar management application. It exposes tools and resources allowing AI assistants like Claude Desktop to interact with a wine cellar database stored in Supabase (PostgreSQL).

## Setup

1. **Install dependencies:**
   \`\`\`bash
   npm install
   \`\`\`

2. **Configure Environment:**
   Copy \`.env.example\` to \`.env\` and fill in your Supabase credentials and default cellar ID:
   \`\`\`bash
   cp .env.example .env
   \`\`\`
   Edit \`.env\`:
   - \`SUPABASE_URL\`: Your Supabase project URL
   - \`SUPABASE_SERVICE_ROLE_KEY\`: Service role key (required to bypass RLS or interact directly)
   - \`CELLAR_ID\`: The UUID of the cellar you want to manage.

3. **Build the server (optional):**
   \`\`\`bash
   npm run build
   \`\`\`

## Claude Desktop Configuration

To use this server with Claude Desktop, add it to your \`claude_desktop_config.json\`:

\`\`\`json
{
  "mcpServers": {
    "chatmelier": {
      "command": "node",
      "args": ["/absolute/path/to/chatmelier/mcp-server/dist/index.js"]
    }
  }
}
\`\`\`
*(Make sure to adjust the path to point to your compiled \`dist/index.js\` and ensure you have run \`npm run build\`)*

Alternatively, you can run it via \`tsx\` in dev mode:
\`\`\`json
{
  "mcpServers": {
    "chatmelier": {
      "command": "npx",
      "args": ["tsx", "/absolute/path/to/chatmelier/mcp-server/src/index.ts"],
      "env": {
        "SUPABASE_URL": "...",
        "SUPABASE_SERVICE_ROLE_KEY": "...",
        "CELLAR_ID": "..."
      }
    }
  }
}
\`\`\`

## Available Tools

- **search_bottles**: Searches cellar bottles with optional filters (query, wine_type, country, region, limit).
- **get_bottle_details**: Returns full bottle details with wine info, and tasting history. Requires \`bottle_id\`.
- **list_drink_soon**: Returns bottles that should be consumed soon based on vintage and type.
- **suggest_pairing**: Suggests wine pairings from the cellar for a given dish. Uses basic heuristics based on dish components. Requires \`dish\`.
- **consume_bottle**: Marks a bottle as consumed and logs a tasting entry (optional rating, occasion, food, notes).
- **get_cellar_stats**: Returns cellar statistics, total bottles, total value, and breakdown by type/country/region.
- **add_bottle**: Adds a new bottle to the cellar. If the wine doesn't exist, it creates it.

## Available Resources

- **cellar://inventory**: Full list of bottles in the cellar grouped by type.
- **cellar://stats**: Summary statistics of the cellar and drinking windows.
- **cellar://recent-activity**: Recent additions and consumptions from the last 30 days.

## Development

Run the server in development mode:
\`\`\`bash
npm run dev
\`\`\`

Build the server:
\`\`\`bash
npm run build
\`\`\`
