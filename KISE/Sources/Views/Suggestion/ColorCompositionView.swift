// KISE/Sources/Views/Suggestion/ColorCompositionView.swift
import SwiftUI

struct ColorCompositionView: View {
    @Environment(ThemeProvider.self) private var theme
    let pieces: [GarmentPiece]
    var swappablePieceID: String?
    var onSwap: (() -> Void)?
    @State private var selectedPieceID: UUID?

    private var sortedPieces: [GarmentPiece] {
        pieces.sorted { a, b in
            CompositionLayout.sizePriority(for: a.category) > CompositionLayout.sizePriority(for: b.category)
        }
    }

    private var layout: CompositionLayout {
        CompositionLayout.pick(for: pieces.map(\.id))
    }

    var body: some View {
        VStack(spacing: KISEDesign.Spacing.md) {
            // Composition
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let paired = Array(zip(sortedPieces, layout.blocks))

                ZStack {
                    ForEach(Array(paired.enumerated()), id: \.offset) { index, pair in
                        let (piece, block) = pair
                        let isSelected = selectedPieceID == piece.id

                        Rectangle()
                            .fill(Color(hex: piece.colorHex))
                            .frame(
                                width: block.relativeWidth * w,
                                height: block.relativeHeight * h
                            )
                            .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
                            .scaleEffect(isSelected ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: isSelected)
                            .position(
                                x: (block.relativeX + block.relativeWidth / 2) * w,
                                y: (block.relativeY + block.relativeHeight / 2) * h
                            )
                            .zIndex(isSelected ? 10 : Double(index))
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedPieceID = selectedPieceID == piece.id ? nil : piece.id
                                }
                            }
                            .accessibilityLabel(
                                pieceLabel(
                                    color: GarmentColor.resolve(color: piece.color, hex: piece.colorHex).name,
                                    category: piece.category.displayName
                                )
                            )
                    }
                }
            }
            .aspectRatio(4 / 3, contentMode: .fit)
            .padding(.horizontal, KISEDesign.Spacing.md)

            // Labels
            Text(labelText)
                .font(KISEDesign.Typography.small)
                .foregroundStyle(theme.colors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Floating detail card
            if let selectedID = selectedPieceID,
               let piece = pieces.first(where: { $0.id == selectedID }) {
                HStack {
                    VStack(alignment: .leading, spacing: KISEDesign.Spacing.xs) {
                        Text(piece.category.displayName)
                            .font(KISEDesign.Typography.subtitle)
                            .foregroundStyle(theme.colors.textPrimary)
                        HStack(spacing: KISEDesign.Spacing.md) {
                            detailLabel(String(localized: "detail.fit"), piece.fit.displayName)
                            detailLabel(String(localized: "detail.material"), materialDisplayName(piece.material))
                            detailLabel(String(localized: "detail.formality"), piece.formality.displayName)
                        }
                    }

                    Spacer()

                    // Swap button if this piece has an alternative
                    if swappablePieceID == piece.id.uuidString, let onSwap {
                        Button(action: onSwap) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.body)
                                .foregroundStyle(theme.colors.accent)
                                .padding(KISEDesign.Spacing.sm)
                        }
                    }
                }
                .padding(KISEDesign.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .kiseCard()
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var labelText: String {
        sortedPieces.map { piece in
            let color = GarmentColor.resolve(color: piece.color, hex: piece.colorHex)
            return pieceLabel(color: color.name, category: piece.category.displayName)
        }.joined(separator: " · ")
    }

    private func detailLabel(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(theme.colors.textTertiary)
            Text(value)
                .font(KISEDesign.Typography.caption)
                .foregroundStyle(theme.colors.textSecondary)
        }
    }
}
