# Color-First UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace garment images with color-based abstract views — color tile grid for wardrobe, overlapping 配色辞典 composition for suggestions, curated color picker for registration.

**Architecture:** Progressive enhancement — extend existing `GarmentColor` with custom color support and nearest-curated lookup; add `CompositionLayout` for suggestion block templates; create three new view components (`ColorTileView`, `ColorCompositionView`, `CuratedColorPicker`); update existing views to use them; remove dead image-related code.

**Tech Stack:** Swift/SwiftUI, SwiftData, Xcode 26, iOS 17+

**Spec:** `docs/superpowers/specs/2026-03-12-color-first-redesign.md`

---

## File Structure

### Create
- `KISE/Sources/Models/CompositionLayout.swift` — Layout templates for 配色辞典 block compositions
- `KISE/Sources/Views/Shared/ColorTileView.swift` — Wardrobe color tile component
- `KISE/Sources/Views/Suggestion/ColorCompositionView.swift` — Overlapping color block composition
- `KISE/Sources/Views/Registration/CuratedColorPicker.swift` — Horizontal scrollable palette + custom picker
- `KISE/Tests/Models/CompositionLayoutTests.swift` — Tests for layout templates

### Modify
- `KISE/Sources/Models/GarmentColor.swift` — Add `isCustom`, `nearestCurated(hex:)`, `init(customHex:)`; remove `assetKey`
- `KISE/Sources/Models/GarmentPiece.swift` — Remove `catalogImageID` computed property
- `KISE/Sources/ViewModels/WardrobeViewModel.swift` — Add hue-based sorting to `filterPieces`
- `KISE/Sources/ViewModels/RegistrationViewModel.swift` — Remove `.confirm` step and `catalogImageKey`; save directly after formality
- `KISE/Sources/Views/Wardrobe/WardrobeView.swift` — Replace `garmentCard` with `ColorTileView`
- `KISE/Sources/Views/Wardrobe/GarmentDetailView.swift` — Replace catalog image with color swatch
- `KISE/Sources/Views/Suggestion/SuggestionView.swift` — Replace `outfitCards` with `ColorCompositionView`
- `KISE/Sources/Views/Registration/RegistrationFlowView.swift` — Remove `.confirm` case; save after `.formality`
- `KISE/Sources/Views/Registration/AttributeStepView.swift` — Replace `ColorPickerStepView` with `CuratedColorPicker`
- `KISE/Tests/Models/GarmentColorTests.swift` — Update for removed `assetKey`, add custom color tests
- `KISE/Tests/ViewModels/RegistrationViewModelTests.swift` — Update for removed `.confirm` step
- `KISE/Tests/ViewModels/WardrobeViewModelTests.swift` — Add hue sorting test

### Delete
- `KISE/Sources/Views/Registration/CatalogConfirmView.swift`
- `KISE/Sources/Services/CatalogImageService.swift`
- `KISE/Sources/Views/Suggestion/OutfitPieceCard.swift`
- `KISE/Tests/Services/CatalogImageServiceTests.swift`

---

## Chunk 1: Foundation Types

### Task 1: Extend GarmentColor with custom color support

**Files:**
- Modify: `KISE/Sources/Models/GarmentColor.swift`
- Modify: `KISE/Tests/Models/GarmentColorTests.swift`

- [ ] **Step 1: Update existing tests — remove assetKey test, add custom color tests**

Replace the entire test file:

```swift
// KISE/Tests/Models/GarmentColorTests.swift
import XCTest
@testable import KISE

final class GarmentColorTests: XCTestCase {

    func testAllColorsHaveValidHex() {
        for color in GarmentColor.allColors {
            XCTAssertTrue(color.hex.hasPrefix("#"), "\(color.name) hex should start with #")
            XCTAssertEqual(color.hex.count, 7, "\(color.name) hex should be 7 chars")
        }
    }

    func testCuratedColorsAreNotCustom() {
        for color in GarmentColor.allColors {
            XCTAssertFalse(color.isCustom, "\(color.name) should not be custom")
        }
    }

    func testColorLookupByName() {
        let navy = GarmentColor.byName("navy")
        XCTAssertNotNil(navy)
        XCTAssertEqual(navy?.hex, "#1B2A4A")
    }

    func testColorCount() {
        XCTAssertEqual(GarmentColor.allColors.count, 15)
    }

    func testNearestCuratedForExactMatch() {
        let nearest = GarmentColor.nearestCurated(hex: "#1B2A4A")
        XCTAssertEqual(nearest.id, "navy")
    }

    func testNearestCuratedForCloseMatch() {
        // A slightly different navy should still match navy
        let nearest = GarmentColor.nearestCurated(hex: "#1C2B4B")
        XCTAssertEqual(nearest.id, "navy")
    }

    func testCustomColorInit() {
        let custom = GarmentColor(customHex: "#FF6B35")
        XCTAssertTrue(custom.isCustom)
        XCTAssertEqual(custom.hex, "#FF6B35")
        XCTAssertTrue(custom.name.hasPrefix("Custom"))
    }

    func testCustomColorNaming() {
        // A reddish custom color should get "Custom Red" or similar
        let custom = GarmentColor(customHex: "#FF0000")
        XCTAssertTrue(custom.name.contains("Custom"))
    }

    func testHueSortValue() {
        let white = GarmentColor.allColors.first { $0.id == "white" }!
        let navy = GarmentColor.allColors.first { $0.id == "navy" }!
        // Neutrals sort after chromatic colors
        XCTAssertGreaterThan(white.hueSortValue, navy.hueSortValue)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:KISETests/GarmentColorTests 2>&1 | tail -20`
Expected: FAIL — `isCustom`, `nearestCurated`, `init(customHex:)`, `hueSortValue` don't exist yet

- [ ] **Step 3: Implement GarmentColor extensions**

Replace `KISE/Sources/Models/GarmentColor.swift` with:

```swift
// KISE/Sources/Models/GarmentColor.swift
import SwiftUI

struct GarmentColor: Identifiable, Equatable {
    let id: String
    let name: String
    let hex: String
    let isCustom: Bool

    var color: Color {
        Color(hex: hex)
    }

    /// HSB components extracted from hex, used for sorting and nearest-match
    var hsbComponents: (hue: CGFloat, saturation: CGFloat, brightness: CGFloat) {
        let c = UIColor(Color(hex: hex))
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return (h, s, b)
    }

    /// Sort value for hue-based ordering.
    /// Chromatic colors sort by hue (0.0–1.0); neutrals (low saturation) sort after at 2.0+ by lightness.
    var hueSortValue: Double {
        let (h, s, b) = hsbComponents
        if s < 0.1 {
            // Neutral: sort after all chromatic colors, ordered by brightness (dark → light)
            return 2.0 + Double(b)
        }
        return Double(h)
    }

    /// Whether this color needs a border to be visible against a light background.
    /// True when brightness > 0.85 and saturation < 0.1.
    var needsBorder: Bool {
        let (_, s, b) = hsbComponents
        return b > 0.85 && s < 0.1
    }

    // MARK: - Curated Palette

    static let allColors: [GarmentColor] = [
        GarmentColor(id: "white", name: "White", hex: "#FFFFFF", isCustom: false),
        GarmentColor(id: "cream", name: "Off-White", hex: "#F5F0E8", isCustom: false),
        GarmentColor(id: "lightGray", name: "Light Gray", hex: "#C8C8C8", isCustom: false),
        GarmentColor(id: "charcoal", name: "Charcoal", hex: "#4A4A4A", isCustom: false),
        GarmentColor(id: "black", name: "Black", hex: "#1A1A1A", isCustom: false),
        GarmentColor(id: "navy", name: "Navy", hex: "#1B2A4A", isCustom: false),
        GarmentColor(id: "lightBlue", name: "Light Blue", hex: "#A4C8E8", isCustom: false),
        GarmentColor(id: "olive", name: "Olive", hex: "#6B7F4E", isCustom: false),
        GarmentColor(id: "khaki", name: "Khaki", hex: "#C4A46C", isCustom: false),
        GarmentColor(id: "brown", name: "Brown", hex: "#6B4226", isCustom: false),
        GarmentColor(id: "burgundy", name: "Burgundy", hex: "#722F37", isCustom: false),
        GarmentColor(id: "terracotta", name: "Terracotta", hex: "#C75B39", isCustom: false),
        GarmentColor(id: "sage", name: "Sage", hex: "#9CAF88", isCustom: false),
        GarmentColor(id: "indigo", name: "Indigo", hex: "#3F5277", isCustom: false),
        GarmentColor(id: "camel", name: "Camel", hex: "#C19A6B", isCustom: false),
    ]

    static func byName(_ name: String) -> GarmentColor? {
        allColors.first { $0.name.lowercased() == name.lowercased() || $0.id == name.lowercased() }
    }

    // MARK: - Custom Color Support

    /// Creates a custom color with an auto-generated name based on the nearest curated hue.
    init(customHex: String) {
        let nearest = GarmentColor.nearestCurated(hex: customHex)
        self.id = "custom"
        self.name = "Custom \(nearest.name)"
        self.hex = customHex
        self.isCustom = true
    }

    /// Finds the closest curated color by Euclidean distance in RGB space.
    static func nearestCurated(hex: String) -> GarmentColor {
        let target = Self.rgbComponents(hex: hex)
        var best = allColors[0]
        var bestDist = Double.infinity
        for color in allColors {
            let c = rgbComponents(hex: color.hex)
            let dist = pow(target.r - c.r, 2) + pow(target.g - c.g, 2) + pow(target.b - c.b, 2)
            if dist < bestDist {
                bestDist = dist
                best = color
            }
        }
        return best
    }

    /// Resolves a stored color string + hex into a GarmentColor for display.
    /// If color == "custom", creates a custom GarmentColor; otherwise looks up from curated palette.
    static func resolve(color: String, hex: String) -> GarmentColor {
        if color == "custom" {
            return GarmentColor(customHex: hex)
        }
        return byName(color) ?? GarmentColor(customHex: hex)
    }

    // MARK: - Private

    private static func rgbComponents(hex: String) -> (r: Double, g: Double, b: Double) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        return (
            Double((rgbValue & 0xFF0000) >> 16) / 255.0,
            Double((rgbValue & 0x00FF00) >> 8) / 255.0,
            Double(rgbValue & 0x0000FF) / 255.0
        )
    }
}

// MARK: - Color hex extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:KISETests/GarmentColorTests 2>&1 | tail -20`
Expected: PASS — all 9 tests pass

- [ ] **Step 5: Commit**

```bash
git add KISE/Sources/Models/GarmentColor.swift KISE/Tests/Models/GarmentColorTests.swift
git commit -m "feat: extend GarmentColor with custom color support, nearest-curated lookup, and hue sorting"
```

---

### Task 2: Create CompositionLayout

**Files:**
- Create: `KISE/Sources/Models/CompositionLayout.swift`
- Create: `KISE/Tests/Models/CompositionLayoutTests.swift`

- [ ] **Step 1: Write the tests**

