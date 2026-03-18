// kise-proxy/src/weather.ts

interface CityWeather {
  temp: number;
  condition: string;
}

const CITY_COORDS: Record<string, { lat: number; lon: number }> = {
  Tokyo: { lat: 35.6762, lon: 139.6503 },
  Copenhagen: { lat: 55.6761, lon: 12.5683 },
  "Mexico City": { lat: 19.4326, lon: -99.1332 },
  "São Paulo": { lat: -23.5505, lon: -46.6333 },
  Marrakech: { lat: 31.6295, lon: -7.9811 },
  Seoul: { lat: 37.5665, lon: 126.978 },
  Lisboa: { lat: 38.7223, lon: -9.1393 },
};

export const CITIES = Object.keys(CITY_COORDS);

export async function fetchCityWeather(
  city: string,
  apiKey: string
): Promise<CityWeather> {
  const coords = CITY_COORDS[city];
  if (!coords) throw new Error(`Unknown city: ${city}`);

  const url = `https://api.openweathermap.org/data/2.5/weather?lat=${coords.lat}&lon=${coords.lon}&units=metric&appid=${apiKey}`;

  const res = await fetch(url);
  if (!res.ok) throw new Error(`OpenWeatherMap error: ${res.status}`);

  const data = (await res.json()) as {
    main: { temp: number };
    weather: { description: string }[];
  };

  return {
    temp: Math.round(data.main.temp),
    condition: data.weather[0]?.description ?? "unknown",
  };
}
