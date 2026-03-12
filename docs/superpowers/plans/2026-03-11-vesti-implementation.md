# VESTI Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build VESTI MVP — an iOS wardrobe consultant app that suggests daily outfits using Claude API, based on the user's style archetypes, registered pieces, weather, and occasion.

**Architecture:** Native iOS app (SwiftUI + SwiftData) communicates with a stateless Cloudflare Worker proxy that forwards suggestion requests to Claude API. All user data lives on-device. Catalog images are pre-generated and bundled as app assets. WeatherKit provides weather context.

**Tech Stack:** Swift/SwiftUI, SwiftData, WeatherKit, XCTest, xcodegen (project generation), Cloudflare Workers (TypeScript), Claude API (Anthropic)

**Spec:** `docs/superpowers/specs/2026-03-11-vesti-design.md`

---

## File Structure

### iOS App (`VESTI/`)

```
VESTI/
├── Sources/
│   ├── App/
│   │   ├── VESTIApp.swift                  # App entry, model container, onboarding gate
│   │   └── AppState.swift                  # Observable app state (has completed onboarding, etc.)
│   │
│   ├── Models/
│   │   ├── Enums.swift                     # GarmentCategory, Fit, FabricWeight, Formality, Occasion, StyleArchetype
│   │   ├── GarmentColor.swift              # Predefined color palette (name, hex, asset key)
│   │   ├── StyleProfile.swift              # SwiftData model
│   │   ├── GarmentPiece.swift              # SwiftData model
│   │   ├── OutfitSuggestion.swift          # SwiftData model
│   │   ├── Feedback.swift                  # SwiftData model
│   │   └── WeatherSnapshot.swift           # Codable struct (embedded in OutfitSuggestion)
│   │
│   ├── Services/
│   │   ├── CatalogImageService.swift       # Image asset lookup by category+color+fit
│   │   ├── WeatherService.swift            # WeatherKit wrapper, caching, error handling
│   │   ├── SuggestionService.swift         # Proxy API client, request building, response parsing
│   │   └── SuggestionPrefetchService.swift # Background refresh orchestration
│   │
│   ├── ViewModels/
│   │   ├── OnboardingViewModel.swift       # Style selection state, validation, persistence
│   │   ├── RegistrationViewModel.swift     # Step-by-step piece registration state machine
│   │   ├── WardrobeViewModel.swift         # Piece list, filtering, archiving
│   │   └── SuggestionViewModel.swift       # Suggestion loading, feedback, regeneration
│   │
│   ├── Views/
│   │   ├── Onboarding/
│   │   │   └── StyleOnboardingView.swift   # Moodboard grid, archetype cards, continue button
│   │   │
│   │   ├── Registration/
│   │   │   ├── RegistrationFlowView.swift  # Modal container managing step navigation
│   │   │   ├── CategoryPickerView.swift    # Grid of garment type icons
│   │   │   ├── AttributeStepView.swift     # Reusable step view for color/fit/material/weight/formality
│   │   │   └── CatalogConfirmView.swift    # Shows matched image, confirm or take photo
│   │   │
│   │   ├── Wardrobe/
│   │   │   ├── WardrobeView.swift          # Tab bar + grid + category filter
│   │   │   └── GarmentDetailView.swift     # Piece detail sheet with attributes
│   │   │
│   │   ├── Suggestion/
│   │   │   ├── SuggestionView.swift        # Home screen — outfit cards, reasoning, feedback
│   │   │   ├── OutfitCardView.swift        # Single piece card (image + label)
│   │   │   ├── SuggestionControlsView.swift # Pull-down occasion + boldness controls
│   │   │   └── SuggestionLoadingView.swift # Skeleton card animation
│   │   │
│   │   ├── Settings/
│   │   │   └── SettingsView.swift          # Edit archetypes, location, about
│   │   │
│   │   └── Shared/
│   │       ├── DesignSystem.swift          # Colors, fonts, spacing, shadows
│   │       └── EmptyStateView.swift        # Reusable empty/minimum pieces state
│   │
│   └── Utilities/
│       └── MaterialDefaults.swift          # Auto-suggest weight/formality from category+material
│
├── Tests/
│   ├── Models/
│   │   ├── EnumsTests.swift
│   │   ├── GarmentColorTests.swift
│   │   └── GarmentPieceTests.swift
│   ├── Services/
│   │   ├── CatalogImageServiceTests.swift
│   │   ├── WeatherServiceTests.swift
│   │   └── SuggestionServiceTests.swift
│   └── ViewModels/
│       ├── OnboardingViewModelTests.swift
│       ├── RegistrationViewModelTests.swift
│       ├── WardrobeViewModelTests.swift
│       └── SuggestionViewModelTests.swift
│
├── Assets.xcassets/
│   ├── Colors/                             # Design system colors
│   ├── Catalog/                            # Garment images (placeholder set for MVP testing)
│   └── Onboarding/                         # Archetype moodboard images
│
├── Preview Content/
│   └── PreviewData.swift                   # Sample data for SwiftUI previews
│
└── Info.plist
```

### Proxy Server (`vesti-proxy/`)

```
vesti-proxy/
├── src/
│   ├── index.ts              # Worker entry point, request routing
│   ├── handler.ts            # Main suggestion handler
│   ├── prompt.ts             # System prompt builder
│   ├── archetypes.ts         # Style archetype brief texts
│   ├── tool-schema.ts        # Claude tool definition for structured output
│   └── types.ts              # Request/response TypeScript interfaces
├── test/
│   ├── handler.test.ts
│   ├── prompt.test.ts
│   └── archetypes.test.ts
├── wrangler.toml             # Cloudflare Workers config
├── package.json
└── tsconfig.json
```

### Project Config (repo root)

```
vesti/
├── project.yml               # xcodegen project spec
├── CLAUDE.md
└── docs/
    └── superpowers/
        ├── specs/
        │   └── 2026-03-11-vesti-design.md
        └── plans/
            └── 2026-03-11-vesti-implementation.md
```

---

## Chunk 1: Project Foundation + Data Models

### Task 1: Xcode Project Setup

**Files:**
- Create: `project.yml`
- Create: `VESTI/Sources/App/VESTIApp.swift`
- Create: `.gitignore`

- [ ] **Step 1: Install xcodegen if needed**

Run: `brew install xcodegen` (skip if already installed)

- [ ] **Step 2: Create .gitignore**

```gitignore
# Xcode
*.xcodeproj/xcuserdata/
*.xcworkspace/xcuserdata/
DerivedData/
build/
*.pbxuser
*.mode1v3
*.mode2v3
*.perspectivev3
*.moved-aside
*.hmap
*.ipa
*.dSYM.zip
*.dSYM

# Swift Package Manager
.build/
Packages/
Package.pins
Package.resolved

# Node (proxy)
node_modules/
dist/
.wrangler/

# Misc
.DS_Store
*.swp
.env
```

- [ ] **Step 3: Create project.yml for xcodegen**

```yaml
name: VESTI
options:
  bundleIdPrefix: com.vesti
  deploymentTarget:
    iOS: "17.0"
  xcodeVersion: "16.0"
  generateEmptyDirectories: true

settings:
  base:
    SWIFT_VERSION: "5.9"
    MARKETING_VERSION: "1.0.0"
    CURRENT_PROJECT_VERSION: 1

targets:
  VESTI:
    type: application
    platform: iOS
    sources:
      - path: VESTI/Sources
      - path: VESTI/Assets.xcassets
      - path: VESTI/Preview Content
    settings:
      base:
        INFOPLIST_FILE: VESTI/Info.plist
        PRODUCT_BUNDLE_IDENTIFIER: com.vesti.app
        CODE_SIGN_STYLE: Automatic
    entitlements:
      path: VESTI/VESTI.entitlements
      properties:
        com.apple.developer.weatherkit: true

  VESTITests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: VESTI/Tests
    dependencies:
      - target: VESTI
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.vesti.app.tests
```

- [ ] **Step 4: Create directory structure**

Run:
```bash
mkdir -p VESTI/Sources/{App,Models,Services,ViewModels,Views/{Onboarding,Registration,Wardrobe,Suggestion,Settings,Shared},Utilities}
mkdir -p VESTI/Tests/{Models,Services,ViewModels}
mkdir -p VESTI/Assets.xcassets/{Colors,Catalog,Onboarding}
mkdir -p VESTI/"Preview Content"
```

- [ ] **Step 5: Create Info.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>VESTI</string>
    <key>CFBundleDisplayName</key>
    <string>VESTI</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>VESTI uses your location to check the weather and suggest weather-appropriate outfits.</string>
    <key>UILaunchScreen</key>
    <dict/>
</dict>
</plist>
```

- [ ] **Step 6: Create entitlements file**

Create `VESTI/VESTI.entitlements`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.weatherkit</key>
    <true/>
</dict>
</plist>
```

- [ ] **Step 7: Create minimal app entry point**

```swift
// VESTI/Sources/App/VESTIApp.swift
import SwiftUI
import SwiftData

@main
struct VESTIApp: App {
    var body: some Scene {
        WindowGroup {
            Text("VESTI")
        }
        .modelContainer(for: [
            StyleProfile.self,
            GarmentPiece.self,
            OutfitSuggestion.self,
        ])
    }
}
```

- [ ] **Step 8: Generate Xcode project and verify it builds**

Run:
```bash
cd /Users/lucasgalhardo/Documents/Projects/vesti
xcodegen generate
xcodebuild -project VESTI.xcodeproj -scheme VESTI -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

Expected: Build may fail due to missing model types — that's fine, we'll add them in the next task.

- [ ] **Step 9: Commit**

```bash
git add .gitignore project.yml VESTI/ VESTI.xcodeproj
git commit -m "feat: initialize Xcode project with xcodegen"
```

---

### Task 2: Core Enums and Color Palette

**Files:**
- Create: `VESTI/Sources/Models/Enums.swift`
- Create: `VESTI/Sources/Models/GarmentColor.swift`
- Test: `VESTI/Tests/Models/EnumsTests.swift`
- Test: `VESTI/Tests/Models/GarmentColorTests.swift`

- [ ] **Step 1: Write tests for enums**

```swift
// VESTI/Tests/Models/EnumsTests.swift
import XCTest
@testable import VESTI

final class EnumsTests: XCTestCase {

    func testGarmentCategoryDisplayName() {
        XCTAssertEqual(GarmentCategory.tShirt.displayName, "T-Shirt")
        XCTAssertEqual(GarmentCategory.smartCasual.rawValue, "smartCasual")  // verify raw value
    }

    func testGarmentCategoryTabGroup() {
        XCTAssertEqual(GarmentCategory.tShirt.tabGroup, .tops)
        XCTAssertEqual(GarmentCategory.jeans.tabGroup, .bottoms)
        XCTAssertEqual(GarmentCategory.jacket.tabGroup, .outerwear)
        XCTAssertEqual(GarmentCategory.shoes.tabGroup, .shoes)
    }

    func testFitAvailabilityByCategory() {
        let jeansFits = GarmentCategory.jeans.availableFits
        XCTAssertTrue(jeansFits.contains(.straight))
        XCTAssertTrue(jeansFits.contains(.slim))

        let tshirtFits = GarmentCategory.tShirt.availableFits
        XCTAssertFalse(tshirtFits.contains(.straight))
        XCTAssertTrue(tshirtFits.contains(.oversized))
    }

    func testMaterialAvailabilityByCategory() {
        let jeansMaterials = GarmentCategory.jeans.availableMaterials
        XCTAssertTrue(jeansMaterials.contains("denim"))
        XCTAssertFalse(jeansMaterials.contains("wool"))

        let sweaterMaterials = GarmentCategory.sweater.availableMaterials
        XCTAssertTrue(sweaterMaterials.contains("wool"))
        XCTAssertFalse(sweaterMaterials.contains("denim"))
    }

    func testStyleArchetypeAssetKey() {
        XCTAssertEqual(StyleArchetype.oldMoney.assetKey, "old-money")
        XCTAssertEqual(StyleArchetype.smartCasual.assetKey, "smart-casual")
    }

    func testOccasionDisplayName() {
        XCTAssertEqual(Occasion.everyday.displayName, "Everyday")
        XCTAssertEqual(Occasion.dateNight.displayName, "Date Night")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project VESTI.xcodeproj -scheme VESTITests -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E '(Test Case|error:)' | head -20`

Expected: Compilation errors — types don't exist yet.

- [ ] **Step 3: Implement Enums.swift**

```swift
// VESTI/Sources/Models/Enums.swift
import Foundation

// MARK: - Tab Groups

enum TabGroup: String, CaseIterable {
    case tops, bottoms, outerwear, shoes
}

// MARK: - Garment Category

enum GarmentCategory: String, Codable, CaseIterable, Identifiable {
    case tShirt, shirt, polo, sweater, hoodie
    case jacket, coat
    case jeans, chinos, shorts
    case shoes

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tShirt: "T-Shirt"
        case .shirt: "Shirt"
        case .polo: "Polo"
        case .sweater: "Sweater"
        case .hoodie: "Hoodie"
        case .jacket: "Jacket"
        case .coat: "Coat"
        case .jeans: "Jeans"
        case .chinos: "Chinos"
        case .shorts: "Shorts"
        case .shoes: "Shoes"
        }
    }

    var tabGroup: TabGroup {
        switch self {
        case .tShirt, .shirt, .polo, .sweater, .hoodie: .tops
        case .jeans, .chinos, .shorts: .bottoms
        case .jacket, .coat: .outerwear
        case .shoes: .shoes
        }
    }

    var availableFits: [Fit] {
        switch self {
        case .jeans, .chinos: [.slim, .regular, .relaxed, .straight]
        case .shorts: [.slim, .regular, .relaxed]
        case .tShirt, .shirt, .polo, .sweater, .hoodie: [.slim, .regular, .oversized]
        case .jacket, .coat: [.slim, .regular, .oversized]
        case .shoes: [.regular]
        }
    }

    var availableMaterials: [String] {
        switch self {
        case .tShirt, .polo: ["cotton", "linen", "synthetic"]
        case .shirt: ["cotton", "linen", "synthetic"]
        case .sweater: ["cotton", "wool", "cashmere", "synthetic"]
        case .hoodie: ["cotton", "synthetic"]
        case .jacket: ["cotton", "linen", "wool", "leather", "synthetic"]
        case .coat: ["wool", "cotton", "synthetic"]
        case .jeans: ["denim"]
        case .chinos: ["cotton", "linen"]
        case .shorts: ["cotton", "linen", "denim", "synthetic"]
        case .shoes: ["leather", "suede", "canvas", "synthetic"]
        }
    }

    var defaultFormality: Formality {
        switch self {
        case .tShirt, .hoodie, .shorts: .casual
        case .polo, .sweater, .jeans, .chinos: .smartCasual
        case .shirt, .jacket, .coat, .shoes: .smartCasual
        }
    }
}

// MARK: - Fit

enum Fit: String, Codable, CaseIterable, Identifiable {
    case slim, regular, relaxed, straight, oversized

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }
}

// MARK: - Fabric Weight

enum FabricWeight: String, Codable, CaseIterable, Identifiable {
    case light, mid, heavy

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }

    static func defaultWeight(for material: String) -> FabricWeight {
        switch material.lowercased() {
        case "linen": .light
        case "cotton": .mid
        case "denim": .mid
        case "wool", "cashmere", "leather": .heavy
        case "suede": .mid
        case "canvas": .mid
        case "synthetic": .light
        default: .mid
        }
    }
}

// MARK: - Formality

enum Formality: String, Codable, CaseIterable, Identifiable {
    case casual, smartCasual, formal

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .casual: "Casual"
        case .smartCasual: "Smart Casual"
        case .formal: "Formal"
        }
    }
}

// MARK: - Occasion

enum Occasion: String, Codable, CaseIterable, Identifiable {
    case everyday, meeting, dateNight, nightOut

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .everyday: "Everyday"
        case .meeting: "Meeting"
        case .dateNight: "Date Night"
        case .nightOut: "Night Out"
        }
    }
}

