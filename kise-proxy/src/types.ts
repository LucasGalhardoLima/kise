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
  language?: string;
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

export interface DailyPalette {
  type: "palette";
  city: string;
  temperature: number;
  condition: string;
  poeticNameLocal: string;
  poeticNameEnglish: string;
  description: string;
  colors: string[];
}

export interface DailyWabiColor {
  type: "wabi-color";
  kanji: string;
  romanization: string;
  meaning: string;
  hex: string;
  poeticDescription: string;
  howToWear: string;
}

export interface DailyReflection {
  type: "reflection";
  text: string;
}

export type DailyContent = DailyPalette | DailyWabiColor | DailyReflection;

export interface Env {
  ANTHROPIC_API_KEY: string;
  OPENWEATHER_API_KEY: string;
  RESEND_API_KEY: string;
  ADMIN_EMAIL: string;
  ADMIN_TRIGGER_KEY: string;
  DAILY_PICK: KVNamespace;
}
