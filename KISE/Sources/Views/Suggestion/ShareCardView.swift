// KISE/Sources/Views/Suggestion/ShareCardView.swift
import SwiftUI

struct ShareCardView: View {
    let data: ShareCardData
    let theme: ThemeColors

    private let cardWidth: CGFloat = 390
    private let cardHeight: CGFloat = 520

    var body: some View {
        VStack(spacing: 0) {
            // Composition — top ~60%
            compositionSection
                .frame(height: cardHeight * 0.6)

            Spacer(minLength: KISEDesign.Spacing.md)

            // Piece names
            Text(data.pieceNamesText)
                .font(KISEDesign.Typography.caption)
                .foregroundStyle(theme.textSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)
                .padding(.horizontal, KISEDesign.Spacing.lg)

            // Weather line
            if let weatherLine = data.weatherLine {
                Text(weatherLine)
                    .font(KISEDesign.Typography.small)
                    .foregroundStyle(theme.textTertiary)
                    .lineLimit(1)
                    .padding(.top, KISEDesign.Spacing.xs)
            }

            Spacer(minLength: KISEDesign.Spacing.md)

            // Brand footer
            brandFooter
                .padding(.horizontal, KISEDesign.Spacing.lg)
                .padding(.bottom, KISEDesign.Spacing.md)
        }
        .frame(width: cardWidth, height: cardHeight)
        .background(theme.background)
        .overlay(
            RoundedRectangle(cornerRadius: KISEDesign.Radius.md)
                .strokeBorder(theme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: KISEDesign.Radius.md))
    }

    // MARK: - Composition Blocks

    private var compositionSection: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let sorted = data.sortedPieces
            let blocks = data.layout.blocks
            let paired = Array(zip(sorted, blocks))

            ZStack {
                ForEach(Array(paired.enumerated()), id: \.offset) { index, pair in
                    let (piece, block) = pair
                    Rectangle()
                        .fill(Color(hex: piece.colorHex))
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
        .padding(.horizontal, KISEDesign.Spacing.lg)
        .padding(.top, KISEDesign.Spacing.md)
    }

    // MARK: - Brand Footer

    private var brandFooter: some View {
        HStack {
            Text(data.tagline)
                .font(KISEDesign.Typography.caption)
                .foregroundStyle(theme.textTertiary)

            Spacer()

            Text(data.brandSignature)
                .font(KISEDesign.Typography.brand(14))
                .foregroundStyle(theme.textSecondary)
        }
    }
}