// MARK: - Style Archetype

enum StyleArchetype: String, Codable, CaseIterable, Identifiable {
    case oldMoney, minimalist, smartCasual, streetwear, classic, scandinavian

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .oldMoney: "Old Money"
        case .minimalist: "Minimalist"
        case .smartCasual: "Smart Casual"
        case .streetwear: "Streetwear"
        case .classic: "Classic"
        case .scandinavian: "Scandinavian"
        }
    }

    /// Key used for asset names and API payloads
    var assetKey: String {
        switch self {
        case .oldMoney: "old-money"
        case .minimalist: "minimalist"
        case .smartCasual: "smart-casual"
        case .streetwear: "streetwear"
        case .classic: "classic"
        case .scandinavian: "scandinavian"
        }
    }
}
```

- [ ] **Step 4: Write tests for GarmentColor**

```swift
// VESTI/Tests/Models/GarmentColorTests.swift
import XCTest
@testable import VESTI

final class GarmentColorTests: XCTestCase {

    func testAllColorsHaveValidHex() {
        for color in GarmentColor.allColors {
            XCTAssertTrue(color.hex.hasPrefix("#"), "\(color.name) hex should start with #")
            XCTAssertEqual(color.hex.count, 7, "\(color.name) hex should be 7 chars")
        }
    }

    func testAllColorsHaveAssetKey() {
        for color in GarmentColor.allColors {
            XCTAssertFalse(color.assetKey.isEmpty, "\(color.name) should have an asset key")
            XCTAssertFalse(color.assetKey.contains(" "), "\(color.name) asset key should not have spaces")
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
}
```

- [ ] **Step 5: Implement GarmentColor.swift**

```swift
// VESTI/Sources/Models/GarmentColor.swift
import SwiftUI

struct GarmentColor: Identifiable, Equatable {
    let id: String
    let name: String
    let hex: String
    let assetKey: String

    var color: Color {
        Color(hex: hex)
    }

    static let allColors: [GarmentColor] = [
        GarmentColor(id: "white", name: "White", hex: "#FFFFFF", assetKey: "white"),
        GarmentColor(id: "cream", name: "Off-White", hex: "#F5F0E8", assetKey: "cream"),
        GarmentColor(id: "lightGray", name: "Light Gray", hex: "#C8C8C8", assetKey: "light-gray"),
        GarmentColor(id: "charcoal", name: "Charcoal", hex: "#4A4A4A", assetKey: "charcoal"),
        GarmentColor(id: "black", name: "Black", hex: "#1A1A1A", assetKey: "black"),
        GarmentColor(id: "navy", name: "Navy", hex: "#1B2A4A", assetKey: "navy"),
        GarmentColor(id: "lightBlue", name: "Light Blue", hex: "#A4C8E8", assetKey: "light-blue"),
        GarmentColor(id: "olive", name: "Olive", hex: "#6B7F4E", assetKey: "olive"),
        GarmentColor(id: "khaki", name: "Khaki", hex: "#C4A46C", assetKey: "khaki"),
        GarmentColor(id: "brown", name: "Brown", hex: "#6B4226", assetKey: "brown"),
        GarmentColor(id: "burgundy", name: "Burgundy", hex: "#722F37", assetKey: "burgundy"),
        GarmentColor(id: "terracotta", name: "Terracotta", hex: "#C75B39", assetKey: "terracotta"),
        GarmentColor(id: "sage", name: "Sage", hex: "#9CAF88", assetKey: "sage"),
        GarmentColor(id: "indigo", name: "Indigo", hex: "#3F5277", assetKey: "indigo"),
        GarmentColor(id: "camel", name: "Camel", hex: "#C19A6B", assetKey: "camel"),
    ]

    static func byName(_ name: String) -> GarmentColor? {
        allColors.first { $0.name.lowercased() == name.lowercased() || $0.id == name.lowercased() }
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

- [ ] **Step 6: Run tests to verify they pass**

Run: `xcodebuild test -project VESTI.xcodeproj -scheme VESTITests -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E '(Test Case|Executed)' | tail -20`

Expected: All enum and color tests pass.

- [ ] **Step 7: Commit**

```bash
git add VESTI/Sources/Models/Enums.swift VESTI/Sources/Models/GarmentColor.swift VESTI/Tests/Models/EnumsTests.swift VESTI/Tests/Models/GarmentColorTests.swift
git commit -m "feat: add core enums and predefined color palette"
```

---

### Task 3: SwiftData Models

**Files:**
- Create: `VESTI/Sources/Models/StyleProfile.swift`
- Create: `VESTI/Sources/Models/GarmentPiece.swift`
- Create: `VESTI/Sources/Models/OutfitSuggestion.swift`
- Create: `VESTI/Sources/Models/Feedback.swift`
- Create: `VESTI/Sources/Models/WeatherSnapshot.swift`
- Test: `VESTI/Tests/Models/GarmentPieceTests.swift`

- [ ] **Step 1: Write tests for GarmentPiece**

```swift
// VESTI/Tests/Models/GarmentPieceTests.swift
import XCTest
import SwiftData
@testable import VESTI

final class GarmentPieceTests: XCTestCase {

    private var container: ModelContainer!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(
            for: StyleProfile.self, GarmentPiece.self, OutfitSuggestion.self,
            configurations: config
        )
    }

    override func tearDown() {
        container = nil
        super.tearDown()
    }

    @MainActor
    func testCreateGarmentPiece() {
        let context = container.mainContext
        let piece = GarmentPiece(
            category: .tShirt,
            color: "white",
            colorHex: "#FFFFFF",
            fit: .slim,
            material: "cotton",
            weight: .light,
            formality: .casual
        )
        context.insert(piece)
        try! context.save()

        let fetched = try! context.fetch(FetchDescriptor<GarmentPiece>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.category, .tShirt)
        XCTAssertEqual(fetched.first?.color, "white")
        XCTAssertTrue(fetched.first?.isActive ?? false)
    }

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

    @MainActor
    func testArchivePiece() {
        let piece = GarmentPiece(
            category: .jacket,
            color: "navy",
            colorHex: "#1B2A4A",
            fit: .regular,
            material: "wool",
            weight: .heavy,
            formality: .smartCasual
        )
        XCTAssertTrue(piece.isActive)
        piece.isActive = false
        XCTAssertFalse(piece.isActive)
    }

    @MainActor
    func testCreateStyleProfile() {
        let context = container.mainContext
        let profile = StyleProfile(archetypes: [.oldMoney, .minimalist])
        context.insert(profile)
        try! context.save()

        let fetched = try! context.fetch(FetchDescriptor<StyleProfile>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.archetypes, [.oldMoney, .minimalist])
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project VESTI.xcodeproj -scheme VESTITests -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E '(error:)' | head -10`

Expected: Compilation errors — model types don't exist yet.

- [ ] **Step 3: Implement WeatherSnapshot.swift**

```swift
// VESTI/Sources/Models/WeatherSnapshot.swift
import Foundation

struct HourlyEntry: Codable, Equatable {
    let hour: Int
    let temperature: Double
    let condition: String
}

struct WeatherSnapshot: Codable, Equatable {
    let temperature: Double
    let feelsLike: Double
    let humidity: Double
    let windSpeed: Double
    let condition: String
    let hourlyForecast: [HourlyEntry]

    var hasSignificantTransition: Bool {
        guard let minTemp = hourlyForecast.map(\.temperature).min(),
              let maxTemp = hourlyForecast.map(\.temperature).max() else {
            return false
        }
        return (maxTemp - minTemp) > 10
    }
}
```

- [ ] **Step 4: Implement Feedback.swift**

```swift
// VESTI/Sources/Models/Feedback.swift
import Foundation
import SwiftData

@Model
final class Feedback {
    var id: UUID
    var liked: Bool
    var dislikeReason: String?
    var dislikedPieceID: UUID?
    var createdAt: Date

    init(liked: Bool) {
        self.id = UUID()
        self.liked = liked
        self.dislikeReason = nil
        self.dislikedPieceID = nil
        self.createdAt = Date()
    }

    /// Serializes for the suggestion request payload
    var payloadValue: String {
        liked ? "liked" : "disliked"
    }
}
```

- [ ] **Step 5: Implement StyleProfile.swift**

```swift
// VESTI/Sources/Models/StyleProfile.swift
import Foundation
import SwiftData

@Model
final class StyleProfile {
    var id: UUID
    var archetypes: [StyleArchetype]
    var createdAt: Date
    var updatedAt: Date

    init(archetypes: [StyleArchetype]) {
        self.id = UUID()
        self.archetypes = archetypes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
```

- [ ] **Step 6: Implement GarmentPiece.swift**

```swift
// VESTI/Sources/Models/GarmentPiece.swift
import Foundation
import SwiftData

@Model
final class GarmentPiece {
    var id: UUID
    var category: GarmentCategory
    var color: String
    var colorHex: String
    var fit: Fit
    var material: String
    var weight: FabricWeight
    var formality: Formality
    var userPhotoPath: String?
    var isActive: Bool
    var createdAt: Date

    /// Computed catalog image asset key: {category}_{color}_{fit}
    var catalogImageID: String {
        let colorKey = GarmentColor.byName(color)?.assetKey ?? color.lowercased()
        return "\(category.rawValue)_\(colorKey)_\(fit.rawValue)"
            .replacingOccurrences(of: "tShirt", with: "tshirt")
    }

    init(
        category: GarmentCategory,
        color: String,
        colorHex: String,
        fit: Fit,
        material: String,
        weight: FabricWeight,
        formality: Formality
    ) {
        self.id = UUID()
        self.category = category
        self.color = color
        self.colorHex = colorHex
        self.fit = fit
        self.material = material
        self.weight = weight
        self.formality = formality
        self.userPhotoPath = nil
        self.isActive = true
        self.createdAt = Date()
    }
}
```

- [ ] **Step 7: Implement OutfitSuggestion.swift**

```swift
// VESTI/Sources/Models/OutfitSuggestion.swift
import Foundation
import SwiftData

struct AlternativeSwap: Codable, Equatable {
    let swapPieceID: String
    let forPieceID: String
    let reason: String
}

@Model
final class OutfitSuggestion {
    var id: UUID
    var pieceIDs: [UUID]
    var occasion: Occasion?
    var weatherData: Data?
    var reasoning: String
    var layeringNote: String?
    var alternativeSwapData: Data?
    var suggestedAt: Date
    @Relationship var feedback: Feedback?

    var weather: WeatherSnapshot? {
        get {
            guard let data = weatherData else { return nil }
            return try? JSONDecoder().decode(WeatherSnapshot.self, from: data)
        }
        set {
            weatherData = try? JSONEncoder().encode(newValue)
        }
    }

    var alternativeSwap: AlternativeSwap? {
        get {
            guard let data = alternativeSwapData else { return nil }
            return try? JSONDecoder().decode(AlternativeSwap.self, from: data)
        }
        set {
            alternativeSwapData = try? JSONEncoder().encode(newValue)
        }
    }

    init(
        pieceIDs: [UUID],
        occasion: Occasion?,
        weather: WeatherSnapshot?,
        reasoning: String,
        layeringNote: String? = nil,
        alternativeSwap: AlternativeSwap? = nil
    ) {
        self.id = UUID()
        self.pieceIDs = pieceIDs
        self.occasion = occasion
        self.reasoning = reasoning
        self.layeringNote = layeringNote
        self.suggestedAt = Date()
        self.feedback = nil

        self.weatherData = try? JSONEncoder().encode(weather)
        self.alternativeSwapData = try? JSONEncoder().encode(alternativeSwap)
    }
}
```

- [ ] **Step 8: Update VESTIApp.swift with correct model container**

```swift
// VESTI/Sources/App/VESTIApp.swift
import SwiftUI
import SwiftData

@main
struct VESTIApp: App {
    var body: some Scene {
        WindowGroup {
            Text("VESTI")
        }
        .modelContainer(for: [
            StyleProfile.self,
            GarmentPiece.self,
            OutfitSuggestion.self,
            Feedback.self,
        ])
    }
}
```

- [ ] **Step 9: Regenerate project and run tests**

Run:
```bash
cd /Users/lucasgalhardo/Documents/Projects/vesti
xcodegen generate
xcodebuild test -project VESTI.xcodeproj -scheme VESTITests -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E '(Test Case|Executed)' | tail -20
```

Expected: All tests pass.

- [ ] **Step 10: Commit**

```bash
git add VESTI/Sources/Models/ VESTI/Tests/Models/ VESTI/Sources/App/VESTIApp.swift
git commit -m "feat: add SwiftData models (StyleProfile, GarmentPiece, OutfitSuggestion, Feedback)"
```

---

### Task 4: Material Defaults Utility

**Files:**
- Create: `VESTI/Sources/Utilities/MaterialDefaults.swift`

- [ ] **Step 1: Implement MaterialDefaults**

```swift
// VESTI/Sources/Utilities/MaterialDefaults.swift
import Foundation

enum MaterialDefaults {
    /// Returns the auto-suggested fabric weight for a given material
    static func weight(for material: String) -> FabricWeight {
        FabricWeight.defaultWeight(for: material)
    }

    /// Returns the auto-suggested formality for a given category
    static func formality(for category: GarmentCategory) -> Formality {
        category.defaultFormality
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add VESTI/Sources/Utilities/MaterialDefaults.swift
git commit -m "feat: add material defaults utility for auto-suggestions"
```

---

## Chunk 2: Design System + App Shell + Onboarding

### Task 5: Design System

**Files:**
- Create: `VESTI/Sources/Views/Shared/DesignSystem.swift`
- Create: `VESTI/Assets.xcassets/Colors/Contents.json` (color set definitions)

- [ ] **Step 1: Implement DesignSystem.swift**

```swift
// VESTI/Sources/Views/Shared/DesignSystem.swift
import SwiftUI

enum VESTIDesign {

    // MARK: - Colors

    enum Colors {
        static let background = Color(hex: "#F5F3EF")
        static let surface = Color.white
        static let textPrimary = Color(hex: "#1A1A1A")
        static let textSecondary = Color(hex: "#6B6B6B")
        static let textTertiary = Color(hex: "#9B9B9B")
        static let accent = Color(hex: "#1A1A1A")
        static let border = Color(hex: "#E5E1DB")
        static let cardShadow = Color.black.opacity(0.06)
        static let liked = Color(hex: "#4A7C59")
        static let disliked = Color(hex: "#8B4B4B")
    }

    // MARK: - Typography

    enum Typography {
        static let headingFont = "PlayfairDisplay-Regular"
        static let headingBoldFont = "PlayfairDisplay-Bold"

        static func heading(_ size: CGFloat) -> Font {
            .custom(headingFont, size: size)
        }

        static func headingBold(_ size: CGFloat) -> Font {
            .custom(headingBoldFont, size: size)
        }

        static func body(_ size: CGFloat) -> Font {
            .system(size: size)
        }

        static func bodyMedium(_ size: CGFloat) -> Font {
            .system(size: size, weight: .medium)
        }

        // Predefined sizes
        static let largeTitle = heading(32)
        static let title = heading(24)
        static let subtitle = bodyMedium(17)
        static let bodyText = body(15)
        static let caption = body(13)
        static let small = body(11)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
    }
}

// MARK: - Card Style Modifier

struct VESTICardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(VESTIDesign.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: VESTIDesign.Radius.md))
            .shadow(color: VESTIDesign.Colors.cardShadow, radius: 8, x: 0, y: 2)
    }
}

extension View {
    func vestiCard() -> some View {
        modifier(VESTICardStyle())
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add VESTI/Sources/Views/Shared/DesignSystem.swift
git commit -m "feat: add design system (colors, typography, spacing)"
```

---

### Task 6: App State + Routing

**Files:**
- Create: `VESTI/Sources/App/AppState.swift`
- Modify: `VESTI/Sources/App/VESTIApp.swift`

- [ ] **Step 1: Implement AppState**

```swift
// VESTI/Sources/App/AppState.swift
import SwiftUI
import SwiftData

@Observable
final class AppState {
    var hasCompletedOnboarding: Bool = false

    @MainActor
    func checkOnboardingStatus(context: ModelContext) {
        let descriptor = FetchDescriptor<StyleProfile>()
        let profiles = (try? context.fetch(descriptor)) ?? []
        hasCompletedOnboarding = !profiles.isEmpty
    }

    @MainActor
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}
```

- [ ] **Step 2: Update VESTIApp.swift with routing**

```swift
// VESTI/Sources/App/VESTIApp.swift
import SwiftUI
import SwiftData

@main
struct VESTIApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .modelContainer(for: [
            StyleProfile.self,
            GarmentPiece.self,
            OutfitSuggestion.self,
            Feedback.self,
        ])
    }
}

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                MainTabView()
            } else {
                StyleOnboardingView()
            }
        }
        .onAppear {
            appState.checkOnboardingStatus(context: modelContext)
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "tshirt") {
                Text("Suggestions coming soon")
            }
            Tab("Wardrobe", systemImage: "cabinet") {
                Text("Wardrobe coming soon")
            }
        }
        .tint(VESTIDesign.Colors.accent)
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add VESTI/Sources/App/
git commit -m "feat: add app state and onboarding/main routing"
```

---

### Task 7: Onboarding ViewModel

**Files:**
- Create: `VESTI/Sources/ViewModels/OnboardingViewModel.swift`
- Test: `VESTI/Tests/ViewModels/OnboardingViewModelTests.swift`

- [ ] **Step 1: Write tests for OnboardingViewModel**

```swift
// VESTI/Tests/ViewModels/OnboardingViewModelTests.swift
import XCTest
import SwiftData
@testable import VESTI

final class OnboardingViewModelTests: XCTestCase {

    func testInitialState() {
        let vm = OnboardingViewModel()
        XCTAssertTrue(vm.selectedArchetypes.isEmpty)
        XCTAssertFalse(vm.canContinue)
    }

    func testToggleArchetype() {
        let vm = OnboardingViewModel()
        vm.toggleArchetype(.oldMoney)
        XCTAssertTrue(vm.selectedArchetypes.contains(.oldMoney))
        XCTAssertTrue(vm.canContinue)

        vm.toggleArchetype(.oldMoney)
        XCTAssertFalse(vm.selectedArchetypes.contains(.oldMoney))
        XCTAssertFalse(vm.canContinue)
    }

    func testMultipleSelections() {
        let vm = OnboardingViewModel()
        vm.toggleArchetype(.oldMoney)
        vm.toggleArchetype(.minimalist)
        vm.toggleArchetype(.classic)
        XCTAssertEqual(vm.selectedArchetypes.count, 3)
        XCTAssertTrue(vm.canContinue)
    }

    @MainActor
    func testSaveProfile() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: StyleProfile.self, GarmentPiece.self, OutfitSuggestion.self, Feedback.self,
            configurations: config
        )
        let context = container.mainContext

        let vm = OnboardingViewModel()
        vm.toggleArchetype(.oldMoney)
        vm.toggleArchetype(.minimalist)
        vm.saveProfile(context: context)

        let profiles = try context.fetch(FetchDescriptor<StyleProfile>())
        XCTAssertEqual(profiles.count, 1)
        XCTAssertEqual(profiles.first?.archetypes, [.oldMoney, .minimalist])
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: Compilation errors — OnboardingViewModel doesn't exist.

- [ ] **Step 3: Implement OnboardingViewModel**

```swift
// VESTI/Sources/ViewModels/OnboardingViewModel.swift
import SwiftUI
import SwiftData

@Observable
final class OnboardingViewModel {
    var selectedArchetypes: Set<StyleArchetype> = []

    var canContinue: Bool {
        !selectedArchetypes.isEmpty
    }

    func toggleArchetype(_ archetype: StyleArchetype) {
        if selectedArchetypes.contains(archetype) {
            selectedArchetypes.remove(archetype)
        } else {
            selectedArchetypes.insert(archetype)
        }
    }

    func isSelected(_ archetype: StyleArchetype) -> Bool {
        selectedArchetypes.contains(archetype)
    }

    @MainActor
    func saveProfile(context: ModelContext) {
        let profile = StyleProfile(archetypes: Array(selectedArchetypes))
        context.insert(profile)
        try? context.save()
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Expected: All 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add VESTI/Sources/ViewModels/OnboardingViewModel.swift VESTI/Tests/ViewModels/OnboardingViewModelTests.swift
git commit -m "feat: add onboarding view model with archetype selection"
```

---

### Task 8: Style Onboarding View

**Files:**
- Create: `VESTI/Sources/Views/Onboarding/StyleOnboardingView.swift`

- [ ] **Step 1: Implement StyleOnboardingView**

```swift
// VESTI/Sources/Views/Onboarding/StyleOnboardingView.swift
import SwiftUI

struct StyleOnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = OnboardingViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: VESTIDesign.Spacing.md),
        GridItem(.flexible(), spacing: VESTIDesign.Spacing.md),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: VESTIDesign.Spacing.sm) {
                Text("VESTI")
                    .font(VESTIDesign.Typography.largeTitle)
                    .foregroundStyle(VESTIDesign.Colors.textPrimary)

                Text("Select the styles that inspire you")
                    .font(VESTIDesign.Typography.bodyText)
                    .foregroundStyle(VESTIDesign.Colors.textSecondary)
            }
            .padding(.top, VESTIDesign.Spacing.xxl)
            .padding(.bottom, VESTIDesign.Spacing.lg)

            // Archetype Grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: VESTIDesign.Spacing.md) {
                    ForEach(StyleArchetype.allCases) { archetype in
                        ArchetypeCard(
                            archetype: archetype,
                            isSelected: viewModel.isSelected(archetype)
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.toggleArchetype(archetype)
                            }
                        }
                    }
                }
                .padding(.horizontal, VESTIDesign.Spacing.md)
            }

