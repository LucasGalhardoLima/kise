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
