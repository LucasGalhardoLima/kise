import { describe, it, expect } from "vitest";
import {
  THREADS_TOPIC_TAGS,
  buildTopicSelectionPrompt,
  buildTopicFallback,
  buildPaletteCaption,
  buildWabiCaption,
  buildReflectionCaption,
} from "../src/palette-handler";
import type { DailyContent, DailyPalette, DailyWabiColor, DailyReflection, TopicSelection } from "../src/types";

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

describe("buildTopicFallback", () => {
  it("returns FASHION_STYLE and 3 hashtags for palette", () => {
    const content: DailyContent = {
      type: "palette",
      city: "Tokyo",
      temperature: 20,
      condition: "clear",
      poeticNameLocal: "霞色",
      poeticNameEnglish: "Haze",
      description: "soft",
      colors: ["#aaa"],
    };
    const result = buildTopicFallback(content);
    expect(result.topicTag).toBe("FASHION_STYLE");
    expect(result.hashtags).toHaveLength(3);
    expect(result.hashtags[2]).toBe("#kise");
  });

  it("returns ART_CULTURE for wabi-color", () => {
    const content: DailyContent = {
      type: "wabi-color",
      kanji: "藍色",
      romanization: "ai-iro",
      meaning: "indigo",
      hex: "#264F73",
      poeticDescription: "deep blue",
      howToWear: "in winter",
    };
    const result = buildTopicFallback(content);
    expect(result.topicTag).toBe("ART_CULTURE");
    expect(result.hashtags[2]).toBe("#kise");
  });

  it("returns INSPIRATIONAL_MOTIVATIONAL for reflection", () => {
    const content: DailyContent = {
      type: "reflection",
      text: "Style is confidence.",
    };
    const result = buildTopicFallback(content);
    expect(result.topicTag).toBe("INSPIRATIONAL_MOTIVATIONAL");
    expect(result.hashtags[2]).toBe("#kise");
  });
});

const mockSelection: TopicSelection = {
  topicTag: "FASHION_STYLE",
  hashtags: ["#colorstory", "#wardrobegoals", "#kise"],
};

describe("buildPaletteCaption", () => {
  it("includes dynamic hashtags from selection", () => {
    const palette: DailyPalette = {
      type: "palette",
      city: "Tokyo",
      temperature: 18,
      condition: "clear sky",
      poeticNameLocal: "霞色",
      poeticNameEnglish: "Haze",
      description: "A soft grey morning.",
      colors: ["#B0B0B0", "#C8C8C8"],
    };
    const caption = buildPaletteCaption(palette, mockSelection);
    expect(caption).toContain("#colorstory");
    expect(caption).toContain("#wardrobegoals");
    expect(caption).toContain("#kise");
    expect(caption).not.toContain("#colorpalette");
  });
});

describe("buildWabiCaption", () => {
  it("includes dynamic hashtags from selection", () => {
    const color: DailyWabiColor = {
      type: "wabi-color",
      kanji: "藍色",
      romanization: "ai-iro",
      meaning: "Japanese indigo",
      hex: "#264F73",
      poeticDescription: "The deepest blue.",
      howToWear: "The anchor of any cold-weather palette.",
    };
    const wabiSelection: TopicSelection = {
      topicTag: "ART_CULTURE",
      hashtags: ["#japaneseaesthetics", "#和色", "#kise"],
    };
    const caption = buildWabiCaption(color, wabiSelection);
    expect(caption).toContain("#japaneseaesthetics");
    expect(caption).toContain("#kise");
    expect(caption).not.toContain("#japanesecolor");
  });
});

describe("buildReflectionCaption", () => {
  it("includes dynamic hashtags from selection", () => {
    const reflection: DailyReflection = {
      type: "reflection",
      text: "Style is confidence.",
    };
    const reflectionSelection: TopicSelection = {
      topicTag: "INSPIRATIONAL_MOTIVATIONAL",
      hashtags: ["#slowfashion", "#intentionalstyle", "#kise"],
    };
    const caption = buildReflectionCaption(reflection, reflectionSelection);
    expect(caption).toContain("#slowfashion");
    expect(caption).toContain("#kise");
    expect(caption).not.toContain("#intentionalliving");
  });
});