```swift
// KISE/Tests/Models/CompositionLayoutTests.swift
import XCTest
@testable import KISE

final class CompositionLayoutTests: XCTestCase {

    func testTemplatesExistForAllPieceCounts() {
        for count in 2...5 {
            let templates = CompositionLayout.templates(for: count)
            XCTAssertFalse(templates.isEmpty, "Should have templates for \(count) pieces")
            for template in templates {
                XCTAssertEqual(template.blocks.count, count, "Template for \(count) should have \(count) blocks")
            }
        }
    }

    func testBlocksHaveValidRelativeCoordinates() {
        for count in 2...5 {
            for template in CompositionLayout.templates(for: count) {
                for block in template.blocks {
                    XCTAssertTrue(block.relativeX >= 0 && block.relativeX <= 1)
                    XCTAssertTrue(block.relativeY >= 0 && block.relativeY <= 1)
                    XCTAssertTrue(block.relativeWidth > 0 && block.relativeWidth <= 1)
                    XCTAssertTrue(block.relativeHeight > 0 && block.relativeHeight <= 1)
                }
            }
        }
    }

    func testPickIsDeterministic() {
        let ids = [UUID(), UUID(), UUID()]
        let layout1 = CompositionLayout.pick(for: ids)
        let layout2 = CompositionLayout.pick(for: ids)
        XCTAssertEqual(layout1.blocks.count, layout2.blocks.count)
        for (a, b) in zip(layout1.blocks, layout2.blocks) {
            XCTAssertEqual(a.relativeX, b.relativeX)
            XCTAssertEqual(a.relativeY, b.relativeY)
        }
    }

    func testPickVariesByInput() {
        let ids1 = [UUID(), UUID(), UUID()]
        let ids2 = [UUID(), UUID(), UUID()]
        // Different UUIDs should potentially pick different templates
        // (not guaranteed, but with 5+ templates the odds of collision are low)
        let layout1 = CompositionLayout.pick(for: ids1)
        let layout2 = CompositionLayout.pick(for: ids2)
        // Just verify both produce valid layouts — determinism is the key guarantee
        XCTAssertEqual(layout1.blocks.count, 3)
        XCTAssertEqual(layout2.blocks.count, 3)
    }

    func testCategorySizePriority() {
        // Outerwear should have higher priority (larger block) than shoes
        XCTAssertGreaterThan(
            CompositionLayout.sizePriority(for: .jacket),
            CompositionLayout.sizePriority(for: .shoes)
        )
        // Tops > shoes
        XCTAssertGreaterThan(
            CompositionLayout.sizePriority(for: .tShirt),
            CompositionLayout.sizePriority(for: .shoes)
        )
    }

    func testFallbackForOutOfRangePieceCount() {
        // 1 piece should get a single-block fallback
        let templates = CompositionLayout.templates(for: 1)
        XCTAssertFalse(templates.isEmpty)
        XCTAssertEqual(templates[0].blocks.count, 1)

        // 6 pieces should cap at 5
        let capped = CompositionLayout.templates(for: 6)
        XCTAssertFalse(capped.isEmpty)
        XCTAssertEqual(capped[0].blocks.count, 5)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:KISETests/CompositionLayoutTests 2>&1 | tail -20`
Expected: FAIL — `CompositionLayout` doesn't exist

- [ ] **Step 3: Implement CompositionLayout**