            // Continue Button
            Button {
                viewModel.saveProfile(context: modelContext)
                appState.completeOnboarding()
            } label: {
                Text("Continue")
                    .font(VESTIDesign.Typography.subtitle)
                    .foregroundStyle(VESTIDesign.Colors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, VESTIDesign.Spacing.md)
                    .background(
                        viewModel.canContinue
                            ? VESTIDesign.Colors.accent
                            : VESTIDesign.Colors.textTertiary
                    )
                    .clipShape(RoundedRectangle(cornerRadius: VESTIDesign.Radius.md))
            }
            .disabled(!viewModel.canContinue)
            .padding(VESTIDesign.Spacing.md)
        }
        .background(VESTIDesign.Colors.background)
    }
}

// MARK: - Archetype Card

private struct ArchetypeCard: View {
    let archetype: StyleArchetype
    let isSelected: Bool

    var body: some View {
        VStack(spacing: VESTIDesign.Spacing.sm) {
            // Placeholder for moodboard image — replace with actual asset
            RoundedRectangle(cornerRadius: VESTIDesign.Radius.sm)
                .fill(VESTIDesign.Colors.border)
                .aspectRatio(3 / 4, contentMode: .fit)
                .overlay {
                    // Attempt to load the archetype image, fall back to text
                    Image(archetype.assetKey)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: VESTIDesign.Radius.sm))
                        // If image doesn't exist, this will show an empty view
                }

            Text(archetype.displayName)
                .font(VESTIDesign.Typography.caption)
                .foregroundStyle(VESTIDesign.Colors.textPrimary)
        }
        .padding(VESTIDesign.Spacing.sm)
        .background(isSelected ? VESTIDesign.Colors.accent.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: VESTIDesign.Radius.md))
        .overlay {
            RoundedRectangle(cornerRadius: VESTIDesign.Radius.md)
                .stroke(
                    isSelected ? VESTIDesign.Colors.accent : Color.clear,
                    lineWidth: 2
                )
        }
    }
}
```

- [ ] **Step 2: Build and verify in simulator/preview**

Run: `xcodebuild build -project VESTI.xcodeproj -scheme VESTI -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -3`

Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add VESTI/Sources/Views/Onboarding/StyleOnboardingView.swift
git commit -m "feat: add style onboarding view with archetype moodboard grid"
```

---

## Chunk 3: Piece Registration

### Task 9: Catalog Image Service

**Files:**
- Create: `VESTI/Sources/Services/CatalogImageService.swift`
- Test: `VESTI/Tests/Services/CatalogImageServiceTests.swift`

- [ ] **Step 1: Write tests**

```swift
// VESTI/Tests/Services/CatalogImageServiceTests.swift
import XCTest
@testable import VESTI

final class CatalogImageServiceTests: XCTestCase {

    func testExactMatchKey() {
        let key = CatalogImageService.imageKey(
            category: .tShirt, color: "white", fit: .slim
        )
        XCTAssertEqual(key, "tshirt_white_slim")
    }

    func testKeyWithColorLookup() {
        let key = CatalogImageService.imageKey(
            category: .jeans, color: "Navy", fit: .straight
        )
        XCTAssertEqual(key, "jeans_navy_straight")
    }

    func testFallbackKey() {
        // When exact key has no asset, fall back to default fit
        let fallback = CatalogImageService.fallbackKey(
            category: .polo, color: "terracotta", defaultFit: .regular
        )
        XCTAssertEqual(fallback, "polo_terracotta_regular")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: Compilation errors.

- [ ] **Step 3: Implement CatalogImageService**

```swift
// VESTI/Sources/Services/CatalogImageService.swift
import SwiftUI

enum CatalogImageService {

    /// Builds the asset key for a given garment configuration
    static func imageKey(category: GarmentCategory, color: String, fit: Fit) -> String {
        let categoryKey = category.rawValue
            .replacingOccurrences(of: "tShirt", with: "tshirt")
        let colorKey = GarmentColor.byName(color)?.assetKey ?? color.lowercased()
            .replacingOccurrences(of: " ", with: "-")
        return "\(categoryKey)_\(colorKey)_\(fit.rawValue)"
    }

    /// Fallback key using the default fit for the category
    static func fallbackKey(category: GarmentCategory, color: String, defaultFit: Fit) -> String {
        imageKey(category: category, color: color, fit: defaultFit)
    }

    /// Attempts to load a catalog image, trying exact match then fallback
    static func loadImage(category: GarmentCategory, color: String, fit: Fit) -> UIImage? {
        let exactKey = imageKey(category: category, color: color, fit: fit)
        if let image = UIImage(named: exactKey) {
            return image
        }

        // Fallback: same category + color, regular fit
        let fallback = fallbackKey(category: category, color: color, defaultFit: .regular)
        return UIImage(named: fallback)
    }

