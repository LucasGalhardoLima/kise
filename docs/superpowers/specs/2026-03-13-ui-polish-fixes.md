# UI Polish Fixes — TestFlight Feedback

## Summary

Address four UI issues discovered during TestFlight testing: Liquid Glass color clash on cards, cramped horizontal color picker, tiny custom color picker sheet, and step transition bleed-through in the registration flow.

## Issues & Fixes

### 1. Remove Liquid Glass from `.kiseCard()`

**Problem:** The `KISECardStyle` ViewModifier applies `.glassEffect(.regular.interactive())` on iOS 26+, rendering cards as dark frosted glass. This clashes with the light off-white aesthetic — category cards, option pickers, and controls all appear as dark gray blocks.

**Fix:** Remove the iOS 26 `glassEffect` branch from `KISECardStyle`. All cards use the existing fallback: white background (`KISEDesign.Colors.surface`), rounded corners (`KISEDesign.Radius.md`), and subtle shadow. The native `TabView` retains Liquid Glass automatically — no changes needed there.

**Scope:** Modify `KISECardStyle` in `KISE/Sources/Views/Shared/DesignSystem.swift`. Remove the `#available(iOS 26, *)` branch. Keep the else branch as the sole implementation.

### 2. CuratedColorPicker: 4-column grid layout

**Problem:** The `CuratedColorPicker` uses a horizontal `ScrollView` with 56px swatches. Only ~5 of 15 colors are visible; the rest require scrolling right. This hides most options and wastes vertical space.

**Fix:** Replace `ScrollView(.horizontal)` + `HStack` with a `LazyVGrid` using 4 flexible columns. Increase swatch size from 56px to 68px. All 15 curated colors plus the "+" custom button (16 cells total) display in 4 rows without scrolling.

**Scope:** Modify `KISE/Sources/Views/Registration/CuratedColorPicker.swift`. Replace the scroll layout with a grid. Update swatch frame sizes from 56 to 68. Keep the same visual styling (rounded rectangle, border for near-white, color name label).

### 3. Custom color: inline native picker

**Problem:** The custom color picker opens in a `.presentationDetents([.medium])` sheet containing only a `ColorPicker` control. The native picker renders as a tiny circle in a large dark half-sheet — hard to use and aesthetically jarring.

**Fix:** Replace the sheet-based approach with an inline `ColorPicker`. The "+" grid cell becomes a `ColorPicker` with a custom label (the dashed rectangle + "Custom" text). Tapping opens the native iOS color picker popover directly. On color selection, convert to hex and call `onSelect` with `GarmentColor(customHex:)`. Remove the `showCustomPicker` state and `.sheet` modifier.

**Scope:** Modify `KISE/Sources/Views/Registration/CuratedColorPicker.swift`. Replace the "+" `Button` + `.sheet` with a `ColorPicker` using a custom label. Add an `.onChange` handler that converts the selected color to hex and invokes `onSelect`.

### 4. Fix registration step transition bleed-through

**Problem:** During step transitions in the registration flow, the previous step's content (e.g., color picker row) remains visible behind the current step (e.g., fit options). This is caused by SwiftUI's default animation behavior when switching views inside a `ScrollView` + `VStack` with `withAnimation`.

**Fix:** Add `.transition(.opacity)` to each step case in the `RegistrationFlowView` switch statement. Wrap the switch in a container with `.animation(.easeInOut(duration: 0.2), value: viewModel.currentStep)` so transitions are clean opacity crossfades.

**Scope:** Modify `KISE/Sources/Views/Registration/RegistrationFlowView.swift`. Add transitions to each case and animation to the container.

## Architecture

No model or data changes. All fixes are view-layer only:
- `DesignSystem.swift` — card modifier
- `CuratedColorPicker.swift` — layout and custom picker
- `RegistrationFlowView.swift` — step transitions

## Out of Scope

- Matcha theme (separate project)
- Tab bar customization (native Liquid Glass stays)
- Color composition view changes (working well per screenshots)
