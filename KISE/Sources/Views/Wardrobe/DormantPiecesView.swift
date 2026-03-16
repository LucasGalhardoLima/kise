// KISE/Sources/Views/Wardrobe/DormantPiecesView.swift
import SwiftUI
import SwiftData

struct DormantPiecesView: View {
    @Environment(ThemeProvider.self) private var theme
    @Query(filter: #Predicate<GarmentPiece> { $0.isActive })
    private var pieces: [GarmentPiece]

    @Query(sort: \OutfitSuggestion.suggestedAt, order: .reverse)
    private var suggestions: [OutfitSuggestion]

    @State private var viewModel = DormantPiecesViewModel()

    var body: some View {
        let unusedPieces = viewModel.unusedPieces(pieces: pieces, suggestions: suggestions)

        ScrollView {
            VStack(alignment: .leading, spacing: KISEDesign.Spacing.md) {
                // Header
                HStack(alignment: .firstTextBaseline) {
                    Text("Unused Recently")
                        .font(KISEDesign.Typography.largeTitle)
                        .foregroundStyle(theme.colors.textPrimary)
                    Spacer()
                    Text("\(unusedPieces.count) pieces")
                        .font(KISEDesign.Typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                        .padding(.horizontal, KISEDesign.Spacing.sm)
                        .padding(.vertical, KISEDesign.Spacing.xs)
                        .background(theme.colors.surface)
                        .clipShape(Capsule())
                }

                Text("These pieces haven't been used in over 30 days. Do they still belong in your wardrobe?")
                    .font(KISEDesign.Typography.bodyText)
                    .foregroundStyle(theme.colors.textSecondary)

                // Piece list
                LazyVStack(spacing: 0) {
                    ForEach(unusedPieces) { info in
                        pieceRow(info)
                        if info.id != unusedPieces.last?.id {
                            Divider()
                        }
                    }
                }

                // Bulk action
                if !unusedPieces.isEmpty {
                    Button {
                        withAnimation {
                            viewModel.archiveAll(unusedPieces)
                        }
                    } label: {
                        Text("Archive all dormant")
                            .font(KISEDesign.Typography.bodyText)
                            .foregroundStyle(theme.colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, KISEDesign.Spacing.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: KISEDesign.Radius.md)
                                    .strokeBorder(theme.colors.accentMuted, lineWidth: 1)
                            )
                    }
                    .padding(.top, KISEDesign.Spacing.md)
                }
            }
            .padding(KISEDesign.Spacing.md)
        }
        .background(theme.colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private func pieceRow(_ info: DormantPieceInfo) -> some View {
        let garmentColor = GarmentColor.resolve(color: info.piece.color, hex: info.piece.colorHex)

        return HStack(spacing: KISEDesign.Spacing.md) {
            // Color swatch
            RoundedRectangle(cornerRadius: KISEDesign.Radius.sm)
                .fill(Color(hex: info.piece.colorHex))
                .frame(width: 56, height: 56)
                .overlay {
                    if garmentColor.needsBorder {
                        RoundedRectangle(cornerRadius: KISEDesign.Radius.sm)
                            .strokeBorder(theme.colors.border, lineWidth: 1)
                    }
                }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text("\(garmentColor.name) \(info.piece.category.displayName)")
                    .font(KISEDesign.Typography.subtitle)
                    .foregroundStyle(theme.colors.textPrimary)
                Text("Unused for \(info.daysUnused) days")
                    .font(KISEDesign.Typography.caption)
                    .foregroundStyle(theme.colors.disliked)
                Text("\(info.piece.material.capitalized) · \(garmentColor.name)")
                    .font(KISEDesign.Typography.caption)
                    .foregroundStyle(theme.colors.textTertiary)
            }

            Spacer()

            // Actions
            VStack(spacing: KISEDesign.Spacing.xs) {
                Button {
                    withAnimation { viewModel.keep(info.piece) }
                } label: {
                    Text("Keep")
                        .font(KISEDesign.Typography.caption)
                        .foregroundStyle(theme.colors.accent)
                }

                Button {
                    withAnimation { viewModel.archive(info.piece) }
                } label: {
                    Text("Remove")
                        .font(KISEDesign.Typography.caption)
                        .foregroundStyle(theme.colors.disliked)
                }
            }
        }
        .padding(.vertical, KISEDesign.Spacing.sm)
    }
}
