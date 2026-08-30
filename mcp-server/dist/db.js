import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config();
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const defaultCellarId = process.env.CELLAR_ID;
if (!supabaseUrl || !supabaseKey) {
    console.error("Warning: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set in .env");
}
export const supabase = supabaseUrl && supabaseKey
    ? createClient(supabaseUrl, supabaseKey)
    : null;
export function getCellarId() {
    if (!defaultCellarId) {
        throw new Error("CELLAR_ID is not configured in environment variables.");
    }
    return defaultCellarId;
}
