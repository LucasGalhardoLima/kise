// KISE/Sources/Views/Suggestion/OutfitPieceCard.swift
import SwiftUI

struct OutfitPieceCard: View {
    let piece: GarmentPiece
    let isSwappable: Bool
    let onSwap: () -> Void

    var body: some View {
        HStack(spacing: KISEDesign.Spacing.md) {
            // Catalog image placeholder
            catalogImage

            // Piece info
            VStack(alignment: .leading, spacing: KISEDesign.Spacing.xs) {
                Text(piece.category.displayName)
                    .font(KISEDesign.Typography.subtitle)
                    .foregroundStyle(KISEDesign.Colors.textPrimary)

                Text("\(piece.color) · \(piece.fit.displayName) · \(piece.material)")
                    .font(KISEDesign.Typography.caption)
                    .foregroundStyle(KISEDesign.Colors.textSecondary)
            }

            Spacer()

            // Swap button if this piece has an alternative
            if isSwappable {
                Button(action: onSwap) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.body)
                        .foregroundStyle(KISEDesign.Colors.accent)
                        .padding(KISEDesign.Spacing.sm)
                }
            }
        }
        .padding(KISEDesign.Spacing.md)
        .kiseCard()
    }

    private var catalogImage: some View {
        Group {
            if let image = UIImage(named: piece.catalogImageID) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // Color swatch fallback
                RoundedRectangle(cornerRadius: KISEDesign.Radius.sm)
                    .fill(Color(hex: piece.colorHex))
                    .overlay(
                        Text(piece.category.displayName.prefix(1))
                            .font(KISEDesign.Typography.heading(20))
                            .foregroundStyle(.white.opacity(0.8))
                    )
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: KISEDesign.Radius.sm))
    }
}
