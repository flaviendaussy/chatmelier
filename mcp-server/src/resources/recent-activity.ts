import { supabase, getCellarId } from '../db.js';

export async function getRecentActivityResource(): Promise<string> {
  if (!supabase) throw new Error('Database not configured');
  const cellarId = getCellarId();

  // Last 30 days
  const dateLimit = new Date();
  dateLimit.setDate(dateLimit.getDate() - 30);
  const isoLimit = dateLimit.toISOString();

  // Recent additions
  const { data: added, error: addedError } = await supabase
    .from('bottles')
    .select(`*, wine:wines(*)`)
    .eq('cellar_id', cellarId)
    .gte('created_at', isoLimit)
    .order('created_at', { ascending: false });

  if (addedError) throw new Error(`Error fetching additions: ${addedError.message}`);

  // Recent consumptions
  const { data: consumed, error: consumedError } = await supabase
    .from('bottles')
    .select(`*, wine:wines(*)`)
    .eq('cellar_id', cellarId)
    .eq('status', 'CONSUMED')
    .gte('consumed_at', isoLimit)
    .order('consumed_at', { ascending: false });

  if (consumedError) throw new Error(`Error fetching consumptions: ${consumedError.message}`);

  let output = `# Recent Activity (Last 30 Days)\n\n`;

  output += `## Added to Cellar\n`;
  if (added && added.length > 0) {
    added.forEach((b: any) => {
      output += `- ${b.created_at.split('T')[0]}: Added ${b.quantity}x ${b.wine.vintage || ''} ${b.wine.name}\n`;
    });
  } else {
    output += `No recent additions.\n`;
  }

  output += `\n## Consumed\n`;
  if (consumed && consumed.length > 0) {
    consumed.forEach((b: any) => {
      output += `- ${b.consumed_at.split('T')[0]}: Consumed ${b.wine.vintage || ''} ${b.wine.name}\n`;
    });
  } else {
    output += `No recent consumptions.\n`;
  }

  return output;
}
