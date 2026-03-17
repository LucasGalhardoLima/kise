# Brand Identity Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the matcha color palette, Cormorant Garamond display headings, and tracked small-caps section labels to transform KISE's visual identity from generic minimalist to distinctly branded.

**Architecture:** Pure styling changes across 4 files. DesignSystem.swift token updates are the foundation — most views pick up changes automatically. Per-view work replaces system `.navigationTitle` with custom Cormorant headings, adjusts accent border colors, and adds a section label modifier. No model or data changes.

**Tech Stack:** Swift/SwiftUI, iOS 17+, Xcode 26

**Spec:** `docs/superpowers/specs/2026-03-13-brand-identity-phase1.md`

---

## File Structure

### Modify
- `KISE/Sources/Views/Shared/DesignSystem.swift` — Color tokens, typography tokens, new section label modifier
- `KISE/Sources/Views/Suggestion/SuggestionView.swift` — Custom title view, section label, pill borders, slider tint
- `KISE/Sources/Views/Wardrobe/WardrobeView.swift` — Custom title view, tab borders
- `KISE/Sources/Views/Onboarding/StyleOnboardingView.swift` — Archetype selection stroke color

---

## Chunk 1: All Tasks

### Task 1: Update DesignSystem.swift — tokens + section label modifier

**Files:**
- Modify: `KISE/Sources/Views/Shared/DesignSystem.swift:1-100`

- [ ] **Step 1: Update color tokens and add new ones**

Replace the entire `Colors` enum (lines 8-19) with:

```swift
    enum Colors {
        static let background = Color(hex: "#F5F3EF")
        static let surface = Color.white
        static let textPrimary = Color(hex: "#344E41")
        static let textSecondary = Color(hex: "#6B6B6B")
        static let textTertiary = Color(hex: "#9B9B9B")
        static let accent = Color(hex: "#3A5A40")
        static let accentSecondary = Color(hex: "#588157")
        static let accentMuted = Color(hex: "#A3B18A")
        static let border = Color(hex: "#E5E1DB")
        static let cardShadow = Color.black.opacity(0.06)
        static let liked = Color(hex: "#588157")
        static let disliked = Color(hex: "#8B4B4B")
    }
```

- [ ] **Step 2: Update typography predefined sizes and add sectionLabel**

Replace lines 54-61 (the predefined sizes block) with:

```swift
        // Predefined sizes
        static let largeTitle = brand(32)
        static let title = brand(24)
        static let subtitle = bodyMedium(17)
        static let bodyText = body(15)
        static let caption = body(13)
        static let small = body(11)
        static let sectionLabel = bodyMedium(11)
        static let brandTitle = brand(36)
```

Also update the brand font comment on line 30 from:

```swift
        // Brand font: Cormorant Garamond (splash/wordmark only)
```

to:

```swift
        // Brand font: Cormorant Garamond (display headings + wordmark)
```

- [ ] **Step 3: Add KISESectionLabelStyle modifier and View extension**

After the existing `kiseCard()` View extension (after line 99), add:

```swift

// MARK: - Section Label Style Modifier

struct KISESectionLabelStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(KISEDesign.Typography.sectionLabel)
            .tracking(3)
            .textCase(.uppercase)
            .foregroundStyle(KISEDesign.Colors.textTertiary)
    }
}

extension View {
    func kiseSectionLabel() -> some View {
        modifier(KISESectionLabelStyle())
    }
}
```

- [ ] **Step 4: Build to verify**

Run: `xcodebuild build -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add KISE/Sources/Views/Shared/DesignSystem.swift
git commit -m "feat: apply matcha palette, Cormorant headings, and section label style to design system"
```

---

### Task 2: Update SuggestionView — custom title, section label, pill borders, slider tint

**Files:**
- Modify: `KISE/Sources/Views/Suggestion/SuggestionView.swift`

- [ ] **Step 1: Replace .navigationTitle with custom toolbar title**

Replace lines 34-35:

```swift
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
```

with:

```swift
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Today")
                        .font(KISEDesign.Typography.largeTitle)
                        .foregroundStyle(KISEDesign.Colors.textPrimary)
                }
            }
```

- [ ] **Step 2: Add "Your Look" section label above outfit cards**

Replace lines 123-124 (the `// Outfit cards` comment and `outfitCards`):

