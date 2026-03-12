# KISE 着せ — Design Specification

**Your wardrobe, with intention.**

A native iOS app that dresses you with purpose — combining your pieces, style, local weather, and daily context to suggest outfits that make sense.

---

## Vision

KISE treats the wardrobe as a living system that evolves with the person. It's not "what to wear today" — it's "how to intentionally build the way you present yourself to the world."

The app starts as a **wardrobe consultant** and evolves into a **personal shopper** — helping not only to combine what you have, but to intelligently buy what's missing.

---

## Primary Persona

**Lucas, 28, developer.** Went through significant weight loss (XXL → S/M). Rebuilding his wardrobe consciously — pieces should work together. Follows Old Money / minimalist style influencers (Daniel Simmons, Tim Dessaint) and uses their looks as reference when dressing intentionally. Doesn't want to accumulate — wants intention.

**Core needs:**
- Know that what he's wearing matches and fits the context
- Build a lean but versatile wardrobe
- Not overthink getting dressed in the morning
- Feel confidence in the process of rebuilding personal image

---

## Positioning

KISE is not a "look suggestion by AI" app. It's a wardrobe partner for people who dress with intention. The real value is closer to a personal image consultant in your pocket.

**The name:** From Japanese 着せ (kiseru) — "to dress someone." The app dresses you. Four letters, two syllables, global. Phonetically, 気 (ki — spirit/energy) + 背 (se — posture/bearing) add layers of meaning to the brand storytelling.

**Aesthetic:** Japanese functional minimalism. Clean typography with light weight, generous negative space, reduced palette, off-white background. Visual references: MUJI, UNIQLO, COS, Arket, Aesop. The branding breathes the same culture that inspires the Japanese color dictionaries in the product roadmap.

**Japanese language in branding — identity, not interface:**

Japanese appears in deliberate, decorative moments — never in navigation, buttons, or any text the user needs to read to use the app.

Where to use:
- **Branding:** "KISE 着せ" as visual signature on splash screen, App Store listing, and website. The kanji beside the name works as a seal — users don't need to read it, they need to recognize it.
- **Easter eggs and craft details:** Subtle moments that reward those who notice. E.g., after completing onboarding, a brief transition with 整う (tonou — "in harmony"). Those who notice are delighted. Those who don't miss nothing.
- **Color dictionaries feature (V2):** Japanese color harmony names keep their original nomenclature — 桜鼠 (sakura-nezumi), 藍色 (ai-iro). Here, Japanese is content, not decoration.

Where never to use:
- Navigation, menus, form labels, action buttons, onboarding — 100% in the device's local language.

---

## MVP Scope

Three systems:

1. **Style onboarding** — select style archetypes that define the engine's taste
2. **Piece registration** — manually add garments with attributes, matched to pre-generated catalog images
3. **Daily suggestions** — LLM-powered, context-aware outfit combinations

Additionally, **basic feedback** (like/dislike on suggestions) is included in MVP — it's lightweight and essential for the engine to learn. Full feedback micro-interactions (dislike reasons, piece-specific feedback) are post-MVP.

Everything else (wardrobe management, repetition tracking, Vision recognition) is post-MVP.

---

## Architecture Overview

```
┌─────────────────────────────────────────────┐
│                 iOS App (SwiftUI)            │
│                                             │
│  ┌───────────┐  ┌──────────┐  ┌──────────┐  │
│  │ Onboarding│  │ Wardrobe │  │Suggestion│  │
│  │   Flow    │  │ Manager  │  │  View    │  │
│  └───────────┘  └──────────┘  └──────────┘  │
│         │            │             │         │
│         ▼            ▼             ▼         │
│  ┌──────────────────────────────────────┐   │
│  │        Local Data Layer (SwiftData)   │   │
│  │  • Style preferences                 │   │
│  │  • Wardrobe pieces + attributes       │   │
│  │  • Suggestion history + feedback      │   │
│  │  • Cached suggestions                 │   │
│  └──────────────────────────────────────┘   │
│         │                    │               │
│  ┌──────┴──────┐    ┌───────┴────────┐      │
│  │  WeatherKit  │    │ Catalog Image  │      │
│  │  (on-device) │    │ Asset Library  │      │
│  └─────────────┘    └────────────────┘      │
└──────────────┬──────────────────────────────┘
               │ HTTPS (suggestion requests only)
       ┌───────▼───────┐
       │  Proxy Server  │
       │  (thin layer)  │
       │  • API key mgmt │
       │  • Rate limiting │
       │  • No data stored│
       └───────┬───────┘
               │
       ┌───────▼───────┐
       │  Claude API    │
       │  (Anthropic)   │
       └───────────────┘
```

