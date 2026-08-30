import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { CallToolRequestSchema, ListResourcesRequestSchema, ListToolsRequestSchema, ReadResourceRequestSchema, } from '@modelcontextprotocol/sdk/types.js';
import { searchBottles, SearchBottlesInput } from './tools/search-bottles.js';
import { getBottleDetails, GetBottleDetailsInput } from './tools/get-bottle-details.js';
import { listDrinkSoon, ListDrinkSoonInput } from './tools/list-drink-soon.js';
import { suggestPairing, SuggestPairingInput } from './tools/suggest-pairing.js';
import { consumeBottle, ConsumeBottleInput } from './tools/consume-bottle.js';
import { getCellarStats, GetCellarStatsInput } from './tools/get-cellar-stats.js';
import { addBottle, AddBottleInput } from './tools/add-bottle.js';
import { getInventoryResource } from './resources/inventory.js';
import { getStatsResource } from './resources/stats.js';
import { getRecentActivityResource } from './resources/recent-activity.js';
const server = new Server({
    name: 'chatmelier',
    version: '1.0.0',
}, {
    capabilities: {
        tools: {},
        resources: {},
    },
});
// Tools Setup
const TOOLS = [
    {
        name: 'search_bottles',
        description: 'Searches cellar bottles with optional filters',
        inputSchema: {
            type: 'object',
            properties: {
                query: { type: 'string' },
                wine_type: { type: 'string' },
                country: { type: 'string' },
                region: { type: 'string' },
                owner_id: { type: 'string' },
                status: { type: 'string', default: 'IN_CELLAR' },
                limit: { type: 'number', default: 50 }
            }
        }
    },
    {
        name: 'get_bottle_details',
        description: 'Returns full bottle details with wine info and tasting history',
        inputSchema: {
            type: 'object',
            properties: {
                bottle_id: { type: 'string' }
            },
            required: ['bottle_id']
        }
    },
    {
        name: 'list_drink_soon',
        description: 'Returns bottles that should be consumed soon',
        inputSchema: {
            type: 'object',
            properties: {
                months_ahead: { type: 'number', default: 6 }
            }
        }
    },
    {
        name: 'suggest_pairing',
        description: 'Suggests wine pairings from the cellar for a given dish',
        inputSchema: {
            type: 'object',
            properties: {
                dish: { type: 'string' },
                preferences: { type: 'string' }
            },
            required: ['dish']
        }
    },
    {
        name: 'consume_bottle',
        description: 'Marks a bottle as consumed and logs a tasting entry',
        inputSchema: {
            type: 'object',
            properties: {
                bottle_id: { type: 'string' },
                rating: { type: 'number' },
                occasion: { type: 'string' },
                food_paired: { type: 'string' },
                notes: { type: 'string' }
            },
            required: ['bottle_id']
        }
    },
    {
        name: 'get_cellar_stats',
        description: 'Returns cellar statistics',
        inputSchema: {
            type: 'object',
            properties: {}
        }
    },
    {
        name: 'add_bottle',
        description: "Adds a new bottle to the cellar (creates wine if it doesn't exist)",
        inputSchema: {
            type: 'object',
            properties: {
                wine_name: { type: 'string' },
                vintage: { type: 'number' },
                wine_type: { type: 'string' },
                producer: { type: 'string' },
                country: { type: 'string' },
                region: { type: 'string' },
                quantity: { type: 'number', default: 1 },
                purchase_price: { type: 'number' },
                notes: { type: 'string' }
            },
            required: ['wine_name']
        }
    }
];
server.setRequestHandler(ListToolsRequestSchema, async () => {
    return {
        tools: TOOLS,
    };
});
server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args } = request.params;
    try {
        let result = '';
        switch (name) {
            case 'search_bottles':
                result = await searchBottles(SearchBottlesInput.parse(args || {}));
                break;
            case 'get_bottle_details':
                result = await getBottleDetails(GetBottleDetailsInput.parse(args));
                break;
            case 'list_drink_soon':
                result = await listDrinkSoon(ListDrinkSoonInput.parse(args || {}));
                break;
            case 'suggest_pairing':
                result = await suggestPairing(SuggestPairingInput.parse(args));
                break;
            case 'consume_bottle':
                result = await consumeBottle(ConsumeBottleInput.parse(args));
                break;
            case 'get_cellar_stats':
                result = await getCellarStats(GetCellarStatsInput.parse(args || {}));
                break;
            case 'add_bottle':
                result = await addBottle(AddBottleInput.parse(args));
                break;
            default:
                throw new Error(`Unknown tool: ${name}`);
        }
        return {
            content: [{ type: 'text', text: result }],
        };
    }
    catch (error) {
        return {
            content: [{ type: 'text', text: `Error: ${error.message}` }],
            isError: true,
        };
    }
});
// Resources Setup
const RESOURCES = [
    {
        uri: 'cellar://inventory',
        name: 'Cellar Inventory',
        description: 'Full list of bottles in the cellar grouped by type'
    },
    {
        uri: 'cellar://stats',
        name: 'Cellar Statistics',
        description: 'Summary statistics of the cellar and drinking windows'
    },
    {
        uri: 'cellar://recent-activity',
        name: 'Recent Activity',
        description: 'Recent additions and consumptions (last 30 days)'
    }
];
server.setRequestHandler(ListResourcesRequestSchema, async () => {
    return {
        resources: RESOURCES,
    };
});
server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
    const uri = request.params.uri;
    let text = '';
    try {
        switch (uri) {
            case 'cellar://inventory':
                text = await getInventoryResource();
                break;
            case 'cellar://stats':
                text = await getStatsResource();
                break;
            case 'cellar://recent-activity':
                text = await getRecentActivityResource();
                break;
            default:
                throw new Error(`Unknown resource: ${uri}`);
        }
        return {
            contents: [{ uri, mimeType: 'text/markdown', text }],
        };
    }
    catch (error) {
        throw new Error(`Failed to read resource ${uri}: ${error.message}`);
    }
});
// Start the server
async function main() {
    const transport = new StdioServerTransport();
    await server.connect(transport);
    console.error('Chatmelier MCP Server running on stdio');
}
main().catch((error) => {
    console.error('Fatal error in main():', error);
    process.exit(1);
});
