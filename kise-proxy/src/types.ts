// kise-proxy/src/types.ts

export interface HourlyForecast {
  hour: number;
  temp: number;
  condition: string;
}

export interface WeatherPayload {
  temperature: number;
  feels_like: number;
  humidity: number;
  wind: number;
  condition: string;
  hourly_forecast: HourlyForecast[];
}

export interface WardrobePiece {
  id: string;
  category: string;
  color: string;
  fit: string;
  material: string;
  weight: string;
  formality: string;
}

export interface RecentSuggestion {
  date: string;
  piece_ids: string[];
  feedback: string;
}

export interface SuggestionRequest {
  style_archetypes: string[];
  boldness: number;
  occasion: string;
  weather?: WeatherPayload;
  wardrobe: WardrobePiece[];
  recent_suggestions: RecentSuggestion[];
}

export interface AlternativePiece {
  swap: string;
  for: string;
  why: string;
}

export interface SuggestionResponse {
  pieces: string[];
  reasoning: string;
  layering_note?: string;
  alternative_piece?: AlternativePiece;
}

export interface Env {
  ANTHROPIC_API_KEY: string;
}
