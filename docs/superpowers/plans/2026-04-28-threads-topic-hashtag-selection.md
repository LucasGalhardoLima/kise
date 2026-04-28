# Threads Topic & Hashtag Selection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** After generating each daily post, use a Claude tool call to pick the best Threads topic tag and up to 3 hashtags based on the post content, then include them in the email caption.

**Architecture:** A new `selectTopicAndHashtags()` function in `palette-handler.ts` calls Claude with the generated post content and a `select_topic_hashtags` tool. The three caption builders gain a `TopicSelection` parameter. Each `handle*Day()` function calls selection after content generation and before sending the email. If the Claude call fails, it falls back to the existing static maps.

**Tech Stack:** TypeScript, Cloudflare Workers, `@anthropic-ai/sdk`, Vitest

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `src/types.ts` | Modify | Add `TopicSelection` interface |
| `src/palette-handler.ts` | Modify | Add `selectTopicAndHashtags()`, update caption builders and `handle*Day()` functions |
| `test/topic-selection.test.ts` | Create | Unit tests for `buildTopicSelectionPrompt`, caption builder signatures, and fallback logic |

---

## Task 1: Add `TopicSelection` type

**Files:**
- Modify: `kise-proxy/src/types.ts`

- [ ] **Step 1: Add the interface**

Open `kise-proxy/src/types.ts` and append after the `Env` interface:

```ts
export interface TopicSelection {
  topicTag: string;   // Threads topic tag enum value e.g. "FASHION_STYLE"
  hashtags: string[]; // up to 3 items, each starting with #
}
```

- [ ] **Step 2: Commit**

```bash
cd kise-proxy
git add src/types.ts
git commit -m "feat: add TopicSelection type"
```

---

## Task 2: Add `THREADS_TOPIC_TAGS` constant and `buildTopicSelectionPrompt`

**Files:**
- Modify: `kise-proxy/src/palette-handler.ts`
- Create: `kise-proxy/test/topic-selection.test.ts`

These are pure functions with no I/O — test them first.

- [ ] **Step 1: Write the failing test**

Create `kise-proxy/test/topic-selection.test.ts`:

```ts
import { describe, it, expect } from "vitest";
import {
  THREADS_TOPIC_TAGS,
  buildTopicSelectionPrompt,
} from "../src/palette-handler";
import type { DailyContent } from "../src/types";

describe("THREADS_TOPIC_TAGS", () => {
  it("contains FASHION_STYLE", () => {
    expect(THREADS_TOPIC_TAGS).toContain("FASHION_STYLE");
  });

  it("contains ART_CULTURE", () => {
    expect(THREADS_TOPIC_TAGS).toContain("ART_CULTURE");
  });

  it("contains INSPIRATIONAL_MOTIVATIONAL", () => {
    expect(THREADS_TOPIC_TAGS).toContain("INSPIRATIONAL_MOTIVATIONAL");
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
```

- [ ] **Step 2: Run to verify it fails**

```bash
cd kise-proxy
npx vitest run test/topic-selection.test.ts
```

Expected: FAIL — `THREADS_TOPIC_TAGS` and `buildTopicSelectionPrompt` not exported.

- [ ] **Step 3: Add the constant and function to `palette-handler.ts`**

Find the existing `TOPIC` and `HASHTAGS` constants near the top of the Topics & Hashtags section in `kise-proxy/src/palette-handler.ts`. Add **above** them:

```ts
// ---------------------------------------------------------------------------
// Threads topic tags (official enum, KISE-relevant subset)
// ---------------------------------------------------------------------------

export const THREADS_TOPIC_TAGS = [
  "FASHION_STYLE",
  "ART_CULTURE",
  "BEAUTY",
  "INSPIRATIONAL_MOTIVATIONAL",
  "LIFESTYLE",
  "DIY_DESIGN_CRAFT",
  "HEALTH",
  "MENTAL_HEALTH",
] as const;

export function buildTopicSelectionPrompt(content: DailyContent): string {
  const tagsLine = THREADS_TOPIC_TAGS.join(", ");

  let contentSummary: string;
  switch (content.type) {
    case "palette":
      contentSummary = `Type: color palette
