// kise-proxy/src/tool-schema.ts

export const SUGGEST_OUTFIT_TOOL = {
  name: "suggest_outfit",
  description: "Suggest a daily outfit from the user's wardrobe",
  input_schema: {
    type: "object" as const,
    required: ["pieces", "reasoning"],
    properties: {
      pieces: {
        type: "array" as const,
        items: { type: "string" as const },
        description: "Array of garment piece UUIDs forming the outfit",
      },
      reasoning: {
        type: "string" as const,
        description:
          "1-2 sentence explanation of why this combination works for the context",
      },
      layering_note: {
        type: "string" as const,
        description:
          "Optional note about layering for weather transitions (e.g., cold morning warming to hot afternoon)",
      },
      alternative_piece: {
        type: "object" as const,
        properties: {
          swap: {
            type: "string" as const,
            description: "UUID of the piece to replace",
          },
          for: {
            type: "string" as const,
            description: "UUID of the alternative piece to use instead",
          },
          why: {
            type: "string" as const,
            description: "Brief explanation of why this swap works",
          },
        },
        required: ["swap", "for", "why"],
        description:
          "Optional one-tap swap suggestion — a single piece replacement that offers a meaningful variation",
      },
    },
  },
} as const;
