// kise-proxy/src/index.ts

import { handleSuggestion } from "./handler";
import { handleScheduled, buildDailyPostHtml } from "./palette-handler";
import type { SuggestionRequest, DailyContent, Env } from "./types";

async function getImageGenerator() {
  // Dynamic import WASM modules and image generator to avoid startup WASM errors
  // @ts-ignore — wrangler bundles .wasm as CompiledWasm (WebAssembly.Module)
  const [yogaModule, resvgModule, mod] = await Promise.all([
    import("./yoga.wasm").catch(() => ({ default: undefined })),
    import("./resvg.wasm").catch(() => ({ default: undefined })),
    import("./image-generator"),
  ]);
  await mod.initYoga(yogaModule.default, resvgModule.default);
  return mod;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders() });
    }

    const url = new URL(request.url);

    // GET /daily-post/image — serve today's Threads content as PNG (fallback: SVG)
    if (request.method === "GET" && url.pathname === "/daily-post/image") {
      const cached = await env.DAILY_PICK.get("daily-content");
      if (!cached) return jsonError("No daily content available", 404);
      const content = JSON.parse(cached) as DailyContent;
      try {
        const mod = await getImageGenerator();
        try {
          const png = await mod.generatePng(content, { dark: false });
          return new Response(png, {
            headers: { "Content-Type": "image/png", ...corsHeaders() },
          });
        } catch {
          const svg = await mod.generateSvg(content, { dark: false });
          return new Response(svg, {
            headers: { "Content-Type": "image/svg+xml", ...corsHeaders() },
          });
        }
      } catch (e) {
        return jsonError("Image generation unavailable: " + (e instanceof Error ? e.message : "unknown"), 503);
      }
    }

    // GET /daily-post/image/dark — dark variant
    if (request.method === "GET" && url.pathname === "/daily-post/image/dark") {
      const cached = await env.DAILY_PICK.get("daily-content");
      if (!cached) return jsonError("No daily content available", 404);
      const content = JSON.parse(cached) as DailyContent;
      try {
        const mod = await getImageGenerator();
        try {
          const png = await mod.generatePng(content, { dark: true });
          return new Response(png, {
            headers: { "Content-Type": "image/png", ...corsHeaders() },
          });
        } catch {
          const svg = await mod.generateSvg(content, { dark: true });
          return new Response(svg, {
            headers: { "Content-Type": "image/svg+xml", ...corsHeaders() },
          });
        }
      } catch (e) {
        return jsonError("Image generation unavailable: " + (e instanceof Error ? e.message : "unknown"), 503);
      }
    }

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

    // GET /daily-post — serve today's Threads content as screenshot-ready HTML
    if (request.method === "GET" && url.pathname === "/daily-post") {
      const cached = await env.DAILY_PICK.get("daily-content");
      if (!cached) {
        return jsonError("No daily content available", 404);
      }
      const content = JSON.parse(cached) as DailyContent;
      const html = buildDailyPostHtml(content);
      return new Response(html, {
        headers: { "Content-Type": "text/html;charset=UTF-8", ...corsHeaders() },
      });
    }

    // POST /admin/trigger — manually trigger the scheduled handler
    if (request.method === "POST" && url.pathname === "/admin/trigger") {
      const authHeader = request.headers.get("Authorization");
      if (authHeader !== `Bearer ${env.ADMIN_TRIGGER_KEY}`) {
        return jsonError("Unauthorized", 401);
      }
      await handleScheduled(env);
      return new Response(JSON.stringify({ ok: true }), {
        headers: { "Content-Type": "application/json", ...corsHeaders() },
      });
    }

    // GET /weather?lat=X&lon=Y — proxy OpenWeatherMap (keeps API key server-side)
    if (request.method === "GET" && url.pathname === "/weather") {
      const lat = url.searchParams.get("lat");
      const lon = url.searchParams.get("lon");
      const lang = url.searchParams.get("lang") || "en";
      if (!lat || !lon) {
        return jsonError("Missing lat/lon parameters", 400);
      }
      try {
        const owmUrl = `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&units=metric&lang=${lang}&appid=${env.OPENWEATHER_API_KEY}`;
        const owmRes = await fetch(owmUrl);
        if (!owmRes.ok) throw new Error(`OWM: ${owmRes.status}`);
        const data = (await owmRes.json()) as {
          main: { temp: number };
          weather: { description: string }[];
          name: string;
        };
        return new Response(
          JSON.stringify({
            temp: Math.round(data.main.temp),
            condition: data.weather[0]?.description ?? "unknown",
            city: data.name,
          }),
          {
            headers: {
              "Content-Type": "application/json",
              "Cache-Control": "public, max-age=1800",
              ...corsHeaders(),
            },
          }
        );
      } catch (err) {
        return jsonError("Weather fetch failed", 502);
      }
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
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
  };
}
