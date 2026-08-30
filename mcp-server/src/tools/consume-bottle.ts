import { z } from 'zod';
import { supabase } from '../db.js';

export const ConsumeBottleInput = z.object({
  bottle_id: z.string().uuid(),
  rating: z.number().min(1).max(10).optional(),
  occasion: z.string().optional(),
  food_paired: z.string().optional(),
  notes: z.string().optional()
});

export async function consumeBottle(args: z.infer<typeof ConsumeBottleInput>) {
  if (!supabase) throw new Error('Database not configured');

  // Update bottle status
  const { error: updateError } = await supabase
    .from('bottles')
    .update({ status: 'CONSUMED', consumed_at: new Date().toISOString() })
    .eq('id', args.bottle_id)
    .eq('status', 'IN_CELLAR');

  if (updateError) {
    throw new Error(`Failed to update bottle status: ${updateError.message}`);
  }

  // Create tasting entry
  const { error: insertError } = await supabase
    .from('tasting_entries')
    .insert({
      bottle_id: args.bottle_id,
      rating: args.rating || null,
      occasion: args.occasion || null,
      food_paired: args.food_paired || null,
      notes: args.notes || null,
      tasting_date: new Date().toISOString()
    });

  if (insertError) {
    throw new Error(`Bottle marked consumed, but failed to log tasting: ${insertError.message}`);
  }

  return `Successfully marked bottle ${args.bottle_id} as consumed and logged the tasting.`;
}
