// kise-proxy/test/prompt.test.ts

import { describe, it, expect } from "vitest";
import { buildSystemPrompt } from "../src/prompt";
import { ARCHETYPE_BRIEFS } from "../src/archetypes";
import { buildSuggestOutfitTool } from "../src/tool-schema";

const SUGGEST_OUTFIT_TOOL = buildSuggestOutfitTool();


describe("buildSystemPrompt", () => {
  it("includes selected archetype briefs", () => {
    const prompt = buildSystemPrompt(["old-money", "minimalist"]);
    expect(prompt).toContain("Old Money");
    expect(prompt).toContain("Minimalist");
    expect(prompt).not.toContain("Streetwear");
  });

  it("skips unknown archetypes gracefully", () => {
    const prompt = buildSystemPrompt(["old-money", "unknown-style"]);
    expect(prompt).toContain("Old Money");
    expect(prompt).not.toContain("unknown-style");
  });

  it("includes hard rules and boldness instructions", () => {
    const prompt = buildSystemPrompt(["classic"]);
    expect(prompt).toContain("HARD RULES");
    expect(prompt).toContain("BOLDNESS");
    expect(prompt).toContain("Fabric weight must match weather");
  });

  it("includes all six archetypes in the briefs map", () => {
    const keys = Object.keys(ARCHETYPE_BRIEFS);
    expect(keys).toHaveLength(6);
    expect(keys).toContain("old-money");
    expect(keys).toContain("minimalist");
    expect(keys).toContain("smart-casual");
    expect(keys).toContain("streetwear");
    expect(keys).toContain("classic");
    expect(keys).toContain("scandinavian");
  });
});

describe("SUGGEST_OUTFIT_TOOL", () => {
  it("has the correct tool name", () => {
    expect(SUGGEST_OUTFIT_TOOL.name).toBe("suggest_outfit");
  });

  it("requires pieces and reasoning", () => {
    expect(SUGGEST_OUTFIT_TOOL.input_schema.required).toContain("pieces");
    expect(SUGGEST_OUTFIT_TOOL.input_schema.required).toContain("reasoning");
  });

  it("defines alternative_piece with swap/for/why", () => {
    const alt = SUGGEST_OUTFIT_TOOL.input_schema.properties.alternative_piece;
    expect(alt.properties).toHaveProperty("swap");
    expect(alt.properties).toHaveProperty("for");
    expect(alt.properties).toHaveProperty("why");
  });
});