City: ${content.city}
Temperature: ${content.temperature}°C, ${content.condition}
Palette name: ${content.poeticNameLocal} (${content.poeticNameEnglish})
Description: ${content.description}
Colors: ${content.colors.join(", ")}`;
      break;
    case "wabi-color":
      contentSummary = `Type: Japanese wabi color
Kanji: ${content.kanji} (${content.romanization})
Meaning: ${content.meaning}
Description: ${content.poeticDescription}
How to wear: ${content.howToWear}`;
      break;
    case "reflection":
      contentSummary = `Type: style reflection
Text: ${content.text}`;
      break;
  }

  return `You are a social media strategist for KISE, a fashion and Japanese aesthetics brand posting on Threads.

Given this post content, select:
1. The single best Threads topic tag from this list: ${tagsLine}
2. Up to 3 hashtags that are specific to this post's content. Always include #kise as the last hashtag.

Post content:
${contentSummary}`;
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd kise-proxy
npx vitest run test/topic-selection.test.ts
```

Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add src/palette-handler.ts test/topic-selection.test.ts
git commit -m "feat: add THREADS_TOPIC_TAGS constant and buildTopicSelectionPrompt"
```

---

## Task 3: Add `selectTopicAndHashtags` with fallback

**Files:**
- Modify: `kise-proxy/src/palette-handler.ts`
- Modify: `kise-proxy/test/topic-selection.test.ts`

- [ ] **Step 1: Write the failing test**

Append to `kise-proxy/test/topic-selection.test.ts`:

```ts
import { buildTopicFallback } from "../src/palette-handler";

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
```

Also update the import line at the top of the test file to include `buildTopicFallback`:

```ts
import {
  THREADS_TOPIC_TAGS,
  buildTopicSelectionPrompt,
  buildTopicFallback,
} from "../src/palette-handler";
```

- [ ] **Step 2: Run to verify it fails**

```bash
cd kise-proxy
npx vitest run test/topic-selection.test.ts
```

Expected: FAIL — `buildTopicFallback` not exported.

- [ ] **Step 3: Add `buildTopicFallback` and `selectTopicAndHashtags` to `palette-handler.ts`**

Add these two functions after `buildTopicSelectionPrompt`. Also add `TopicSelection` to the import from `./types`:

```ts
// Update the types import at the top of palette-handler.ts:
import type {
  DailyPalette,
  DailyWabiColor,
  DailyReflection,
  DailyContent,
  TopicSelection,
  Env,
} from "./types";
```

Then add the two functions after `buildTopicSelectionPrompt`:

```ts
export function buildTopicFallback(content: DailyContent): TopicSelection {
  switch (content.type) {
    case "palette":
      return {
        topicTag: "FASHION_STYLE",
        hashtags: ["#colorpalette", "#designinspiration", "#kise"],
      };
    case "wabi-color":
      return {
        topicTag: "ART_CULTURE",
        hashtags: ["#japanesecolor", "#和色", "#kise"],
      };
    case "reflection":
      return {
        topicTag: "INSPIRATIONAL_MOTIVATIONAL",
        hashtags: ["#intentionalliving", "#wardrobephilosophy", "#kise"],
      };
  }
}

