// kise-proxy/src/index.ts

import { handleSuggestion } from "./handler";
import type { SuggestionRequest, Env } from "./types";

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: corsHeaders(),
      });
    }

    if (request.method !== "POST") {
      return jsonError("Method not allowed", 405);
    }

    const url = new URL(request.url);
    if (url.pathname !== "/suggest") {
      return jsonError("Not found", 404);
    }

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
        headers: {
          "Content-Type": "application/json",
          ...corsHeaders(),
        },
      });
    } catch (err) {
      const message =
        err instanceof Error ? err.message : "Internal server error";
      console.error("Suggestion error:", message);
      return jsonError(message, 500);
    }
  },
};

function jsonError(message: string, status: number): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders(),
    },
  });
}

function corsHeaders(): Record<string, string> {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
  };
}
