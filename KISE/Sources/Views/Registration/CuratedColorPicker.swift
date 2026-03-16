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
                            let dictionaryName = ColorDictionary.nearestName(for: hex)
                            let hexClean = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
                            let garmentColor = GarmentColor(
                                id: "custom-\(hexClean)",
                                name: dictionaryName,
                                hex: hex,
                                isCustom: true
                            )
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
