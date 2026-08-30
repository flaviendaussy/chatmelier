import { z } from 'zod';
import { supabase, getCellarId } from '../db.js';
export const SuggestPairingInput = z.object({
    dish: z.string(),
    preferences: z.string().optional()
});
export async function suggestPairing(args) {
    if (!supabase)
        throw new Error('Database not configured');
    const cellarId = getCellarId();
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
    if (bottles.length === 0) {
        return "Cellar is empty, no pairings available.";
    }
    // Very basic heuristic for pairing
    const dishLower = args.dish.toLowerCase();
    let preferredType = '';
    if (dishLower.includes('beef') || dishLower.includes('steak') || dishLower.includes('lamb')) {
        preferredType = 'red';
    }
    else if (dishLower.includes('fish') || dishLower.includes('chicken') || dishLower.includes('salad')) {
        preferredType = 'white';
    }
    else if (dishLower.includes('spicy') || dishLower.includes('curry') || dishLower.includes('pork')) {
        preferredType = 'rose'; // or off-dry white
    }
    // Filter based on preferred type if detected, else just return random/all
    let matched = bottles;
    if (preferredType) {
        matched = bottles.filter(b => b.wine.type?.toLowerCase().includes(preferredType));
    }
    if (matched.length === 0) {
        matched = bottles; // fallback to all
    }
    matched = matched.slice(0, 5); // top 5
    let output = `Wine pairing suggestions for "${args.dish}":\n\n`;
    matched.forEach((b, i) => {
        output += `${i + 1}. [${b.id}] ${b.wine.vintage || ''} ${b.wine.name} (${b.wine.type})\n`;
        output += `   Reasoning: Matches well with the profile of the dish.\n`;
    });
    return output;
}
