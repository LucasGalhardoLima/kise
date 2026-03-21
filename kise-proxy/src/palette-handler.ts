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
        `<div style="display:inline-block;width:80px;height:80px;background:${c};margin:0 4px"></div>`
    )
    .join("");

  const hexCodes = palette.colors.join("    ");

  const html = `
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#F5F3EF;font-family:'DM Sans',Helvetica,Arial,sans-serif">
  <tr><td align="center" style="padding:60px 20px">
    <table role="presentation" width="480" cellpadding="0" cellspacing="0" style="max-width:480px;width:100%">
      <tr><td align="center" style="padding-bottom:12px">
        <span style="font-family:'Cormorant Garamond',Georgia,serif;font-weight:300;font-size:14px;color:#9B9B9B;letter-spacing:0.15em;text-transform:uppercase">KISE'S PICK</span>
      </td></tr>
      <tr><td align="center" style="padding-bottom:8px">
        <span style="font-family:'Cormorant Garamond',Georgia,serif;font-weight:300;font-size:28px;color:#344E41">${palette.paletteName}</span>
      </td></tr>
      <tr><td align="center" style="padding-bottom:32px">
        <span style="font-size:13px;color:#6B6B6B">${palette.city} · ${palette.temperature}°C · ${palette.condition}</span>
      </td></tr>
      <tr><td align="center" style="padding-bottom:12px">${colorSwatches}</td></tr>
      <tr><td align="center" style="padding-bottom:32px">
        <span style="font-size:11px;color:#9B9B9B;letter-spacing:0.08em">${hexCodes}</span>
      </td></tr>
      <tr><td style="padding-bottom:32px">
        <p style="margin:0;font-size:14px;line-height:1.7;color:#6B6B6B;text-align:center">${palette.description}</p>
      </td></tr>
      <tr><td align="center" style="padding:16px 0 32px">
        <div style="width:60px;height:1px;background-color:#A3B18A;opacity:0.4"></div>
      </td></tr>
      <tr><td align="center">
        <span style="font-family:'Cormorant Garamond',Georgia,serif;font-weight:300;font-size:18px;color:#344E41">KISE 着せ</span>
        <p style="margin:8px 0 0;font-family:'Cormorant Garamond',Georgia,serif;font-weight:300;font-size:14px;color:#9B9B9B;font-style:italic">Vista com intenção.</p>
      </td></tr>
    </table>
  </td></tr>
</table>`;

  await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${env.RESEND_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: "KISE <hello@contact.kise-app.com>",
      to: env.ADMIN_EMAIL,
      subject: `KISE's Pick: ${palette.paletteName}`,
      html,
    }),
  });
}
