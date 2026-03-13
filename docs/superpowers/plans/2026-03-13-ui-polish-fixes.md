# UI Polish Fixes Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix four UI issues from TestFlight feedback — remove Liquid Glass from cards, redesign color picker as 4-column grid, inline custom color picker, and fix registration step transition bleed-through.

**Architecture:** View-layer only changes to three files. No model or data changes. Remove iOS 26 glass effect from card modifier, restructure CuratedColorPicker layout and custom picker interaction, add step transitions to RegistrationFlowView.

**Tech Stack:** Swift/SwiftUI, iOS 17+, Xcode 26

**Spec:** `docs/superpowers/specs/2026-03-13-ui-polish-fixes.md`

---

## File Structure

### Modify
- `KISE/Sources/Views/Shared/DesignSystem.swift:86-98` — Remove iOS 26 glass branch from `KISECardStyle`
- `KISE/Sources/Views/Registration/CuratedColorPicker.swift` — Replace horizontal scroll with 4-column grid; replace sheet with inline `ColorPicker`
- `KISE/Sources/Views/Registration/RegistrationFlowView.swift:12-67` — Add step transitions

---

## Chunk 1: All Fixes

### Task 1: Remove Liquid Glass from `.kiseCard()`

**Files:**
- Modify: `KISE/Sources/Views/Shared/DesignSystem.swift:86-98`

- [ ] **Step 1: Replace KISECardStyle body**

Replace lines 86-98 of `DesignSystem.swift` (the entire `KISECardStyle` struct) with:

```swift
struct KISECardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(KISEDesign.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: KISEDesign.Radius.md))
            .shadow(color: KISEDesign.Colors.cardShadow, radius: 8, x: 0, y: 2)
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild build -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add KISE/Sources/Views/Shared/DesignSystem.swift
git commit -m "fix: remove Liquid Glass from kiseCard to restore light card aesthetic"
```

---

### Task 2: Redesign CuratedColorPicker as 4-column grid with improved custom picker

**Files:**
- Modify: `KISE/Sources/Views/Registration/CuratedColorPicker.swift`

- [ ] **Step 1: Replace entire CuratedColorPicker.swift**

Replace the full file content with:

```swift
// KISE/Sources/Views/Registration/CuratedColorPicker.swift
import SwiftUI

struct CuratedColorPicker: View {
    let onSelect: (GarmentColor) -> Void
    @State private var showCustomPicker = false
    @State private var customColor: Color = .gray

    private let columns = [
        GridItem(.flexible()), GridItem(.flexible()),
        GridItem(.flexible()), GridItem(.flexible()),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: KISEDesign.Spacing.lg) {
            Text("What color?")
                .font(KISEDesign.Typography.title)
                .foregroundStyle(KISEDesign.Colors.textPrimary)

            LazyVGrid(columns: columns, spacing: KISEDesign.Spacing.md) {
                ForEach(GarmentColor.allColors) { color in
                    Button {
                        onSelect(color)
                    } label: {
                        VStack(spacing: KISEDesign.Spacing.xs) {
                            RoundedRectangle(cornerRadius: KISEDesign.Radius.sm)
                                .fill(color.color)
                                .frame(width: 68, height: 68)
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
                                .frame(width: 68)
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
                            .frame(width: 68, height: 68)
                            .overlay {
                                Image(systemName: "plus")
                                    .font(.title3)
                                    .foregroundStyle(KISEDesign.Colors.textTertiary)
                            }
                        Text("Custom")
                            .font(KISEDesign.Typography.small)
                            .foregroundStyle(KISEDesign.Colors.textTertiary)
                            .frame(width: 68)
                    }
                }
            }
        }
        .sheet(isPresented: $showCustomPicker) {
            NavigationStack {
                VStack(spacing: KISEDesign.Spacing.xl) {
                    // Large color preview
                    RoundedRectangle(cornerRadius: KISEDesign.Radius.lg)
                        .fill(customColor)
                        .frame(height: 200)
                        .padding(.horizontal, KISEDesign.Spacing.xl)

                    ColorPicker("Pick a color", selection: $customColor, supportsOpacity: false)
                        .labelsHidden()
                        .scaleEffect(1.5)
                        .padding(KISEDesign.Spacing.xl)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(KISEDesign.Colors.background)
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
            .presentationDetents([.large])
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

Key changes from the original:
- `ScrollView(.horizontal)` + `HStack` → `LazyVGrid` with 4 columns
- Swatch size: 56px → 68px (both `RoundedRectangle` frame and `Text` label `frame(width:)`)
- Custom button retains "+" dashed rectangle with "Custom" label
- Sheet upgraded: `.large` detent, large color preview swatch, scaled-up picker, explicit "Done" to commit
- Sheet background uses `KISEDesign.Colors.background` to match app aesthetic
- Retained: `showCustomPicker` state, `customColor` state, `Color.toHex()` extension

- [ ] **Step 2: Build to verify**

Run: `xcodebuild build -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add KISE/Sources/Views/Registration/CuratedColorPicker.swift
git commit -m "fix: redesign CuratedColorPicker as 4-column grid with inline custom picker"
```

---

### Task 3: Fix registration step transition bleed-through

**Files:**
- Modify: `KISE/Sources/Views/Registration/RegistrationFlowView.swift:12-68`

- [ ] **Step 1: Add transitions to each step case and animation to VStack**

Replace the `VStack` block (lines 12-68, including the closing `}` and `.padding` on line 68) with:

```swift
                VStack {
                    switch viewModel.currentStep {
                    case .category:
                        CategoryPickerView { category in
                            withAnimation { viewModel.selectCategory(category) }
                        }
                        .transition(.opacity)

                    case .color:
                        CuratedColorPicker { color in
                            withAnimation { viewModel.selectColor(color) }
                        }
                        .transition(.opacity)

                    case .fit:
                        OptionPickerStepView(
                            title: "What fit?",
                            options: viewModel.availableFits,
                            labelFor: { $0.displayName },
                            suggested: nil
                        ) { fit in
                            withAnimation { viewModel.selectFit(fit) }
                        }
                        .transition(.opacity)

                    case .material:
                        MaterialPickerStepView(
                            materials: viewModel.availableMaterials
                        ) { material in
                            withAnimation { viewModel.selectMaterial(material) }
                        }
                        .transition(.opacity)

                    case .weight:
                        OptionPickerStepView(
                            title: "Fabric weight?",
                            options: FabricWeight.allCases,
                            labelFor: { $0.displayName },
                            suggested: viewModel.selectedWeight
                        ) { weight in
                            withAnimation { viewModel.selectWeight(weight) }
                        }
                        .transition(.opacity)

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
                        .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: viewModel.currentStep)
                .padding(KISEDesign.Spacing.md)
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild build -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Run all tests**

Run: `xcodebuild test -project KISE.xcodeproj -scheme KISE -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -30`
Expected: All tests pass

- [ ] **Step 4: Commit**

```bash
git add KISE/Sources/Views/Registration/RegistrationFlowView.swift
git commit -m "fix: add opacity transitions to registration step switches"
```
