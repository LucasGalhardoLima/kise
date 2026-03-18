// kise-proxy/src/index.ts

import { handleSuggestion } from "./handler";
import { handleScheduled } from "./palette-handler";
import type { SuggestionRequest, Env } from "./types";

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders() });
    }

    const url = new URL(request.url);

    // GET /daily-pick — serve cached palette
    if (request.method === "GET" && url.pathname === "/daily-pick") {
      const cached = await env.DAILY_PICK.get("daily-pick");
      if (!cached) {
        return jsonError("No daily pick available", 404);
      }
      return new Response(cached, {
        headers: { "Content-Type": "application/json", ...corsHeaders() },
      });
    }

    // POST /suggest — existing suggestion handler
    if (request.method === "POST" && url.pathname === "/suggest") {
      try {
        const body = (await request.json()) as SuggestionRequest;

        if (!body.style_archetypes?.length || !body.wardrobe?.length) {
          return jsonError(
            "Missing required fields: style_archetypes and wardrobe",
            400
          );
        }

        const result = await handleSuggestion(body, env);

        return new Response(JSON.stringify(result), {
          headers: { "Content-Type": "application/json", ...corsHeaders() },
        });
      } catch (err) {
        const message =
          err instanceof Error ? err.message : "Internal server error";
        console.error("Suggestion error:", message);
        return jsonError(message, 500);
      }
    }

    return jsonError("Not found", 404);
  },

  async scheduled(event: ScheduledEvent, env: Env, ctx: ExecutionContext) {
    ctx.waitUntil(handleScheduled(env));
  },
};

function jsonError(message: string, status: number): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders() },
  });
}

function corsHeaders(): Record<string, string> {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
  };
}
