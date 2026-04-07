// kise-proxy/src/palette-tool.ts

export function buildPaletteTool() {
  return {
    name: "generate_palette",
    description:
      "Generate a wearable color palette inspired by a city and its current weather",
    input_schema: {
      type: "object" as const,
      required: [
        "poeticNameLocal",
        "poeticNameEnglish",
        "description",
        "colors",
      ],
      properties: {
        poeticNameLocal: {
          type: "string" as const,
          description:
            "Short poetic phrase in the city's cultural language. Examples: '春雲の隙間' (Tokyo), 'entre nuages de printemps' (Paris), 'entre nuvens de primavera' (São Paulo)",
        },
        poeticNameEnglish: {
          type: "string" as const,
          description:
            "English translation of the poetic name, lowercase. Example: 'between the spring clouds'",
        },
        description: {
          type: "string" as const,
          description:
            "One short poetic line connecting weather to wardrobe. How the climate shapes what to wear. Example: 'Fog erases edges. Dress in tones, not contrasts.'",
        },
        colors: {
          type: "array" as const,
          items: { type: "string" as const },
          minItems: 4,
          maxItems: 4,
          description:
            "Exactly 4 hex color codes (e.g. '#8B6F5E'). Colors should work as garment colors — wearable tones, not neon or pastel extremes",
        },
      },
    },
  };
}