    /// Checks if an exact match exists in the asset catalog
    static func hasExactMatch(category: GarmentCategory, color: String, fit: Fit) -> Bool {
        let key = imageKey(category: category, color: color, fit: fit)
        return UIImage(named: key) != nil
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Expected: All 3 tests pass.

- [ ] **Step 5: Commit**

```bash
git add VESTI/Sources/Services/CatalogImageService.swift VESTI/Tests/Services/CatalogImageServiceTests.swift
git commit -m "feat: add catalog image service with asset key lookup"
```

---

### Task 10: Registration ViewModel

**Files:**
- Create: `VESTI/Sources/ViewModels/RegistrationViewModel.swift`
- Test: `VESTI/Tests/ViewModels/RegistrationViewModelTests.swift`

- [ ] **Step 1: Write tests**

```swift
// VESTI/Tests/ViewModels/RegistrationViewModelTests.swift
import XCTest
import SwiftData
@testable import VESTI

final class RegistrationViewModelTests: XCTestCase {

    func testInitialStep() {
        let vm = RegistrationViewModel()
        XCTAssertEqual(vm.currentStep, .category)
    }

    func testSelectCategory() {
        let vm = RegistrationViewModel()
        vm.selectCategory(.tShirt)
        XCTAssertEqual(vm.selectedCategory, .tShirt)
        XCTAssertEqual(vm.currentStep, .color)
    }

    func testSelectColor() {
        let vm = RegistrationViewModel()
        vm.selectCategory(.tShirt)
        vm.selectColor(GarmentColor.allColors[0]) // White
        XCTAssertEqual(vm.selectedColor?.name, "White")
        XCTAssertEqual(vm.currentStep, .fit)
    }

    func testAvailableFitsFilteredByCategory() {
        let vm = RegistrationViewModel()
        vm.selectCategory(.jeans)
        XCTAssertTrue(vm.availableFits.contains(.straight))
        XCTAssertFalse(vm.availableFits.contains(.oversized))
    }

    func testAvailableMaterialsFilteredByCategory() {
        let vm = RegistrationViewModel()
        vm.selectCategory(.sweater)
        XCTAssertTrue(vm.availableMaterials.contains("wool"))
        XCTAssertFalse(vm.availableMaterials.contains("denim"))
    }

    func testAutoSuggestedWeight() {
        let vm = RegistrationViewModel()
        vm.selectCategory(.sweater)
        vm.selectColor(GarmentColor.allColors[0])
        vm.selectFit(.regular)
        vm.selectMaterial("wool")
        XCTAssertEqual(vm.selectedWeight, .heavy)
    }

    func testAutoSuggestedFormality() {
        let vm = RegistrationViewModel()
        vm.selectCategory(.tShirt)
        XCTAssertEqual(vm.suggestedFormality, .casual)
    }

    func testFullFlowProducesPiece() {
        let vm = RegistrationViewModel()
        vm.selectCategory(.jeans)
        vm.selectColor(GarmentColor.byName("indigo")!)
        vm.selectFit(.straight)
        vm.selectMaterial("denim")
        vm.selectWeight(.mid)
        vm.selectFormality(.casual)

        let piece = vm.buildPiece()
        XCTAssertNotNil(piece)
        XCTAssertEqual(piece?.category, .jeans)
        XCTAssertEqual(piece?.color, "indigo")
        XCTAssertEqual(piece?.fit, .straight)
        XCTAssertEqual(piece?.catalogImageID, "jeans_indigo_straight")
    }

    func testGoBack() {
        let vm = RegistrationViewModel()
        vm.selectCategory(.tShirt)
        vm.selectColor(GarmentColor.allColors[0])
        XCTAssertEqual(vm.currentStep, .fit)
        vm.goBack()
        XCTAssertEqual(vm.currentStep, .color)
    }

    func testReset() {
        let vm = RegistrationViewModel()
        vm.selectCategory(.tShirt)
        vm.selectColor(GarmentColor.allColors[0])
        vm.reset()
        XCTAssertEqual(vm.currentStep, .category)
        XCTAssertNil(vm.selectedCategory)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: Compilation errors.

- [ ] **Step 3: Implement RegistrationViewModel**

```swift
// VESTI/Sources/ViewModels/RegistrationViewModel.swift
import SwiftUI
import SwiftData

enum RegistrationStep: Int, CaseIterable, Comparable {
    case category, color, fit, material, weight, formality, confirm

    static func < (lhs: RegistrationStep, rhs: RegistrationStep) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

@Observable
final class RegistrationViewModel {
    var currentStep: RegistrationStep = .category
    var selectedCategory: GarmentCategory?
    var selectedColor: GarmentColor?
    var selectedFit: Fit?
    var selectedMaterial: String?
    var selectedWeight: FabricWeight?
    var selectedFormality: Formality?
    var userPhotoPath: String?

    // MARK: - Computed

    var availableFits: [Fit] {
        selectedCategory?.availableFits ?? Fit.allCases
    }

    var availableMaterials: [String] {
        selectedCategory?.availableMaterials ?? []
    }

    var suggestedFormality: Formality? {
        selectedCategory?.defaultFormality
    }

    var catalogImageKey: String? {
        guard let category = selectedCategory,
              let color = selectedColor,
              let fit = selectedFit else { return nil }
        return CatalogImageService.imageKey(category: category, color: color.id, fit: fit)
    }

    // MARK: - Actions

    func selectCategory(_ category: GarmentCategory) {
        selectedCategory = category
        currentStep = .color
    }

    func selectColor(_ color: GarmentColor) {
        selectedColor = color
        currentStep = .fit
    }

    func selectFit(_ fit: Fit) {
        selectedFit = fit
        currentStep = .material
    }

    func selectMaterial(_ material: String) {
        selectedMaterial = material
        selectedWeight = FabricWeight.defaultWeight(for: material)
        currentStep = .weight
    }

    func selectWeight(_ weight: FabricWeight) {
        selectedWeight = weight
        selectedFormality = suggestedFormality
        currentStep = .formality
    }

    func selectFormality(_ formality: Formality) {
        selectedFormality = formality
        currentStep = .confirm
    }

    func goBack() {
        guard let previousIndex = RegistrationStep.allCases.firstIndex(of: currentStep),
              previousIndex > 0 else { return }
        currentStep = RegistrationStep.allCases[previousIndex - 1]
    }

    func reset() {
        currentStep = .category
        selectedCategory = nil
        selectedColor = nil
        selectedFit = nil
        selectedMaterial = nil
        selectedWeight = nil
        selectedFormality = nil
        userPhotoPath = nil
    }

    func buildPiece() -> GarmentPiece? {
        guard let category = selectedCategory,
              let color = selectedColor,
              let fit = selectedFit,
              let material = selectedMaterial,
              let weight = selectedWeight,
              let formality = selectedFormality else { return nil }

        return GarmentPiece(
            category: category,
            color: color.id,
            colorHex: color.hex,
            fit: fit,
            material: material,
            weight: weight,
            formality: formality
        )
    }

    @MainActor
    func savePiece(context: ModelContext) -> Bool {
        guard let piece = buildPiece() else { return false }
        piece.userPhotoPath = userPhotoPath
        context.insert(piece)
        try? context.save()
        return true
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Expected: All 9 tests pass.

- [ ] **Step 5: Commit**

```bash
git add VESTI/Sources/ViewModels/RegistrationViewModel.swift VESTI/Tests/ViewModels/RegistrationViewModelTests.swift
git commit -m "feat: add registration view model with step-by-step state machine"
```

---

### Task 11: Registration Flow Views

**Files:**
- Create: `VESTI/Sources/Views/Registration/RegistrationFlowView.swift`
- Create: `VESTI/Sources/Views/Registration/CategoryPickerView.swift`
- Create: `VESTI/Sources/Views/Registration/AttributeStepView.swift`
- Create: `VESTI/Sources/Views/Registration/CatalogConfirmView.swift`

- [ ] **Step 1: Implement CategoryPickerView**

```swift
// VESTI/Sources/Views/Registration/CategoryPickerView.swift
import SwiftUI

struct CategoryPickerView: View {
    let onSelect: (GarmentCategory) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: VESTIDesign.Spacing.md),
        GridItem(.flexible(), spacing: VESTIDesign.Spacing.md),
        GridItem(.flexible(), spacing: VESTIDesign.Spacing.md),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: VESTIDesign.Spacing.lg) {
            Text("What type of piece?")
                .font(VESTIDesign.Typography.title)
                .foregroundStyle(VESTIDesign.Colors.textPrimary)

            LazyVGrid(columns: columns, spacing: VESTIDesign.Spacing.md) {
                ForEach(GarmentCategory.allCases) { category in
                    Button {
                        onSelect(category)
                    } label: {
                        VStack(spacing: VESTIDesign.Spacing.sm) {
                            Image(systemName: category.systemIcon)
                                .font(.system(size: 28))
                                .frame(height: 36)
                            Text(category.displayName)
                                .font(VESTIDesign.Typography.caption)
                        }
                        .foregroundStyle(VESTIDesign.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, VESTIDesign.Spacing.md)
                        .vestiCard()
                    }
                }
            }
        }
    }
}

extension GarmentCategory {
    var systemIcon: String {
        switch self {
        case .tShirt: "tshirt"
        case .shirt: "tshirt"
        case .polo: "tshirt"
        case .sweater: "tshirt"
        case .hoodie: "tshirt"
        case .jacket: "cloud.sun"
        case .coat: "cloud.snow"
        case .jeans: "figure.stand"
        case .chinos: "figure.stand"
        case .shorts: "figure.run"
        case .shoes: "shoe"
        }
    }
}
```

- [ ] **Step 2: Implement AttributeStepView**

```swift
// VESTI/Sources/Views/Registration/AttributeStepView.swift
import SwiftUI

// MARK: - Color Picker Step

struct ColorPickerStepView: View {
    let onSelect: (GarmentColor) -> Void

    private let columns = [
        GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()),
        GridItem(.flexible()), GridItem(.flexible()),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: VESTIDesign.Spacing.lg) {
            Text("What color?")
                .font(VESTIDesign.Typography.title)
                .foregroundStyle(VESTIDesign.Colors.textPrimary)

            LazyVGrid(columns: columns, spacing: VESTIDesign.Spacing.md) {
                ForEach(GarmentColor.allColors) { color in
                    Button {
                        onSelect(color)
                    } label: {
                        VStack(spacing: VESTIDesign.Spacing.xs) {
                            Circle()
                                .fill(color.color)
                                .frame(width: 48, height: 48)
                                .overlay {
                                    Circle().stroke(VESTIDesign.Colors.border, lineWidth: 1)
                                }
                            Text(color.name)
                                .font(VESTIDesign.Typography.small)
                                .foregroundStyle(VESTIDesign.Colors.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Generic Option Picker Step

struct OptionPickerStepView<T: Identifiable>: View where T: Equatable {
    let title: String
    let options: [T]
    let labelFor: (T) -> String
    let suggested: T?
    let onSelect: (T) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: VESTIDesign.Spacing.lg) {
            Text(title)
                .font(VESTIDesign.Typography.title)
                .foregroundStyle(VESTIDesign.Colors.textPrimary)

            VStack(spacing: VESTIDesign.Spacing.sm) {
                ForEach(options) { option in
                    Button {
                        onSelect(option)
                    } label: {
                        HStack {
                            Text(labelFor(option))
                                .font(VESTIDesign.Typography.bodyText)
                                .foregroundStyle(VESTIDesign.Colors.textPrimary)

                            Spacer()

                            if let suggested, suggested.id as AnyHashable == option.id as AnyHashable {
                                Text("Suggested")
                                    .font(VESTIDesign.Typography.small)
                                    .foregroundStyle(VESTIDesign.Colors.textTertiary)
                            }
                        }
                        .padding(VESTIDesign.Spacing.md)
                        .vestiCard()
                    }
                }
            }
        }
    }
}

// MARK: - Material Picker (String-based)

struct MaterialPickerStepView: View {
    let materials: [String]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: VESTIDesign.Spacing.lg) {
            Text("What material?")
                .font(VESTIDesign.Typography.title)
                .foregroundStyle(VESTIDesign.Colors.textPrimary)

            VStack(spacing: VESTIDesign.Spacing.sm) {
                ForEach(materials, id: \.self) { material in
                    Button {
                        onSelect(material)
                    } label: {
                        Text(material.capitalized)
                            .font(VESTIDesign.Typography.bodyText)
                            .foregroundStyle(VESTIDesign.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(VESTIDesign.Spacing.md)
                            .vestiCard()
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 3: Implement CatalogConfirmView**

```swift
// VESTI/Sources/Views/Registration/CatalogConfirmView.swift
import SwiftUI

struct CatalogConfirmView: View {
    let imageKey: String?
    let category: GarmentCategory
    let color: GarmentColor
    let fit: Fit
    let onConfirm: () -> Void
    let onTakePhoto: () -> Void

    var body: some View {
        VStack(spacing: VESTIDesign.Spacing.lg) {
            Text("Does this look like your piece?")
                .font(VESTIDesign.Typography.title)
                .foregroundStyle(VESTIDesign.Colors.textPrimary)

            // Catalog image or placeholder
            Group {
                if let imageKey, let uiImage = UIImage(named: imageKey) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                } else {
                    // Placeholder when no catalog image exists
                    RoundedRectangle(cornerRadius: VESTIDesign.Radius.md)
                        .fill(color.color.opacity(0.3))
                        .overlay {
                            VStack(spacing: VESTIDesign.Spacing.sm) {
                                Image(systemName: category.systemIcon)
                                    .font(.system(size: 48))
                                Text("\(color.name) \(category.displayName)")
                                    .font(VESTIDesign.Typography.caption)
                            }
                            .foregroundStyle(VESTIDesign.Colors.textSecondary)
                        }
                }
            }
            .frame(maxWidth: 280, maxHeight: 360)
            .vestiCard()

            VStack(spacing: VESTIDesign.Spacing.sm) {
                Button {
                    onConfirm()
                } label: {
                    Text("Yes, that's it")
                        .font(VESTIDesign.Typography.subtitle)
                        .foregroundStyle(VESTIDesign.Colors.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, VESTIDesign.Spacing.md)
                        .background(VESTIDesign.Colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: VESTIDesign.Radius.md))
                }

                Button {
                    onTakePhoto()
                } label: {
                    Text("Not quite — I'll take a photo")
                        .font(VESTIDesign.Typography.bodyText)
                        .foregroundStyle(VESTIDesign.Colors.textSecondary)
                }
            }
        }
    }
}
```

- [ ] **Step 4: Implement RegistrationFlowView**

```swift
// VESTI/Sources/Views/Registration/RegistrationFlowView.swift
import SwiftUI

struct RegistrationFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = RegistrationViewModel()
    @State private var showCamera = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    switch viewModel.currentStep {
                    case .category:
                        CategoryPickerView { category in
                            withAnimation { viewModel.selectCategory(category) }
                        }

                    case .color:
                        ColorPickerStepView { color in
                            withAnimation { viewModel.selectColor(color) }
                        }

                    case .fit:
                        OptionPickerStepView(
                            title: "What fit?",
                            options: viewModel.availableFits,
                            labelFor: { $0.displayName },
                            suggested: nil
                        ) { fit in
                            withAnimation { viewModel.selectFit(fit) }
                        }

                    case .material:
                        MaterialPickerStepView(
                            materials: viewModel.availableMaterials
                        ) { material in
                            withAnimation { viewModel.selectMaterial(material) }
                        }

                    case .weight:
                        OptionPickerStepView(
                            title: "Fabric weight?",
                            options: FabricWeight.allCases,
                            labelFor: { $0.displayName },
                            suggested: viewModel.selectedWeight
                        ) { weight in
                            withAnimation { viewModel.selectWeight(weight) }
                        }

                    case .formality:
                        OptionPickerStepView(
                            title: "Formality level?",
                            options: Formality.allCases,
                            labelFor: { $0.displayName },
                            suggested: viewModel.suggestedFormality
                        ) { formality in
                            withAnimation { viewModel.selectFormality(formality) }
                        }

                    case .confirm:
                        if let category = viewModel.selectedCategory,
                           let color = viewModel.selectedColor,
                           let fit = viewModel.selectedFit {
                            CatalogConfirmView(
                                imageKey: viewModel.catalogImageKey,
                                category: category,
                                color: color,
                                fit: fit,
                                onConfirm: {
                                    if viewModel.savePiece(context: modelContext) {
                                        dismiss()
                                    }
                                },
                                onTakePhoto: {
                                    // TODO: Camera integration post-MVP
                                    // For now, save without photo
                                    if viewModel.savePiece(context: modelContext) {
                                        dismiss()
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(VESTIDesign.Spacing.md)
            }
            .background(VESTIDesign.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if viewModel.currentStep > .category {
                        Button("Back") {
                            withAnimation { viewModel.goBack() }
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
```

- [ ] **Step 5: Build and verify**

Run: `xcodebuild build -project VESTI.xcodeproj -scheme VESTI -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -3`

Expected: Build succeeds.

- [ ] **Step 6: Commit**

```bash
git add VESTI/Sources/Views/Registration/
git commit -m "feat: add piece registration flow (category, color, fit, material, weight, formality, confirm)"
```

---

## Chunk 4: Wardrobe View

### Task 12: Wardrobe ViewModel

**Files:**
- Create: `VESTI/Sources/ViewModels/WardrobeViewModel.swift`
- Test: `VESTI/Tests/ViewModels/WardrobeViewModelTests.swift`

- [ ] **Step 1: Write tests**

```swift
// VESTI/Tests/ViewModels/WardrobeViewModelTests.swift
import XCTest
import SwiftData
@testable import VESTI

final class WardrobeViewModelTests: XCTestCase {

    private var container: ModelContainer!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(
            for: StyleProfile.self, GarmentPiece.self, OutfitSuggestion.self, Feedback.self,
            configurations: config
        )
    }

    @MainActor
    func testFilterByTabGroup() {
        let context = container.mainContext
        let tshirt = GarmentPiece(category: .tShirt, color: "white", colorHex: "#FFF", fit: .slim, material: "cotton", weight: .light, formality: .casual)
        let jeans = GarmentPiece(category: .jeans, color: "blue", colorHex: "#00F", fit: .straight, material: "denim", weight: .mid, formality: .casual)
        context.insert(tshirt)
        context.insert(jeans)

        let vm = WardrobeViewModel()
        vm.selectedTab = .tops
        let filtered = vm.filterPieces([tshirt, jeans])
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.category, .tShirt)
    }

    @MainActor
    func testFilterAll() {
        let tshirt = GarmentPiece(category: .tShirt, color: "white", colorHex: "#FFF", fit: .slim, material: "cotton", weight: .light, formality: .casual)
        let jeans = GarmentPiece(category: .jeans, color: "blue", colorHex: "#00F", fit: .straight, material: "denim", weight: .mid, formality: .casual)

        let vm = WardrobeViewModel()
        vm.selectedTab = nil
        let filtered = vm.filterPieces([tshirt, jeans])
        XCTAssertEqual(filtered.count, 2)
    }

    @MainActor
    func testArchivePiece() {
        let piece = GarmentPiece(category: .tShirt, color: "white", colorHex: "#FFF", fit: .slim, material: "cotton", weight: .light, formality: .casual)
        XCTAssertTrue(piece.isActive)
        WardrobeViewModel.archivePiece(piece)
        XCTAssertFalse(piece.isActive)
    }

    @MainActor
    func testPieceCount() {
        let pieces = [
            GarmentPiece(category: .tShirt, color: "white", colorHex: "#FFF", fit: .slim, material: "cotton", weight: .light, formality: .casual),
            GarmentPiece(category: .jeans, color: "blue", colorHex: "#00F", fit: .straight, material: "denim", weight: .mid, formality: .casual),
            GarmentPiece(category: .jacket, color: "navy", colorHex: "#1B2A4A", fit: .regular, material: "wool", weight: .heavy, formality: .smartCasual),
        ]

        let vm = WardrobeViewModel()
        XCTAssertEqual(vm.activePieceCount(pieces), 3)

        pieces[0].isActive = false
        XCTAssertEqual(vm.activePieceCount(pieces), 2)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: Compilation errors.

- [ ] **Step 3: Implement WardrobeViewModel**

```swift
// VESTI/Sources/ViewModels/WardrobeViewModel.swift
import SwiftUI
import SwiftData

@Observable
final class WardrobeViewModel {
    var selectedTab: TabGroup? = nil // nil = "All"
    var showRegistration = false
    var selectedPiece: GarmentPiece?

    func filterPieces(_ pieces: [GarmentPiece]) -> [GarmentPiece] {
        let active = pieces.filter(\.isActive)
        guard let tab = selectedTab else { return active }
        return active.filter { $0.category.tabGroup == tab }
    }

    func activePieceCount(_ pieces: [GarmentPiece]) -> Int {
        pieces.filter(\.isActive).count
    }

    static func archivePiece(_ piece: GarmentPiece) {
        piece.isActive = false
    }

    static func restorePiece(_ piece: GarmentPiece) {
        piece.isActive = true
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Expected: All 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add VESTI/Sources/ViewModels/WardrobeViewModel.swift VESTI/Tests/ViewModels/WardrobeViewModelTests.swift
git commit -m "feat: add wardrobe view model with tab filtering and archiving"
```

---

### Task 13: Wardrobe Views

**Files:**
- Create: `VESTI/Sources/Views/Wardrobe/WardrobeView.swift`
- Create: `VESTI/Sources/Views/Wardrobe/GarmentDetailView.swift`
- Create: `VESTI/Sources/Views/Shared/EmptyStateView.swift`
- Modify: `VESTI/Sources/App/VESTIApp.swift` — wire up MainTabView

- [ ] **Step 1: Implement EmptyStateView**

```swift
// VESTI/Sources/Views/Shared/EmptyStateView.swift
import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let actionLabel: String?
    let action: (() -> Void)?

    init(title: String, message: String, actionLabel: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.actionLabel = actionLabel
        self.action = action
    }

    var body: some View {
        VStack(spacing: VESTIDesign.Spacing.md) {
            Text(title)
                .font(VESTIDesign.Typography.title)
                .foregroundStyle(VESTIDesign.Colors.textPrimary)

            Text(message)
                .font(VESTIDesign.Typography.bodyText)
                .foregroundStyle(VESTIDesign.Colors.textSecondary)
                .multilineTextAlignment(.center)

            if let actionLabel, let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(VESTIDesign.Typography.subtitle)
                        .foregroundStyle(VESTIDesign.Colors.background)
                        .padding(.horizontal, VESTIDesign.Spacing.xl)
                        .padding(.vertical, VESTIDesign.Spacing.md)
                        .background(VESTIDesign.Colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: VESTIDesign.Radius.md))
                }
            }
        }
        .padding(VESTIDesign.Spacing.xl)
    }
}
```

- [ ] **Step 2: Implement GarmentDetailView**

```swift
// VESTI/Sources/Views/Wardrobe/GarmentDetailView.swift
import SwiftUI

struct GarmentDetailView: View {
    let piece: GarmentPiece

    var body: some View {
        ScrollView {
            VStack(spacing: VESTIDesign.Spacing.lg) {
                // Image
                Group {
                    if let uiImage = CatalogImageService.loadImage(
                        category: piece.category, color: piece.color, fit: piece.fit
                    ) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                    } else {
                        RoundedRectangle(cornerRadius: VESTIDesign.Radius.md)
                            .fill(Color(hex: piece.colorHex).opacity(0.3))
                            .aspectRatio(3 / 4, contentMode: .fit)
                            .overlay {
                                Image(systemName: piece.category.systemIcon)
                                    .font(.system(size: 48))
                                    .foregroundStyle(VESTIDesign.Colors.textSecondary)
                            }
                    }
                }
                .frame(maxWidth: 280)
                .vestiCard()

                // Attributes
                VStack(spacing: VESTIDesign.Spacing.sm) {
                    attributeRow("Category", piece.category.displayName)
                    attributeRow("Color", piece.color.capitalized)
                    attributeRow("Fit", piece.fit.displayName)
                    attributeRow("Material", piece.material.capitalized)
                    attributeRow("Weight", piece.weight.displayName)
                    attributeRow("Formality", piece.formality.displayName)
                }
                .padding(VESTIDesign.Spacing.md)
            }
            .padding(VESTIDesign.Spacing.md)
        }
        .background(VESTIDesign.Colors.background)
        .navigationTitle(piece.category.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func attributeRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(VESTIDesign.Typography.bodyText)
                .foregroundStyle(VESTIDesign.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(VESTIDesign.Typography.bodyText)
                .foregroundStyle(VESTIDesign.Colors.textPrimary)
        }
        .padding(.vertical, VESTIDesign.Spacing.xs)
    }
}
```

- [ ] **Step 3: Implement WardrobeView**

```swift
// VESTI/Sources/Views/Wardrobe/WardrobeView.swift
import SwiftUI
import SwiftData

struct WardrobeView: View {
    @Query(filter: #Predicate<GarmentPiece> { $0.isActive })
    private var pieces: [GarmentPiece]

    @State private var viewModel = WardrobeViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: VESTIDesign.Spacing.md),
        GridItem(.flexible(), spacing: VESTIDesign.Spacing.md),
        GridItem(.flexible(), spacing: VESTIDesign.Spacing.md),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: VESTIDesign.Spacing.sm) {
                        tabButton("All", tab: nil)
                        ForEach(TabGroup.allCases, id: \.self) { tab in
                            tabButton(tab.rawValue.capitalized, tab: tab)
                        }
                    }
                    .padding(.horizontal, VESTIDesign.Spacing.md)
                    .padding(.vertical, VESTIDesign.Spacing.sm)
                }

                // Grid or empty state
                if pieces.isEmpty {
                    Spacer()
                    EmptyStateView(
                        title: "Your wardrobe is empty",
                        message: "Add your first pieces to get started",
                        actionLabel: "Add Piece",
                        action: { viewModel.showRegistration = true }
                    )
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: VESTIDesign.Spacing.md) {
                            ForEach(viewModel.filterPieces(pieces)) { piece in
                                Button {
                                    viewModel.selectedPiece = piece
                                } label: {
                                    garmentCard(piece)
                                }
                            }
                        }
                        .padding(VESTIDesign.Spacing.md)
                    }
                }
            }
            .background(VESTIDesign.Colors.background)
            .navigationTitle("Wardrobe")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showRegistration = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showRegistration) {
                RegistrationFlowView()
            }
            .sheet(item: $viewModel.selectedPiece) { piece in
                NavigationStack {
                    GarmentDetailView(piece: piece)
                }
            }
        }
    }

    private func tabButton(_ label: String, tab: TabGroup?) -> some View {
        Button {
            withAnimation { viewModel.selectedTab = tab }
        } label: {
            Text(label)
                .font(VESTIDesign.Typography.caption)
                .foregroundStyle(
                    viewModel.selectedTab == tab
                        ? VESTIDesign.Colors.background
                        : VESTIDesign.Colors.textPrimary
                )
                .padding(.horizontal, VESTIDesign.Spacing.md)
                .padding(.vertical, VESTIDesign.Spacing.sm)
                .background(
                    viewModel.selectedTab == tab
                        ? VESTIDesign.Colors.accent
                        : VESTIDesign.Colors.surface
                )
                .clipShape(Capsule())
        }
    }

    private func garmentCard(_ piece: GarmentPiece) -> some View {
        VStack(spacing: VESTIDesign.Spacing.xs) {
            Group {
                if let uiImage = CatalogImageService.loadImage(
                    category: piece.category, color: piece.color, fit: piece.fit
                ) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: VESTIDesign.Radius.sm)
                        .fill(Color(hex: piece.colorHex).opacity(0.3))
                        .overlay {
                            Image(systemName: piece.category.systemIcon)
                                .foregroundStyle(VESTIDesign.Colors.textSecondary)
                        }
                }
            }
            .aspectRatio(3 / 4, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: VESTIDesign.Radius.sm))

            Text("\(piece.color.capitalized) \(piece.category.displayName)")
                .font(VESTIDesign.Typography.small)
                .foregroundStyle(VESTIDesign.Colors.textSecondary)
                .lineLimit(1)
        }
    }
}
```

- [ ] **Step 4: Update MainTabView in VESTIApp.swift**

Replace the placeholder `MainTabView` with:

```swift
struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "tshirt") {
                Text("Suggestions coming soon")
            }
            Tab("Wardrobe", systemImage: "cabinet") {
                WardrobeView()
            }
        }
        .tint(VESTIDesign.Colors.accent)
    }
}
```

- [ ] **Step 5: Build and verify**

Run: `xcodebuild build -project VESTI.xcodeproj -scheme VESTI -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -3`

Expected: Build succeeds.

- [ ] **Step 6: Commit**

```bash
git add VESTI/Sources/Views/Wardrobe/ VESTI/Sources/Views/Shared/EmptyStateView.swift VESTI/Sources/App/VESTIApp.swift
git commit -m "feat: add wardrobe view with grid, tab filtering, detail view, and empty state"
```

---

## Chunk 5: Proxy Server

### Task 14: Proxy Project Setup

**Files:**
- Create: `vesti-proxy/package.json`
- Create: `vesti-proxy/tsconfig.json`
- Create: `vesti-proxy/wrangler.toml`
- Create: `vesti-proxy/src/types.ts`

- [ ] **Step 1: Initialize proxy project**

```bash
mkdir -p vesti-proxy/src vesti-proxy/test
```

- [ ] **Step 2: Create package.json**

```json
{
  "name": "vesti-proxy",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "wrangler dev",
    "deploy": "wrangler deploy",
    "test": "vitest"
  },
  "devDependencies": {
    "@cloudflare/workers-types": "^4.20240512.0",
    "typescript": "^5.4.0",
    "vitest": "^1.6.0",
    "wrangler": "^3.60.0"
  },
  "dependencies": {
    "@anthropic-ai/sdk": "^0.30.0"
  }
}
```

- [ ] **Step 3: Create tsconfig.json**

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "moduleResolution": "bundler",
    "lib": ["ES2022"],
    "types": ["@cloudflare/workers-types"],
    "strict": true,
    "outDir": "dist",
    "rootDir": "src",
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "include": ["src/**/*"]
}
```

- [ ] **Step 4: Create wrangler.toml**

```toml
name = "vesti-proxy"
main = "src/index.ts"
compatibility_date = "2024-05-01"

[vars]
# ANTHROPIC_API_KEY is set via `wrangler secret put ANTHROPIC_API_KEY`
```

- [ ] **Step 5: Create types.ts**

```typescript
// vesti-proxy/src/types.ts

export interface HourlyForecast {
  hour: number;
  temp: number;
  condition: string;
}

export interface WeatherPayload {
  temperature: number;
  feels_like: number;
  humidity: number;
  wind: number;
  condition: string;
  hourly_forecast: HourlyForecast[];
}

export interface WardrobePiece {
  id: string;
  category: string;
  color: string;
  fit: string;
  material: string;
  weight: string;
  formality: string;
}

export interface RecentSuggestion {
  date: string;
  piece_ids: string[];
  feedback: string;
}

export interface SuggestionRequest {
  style_archetypes: string[];
  boldness: number;
  occasion: string;
  weather?: WeatherPayload;
  wardrobe: WardrobePiece[];
  recent_suggestions: RecentSuggestion[];
}

export interface AlternativePiece {
  swap: string;
  for: string;
  why: string;
}

export interface SuggestionResponse {
  pieces: string[];
  reasoning: string;
  layering_note?: string;
  alternative_piece?: AlternativePiece;
}

export interface Env {
  ANTHROPIC_API_KEY: string;
}
```

- [ ] **Step 6: Install dependencies**

Run: `cd vesti-proxy && npm install`

- [ ] **Step 7: Commit**

```bash
git add vesti-proxy/package.json vesti-proxy/tsconfig.json vesti-proxy/wrangler.toml vesti-proxy/src/types.ts
git commit -m "feat: initialize proxy server project (Cloudflare Worker)"
```

---

### Task 15: System Prompt Builder + Archetype Briefs

**Files:**
- Create: `vesti-proxy/src/archetypes.ts`
- Create: `vesti-proxy/src/tool-schema.ts`
- Create: `vesti-proxy/src/prompt.ts`
- Test: `vesti-proxy/test/prompt.test.ts`

- [ ] **Step 1: Write tests**

```typescript
// vesti-proxy/test/prompt.test.ts
import { describe, it, expect } from 'vitest';
import { buildSystemPrompt } from '../src/prompt';
import { ARCHETYPE_BRIEFS } from '../src/archetypes';

describe('buildSystemPrompt', () => {
  it('includes selected archetype briefs', () => {
    const prompt = buildSystemPrompt(['old-money', 'minimalist']);
    expect(prompt).toContain('Old Money:');
    expect(prompt).toContain('Minimalist:');
    expect(prompt).not.toContain('Streetwear:');
  });

  it('includes boldness instructions', () => {
    const prompt = buildSystemPrompt(['classic']);
    expect(prompt).toContain('BOLDNESS');
    expect(prompt).toContain('0.0-0.3');
  });

  it('includes hard rules', () => {
    const prompt = buildSystemPrompt(['old-money']);
    expect(prompt).toContain('HARD RULES');
    expect(prompt).toContain('Fabric weight must match weather');
  });

  it('handles unknown archetypes gracefully', () => {
    const prompt = buildSystemPrompt(['unknown-style']);
    expect(prompt).toContain('VESTI');
    // Should not crash, just skip unknown archetype
  });
});

describe('ARCHETYPE_BRIEFS', () => {
  it('has briefs for all 6 archetypes', () => {
    expect(Object.keys(ARCHETYPE_BRIEFS)).toHaveLength(6);
    expect(ARCHETYPE_BRIEFS['old-money']).toBeDefined();
    expect(ARCHETYPE_BRIEFS['minimalist']).toBeDefined();
    expect(ARCHETYPE_BRIEFS['smart-casual']).toBeDefined();
    expect(ARCHETYPE_BRIEFS['streetwear']).toBeDefined();
    expect(ARCHETYPE_BRIEFS['classic']).toBeDefined();
    expect(ARCHETYPE_BRIEFS['scandinavian']).toBeDefined();
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd vesti-proxy && npx vitest run --reporter=verbose 2>&1 | tail -20`

Expected: Import errors — modules don't exist.

- [ ] **Step 3: Implement archetypes.ts**

```typescript
// vesti-proxy/src/archetypes.ts

export const ARCHETYPE_BRIEFS: Record<string, string> = {
  'old-money': `Old Money: Structured silhouettes, neutral palette (navy, cream, olive, gray, camel), quality fabrics, understated elegance. Think: well-fitted chinos + fine knit sweater + structured outerwear. Avoid logos, bold prints, or anything that screams for attention. The outfit should look expensive through fit and fabric, not branding. Layering is key — a collared shirt under a crewneck sweater is a signature move.`,

  'minimalist': `Minimalist: Clean lines, monochrome or tonal palettes, few elements, every piece intentional. Think: single-tone layers with texture contrast (matte cotton tee under a slightly shiny bomber). Stick to black, white, gray, navy, and earth tones. Silhouettes should be clean — no excess fabric, no unnecessary details. When in doubt, remove an element rather than add one.`,

  'smart-casual': `Smart Casual: Polished but relaxed. The sweet spot between formal and casual — a dress shirt with chinos, a blazer with jeans. Versatile layering is the strength. Colors can be slightly more expressive than Old Money but stay grounded. Fit should be intentional but not restrictive. This archetype bridges occasions well — a smart casual outfit works for both a lunch meeting and a dinner out.`,

  'streetwear': `Streetwear: Relaxed fits, graphic elements, sneaker-forward styling. Think: oversized tee + relaxed jeans + statement sneakers. Layering is more casual — hoodies under jackets, open shirts over tees. Colors can be bolder and contrast-heavy. The silhouette tends toward relaxed and oversized. Accessories play a bigger role here than in other archetypes.`,

  'classic': `Classic: Timeless, balanced proportions, conventional combinations that never go out of style. Think: navy blazer + white shirt + gray trousers. The outfit should look appropriate in any decade. Fit is traditional — not too slim, not too relaxed. Color palette is conservative: navy, charcoal, white, light blue, khaki. Pattern mixing (e.g., solid jacket + striped shirt) is welcomed when subtle.`,

  'scandinavian': `Scandinavian: Muted, earthy tones — sage, oatmeal, stone, charcoal. Functional fabrics and clean construction. Texture is more important than color contrast. Think: heavyweight cotton tee + wool overshirt + well-worn denim. The aesthetic values quality materials and intentional simplicity. Layering is practical, not decorative. Everything should look like it could withstand a Nordic winter walk.`,
};
```

- [ ] **Step 4: Implement tool-schema.ts**

```typescript
// vesti-proxy/src/tool-schema.ts

export const SUGGEST_OUTFIT_TOOL = {
  name: 'suggest_outfit',
  description: 'Suggest a daily outfit from the user\'s wardrobe',
  input_schema: {
    type: 'object' as const,
    required: ['pieces', 'reasoning'],
    properties: {
      pieces: {
        type: 'array' as const,
        items: { type: 'string' as const },
        description: 'Array of garment piece UUIDs forming the outfit',
      },
      reasoning: {
        type: 'string' as const,
        description: '1-2 sentence explanation of why this combination works',
      },
      layering_note: {
        type: 'string' as const,
        description: 'Optional note about layering for weather transitions',
      },
      alternative_piece: {
        type: 'object' as const,
        properties: {
          swap: { type: 'string' as const, description: 'UUID of piece to replace' },
          for: { type: 'string' as const, description: 'UUID of alternative piece' },
          why: { type: 'string' as const, description: 'Why this swap works' },
        },
      },
    },
  },
};
```

- [ ] **Step 5: Implement prompt.ts**

```typescript
// vesti-proxy/src/prompt.ts

import { ARCHETYPE_BRIEFS } from './archetypes';

export function buildSystemPrompt(archetypes: string[]): string {
  const archetypeSections = archetypes
    .map((key) => ARCHETYPE_BRIEFS[key])
    .filter(Boolean)
    .map((brief) => `- ${brief}`)
    .join('\n');

  return `You are VESTI, a personal wardrobe consultant. You help users dress with intention by selecting outfit combinations from their registered wardrobe pieces.

STYLE CONTEXT:
The user's style archetypes define the "outfit formulas" you should follow:
${archetypeSections || '- No specific archetype selected. Use balanced, versatile combinations.'}

BOLDNESS:
A value from 0.0 (safe/classic) to 1.0 (creative/unexpected).
- 0.0-0.3: Stick to proven combinations within the archetype. No surprises.
- 0.4-0.6: Introduce subtle variations — unexpected color pairings, mixing archetype elements.
- 0.7-1.0: Push boundaries — cross-archetype mixing, bold color plays, unconventional formality combinations that still work.

HARD RULES (never violate):
- Fabric weight must match weather. Never suggest heavy wool when it's 30°C or light linen when it's 5°C.
- If hourly forecast shows temperature swings >10°C, suggest a removable layer and include a layering_note.
- Each outfit must include at least one top and one bottom piece.

SOFT RULES (use judgment):
- Formality can be mixed if pieces bridge the gap (smart pants + dress shirt = OK).
- Monochrome is fine with texture or shade variation.
- Avoid suggesting the same outfit as recent_suggestions unless 10+ days have passed.
- If the user disliked a recent suggestion, avoid the specific pattern they rejected.

OUTPUT: Use the suggest_outfit tool to return your suggestion. Always include reasoning (1-2 sentences explaining why this combination works). Include layering_note only when weather transitions warrant it. Include alternative_piece only when there's a meaningful swap available.

If the wardrobe has too few pieces to form a coherent outfit for the given occasion and weather, return what you can and explain in reasoning what's missing.`;
}
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `cd vesti-proxy && npx vitest run --reporter=verbose 2>&1 | tail -20`

Expected: All 5 tests pass.

- [ ] **Step 7: Commit**

```bash
git add vesti-proxy/src/archetypes.ts vesti-proxy/src/tool-schema.ts vesti-proxy/src/prompt.ts vesti-proxy/test/prompt.test.ts
git commit -m "feat: add system prompt builder with archetype briefs and tool schema"
```

---

### Task 16: Request Handler + Worker Entry

**Files:**
- Create: `vesti-proxy/src/handler.ts`
- Create: `vesti-proxy/src/index.ts`
- Test: `vesti-proxy/test/handler.test.ts`

- [ ] **Step 1: Write tests**

```typescript
// vesti-proxy/test/handler.test.ts
import { describe, it, expect, vi } from 'vitest';
import { buildClaudeRequest } from '../src/handler';

describe('buildClaudeRequest', () => {
  it('builds a valid Claude API request', () => {
    const request = buildClaudeRequest({
      style_archetypes: ['old-money'],
      boldness: 0.3,
      occasion: 'everyday',
      weather: {
        temperature: 22,
        feels_like: 20,
        humidity: 65,
        wind: 12,
        condition: 'clear',
        hourly_forecast: [],
      },
      wardrobe: [
        { id: 'uuid1', category: 'tShirt', color: 'white', fit: 'slim', material: 'cotton', weight: 'light', formality: 'casual' },
      ],
      recent_suggestions: [],
    });

    expect(request.model).toContain('claude');
    expect(request.system).toContain('VESTI');
    expect(request.tools).toHaveLength(1);
    expect(request.tools[0].name).toBe('suggest_outfit');
    expect(request.messages).toHaveLength(1);
    expect(request.messages[0].content).toContain('old-money');
  });

  it('includes weather in user message when provided', () => {
    const request = buildClaudeRequest({
      style_archetypes: ['minimalist'],
      boldness: 0.5,
      occasion: 'meeting',
      weather: {
        temperature: 15,
        feels_like: 13,
        humidity: 80,
        wind: 20,
        condition: 'rain',
        hourly_forecast: [{ hour: 8, temp: 12, condition: 'rain' }],
      },
      wardrobe: [],
      recent_suggestions: [],
    });

    expect(request.messages[0].content).toContain('15°C');
    expect(request.messages[0].content).toContain('rain');
  });

  it('omits weather section when not provided', () => {
    const request = buildClaudeRequest({
      style_archetypes: ['classic'],
      boldness: 0.3,
      occasion: 'everyday',
      wardrobe: [],
      recent_suggestions: [],
    });

    expect(request.messages[0].content).not.toContain('WEATHER');
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: Import errors.

- [ ] **Step 3: Implement handler.ts**

```typescript
// vesti-proxy/src/handler.ts

import { buildSystemPrompt } from './prompt';
import { SUGGEST_OUTFIT_TOOL } from './tool-schema';
import type { SuggestionRequest, SuggestionResponse, Env } from './types';

interface ClaudeRequest {
  model: string;
  max_tokens: number;
  system: string;
  tools: any[];
  tool_choice: { type: string; name: string };
  messages: { role: string; content: string }[];
}

export function buildClaudeRequest(payload: SuggestionRequest): ClaudeRequest {
  const systemPrompt = buildSystemPrompt(payload.style_archetypes);

  let userMessage = `Suggest an outfit for today.\n\n`;
  userMessage += `Style archetypes: ${payload.style_archetypes.join(', ')}\n`;
  userMessage += `Boldness level: ${payload.boldness}\n`;
  userMessage += `Occasion: ${payload.occasion}\n\n`;

  if (payload.weather) {
    const w = payload.weather;
    userMessage += `WEATHER:\n`;
    userMessage += `Temperature: ${w.temperature}°C (feels like ${w.feels_like}°C)\n`;
    userMessage += `Humidity: ${w.humidity}%, Wind: ${w.wind} km/h\n`;
    userMessage += `Condition: ${w.condition}\n`;
    if (w.hourly_forecast.length > 0) {
      userMessage += `Hourly: ${w.hourly_forecast.map((h) => `${h.hour}h: ${h.temp}°C ${h.condition}`).join(', ')}\n`;
    }
    userMessage += '\n';
  }

  userMessage += `WARDROBE (${payload.wardrobe.length} pieces):\n`;
  for (const piece of payload.wardrobe) {
    userMessage += `- [${piece.id}] ${piece.color} ${piece.category} (${piece.fit}, ${piece.material}, ${piece.weight}, ${piece.formality})\n`;
  }

  if (payload.recent_suggestions.length > 0) {
    userMessage += `\nRECENT SUGGESTIONS:\n`;
    for (const s of payload.recent_suggestions) {
      userMessage += `- ${s.date}: pieces [${s.piece_ids.join(', ')}] → ${s.feedback}\n`;
    }
  }

  return {
    model: 'claude-sonnet-4-6',
    max_tokens: 1024,
    system: systemPrompt,
    tools: [SUGGEST_OUTFIT_TOOL],
    tool_choice: { type: 'tool', name: 'suggest_outfit' },
    messages: [{ role: 'user', content: userMessage }],
  };
}

export async function handleSuggestionRequest(
  payload: SuggestionRequest,
  env: Env
): Promise<SuggestionResponse> {
  const claudeRequest = buildClaudeRequest(payload);

  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': env.ANTHROPIC_API_KEY,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify(claudeRequest),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Claude API error ${response.status}: ${errorText}`);
  }

  const result = await response.json() as any;

  // Extract tool use result
  const toolUse = result.content?.find((block: any) => block.type === 'tool_use');
  if (!toolUse?.input) {
    throw new Error('No tool_use response from Claude');
  }

  return toolUse.input as SuggestionResponse;
}
```

- [ ] **Step 4: Implement index.ts (Worker entry)**

```typescript
// vesti-proxy/src/index.ts

import { handleSuggestionRequest } from './handler';
import type { SuggestionRequest, Env } from './types';

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    };

    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    if (request.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const url = new URL(request.url);

    if (url.pathname !== '/suggest') {
      return new Response(JSON.stringify({ error: 'Not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    try {
      const payload = (await request.json()) as SuggestionRequest;

      // Basic validation
      if (!payload.wardrobe || !payload.style_archetypes) {
        return new Response(
          JSON.stringify({ error: 'Missing required fields: wardrobe, style_archetypes' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      const suggestion = await handleSuggestionRequest(payload, env);

      return new Response(JSON.stringify(suggestion), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Internal server error';
      return new Response(JSON.stringify({ error: message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
  },
};
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd vesti-proxy && npx vitest run --reporter=verbose 2>&1 | tail -20`

Expected: All handler tests pass.

- [ ] **Step 6: Commit**

```bash
git add vesti-proxy/src/handler.ts vesti-proxy/src/index.ts vesti-proxy/test/handler.test.ts
git commit -m "feat: add proxy request handler and Cloudflare Worker entry point"
```

---

## Chunk 6: Suggestion Engine + Weather (iOS)

### Task 17: Weather Service

**Files:**
- Create: `VESTI/Sources/Services/WeatherService.swift`
- Test: `VESTI/Tests/Services/WeatherServiceTests.swift`

- [ ] **Step 1: Write tests**

```swift
// VESTI/Tests/Services/WeatherServiceTests.swift
import XCTest
@testable import VESTI

final class WeatherServiceTests: XCTestCase {

    func testWeatherSnapshotTransition() {
        let snapshot = WeatherSnapshot(
            temperature: 22,
            feelsLike: 20,
            humidity: 65,
            windSpeed: 12,
            condition: "clear",
            hourlyForecast: [
                HourlyEntry(hour: 7, temperature: 12, condition: "clear"),
                HourlyEntry(hour: 12, temperature: 28, condition: "sunny"),
                HourlyEntry(hour: 18, temperature: 20, condition: "cloudy"),
            ]
        )
        // 28 - 12 = 16 > 10, so significant transition
        XCTAssertTrue(snapshot.hasSignificantTransition)
    }

    func testWeatherSnapshotNoTransition() {
        let snapshot = WeatherSnapshot(
            temperature: 22,
            feelsLike: 20,
            humidity: 65,
            windSpeed: 12,
            condition: "clear",
            hourlyForecast: [
                HourlyEntry(hour: 7, temperature: 20, condition: "clear"),
                HourlyEntry(hour: 12, temperature: 24, condition: "sunny"),
            ]
        )
        // 24 - 20 = 4 < 10, no significant transition
        XCTAssertFalse(snapshot.hasSignificantTransition)
    }

    func testCachedWeatherIsStale() {
        let service = WeatherService()

        // Cache weather with an old timestamp
        let snapshot = WeatherSnapshot(
            temperature: 20, feelsLike: 18, humidity: 60,
            windSpeed: 10, condition: "clear", hourlyForecast: []
        )

        let oldDate = Calendar.current.date(byAdding: .hour, value: -7, to: Date())!
        service.setCachedWeather(snapshot, fetchedAt: oldDate)

        XCTAssertTrue(service.isCacheStale(maxAge: 6 * 3600))
    }

    func testCachedWeatherIsFresh() {
        let service = WeatherService()

        let snapshot = WeatherSnapshot(
            temperature: 20, feelsLike: 18, humidity: 60,
            windSpeed: 10, condition: "clear", hourlyForecast: []
        )
        service.setCachedWeather(snapshot, fetchedAt: Date())

        XCTAssertFalse(service.isCacheStale(maxAge: 6 * 3600))
    }

    func testSignificantWeatherChange() {
        let old = WeatherSnapshot(
            temperature: 20, feelsLike: 18, humidity: 60,
            windSpeed: 10, condition: "clear", hourlyForecast: []
        )
        let new_ = WeatherSnapshot(
            temperature: 28, feelsLike: 30, humidity: 80,
            windSpeed: 5, condition: "rain", hourlyForecast: []
        )
        XCTAssertTrue(WeatherService.hasSignificantChange(from: old, to: new_))
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: Compilation errors.

- [ ] **Step 3: Implement WeatherService**

```swift
// VESTI/Sources/Services/WeatherService.swift
import Foundation
import WeatherKit
import CoreLocation

final class WeatherService: @unchecked Sendable {
    private var cachedWeather: WeatherSnapshot?
    private var cachedAt: Date?

    func setCachedWeather(_ snapshot: WeatherSnapshot, fetchedAt: Date = Date()) {
        cachedWeather = snapshot
        cachedAt = fetchedAt
    }

    func getCachedWeather() -> WeatherSnapshot? {
        cachedWeather
    }

    func isCacheStale(maxAge: TimeInterval) -> Bool {
        guard let cachedAt else { return true }
        return Date().timeIntervalSince(cachedAt) > maxAge
    }

    /// Fetches current weather using WeatherKit
    func fetchWeather(for location: CLLocation) async -> WeatherSnapshot? {
        do {
            let weatherService = WeatherKit.WeatherService.shared
            let weather = try await weatherService.weather(for: location)
            let current = weather.currentWeather

            let hourly = weather.hourlyForecast.prefix(12).map { forecast in
                HourlyEntry(
                    hour: Calendar.current.component(.hour, from: forecast.date),
                    temperature: forecast.temperature.value,
                    condition: forecast.condition.rawValue
                )
            }

            let snapshot = WeatherSnapshot(
                temperature: current.temperature.value,
                feelsLike: current.apparentTemperature.value,
                humidity: current.humidity * 100,
                windSpeed: current.wind.speed.value,
                condition: current.condition.rawValue,
                hourlyForecast: Array(hourly)
            )

            setCachedWeather(snapshot)
            return snapshot
        } catch {
            // Fall back to cached weather if available
            if !isCacheStale(maxAge: 6 * 3600) {
                return cachedWeather
            }
            return nil
        }
    }

    /// Determines if weather has changed enough to warrant a new suggestion
    static func hasSignificantChange(from old: WeatherSnapshot, to new: WeatherSnapshot) -> Bool {
        let tempDelta = abs(new.temperature - old.temperature)
        let conditionChanged = old.condition != new.condition
        return tempDelta > 5 || conditionChanged
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Expected: All 5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add VESTI/Sources/Services/WeatherService.swift VESTI/Tests/Services/WeatherServiceTests.swift
git commit -m "feat: add weather service with WeatherKit integration and caching"
```

---

### Task 18: Suggestion Service (API Client)

**Files:**
- Create: `VESTI/Sources/Services/SuggestionService.swift`
- Test: `VESTI/Tests/Services/SuggestionServiceTests.swift`

- [ ] **Step 1: Write tests**

```swift
// VESTI/Tests/Services/SuggestionServiceTests.swift
import XCTest
@testable import VESTI

final class SuggestionServiceTests: XCTestCase {

    func testBuildRequestPayload() throws {
        let pieces = [
            GarmentPiece(category: .tShirt, color: "white", colorHex: "#FFF", fit: .slim, material: "cotton", weight: .light, formality: .casual),
            GarmentPiece(category: .jeans, color: "indigo", colorHex: "#3F5277", fit: .straight, material: "denim", weight: .mid, formality: .casual),
        ]
        let archetypes: [StyleArchetype] = [.oldMoney, .minimalist]
        let weather = WeatherSnapshot(
            temperature: 22, feelsLike: 20, humidity: 65,
            windSpeed: 12, condition: "clear", hourlyForecast: []
        )

        let payload = SuggestionService.buildPayload(
            archetypes: archetypes,
            boldness: 0.3,
            occasion: .everyday,
            weather: weather,
            wardrobe: pieces,
            recentSuggestions: []
        )

        XCTAssertEqual(payload["style_archetypes"] as? [String], ["old-money", "minimalist"])
        XCTAssertEqual(payload["boldness"] as? Double, 0.3)
        XCTAssertEqual(payload["occasion"] as? String, "everyday")

        let wardrobePayload = payload["wardrobe"] as? [[String: String]]
        XCTAssertEqual(wardrobePayload?.count, 2)
        XCTAssertEqual(wardrobePayload?.first?["category"], "tShirt")
    }

    func testParseResponse() throws {
        let json: [String: Any] = [
            "pieces": ["uuid1", "uuid2"],
            "reasoning": "Great combination",
            "layering_note": "Bring a jacket",
            "alternative_piece": [
                "swap": "uuid2",
                "for": "uuid3",
                "why": "More casual option",
            ],
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let response = try SuggestionService.parseResponse(data)

        XCTAssertEqual(response.pieceIDs, ["uuid1", "uuid2"])
        XCTAssertEqual(response.reasoning, "Great combination")
        XCTAssertEqual(response.layeringNote, "Bring a jacket")
        XCTAssertEqual(response.alternativeSwap?.swapPieceID, "uuid2")
    }

    func testParseResponseMinimal() throws {
        let json: [String: Any] = [
            "pieces": ["uuid1"],
            "reasoning": "Simple look",
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let response = try SuggestionService.parseResponse(data)

        XCTAssertEqual(response.pieceIDs, ["uuid1"])
        XCTAssertNil(response.layeringNote)
        XCTAssertNil(response.alternativeSwap)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: Compilation errors.

- [ ] **Step 3: Implement SuggestionService**

```swift
// VESTI/Sources/Services/SuggestionService.swift
import Foundation

struct SuggestionAPIResponse {
    let pieceIDs: [String]
    let reasoning: String
    let layeringNote: String?
    let alternativeSwap: AlternativeSwap?
}

final class SuggestionService {
    // TODO: Replace with actual proxy URL after deployment
    static let proxyBaseURL = "https://vesti-proxy.YOUR_DOMAIN.workers.dev"

    // MARK: - Payload Building

    static func buildPayload(
        archetypes: [StyleArchetype],
        boldness: Double,
        occasion: Occasion,
        weather: WeatherSnapshot?,
        wardrobe: [GarmentPiece],
        recentSuggestions: [(date: String, pieceIDs: [String], feedback: String)]
    ) -> [String: Any] {
        var payload: [String: Any] = [
            "style_archetypes": archetypes.map(\.assetKey),
            "boldness": boldness,
            "occasion": occasion.rawValue,
            "wardrobe": wardrobe.map { piece in
                [
                    "id": piece.id.uuidString,
                    "category": piece.category.rawValue,
                    "color": piece.color,
                    "fit": piece.fit.rawValue,
                    "material": piece.material,
                    "weight": piece.weight.rawValue,
                    "formality": piece.formality.rawValue,
                ]
            },
            "recent_suggestions": recentSuggestions.map { suggestion in
                [
                    "date": suggestion.date,
                    "piece_ids": suggestion.pieceIDs,
                    "feedback": suggestion.feedback,
                ] as [String: Any]
            },
        ]

        if let weather {
            payload["weather"] = [
                "temperature": weather.temperature,
                "feels_like": weather.feelsLike,
                "humidity": weather.humidity,
                "wind": weather.windSpeed,
                "condition": weather.condition,
                "hourly_forecast": weather.hourlyForecast.map { entry in
                    [
                        "hour": entry.hour,
                        "temp": entry.temperature,
                        "condition": entry.condition,
                    ] as [String: Any]
                },
            ] as [String: Any]
        }

        return payload
    }

    // MARK: - Response Parsing

    static func parseResponse(_ data: Data) throws -> SuggestionAPIResponse {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SuggestionError.malformedResponse
        }

        guard let pieces = json["pieces"] as? [String],
              let reasoning = json["reasoning"] as? String else {
            throw SuggestionError.missingRequiredFields
        }

        let layeringNote = json["layering_note"] as? String

        var alternativeSwap: AlternativeSwap?
        if let altJSON = json["alternative_piece"] as? [String: String],
           let swap = altJSON["swap"],
           let forPiece = altJSON["for"],
           let why = altJSON["why"] {
            alternativeSwap = AlternativeSwap(swapPieceID: swap, forPieceID: forPiece, reason: why)
        }

        return SuggestionAPIResponse(
            pieceIDs: pieces,
            reasoning: reasoning,
            layeringNote: layeringNote,
            alternativeSwap: alternativeSwap
        )
    }

    // MARK: - API Call

    func fetchSuggestion(
        archetypes: [StyleArchetype],
        boldness: Double,
        occasion: Occasion,
        weather: WeatherSnapshot?,
        wardrobe: [GarmentPiece],
        recentSuggestions: [(date: String, pieceIDs: [String], feedback: String)]
    ) async throws -> SuggestionAPIResponse {
        let payload = Self.buildPayload(
            archetypes: archetypes,
            boldness: boldness,
            occasion: occasion,
            weather: weather,
            wardrobe: wardrobe,
            recentSuggestions: recentSuggestions
        )

        let url = URL(string: "\(Self.proxyBaseURL)/suggest")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SuggestionError.networkError
        }

        guard httpResponse.statusCode == 200 else {
            throw SuggestionError.serverError(httpResponse.statusCode)
        }

        return try Self.parseResponse(data)
    }
}

// MARK: - Errors

enum SuggestionError: Error, LocalizedError {
    case malformedResponse
    case missingRequiredFields
    case networkError
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .malformedResponse: "Invalid response from server"
        case .missingRequiredFields: "Response missing required fields"
        case .networkError: "Network connection failed"
        case .serverError(let code): "Server error (\(code))"
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Expected: All 3 tests pass.

- [ ] **Step 5: Commit**

```bash
git add VESTI/Sources/Services/SuggestionService.swift VESTI/Tests/Services/SuggestionServiceTests.swift
git commit -m "feat: add suggestion service with proxy API client and response parsing"
```

---

### Task 19: Suggestion ViewModel

**Files:**
- Create: `VESTI/Sources/ViewModels/SuggestionViewModel.swift`
- Test: `VESTI/Tests/ViewModels/SuggestionViewModelTests.swift`

- [ ] **Step 1: Write tests**

```swift
// VESTI/Tests/ViewModels/SuggestionViewModelTests.swift
import XCTest
import SwiftData
@testable import VESTI

final class SuggestionViewModelTests: XCTestCase {

    func testInitialState() {
        let vm = SuggestionViewModel()
        XCTAssertEqual(vm.state, .empty)
        XCTAssertEqual(vm.boldness, 0.3)
        XCTAssertEqual(vm.occasion, .everyday)
    }

    func testMinimumPiecesCheck() {
        let vm = SuggestionViewModel()

        // 0 pieces — not enough
        XCTAssertFalse(vm.hasMinimumPieces([]))

        // 1 top, 1 bottom — enough
        let top = GarmentPiece(category: .tShirt, color: "white", colorHex: "#FFF", fit: .slim, material: "cotton", weight: .light, formality: .casual)
        let bottom = GarmentPiece(category: .jeans, color: "blue", colorHex: "#00F", fit: .straight, material: "denim", weight: .mid, formality: .casual)
        XCTAssertTrue(vm.hasMinimumPieces([top, bottom]))

        // 2 tops, 0 bottoms — not enough
        let top2 = GarmentPiece(category: .shirt, color: "white", colorHex: "#FFF", fit: .regular, material: "cotton", weight: .light, formality: .smartCasual)
        XCTAssertFalse(vm.hasMinimumPieces([top, top2]))
    }

    func testBuildRecentSuggestions() {
        let vm = SuggestionViewModel()

        let suggestion = OutfitSuggestion(
            pieceIDs: [UUID(), UUID()],
            occasion: .everyday,
            weather: nil,
            reasoning: "test"
        )
        suggestion.feedback = Feedback(liked: true)

        let recent = vm.buildRecentSuggestions(from: [suggestion])
        XCTAssertEqual(recent.count, 1)
        XCTAssertEqual(recent.first?.feedback, "liked")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: Compilation errors.

- [ ] **Step 3: Implement SuggestionViewModel**

```swift
// VESTI/Sources/ViewModels/SuggestionViewModel.swift
import SwiftUI
import SwiftData

enum SuggestionState: Equatable {
    case empty
    case loading
    case loaded
    case error(String)
    case insufficientPieces
}

@Observable
final class SuggestionViewModel {
    var state: SuggestionState = .empty
    var currentSuggestion: OutfitSuggestion?
    var suggestedPieces: [GarmentPiece] = []
    var boldness: Double = 0.3
    var occasion: Occasion = .everyday
    var showControls: Bool = false

    private let suggestionService = SuggestionService()
    private let weatherService = WeatherService()

    // MARK: - Validation

    func hasMinimumPieces(_ pieces: [GarmentPiece]) -> Bool {
        let active = pieces.filter(\.isActive)
        let hasTops = active.contains { $0.category.tabGroup == .tops }
        let hasBottoms = active.contains { $0.category.tabGroup == .bottoms }
        return hasTops && hasBottoms
    }

    // MARK: - Fetch Suggestion

    @MainActor
    func fetchSuggestion(
        archetypes: [StyleArchetype],
        wardrobe: [GarmentPiece],
        location: CLLocation?,
        recentSuggestions: [OutfitSuggestion]
    ) async {
        let activePieces = wardrobe.filter(\.isActive)

        guard hasMinimumPieces(activePieces) else {
            state = .insufficientPieces
            return
        }

        state = .loading

        // Fetch weather
        var weather: WeatherSnapshot?
        if let location {
            weather = await weatherService.fetchWeather(for: location)
        }

        // Build recent suggestions context
        let recent = buildRecentSuggestions(from: recentSuggestions)

        do {
            let response = try await suggestionService.fetchSuggestion(
                archetypes: archetypes,
                boldness: boldness,
                occasion: occasion,
                weather: weather,
                wardrobe: activePieces,
                recentSuggestions: recent
            )

            // Resolve piece UUIDs to actual pieces
            let resolvedPieces = response.pieceIDs.compactMap { idString in
                activePieces.first { $0.id.uuidString == idString }
            }

            // Create and store the suggestion
            let suggestion = OutfitSuggestion(
                pieceIDs: resolvedPieces.map(\.id),
                occasion: occasion,
                weather: weather,
                reasoning: response.reasoning,
                layeringNote: response.layeringNote,
                alternativeSwap: response.alternativeSwap
            )

            currentSuggestion = suggestion
            suggestedPieces = resolvedPieces
            state = .loaded
        } catch {
            // Try to show cached suggestion
            if let cached = recentSuggestions.first {
                currentSuggestion = cached
                suggestedPieces = cached.pieceIDs.compactMap { id in
                    activePieces.first { $0.id == id }
                }
                state = .loaded
            } else {
                state = .error(error.localizedDescription)
            }
        }
    }

    // MARK: - Feedback

    @MainActor
    func submitFeedback(liked: Bool, context: ModelContext) {
        guard let suggestion = currentSuggestion else { return }
        let feedback = Feedback(liked: liked)
        suggestion.feedback = feedback
        context.insert(suggestion)
        try? context.save()
    }

    // MARK: - Helpers

    func buildRecentSuggestions(
        from suggestions: [OutfitSuggestion]
    ) -> [(date: String, pieceIDs: [String], feedback: String)] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        return suggestions.prefix(10).map { suggestion in
            (
                date: formatter.string(from: suggestion.suggestedAt),
                pieceIDs: suggestion.pieceIDs.map(\.uuidString),
                feedback: suggestion.feedback?.payloadValue ?? "none"
            )
        }
    }
}
```

Note: Add `import CoreLocation` at the top of the file.

- [ ] **Step 4: Run tests to verify they pass**

Expected: All 3 tests pass.

- [ ] **Step 5: Commit**

```bash
git add VESTI/Sources/ViewModels/SuggestionViewModel.swift VESTI/Tests/ViewModels/SuggestionViewModelTests.swift
git commit -m "feat: add suggestion view model with fetch, feedback, and state management"
```

---

## Chunk 7: Home Screen + Settings + Integration

### Task 20: Suggestion Views

**Files:**
- Create: `VESTI/Sources/Views/Suggestion/OutfitCardView.swift`
- Create: `VESTI/Sources/Views/Suggestion/SuggestionLoadingView.swift`
- Create: `VESTI/Sources/Views/Suggestion/SuggestionControlsView.swift`
- Create: `VESTI/Sources/Views/Suggestion/SuggestionView.swift`

- [ ] **Step 1: Implement OutfitCardView**

```swift
// VESTI/Sources/Views/Suggestion/OutfitCardView.swift
import SwiftUI

struct OutfitCardView: View {
    let piece: GarmentPiece
    let alternativeLabel: String?

    init(piece: GarmentPiece, alternativeLabel: String? = nil) {
        self.piece = piece
        self.alternativeLabel = alternativeLabel
    }

    var body: some View {
        VStack(spacing: VESTIDesign.Spacing.sm) {
            Group {
                if let uiImage = CatalogImageService.loadImage(
                    category: piece.category, color: piece.color, fit: piece.fit
                ) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                } else {
                    RoundedRectangle(cornerRadius: VESTIDesign.Radius.sm)
                        .fill(Color(hex: piece.colorHex).opacity(0.3))
                        .aspectRatio(4 / 3, contentMode: .fit)
                        .overlay {
                            VStack(spacing: VESTIDesign.Spacing.xs) {
                                Image(systemName: piece.category.systemIcon)
                                    .font(.system(size: 32))
                                Text("\(piece.color.capitalized) \(piece.category.displayName)")
                                    .font(VESTIDesign.Typography.caption)
                            }
                            .foregroundStyle(VESTIDesign.Colors.textSecondary)
                        }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: VESTIDesign.Radius.sm))

            Text("\(piece.color.capitalized) \(piece.category.displayName)")
                .font(VESTIDesign.Typography.caption)
                .foregroundStyle(VESTIDesign.Colors.textSecondary)

            if let alternativeLabel {
                Text(alternativeLabel)
                    .font(VESTIDesign.Typography.small)
                    .foregroundStyle(VESTIDesign.Colors.textTertiary)
                    .italic()
            }
        }
        .vestiCard()
    }
}
```

- [ ] **Step 2: Implement SuggestionLoadingView**

```swift
// VESTI/Sources/Views/Suggestion/SuggestionLoadingView.swift
import SwiftUI

struct SuggestionLoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: VESTIDesign.Spacing.lg) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: VESTIDesign.Radius.md)
                    .fill(VESTIDesign.Colors.border)
                    .frame(height: 120)
                    .opacity(isAnimating ? 0.4 : 0.8)
            }

            RoundedRectangle(cornerRadius: VESTIDesign.Radius.sm)
                .fill(VESTIDesign.Colors.border)
                .frame(height: 20)
                .frame(maxWidth: 200)
                .opacity(isAnimating ? 0.4 : 0.8)
        }
        .padding(VESTIDesign.Spacing.md)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}
```

- [ ] **Step 3: Implement SuggestionControlsView**

```swift
// VESTI/Sources/Views/Suggestion/SuggestionControlsView.swift
import SwiftUI

struct SuggestionControlsView: View {
    @Binding var occasion: Occasion
    @Binding var boldness: Double

    var body: some View {
        VStack(spacing: VESTIDesign.Spacing.md) {
            // Occasion selector
            VStack(alignment: .leading, spacing: VESTIDesign.Spacing.sm) {
                Text("Occasion")
                    .font(VESTIDesign.Typography.caption)
                    .foregroundStyle(VESTIDesign.Colors.textSecondary)

                HStack(spacing: VESTIDesign.Spacing.sm) {
                    ForEach(Occasion.allCases) { occ in
                        Button {
                            occasion = occ
                        } label: {
                            Text(occ.displayName)
                                .font(VESTIDesign.Typography.small)
                                .foregroundStyle(
                                    occasion == occ
                                        ? VESTIDesign.Colors.background
                                        : VESTIDesign.Colors.textPrimary
                                )
                                .padding(.horizontal, VESTIDesign.Spacing.md)
                                .padding(.vertical, VESTIDesign.Spacing.sm)
                                .background(
                                    occasion == occ
                                        ? VESTIDesign.Colors.accent
                                        : VESTIDesign.Colors.surface
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // Boldness slider
            VStack(alignment: .leading, spacing: VESTIDesign.Spacing.sm) {
                Text("Boldness")
                    .font(VESTIDesign.Typography.caption)
                    .foregroundStyle(VESTIDesign.Colors.textSecondary)

                HStack {
                    Text("Safe")
                        .font(VESTIDesign.Typography.small)
                        .foregroundStyle(VESTIDesign.Colors.textTertiary)
                    Slider(value: $boldness, in: 0...1, step: 0.1)
                        .tint(VESTIDesign.Colors.accent)
                    Text("Bold")
                        .font(VESTIDesign.Typography.small)
                        .foregroundStyle(VESTIDesign.Colors.textTertiary)
                }
            }
        }
        .padding(VESTIDesign.Spacing.md)
        .background(VESTIDesign.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: VESTIDesign.Radius.lg))
        .shadow(color: VESTIDesign.Colors.cardShadow, radius: 12)
    }
}
```

- [ ] **Step 4: Implement SuggestionView (Home Screen)**

```swift
// VESTI/Sources/Views/Suggestion/SuggestionView.swift
import SwiftUI
import SwiftData
import CoreLocation

struct SuggestionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [StyleProfile]
    @Query(filter: #Predicate<GarmentPiece> { $0.isActive })
    private var pieces: [GarmentPiece]
    @Query(sort: \OutfitSuggestion.suggestedAt, order: .reverse)
    private var recentSuggestions: [OutfitSuggestion]

    @State private var viewModel = SuggestionViewModel()
    @State private var locationManager = LocationManager()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: VESTIDesign.Spacing.lg) {
                    // Pull-down controls
                    if viewModel.showControls {
                        SuggestionControlsView(
                            occasion: $viewModel.occasion,
                            boldness: $viewModel.boldness
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    switch viewModel.state {
                    case .empty, .loading:
                        SuggestionLoadingView()

                    case .insufficientPieces:
                        EmptyStateView(
                            title: "Almost there",
                            message: "Add a few more pieces and I'll start suggesting outfits. You need at least one top and one bottom."
                        )

                    case .error(let message):
                        EmptyStateView(
                            title: "Couldn't load suggestion",
                            message: message,
                            actionLabel: "Try Again",
                            action: { Task { await loadSuggestion() } }
                        )

                    case .loaded:
                        if let suggestion = viewModel.currentSuggestion {
                            // Outfit cards
                            VStack(spacing: VESTIDesign.Spacing.md) {
                                ForEach(viewModel.suggestedPieces) { piece in
                                    OutfitCardView(piece: piece)
                                }
                            }

                            // Reasoning
                            Text(suggestion.reasoning)
                                .font(VESTIDesign.Typography.bodyText)
                                .foregroundStyle(VESTIDesign.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, VESTIDesign.Spacing.md)

                            // Layering note
                            if let note = suggestion.layeringNote {
                                HStack(spacing: VESTIDesign.Spacing.sm) {
                                    Image(systemName: "cloud.sun")
                                        .foregroundStyle(VESTIDesign.Colors.textTertiary)
                                    Text(note)
                                        .font(VESTIDesign.Typography.caption)
                                        .foregroundStyle(VESTIDesign.Colors.textSecondary)
                                }
                                .padding(VESTIDesign.Spacing.md)
                                .background(VESTIDesign.Colors.border.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: VESTIDesign.Radius.sm))
                            }

                            // Feedback + Regenerate
                            HStack(spacing: VESTIDesign.Spacing.xl) {
                                Button {
                                    viewModel.submitFeedback(liked: false, context: modelContext)
                                } label: {
                                    Image(systemName: "hand.thumbsdown")
                                        .font(.system(size: 20))
                                        .foregroundStyle(VESTIDesign.Colors.disliked)
                                }

                                Button {
                                    Task { await loadSuggestion() }
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 20))
                                        .foregroundStyle(VESTIDesign.Colors.textSecondary)
                                }

                                Button {
                                    viewModel.submitFeedback(liked: true, context: modelContext)
                                } label: {
                                    Image(systemName: "hand.thumbsup")
                                        .font(.system(size: 20))
                                        .foregroundStyle(VESTIDesign.Colors.liked)
                                }
                            }
                            .padding(.top, VESTIDesign.Spacing.md)
                        }
                    }
                }
                .padding(VESTIDesign.Spacing.md)
            }
            .background(VESTIDesign.Colors.background)
            .navigationTitle("VESTI")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation { viewModel.showControls.toggle() }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .task {
                await loadSuggestion()
            }
        }
    }

    private func loadSuggestion() async {
        guard let profile = profiles.first else { return }
        await viewModel.fetchSuggestion(
            archetypes: profile.archetypes,
            wardrobe: pieces,
            location: locationManager.location,
            recentSuggestions: Array(recentSuggestions.prefix(10))
        )
    }
}

// MARK: - Simple Location Manager

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    var location: CLLocation?
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
        manager.stopUpdatingLocation()
    }
}
```

- [ ] **Step 5: Build and verify**

Run: `xcodebuild build -project VESTI.xcodeproj -scheme VESTI -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -3`

Expected: Build succeeds.

- [ ] **Step 6: Commit**

```bash
git add VESTI/Sources/Views/Suggestion/
git commit -m "feat: add suggestion home screen with outfit cards, feedback, and controls"
```

---

### Task 21: Settings View

**Files:**
- Create: `VESTI/Sources/Views/Settings/SettingsView.swift`

- [ ] **Step 1: Implement SettingsView**

```swift
// VESTI/Sources/Views/Settings/SettingsView.swift
import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [StyleProfile]
    @State private var selectedArchetypes: Set<StyleArchetype> = []

    private let columns = [
        GridItem(.flexible(), spacing: VESTIDesign.Spacing.md),
        GridItem(.flexible(), spacing: VESTIDesign.Spacing.md),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: VESTIDesign.Spacing.lg) {
                    // Style Archetypes
                    VStack(alignment: .leading, spacing: VESTIDesign.Spacing.md) {
                        Text("Your Styles")
                            .font(VESTIDesign.Typography.title)
                            .foregroundStyle(VESTIDesign.Colors.textPrimary)

                        LazyVGrid(columns: columns, spacing: VESTIDesign.Spacing.md) {
                            ForEach(StyleArchetype.allCases) { archetype in
                                Button {
                                    toggleArchetype(archetype)
                                } label: {
                                    Text(archetype.displayName)
                                        .font(VESTIDesign.Typography.caption)
                                        .foregroundStyle(VESTIDesign.Colors.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(VESTIDesign.Spacing.md)
                                        .background(
                                            selectedArchetypes.contains(archetype)
                                                ? VESTIDesign.Colors.accent.opacity(0.1)
                                                : VESTIDesign.Colors.surface
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: VESTIDesign.Radius.md))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: VESTIDesign.Radius.md)
                                                .stroke(
                                                    selectedArchetypes.contains(archetype)
                                                        ? VESTIDesign.Colors.accent : VESTIDesign.Colors.border,
                                                    lineWidth: 1
                                                )
                                        }
                                }
                            }
                        }
                    }

                    Divider()

                    // About
                    VStack(alignment: .leading, spacing: VESTIDesign.Spacing.sm) {
                        Text("About")
                            .font(VESTIDesign.Typography.title)
                            .foregroundStyle(VESTIDesign.Colors.textPrimary)

                        Text("VESTI v1.0")
                            .font(VESTIDesign.Typography.bodyText)
                            .foregroundStyle(VESTIDesign.Colors.textSecondary)

                        Text("Dress with intention.")
                            .font(VESTIDesign.Typography.caption)
                            .foregroundStyle(VESTIDesign.Colors.textTertiary)
                    }
                }
                .padding(VESTIDesign.Spacing.md)
            }
            .background(VESTIDesign.Colors.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let profile = profiles.first {
                    selectedArchetypes = Set(profile.archetypes)
                }
            }
        }
    }

    private func toggleArchetype(_ archetype: StyleArchetype) {
        if selectedArchetypes.contains(archetype) {
            if selectedArchetypes.count > 1 { // Keep minimum 1
                selectedArchetypes.remove(archetype)
            }
        } else {
            selectedArchetypes.insert(archetype)
        }
    }

    private func saveChanges() {
        if let profile = profiles.first {
            profile.archetypes = Array(selectedArchetypes)
            profile.updatedAt = Date()
            try? modelContext.save()
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add VESTI/Sources/Views/Settings/SettingsView.swift
git commit -m "feat: add settings view with archetype editing"
```

---

### Task 22: Wire Everything Together

**Files:**
- Modify: `VESTI/Sources/App/VESTIApp.swift`

- [ ] **Step 1: Update MainTabView and ContentView**

```swift
// VESTI/Sources/App/VESTIApp.swift
import SwiftUI
import SwiftData

@main
struct VESTIApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .modelContainer(for: [
            StyleProfile.self,
            GarmentPiece.self,
            OutfitSuggestion.self,
            Feedback.self,
        ])
    }
}

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                MainTabView()
            } else {
                StyleOnboardingView()
            }
        }
        .onAppear {
            appState.checkOnboardingStatus(context: modelContext)
        }
    }
}

struct MainTabView: View {
    @State private var showSettings = false

    var body: some View {
        TabView {
            Tab("Home", systemImage: "tshirt") {
                SuggestionView()
            }
            Tab("Wardrobe", systemImage: "cabinet") {
                WardrobeView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                showSettings = true
                            } label: {
                                Image(systemName: "gearshape")
                            }
                        }
                    }
            }
        }
        .tint(VESTIDesign.Colors.accent)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}
```

- [ ] **Step 2: Create PreviewData for SwiftUI previews**

```swift
// VESTI/Preview Content/PreviewData.swift
import SwiftData
import Foundation

enum PreviewData {
    static var samplePieces: [GarmentPiece] {
        [
            GarmentPiece(category: .tShirt, color: "white", colorHex: "#FFFFFF", fit: .slim, material: "cotton", weight: .light, formality: .casual),
            GarmentPiece(category: .jeans, color: "indigo", colorHex: "#3F5277", fit: .straight, material: "denim", weight: .mid, formality: .casual),
            GarmentPiece(category: .jacket, color: "navy", colorHex: "#1B2A4A", fit: .regular, material: "wool", weight: .heavy, formality: .smartCasual),
            GarmentPiece(category: .chinos, color: "khaki", colorHex: "#C4A46C", fit: .regular, material: "cotton", weight: .mid, formality: .smartCasual),
            GarmentPiece(category: .sweater, color: "charcoal", colorHex: "#4A4A4A", fit: .regular, material: "wool", weight: .heavy, formality: .smartCasual),
        ]
    }

    static var sampleProfile: StyleProfile {
        StyleProfile(archetypes: [.oldMoney, .minimalist])
    }
}
```

- [ ] **Step 3: Regenerate project, build, and run all tests**

Run:
```bash
cd /Users/lucasgalhardo/Documents/Projects/vesti
xcodegen generate
xcodebuild build -project VESTI.xcodeproj -scheme VESTI -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5
xcodebuild test -project VESTI.xcodeproj -scheme VESTITests -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E '(Executed|FAIL)' | tail -5
```

Expected: Build succeeds, all tests pass.

- [ ] **Step 4: Commit**

```bash
git add VESTI/Sources/App/VESTIApp.swift VESTI/"Preview Content"/PreviewData.swift
git commit -m "feat: wire up all views — onboarding, wardrobe, suggestions, settings"
```

---

### Task 23: Deploy Proxy Server

- [ ] **Step 1: Install wrangler CLI if needed**

Run: `npm install -g wrangler` (skip if already installed)

- [ ] **Step 2: Login to Cloudflare**

Run: `cd vesti-proxy && wrangler login`

- [ ] **Step 3: Set the Anthropic API key as a secret**

Run: `cd vesti-proxy && wrangler secret put ANTHROPIC_API_KEY`

Enter your Anthropic API key when prompted.

- [ ] **Step 4: Deploy**

Run: `cd vesti-proxy && npm run deploy`

Expected: Deployment succeeds, outputs a URL like `https://vesti-proxy.YOUR_SUBDOMAIN.workers.dev`

- [ ] **Step 5: Update SuggestionService with the deployed URL**

In `VESTI/Sources/Services/SuggestionService.swift`, update:
```swift
static let proxyBaseURL = "https://vesti-proxy.YOUR_SUBDOMAIN.workers.dev"
```

- [ ] **Step 6: Test the proxy manually**

Run:
```bash
curl -X POST https://vesti-proxy.YOUR_SUBDOMAIN.workers.dev/suggest \
  -H "Content-Type: application/json" \
  -d '{
    "style_archetypes": ["old-money", "minimalist"],
    "boldness": 0.3,
    "occasion": "everyday",
    "wardrobe": [
      {"id": "1", "category": "tShirt", "color": "white", "fit": "slim", "material": "cotton", "weight": "light", "formality": "casual"},
      {"id": "2", "category": "jeans", "color": "indigo", "fit": "straight", "material": "denim", "weight": "mid", "formality": "casual"},
      {"id": "3", "category": "jacket", "color": "navy", "fit": "regular", "material": "wool", "weight": "heavy", "formality": "smartCasual"}
    ],
    "recent_suggestions": []
  }'
```

Expected: JSON response with pieces, reasoning, and optionally layering_note and alternative_piece.

- [ ] **Step 7: Commit the URL update**

```bash
git add VESTI/Sources/Services/SuggestionService.swift
git commit -m "feat: configure proxy URL for deployed Cloudflare Worker"
```

---

### Task 24: Final Build + Smoke Test

- [ ] **Step 1: Run full test suite**

```bash
cd /Users/lucasgalhardo/Documents/Projects/vesti
xcodegen generate
xcodebuild test -project VESTI.xcodeproj -scheme VESTITests -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E '(Executed|FAIL)'
cd vesti-proxy && npx vitest run
```

Expected: All iOS and proxy tests pass.

- [ ] **Step 2: Run the app in simulator**

Open `VESTI.xcodeproj` in Xcode, select iPhone 16 simulator, and run. Verify:
1. Onboarding shows archetype grid
2. Selecting 1+ archetypes and tapping Continue saves profile
3. Wardrobe screen shows empty state with "Add Piece" button
4. Registration flow works: category → color → fit → material → weight → formality → confirm
5. Home screen attempts to load suggestion (may show loading or error without real pieces + proxy)
6. Settings allows editing archetypes

- [ ] **Step 3: Commit any final adjustments**

```bash
git add -A
git commit -m "chore: final adjustments after smoke test"
```