```swift
// KISE/Sources/Models/CompositionLayout.swift
import Foundation

struct CompositionBlock: Equatable {
    let relativeX: Double
    let relativeY: Double
    let relativeWidth: Double
    let relativeHeight: Double
}

struct CompositionLayout: Equatable {
    let blocks: [CompositionBlock]

    /// Returns layout templates for a given piece count.
    /// Blocks are ordered largest-first (for assignment to highest-priority categories).
    static func templates(for pieceCount: Int) -> [CompositionLayout] {
        let clamped = min(max(pieceCount, 1), 5)
        switch clamped {
        case 1:
            return [
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.1, relativeY: 0.1, relativeWidth: 0.8, relativeHeight: 0.8),
                ]),
            ]
        case 2:
            return [
                // Large left, smaller right-overlapping
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.05, relativeY: 0.15, relativeWidth: 0.65, relativeHeight: 0.7),
                    CompositionBlock(relativeX: 0.40, relativeY: 0.05, relativeWidth: 0.55, relativeHeight: 0.55),
                ]),
                // Large bottom, smaller top-right
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.05, relativeY: 0.30, relativeWidth: 0.75, relativeHeight: 0.65),
                    CompositionBlock(relativeX: 0.30, relativeY: 0.05, relativeWidth: 0.60, relativeHeight: 0.45),
                ]),
                // Stacked with offset
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.10, relativeY: 0.25, relativeWidth: 0.70, relativeHeight: 0.65),
                    CompositionBlock(relativeX: 0.25, relativeY: 0.05, relativeWidth: 0.55, relativeHeight: 0.40),
                ]),
                // Large right, smaller left-overlapping
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.30, relativeY: 0.10, relativeWidth: 0.65, relativeHeight: 0.70),
                    CompositionBlock(relativeX: 0.05, relativeY: 0.25, relativeWidth: 0.50, relativeHeight: 0.55),
                ]),
                // Diagonal overlap
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.05, relativeY: 0.05, relativeWidth: 0.70, relativeHeight: 0.65),
                    CompositionBlock(relativeX: 0.30, relativeY: 0.35, relativeWidth: 0.65, relativeHeight: 0.60),
                ]),
            ]
        case 3:
            return [
                // Classic: large center, medium top-left, small bottom-right
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.10, relativeY: 0.25, relativeWidth: 0.65, relativeHeight: 0.55),
                    CompositionBlock(relativeX: 0.25, relativeY: 0.05, relativeWidth: 0.50, relativeHeight: 0.40),
                    CompositionBlock(relativeX: 0.50, relativeY: 0.60, relativeWidth: 0.40, relativeHeight: 0.30),
                ]),
                // Diagonal cascade
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.05, relativeY: 0.20, relativeWidth: 0.60, relativeHeight: 0.60),
                    CompositionBlock(relativeX: 0.30, relativeY: 0.05, relativeWidth: 0.50, relativeHeight: 0.35),
                    CompositionBlock(relativeX: 0.45, relativeY: 0.55, relativeWidth: 0.45, relativeHeight: 0.35),
                ]),
                // T-shape: wide top, two small below
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.05, relativeY: 0.05, relativeWidth: 0.75, relativeHeight: 0.50),
                    CompositionBlock(relativeX: 0.05, relativeY: 0.40, relativeWidth: 0.45, relativeHeight: 0.40),
                    CompositionBlock(relativeX: 0.40, relativeY: 0.50, relativeWidth: 0.50, relativeHeight: 0.35),
                ]),
                // L-shape: tall left, stacked right
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.05, relativeY: 0.05, relativeWidth: 0.50, relativeHeight: 0.75),
                    CompositionBlock(relativeX: 0.35, relativeY: 0.05, relativeWidth: 0.55, relativeHeight: 0.40),
                    CompositionBlock(relativeX: 0.40, relativeY: 0.55, relativeWidth: 0.45, relativeHeight: 0.35),
                ]),
                // Asymmetric overlap
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.15, relativeY: 0.15, relativeWidth: 0.65, relativeHeight: 0.55),
                    CompositionBlock(relativeX: 0.05, relativeY: 0.05, relativeWidth: 0.40, relativeHeight: 0.35),
                    CompositionBlock(relativeX: 0.55, relativeY: 0.50, relativeWidth: 0.35, relativeHeight: 0.40),
                ]),
            ]
        case 4:
            return [
                // Grid-ish with overlap
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.05, relativeY: 0.15, relativeWidth: 0.55, relativeHeight: 0.55),
                    CompositionBlock(relativeX: 0.25, relativeY: 0.05, relativeWidth: 0.45, relativeHeight: 0.30),
                    CompositionBlock(relativeX: 0.45, relativeY: 0.30, relativeWidth: 0.45, relativeHeight: 0.35),
                    CompositionBlock(relativeX: 0.35, relativeY: 0.60, relativeWidth: 0.35, relativeHeight: 0.30),
                ]),
                // Cascading diagonal
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.05, relativeY: 0.10, relativeWidth: 0.55, relativeHeight: 0.50),
                    CompositionBlock(relativeX: 0.30, relativeY: 0.05, relativeWidth: 0.40, relativeHeight: 0.30),
                    CompositionBlock(relativeX: 0.45, relativeY: 0.35, relativeWidth: 0.45, relativeHeight: 0.35),
                    CompositionBlock(relativeX: 0.20, relativeY: 0.60, relativeWidth: 0.40, relativeHeight: 0.30),
                ]),
                // Column pairs
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.05, relativeY: 0.05, relativeWidth: 0.50, relativeHeight: 0.55),
                    CompositionBlock(relativeX: 0.40, relativeY: 0.20, relativeWidth: 0.50, relativeHeight: 0.45),
                    CompositionBlock(relativeX: 0.10, relativeY: 0.50, relativeWidth: 0.40, relativeHeight: 0.35),
                    CompositionBlock(relativeX: 0.45, relativeY: 0.60, relativeWidth: 0.35, relativeHeight: 0.30),
                ]),
                // Pinwheel
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.10, relativeY: 0.10, relativeWidth: 0.55, relativeHeight: 0.50),
                    CompositionBlock(relativeX: 0.40, relativeY: 0.05, relativeWidth: 0.50, relativeHeight: 0.30),
                    CompositionBlock(relativeX: 0.05, relativeY: 0.50, relativeWidth: 0.40, relativeHeight: 0.35),
                    CompositionBlock(relativeX: 0.40, relativeY: 0.55, relativeWidth: 0.45, relativeHeight: 0.35),
                ]),
                // Stacked with offset
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.05, relativeY: 0.20, relativeWidth: 0.60, relativeHeight: 0.50),
                    CompositionBlock(relativeX: 0.20, relativeY: 0.05, relativeWidth: 0.50, relativeHeight: 0.30),
                    CompositionBlock(relativeX: 0.45, relativeY: 0.40, relativeWidth: 0.45, relativeHeight: 0.30),
                    CompositionBlock(relativeX: 0.25, relativeY: 0.65, relativeWidth: 0.35, relativeHeight: 0.25),
                ]),
            ]
        case 5:
            return [
                // Dense mosaic
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.05, relativeY: 0.15, relativeWidth: 0.50, relativeHeight: 0.45),
                    CompositionBlock(relativeX: 0.20, relativeY: 0.05, relativeWidth: 0.40, relativeHeight: 0.25),
                    CompositionBlock(relativeX: 0.45, relativeY: 0.25, relativeWidth: 0.40, relativeHeight: 0.30),
                    CompositionBlock(relativeX: 0.10, relativeY: 0.55, relativeWidth: 0.35, relativeHeight: 0.30),
                    CompositionBlock(relativeX: 0.45, relativeY: 0.60, relativeWidth: 0.35, relativeHeight: 0.25),
                ]),
                // Scattered
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.10, relativeY: 0.10, relativeWidth: 0.50, relativeHeight: 0.45),
                    CompositionBlock(relativeX: 0.45, relativeY: 0.05, relativeWidth: 0.40, relativeHeight: 0.25),
                    CompositionBlock(relativeX: 0.05, relativeY: 0.50, relativeWidth: 0.35, relativeHeight: 0.30),
                    CompositionBlock(relativeX: 0.40, relativeY: 0.35, relativeWidth: 0.40, relativeHeight: 0.30),
                    CompositionBlock(relativeX: 0.30, relativeY: 0.65, relativeWidth: 0.35, relativeHeight: 0.25),
                ]),
                // Flowing
                CompositionLayout(blocks: [
                    CompositionBlock(relativeX: 0.05, relativeY: 0.15, relativeWidth: 0.55, relativeHeight: 0.40),
                    CompositionBlock(relativeX: 0.35, relativeY: 0.05, relativeWidth: 0.45, relativeHeight: 0.25),
                    CompositionBlock(relativeX: 0.40, relativeY: 0.30, relativeWidth: 0.45, relativeHeight: 0.30),
                    CompositionBlock(relativeX: 0.05, relativeY: 0.50, relativeWidth: 0.40, relativeHeight: 0.35),
                    CompositionBlock(relativeX: 0.40, relativeY: 0.60, relativeWidth: 0.40, relativeHeight: 0.25),
                ]),
            ]
        default:
            return []
        }
    }

    /// Deterministic layout selection based on piece IDs.
    static func pick(for pieceIDs: [UUID]) -> CompositionLayout {
        let available = templates(for: pieceIDs.count)
        guard !available.isEmpty else {
            return CompositionLayout(blocks: [])
        }
        let hash = pieceIDs.map(\.uuidString).joined().hashValue
        let index = abs(hash) % available.count
        return available[index]
    }

    /// Size priority for category-to-block assignment.
    /// Higher value = larger block in the composition.
    static func sizePriority(for category: GarmentCategory) -> Int {
        switch category.tabGroup {
        case .outerwear: 4
        case .tops: 3
        case .bottoms: 2
        case .shoes: 1
        }
    }
}
```

