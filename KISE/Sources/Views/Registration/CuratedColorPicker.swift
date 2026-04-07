// KISE/Sources/Views/Registration/CuratedColorPicker.swift
import SwiftUI

struct CuratedColorPicker: View {
    @Environment(ThemeProvider.self) private var theme
    let onSelect: (GarmentColor) -> Void
    @State private var showHuePicker = false
    @State private var hueValue: Double = 0.0

    private let columns = [
        GridItem(.flexible()), GridItem(.flexible()),
        GridItem(.flexible()), GridItem(.flexible()),
    ]

    /// Auto-derived wearable tone from hue
    private var derivedColor: Color {
        Color(hue: hueValue, saturation: 0.55, brightness: 0.65)
    }

    private var derivedHex: String {
        derivedColor.toHex()
    }

    private var derivedName: String {
        ColorDictionary.nearestName(for: derivedHex)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: KISEDesign.Spacing.lg) {
            Text("registration.whatColor")
                .font(KISEDesign.Typography.title)
                .foregroundStyle(theme.colors.textPrimary)

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
                                            .strokeBorder(theme.colors.border, lineWidth: 1)
                                    }
                                }
                            Text(color.name)
                                .font(KISEDesign.Typography.small)
                                .foregroundStyle(theme.colors.textSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(width: 68)
                        }
                    }
                }

                // Custom color "+" button
                Button {
                    showHuePicker = true
                } label: {
                    VStack(spacing: KISEDesign.Spacing.xs) {
                        RoundedRectangle(cornerRadius: KISEDesign.Radius.sm)
                            .strokeBorder(theme.colors.border, style: StrokeStyle(lineWidth: 1, dash: [4]))
                            .frame(width: 68, height: 68)
                            .overlay {
                                Image(systemName: "plus")
                                    .font(.title3)
                                    .foregroundStyle(theme.colors.textTertiary)
                            }
                        Text("color.custom")
                            .font(KISEDesign.Typography.small)
                            .foregroundStyle(theme.colors.textTertiary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(width: 68)
                    }
                }
            }
        }
        .sheet(isPresented: $showHuePicker) {
            huePickerSheet
                .presentationDetents([.medium])
        }
    }

    // MARK: - Hue Picker Sheet

    private var huePickerSheet: some View {
        NavigationStack {
            VStack(spacing: KISEDesign.Spacing.lg) {
                HueSlider(hue: $hueValue)
                    .frame(height: 36)

                HStack(spacing: KISEDesign.Spacing.md) {
                    RoundedRectangle(cornerRadius: KISEDesign.Radius.sm)
                        .fill(derivedColor)
                        .frame(width: 52, height: 52)
                        .overlay {
                            RoundedRectangle(cornerRadius: KISEDesign.Radius.sm)
                                .strokeBorder(theme.colors.border, lineWidth: 1)
                        }

                    Text(derivedName)
                        .font(KISEDesign.Typography.bodyText)
                        .foregroundStyle(theme.colors.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    Button {
                        let hex = derivedHex
                        let name = derivedName
                        let hexClean = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
                        let garmentColor = GarmentColor(
                            id: "custom-\(hexClean)",
                            name: name,
                            hex: hex,
                            isCustom: true
                        )
                        showHuePicker = false
                        onSelect(garmentColor)
                    } label: {
                        Text("action.done")
                            .font(KISEDesign.Typography.subtitle)
                            .foregroundStyle(theme.colors.background)
                            .padding(.horizontal, KISEDesign.Spacing.lg)
                            .padding(.vertical, KISEDesign.Spacing.sm)
                            .background(theme.colors.accent)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(KISEDesign.Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(theme.colors.background)
            .navigationTitle("registration.customColor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel") {
                        showHuePicker = false
                    }
                }
            }
        }
    }
}

// MARK: - Hue Slider

private struct HueSlider: View {
    @Binding var hue: Double

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .leading) {
                // Rainbow gradient
                LinearGradient(
                    gradient: Gradient(colors: stride(from: 0.0, through: 1.0, by: 0.1).map {
                        Color(hue: $0, saturation: 0.55, brightness: 0.65)
                    }),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .clipShape(Capsule())

                // Thumb
                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    .frame(width: 28, height: 28)
                    .offset(x: hue * (width - 28))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let raw = drag.location.x / width
                        hue = min(max(raw, 0), 1)
                    }
            )
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
