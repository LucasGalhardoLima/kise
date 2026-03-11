# VESTI — Design Specification

**Intelligent wardrobe consultant.**

A native iOS app that helps people dress with intention — combining their pieces, style, local weather, and daily context to suggest outfits that make sense.

---

## Vision

VESTI treats the wardrobe as a living system that evolves with the person. It's not "what to wear today" — it's "how to intentionally build the way you present yourself to the world."

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

VESTI is not a "look suggestion by AI" app. It's a wardrobe partner for people who dress with intention. The real value is closer to a personal image consultant in your pocket.

**The name:** From Latin *vestire*. In Italian, "vesti" means "you dressed" — past tense, with pride, with intention. Short, premium, global.

**Aesthetic:** Recognizable minimalism. Thin serif typography, off-white background, zero noise. Visual references: UNIQLO, COS, Arket, Aesop.

---

## MVP Scope

Three systems:

1. **Style onboarding** — select style archetypes that define the engine's taste
2. **Piece registration** — manually add garments with attributes, matched to pre-generated catalog images
3. **Daily suggestions** — LLM-powered, context-aware outfit combinations

Everything else (feedback loop, wardrobe management, repetition tracking, Vision recognition) is post-MVP.

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
- WeatherKit is on-device — Apple handles the weather API transparently.
- One network dependency for core functionality: the Claude API call via proxy, mitigated by background prefetch.

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
| category | GarmentCategory | Enum: tShirt, shirt, polo, sweater, hoodie, jacket, coat, jeans, chinos, shorts, shoes, accessories |
| color | String | e.g., "navy", "white", "olive" |
| colorHex | String | Hex value for UI display |
| fit | Fit | Enum: slim, regular, oversized |
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
| occasion | Occasion? | Enum: daily, meeting, casual, nightOut |
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
   - **Fit** — slim / regular / oversized (visual icons)
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
  "occasion": "daily",
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
- No database, no auth, no user tracking
- Rate limiting per hashed device ID to prevent abuse

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
- ~10-15 colors per category
- ~2-3 fits per category
- Total: 500-800 images covering ~95% of real wardrobe pieces
- User photo fallback for the remaining 5%

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
- Like button (single tap) / Dislike button (opens feedback micro-interaction)
- Pull down to reveal: occasion selector + boldness slider
- "Regenerate" button — different suggestion, same parameters
- Alternative piece swap as subtle "try this instead" on one card

### Screen 2: Wardrobe

Grid view of all pieces — catalog images in a clean grid. Category tabs at top (All, Tops, Bottoms, Outerwear, Shoes).

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
- Serif typeface for headings (Playfair Display or similar)
- Sans-serif for body (SF Pro for readability)
- Minimal color in UI — the clothes are the color
- Cards with subtle shadows, generous spacing
- No gradients, no neon, no badges, no gamification

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
- Location used only for weather via WeatherKit (on-device)
- No analytics or tracking in MVP

---

## Technical Stack

- **Platform:** iOS native (Swift / SwiftUI)
- **Data persistence:** SwiftData (on-device)
- **Weather:** WeatherKit
- **Suggestion engine:** Claude API (Anthropic) via thin proxy server
- **Proxy:** Cloudflare Worker or Railway/Fly.io
- **Catalog images:** Pre-generated, bundled as app assets
- **Minimum iOS version:** TBD (latest or latest-1)

---

## Future (Post-MVP)

These features are explicitly out of MVP scope but inform architectural decisions:

- **Feedback loop** — like/dislike with micro-interaction, feeds into Claude context
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

*VESTI. Dress with intention.*