**Key principles:**
- All user data lives on-device in SwiftData. Nothing leaves the phone except the suggestion request payload.
- The proxy server is stateless — receives request, forwards to Claude, returns response. No database, no user accounts, no sessions.
- Catalog images are bundled assets — no network calls for images.
- WeatherKit is Apple-managed — the framework handles weather API calls transparently, but does require network connectivity. Free tier: 500K calls/month per Apple Developer account.
- Two network dependencies: WeatherKit (Apple-managed) and Claude API via proxy. Both mitigated by background prefetch and caching.
- **iOS 26 progressive enhancement:** On devices running iOS 26+, the app uses Apple's Foundation Models framework as an on-device fallback for suggestions when offline, and applies Liquid Glass effects to custom views. On iOS 17-25, the app works fully via the Claude API path with standard UI styling.

---

## Data Model

### StyleProfile
| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key |
| archetypes | [String] | e.g., ["old-money", "minimalist"]. Minimum 1, no maximum. |
| createdAt | Date | |
| updatedAt | Date | |

### GarmentPiece
| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key |
| category | GarmentCategory | Enum: tShirt, shirt, polo, sweater, hoodie, jacket, coat, jeans, chinos, shorts, shoes |
| color | String | e.g., "navy", "white", "olive" |
| colorHex | String | Hex value for UI display |
| fit | Fit | Enum: slim, regular, relaxed, straight, oversized |
| material | String | e.g., "cotton", "linen", "wool", "denim" |
| weight | FabricWeight | Enum: light, mid, heavy. Primary driver for weather matching. |
| formality | Formality | Enum: casual, smartCasual, formal |
| catalogImageID | String | Maps to bundled asset |
| userPhotoPath | String? | Fallback if no catalog match |
| isActive | Bool | In rotation or archived |
| createdAt | Date | |

### OutfitSuggestion
| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key |
| pieces | [GarmentPiece] | The outfit combination |
| occasion | Occasion? | Enum: everyday, meeting, dateNight, nightOut |
| weather | WeatherSnapshot | Conditions at time of suggestion |
| reasoning | String | Claude's explanation of why this works |
| layeringNote | String? | e.g., "Bring this jacket for the morning" |
| alternativePiece | AlternativeSwap? | One-tap swap option |
| suggestedAt | Date | |
| feedback | Feedback? | |

### Feedback
| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key |
| liked | Bool | |
| dislikeReason | String? | "colors", "style", "occasion", "piece" |
| dislikedPieceID | UUID? | Specific piece that felt wrong |
| createdAt | Date | |

### WeatherSnapshot
| Field | Type | Description |
|-------|------|-------------|
| temperature | Double | Celsius |
| feelsLike | Double | |
| humidity | Double | |
| windSpeed | Double | |
| condition | String | "clear", "rain", "cloudy" |
| hourlyForecast | [HourlyEntry] | For transition days |

**Key decisions:**
- `FabricWeight` is the main driver for weather matching — not the material itself. Linen is "light", wool is "heavy", cotton can be either.
- `Formality` is on the piece, not the outfit. The engine decides if formality levels across pieces are compatible.
- `catalogImageID` maps to a bundled asset. During registration, the app finds the best match based on category + color + fit.
- `reasoning` from Claude is stored — becomes valuable for the future personal shopper.
- Feedback is lightweight — bool + optional reason. Enough to feed back into Claude's context.
- The `Feedback` model includes `dislikeReason` and `dislikedPieceID` fields as forward-looking schema design. **In MVP, only `liked` (Bool) is populated.** The additional fields exist so the schema doesn't need migration when advanced feedback is added post-MVP.
- **Payload serialization:** `Feedback.liked = true` serializes as `"feedback": "liked"` in the request payload. `Feedback.liked = false` serializes as `"feedback": "disliked"`. Post-MVP, when dislike reasons are captured, the format expands to `"feedback": {"liked": false, "reason": "colors", "piece_id": "uuid"}`.