```swift
            // Outfit cards
            outfitCards
```

with:

```swift
            // Section label + Outfit cards
            VStack(alignment: .leading, spacing: KISEDesign.Spacing.sm) {
                Text("Your Look")
                    .kiseSectionLabel()
                outfitCards
            }
```

- [ ] **Step 3: Change inactive pill border from .border to .accentMuted**

Replace line 184:

```swift
                                            .strokeBorder(KISEDesign.Colors.border, lineWidth: viewModel.occasion == occasion ? 0 : 1)
```

with:

```swift
                                            .strokeBorder(KISEDesign.Colors.accentMuted, lineWidth: viewModel.occasion == occasion ? 0 : 1)
```

- [ ] **Step 4: Change slider tint from .accent to .accentSecondary**

Replace line 206:

```swift
                            .tint(KISEDesign.Colors.accent)
```

with:

```swift
                            .tint(KISEDesign.Colors.accentSecondary)
```

- [ ] **Step 5: Build to verify**

Run: `xcodebuild build -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

- [ ] **Step 6: Commit**

```bash
git add KISE/Sources/Views/Suggestion/SuggestionView.swift
git commit -m "feat: apply matcha identity to SuggestionView — custom title, section label, pill borders, slider tint"
```

---

### Task 3: Update WardrobeView — custom title, tab borders

**Files:**
- Modify: `KISE/Sources/Views/Wardrobe/WardrobeView.swift`

- [ ] **Step 1: Replace .navigationTitle and existing .toolbar with merged toolbar**

Replace lines 67-77 (`.navigationTitle`, `.navigationBarTitleDisplayMode`, and the existing `.toolbar` block) — the old code is:

```swift
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
```

Replace with:

```swift
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Wardrobe")
                        .font(KISEDesign.Typography.largeTitle)
                        .foregroundStyle(KISEDesign.Colors.textPrimary)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showRegistration = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
```

- [ ] **Step 2: Add accentMuted border on inactive tabs**

Replace the `tabButton` function (lines 89-109) with:

```swift
    private func tabButton(_ label: String, tab: TabGroup?) -> some View {
        Button {
            withAnimation { viewModel.selectedTab = tab }
        } label: {
            Text(label)
                .font(KISEDesign.Typography.caption)
                .foregroundStyle(
                    viewModel.selectedTab == tab
                        ? KISEDesign.Colors.background
                        : KISEDesign.Colors.textPrimary
                )
                .padding(.horizontal, KISEDesign.Spacing.md)
                .padding(.vertical, KISEDesign.Spacing.sm)
                .background(
                    viewModel.selectedTab == tab
                        ? KISEDesign.Colors.accent
                        : KISEDesign.Colors.surface
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(
                            viewModel.selectedTab == tab
                                ? Color.clear
                                : KISEDesign.Colors.accentMuted,
                            lineWidth: 1
                        )
                )
        }
    }
```

- [ ] **Step 3: Build to verify**

Run: `xcodebuild build -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add KISE/Sources/Views/Wardrobe/WardrobeView.swift
git commit -m "feat: apply matcha identity to WardrobeView — custom title, tab borders"
```

---

### Task 4: Update StyleOnboardingView — archetype stroke color

**Files:**
- Modify: `KISE/Sources/Views/Onboarding/StyleOnboardingView.swift:108-114`

- [ ] **Step 1: Change archetype selection stroke from accent to accentMuted**

Replace lines 108-114 (the `.overlay` on ArchetypeCard):

```swift
        .overlay {
            RoundedRectangle(cornerRadius: KISEDesign.Radius.md)
                .stroke(
                    isSelected ? KISEDesign.Colors.accent : Color.clear,
                    lineWidth: 2
                )
        }
```

with:

```swift
        .overlay {
            RoundedRectangle(cornerRadius: KISEDesign.Radius.md)
                .stroke(
                    isSelected ? KISEDesign.Colors.accentMuted : Color.clear,
                    lineWidth: 2
                )
        }
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild build -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Run all tests**

Run: `xcodebuild test -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -30`
Expected: All tests pass (8/8)

- [ ] **Step 4: Commit**

```bash
git add KISE/Sources/Views/Onboarding/StyleOnboardingView.swift
git commit -m "feat: soften archetype selection stroke to accentMuted"
```
