export interface CriticScore {
  source: string;
  score: string;
  reviewer?: string | null;
  year?: number | null;
  notes?: string | null;
}

export interface Grape {
  name: string;
  pct?: number | null;
}

export interface Wine {
  id: string;
  name: string;
  vintage: number | null;
  type?: string | null;
  wine_type?: string | null;
  producer: string | null;
  cuvee_parcel?: string | null;
  country: string | null;
  region: string | null;
  sub_region?: string | null;
  appellation?: string | null;
  classification?: string | null;
  alcohol_pct?: number | null;
  grapes?: Grape[];
  tasting_notes?: string | null;
  ideal_drinking_start?: number | null;
  ideal_drinking_end?: number | null;
  peak_drinking_start?: number | null;
  peak_drinking_end?: number | null;
  critic_scores?: CriticScore[];
  estimated_market_value?: number | null;
  estimated_value_currency?: string;
  last_valuation_date?: string | null;
  sources_verified?: string[];
  created_at: string;
}

export interface Bottle {
  id: string;
  wine_id: string;
  cellar_id: string;
  owner_id?: string;
  quantity: number;
  purchase_price: number | null;
  purchase_date?: string | null;
  purchase_location?: string | null;
  status: string;
  notes: string | null;
  rack?: string | null;
  shelf?: string | null;
  position?: string | null;
  created_at: string;
  consumed_at?: string | null;
}

export interface BottleWithWine extends Bottle {
  wine: Wine;
}

export interface TastingEntry {
  id: string;
  bottle_id: string;
  rating: number | null;
  occasion: string | null;
  food_paired: string | null;
  tasting_notes?: string | null;
  notes?: string | null;
  tasting_date?: string;
  consumed_at?: string;
}

export interface CellarStats {
  total_bottles: number;
  total_consumed: number;
  total_value: number;
  total_paid_value?: number;
  total_estimated_market_value?: number;
  by_type: Record<string, number>;
  by_country: Record<string, number>;
  by_region: Record<string, number>;
  drink_soon_count: number;
  past_peak_count?: number;
}
