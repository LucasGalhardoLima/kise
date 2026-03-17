# Brand Identity Phase 1 — Matcha Palette, Editorial Typography, Tracked Labels

## Summary

Transform KISE's visual identity from generic minimalist to distinctly branded by applying the matcha color palette to UI chrome, expanding Cormorant Garamond to screen headings, and adding tracked small-caps section labels. Pure styling changes — no new features, data models, or assets.

## Motivation

TestFlight feedback confirmed the app is functional but visually generic. The current implementation uses charcoal (#1A1A1A) as the sole accent and DM Sans Light for all headings — technically clean but indistinguishable from any minimalist app. The matcha palette and editorial typography create a visual identity that is unmistakably KISE.

## Changes

### 1. Color System — Matcha Palette

Update color tokens in `KISEDesign.Colors` (DesignSystem.swift):

| Token | Current | New | Matcha Shade |
|-------|---------|-----|-------------|
| `textPrimary` | #1A1A1A | #344E41 | Pine Teal |
| `accent` | #1A1A1A | #3A5A40 | Hunter Green |
| `liked` | #4A7C59 | #588157 | Fern |
| `textSecondary` | #6B6B6B | unchanged | — |
| `textTertiary` | #9B9B9B | unchanged | — |
| `border` | #E5E1DB | unchanged | structural borders stay neutral |
| `disliked` | #8B4B4B | unchanged | warm brown for contrast |
| `background` | #F5F3EF | unchanged | warm off-white base stays |
| `surface` | #FFFFFF | unchanged | card background stays white |
| `cardShadow` | black 6% | unchanged | — |

New tokens to add:

| Token | Value | Matcha Shade | Purpose |
|-------|-------|-------------|---------|
| `accentSecondary` | #588157 | Fern | Slider tint, interactive accents |
| `accentMuted` | #A3B18A | Dry Sage | Inactive pill borders, kanji color, decorative borders |

**Design rationale:**
- `border` (#E5E1DB) stays unchanged for structural borders (card edges, dividers, separators). Dry Sage is more saturated and should only be used for accent borders.
- `textSecondary` and `textTertiary` stay neutral gray — they provide breathing room between the green-tinted headings and the matcha accents.
- `disliked` stays warm brown (#8B4B4B) — provides clear contrast against the green palette.
- Dust Grey (#DAD7CD) is reserved for Phase 2 — not used in Phase 1.

### 2. Typography — Cormorant Garamond for Display Headings

Expand Cormorant Garamond Light from wordmark-only to screen-level display headings.

**Change predefined sizes in `KISEDesign.Typography`:**
- `largeTitle`: currently `heading(32)` (DM Sans Light) → `brand(32)` (Cormorant Garamond Light)
- `title`: currently `heading(24)` (DM Sans Light) → `brand(24)` (Cormorant Garamond Light)

**Everything else stays DM Sans:**
- `subtitle` (17pt, medium) — buttons, CTA labels
- `bodyText` (15pt, regular) — descriptions
- `caption` (13pt, regular) — metadata
- `small` (11pt, regular) — tertiary text
- `brandTitle` (36pt, Cormorant) — wordmark (unchanged)

**Rule:** Cormorant Garamond for display/read-only headings. DM Sans for everything the user interacts with (buttons, form labels, body text, captions).

### 3. Tracked Small-Caps Section Labels

Add a new reusable text style for editorial section labels:

**New in `KISEDesign.Typography`:**
- `sectionLabel`: defined as `bodyMedium(11)` (DM Sans Medium, 11pt)

**New `ViewModifier`** (`KISESectionLabelStyle`):
- Applies `sectionLabel` font
- `.tracking(3)` for letter spacing
- `.textCase(.uppercase)`
- `.foregroundStyle(KISEDesign.Colors.textTertiary)`

Usage: `.modifier(KISESectionLabelStyle())` or `.kiseSectionLabel()` extension.

**Where to apply:**
- SuggestionView: "Your Look" label above the outfit composition
- Any future section headers that benefit from the editorial treatment

### 4. View Updates

Most views pick up changes automatically from the token updates. Per-view work required:

**SuggestionView.swift:**
- Screen heading: replace `.navigationTitle("Today")` with a custom toolbar title view using `largeTitle` (Cormorant Garamond). SwiftUI's `.navigationTitle` renders in the system font and does not use design tokens.
- Occasion pills: inactive border changes from `border` to `accentMuted`
- Add "Your Look" section label above outfit composition using `kiseSectionLabel()` style
- Slider tint: change from `accent` to `accentSecondary` (Fern)

**WardrobeView.swift:**
- Screen heading: replace `.navigationTitle("Wardrobe")` with a custom toolbar title view using `largeTitle` (Cormorant Garamond). SwiftUI's `.navigationTitle` renders in the system font and does not use design tokens.
- Category filter tabs: selected fill uses `accent` (automatic), inactive tabs: add `accentMuted` border stroke (currently no border on inactive tabs)

**StyleOnboardingView.swift:**
- "KISE" header picks up Pine Teal from `textPrimary` (automatic) and Cormorant Garamond from `largeTitle` token change (automatic — it uses `KISEDesign.Typography.largeTitle` directly, not `.navigationTitle`)
- Selected archetype card: stroke changes from `accent` to `accentMuted` for a softer selection state. Background tint stays as `accent.opacity(0.08)` (now Hunter Green at 8% — subtler than the previous charcoal tint)
- Continue button uses `accent` (automatic — Hunter Green)

**RegistrationFlowView.swift:**
- "Added!" toast uses `accent` (automatic — Hunter Green)

**Automatic (no per-view changes needed):**
- EmptyStateView — button accent flows from token
- GarmentDetailView — text colors flow from tokens
- SettingsView — text colors flow from tokens
- CuratedColorPicker — text colors flow from tokens
- ColorCompositionView — detail card text flows from tokens (composition block colors are garment colors, unaffected)
- CategoryPickerView — accent flows from token

## Architecture

No model or data changes. All changes are in:
- `KISE/Sources/Views/Shared/DesignSystem.swift` — token updates + new section label modifier
- `KISE/Sources/Views/Suggestion/SuggestionView.swift` — custom title, section label, pill borders, slider tint
- `KISE/Sources/Views/Wardrobe/WardrobeView.swift` — custom title, tab borders
- `KISE/Sources/Views/Onboarding/StyleOnboardingView.swift` — archetype selection stroke

## Out of Scope

- Garment silhouette illustrations (Phase 2)
- Wardrobe insights row with usage stats (Phase 2)
- Status badges on garment cards (Phase 2)
- Localization (future — all strings remain English)
- Matcha theme for app icon (already done — Pine Teal background with Dust Grey "K")
