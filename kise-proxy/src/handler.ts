// kise-proxy/src/handler.ts

import Anthropic from "@anthropic-ai/sdk";
import { buildSystemPrompt } from "./prompt";
import { SUGGEST_OUTFIT_TOOL } from "./tool-schema";
import type {
  SuggestionRequest,
  SuggestionResponse,
  Env,
} from "./types";

export async function handleSuggestion(
  body: SuggestionRequest,
  env: Env
): Promise<SuggestionResponse> {
  const client = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });

  const systemPrompt = buildSystemPrompt(body.style_archetypes);

  const userMessage = buildUserMessage(body);

  const response = await client.messages.create({
    model: "claude-sonnet-4-20250514",
    max_tokens: 1024,
    system: systemPrompt,
    tools: [SUGGEST_OUTFIT_TOOL],
    tool_choice: { type: "tool", name: "suggest_outfit" },
    messages: [{ role: "user", content: userMessage }],
  });

  const toolBlock = response.content.find(
    (block) => block.type === "tool_use" && block.name === "suggest_outfit"
  );

  if (!toolBlock || toolBlock.type !== "tool_use") {
    throw new Error("Claude did not return a suggest_outfit tool call");
  }

  const input = toolBlock.input as Record<string, unknown>;

  return {
    pieces: input.pieces as string[],
    reasoning: input.reasoning as string,
    layering_note: input.layering_note as string | undefined,
    alternative_piece: input.alternative_piece as
      | SuggestionResponse["alternative_piece"]
      | undefined,
  };
}

function buildUserMessage(body: SuggestionRequest): string {
  const parts: string[] = [];

  parts.push(`Occasion: ${body.occasion}`);
  parts.push(`Boldness: ${body.boldness}`);

  if (body.weather) {
    const w = body.weather;
    parts.push(
      `Weather: ${w.temperature}°C (feels like ${w.feels_like}°C), ${w.condition}, humidity ${w.humidity}%, wind ${w.wind} km/h`
    );
    if (w.hourly_forecast.length > 0) {
      const forecast = w.hourly_forecast
        .map((h) => `${h.hour}:00 → ${h.temp}°C ${h.condition}`)
        .join(", ");
      parts.push(`Hourly forecast: ${forecast}`);
    }
  }

  parts.push(`\nWardrobe (${body.wardrobe.length} pieces):`);
  for (const piece of body.wardrobe) {
    parts.push(
      `- ${piece.id}: ${piece.color} ${piece.category} (${piece.fit}, ${piece.material}, ${piece.weight}, ${piece.formality})`
    );
  }

  if (body.recent_suggestions.length > 0) {
    parts.push(`\nRecent suggestions:`);
    for (const s of body.recent_suggestions) {
      parts.push(
        `- ${s.date}: [${s.piece_ids.join(", ")}] → ${s.feedback}`
      );
    }
  }

  if (body.language) {
    parts.push(`\nRespond in ${body.language}.`);
  }

  return parts.join("\n");
}
