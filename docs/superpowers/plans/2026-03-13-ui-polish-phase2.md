# UI Polish Phase 2 Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 5 visual/UI inconsistencies from TestFlight build 3 to align with the matcha brand identity.

**Architecture:** All changes are contained edits to existing SwiftUI view files. No new files, no model changes. Fixes touch CategoryPickerView, WardrobeView, SuggestionView, and GarmentDetailView.

**Tech Stack:** Swift, SwiftUI, xcodegen

**Prerequisites:** The `KISE.xcodeproj` must be generated before building. No files are created or deleted in this plan (only modified in place), so existing xcodeproj file references remain valid. If the xcodeproj is stale, run `xcodegen generate` first.

---

## Chunk 1: All Tasks

### Task 1: Category Picker — Grouped Sections, No Icons (Fix 1 + Fix 5)

Combines spec Fix 1 (remove icons, group by section) and Fix 5 (add accentMuted border) since both modify the same file.

**Files:**
- Modify: `KISE/Sources/Views/Registration/CategoryPickerView.swift` (entire file rewrite)

- [ ] **Step 1: Rewrite CategoryPickerView with grouped sections and branded cards**

Replace the entire file content. The new version:
- Removes the `GarmentCategory.systemIcon` extension (lines 42-58)
- Replaces the flat `ForEach(GarmentCategory.allCases)` with a `ForEach(TabGroup.allCases, id: \.self)` that filters categories per group
- Adds `kiseSectionLabel()` headers for each group
- Removes `Image(systemName:)` from cards — text-only
- Adds `accentMuted` border overlay on each card (Fix 5)

```swift
// KISE/Sources/Views/Registration/CategoryPickerView.swift
import SwiftUI

struct CategoryPickerView: View {
    let onSelect: (GarmentCategory) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: KISEDesign.Spacing.md),
        GridItem(.flexible(), spacing: KISEDesign.Spacing.md),
        GridItem(.flexible(), spacing: KISEDesign.Spacing.md),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: KISEDesign.Spacing.lg) {
            Text("What type of piece?")
                .font(KISEDesign.Typography.title)
                .foregroundStyle(KISEDesign.Colors.textPrimary)

            VStack(alignment: .leading, spacing: KISEDesign.Spacing.lg) {
                ForEach(TabGroup.allCases, id: \.self) { group in
                    let categories = GarmentCategory.allCases.filter { $0.tabGroup == group }
                    VStack(alignment: .leading, spacing: KISEDesign.Spacing.sm) {
                        Text(group.rawValue.capitalized)
                            .kiseSectionLabel()

                        LazyVGrid(columns: columns, spacing: KISEDesign.Spacing.md) {
                            ForEach(categories) { category in
                                Button {
                                    onSelect(category)
                                } label: {
                                    Text(category.displayName)
                                        .font(KISEDesign.Typography.caption)
                                        .foregroundStyle(KISEDesign.Colors.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, KISEDesign.Spacing.md)
                                        .kiseCard()
                                        .overlay {
                                            RoundedRectangle(cornerRadius: KISEDesign.Radius.md)
                                                .strokeBorder(KISEDesign.Colors.accentMuted, lineWidth: 1)
                                        }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 2: Build to verify compilation**

Run: `cd /Users/lucasgalhardo/Documents/Projects/vesti && xcodebuild build -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet 2>&1 | tail -5`

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Run tests**

Run: `cd /Users/lucasgalhardo/Documents/Projects/vesti && xcodebuild test -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet 2>&1 | tail -10`

Expected: All tests pass. No tests reference `systemIcon` so removing it should not break anything.

- [ ] **Step 4: Commit**

```bash
git add KISE/Sources/Views/Registration/CategoryPickerView.swift
git commit -m "fix: replace category picker icons with grouped text sections and branded borders"
```

---

### Task 2: Wardrobe Title Left-Alignment (Fix 2)

**Files:**
- Modify: `KISE/Sources/Views/Wardrobe/WardrobeView.swift:68-81` (toolbar block)

- [ ] **Step 1: Change toolbar title placement from `.principal` to `.topBarLeading`**

In `WardrobeView.swift`, replace lines 68-81 (the `.toolbar` block):

```swift
// BEFORE (lines 68-81):
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

```swift
// AFTER:
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
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

Only change: `.principal` → `.topBarLeading` on line 69.

**Note:** The settings gear button is defined in `KISEApp.swift` (lines 58-66) on `.topBarTrailing`. After this change the toolbar has: `.topBarLeading` (title), `.topBarTrailing` (gear from MainTabView), `.primaryAction` (`+`). Verify in simulator that gear and `+` don't overlap.

- [ ] **Step 2: Build to verify compilation**

Run: `cd /Users/lucasgalhardo/Documents/Projects/vesti && xcodebuild build -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet 2>&1 | tail -5`

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add KISE/Sources/Views/Wardrobe/WardrobeView.swift
git commit -m "fix: left-align Wardrobe title to close gap with + button"
```

