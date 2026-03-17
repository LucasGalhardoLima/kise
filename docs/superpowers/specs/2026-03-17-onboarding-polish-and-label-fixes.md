# Onboarding Polish & Label Fixes — Design Spec

**Goal:** Improve onboarding with kanji explanation and interactive outfit generator; fix Portuguese label word order and hide fit for shoes.

---

## 1. Kanji Explanation in WelcomeView

**File:** `KISE/Sources/Views/Onboarding/WelcomeView.swift`

Add the kanji "着せ" below "KISE" in the welcome screen, with an explanatory line.

Layout (top to bottom, all centered):
- "KISE" — brand(48) font (existing)
- "着せ" — brand(28) font, textSecondary color
- "onboarding.tagline" — title font (existing, moves below kanji)
- "onboarding.welcomeDescription" — bodyText (existing)

The kanji sits between the wordmark and tagline, bridging the name to its Japanese meaning.

**Localization strings:**
- `"onboarding.kanjiExplanation"` — en: `"着せる — to dress with intention"`, pt-BR: `"着せる — vestir com intenção"`

Wait — simpler approach: just show "着せ" as the kanji display, and fold the explanation into the existing tagline or description. Actually, cleanest: show "着せ" directly after "KISE" as a subtitle, and keep the tagline below. The kanji is self-explanatory in context with the tagline.

**Final layout:**
```
         KISE
          着せ
  Vista-se com intenção
```

The "着せ" line uses `brand(28)` font, `textTertiary` color — subtle, decorative, not a focal point.

---

## 2. Interactive Outfit Generator in CompositionDemoView

**File:** `KISE/Sources/Views/Onboarding/CompositionDemoView.swift`

Replace the single hardcoded outfit with 10 preset combinations. Add a "generate" button that cycles through them.

### Preset Outfits

10 color combinations using curated `GarmentColor` palette colors. Each outfit is 3 pieces (top + bottom + shoes). Use varied categories and color harmonies:

```swift
static let presetOutfits: [[PresetPiece]] = [
    // 1. Classic navy
    [(.polo, "navy", "#1B2A4A"), (.chinos, "beige", "#D4C5A9"), (.shoes, "brown", "#6B4226")],
    // 2. Earth tones
    [(.sweater, "camel", "#C19A6B"), (.jeans, "indigo", "#3F5277"), (.shoes, "black", "#1A1A1A")],
    // 3. Summer casual
    [(.tShirt, "white", "#FFFFFF"), (.shorts, "olive", "#6B7F4E"), (.shoes, "tan", "#C2956B")],
    // 4. Smart casual
    [(.shirt, "lightBlue", "#A4C8E8"), (.chinos, "charcoal", "#4A4A4A"), (.shoes, "burgundy", "#722F37")],
    // 5. Muted tones
    [(.sweater, "sage", "#9CAF88"), (.jeans, "black", "#1A1A1A"), (.shoes, "white", "#FFFFFF")],
    // 6. Warm palette
    [(.polo, "terracotta", "#C75B39"), (.chinos, "cream", "#F5F0E8"), (.shoes, "brown", "#6B4226")],
    // 7. Cool minimal
    [(.tShirt, "lightGray", "#C8C8C8"), (.chinos, "navy", "#1B2A4A"), (.shoes, "white", "#FFFFFF")],
    // 8. Bold contrast
    [(.shirt, "mustard", "#D4A520"), (.jeans, "charcoal", "#4A4A4A"), (.shoes, "black", "#1A1A1A")],
    // 9. Layered look (with outerwear)
    [(.jacket, "khaki", "#C4A46C"), (.tShirt, "white", "#FFFFFF"), (.jeans, "indigo", "#3F5277")],
    // 10. Evening out
    [(.shirt, "black", "#1A1A1A"), (.chinos, "charcoal", "#4A4A4A"), (.shoes, "maroon", "#5B1E31")],
]
```

### UI Changes

- Start showing preset index 0
- Below the composition, add a "generate" button (capsule outline style, matching occasion pills):
  - Icon: `arrow.clockwise` + localized label `"onboarding.generate"`
  - en: "Generate", pt-BR: "Gerar"
- Each tap advances to next preset (wrapping around after 10)
- The composition + label text animate on change
- The label below the composition shows the piece names (using the same `ColorCompositionView` label)

### Data Model

Use a lightweight struct instead of full `GarmentPiece` for presets to avoid SwiftData overhead:

```swift
struct PresetPiece {
    let category: GarmentCategory
    let color: String      // GarmentColor id
    let colorHex: String
}
```

