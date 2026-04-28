// kise-proxy/src/palette-handler.ts

import Anthropic from "@anthropic-ai/sdk";
import { buildPalettePrompt, getSeason } from "./palette-prompt";
import { buildPaletteTool } from "./palette-tool";
import { fetchCityWeather, CITIES } from "./weather";
import { getWabiColorForToday, getReflectionForToday } from "./content-banks";
import type {
  DailyPalette,
  DailyWabiColor,
  DailyReflection,
  DailyContent,
  Env,
} from "./types";

// ---------------------------------------------------------------------------
// Scheduler entry point
// ---------------------------------------------------------------------------

export async function handleScheduled(env: Env): Promise<void> {
  const day = new Date().getUTCDay(); // 0=Sun … 6=Sat

  if (day === 0) return; // Sunday — rest

  if (day === 1 || day === 3 || day === 5) {
    await handlePaletteDay(env);
  } else if (day === 2 || day === 6) {
    await handleWabiDay(env);
  } else if (day === 4) {
    await handleReflectionDay(env);
  }
}

// ---------------------------------------------------------------------------
// Palette — Mon / Wed / Fri
// ---------------------------------------------------------------------------

export async function handlePaletteDay(env: Env): Promise<void> {
  const daysSinceEpoch = Math.floor(Date.now() / 86_400_000);
  const city = CITIES[daysSinceEpoch % CITIES.length];
  const weather = await fetchCityWeather(city, env.OPENWEATHER_API_KEY);
  const palette = await generatePalette(city, weather, env);

  // Landing page cache (4-day TTL covers Fri→Mon gap)
  await env.DAILY_PICK.put("daily-pick", JSON.stringify(palette), {
    expirationTtl: 345600,
  });

  // Threads content cache (24h)
  await env.DAILY_PICK.put("daily-content", JSON.stringify(palette), {
    expirationTtl: 86400,
  });

  await sendPaletteEmail(palette, env);
  console.log(`Palette: ${palette.poeticNameLocal} (${city})`);
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
    type: "palette",
    city,
    temperature: weather.temp,
    condition: weather.condition,
    poeticNameLocal: input.poeticNameLocal as string,
    poeticNameEnglish: input.poeticNameEnglish as string,
    description: input.description as string,
    colors: input.colors as string[],
  };
}

// ---------------------------------------------------------------------------
// 和色 — Tue / Sat
// ---------------------------------------------------------------------------

export async function handleWabiDay(env: Env): Promise<void> {
  const day = new Date().getUTCDay();
  const color = getWabiColorForToday(day);

  await env.DAILY_PICK.put("daily-content", JSON.stringify(color), {
    expirationTtl: 86400,
  });

  await sendWabiEmail(color, env);
  console.log(`和色: ${color.kanji} (${color.romanization})`);
}

// ---------------------------------------------------------------------------
// Reflection — Thu
// ---------------------------------------------------------------------------

export async function handleReflectionDay(env: Env): Promise<void> {
  const reflection = getReflectionForToday();

  await env.DAILY_PICK.put("daily-content", JSON.stringify(reflection), {
    expirationTtl: 86400,
  });

  await sendReflectionEmail(reflection, env);
  console.log(`Reflection: ${reflection.text.slice(0, 50)}…`);
}

// ---------------------------------------------------------------------------
// Captions
// ---------------------------------------------------------------------------

function buildPaletteCaption(p: DailyPalette): string {
  return `${p.poeticNameLocal} — ${p.poeticNameEnglish}.

${p.city}, ${p.temperature}°C, ${p.condition}.
${p.description}

${p.colors.join(" · ")}`;
}

function buildWabiCaption(c: DailyWabiColor): string {
  return `${c.kanji} (${c.romanization}) — ${c.meaning}.

${c.poeticDescription}

${c.hex}. ${c.howToWear}`;
}

function buildReflectionCaption(r: DailyReflection): string {
  return r.text;
}

// ---------------------------------------------------------------------------
// Emails
// ---------------------------------------------------------------------------

async function sendEmail(
  subject: string,
  html: string,
  env: Env
): Promise<void> {
  await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${env.RESEND_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: "KISE <hello@contact.kise-app.com>",
      to: env.ADMIN_EMAIL,
      subject,
      html,
    }),
  });
}