---

### Task 3: Edge-to-Edge Background (Fix 3)

**Files:**
- Modify: `KISE/Sources/Views/Suggestion/SuggestionView.swift:33` (background modifier)
- Modify: `KISE/Sources/Views/Wardrobe/WardrobeView.swift:66` (background modifier)

- [ ] **Step 1: Fix SuggestionView background**

In `SuggestionView.swift`, replace the background modifier on line 33:

```swift
// BEFORE (line 33, on the ScrollView):
            .background(KISEDesign.Colors.background)
```

```swift
// AFTER (on the ScrollView):
            .background {
                KISEDesign.Colors.background.ignoresSafeArea()
            }
```

- [ ] **Step 2: Fix WardrobeView background**

In `WardrobeView.swift`, replace the background modifier on line 66:

```swift
// BEFORE (line 66, on the VStack):
            .background(KISEDesign.Colors.background)
```

```swift
// AFTER (on the VStack):
            .background {
                KISEDesign.Colors.background.ignoresSafeArea()
            }
```

- [ ] **Step 3: Build to verify compilation**

Run: `cd /Users/lucasgalhardo/Documents/Projects/vesti && xcodebuild build -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet 2>&1 | tail -5`

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add KISE/Sources/Views/Suggestion/SuggestionView.swift KISE/Sources/Views/Wardrobe/WardrobeView.swift
git commit -m "fix: extend background color edge-to-edge with ignoresSafeArea"
```

---

### Task 4: Garment Detail Brand Title (Fix 4)

**Files:**
- Modify: `KISE/Sources/Views/Wardrobe/GarmentDetailView.swift:46-48` (navigationTitle + toolbar)

- [ ] **Step 1: Replace navigationTitle with custom toolbar title**

In `GarmentDetailView.swift`, replace line 46:

```swift
// BEFORE (line 46):
        .navigationTitle(piece.category.displayName)
```

```swift
// AFTER:
```

(Remove the line entirely.)

Then add a `ToolbarItem(placement: .principal)` inside the existing `.toolbar` block (lines 48-65). The toolbar block becomes:

```swift
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(piece.category.displayName)
                    .font(KISEDesign.Typography.subtitle)
                    .foregroundStyle(KISEDesign.Colors.textPrimary)
            }
            ToolbarItem(placement: .bottomBar) {
                Button(role: piece.isActive ? .destructive : nil) {
                    if piece.isActive {
                        WardrobeViewModel.archivePiece(piece)
                    } else {
                        WardrobeViewModel.restorePiece(piece)
                    }
                    dismiss()
                } label: {
                    Label(
                        piece.isActive ? "Archive" : "Restore",
                        systemImage: piece.isActive ? "archivebox" : "arrow.uturn.backward"
                    )
                    .font(KISEDesign.Typography.bodyText)
                }
            }
        }
```

Keep `.navigationBarTitleDisplayMode(.inline)` on line 47.

**Context:** `GarmentDetailView` is presented modally in a `.sheet` with its own `NavigationStack` (see `WardrobeView.swift` lines 85-88), so removing `.navigationTitle` has no back-button side effects.

- [ ] **Step 2: Build to verify compilation**

Run: `cd /Users/lucasgalhardo/Documents/Projects/vesti && xcodebuild build -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet 2>&1 | tail -5`

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add KISE/Sources/Views/Wardrobe/GarmentDetailView.swift
git commit -m "fix: replace system font navigationTitle with DM Sans custom title in garment detail"
```

---

### Task 5: Final Verification

- [ ] **Step 1: Run full test suite**

Run: `cd /Users/lucasgalhardo/Documents/Projects/vesti && xcodebuild test -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet 2>&1 | tail -10`

Expected: All tests pass.

- [ ] **Step 2: Visual verification**

Run the app in Simulator on iPhone 16 Pro and walk through the full flow:
1. Onboarding → style selection → Continue
2. Wardrobe (empty state) → verify title is left-aligned, `+` and gear don't overlap
3. Add Piece → verify grouped category sections with section labels, branded card borders
4. Add 2+ pieces → switch to Home tab
5. Suggestion view → verify no white edge gaps, "YOUR LOOK" label
6. Tap a garment in Wardrobe → verify detail title uses DM Sans, not system font

Also check on iPhone SE (3rd generation) for layout on smaller screens.

---
