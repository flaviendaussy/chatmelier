import { z } from 'zod';
import { supabase, getCellarId } from '../db.js';
export const SearchBottlesInput = z.object({
    query: z.string().optional(),
    wine_type: z.string().optional(),
    country: z.string().optional(),
    region: z.string().optional(),
    status: z.string().default('IN_CELLAR'),
    limit: z.number().max(100).default(50)
});
export async function searchBottles(args) {
    if (!supabase)
        throw new Error('Database not configured');
    const cellarId = getCellarId();
    let queryBuilder = supabase
        .from('bottles')
        .select(`
      *,
      wine:wines(*)
    `)
        .eq('cellar_id', cellarId)
        .eq('status', args.status)
        .limit(args.limit);
    if (args.wine_type) {
        queryBuilder = queryBuilder.eq('wine.type', args.wine_type);
    }
    if (args.country) {
        queryBuilder = queryBuilder.eq('wine.country', args.country);
    }
    if (args.region) {
        queryBuilder = queryBuilder.eq('wine.region', args.region);
    }
    const { data, error } = await queryBuilder;
    if (error)
        throw new Error(`Database error: ${error.message}`);
    let results = data;
    // Note: Supabase inner join filtering can sometimes return null for the relation if it doesn't match,
    // so we filter out items where wine is null
    results = results.filter(b => b.wine !== null);
    if (args.query) {
        const q = args.query.toLowerCase();
        results = results.filter(b => b.wine.name.toLowerCase().includes(q) ||
            (b.wine.producer && b.wine.producer.toLowerCase().includes(q)));
    }
    if (results.length === 0) {
        return "No bottles found matching the criteria.";
    }
    return results.map(b => `- [${b.id}] ${b.wine.vintage || 'NV'} ${b.wine.producer || ''} ${b.wine.name} (${b.wine.type || 'Unknown'} - ${b.wine.region || 'Unknown'}, ${b.wine.country || 'Unknown'}) | Qty: ${b.quantity}`).join('\n');
}
