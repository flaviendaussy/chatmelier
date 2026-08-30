import { supabase, getCellarId } from '../db.js';
export async function getInventoryResource() {
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
    const grouped = {};
    bottles.forEach(b => {
        const type = b.wine.type || 'Other';
        if (!grouped[type])
            grouped[type] = [];
        grouped[type].push(b);
    });
    let output = `# Cellar Inventory\n\n`;
    for (const [type, typeBottles] of Object.entries(grouped)) {
        output += `## ${type}\n`;
        typeBottles.forEach(b => {
            output += `- ${b.wine.vintage || 'NV'} ${b.wine.producer || ''} ${b.wine.name} (${b.quantity} bottles)\n`;
            output += `  ID: ${b.id} | Region: ${b.wine.region}, ${b.wine.country}\n`;
        });
        output += `\n`;
    }
    return output;
}
