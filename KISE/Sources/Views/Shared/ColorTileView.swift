// KISE/Sources/Views/Shared/ColorTileView.swift
import SwiftUI

struct ColorTileView: View {
    let colorHex: String
    let colorName: String
    let category: String
    let material: String
    let lastUsedText: String
    let daysUnused: Int?

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
                .overlay(alignment: .topTrailing) {
                    badge
                }
                .accessibilityLabel("\(colorName) \(category)")

            VStack(spacing: 2) {
                Text("\(garmentColor.name) \(category)")
                    .font(KISEDesign.Typography.caption)
                    .foregroundStyle(KISEDesign.Colors.textPrimary)
                    .lineLimit(1)

                Text("\(material.capitalized) · \(lastUsedText)")
                    .font(.system(size: 10))
                    .foregroundStyle(KISEDesign.Colors.textTertiary)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private var badge: some View {
        if let days = daysUnused, days >= 30 {
            let isDormant = days >= 60
            Text("\(days)d")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(isDormant ? KISEDesign.Colors.disliked : KISEDesign.Colors.textTertiary)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(.white.opacity(0.85))
                .clipShape(Capsule())
                .padding(4)
        }
    }
}
