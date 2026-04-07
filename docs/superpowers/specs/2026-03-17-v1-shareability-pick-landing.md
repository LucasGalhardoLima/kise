# v1.0 — Shareability, KISE's Pick, Landing Page

## Overview

Three features to complete the v1.0 launch package: organic growth via shareable look cards, editorial content via daily city palettes, and a branded landing page with waitlist to capture pre-launch interest.

---

## Feature 1: Shareability

### Trigger

New share button in the suggestion action row (alongside thumbs up/down and "try another"). Also available on KISE's Pick palette cards.

### Render Pipeline

1. Build a `ShareCardView` (SwiftUI view, rendering-only — never displayed on screen)
2. Render to `UIImage` via `ImageRenderer` at 3x scale
3. Present `UIActivityViewController` with the image

### ShareCardView Layout (390×520pt)

- **Background:** `theme.colors.background` (Dust Grey) with subtle border
- **Top ~60%:** 配色辞典 composition — reuses `CompositionLayout` and existing color block logic
- **Middle:** Piece names joined with " · " (same format as in-app)
- **Below:** Weather line — "São Paulo · 22°C · Parcialmente nublado"
- **Bottom-right:** "KISE 着せ" in Cormorant Garamond, small
- **Bottom-left:** "Vista com intenção." in DM Sans, caption size

No deep links, no QR codes. The brand name is enough.

### Palette Share Variant

When sharing KISE's Pick instead of a personal suggestion:
- Composition blocks use the palette colors (3-4 blocks)
- Palette name replaces piece names ("Manhã Chuvosa em Shibuya")
- City + weather line stays
- Same branding footer

---

## Feature 2: KISE's Pick

### Backend: Daily Palette Pipeline

**Cloudflare Worker cron** (in existing `kise-proxy`):

- Runs daily via Cron Trigger (06:00 UTC)
- Picks next city from hardcoded rotation: `day_count % cities.length`
- Fetches current weather from OpenWeatherMap free tier
- Calls Claude with `generate_palette` tool — inputs: city, weather, season, temperature. Output: 3-4 hex colors, evocative palette name, 1-sentence description
- Caches result in Cloudflare KV (`daily-pick` key, 24h TTL)
- Sends email to admin via Resend with palette details (city, colors, name, description) for Threads posting

**New endpoints:**
- `GET /daily-pick` — returns cached palette JSON

**City rotation (initial 7):**
Tokyo, Copenhagen, Mexico City, São Paulo, Marrakech, Seoul, Lisboa

**Claude prompt context:** KISE as color curator inspired by 配色辞典 tradition. Palettes should feel like wearable color stories — colors that work as garments, not abstract art. Language matches the city's cultural context or the requesting client's locale.

### Data Model

```swift
struct DailyPalette: Codable {
    let city: String
    let temperature: Int
    let condition: String
    let paletteName: String
    let description: String
    let colors: [String] // hex values
}
```

### Frontend: Home Tab Integration

**Placement:** Below the suggestion content, visible when scrolling. Separated by standard spacing.

**Card layout:**
- Section label: "KISE'S PICK" (tracked uppercase, same style as "SEU LOOK")
- 配色辞典 composition blocks — 3-4 color rectangles using `CompositionLayout`
- City + weather: "Tóquio · 18°C · Chuva leve"
- Palette name in Cormorant: "Manhã Chuvosa em Shibuya"
- Hex codes row — DM Sans caption, subtle
- Share button — reuses ShareCardView pipeline (palette variant)

**Data flow:**
- `SuggestionViewModel` gains `dailyPick: DailyPalette?` published property
- Fetched on `task` alongside weather, non-blocking
- If fetch fails, section simply doesn't appear — no error state

---

## Feature 3: Landing Page

### Stack

**Astro + Tailwind CSS** on Vercel. Static by default, Astro islands for interactive elements.

### i18n

Astro built-in i18n routing:
- `/` — pt-BR (default)
- `/en` — English

Same components, different content strings. No layout duplication.

### Design System (Tailwind config)

- **Colors:** Dust Grey (#DAD7CD), Dry Sage (#A3B18A), Fern (#588157), Hunter Green (#3A5A40), Pine Teal (#344E41)
- **Fonts:** Cormorant Garamond Light 300 (headings), DM Sans (body)
- **Layout:** Max-width ~720px content, generous spacing — editorial feel, not SaaS

### Page Structure

**1. Hero**
- "KISE 着せ" in Cormorant, large
- "Seu guarda-roupa, com intenção." tagline (localized)
- Email input + "Entrar na lista" / "Join the waitlist" CTA (Fern bg, Dust Grey text)
- Static 配色辞典 composition visual below — communicates the product's visual language without app screenshots

**2. How it works**
- Three columns, icon + short text:
  - Register your wardrobe
  - Get daily suggestions (weather, style, context)
  - Dress with intention
- Cormorant headings, DM Sans body, minimal copy

**3. The philosophy**
- Editorial block on intentional dressing — why wardrobes should be systems, not collections
- Pull quote or highlight — memorable and shareable
- Should feel like reading a magazine, not a product page

**4. Color language showcase**
- Interactive Astro island: live 配色辞典 palette based on visitor's local weather
- Browser geolocation + OpenWeatherMap client-side fetch
- Falls back to static São Paulo palette if geolocation denied
- Hex codes displayed below composition blocks
- "Sua paleta agora" / "Your palette right now" label
- The "wow" moment — visitor experiences KISE's core concept before downloading

**5. Waitlist CTA (repeated)**
- Same email capture as hero, anchored at bottom
- Social proof counter: "X pessoas na lista" (when meaningful)

**6. Footer**
- "KISE 着せ" logotype
- Link to Threads account
- "Vista com intenção."

### Waitlist Backend

- Vercel serverless function: `POST /api/waitlist`
- Validates email format, deduplicates
- Adds contact to Resend audience list
- Sends branded confirmation email: Cormorant heading, "Você está na lista. Vamos te avisar quando o KISE estiver pronto." (localized)
- No database — Resend audience list is the source of truth

---

## What's NOT in scope

- Threads API automation (manual posting from email for now)
- Deep links or QR codes on share cards
- KISE's Pick as a replacement for the personal suggestion (it's additive, below)
- Landing page analytics beyond Vercel built-in (add later if needed)
