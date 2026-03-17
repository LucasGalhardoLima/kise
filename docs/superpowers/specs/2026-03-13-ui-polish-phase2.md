# UI Polish Phase 2 — Visual Consistency Fixes

## Goal

Address 5 visual/UI inconsistencies identified during TestFlight review of build 3 to bring the app closer to the matcha brand identity established in Brand Identity Phase 1.

## Scope

All changes are contained edits to existing view files. No new files, no model changes, no architecture shifts.

---

## Fix 1: Category Picker — Grouped Sections, No Icons

**Problem:** SF Symbols for jacket (`cloud.sun`), coat (`cloud.snow`), jeans/chinos/shorts (`figure.stand`/`figure.run`) are misleading and confuse users. Only `tshirt` and `shoe` are reasonable matches.

**Solution:** Remove all icons from `CategoryPickerView`. Group categories by `TabGroup` with tracked section headers using `kiseSectionLabel()`. Categories become text-only cards in a 3-column grid under each section.

**File:** `KISE/Sources/Views/Registration/CategoryPickerView.swift`

**Layout** (follows `TabGroup.allCases` order: tops, bottoms, outerwear, shoes):
```
TOPS (kiseSectionLabel)
[T-Shirt] [Shirt]   [Polo]
[Sweater] [Hoodie]

BOTTOMS (kiseSectionLabel)
[Jeans]   [Chinos]  [Shorts]

OUTERWEAR (kiseSectionLabel)
[Jacket]  [Coat]

SHOES (kiseSectionLabel)
[Shoes]
```

**Details:**
- Remove the `GarmentCategory.systemIcon` extension entirely (it is file-scoped in `CategoryPickerView.swift` and has no other callers)
- Remove `Image(systemName:)` from category cards
- Group by iterating `TabGroup.allCases`, then filtering `GarmentCategory.allCases` by `.tabGroup`
- Each group header uses `.kiseSectionLabel()` modifier
- Card label uses `KISEDesign.Typography.caption` (DM Sans 13pt), centered
- Cards retain `kiseCard()` styling

---

## Fix 2: Wardrobe `+` Button Position

**Problem:** The `+` button is placed via `ToolbarItem(placement: .primaryAction)` which pushes it to the far top-right corner, visually disconnected from the "Wardrobe" title centered via `.principal`.

**Solution:** Move the "Wardrobe" title from `.principal` (centered) to `.topBarLeading`. Keep the `+` button in `.primaryAction` (trailing). This closes the visual gap by left-aligning the title, which is a common iOS navigation pattern and brings the two elements closer together.

**File:** `KISE/Sources/Views/Wardrobe/WardrobeView.swift`

**Before:** `.principal` (centered title) + `.primaryAction` (`+` button far right) — large gap between them.

**After:** `.topBarLeading` (left-aligned title) + `.primaryAction` (`+` button right) — title and button are on the same line with natural proximity.

**Note:** The settings gear button in `MainTabView` uses `.topBarTrailing` placement (defined in `KISEApp.swift` lines 58-67). After this change, the toolbar will have: `.topBarLeading` (Wardrobe title), `.topBarTrailing` (gear), `.primaryAction` (`+`). The gear and `+` will both appear on the trailing side — verify they don't overlap and maintain adequate spacing.

---

## Fix 3: Content Width Gap

**Problem:** White strips visible on left and right edges of the SuggestionView ("Today" screen), where the matcha background doesn't extend edge-to-edge.

**Solution:** Use the closure-based background modifier with `.ignoresSafeArea()` so the background color fills edge-to-edge without affecting content layout.

**File:** `KISE/Sources/Views/Suggestion/SuggestionView.swift`

**Current code** (line 33 on the `ScrollView`):
```swift
.background(KISEDesign.Colors.background)
```

**Replace with** (on the outermost `NavigationStack` or `VStack`):
```swift
.background {
    KISEDesign.Colors.background.ignoresSafeArea()
}
```

**Also check:** `KISE/Sources/Views/Wardrobe/WardrobeView.swift` (line 66) has the same `.background(KISEDesign.Colors.background)` — apply the same fix for consistency if it shows the same gap.

---

## Fix 4: Garment Detail Title — Brand Font

**Problem:** `GarmentDetailView` uses `.navigationTitle(piece.category.displayName)` which renders in system SF Pro, breaking the brand typography.

**Solution:** Replace `.navigationTitle` with a custom toolbar title view using `KISEDesign.Typography.subtitle` (DM Sans Medium 17pt). This is the interface font for detail/content titles — Cormorant is reserved for screen-level headings only ("Today", "Wardrobe").

**File:** `KISE/Sources/Views/Wardrobe/GarmentDetailView.swift`

**Context:** `GarmentDetailView` is presented modally in a `.sheet` with its own `NavigationStack` (see `WardrobeView.swift` lines 86-88). There is no parent navigation to show a back-button label, so removing `.navigationTitle` has no side effects.

**Changes:**
- Remove `.navigationTitle(piece.category.displayName)` (line 46)
- Add `ToolbarItem(placement: .principal)` with:
  ```swift
  Text(piece.category.displayName)
      .font(KISEDesign.Typography.subtitle)
      .foregroundStyle(KISEDesign.Colors.textPrimary)
  ```
- Keep `.navigationBarTitleDisplayMode(.inline)`

---

## Fix 5: Registration Card Styling — Brand Connection

**Problem:** White cards with (now removed) icons feel generic and disconnected from the matcha brand identity. With Fix 1 removing icons, the cards need visual refinement.

**Solution:** Add subtle `accentMuted` border stroke to category cards, matching the unselected wardrobe tab pill style in `WardrobeView`.

**File:** `KISE/Sources/Views/Registration/CategoryPickerView.swift`

**Changes:**
- Add `.overlay { RoundedRectangle(cornerRadius: KISEDesign.Radius.md).strokeBorder(KISEDesign.Colors.accentMuted, lineWidth: 1) }` to each card
- This matches the unselected pill border style used in `WardrobeView`'s tab buttons (`.strokeBorder(KISEDesign.Colors.accentMuted, lineWidth: 1)`)

---

## Testing

- Run `xcodebuild build` to verify compilation
- Run `xcodebuild test` for KISETests
- Visual verification on Simulator: walk through onboarding → registration → wardrobe → suggestion flow on iPhone 16 Pro and iPhone SE (3rd gen) to check layout on different screen sizes
