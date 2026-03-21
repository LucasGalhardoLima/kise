// KISE/Sources/Views/Suggestion/DailyPickView.swift
import SwiftUI

struct DailyPickView: View {
    @Environment(ThemeProvider.self) private var theme
    let palette: DailyPalette
    let onShare: () -> Void

    private var layout: CompositionLayout {
        let available = CompositionLayout.templates(for: palette.colors.count)
        guard !available.isEmpty else { return CompositionLayout(blocks: []) }
        let key = palette.colors.joined()
        let index = abs(StableHash.fnv1a(key)) % available.count
        return available[index]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: KISEDesign.Spacing.sm) {
            // Section label
            Text("dailyPick.sectionLabel")
                .kiseSectionLabel()

            // Composition blocks
            compositionBlocks
                .aspectRatio(4 / 3, contentMode: .fit)

            // City + weather
            Text("\(palette.city) · \(palette.temperature)°C · \(palette.condition)")
                .font(KISEDesign.Typography.caption)
                .foregroundStyle(theme.colors.textSecondary)

            // Palette name
            Text(palette.paletteName)
                .font(KISEDesign.Typography.title)
                .foregroundStyle(theme.colors.textPrimary)

            // Hex codes row
            HStack(spacing: KISEDesign.Spacing.sm) {
                ForEach(palette.colors, id: \.self) { hex in
                    Text(hex.uppercased())
                        .font(KISEDesign.Typography.small)
                        .foregroundStyle(theme.colors.textTertiary)
                }
            }

            // Share button
            Button(action: onShare) {
                HStack(spacing: KISEDesign.Spacing.xs) {
                    Image(systemName: "square.and.arrow.up")
                    Text("dailyPick.share")
                }
                .font(KISEDesign.Typography.caption)
                .foregroundStyle(theme.colors.textTertiary)
                .padding(.horizontal, KISEDesign.Spacing.md)
                .padding(.vertical, KISEDesign.Spacing.sm)
                .overlay(
                    Capsule()
                        .strokeBorder(theme.colors.border, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Composition Blocks

    private var compositionBlocks: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let blocks = layout.blocks
            let paired = Array(zip(palette.colors, blocks))

            ZStack {
                ForEach(Array(paired.enumerated()), id: \.offset) { index, pair in
                    let (hex, block) = pair
                    Rectangle()
                        .fill(Color(hex: hex))
                        .frame(
                            width: block.relativeWidth * w,
                            height: block.relativeHeight * h
                        )
                        .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
                        .position(
                            x: (block.relativeX + block.relativeWidth / 2) * w,
                            y: (block.relativeY + block.relativeHeight / 2) * h
                        )
                        .zIndex(Double(index))
                }
            }
        }
    }
}