export async function selectTopicAndHashtags(
  content: DailyContent,
  env: Env
): Promise<TopicSelection> {
  try {
    const client = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });

    const response = await client.messages.create({
      model: "claude-sonnet-4-20250514",
      max_tokens: 256,
      system: buildTopicSelectionPrompt(content),
      tools: [
        {
          name: "select_topic_hashtags",
          description:
            "Select the best Threads topic tag and up to 3 hashtags for this post.",
          input_schema: {
            type: "object" as const,
            properties: {
              topicTag: {
                type: "string",
                enum: [...THREADS_TOPIC_TAGS],
                description: "The Threads topic tag that best fits this post.",
              },
              hashtags: {
                type: "array",
                items: { type: "string" },
                maxItems: 3,
                description:
                  "Up to 3 hashtags. Each must start with #. Always include #kise last.",
              },
            },
            required: ["topicTag", "hashtags"],
          },
        },
      ],
      tool_choice: { type: "tool", name: "select_topic_hashtags" },
      messages: [
        {
          role: "user",
          content: "Select the topic tag and hashtags for this post.",
        },
      ],
    });

    const toolBlock = response.content.find(
      (block) => block.type === "tool_use" && block.name === "select_topic_hashtags"
    );

    if (!toolBlock || toolBlock.type !== "tool_use") {
      return buildTopicFallback(content);
    }

    const input = toolBlock.input as { topicTag: string; hashtags: string[] };
    return {
      topicTag: input.topicTag,
      hashtags: input.hashtags.slice(0, 3),
    };
  } catch {
    return buildTopicFallback(content);
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd kise-proxy
npx vitest run test/topic-selection.test.ts
```

Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add src/palette-handler.ts test/topic-selection.test.ts
git commit -m "feat: add buildTopicFallback and selectTopicAndHashtags"
```

---

## Task 4: Update caption builders to accept `TopicSelection`

**Files:**
- Modify: `kise-proxy/src/palette-handler.ts`
- Modify: `kise-proxy/test/topic-selection.test.ts`

- [ ] **Step 1: Write the failing tests**

Append to `kise-proxy/test/topic-selection.test.ts`:

```ts
import {
  THREADS_TOPIC_TAGS,
  buildTopicSelectionPrompt,
  buildTopicFallback,
  buildPaletteCaption,
  buildWabiCaption,
  buildReflectionCaption,
} from "../src/palette-handler";
import type { TopicSelection } from "../src/types";

const mockSelection: TopicSelection = {
  topicTag: "FASHION_STYLE",
  hashtags: ["#colorstory", "#wardrobegoals", "#kise"],
};

describe("buildPaletteCaption", () => {
  it("includes dynamic hashtags from selection", () => {
    const palette: DailyContent = {
      type: "palette",
      city: "Tokyo",
      temperature: 18,
      condition: "clear sky",
      poeticNameLocal: "霞色",
      poeticNameEnglish: "Haze",
      description: "A soft grey morning.",
      colors: ["#B0B0B0", "#C8C8C8"],
    };
    const caption = buildPaletteCaption(palette as any, mockSelection);
    expect(caption).toContain("#colorstory");
    expect(caption).toContain("#wardrobegoals");
    expect(caption).toContain("#kise");
    expect(caption).not.toContain("#colorpalette");
  });
});

describe("buildWabiCaption", () => {
  it("includes dynamic hashtags from selection", () => {
    const color: DailyContent = {
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
    const caption = buildWabiCaption(color as any, wabiSelection);
    expect(caption).toContain("#japaneseaesthetics");
    expect(caption).toContain("#kise");
    expect(caption).not.toContain("#japanesecolor");
  });
});

describe("buildReflectionCaption", () => {
  it("includes dynamic hashtags from selection", () => {
    const reflection: DailyContent = {
      type: "reflection",
      text: "Style is confidence.",
    };
    const reflectionSelection: TopicSelection = {
      topicTag: "INSPIRATIONAL_MOTIVATIONAL",
      hashtags: ["#slowfashion", "#intentionalstyle", "#kise"],
    };
    const caption = buildReflectionCaption(reflection as any, reflectionSelection);
    expect(caption).toContain("#slowfashion");
    expect(caption).toContain("#kise");
    expect(caption).not.toContain("#intentionalliving");
  });
});
```

Also update the import to include the caption builders:

```ts
import {
  THREADS_TOPIC_TAGS,
  buildTopicSelectionPrompt,
  buildTopicFallback,
  buildPaletteCaption,
  buildWabiCaption,
  buildReflectionCaption,
} from "../src/palette-handler";
```

- [ ] **Step 2: Run to verify they fail**

```bash
cd kise-proxy
npx vitest run test/topic-selection.test.ts
```

Expected: FAIL — caption builders not exported / don't accept `TopicSelection`.

- [ ] **Step 3: Update caption builders in `palette-handler.ts`**

Find the three caption functions and update them. Make them exported and add the `selection` parameter:

```ts
// Replace buildPaletteCaption
export function buildPaletteCaption(p: DailyPalette, selection: TopicSelection): string {
  return `${p.poeticNameLocal} — ${p.poeticNameEnglish}.

${p.city}, ${p.temperature}°C, ${p.condition}.
${p.description}

${p.colors.join(" · ")}

${selection.hashtags.join(" ")}`;
}

// Replace buildWabiCaption
export function buildWabiCaption(c: DailyWabiColor, selection: TopicSelection): string {
  return `${c.kanji} (${c.romanization}) — ${c.meaning}.

${c.poeticDescription}

${c.hex}. ${c.howToWear}

${selection.hashtags.join(" ")}`;
}

// Replace buildReflectionCaption
export function buildReflectionCaption(r: DailyReflection, selection: TopicSelection): string {
  return `${r.text}

${selection.hashtags.join(" ")}`;
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd kise-proxy
npx vitest run test/topic-selection.test.ts
```

Expected: all tests PASS.

- [ ] **Step 5: Run the full test suite to catch any regressions**

```bash
cd kise-proxy
npx vitest run
```

Expected: all existing tests still PASS (caption builders were private before — no external callers to break).

- [ ] **Step 6: Commit**

```bash
git add src/palette-handler.ts test/topic-selection.test.ts
git commit -m "feat: update caption builders to accept TopicSelection"
```

---

## Task 5: Wire `selectTopicAndHashtags` into `handle*Day` functions and update email

**Files:**
- Modify: `kise-proxy/src/palette-handler.ts`

This task has no new unit tests — the `selectTopicAndHashtags` integration is tested manually via `/admin/trigger`. The caption builder tests in Task 4 already cover correctness of the output.

- [ ] **Step 1: Update `handlePaletteDay`**

Find `handlePaletteDay` in `palette-handler.ts` and update it:

```ts
export async function handlePaletteDay(env: Env): Promise<void> {
  const daysSinceEpoch = Math.floor(Date.now() / 86_400_000);
  const city = CITIES[daysSinceEpoch % CITIES.length];
  const weather = await fetchCityWeather(city, env.OPENWEATHER_API_KEY);
  const palette = await generatePalette(city, weather, env);
  const selection = await selectTopicAndHashtags(palette, env);

  await env.DAILY_PICK.put("daily-pick", JSON.stringify(palette), {
    expirationTtl: 345600,
  });

  await env.DAILY_PICK.put("daily-content", JSON.stringify(palette), {
    expirationTtl: 86400,
  });

  await sendPaletteEmail(palette, selection, env);
  console.log(`Palette: ${palette.poeticNameLocal} (${city}) — topic: ${selection.topicTag}`);
}
```

- [ ] **Step 2: Update `handleWabiDay`**

```ts
export async function handleWabiDay(env: Env): Promise<void> {
  const day = new Date().getUTCDay();
  const color = getWabiColorForToday(day);
  const selection = await selectTopicAndHashtags(color, env);

  await env.DAILY_PICK.put("daily-content", JSON.stringify(color), {
    expirationTtl: 86400,
  });

  await sendWabiEmail(color, selection, env);
  console.log(`和色: ${color.kanji} (${color.romanization}) — topic: ${selection.topicTag}`);
}
```

- [ ] **Step 3: Update `handleReflectionDay`**

```ts
export async function handleReflectionDay(env: Env): Promise<void> {
  const reflection = getReflectionForToday();
  const selection = await selectTopicAndHashtags(reflection, env);

  await env.DAILY_PICK.put("daily-content", JSON.stringify(reflection), {
    expirationTtl: 86400,
  });

  await sendReflectionEmail(reflection, selection, env);
  console.log(`Reflection: ${reflection.text.slice(0, 50)}… — topic: ${selection.topicTag}`);
}
```

- [ ] **Step 4: Update `sendPaletteEmail` signature and caption call**

Find `sendPaletteEmail` and add `selection: TopicSelection` as the second parameter:

```ts
async function sendPaletteEmail(p: DailyPalette, selection: TopicSelection, env: Env): Promise<void> {
  const caption = buildPaletteCaption(p, selection);
  // ... rest unchanged
```

Also update the topic label in the email inner block. Find this line inside `sendPaletteEmail`:

```ts
<span style="font-size:10px;color:#A3B18A;letter-spacing:0.15em;text-transform:uppercase">DAILY PALETTE · ${TOPIC["palette"]}</span>
```

Replace with:

```ts
<span style="font-size:10px;color:#A3B18A;letter-spacing:0.15em;text-transform:uppercase">DAILY PALETTE · ${selection.topicTag.replace(/_/g, " ")}</span>
```

- [ ] **Step 5: Update `sendWabiEmail` signature and caption call**

```ts
async function sendWabiEmail(c: DailyWabiColor, selection: TopicSelection, env: Env): Promise<void> {
  const caption = buildWabiCaption(c, selection);
  // ... rest unchanged
```

Find the topic label line:

```ts
<span style="font-size:10px;color:#A3B18A;letter-spacing:0.15em;text-transform:uppercase">和色 — JAPANESE COLOR · ${TOPIC["wabi-color"]}</span>
```

Replace with:

```ts
<span style="font-size:10px;color:#A3B18A;letter-spacing:0.15em;text-transform:uppercase">和色 — JAPANESE COLOR · ${selection.topicTag.replace(/_/g, " ")}</span>
```

- [ ] **Step 6: Update `sendReflectionEmail` signature and caption call**

```ts
async function sendReflectionEmail(r: DailyReflection, selection: TopicSelection, env: Env): Promise<void> {
  const caption = buildReflectionCaption(r, selection);  // add this line if missing
  // ... rest unchanged
```

Find the topic label line:

```ts
<span style="font-size:10px;color:#A3B18A;letter-spacing:0.15em;text-transform:uppercase">REFLECTION · ${TOPIC["reflection"]}</span>
```

Replace with:

```ts
<span style="font-size:10px;color:#A3B18A;letter-spacing:0.15em;text-transform:uppercase">REFLECTION · ${selection.topicTag.replace(/_/g, " ")}</span>
```

Also update the `captionBlock` call to use `caption` (since `sendReflectionEmail` didn't have a `caption` variable before — it passed `r.text` directly). Ensure:

```ts
${captionBlock(caption, "CAPTION — TEXT ONLY POST")}
```

- [ ] **Step 7: Remove the now-unused static `TOPIC` and `HASHTAGS` maps**

Delete these two constants from `palette-handler.ts` (they are replaced by `buildTopicFallback`):

```ts
// DELETE these:
const TOPIC: Record<string, string> = { ... };
const HASHTAGS: Record<string, string> = { ... };
```

- [ ] **Step 8: Run the full test suite**

```bash
cd kise-proxy
npx vitest run
```

Expected: all tests PASS.

- [ ] **Step 9: Commit**

```bash
git add src/palette-handler.ts
git commit -m "feat: wire selectTopicAndHashtags into scheduled handlers and emails"
```

---

## Task 6: Manual smoke test via `/admin/trigger`

**Files:** none

- [ ] **Step 1: Start the dev worker**

```bash
cd kise-proxy
npx wrangler dev
```

- [ ] **Step 2: Trigger the scheduled handler**

```bash
curl -X POST http://localhost:8787/admin/trigger \
  -H "Authorization: Bearer <your-ADMIN_TRIGGER_KEY-from-wrangler-dev-output>"
```

Expected: `{"ok":true}` — and in the wrangler dev logs you should see a line like:
```
Palette: 霞色 (Tokyo) — topic: FASHION_STYLE
```

- [ ] **Step 3: Verify the email content**

Check your inbox. The email caption block should now contain dynamic hashtags (not the old hard-coded ones) and the topic label in the header should read e.g. `DAILY PALETTE · FASHION STYLE`.

- [ ] **Step 4: Commit if any fixes were needed, then tag**

```bash
git add -p
git commit -m "fix: <describe any fix>"
```
