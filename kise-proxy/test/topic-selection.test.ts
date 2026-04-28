import { describe, it, expect } from "vitest";
import {
  THREADS_TOPIC_TAGS,
  buildTopicSelectionPrompt,
} from "../src/palette-handler";
import type { DailyContent } from "../src/types";

describe("THREADS_TOPIC_TAGS", () => {
  it("contains exactly the expected KISE-relevant topic tags", () => {
    expect(THREADS_TOPIC_TAGS).toEqual([
      "FASHION_STYLE",
      "ART_CULTURE",
      "BEAUTY",
      "INSPIRATIONAL_MOTIVATIONAL",
      "LIFESTYLE",
      "DIY_DESIGN_CRAFT",
      "HEALTH",
      "MENTAL_HEALTH",
    ]);
  });
});

describe("buildTopicSelectionPrompt", () => {
  it("includes palette content in prompt", () => {
    const content: DailyContent = {
      type: "palette",
      city: "Tokyo",
      temperature: 18,
      condition: "clear sky",
      poeticNameLocal: "霞色",
      poeticNameEnglish: "Haze",
      description: "A soft grey morning.",
      colors: ["#B0B0B0", "#C8C8C8"],
    };
    const prompt = buildTopicSelectionPrompt(content);
    expect(prompt).toContain("Tokyo");
    expect(prompt).toContain("霞色");
    expect(prompt).toContain("Haze");
    expect(prompt).toContain("A soft grey morning.");
  });

  it("includes wabi-color content in prompt", () => {
    const content: DailyContent = {
      type: "wabi-color",
      kanji: "藍色",
      romanization: "ai-iro",
      meaning: "Japanese indigo",
      hex: "#264F73",
      poeticDescription: "The deepest blue.",
      howToWear: "The anchor of any cold-weather palette.",
    };
    const prompt = buildTopicSelectionPrompt(content);
    expect(prompt).toContain("藍色");
    expect(prompt).toContain("ai-iro");
    expect(prompt).toContain("Japanese indigo");
    expect(prompt).toContain("The deepest blue.");
  });

  it("includes reflection content in prompt", () => {
    const content: DailyContent = {
      type: "reflection",
      text: "Repeating an outfit isn't a lack of options. It's confidence.",
    };
    const prompt = buildTopicSelectionPrompt(content);
    expect(prompt).toContain("Repeating an outfit");
  });

  it("always asks for topic tag from the enum and up to 3 hashtags", () => {
    const content: DailyContent = {
      type: "reflection",
      text: "Style is confidence.",
    };
    const prompt = buildTopicSelectionPrompt(content);
    expect(prompt).toContain("FASHION_STYLE");
    expect(prompt).toContain("3 hashtags");
    expect(prompt).toContain("#kise");
  });
});