But `ColorCompositionView` expects `[GarmentPiece]`. Two options:
- **A)** Create real `GarmentPiece` instances (not inserted into SwiftData context) — works because `GarmentPiece` init doesn't require a context
- **B)** Refactor `ColorCompositionView` to accept a protocol

**Decision:** Option A. The current `CompositionDemoView` already creates `GarmentPiece` instances without inserting them (line 9-17). Just expand to 10 arrays of pieces.

---

## 3. Portuguese Word Order Fix

**Files:**
- `KISE/Sources/Views/Suggestion/ColorCompositionView.swift:104-108` (labelText)
- `KISE/Sources/Views/Shared/ColorTileView.swift:34` (tile label)
- `KISE/Sources/Views/Wardrobe/GarmentDetailView.swift:54,59` (title/subtitle)
- `KISE/Sources/Views/Suggestion/ColorCompositionView.swift:54` (accessibility label)

### Approach

Add a localized format string with positional arguments:

```
"pieceLabel.colorCategory" = "%1$@ %2$@"          // en: "Black Shoes"
"pieceLabel.colorCategory" = "%2$@ %1$@"          // pt-BR: "Calçados Pretos"
```

Create a helper function:

```swift
func pieceLabel(color: String, category: String) -> String {
    String(format: String(localized: "pieceLabel.colorCategory"), color, category)
}
```

Apply everywhere that joins color name + category display name:

1. `ColorCompositionView.labelText` — `"\(color.name) \(piece.category.displayName)"` → `pieceLabel(color:category:)`
2. `ColorTileView` body — `"\(colorDisplayName ?? garmentColor.name) \(category)"` → `pieceLabel(color:category:)`
3. `GarmentDetailView` title — `"\(piece.fit.displayName) \(garmentColor.name) \(piece.category.displayName)"` — this is a 3-part label, needs separate handling (see section 4)
4. `ColorCompositionView` accessibility label — same fix

---

## 4. Hide Fit for Shoes

**Files:**
- `KISE/Sources/Views/Suggestion/ColorCompositionView.swift:78` (detail card)
- `KISE/Sources/Views/Wardrobe/GarmentDetailView.swift:54,59` (title/subtitle)

### ColorCompositionView Detail Card

Currently shows fit/material/formality for all pieces (line 77-81). For shoes:
- Replace "Fit" with "Type" showing `piece.shoeType?.displayName ?? "—"`
- Keep material and formality

```swift
if piece.category == .shoes {
    if let shoeType = piece.shoeType {
        detailLabel(String(localized: "detail.type"), shoeType.displayName)
    }
} else {
    detailLabel(String(localized: "detail.fit"), piece.fit.displayName)
}
detailLabel(String(localized: "detail.material"), materialDisplayName(piece.material))
detailLabel(String(localized: "detail.formality"), piece.formality.displayName)
```

### GarmentDetailView Title/Subtitle

Line 54 currently: `"\(piece.fit.displayName) \(garmentColor.name) \(piece.category.displayName)"`

For shoes, use shoe type instead of fit:
```swift
if piece.category == .shoes, let shoeType = piece.shoeType {
    // "Sneakers Black Shoes" (en) / "Calçados Pretos Tênis" (pt-BR) — actually better:
    // Just show: "Black Sneakers" / "Tênis Pretos"
    pieceLabel(color: garmentColor.name, category: shoeType.displayName)
} else {
    "\(piece.fit.displayName) \(pieceLabel(color: garmentColor.name, category: piece.category.displayName))"
}
```

Line 59 subtitle: `"\(materialDisplayName(piece.material)) · \(garmentColor.name) · \(piece.fit.displayName)"`

For shoes: replace fit with shoe type:
```swift
if piece.category == .shoes, let shoeType = piece.shoeType {
    "\(materialDisplayName(piece.material)) · \(garmentColor.name) · \(shoeType.displayName)"
} else {
    "\(materialDisplayName(piece.material)) · \(garmentColor.name) · \(piece.fit.displayName)"
}
```

---

## Localization Keys Needed

| Key | en | pt-BR |
|---|---|---|
| `pieceLabel.colorCategory` | `%1$@ %2$@` | `%2$@ %1$@` |
| `onboarding.generate` | `Generate` | `Gerar` |
| `detail.type` | `Type` | `Tipo` |

---

## Files Touched

- `WelcomeView.swift` — add kanji line
- `CompositionDemoView.swift` — 10 presets + generate button
- `ColorCompositionView.swift` — word order fix + shoe type in detail card
- `ColorTileView.swift` — word order fix
- `GarmentDetailView.swift` — word order fix + shoe type in title/subtitle
- `Localizable.xcstrings` — new keys
- `Enums.swift` — add `pieceLabel()` helper (or a small extension)
