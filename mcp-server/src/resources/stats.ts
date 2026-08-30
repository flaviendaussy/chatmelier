import { getCellarStats } from '../tools/get-cellar-stats.js';

export async function getStatsResource(): Promise<string> {
  // We can reuse the logic from the tool
  const text = await getCellarStats({});
  return `# Cellar Stats Resource\n\n` + text;
}