function escapeHtml(text: string): string {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function emailWrapper(inner: string, preheader: string): string {
  const safePreheader = escapeHtml(preheader);
  return `
<div style="display:none;visibility:hidden;opacity:0;color:transparent;height:0;width:0;overflow:hidden;mso-hide:all;max-height:0;max-width:0;font-size:1px;line-height:1px">
  ${safePreheader}&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;
</div>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#F5F3EF;font-family:'DM Sans',Helvetica,Arial,sans-serif">
  <tr><td align="center" style="padding:60px 20px">
    <table role="presentation" width="480" cellpadding="0" cellspacing="0" style="max-width:480px;width:100%">
      ${inner}
      <tr><td align="center" style="padding:16px 0 24px">
        <div style="width:60px;height:1px;background-color:#A3B18A;opacity:0.4"></div>
      </td></tr>
      <tr><td align="center">
        <span style="font-family:'Cormorant Garamond',Georgia,serif;font-weight:300;font-size:18px;color:#344E41">KISE 着せ</span>
        <p style="margin:8px 0 0;font-family:'Cormorant Garamond',Georgia,serif;font-weight:300;font-size:14px;color:#9B9B9B;font-style:italic">Vista com intenção.</p>
      </td></tr>
    </table>
  </td></tr>
</table>`;
}

function captionBlock(caption: string, label: string): string {
  return `
      <tr><td style="padding:0 0 32px">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#EEEDEA;border-radius:8px">
          <tr><td style="padding:20px 24px">
            <p style="margin:0 0 8px;font-size:10px;color:#A3B18A;letter-spacing:0.15em;text-transform:uppercase">${label}</p>
            <p style="margin:0;font-size:13px;line-height:1.7;color:#344E41;white-space:pre-line">${caption}</p>
          </td></tr>
        </table>
      </td></tr>`;
}

function buildPaletteSubject(p: DailyPalette): string {
  const variants = [
    `KISE Palette: ${p.poeticNameLocal}`,
    `Threads palette draft: ${p.city} · ${p.poeticNameLocal}`,
    `${p.poeticNameLocal} — ready for Threads`,
    `Today's KISE palette for ${p.city}`,
  ];
  const daysSinceEpoch = Math.floor(Date.now() / 86_400_000);
  const seed = `${p.city}|${p.poeticNameLocal}|${daysSinceEpoch}`;
  const hash = [...seed].reduce((acc, char) => acc + char.charCodeAt(0), 0);
  return variants[hash % variants.length];
}

async function sendPaletteEmail(p: DailyPalette, env: Env): Promise<void> {
  const caption = buildPaletteCaption(p);
  const hexLine = p.colors.join(" · ");
  const preheader = `Palette for ${p.city}: ${p.poeticNameEnglish}. ${hexLine}.`;
  const swatches = p.colors
    .map(
      (c) =>
        `<div style="display:inline-block;width:64px;height:64px;background:${c};margin:0 2px"></div>`
    )
    .join("");

  const inner = `
      <tr><td align="center" style="padding-bottom:6px">
        <span style="font-size:10px;color:#A3B18A;letter-spacing:0.15em;text-transform:uppercase">DAILY PALETTE</span>
      </td></tr>
      <tr><td align="center" style="padding-bottom:6px">
        <span style="font-family:'Cormorant Garamond',Georgia,serif;font-weight:300;font-size:28px;color:#344E41">${p.poeticNameLocal}</span>
      </td></tr>
      <tr><td align="center" style="padding-bottom:32px">
        <span style="font-size:13px;color:#6B6B6B;font-style:italic">${p.poeticNameEnglish}</span>
      </td></tr>
      <tr><td align="center" style="padding-bottom:12px">${swatches}</td></tr>
      <tr><td align="center" style="padding-bottom:32px">
        <span style="font-size:11px;color:#9B9B9B;letter-spacing:0.08em">${hexLine}</span>
      </td></tr>
      <tr><td align="center" style="padding-bottom:12px">
        <span style="font-size:13px;color:#6B6B6B">${p.city} · ${p.temperature}°C · ${p.condition}</span>
      </td></tr>
      <tr><td style="padding-bottom:32px">
        <p style="margin:0;font-size:14px;line-height:1.7;color:#6B6B6B;text-align:center">${p.description}</p>
      </td></tr>
      <tr><td align="center" style="padding:0 0 24px">
        <div style="display:flex;justify-content:center;gap:12px">
          <a href="https://kise-proxy.lima-galhardo.workers.dev/daily-post/image" style="display:inline-block;padding:12px 20px;background:#344E41;color:#DAD7CD;font-size:12px;letter-spacing:0.15em;text-transform:uppercase;text-decoration:none;border-radius:6px">DOWNLOAD LIGHT</a>
          <a href="https://kise-proxy.lima-galhardo.workers.dev/daily-post/image/dark" style="display:inline-block;padding:12px 20px;background:#2C3E35;color:#DAD7CD;font-size:12px;letter-spacing:0.15em;text-transform:uppercase;text-decoration:none;border-radius:6px">DOWNLOAD DARK</a>
        </div>
      </td></tr>
      ${captionBlock(caption, "CAPTION — COPY AND PASTE")}`;

  await sendEmail(
    buildPaletteSubject(p),
    emailWrapper(inner, preheader),
    env
  );
}

async function sendWabiEmail(c: DailyWabiColor, env: Env): Promise<void> {
  const caption = buildWabiCaption(c);
  const textColor = isLightColor(c.hex) ? "#344E41" : "#F5F4F0";

  const inner = `
      <tr><td align="center" style="padding-bottom:6px">
        <span style="font-size:10px;color:#A3B18A;letter-spacing:0.15em;text-transform:uppercase">和色 — JAPANESE COLOR</span>
      </td></tr>
      <tr><td align="center" style="padding-bottom:24px">
        <div style="width:200px;height:200px;background:${c.hex};border-radius:4px;display:flex;align-items:center;justify-content:center;margin:0 auto">
          <span style="font-family:'Cormorant Garamond',Georgia,serif;font-size:48px;color:${textColor};line-height:200px">${c.kanji}</span>
        </div>
      </td></tr>
      <tr><td align="center" style="padding-bottom:6px">
        <span style="font-family:'Cormorant Garamond',Georgia,serif;font-weight:300;font-size:24px;color:#344E41">${c.kanji}</span>
        <span style="font-size:13px;color:#6B6B6B;margin-left:8px">(${c.romanization})</span>
      </td></tr>
      <tr><td align="center" style="padding-bottom:24px">
        <span style="font-size:13px;color:#6B6B6B;font-style:italic">${c.meaning}</span>
      </td></tr>
      <tr><td align="center" style="padding-bottom:8px">
        <span style="font-size:11px;color:#9B9B9B;letter-spacing:0.08em">${c.hex}</span>
      </td></tr>
      <tr><td style="padding-bottom:12px">
        <p style="margin:0;font-size:14px;line-height:1.7;color:#6B6B6B;text-align:center">${c.poeticDescription}</p>
      </td></tr>
      <tr><td style="padding-bottom:32px">
        <p style="margin:0;font-size:14px;line-height:1.7;color:#6B6B6B;text-align:center">${c.howToWear}</p>
      </td></tr>
      <tr><td align="center" style="padding:0 0 24px">
        <div style="display:flex;justify-content:center;gap:12px">
          <a href="https://kise-proxy.lima-galhardo.workers.dev/daily-post/image" style="display:inline-block;padding:12px 20px;background:#344E41;color:#DAD7CD;font-size:12px;letter-spacing:0.15em;text-transform:uppercase;text-decoration:none;border-radius:6px">DOWNLOAD PNG</a>
        </div>
      </td></tr>
      ${captionBlock(caption, "CAPTION — COPY AND PASTE")}`;

  await sendEmail(
    `和色 — ${c.kanji} (${c.romanization})`,
    emailWrapper(
      inner,
      `Wabi color for Threads: ${c.kanji} (${c.romanization}) ${c.hex}.`
    ),
    env
  );
}

async function sendReflectionEmail(
  r: DailyReflection,
  env: Env
): Promise<void> {
  const inner = `
      <tr><td align="center" style="padding-bottom:6px">
        <span style="font-size:10px;color:#A3B18A;letter-spacing:0.15em;text-transform:uppercase">REFLECTION</span>
      </td></tr>
      <tr><td style="padding:24px 0 32px">
        <p style="margin:0;font-family:'Cormorant Garamond',Georgia,serif;font-weight:300;font-size:22px;line-height:1.6;color:#344E41;text-align:center">${r.text}</p>
      </td></tr>
      <tr><td align="center" style="padding:0 0 24px">
        <a href="https://kise-proxy.lima-galhardo.workers.dev/daily-post/image" style="display:inline-block;padding:12px 20px;background:#344E41;color:#DAD7CD;font-size:12px;letter-spacing:0.15em;text-transform:uppercase;text-decoration:none;border-radius:6px">DOWNLOAD PNG</a>
      </td></tr>
      ${captionBlock(r.text, "CAPTION — TEXT ONLY POST")}`;

  await sendEmail(
    "KISE — Thursday reflection",
    emailWrapper(inner, "Thursday reflection draft ready for Threads posting."),
    env
  );
}

// ---------------------------------------------------------------------------
// HTML templates for /daily-post
// ---------------------------------------------------------------------------

export function buildDailyPostHtml(content: DailyContent): string {
  switch (content.type) {
    case "palette":
      return buildPalettePostHtml(content);
    case "wabi-color":
      return buildWabiPostHtml(content);
    case "reflection":
      return buildReflectionPostHtml(content);
  }
}

function baseStyles(): string {
  return `
  @import url('https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,300;0,400;1,300&family=DM+Sans:wght@300;400;500&display=swap');
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    background: #E8E6E0;
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 40px;
    gap: 40px;
    font-family: 'DM Sans', sans-serif;
    -webkit-font-smoothing: antialiased;
  }
  .instruction { font-size: 12px; color: #999; text-align: center; max-width: 500px; line-height: 1.6; }
  .instruction strong { color: #666; }
  .label { font-family: 'DM Sans', sans-serif; font-weight: 500; font-size: 11px; letter-spacing: 0.2em; text-transform: uppercase; color: #A3B18A; }
  .caption-box { max-width: 540px; background: #F5F4F0; border-radius: 12px; padding: 24px 28px; font-family: 'DM Sans', sans-serif; font-weight: 300; font-size: 14px; line-height: 1.7; color: #344E41; white-space: pre-line; }
  .caption-box .copy-hint { font-size: 10px; color: #A3B18A; margin-top: 16px; letter-spacing: 0.05em; }
  .divider { width: 400px; height: 1px; background: #CCC; opacity: 0.3; }`;
}

// Seeded PRNG (mulberry32) — deterministic per day
function mulberry32(seed: number): () => number {
  return function () {
    seed |= 0;
    seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

interface BlockLayout {
  width: number;
  height: number;
  left: number;
  top: number;
  rotation: number;
  zIndex: number;
}

function generateBlockLayout(seed: number): BlockLayout[] {
  const rand = mulberry32(seed);

  // Sizes — hero is always significantly larger, rest decrease
  const sizes = [
    { w: Math.round(175 + rand() * 55), h: Math.round(145 + rand() * 50) },
    { w: Math.round(125 + rand() * 45), h: Math.round(110 + rand() * 40) },
    { w: Math.round(95 + rand() * 40), h: Math.round(85 + rand() * 35) },
    { w: Math.round(80 + rand() * 35), h: Math.round(70 + rand() * 30) },
  ];

  // 4 quadrant anchors — close enough to overlap but spread enough
  // that no block can fully hide behind another
  const cells = [
    { x: 65 + rand() * 40, y: 75 + rand() * 25 },
    { x: 245 + rand() * 50, y: 80 + rand() * 30 },
    { x: 80 + rand() * 50, y: 205 + rand() * 30 },
    { x: 240 + rand() * 55, y: 210 + rand() * 30 },
  ];

  // Shuffle which quadrant each block gets
  const cellOrder = [0, 1, 2, 3];
  for (let i = cellOrder.length - 1; i > 0; i--) {
    const j = Math.floor(rand() * (i + 1));
    [cellOrder[i], cellOrder[j]] = [cellOrder[j], cellOrder[i]];
  }

  const blocks: BlockLayout[] = [];

  for (let i = 0; i < 4; i++) {
    const size = sizes[i];
    const cell = cells[cellOrder[i]];

    let left = Math.round(cell.x);
    let top = Math.round(cell.y);

    // Clamp to image bounds
    left = Math.max(20, Math.min(left, 540 - size.w - 20));
    top = Math.max(65, Math.min(top, 385 - size.h));

    const rotation = (rand() - 0.5) * 5; // ±2.5°

    // Z-index by size: hero (i=0) → z:1 (back), smallest (i=3) → z:4 (front)
    // This ensures smaller blocks are always on top and fully visible,
    // while the hero is the dominant background presence.
    blocks.push({
      width: size.w,
      height: size.h,
      left,
      top,
      rotation,
      zIndex: i + 1,
    });
  }

  return blocks;
}

function blockStyle(b: BlockLayout, color: string): string {
  return `position:absolute;left:${b.left}px;top:${b.top}px;width:${b.width}px;height:${b.height}px;background:${color};border-radius:2px;transform:rotate(${b.rotation.toFixed(1)}deg);z-index:${b.zIndex};box-shadow:0 1px 3px rgba(0,0,0,0.06),0 6px 16px rgba(0,0,0,0.04)`;
}

function grainSvg(): string {
  return `<div style="position:absolute;inset:0;opacity:0.3;pointer-events:none;z-index:5;mix-blend-mode:multiply;background-image:url(&quot;data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.85' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='1'/%3E%3C/svg%3E&quot;);background-size:128px 128px"></div>`;
}

function buildPalettePostHtml(p: DailyPalette): string {
  const caption = buildPaletteCaption(p);
  const hexLine = p.colors.join(" · ");
  const seed = Math.floor(Date.now() / 86_400_000);
  const blocks = generateBlockLayout(seed);
  const grain = grainSvg();

  const blockDivs = blocks
    .map((b, i) => `      <div style="${blockStyle(b, p.colors[i])}"></div>`)
    .join("\n");

  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>KISE — Daily Palette: ${p.city}</title>
<style>
  ${baseStyles()}
  .post-image { width: 540px; height: 540px; background: #F5F4F0; position: relative; overflow: hidden; }
  .brand { position: absolute; top: 28px; right: 32px; font-family: 'Cormorant Garamond', serif; font-weight: 300; font-size: 14px; color: #344E41; letter-spacing: 0.15em; opacity: 0.45; z-index: 10; }
  .brand-kanji { font-size: 10px; opacity: 0.7; margin-left: 4px; letter-spacing: 0.05em; }
  .poetic-name { position: absolute; top: 28px; left: 32px; font-family: 'Cormorant Garamond', serif; font-weight: 300; font-size: 20px; color: #344E41; opacity: 0.65; z-index: 10; }
  .hairline { position: absolute; background: #344E41; opacity: 0.06; z-index: 4; }
  .hairline-h { width: 100%; height: 1px; top: 66px; left: 0; }
  .hairline-v { width: 1px; height: 100%; top: 0; right: 72px; }
  .post-info { position: absolute; bottom: 0; left: 0; right: 0; padding: 28px 32px; z-index: 10; background: linear-gradient(transparent, rgba(245,244,240,0.95) 30%); }
  .post-city { font-family: 'DM Sans', sans-serif; font-weight: 400; font-size: 10px; letter-spacing: 0.2em; text-transform: uppercase; color: #A3B18A; margin-bottom: 4px; }
  .post-temp { font-family: 'Cormorant Garamond', serif; font-weight: 300; font-size: 38px; color: #344E41; line-height: 1; margin-bottom: 3px; }
  .post-condition { font-family: 'DM Sans', sans-serif; font-weight: 300; font-size: 11px; color: #588157; margin-bottom: 14px; }
  .post-hexes { font-family: 'DM Sans', sans-serif; font-weight: 300; font-size: 9px; color: #A3B18A; letter-spacing: 0.08em; }

  .post-image-dark { width: 540px; height: 540px; background: #2C3E35; position: relative; overflow: hidden; }
  .post-image-dark .brand { color: #DAD7CD; opacity: 0.35; }
  .post-image-dark .poetic-name { color: #DAD7CD; opacity: 0.4; }
  .post-image-dark .hairline { background: #DAD7CD; }
  .post-image-dark .post-info { background: linear-gradient(transparent, rgba(44,62,53,0.96) 30%); }
  .post-image-dark .post-city { color: #A3B18A; }
  .post-image-dark .post-temp { color: #DAD7CD; }
  .post-image-dark .post-condition { color: #7A9E7E; }
  .post-image-dark .post-hexes { color: rgba(218,215,205,0.35); }
</style>
</head>
<body>
  <div class="instruction">
    <strong>KISE — Daily Palette: ${p.city}</strong><br>
    Screenshot each image with Cmd + Shift + 4. Retina = 1080x1080 automatically.<br>
    Copy the caption text below the image.
  </div>

  <div class="label">Option A — Light</div>
  <div class="post-image">
    <div class="hairline hairline-h"></div>
    <div class="hairline hairline-v"></div>
    <span class="poetic-name">${p.poeticNameLocal}</span>
    <span class="brand">KISE<span class="brand-kanji">着せ</span></span>
${blockDivs}
    ${grain}
    <div class="post-info">
      <div class="post-city">${p.city}</div>
      <div class="post-temp">${p.temperature}°</div>
      <div class="post-condition">${p.condition}</div>
      <div class="post-hexes">${hexLine}</div>
    </div>
  </div>
  <a href="/daily-post/image" download="${p.poeticNameEnglish}-light.png" style="padding:10px 20px;background:#344E41;color:#DAD7CD;text-decoration:none;font-size:11px;letter-spacing:0.1em;text-transform:uppercase;border-radius:4px;margin-top:-20px">Download PNG</a>

  <div class="label">Option B — Dark</div>
  <div class="post-image-dark">
    <div class="hairline hairline-h"></div>
    <div class="hairline hairline-v"></div>
    <span class="poetic-name">${p.poeticNameLocal}</span>
    <span class="brand">KISE<span class="brand-kanji">着せ</span></span>
${blockDivs}
    ${grain}
    <div class="post-info">
      <div class="post-city">${p.city}</div>
      <div class="post-temp">${p.temperature}°</div>
      <div class="post-condition">${p.condition}</div>
      <div class="post-hexes">${hexLine}</div>
    </div>
  </div>
  <a href="/daily-post/image/dark" download="${p.poeticNameEnglish}-dark.png" style="padding:10px 20px;background:#344E41;color:#DAD7CD;text-decoration:none;font-size:11px;letter-spacing:0.1em;text-transform:uppercase;border-radius:4px;margin-top:-20px">Download PNG</a>

  <div class="divider"></div>
  <div class="label">Caption — copy and paste</div>
  <div class="caption-box">${caption}
    <div class="copy-hint">Select all text above → Copy → Paste in Threads</div>
  </div>
</body>
</html>`;
}

function buildWabiPostHtml(c: DailyWabiColor): string {
  const caption = buildWabiCaption(c);
  const textColor = isLightColor(c.hex) ? "#344E41" : "#F5F4F0";
  const subtextColor = isLightColor(c.hex)
    ? "rgba(52,78,65,0.5)"
    : "rgba(245,244,240,0.5)";

  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>KISE — 和色: ${c.kanji}</title>
<style>
  ${baseStyles()}
  .post-image {
    width: 540px;
    height: 540px;
    background: ${c.hex};
    position: relative;
    overflow: hidden;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  .brand { position: absolute; top: 28px; right: 32px; font-family: 'Cormorant Garamond', serif; font-weight: 300; font-size: 14px; color: ${textColor}; letter-spacing: 0.15em; opacity: 0.5; }
  .brand-kanji { font-size: 10px; opacity: 0.7; margin-left: 4px; letter-spacing: 0.05em; }
  .kanji-center { font-family: 'Cormorant Garamond', serif; font-weight: 300; font-size: 72px; color: ${textColor}; opacity: 0.9; }
  .post-info { position: absolute; bottom: 0; left: 0; right: 0; padding: 28px 32px; }
  .romanization { font-family: 'DM Sans', sans-serif; font-weight: 300; font-size: 11px; color: ${subtextColor}; letter-spacing: 0.1em; }
  .hex-code { font-family: 'DM Sans', sans-serif; font-weight: 300; font-size: 9px; color: ${subtextColor}; letter-spacing: 0.08em; margin-top: 4px; }
</style>
</head>
<body>
  <div class="instruction">
    <strong>KISE — 和色: ${c.kanji} (${c.romanization})</strong><br>
    Screenshot the image with Cmd + Shift + 4. Retina = 1080x1080 automatically.<br>
    Image is optional for 和色 posts. Copy the caption below.
  </div>

  <div class="label">和色 — Japanese Color</div>
  <div class="post-image">
    <span class="brand">KISE<span class="brand-kanji">着せ</span></span>
    <span class="kanji-center">${c.kanji}</span>
    <div class="post-info">
      <div class="romanization">${c.romanization}</div>
      <div class="hex-code">${c.hex}</div>
    </div>
  </div>

  <div class="divider"></div>
  <div class="label">Caption — copy and paste</div>
  <div class="caption-box">${caption}
    <div class="copy-hint">Select all text above → Copy → Paste in Threads</div>
  </div>
</body>
</html>`;
}

function buildReflectionPostHtml(r: DailyReflection): string {
  const caption = buildReflectionCaption(r);

  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>KISE — Reflection</title>
<style>
  ${baseStyles()}
  .reflection-text {
    max-width: 480px;
    font-family: 'Cormorant Garamond', serif;
    font-weight: 300;
    font-size: 26px;
    line-height: 1.6;
    color: #344E41;
    text-align: center;
    padding: 60px 0;
  }
</style>
</head>
<body>
  <div class="instruction">
    <strong>KISE — Thursday Reflection</strong><br>
    Text-only post. No image needed. Copy the caption below.
  </div>

  <div class="label">Reflection</div>
  <div class="reflection-text">${r.text}</div>

  <div class="divider"></div>
  <div class="label">Caption — copy and paste</div>
  <div class="caption-box">${caption}
    <div class="copy-hint">Select all text above → Copy → Paste in Threads</div>
  </div>
</body>
</html>`;
}

// ---------------------------------------------------------------------------
// Topics & Hashtags
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Threads topic tags (official enum, KISE-relevant subset)
// ---------------------------------------------------------------------------

export const THREADS_TOPIC_TAGS = [
  "FASHION_STYLE",
  "ART_CULTURE",
  "BEAUTY",
  "INSPIRATIONAL_MOTIVATIONAL",
  "LIFESTYLE",
  "DIY_DESIGN_CRAFT",
  "HEALTH",
  "MENTAL_HEALTH",
] as const;

export function buildTopicSelectionPrompt(content: DailyContent): string {
  const tagsLine = THREADS_TOPIC_TAGS.join(", ");

  let contentSummary: string;
  switch (content.type) {
    case "palette":
      contentSummary = `Type: color palette
City: ${content.city}
Temperature: ${content.temperature}°C, ${content.condition}
Palette name: ${content.poeticNameLocal} (${content.poeticNameEnglish})
Description: ${content.description}
Colors: ${content.colors.join(", ")}`;
      break;
    case "wabi-color":
      contentSummary = `Type: Japanese wabi color
Kanji: ${content.kanji} (${content.romanization})
Meaning: ${content.meaning}
Description: ${content.poeticDescription}
How to wear: ${content.howToWear}`;
      break;
    case "reflection":
      contentSummary = `Type: style reflection
Text: ${content.text}`;
      break;
  }

  return `You are a social media strategist for KISE, a fashion and Japanese aesthetics brand posting on Threads.

Given this post content, select:
1. The single best Threads topic tag from this list: ${tagsLine}
2. Up to 3 hashtags that are specific to this post's content. Always include #kise as the last hashtag.

Post content:
${contentSummary}`;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function isLightColor(hex: string): boolean {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return (0.299 * r + 0.587 * g + 0.114 * b) / 255 > 0.5;
}
