import { z } from 'zod';
import { supabase, getCellarId } from '../db.js';
export const ListDrinkSoonInput = z.object({
    months_ahead: z.number().default(6)
});
export async function listDrinkSoon(args) {
    if (!supabase)
        throw new Error('Database not configured');
    const cellarId = getCellarId();
    // In a real app, you would have a drink_window_end or similar on the wine table
    // Here we'll simulate it by returning a sample of older vintages if no real logic exists
    const { data, error } = await supabase
        .from('bottles')
        .select(`
      *,
      wine:wines(*)
    `)
        .eq('cellar_id', cellarId)
        .eq('status', 'IN_CELLAR');
    if (error)
        throw new Error(`Database error: ${error.message}`);
    const bottles = data;
    const currentYear = new Date().getFullYear();
    // Simplistic logic for "drink soon":
    // White/Rose > 3 years old
    // Red > 7 years old
    // Or whatever custom logic Chatmelier uses.
    const drinkSoon = bottles.filter(b => {
        if (!b.wine.vintage)
            return false;
        const age = currentYear - b.wine.vintage;
        const type = (b.wine.type || '').toLowerCase();
        if (type.includes('white') || type.includes('rose'))
            return age >= 3;
        if (type.includes('red'))
            return age >= 7;
        return false;
    }).slice(0, 20); // limit to top 20
    if (drinkSoon.length === 0) {
        return "No bottles urgently need to be consumed in the requested timeframe.";
    }
    let output = `Bottles to drink soon (suggested within ${args.months_ahead} months):\n\n`;
    drinkSoon.forEach(b => {
        output += `- [${b.id}] ${b.wine.vintage} ${b.wine.name} (${b.wine.type})\n`;
    });
    return output;
}