- [ ] **Step 4: Regenerate Xcode project (new files added)**

Run: `cd /Users/lucasgalhardo/Documents/Projects/vesti && xcodegen generate`

- [ ] **Step 5: Run tests to verify they pass**

Run: `xcodebuild test -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:KISETests/CompositionLayoutTests 2>&1 | tail -20`
Expected: PASS — all 6 tests pass

- [ ] **Step 6: Commit**

```bash
git add KISE/Sources/Models/CompositionLayout.swift KISE/Tests/Models/CompositionLayoutTests.swift project.yml
git commit -m "feat: add CompositionLayout with block templates for 配色辞典 compositions"
```

---

## Chunk 2: Wardrobe Views

### Task 3: Create ColorTileView

**Files:**
- Create: `KISE/Sources/Views/Shared/ColorTileView.swift`

- [ ] **Step 1: Create ColorTileView**

```swift
// KISE/Sources/Views/Shared/ColorTileView.swift
import SwiftUI

struct ColorTileView: View {
    let colorHex: String
    let colorName: String
    let category: String
    let fit: String

    private var garmentColor: GarmentColor {
        GarmentColor.byName(colorName) ?? GarmentColor(customHex: colorHex)
    }

    var body: some View {
        VStack(spacing: KISEDesign.Spacing.xs) {
            RoundedRectangle(cornerRadius: KISEDesign.Radius.sm)
                .fill(Color(hex: colorHex))
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    if garmentColor.needsBorder {
                        RoundedRectangle(cornerRadius: KISEDesign.Radius.sm)
                            .strokeBorder(KISEDesign.Colors.border, lineWidth: 1)
                    }
                }
                .accessibilityLabel("\(colorName) \(category), \(fit) fit")

            VStack(spacing: 2) {
                Text(garmentColor.name)
                    .font(KISEDesign.Typography.small)
                    .foregroundStyle(KISEDesign.Colors.textSecondary)
                    .lineLimit(1)

                Text("\(category) · \(fit)")
                    .font(.system(size: 10))
                    .foregroundStyle(KISEDesign.Colors.textTertiary)
                    .lineLimit(1)
            }
        }
    }
}
```

- [ ] **Step 2: Regenerate Xcode project**

Run: `cd /Users/lucasgalhardo/Documents/Projects/vesti && xcodegen generate`

- [ ] **Step 3: Build to verify compilation**

Run: `xcodebuild build -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add KISE/Sources/Views/Shared/ColorTileView.swift
git commit -m "feat: add ColorTileView component for wardrobe grid"
```

---

### Task 4: Add hue-based sorting to WardrobeViewModel

**Files:**
- Modify: `KISE/Sources/ViewModels/WardrobeViewModel.swift`
- Modify: `KISE/Tests/ViewModels/WardrobeViewModelTests.swift`

- [ ] **Step 1: Add hue sorting test**

Append to `WardrobeViewModelTests.swift`:

```swift
    @MainActor
    func testFilterPiecesSortedByHue() {
        // Navy (chromatic, hue ~0.6) should sort before White (neutral, hue 2.0+)
        let white = GarmentPiece(category: .tShirt, color: "white", colorHex: "#FFFFFF", fit: .slim, material: "cotton", weight: .light, formality: .casual)
        let navy = GarmentPiece(category: .polo, color: "navy", colorHex: "#1B2A4A", fit: .regular, material: "cotton", weight: .mid, formality: .smartCasual)

        let vm = WardrobeViewModel()
        vm.selectedTab = nil
        let sorted = vm.filterPieces([white, navy])
        XCTAssertEqual(sorted.first?.color, "navy", "Chromatic colors should sort before neutrals")
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:KISETests/WardrobeViewModelTests/testFilterPiecesSortedByHue 2>&1 | tail -20`
Expected: FAIL — no sorting applied yet

- [ ] **Step 3: Add hue sorting to filterPieces**

Replace `filterPieces` in `WardrobeViewModel.swift`:

```swift
    func filterPieces(_ pieces: [GarmentPiece]) -> [GarmentPiece] {
        let active = pieces.filter(\.isActive)
        let filtered: [GarmentPiece]
        if let tab = selectedTab {
            filtered = active.filter { $0.category.tabGroup == tab }
        } else {
            filtered = active
        }
        return filtered.sorted { a, b in
            let colorA = GarmentColor.resolve(color: a.color, hex: a.colorHex)
            let colorB = GarmentColor.resolve(color: b.color, hex: b.colorHex)
            return colorA.hueSortValue < colorB.hueSortValue
        }
    }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:KISETests/WardrobeViewModelTests 2>&1 | tail -20`
Expected: PASS — all 5 tests pass

- [ ] **Step 5: Commit**

```bash
git add KISE/Sources/ViewModels/WardrobeViewModel.swift KISE/Tests/ViewModels/WardrobeViewModelTests.swift
git commit -m "feat: add hue-based sorting to wardrobe grid"
```

---

### Task 5: Update WardrobeView to use ColorTileView

**Files:**
- Modify: `KISE/Sources/Views/Wardrobe/WardrobeView.swift`

- [ ] **Step 1: Replace garmentCard with ColorTileView**

Replace the `garmentCard` method (lines 111-137) with:

```swift
    private func garmentCard(_ piece: GarmentPiece) -> some View {
        ColorTileView(
            colorHex: piece.colorHex,
            colorName: piece.color,
            category: piece.category.displayName,
            fit: piece.fit.displayName
        )
    }
```

