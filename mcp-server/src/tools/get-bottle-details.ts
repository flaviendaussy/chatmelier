import { z } from 'zod';
import { supabase } from '../db.js';
import { BottleWithWine, TastingEntry } from '../types.js';

export const GetBottleDetailsInput = z.object({
  bottle_id: z.string().uuid()
});

export async function getBottleDetails(args: z.infer<typeof GetBottleDetailsInput>) {
  if (!supabase) throw new Error('Database not configured');

  const { data: bottleData, error: bottleError } = await supabase
    .from('bottles')
    .select(`
      *,
      wine:wines(*)
    `)
    .eq('id', args.bottle_id)
    .single();

  if (bottleError) throw new Error(`Bottle not found: ${bottleError.message}`);
  const bottle = bottleData as unknown as BottleWithWine;

  const { data: tastingData, error: tastingError } = await supabase
    .from('tasting_log')
    .select('*')
    .eq('bottle_id', args.bottle_id)
    .order('consumed_at', { ascending: false });

  const tastings = (tastingData || []) as TastingEntry[];

  let output = `🍷 Bottle Details: ${bottle.wine.name}\n`;
  output += `=========================================\n`;
  output += `ID: ${bottle.id}\n`;
  output += `Producer: ${bottle.wine.producer || 'N/A'}\n`;
  if (bottle.wine.cuvee_parcel) output += `Cuvée / Parcel: ${bottle.wine.cuvee_parcel}\n`;
  output += `Vintage: ${bottle.wine.vintage || 'Non-Vintage'}\n`;
  output += `Type: ${bottle.wine.wine_type || bottle.wine.type || 'N/A'}\n`;
  output += `Region: ${bottle.wine.region || 'N/A'}, ${bottle.wine.country || 'N/A'}\n`;
  if (bottle.wine.appellation) output += `Appellation: ${bottle.wine.appellation}\n`;
  output += `Status: ${bottle.status}\n`;
  output += `Quantity: ${bottle.quantity}\n`;
  output += `Purchase Price Paid: ${bottle.purchase_price ? bottle.purchase_price + ' €' : 'Not specified'}\n`;
  output += `Estimated Market Value: ${bottle.wine.estimated_market_value ? bottle.wine.estimated_market_value + ' €' : 'N/A'}\n`;
  output += `Location: Rack ${bottle.rack || '-'} | Shelf ${bottle.shelf || '-'} | Pos ${bottle.position || '-'}\n`;
  output += `Notes: ${bottle.notes || 'None'}\n\n`;

  if (bottle.wine.critic_scores && bottle.wine.critic_scores.length > 0) {
    output += `⭐ Critic Rankings:\n`;
    output += `----------------\n`;
    bottle.wine.critic_scores.forEach(s => {
      output += `- ${s.source}: ${s.score}${s.reviewer ? ` (${s.reviewer})` : ''}\n`;
    });
    output += `\n`;
  }

  if (tastings.length > 0) {
    output += `Tasting History:\n`;
    output += `----------------\n`;
    tastings.forEach(t => {
      output += `Date: ${t.consumed_at || t.tasting_date || 'N/A'}\n`;
      if (t.rating) output += `Rating: ${t.rating}/5 ⭐\n`;
      if (t.occasion) output += `Occasion: ${t.occasion}\n`;
      if (t.food_paired) output += `Paired with: ${t.food_paired}\n`;
      if (t.tasting_notes || t.notes) output += `Notes: ${t.tasting_notes || t.notes}\n`;
      output += `---\n`;
    });
  } else {
    output += `Tasting History: No tastings recorded yet.\n`;
  }

  return output;
}
