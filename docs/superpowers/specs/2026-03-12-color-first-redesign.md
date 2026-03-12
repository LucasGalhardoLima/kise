# KISE Color-First UI Redesign

## Summary

Replace garment images with color-based abstract views throughout KISE. The wardrobe shows color tiles in a grid; outfit suggestions are presented as overlapping color block compositions inspired by Japanese color dictionaries (配色辞典). This shifts the visual identity from "wardrobe catalog" to "color harmony curator."

## Motivation

- KISE's core value is **outfit intelligence**, not wardrobe photography. Color combinations are what make an outfit work — the UI should center that.
- Removes friction: no need for users to photograph garments.
- Creates a distinctive visual identity that no other wardrobe app has.
- Lays groundwork for the V2 Japanese color dictionary feature (和色 names, seasonal palettes).
- Color blocks pair beautifully with iOS 26 Liquid Glass.

## Design Decisions

### Wardrobe View — Color Tile Grid

- **Structure**: Keep existing tab groups (Tops, Bottoms, Outerwear, Shoes).
- **Tiles**: Square rounded rectangles filled with the garment's hex color. 3 per row.
- **Labels**: Two-line below each tile — color name (primary) + category · fit (secondary, dimmed).
- **Sort**: By hue within each tab group. Hue is extracted from the hex value at runtime via HSB conversion. Sort order: red → orange → yellow → green → blue → purple → neutrals (grays/blacks/whites appended at the end, sorted by lightness).
- **Interactions**: Tap → detail/edit view. Long press → context menu (archive).
- **Edge case**: Near-white colors get a subtle 1px border. Threshold: apply border when the color's HSB brightness exceeds 0.85 and saturation is below 0.1.
- No shadows, icons, or badges on tiles.

### Suggestion View — Color Composition (配色辞典 style)

- **Composition**: Overlapping rectangles, one per garment piece. Arranged asymmetrically like a Japanese color dictionary entry.
- **Size encodes role via category priority**: outerwear (largest) → tops → bottoms → shoes (smallest). When no outerwear is present, bottoms take the largest block. This maps `GarmentCategory.tabGroup` to a size rank.
- **Modular by piece count**:
  - 2 pieces: two overlapping blocks
  - 3 pieces: classic three-block arrangement
  - 4 pieces: four blocks, highest-priority piece largest
  - 5+ pieces: caps at 4-5 blocks max
- **Layout templates**: A static set of 5-6 pre-defined arrangements per piece count. Picked per suggestion (deterministic hash of piece IDs for consistency). Dynamic LLM-generated layouts deferred to a future version.
- **Depth**: Subtle shadow on each block (`shadow(.drop(color: .black.opacity(0.08), radius: 2, y: 1))`).
- **Labels**: Single line below the composition — "{Color} {Category}" per piece, separated by mid-dots (e.g., "Cream Polo · Navy Chinos · Brown Shoes"). Intentionally briefer than wardrobe labels since fit/material are available via tap interaction.
- **Tap interaction**: Tapping a block highlights it with a subtle scale animation and shows a floating card anchored below the composition. The card displays category, fit, material, and formality. Tapping elsewhere or tapping the same block dismisses it. Only one card visible at a time.
- **Surrounding UI unchanged**: Occasion/boldness controls above, reasoning card below, feedback thumbs, "Try another" button.

### Color Input (Add/Edit Piece)

- **Primary: Curated palette** — ~15 color swatches in a horizontal scrollable row. Tap to select. Zero friction.
- **Escape hatch: Custom picker** — a "+" swatch at the end opens the native iOS color picker. Saves as hex.
- **Optional (V2): Camera extraction** — camera icon next to palette. Captures dominant color, snaps to nearest curated swatch with option to keep exact color.
- **Curated colors**: white, cream, light gray, charcoal, black, navy, light blue, olive, khaki, brown, burgundy, terracotta, sage, indigo, camel.
- **Naming**: Curated colors have display names. Custom colors get auto-generated names based on nearest curated hue (e.g., "Custom Blue") or user can name them.
- **Custom colors render as-is in compositions.** No hidden snapping.

### Registration Flow Changes

The current flow is: category → color → fit → material → weight → formality → **confirm (CatalogConfirmView)**.

The confirm step currently shows a catalog image and asks "Does this look like your piece?" This step becomes meaningless without images.

**New flow**: category → color → fit → material → weight → formality → **save directly**. Remove the `CatalogConfirmView` step entirely. The color tile serves as sufficient visual confirmation — the user already saw their selected color in the picker. A brief "Added!" confirmation toast replaces the full confirm screen.