- [ ] **Step 2: Remove CatalogImageService import** (if present as explicit import — it's used as a static call, which will now error)

Check that `WardrobeView.swift` no longer references `CatalogImageService`. The replacement in step 1 removes all references.

- [ ] **Step 3: Build to verify**

Run: `xcodebuild build -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add KISE/Sources/Views/Wardrobe/WardrobeView.swift
git commit -m "feat: replace wardrobe image cards with color tiles"
```

---

### Task 6: Update GarmentDetailView to use color swatch

**Files:**
- Modify: `KISE/Sources/Views/Wardrobe/GarmentDetailView.swift`

- [ ] **Step 1: Replace catalog image section with color swatch**

Replace the image `Group` block (lines 12-31, including the `.frame(maxWidth: 280)` and `.kiseCard()` modifiers) with:

```swift
                // Color swatch
                VStack(spacing: KISEDesign.Spacing.sm) {
                    let garmentColor = GarmentColor.resolve(color: piece.color, hex: piece.colorHex)

                    RoundedRectangle(cornerRadius: KISEDesign.Radius.md)
                        .fill(Color(hex: piece.colorHex))
                        .aspectRatio(3 / 4, contentMode: .fit)
                        .overlay {
                            if garmentColor.needsBorder {
                                RoundedRectangle(cornerRadius: KISEDesign.Radius.md)
                                    .strokeBorder(KISEDesign.Colors.border, lineWidth: 1)
                            }
                        }

                    Text(garmentColor.name)
                        .font(KISEDesign.Typography.caption)
                        .foregroundStyle(KISEDesign.Colors.textSecondary)
                }
                .frame(maxWidth: 280)
                .kiseCard()
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild build -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add KISE/Sources/Views/Wardrobe/GarmentDetailView.swift
git commit -m "feat: replace catalog image with color swatch in garment detail"
```

---

## Chunk 3: Suggestion Views

### Task 7: Create ColorCompositionView

**Files:**
- Create: `KISE/Sources/Views/Suggestion/ColorCompositionView.swift`

- [ ] **Step 1: Create ColorCompositionView**

```swift
// KISE/Sources/Views/Suggestion/ColorCompositionView.swift
import SwiftUI

struct ColorCompositionView: View {
    let pieces: [GarmentPiece]
    var swappablePieceID: String?
    var onSwap: (() -> Void)?
    @State private var selectedPieceID: UUID?

    private var sortedPieces: [GarmentPiece] {
        pieces.sorted { a, b in
            CompositionLayout.sizePriority(for: a.category) > CompositionLayout.sizePriority(for: b.category)
        }
    }

    private var layout: CompositionLayout {
        CompositionLayout.pick(for: pieces.map(\.id))
    }

    var body: some View {
        VStack(spacing: KISEDesign.Spacing.md) {
            // Composition
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let paired = Array(zip(sortedPieces, layout.blocks))

                ZStack {
                    ForEach(Array(paired.enumerated()), id: \.offset) { index, pair in
                        let (piece, block) = pair
                        let isSelected = selectedPieceID == piece.id

                        Rectangle()
                            .fill(Color(hex: piece.colorHex))
                            .frame(
                                width: block.relativeWidth * w,
                                height: block.relativeHeight * h
                            )
                            .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
                            .scaleEffect(isSelected ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: isSelected)
                            .position(
                                x: (block.relativeX + block.relativeWidth / 2) * w,
                                y: (block.relativeY + block.relativeHeight / 2) * h
                            )
                            .zIndex(isSelected ? 10 : Double(index))
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedPieceID = selectedPieceID == piece.id ? nil : piece.id
                                }
                            }
                            .accessibilityLabel(
                                "\(GarmentColor.resolve(color: piece.color, hex: piece.colorHex).name) \(piece.category.displayName)"
                            )
                    }
                }
            }
            .aspectRatio(4 / 3, contentMode: .fit)
            .padding(.horizontal, KISEDesign.Spacing.md)

            // Labels
            Text(labelText)
                .font(KISEDesign.Typography.small)
                .foregroundStyle(KISEDesign.Colors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Floating detail card
            if let selectedID = selectedPieceID,
               let piece = pieces.first(where: { $0.id == selectedID }) {
                HStack {
                    VStack(alignment: .leading, spacing: KISEDesign.Spacing.xs) {
                        Text(piece.category.displayName)
                            .font(KISEDesign.Typography.subtitle)
                            .foregroundStyle(KISEDesign.Colors.textPrimary)
                        HStack(spacing: KISEDesign.Spacing.md) {
                            detailLabel("Fit", piece.fit.displayName)
                            detailLabel("Material", piece.material.capitalized)
                            detailLabel("Formality", piece.formality.displayName)
                        }
                    }

                    Spacer()

                    // Swap button if this piece has an alternative
                    if swappablePieceID == piece.id.uuidString, let onSwap {
                        Button(action: onSwap) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.body)
                                .foregroundStyle(KISEDesign.Colors.accent)
                                .padding(KISEDesign.Spacing.sm)
                        }
                    }
                }
                .padding(KISEDesign.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .kiseCard()
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var labelText: String {
        sortedPieces.map { piece in
            let color = GarmentColor.resolve(color: piece.color, hex: piece.colorHex)
            return "\(color.name) \(piece.category.displayName)"
        }.joined(separator: " · ")
    }

    private func detailLabel(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(KISEDesign.Colors.textTertiary)
            Text(value)
                .font(KISEDesign.Typography.caption)
                .foregroundStyle(KISEDesign.Colors.textSecondary)
        }
    }
}
```

- [ ] **Step 2: Regenerate Xcode project**

Run: `cd /Users/lucasgalhardo/Documents/Projects/vesti && xcodegen generate`

- [ ] **Step 3: Build to verify**

Run: `xcodebuild build -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add KISE/Sources/Views/Suggestion/ColorCompositionView.swift
git commit -m "feat: add ColorCompositionView with 配色辞典 overlapping block composition"
```

---

### Task 8: Update SuggestionView to use ColorCompositionView

**Files:**
- Modify: `KISE/Sources/Views/Suggestion/SuggestionView.swift`

- [ ] **Step 1: Replace outfitCards with ColorCompositionView**

Replace the `outfitCards` computed property (lines 218-230) with:

```swift
    private var outfitCards: some View {
        ColorCompositionView(
            pieces: viewModel.suggestedPieces,
            swappablePieceID: viewModel.alternativeSwap?.swapPieceID,
            onSwap: {
                withAnimation { viewModel.applyAlternative() }
            }
        )
    }
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild build -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add KISE/Sources/Views/Suggestion/SuggestionView.swift
git commit -m "feat: replace outfit piece cards with color composition in suggestion view"
```

---

## Chunk 4: Registration & Cleanup

### Task 9: Create CuratedColorPicker

**Files:**
- Create: `KISE/Sources/Views/Registration/CuratedColorPicker.swift`

- [ ] **Step 1: Create CuratedColorPicker**

```swift
// KISE/Sources/Views/Registration/CuratedColorPicker.swift
import SwiftUI

struct CuratedColorPicker: View {
    let onSelect: (GarmentColor) -> Void
    @State private var showCustomPicker = false
    @State private var customColor: Color = .gray

    var body: some View {
        VStack(alignment: .leading, spacing: KISEDesign.Spacing.lg) {
            Text("What color?")
                .font(KISEDesign.Typography.title)
                .foregroundStyle(KISEDesign.Colors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: KISEDesign.Spacing.md) {
                    ForEach(GarmentColor.allColors) { color in
                        Button {
                            onSelect(color)
                        } label: {
                            VStack(spacing: KISEDesign.Spacing.xs) {
                                RoundedRectangle(cornerRadius: KISEDesign.Radius.sm)
                                    .fill(color.color)
                                    .frame(width: 56, height: 56)
                                    .overlay {
                                        if color.needsBorder {
                                            RoundedRectangle(cornerRadius: KISEDesign.Radius.sm)
                                                .strokeBorder(KISEDesign.Colors.border, lineWidth: 1)
                                        }
                                    }
                                Text(color.name)
                                    .font(KISEDesign.Typography.small)
                                    .foregroundStyle(KISEDesign.Colors.textSecondary)
                                    .lineLimit(1)
                                    .frame(width: 56)
                            }
                        }
                    }

                    // Custom color "+" button
                    Button {
                        showCustomPicker = true
                    } label: {
                        VStack(spacing: KISEDesign.Spacing.xs) {
                            RoundedRectangle(cornerRadius: KISEDesign.Radius.sm)
                                .strokeBorder(KISEDesign.Colors.border, style: StrokeStyle(lineWidth: 1, dash: [4]))
                                .frame(width: 56, height: 56)
                                .overlay {
                                    Image(systemName: "plus")
                                        .font(.title3)
                                        .foregroundStyle(KISEDesign.Colors.textTertiary)
                                }
                            Text("Custom")
                                .font(KISEDesign.Typography.small)
                                .foregroundStyle(KISEDesign.Colors.textTertiary)
                                .frame(width: 56)
                        }
                    }
                }
                .padding(.horizontal, KISEDesign.Spacing.md)
            }
        }
        .sheet(isPresented: $showCustomPicker) {
            NavigationStack {
                ColorPicker("Pick a color", selection: $customColor, supportsOpacity: false)
                    .labelsHidden()
                    .padding(KISEDesign.Spacing.xl)
                    .navigationTitle("Custom Color")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showCustomPicker = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                let hex = customColor.toHex()
                                let garmentColor = GarmentColor(customHex: hex)
                                showCustomPicker = false
                                onSelect(garmentColor)
                            }
                        }
                    }
            }
            .presentationDetents([.medium])
        }
    }
}

// MARK: - Color to hex

private extension Color {
    func toHex() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
```

- [ ] **Step 2: Regenerate Xcode project**

Run: `cd /Users/lucasgalhardo/Documents/Projects/vesti && xcodegen generate`

- [ ] **Step 3: Build to verify**

Run: `xcodebuild build -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add KISE/Sources/Views/Registration/CuratedColorPicker.swift
git commit -m "feat: add CuratedColorPicker with horizontal palette and custom color support"
```

---

### Task 10: Update Registration Flow — remove confirm step, use CuratedColorPicker

**Files:**
- Modify: `KISE/Sources/ViewModels/RegistrationViewModel.swift`
- Modify: `KISE/Sources/Views/Registration/RegistrationFlowView.swift`
- Modify: `KISE/Sources/Views/Registration/AttributeStepView.swift`
- Modify: `KISE/Tests/ViewModels/RegistrationViewModelTests.swift`

- [ ] **Step 1: Update RegistrationViewModel — remove confirm step**

In `KISE/Sources/ViewModels/RegistrationViewModel.swift`:

Add a `showAddedConfirmation` property to `RegistrationViewModel`:
```swift
    var showAddedConfirmation = false
```

Replace the `RegistrationStep` enum (line 5-11):
```swift
enum RegistrationStep: Int, CaseIterable, Comparable {
    case category, color, fit, material, weight, formality

    static func < (lhs: RegistrationStep, rhs: RegistrationStep) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
```

Replace `selectFormality` (line 74-77):
```swift
    func selectFormality(_ formality: Formality) {
        selectedFormality = formality
        // No more confirm step — flow ends here, save is triggered by the view
    }
```

Remove `catalogImageKey` computed property (lines 38-43).

- [ ] **Step 2: Update RegistrationFlowView — remove confirm case, save after formality**

Replace the `.formality` case and `.confirm` case (lines 52-84) with:

```swift
                    case .formality:
                        OptionPickerStepView(
                            title: "Formality level?",
                            options: Formality.allCases,
                            labelFor: { $0.displayName },
                            suggested: viewModel.suggestedFormality
                        ) { formality in
                            viewModel.selectFormality(formality)
                            if viewModel.savePiece(context: modelContext) {
                                viewModel.showAddedConfirmation = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    dismiss()
                                }
                            }
                        }
```

Add an overlay to the `NavigationStack` (after `.toolbar` closing brace) for the "Added!" toast:
```swift
            .overlay {
                if viewModel.showAddedConfirmation {
                    VStack {
                        Spacer()
                        Text("Added!")
                            .font(KISEDesign.Typography.subtitle)
                            .foregroundStyle(KISEDesign.Colors.background)
                            .padding(.horizontal, KISEDesign.Spacing.xl)
                            .padding(.vertical, KISEDesign.Spacing.md)
                            .background(KISEDesign.Colors.accent)
                            .clipShape(Capsule())
                            .padding(.bottom, KISEDesign.Spacing.xxl)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeOut(duration: 0.3), value: viewModel.showAddedConfirmation)
                }
            }
```

Replace the `.color` case (lines 20-23) with:

```swift
                    case .color:
                        CuratedColorPicker { color in
                            withAnimation { viewModel.selectColor(color) }
                        }
```

- [ ] **Step 3: Remove old ColorPickerStepView from AttributeStepView.swift**

Delete the entire `ColorPickerStepView` struct (lines 4-42) from `AttributeStepView.swift`. Keep `OptionPickerStepView` and `MaterialPickerStepView`.

- [ ] **Step 4: Update tests**

In `RegistrationViewModelTests.swift`:

In `testFullFlowProducesPiece`, delete line 71:
```swift
        XCTAssertEqual(piece?.catalogImageID, "jeans_indigo_straight")
```

Add a test verifying formality is the last step (no `.confirm` after it):
```swift
    func testFormalityIsLastStep() {
        let vm = RegistrationViewModel()
        vm.selectCategory(.jeans)
        vm.selectColor(GarmentColor.byName("indigo")!)
        vm.selectFit(.straight)
        vm.selectMaterial("denim")
        vm.selectWeight(.mid)
        vm.selectFormality(.casual)
        // After formality, step stays at .formality (no .confirm)
        XCTAssertEqual(vm.currentStep, .formality)
    }
```

- [ ] **Step 5: Run all tests**

Run: `xcodebuild test -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:KISETests/RegistrationViewModelTests 2>&1 | tail -20`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add KISE/Sources/ViewModels/RegistrationViewModel.swift KISE/Sources/Views/Registration/RegistrationFlowView.swift KISE/Sources/Views/Registration/AttributeStepView.swift KISE/Tests/ViewModels/RegistrationViewModelTests.swift
git commit -m "feat: remove confirm step from registration, use CuratedColorPicker"
```

---

### Task 11: Remove dead code

**Files:**
- Delete: `KISE/Sources/Views/Registration/CatalogConfirmView.swift`
- Delete: `KISE/Sources/Services/CatalogImageService.swift`
- Delete: `KISE/Sources/Views/Suggestion/OutfitPieceCard.swift`
- Delete: `KISE/Tests/Services/CatalogImageServiceTests.swift`
- Modify: `KISE/Sources/Models/GarmentPiece.swift` — remove `catalogImageID`
- Modify: `KISE/Tests/Models/GarmentPieceTests.swift` — remove `testCatalogImageID` test

- [ ] **Step 1: Remove catalogImageID from GarmentPiece**

In `GarmentPiece.swift`, delete lines 19-24 (the `catalogImageID` computed property):

```swift
    /// Computed catalog image asset key: {category}_{color}_{fit}
    var catalogImageID: String {
        let colorKey = GarmentColor.byName(color)?.assetKey ?? color.lowercased()
        return "\(category.rawValue)_\(colorKey)_\(fit.rawValue)"
            .replacingOccurrences(of: "tShirt", with: "tshirt")
    }
```

- [ ] **Step 2: Remove testCatalogImageID from GarmentPieceTests.swift**

Delete the `testCatalogImageID` method (lines 46-58) from `KISE/Tests/Models/GarmentPieceTests.swift`:

```swift
    @MainActor
    func testCatalogImageID() {
        let piece = GarmentPiece(
            category: .jeans,
            color: "indigo",
            colorHex: "#3F5277",
            fit: .straight,
            material: "denim",
            weight: .mid,
            formality: .casual
        )
        XCTAssertEqual(piece.catalogImageID, "jeans_indigo_straight")
    }
```

- [ ] **Step 3: Delete dead files**

```bash
rm KISE/Sources/Views/Registration/CatalogConfirmView.swift
rm KISE/Sources/Services/CatalogImageService.swift
rm KISE/Sources/Views/Suggestion/OutfitPieceCard.swift
rm KISE/Tests/Services/CatalogImageServiceTests.swift
```

- [ ] **Step 4: Regenerate Xcode project**

Run: `cd /Users/lucasgalhardo/Documents/Projects/vesti && xcodegen generate`

- [ ] **Step 5: Build and run all tests**

Run: `xcodebuild test -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -30`
Expected: BUILD SUCCEEDED, all tests pass. No references to deleted files remain.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "chore: remove CatalogConfirmView, CatalogImageService, OutfitPieceCard, and catalogImageID"
```

---

### Task 12: Final verification — all tests pass

**Files:** None (verification only)

- [ ] **Step 1: Run full test suite**

Run: `xcodebuild test -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E '(Test Suite|Tests|Passed|Failed|Error)'`
Expected: All test suites pass, 0 failures

- [ ] **Step 2: Verify no references to removed code**

Search for stale references:
```bash
grep -r "CatalogImageService\|CatalogConfirmView\|OutfitPieceCard\|catalogImageID\|catalogImageKey\|assetKey" KISE/Sources/ --include="*.swift"
```
Expected: No matches (the `assetKey` on `StyleArchetype` in `Enums.swift` is unrelated and acceptable)

- [ ] **Step 3: Verify build succeeds clean**

```bash
xcodebuild clean build -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -5
```
Expected: BUILD SUCCEEDED