---

## Style Onboarding

Single screen, scrollable moodboard. The user selects style archetypes that resonate.

**Archetypes for v1:**
- **Old Money** — structured, neutral palette, quality fabrics, understated
- **Minimalist** — clean lines, monochrome, few elements, intentional
- **Smart Casual** — polished but relaxed, versatile layering
- **Streetwear** — relaxed fits, graphic elements, sneaker-forward
- **Classic** — timeless, balanced proportions, conventional combinations
- **Scandinavian** — muted tones, functional, texture-focused

Each archetype is represented by a visual card — a curated reference image (mood/collage feel) with the archetype name. No descriptions — the visual does the talking.

**Selection:** 1 or more archetypes. No maximum. Multiple selection allows blending (Old Money + Minimalist = Tim Dessaint territory). The engine uses the selected combination to weight suggestions.

**After onboarding:** user lands on piece registration. Style profile is editable from settings at any time.

---

## Piece Registration

Presented as a modal/sheet over the wardrobe screen. Step-by-step attribute selection.

**Flow:**

1. **Pick category** — grid of garment types
2. **Select attributes** — sequential, one at a time:
   - **Color** — palette grid with named swatches (predefined colors that map to catalog images)
   - **Fit** — slim / regular / relaxed / straight / oversized (visual icons, filtered by category — jeans show straight, t-shirts don't)
   - **Material** — filtered by category (no "denim" for a sweater)
   - **Fabric weight** — light / mid / heavy (auto-suggested based on material, user can override)
   - **Formality** — casual / smart-casual / formal (auto-suggested based on category, user can override)
3. **Catalog image match** — app combines category + color + fit to find the closest bundled asset. Shows to user: "Does this look like your piece?"
   - Yes → piece saved
   - Not quite → user takes their own photo
4. **Piece added to wardrobe.** Repeat or finish.

**Design notes:**
- Each step is a single screen/card — no long forms
- Auto-suggestions for weight and formality reduce decisions
- ~15-20 seconds per piece
- No minimum or maximum number of pieces

---

## Suggestion Engine (Claude Integration)

### Daily Flow

1. App has a prefetched suggestion (generated via background refresh)
2. User opens app, sees outfit immediately — zero wait
3. If no prefetched suggestion exists, request fires with ~2-3s loading state

### Request Payload (sent to Claude via proxy)

```json
{
  "style_archetypes": ["old-money", "minimalist"],
  "boldness": 0.3,
  "occasion": "everyday",
  "weather": {
    "temperature": 22,
    "feels_like": 20,
    "humidity": 65,
    "wind": 12,
    "condition": "partly-cloudy",
    "hourly_forecast": [
      {"hour": 7, "temp": 14, "condition": "clear"},
      {"hour": 12, "temp": 24, "condition": "sunny"},
      {"hour": 18, "temp": 19, "condition": "cloudy"}
    ]
  },
  "wardrobe": [
    {"id": "uuid", "category": "jeans", "color": "blue", "fit": "straight", "material": "denim", "weight": "mid", "formality": "casual"}
  ],
  "recent_suggestions": [
    {"date": "2026-03-10", "piece_ids": ["uuid1", "uuid2", "uuid3"], "feedback": "liked"},
    {"date": "2026-03-09", "piece_ids": ["uuid4", "uuid5"], "feedback": "disliked", "reason": "colors"}
  ]
}
```

### Response from Claude

```json
{
  "pieces": ["uuid-jeans", "uuid-white-tee", "uuid-navy-jacket"],
  "reasoning": "Clean layered look — white base with navy outerwear works within your minimalist profile. The jacket covers the cooler morning (14°C) and can come off by midday.",
  "layering_note": "Morning will be cold — the jacket isn't optional until noon.",
  "alternative_piece": {
    "swap": "uuid-navy-jacket",
    "for": "uuid-gray-cardigan",
    "why": "If you want something more relaxed, the cardigan gives the same warmth with a softer silhouette."
  }
}
```

### System Prompt Strategy

The Claude API is called with `tool_use` to enforce structured JSON output. The system prompt defines KISE's persona, style knowledge, and constraints:

```
You are KISE, a personal wardrobe consultant. You help users dress with intention
by selecting outfit combinations from their registered wardrobe pieces.

STYLE CONTEXT:
The user's style archetypes are provided in the request. These define the
"outfit formulas" you should follow:
- Old Money: structured silhouettes, neutral palette (navy, cream, olive, gray),
  quality fabrics, understated. Think: chinos + knit + structured outerwear.
- Minimalist: clean lines, monochrome or tonal, few elements, intentional.
  Think: single-tone layers with texture contrast.
- [Each archetype has its own style brief included dynamically]

BOLDNESS:
A value from 0.0 (safe/classic) to 1.0 (creative/unexpected).
- 0.0-0.3: Stick to proven combinations within the archetype. No surprises.
- 0.4-0.6: Introduce subtle variations — unexpected color pairings, mixing
  archetype elements.
- 0.7-1.0: Push boundaries — cross-archetype mixing, bold color plays,
  unconventional formality combinations that still work.

HARD RULES (never violate):
- Fabric weight must match weather. Never suggest heavy wool when it's 30°C.
- If hourly forecast shows temperature swings >10°C, suggest a removable layer
  and include a layering_note.

SOFT RULES (use judgment):
- Formality can be mixed if pieces bridge the gap (smart pants + dress shirt = OK).
- Monochrome is fine with texture or shade variation.
- Avoid suggesting the same outfit as recent_suggestions unless 10+ days have passed.
- If the user disliked a recent suggestion, avoid the specific pattern they rejected.

OUTPUT: Use the provided tool to return your suggestion. Always include reasoning
(1-2 sentences explaining why this combination works). Include layering_note only
when weather transitions warrant it. Include alternative_piece only when there's
a meaningful swap available.

If the wardrobe has too few pieces to form a coherent outfit for the given occasion
and weather, return what you can and explain in reasoning what's missing.
```

The system prompt lives in the proxy server, not the app binary. This allows prompt iteration without App Store updates. Style archetype briefs are modular — each is a paragraph that gets included based on the user's selections. The proxy assembles the full prompt from the base template + relevant archetype briefs before forwarding to Claude.

A Claude tool definition enforces the response schema:

```json
{
  "name": "suggest_outfit",
  "description": "Suggest a daily outfit from the user's wardrobe",
  "input_schema": {
    "type": "object",
    "required": ["pieces", "reasoning"],
    "properties": {
      "pieces": {
        "type": "array",
        "items": {"type": "string"},
        "description": "Array of garment piece UUIDs forming the outfit"
      },
      "reasoning": {
        "type": "string",
        "description": "1-2 sentence explanation of why this combination works"
      },
      "layering_note": {
        "type": "string",
        "description": "Optional note about layering for weather transitions"
      },
      "alternative_piece": {
        "type": "object",
        "properties": {
          "swap": {"type": "string", "description": "UUID of piece to replace"},
          "for": {"type": "string", "description": "UUID of alternative piece"},
          "why": {"type": "string", "description": "Why this swap works"}
        }
      }
    }
  }
}
```

### Boldness Scale

The boldness parameter is a Float from 0.0 to 1.0:
- **Default: 0.3** — safe, proven combinations
- **0.0-0.3 (Safe):** Classic pairings within the archetype. No risks.
- **0.4-0.6 (Moderate):** Subtle variations — an unexpected color accent, mixing textures more freely.
- **0.7-1.0 (Bold):** Cross-archetype blending, unconventional pairings, creative formality mixing.

The slider on the suggestion screen maps to this range. The value is sent per-request and Claude interprets it via the system prompt instructions above.

### Key Decisions

- **Full wardrobe sent every request.** With a personal wardrobe (5-50 pieces), token count is small. No pre-filtering needed. Let Claude see everything and choose.
- **Recent suggestions + feedback included.** This is the personalization — Claude sees what was liked/disliked and adjusts. Avoids repeating recent outfits unless enough time has passed.
- **`alternative_piece`** gives a one-tap swap without regenerating the entire outfit.
- **`reasoning`** displayed in UI — builds trust and teaches the user about style.
- **`layering_note`** handles transition-day scenarios (cold morning, warm afternoon).
- **Boldness slider** lives on the suggestion screen (not onboarding). Per-suggestion control alongside the occasion selector. Pull down to access, invisible by default.

### Background Prefetch

- iOS Background App Refresh triggers the suggestion request overnight or when conditions change
- Suggestion cached locally, ready for instant display
- If weather changes significantly between prefetch and app open, a fresh request fires

### Proxy Server

- Minimal — receives request, attaches Claude API key, forwards, returns response
- Cloudflare Worker or small server on Railway/Fly.io
- No database, no user tracking

**Security:**
- **Apple App Attest** — the proxy validates that requests originate from a legitimate app installation using Apple's DeviceCheck / App Attest framework. This prevents unauthorized clients from using the proxy as an open relay to the Claude API.
- **Rate limiting** — per attested device, max 10 requests/day (covers normal use of 1-3 suggestions plus regenerations). Prevents abuse even from legitimate installations.
- **No user accounts** — authentication is device-level, not identity-level. Consistent with the privacy-first approach.

### Cost Estimation

Based on Claude Sonnet (recommended for cost/quality balance at this usage pattern):
- **Tokens per request:** ~800-1200 input (wardrobe + weather + history), ~200-300 output. ~1500 tokens total.
- **Cost per suggestion:** ~$0.005-0.01
- **Per user per day:** 1-3 suggestions = $0.005-0.03/day
- **Per user per month:** ~$0.15-0.90
- **1,000 active users:** ~$150-900/month

For the personal testing phase, cost is negligible. At scale, the free tier remains viable up to ~5,000 users before monetization becomes necessary.

Model selection (Sonnet vs Opus vs Haiku) can be adjusted based on suggestion quality during testing. Start with Sonnet as the baseline.

---

## Error Handling

### Network Failures (Claude API)

| Scenario | Behavior |
|----------|----------|
| Prefetch succeeded, app opens normally | Show cached suggestion. No network needed. |
| Prefetch failed, app opens with connectivity | Fire live request. Show loading state (skeleton cards with subtle pulse animation, ~2-3s). |
| No prefetch, no connectivity | Show last successful suggestion with a subtle "from yesterday" indicator. If no suggestion has ever been generated, show the wardrobe screen instead. |
| Live request fails (timeout, 5xx) | Single retry after 2s. If retry fails, show last cached suggestion or wardrobe screen. No error dialogs — degrade gracefully. |
| Claude returns malformed JSON | Retry once. If still malformed, fall back to cached suggestion. Log the error for debugging. |
| Claude references unknown piece UUID | Filter out unknown UUIDs. If remaining pieces still form a viable outfit, show it. Otherwise treat as malformed and retry. |

### Weather Failures

| Scenario | Behavior |
|----------|----------|
| WeatherKit permission denied | Prompt user to enable location in settings. Suggestions still work without weather — Claude receives no weather context and suggests based on style + occasion only. |
| WeatherKit API failure | Use last cached weather data if <6 hours old. Otherwise, omit weather from the request. |

### Wardrobe Edge Cases

| Scenario | Behavior |
|----------|----------|
| Empty wardrobe (0 pieces) | Home screen shows a welcoming prompt: "Add your first pieces to get started" with a button to the registration flow. No suggestion is requested. |
| Too few pieces (<3) | Show the pieces the user has with a message: "Add a few more pieces and I'll start suggesting outfits." Minimum 3 pieces to trigger the suggestion engine (at least 1 top + 1 bottom + 1 footwear OR 1 top + 1 bottom). |
| Only one category registered | Claude works with what's available and explains in reasoning what's missing: "Great top choice — add some bottoms and I can build full outfits." |

### Background Prefetch Reliability

iOS Background App Refresh is not guaranteed — iOS throttles infrequently-used apps. Mitigation:
- Accept that the 2-3s loading state will be common, especially in early usage. Design the loading state to feel premium, not broken (skeleton cards, not a spinner).
- As the user opens the app daily, iOS learns the pattern and increases refresh frequency.
- The "significant weather change" threshold for re-fetching: temperature delta >5°C or condition category change (e.g., clear → rain) between cached and current weather.

---

## Catalog Images

### Approach

Pre-generated library of ~500-800 catalog-quality garment images, bundled as app assets.

### Generation Pipeline

1. **Taxonomy definition** — study Zara and H&M product catalogs to define garment types, color variations, and fit variations that cover the real-world wardrobe
2. **AI generation** — use high-quality image generation model (Midjourney, DALL-E, or fine-tuned Stable Diffusion) with prompts targeting the catalog aesthetic: flat lay, neutral background, studio lighting
3. **Quality curation** — manual review for consistency, accuracy, and aesthetic standard
4. **Ship as assets** — bundled in the app binary, no runtime generation needed

### Coverage Strategy

- ~10-12 garment categories
- ~12-15 predefined colors (see below)
- ~2-3 fits per category (not all fits apply to all categories)
- Total: ~400-600 images covering ~95% of real wardrobe pieces
- User photo fallback for the remaining 5%

### Predefined Color Palette

Colors are a closed set — the user picks from these during registration, and each maps to a catalog image asset key:

| Color | Hex | Notes |
|-------|-----|-------|
| White | #FFFFFF | |
| Off-White / Cream | #F5F0E8 | |
| Light Gray | #C8C8C8 | |
| Charcoal | #4A4A4A | |
| Black | #1A1A1A | |
| Navy | #1B2A4A | |
| Light Blue | #A4C8E8 | |
| Olive | #6B7F4E | |
| Khaki / Tan | #C4A46C | |
| Brown | #6B4226 | |
| Burgundy | #722F37 | |
| Terracotta | #C75B39 | |
| Sage | #9CAF88 | |
| Indigo | #3F5277 | |
| Camel | #C19A6B | |

This palette covers the vast majority of real wardrobe pieces, especially within the Old Money / Minimalist / Classic archetypes. Bold colors (red, yellow, pink) can be added as the archetype library expands.

### Image Asset Key Convention

Catalog images are keyed as: `{category}_{color}_{fit}`

Examples:
- `tshirt_white_slim`
- `jeans_indigo_straight`
- `jacket_navy_regular`

During registration, the app performs an exact lookup. If no exact match exists (e.g., `polo_terracotta_oversized` was not generated), the app falls back to the closest available match (same category + color, default fit) and asks the user to confirm. If still not representative, the user takes their own photo.

### App Size Budget

Target: **< 200MB total app size** (including binary + assets). At ~200-400KB per optimized JPEG, 500 images = ~100-200MB. Use HEIC format where possible for ~40% size reduction. Consider on-demand asset downloads (iOS On-Demand Resources) if the total exceeds the target.

### Aesthetic Standard

Zara/H&M product photography style:
- Flat lay on neutral background
- Clean studio lighting
- No models, no lifestyle context
- Consistent framing across all garment types

---

## UI Structure

### Screen 1: Suggestion (Home)

The morning screen. Full outfit displayed as catalog image cards arranged vertically — top piece at top, bottom piece below, shoes at bottom. Clean, editorial layout.

- Reasoning text below the outfit (1-2 sentences from Claude)
- Layering note if applicable (subtle callout)
- Like / Dislike buttons (single tap each). MVP captures the boolean only. Detailed dislike reasons (colors, style, specific piece) are post-MVP.
- Pull down to reveal: occasion selector + boldness slider
- "Regenerate" button — different suggestion, same parameters
- Alternative piece swap as subtle "try this instead" on one card

### Screen 2: Wardrobe

Grid view of all pieces — catalog images in a clean grid. Category tabs at top (All, Tops, Bottoms, Outerwear, Shoes).

**Tab → Category mapping:**
- Tops: tShirt, shirt, polo, sweater, hoodie
- Bottoms: jeans, chinos, shorts
- Outerwear: jacket, coat
- Shoes: shoes

Accessories are out of MVP scope. Adding them later requires a `subCategory` field (belt, watch, scarf, hat) since the generic `accessories` category is too broad for Claude to reason about. This is a post-MVP addition.

- Tap piece → detail view with attributes
- Add piece button → registration flow
- Swipe to archive (removes from rotation, doesn't delete)

### Screen 3: Registration Flow

Modal/sheet over wardrobe. Step-by-step attribute selection. Each step is a single card transitioning to the next. Catalog image confirmation at end.

### Screen 4: Settings

- Edit style archetypes (same moodboard from onboarding)
- Location permissions
- About / feedback

### Navigation

Tab bar with two tabs: **Home** (suggestion) and **Wardrobe**. Settings accessible from wardrobe. Registration is a modal. Onboarding is a one-time flow before tabs appear.

### Aesthetic

- Off-white background (#F5F3EF or similar warm neutral)
- **Typography — two layers (identity vs interface):**
  - **DM Sans** (interface): all UI headings (light weight), body text (regular), buttons (medium). Geometric, quiet, functional.
  - **Cormorant Garamond Light** (brand): exclusively for the "KISE 着せ" wordmark on splash screen and branding moments. Never in interactive UI.
- Generous negative space, reduced palette — Japanese functional minimalism
- Minimal color in UI — the clothes are the color
- Cards with subtle shadows, generous spacing
- No gradients, no neon, no badges, no gamification
- "KISE 着せ" visual signature on splash/launch screen (Cormorant Garamond + kanji)

**Liquid Glass (iOS 26+):**
- Standard controls (tab bar, navigation bar, toolbars) automatically adopt Liquid Glass when compiled with Xcode 26. No code changes needed — this happens for free.
- Custom views (outfit cards, archetype selection cards, registration step cards) use `.glassEffect(.regular, in: .rect(cornerRadius:))` conditionally via `#available(iOS 26, *)`. Falls back to the current `.kiseCard()` shadow style on older iOS.
- `GlassEffectContainer` wraps the outfit suggestion layout so multiple outfit cards morph into a unified glass surface.
- The off-white background works well with Liquid Glass — the translucent material picks up the warm neutral tone and creates depth.
- KISE's minimalist positioning aligns naturally with Liquid Glass's clean, translucent aesthetic. No additional adaptation needed for the design language.

---

## Combination Engine Logic

The engine is **archetype-driven, not rule-based**. Style archetypes encode "outfit formulas" — patterns like "neutral base + structured outerwear" or "monochrome layers with texture contrast." Claude applies these patterns to the user's actual wardrobe.

**Hard rules** (enforced regardless of style):
- Fabric weight must be appropriate for weather conditions
- Seasonal fabric mismatches are always wrong (linen in winter)

**Soft rules** (contextual, handled by Claude's reasoning):
- Formality bridging — smart pants can pair with dress shirts
- Color combinations — monochrome works with texture contrast
- Style coherence — combinations should feel intentional within the archetype blend

The LLM approach is essential here because style rules are full of "it depends." A rule engine would drown in exceptions. Claude reasons about the specific combination in context.

---

## Privacy

- All user data (wardrobe, preferences, feedback) stored on-device in SwiftData
- No user accounts, no server-side data storage
- Suggestion requests are stateless — context sent per-request, nothing persisted by the proxy
- Location used only for weather via WeatherKit (Apple-managed, requires network)
- No analytics or tracking in MVP

---

## Technical Stack

- **Platform:** iOS native (Swift / SwiftUI)
- **Data persistence:** SwiftData (on-device)
- **Weather:** WeatherKit (v1 for iOS 17+, v2 features on iOS 26+ via availability checks)
- **Suggestion engine:** Claude API (Anthropic) via thin proxy server (primary); Apple Foundation Models on-device (iOS 26+ offline fallback)
- **Proxy:** Cloudflare Worker or Railway/Fly.io
- **Catalog images:** Pre-generated, bundled as app assets
- **UI framework:** SwiftUI with Liquid Glass progressive enhancement (iOS 26+)
- **Build toolchain:** Xcode 26 (standard controls get Liquid Glass automatically)
- **Minimum iOS version:** iOS 17+ (required for SwiftData)

---

## iOS 26 Progressive Enhancement

The app targets iOS 17+ as the minimum but progressively adopts iOS 26 features using `#available(iOS 26, *)` checks. This is not a separate code path — it's conditional enhancement layered on top of the core experience.

### Liquid Glass (UI)

All standard SwiftUI controls (tab bar, navigation bar, buttons in toolbars) adopt Liquid Glass automatically when compiled with Xcode 26. No code changes needed.

For custom views, apply glass effects conditionally:
```swift
.modifier(GlassCardModifier()) // internally checks #available(iOS 26, *)
```

Where `GlassCardModifier` applies `.glassEffect(.regular, in: .rect(cornerRadius: 12))` on iOS 26+ and falls back to the existing shadow-based card style on older versions.

### Foundation Models (On-Device Suggestion Fallback)

On iOS 26+ devices, Apple's Foundation Models framework provides a 3B parameter on-device LLM via `LanguageModelSession()`. KISE uses this as an **offline fallback**, not a replacement for Claude:

**When it activates:**
- No network connectivity AND no cached suggestion available
- User explicitly requests a suggestion while offline

**What it provides:**
- Basic outfit suggestions using the same wardrobe context and style archetypes
- Structured output via guided generation (same JSON schema as the Claude response)
- Runs entirely on-device — zero cost, zero latency, full privacy

**What it doesn't replace:**
- Claude remains the primary engine for online suggestions. The nuanced style reasoning, archetype blending, and feedback learning is more sophisticated with Claude.
- Foundation Models is the "good enough" offline experience, not the premium path.

**Architecture impact:** The `SuggestionService` gains a second method `fetchOnDeviceSuggestion()` gated behind `#available(iOS 26, *)`. The `SuggestionViewModel` tries Claude first, falls back to Foundation Models if available, then falls back to cached suggestion.

### WeatherKit v2 (Enhanced Weather Context)

On iOS 26+, WeatherKit v2 provides:
- **Significant change alerts** — "Tomorrow will be 12°C colder." Enables proactive suggestions: "You might want to plan a warmer outfit for tomorrow."
- **Historical comparisons** — Context for "This is unusually warm for March."
- **Cloud cover by altitude** — More nuanced weather context for Claude.

These enhancements feed richer context into the suggestion prompt on iOS 26+ devices without changing the core weather flow.

---

## Future (Post-MVP)

These features are explicitly out of MVP scope but inform architectural decisions:

- **Advanced feedback** — dislike reasons, piece-specific feedback, detailed micro-interactions
- **Wardrobe management** — usage tracking, "still want this piece?" prompts
- **Repetition awareness** — normalizing outfit repetition with positive messaging
- **Personal shopper** — "if you buy X, it creates Y new combinations"
- **Gap mapping** — "you have 5 casual tops and 0 semi-formal pieces"
- **Japanese color dictionaries** — engine for bold mode, unexpected harmonies
- **Marketplace integration** — sell archived pieces via Enjoei etc.
- **Purchase planning** — prioritized acquisition plan for wardrobe rebuilding
- **Commute context** — adjust for walking vs. driving to transport

---

## Monetization (Future)

- **MVP:** Free — wardrobe consultant
- **Premium:** Personal shopper — purchase suggestions, gap mapping, wardrobe planning
- **Affiliates:** Commission via marketplace integrations

Free → premium transition is natural: the app proves value organizing what you have, then monetizes by helping decide what to buy.

---

*KISE. 着せ. Dress with intention.*
