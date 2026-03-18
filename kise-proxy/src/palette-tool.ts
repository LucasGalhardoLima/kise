// kise-proxy/src/palette-tool.ts

export function buildPaletteTool() {
  return {
    name: "generate_palette",
    description:
      "Generate a wearable color palette inspired by a city and its current weather",
    input_schema: {
      type: "object" as const,
      required: ["paletteName", "description", "colors"],
      properties: {
        paletteName: {
          type: "string" as const,
          description:
            "Evocative palette name (2-5 words). Should feel like a mood or moment, not a label. Examples: 'Manhã Chuvosa em Shibuya', 'Copacabana ao Entardecer'",
        },
        description: {
          type: "string" as const,
          description:
            "One sentence describing the palette's mood and how it relates to the city/weather",
        },
        colors: {
          type: "array" as const,
          items: { type: "string" as const },
          minItems: 3,
          maxItems: 4,
          description:
            "3-4 hex color codes (e.g. '#8B6F5E'). Colors should work as garment colors — wearable tones, not neon or pastel extremes",
        },
      },
    },
  };
}
