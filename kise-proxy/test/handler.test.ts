// kise-proxy/test/handler.test.ts

import { describe, it, expect } from "vitest";
import type { SuggestionRequest } from "../src/types";

// We test the worker entry (index.ts) for routing logic.
// The actual Claude API call in handler.ts is integration-tested manually.

// Import the worker default export
import worker from "../src/index";

const mockEnv = { ANTHROPIC_API_KEY: "test-key" };

function makeRequest(
  method: string,
  path: string,
  body?: unknown
): Request {
  const url = `https://test.worker.dev${path}`;
  const init: RequestInit = { method };
  if (body) {
    init.body = JSON.stringify(body);
    init.headers = { "Content-Type": "application/json" };
  }
  return new Request(url, init);
}

describe("Worker routing", () => {
  it("returns 404 for GET /suggest (only GET /daily-pick is valid)", async () => {
    const req = makeRequest("GET", "/suggest");
    const res = await worker.fetch(req, mockEnv);
    expect(res.status).toBe(404);
    const json = (await res.json()) as { error: string };
    expect(json.error).toBe("Not found");
  });

  it("returns 404 for unknown paths", async () => {
    const req = makeRequest("POST", "/unknown");
    const res = await worker.fetch(req, mockEnv);
    expect(res.status).toBe(404);
    const json = (await res.json()) as { error: string };
    expect(json.error).toBe("Not found");
  });

  it("returns 400 when missing required fields", async () => {
    const req = makeRequest("POST", "/suggest", {
      style_archetypes: [],
      wardrobe: [],
    });
    const res = await worker.fetch(req, mockEnv);
    expect(res.status).toBe(400);
    const json = (await res.json()) as { error: string };
    expect(json.error).toContain("Missing required fields");
  });

  it("handles CORS preflight", async () => {
    const req = makeRequest("OPTIONS", "/suggest");
    const res = await worker.fetch(req, mockEnv);
    expect(res.status).toBe(200);
    expect(res.headers.get("Access-Control-Allow-Origin")).toBe("*");
    expect(res.headers.get("Access-Control-Allow-Methods")).toContain("POST");
  });

  it("returns 500 when Claude API fails (no real key)", async () => {
    const body: SuggestionRequest = {
      style_archetypes: ["minimalist"],
      boldness: 0.3,
      occasion: "everyday",
      wardrobe: [
        {
          id: "uuid-1",
          category: "tShirt",
          color: "white",
          fit: "regular",
          material: "cotton",
          weight: "mid",
          formality: "casual",
        },
      ],
      recent_suggestions: [],
    };
    const req = makeRequest("POST", "/suggest", body);
    const res = await worker.fetch(req, mockEnv);
    // With a fake API key, the Anthropic SDK will throw
    expect(res.status).toBe(500);
  });
});
