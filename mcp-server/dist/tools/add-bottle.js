import { z } from 'zod';
import { supabase, getCellarId } from '../db.js';
export const AddBottleInput = z.object({
    wine_name: z.string(),
    vintage: z.number().optional(),
    wine_type: z.string().optional(),
    producer: z.string().optional(),
    country: z.string().optional(),
    region: z.string().optional(),
    quantity: z.number().min(1).default(1),
    purchase_price: z.number().optional(),
    notes: z.string().optional()
});
export async function addBottle(args) {
    if (!supabase)
        throw new Error('Database not configured');
    const cellarId = getCellarId();
    // First check if wine exists
    let wineId = '';
    const { data: existingWines, error: searchError } = await supabase
        .from('wines')
        .select('id')
        .ilike('name', args.wine_name)
        .eq('vintage', args.vintage || null);
    if (searchError)
        throw new Error(`Search error: ${searchError.message}`);
    if (existingWines && existingWines.length > 0) {
        wineId = existingWines[0].id;
    }
    else {
        // Create new wine
        const { data: newWine, error: createError } = await supabase
            .from('wines')
            .insert({
            name: args.wine_name,
            vintage: args.vintage || null,
            type: args.wine_type || null,
            producer: args.producer || null,
            country: args.country || null,
            region: args.region || null
        })
            .select('id')
            .single();
        if (createError)
            throw new Error(`Failed to create wine: ${createError.message}`);
        wineId = newWine.id;
    }
    // Add bottle(s)
    const { data: bottleData, error: bottleError } = await supabase
        .from('bottles')
        .insert({
        wine_id: wineId,
        cellar_id: cellarId,
        quantity: args.quantity,
        purchase_price: args.purchase_price || null,
        status: 'IN_CELLAR',
        notes: args.notes || null
    })
        .select()
        .single();
    if (bottleError)
        throw new Error(`Failed to add bottle: ${bottleError.message}`);
    return `Successfully added bottle(s). ID: ${bottleData.id}`;
}
