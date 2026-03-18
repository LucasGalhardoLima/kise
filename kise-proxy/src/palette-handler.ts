// kise-proxy/src/palette-handler.ts

import Anthropic from "@anthropic-ai/sdk";
import { buildPalettePrompt, getSeason } from "./palette-prompt";
import { buildPaletteTool } from "./palette-tool";
import { fetchCityWeather, CITIES } from "./weather";
import type { DailyPalette, Env } from "./types";

export async function handleScheduled(env: Env): Promise<void> {
  // Pick city from rotation based on day count
  const daysSinceEpoch = Math.floor(Date.now() / 86_400_000);
  const city = CITIES[daysSinceEpoch % CITIES.length];

  // Fetch weather
  const weather = await fetchCityWeather(city, env.OPENWEATHER_API_KEY);

  // Generate palette via Claude
  const palette = await generatePalette(city, weather, env);

  // Cache in KV (24h TTL)
  await env.DAILY_PICK.put("daily-pick", JSON.stringify(palette), {
    expirationTtl: 86400,
  });

  // Email admin via Resend
  await sendPaletteEmail(palette, env);

  console.log(`Daily pick generated: ${palette.paletteName} (${city})`);
}

async function generatePalette(
  city: string,
  weather: { temp: number; condition: string },
  env: Env
): Promise<DailyPalette> {
  const client = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });
  const season = getSeason();
  const systemPrompt = buildPalettePrompt(city, weather, season);
  const tool = buildPaletteTool();

  const response = await client.messages.create({
    model: "claude-sonnet-4-20250514",
    max_tokens: 512,
    system: systemPrompt,
    tools: [tool],
    tool_choice: { type: "tool", name: "generate_palette" },
    messages: [
      {
        role: "user",
        content: `Generate today's palette for ${city}. Weather: ${weather.temp}°C, ${weather.condition}. Season: ${season}.`,
      },
    ],
  });

  const toolBlock = response.content.find(
    (block) => block.type === "tool_use" && block.name === "generate_palette"
  );

  if (!toolBlock || toolBlock.type !== "tool_use") {
    throw new Error("Claude did not return a generate_palette tool call");
  }

  const input = toolBlock.input as Record<string, unknown>;

  return {
    city,
    temperature: weather.temp,
    condition: weather.condition,
    paletteName: input.paletteName as string,
    description: input.description as string,
    colors: input.colors as string[],
  };
}

async function sendPaletteEmail(
  palette: DailyPalette,
  env: Env
): Promise<void> {
  const colorSwatches = palette.colors
    .map(
      (c) =>
        `<div style="display:inline-block;width:48px;height:48px;background:${c};border-radius:8px;margin-right:8px"></div>`
    )
    .join("");

  const html = `
    <div style="font-family:sans-serif;max-width:480px">
      <h2 style="margin-bottom:4px">${palette.paletteName}</h2>
      <p style="color:#666;margin-top:0">${palette.city} · ${palette.temperature}°C · ${palette.condition}</p>
      <div style="margin:16px 0">${colorSwatches}</div>
      <p style="color:#666;font-size:14px">${palette.colors.join("  ")}</p>
      <p>${palette.description}</p>
    </div>
  `;

  await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${env.RESEND_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: "KISE <hello@kise-app.com>",
      to: env.ADMIN_EMAIL,
      subject: `KISE's Pick: ${palette.paletteName}`,
      html,
    }),
  });
}
