# Threads Topic & Hashtag Selection — Design Spec

**Date:** 2026-04-28  
**Project:** kise-proxy (Cloudflare Worker)  
**Scope:** `src/palette-handler.ts`, `src/types.ts`

---

## Problem

The post engine sends a daily email with a ready-to-copy Threads caption. Topic tags and hashtags are currently hard-coded per content type:

- `palette` → topic: "Design", hashtags: `#colorpalette #designinspiration #kise`
- `wabi-color` → topic: "Culture", hashtags: `#japanesecolor #和色 #kise`
- `reflection` → topic: "Mindset", hashtags: `#intentionalliving #wardrobephilosophy #kise`

These never adapt to the actual post content, missing engagement opportunities.

---

## Goal

After generating each post, use Claude to select:
1. The best Threads topic tag from the official enum, based on the specific post content
2. Up to 3 hashtags tailored to that post

The result appears in the email caption, ready to copy-paste.

---

## Approach

A second Claude call runs after content generation and before the email is sent. It receives the fully-generated post content as context and uses a structured tool call to return a topic tag + hashtags. The caption builders consume this output instead of the static maps.

No new infrastructure: same `ANTHROPIC_API_KEY`, no new KV keys, no new endpoints, no changes to `index.ts` or `wrangler.toml`.

---

## Data Flow

```
handleScheduled()
  └─ handle{Palette|Wabi|Reflection}Day()
       ├─ generate content  (existing)
       ├─ selectTopicAndHashtags(content)  ← NEW
       │    └─ Claude call with select_topic_hashtags tool
       ├─ store to KV  (existing)
       └─ send email with topic + hashtags in caption  (updated)
```

---

## New Type

```ts
// src/types.ts
export interface TopicSelection {
  topicTag: string;   // Threads topic tag enum value e.g. "FASHION_STYLE"
  hashtags: string[]; // up to 3 hashtags, each starting with #
}
```

---

## New Function: `selectTopicAndHashtags`

**Location:** `src/palette-handler.ts`

**Signature:**
```ts
async function selectTopicAndHashtags(
  content: DailyContent,
  env: Env
): Promise<TopicSelection>
```

**Claude tool schema:**
```ts
{
  name: "select_topic_hashtags",
  description: "Select the best Threads topic tag and up to 3 hashtags for this post.",
  input_schema: {
    topicTag: z.enum([THREADS_TOPIC_TAGS]),
    hashtags: z.array(z.string()).max(3)
  }
}
```

**Topic tag enum** (Threads-supported values relevant to KISE):
`FASHION_STYLE`, `ART_CULTURE`, `BEAUTY`, `INSPIRATIONAL_MOTIVATIONAL`, `LIFESTYLE`, `DIY_DESIGN_CRAFT`, `HEALTH`, `MENTAL_HEALTH`

Claude receives the full serialized post content (poetic name + description for palette, kanji + meaning + howToWear for wabi, text for reflection) and picks the most contextually relevant tag and hashtags.

**Prompt guidance to Claude:**
- Pick the single topic tag that best matches this specific post's content and tone
- Generate hashtags that are specific to the post (not generic brand tags)
- Always include `#kise` as the last hashtag
- Max 3 hashtags total

---

## Error Handling

If the Claude call fails or returns an invalid response, fall back to the existing static maps (`TOPIC` / `HASHTAGS`) so the email always sends. The static maps are demoted to fallback, not removed.

---

## Caption Builders

`buildPaletteCaption`, `buildWabiCaption`, `buildReflectionCaption` each gain a `selection: TopicSelection` parameter. The hard-coded hashtag string at the end of each caption is replaced with `selection.hashtags.join(' ')`.

The topic tag is included in the email as a separate line above the caption block:
```
Threads topic: FASHION_STYLE
```

---

## Files Changed

| File | Change |
|------|--------|
| `src/types.ts` | Add `TopicSelection` interface |
| `src/palette-handler.ts` | Add `selectTopicAndHashtags()`, update caption builders (add `selection` param), update `handle*Day()` to call selection before email |

---

## Out of Scope

- Threads API read calls (insights, post history)
- KV storage of post IDs
- New admin endpoints
- Auto-publishing to Threads