### Accessibility

Color tiles are the primary visual representation, which impacts users with color vision deficiencies. Mitigations:
- The two-line text label below each tile is always present and provides full identification (color name + category + fit).
- VoiceOver descriptions include all attributes: "Navy polo, regular fit."
- In the composition view, the floating detail card is reachable via VoiceOver by swiping through blocks sequentially.
- No information is conveyed by color alone — every color block has an associated text label.

## Architecture — Progressive Enhancement (Approach 3)

### No SwiftData model changes

`GarmentPiece` already stores `color` (the `GarmentColor.id` string, e.g., "navy") and `colorHex` (e.g., "#1B2A4A"). Both fields continue to be used as-is.

**Custom color storage**: For custom colors, `color` stores `"custom"` and `colorHex` stores the user's chosen hex value. The display name is derived at runtime by `GarmentColor.nearestCurated(hex:)` → "Custom Blue", etc. No schema migration needed.

The 501 catalog images remain in the asset catalog but go unused by views.

### Evolving `GarmentColor`

The existing `GarmentColor` struct already has `id`, `name`, `hex`, and `static allColors`. Rather than creating a separate `ColorInfo` type, **extend `GarmentColor`** with the new capabilities:

- Add `isCustom: Bool` property (false for curated, true for custom).
- Add `static func nearestCurated(hex: String) -> GarmentColor` — finds the closest curated color by Euclidean distance in RGB space. Used for auto-naming custom colors.
- Add `init(customHex: String)` — creates a custom GarmentColor with auto-generated name.
- Remove `assetKey` property (no longer needed, was used for catalog image lookup).
- Forward-looking: V2 adds `japaneseName: String?`, `season: String?`, etc.

This avoids introducing a parallel type and keeps a single source of truth.

### `CompositionLayout` (new value type)

- Properties: `blocks: [CompositionBlock]` where each block has `relativeX`, `relativeY`, `relativeWidth`, `relativeHeight` (all 0.0–1.0 range, relative to the composition container).
- `static func templates(for pieceCount: Int) -> [CompositionLayout]` — returns 5-6 layout options for a given count (2 through 5).
- `static func pick(for pieceIDs: [UUID]) -> CompositionLayout` — deterministic selection using a hash of the piece IDs, so the same suggestion always renders the same layout.

### New views

**`ColorTileView`** — Replaces garment image cards in the wardrobe grid. Renders a colored rounded rectangle with a two-line label.

**`ColorCompositionView`** — Replaces the `OutfitPieceCard` stack in the suggestion view. Takes an array of `(GarmentPiece, CompositionBlock)` pairs sorted by category priority. Renders the overlapping composition with tap-to-highlight interaction and a floating detail card.

**`CuratedColorPicker`** — Horizontal scrollable row of curated swatches + custom "+" button. Replaces the current `ColorPickerStepView` grid in the registration flow. Also used in `GarmentDetailView` for editing color.

### Dead code to remove

- **`CatalogConfirmView`** — removed entirely (confirm step eliminated from flow).
- **`CatalogImageService`** — removed. No views reference catalog images.
- **`catalogImageID` computed property** on `GarmentPiece` — removed.
- **`OutfitPieceCard`** — replaced by `ColorCompositionView`.
- **`catalogImageKey` computed property** on `RegistrationViewModel` — removed.
- References to `CatalogImageService.loadImage()` in `WardrobeView` and `GarmentDetailView` — replaced by `ColorTileView` rendering.

### Proxy / API

No changes. Claude still returns piece UUIDs + reasoning. Composition layout is determined client-side.

## Scope

### In scope (this spec)
- Extend `GarmentColor` with custom color support and nearest-curated lookup
- `CompositionLayout` with static templates for 2-5 piece counts
- `ColorTileView` for wardrobe grid
- `ColorCompositionView` for suggestion view
- `CuratedColorPicker` for add/edit flow
- Update `WardrobeView` to use color tiles instead of catalog images
- Update `SuggestionView` to use color composition instead of `OutfitPieceCard` stack
- Update `RegistrationFlowView` / `ColorPickerStepView` to use `CuratedColorPicker`
- Remove confirm step (`CatalogConfirmView`) from registration flow
- Remove `CatalogImageService`, `OutfitPieceCard`, and related dead code
- Accessibility: VoiceOver descriptions for all color elements

### Out of scope (future)
- Camera-based color extraction
- Japanese color names (和色)
- Seasonal palette associations
- LLM-generated dynamic composition layouts
- Deleting catalog image assets from the asset catalog
