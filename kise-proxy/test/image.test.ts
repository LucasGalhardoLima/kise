// kise-proxy/test/image.test.ts

import { describe, it, expect } from "vitest";
import { generatePng } from "../src/image-generator";
import type { DailyPalette } from "../src/types";

describe("Image generation", () => {
  it("generates a PNG buffer for a palette", async () => {
    const palette: DailyPalette = {
      type: "palette",
      city: "Tokyo",
      temperature: 18,
      condition: "Partly Cloudy",
      poeticNameLocal: "春雲の隙間",
      poeticNameEnglish: "between the spring clouds",
      description: "Fog erases edges. Dress in tones, not contrasts.",
      colors: ["#8B6F5E", "#E8DBC5", "#5B6940", "#2C3E35"],
    };

    const png = await generatePng(palette);
    expect(png).toBeDefined();
    expect(png instanceof Uint8Array).toBe(true);
    expect(png.length).toBeGreaterThan(0);
    
    // Check PNG signature
    expect(png[0]).toBe(0x89);
    expect(png[1]).toBe(0x50);
    expect(png[2]).toBe(0x4e);
    expect(png[3]).toBe(0x47);
  }, 20000);

  it("generates a PNG buffer for a wabi color", async () => {
    const wabi: any = {
      type: "wabi-color",
      kanji: "鶯色",
      romanization: "uguisu-iro",
      meaning: "Color of the nightingale",
      hex: "#5B6940",
      poeticDescription: "A soft olive green that connects any neutral piece.",
      howToWear: "Wear it when you want presence without volume.",
    };

    const png = await generatePng(wabi);
    expect(png).toBeDefined();
    expect(png.length).toBeGreaterThan(0);
  }, 20000);

  it("generates a PNG buffer for a reflection", async () => {
    const reflection: any = {
      type: "reflection",
      text: "Repeating an outfit isn't a lack of options. It's confidence.",
    };

    const png = await generatePng(reflection);
    expect(png).toBeDefined();
    expect(png.length).toBeGreaterThan(0);
  }, 20000);
});
