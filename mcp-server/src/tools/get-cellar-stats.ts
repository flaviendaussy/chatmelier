import { z } from 'zod';
import { supabase, getCellarId } from '../db.js';
import { BottleWithWine, CellarStats } from '../types.js';

export const GetCellarStatsInput = z.object({});

export async function getCellarStats(args: z.infer<typeof GetCellarStatsInput>) {
  if (!supabase) throw new Error('Database not configured');
  const cellarId = getCellarId();

  const { data, error } = await supabase
    .from('bottles')
    .select(`
      *,
      wine:wines(*)
    `)
    .eq('cellar_id', cellarId);

  if (error) throw new Error(`Database error: ${error.message}`);
  const bottles = data as unknown as BottleWithWine[];

  const stats: CellarStats = {
    total_bottles: 0,
    total_consumed: 0,
    total_value: 0,
    total_paid_value: 0,
    total_estimated_market_value: 0,
    by_type: {},
    by_country: {},
    by_region: {},
    drink_soon_count: 0,
    past_peak_count: 0
  };

  const currentYear = new Date().getFullYear();

  bottles.forEach(b => {
    if (b.status === 'consumed') {
      stats.total_consumed += b.quantity;
      return;
    }

    if (b.status !== 'in_cellar') return;

    stats.total_bottles += b.quantity;

    if (b.purchase_price) {
      stats.total_paid_value = (stats.total_paid_value || 0) + (b.purchase_price * b.quantity);
      stats.total_value += b.purchase_price * b.quantity;
    }

    if (b.wine.estimated_market_value) {
      stats.total_estimated_market_value = (stats.total_estimated_market_value || 0) + (b.wine.estimated_market_value * b.quantity);
    }

    const type = b.wine.wine_type || b.wine.type || 'Unknown';
    stats.by_type[type] = (stats.by_type[type] || 0) + b.quantity;

    const country = b.wine.country || 'Unknown';
    stats.by_country[country] = (stats.by_country[country] || 0) + b.quantity;

    const region = b.wine.region || 'Unknown';
    stats.by_region[region] = (stats.by_region[region] || 0) + b.quantity;

    if (b.wine.ideal_drinking_end && currentYear >= b.wine.ideal_drinking_end - 1 && currentYear <= b.wine.ideal_drinking_end) {
      stats.drink_soon_count += b.quantity;
    } else if (b.wine.peak_drinking_end && currentYear > b.wine.peak_drinking_end) {
      stats.past_peak_count = (stats.past_peak_count || 0) + b.quantity;
    }
  });

  let output = `📊 Cellar Statistics\n`;
  output += `=================\n`;
  output += `Active Bottles in Cellar: ${stats.total_bottles}\n`;
  output += `Consumed Bottles (Journal): ${stats.total_consumed}\n`;
  output += `Total Price Paid: ${stats.total_paid_value?.toFixed(2) || '0.00'} €\n`;
  output += `Total Estimated Market Value: ${stats.total_estimated_market_value?.toFixed(2) || '0.00'} €\n`;
  output += `Bottles in 'Drink Soon' Window: ${stats.drink_soon_count}\n`;
  if (stats.past_peak_count) output += `Bottles Past Peak: ${stats.past_peak_count} ⚠️\n`;
  output += `\n`;

  output += `By Wine Type:\n`;
  for (const [k, v] of Object.entries(stats.by_type)) {
    output += `  - ${k}: ${v} bottle${v > 1 ? 's' : ''}\n`;
  }
  
  output += `\nBy Country:\n`;
  for (const [k, v] of Object.entries(stats.by_country)) {
    output += `  - ${k}: ${v}\n`;
  }

  output += `\nBy Region:\n`;
  for (const [k, v] of Object.entries(stats.by_region)) {
    output += `  - ${k}: ${v}\n`;
  }

  return output;
}
