// KISE/Sources/Views/Wardrobe/GarmentDetailView.swift
import SwiftUI
import SwiftData

struct GarmentDetailView: View {
    @Environment(ThemeProvider.self) private var theme
    @Environment(\.dismiss) private var dismiss
    let piece: GarmentPiece

    @Query(sort: \OutfitSuggestion.suggestedAt, order: .reverse)
    private var allSuggestions: [OutfitSuggestion]

    @Query private var allPieces: [GarmentPiece]

    private var garmentColor: GarmentColor {
        GarmentColor.resolve(color: piece.color, hex: piece.colorHex)
    }

    private var pieceLookup: [UUID: GarmentPiece] {
        Dictionary(uniqueKeysWithValues: allPieces.map { ($0.id, $0) })
    }

    private func lastUsedTextFrom(_ suggestions: [OutfitSuggestion]) -> String {
        guard let mostRecent = suggestions.first else { return "—" }
        let days = Calendar.current.dateComponents([.day], from: mostRecent.suggestedAt, to: Date()).day ?? 0
        if days == 0 { return "Today" }
        if days < 7 { return "\(days)d" }
        if days < 30 { return "\(days / 7)w" }
        return "\(days / 30)m"
    }

    var body: some View {
        // Cache expensive filter once per render
        let pieceSuggestions = allSuggestions.filter { $0.pieceIDs.contains(piece.id) }
        let wearCount = pieceSuggestions.filter { $0.feedback?.liked == true }.count
        let combinationsCount = pieceSuggestions.count
        let lastUsed = lastUsedTextFrom(pieceSuggestions)
        let lookup = pieceLookup

        ScrollView {
            VStack(alignment: .leading, spacing: KISEDesign.Spacing.lg) {
                // Hero swatch (16:9)
                RoundedRectangle(cornerRadius: KISEDesign.Radius.md)
                    .fill(Color(hex: piece.colorHex))
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .overlay {
                        if garmentColor.needsBorder {
                            RoundedRectangle(cornerRadius: KISEDesign.Radius.md)
                                .strokeBorder(theme.colors.border, lineWidth: 1)
                        }
                    }

                // Title — auto-generated name
                Text("\(piece.fit.displayName) \(garmentColor.name) \(piece.category.displayName)")
                    .font(KISEDesign.Typography.title)
                    .foregroundStyle(theme.colors.textPrimary)

                // Inline subtitle
                Text("\(piece.material.capitalized) · \(garmentColor.name) · \(piece.fit.displayName)")
                    .font(KISEDesign.Typography.bodyText)
                    .foregroundStyle(theme.colors.textSecondary)

                // Usage stats
                StatsRowView(items: [
                    StatItem(count: wearCount, label: "Times Worn"),
                    StatItem(count: combinationsCount, label: "Combinations"),
                    StatItem(count: 0, label: "Last Used", displayValue: lastUsed),
                ])

                // Pairs With
                if !pieceSuggestions.isEmpty {
                    pairsWithSection(pieceSuggestions, lookup: lookup)
                }
            }
            .padding(KISEDesign.Spacing.md)
        }
        .background(theme.colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(piece.category.displayName)
                    .font(KISEDesign.Typography.subtitle)
                    .foregroundStyle(theme.colors.textPrimary)
            }
            ToolbarItem(placement: .bottomBar) {
                Button(role: piece.isActive ? .destructive : nil) {
                    if piece.isActive {
                        WardrobeViewModel.archivePiece(piece)
                    } else {
                        WardrobeViewModel.restorePiece(piece)
                    }
                    dismiss()
                } label: {
                    Label(
                        piece.isActive ? "Archive" : "Restore",
                        systemImage: piece.isActive ? "archivebox" : "arrow.uturn.backward"
                    )
                    .font(KISEDesign.Typography.bodyText)
                }
            }
        }
    }

    // MARK: - Pairs With

    private func pairsWithSection(_ pieceSuggestions: [OutfitSuggestion], lookup: [UUID: GarmentPiece]) -> some View {
        VStack(alignment: .leading, spacing: KISEDesign.Spacing.sm) {
            Text("Pairs With")
                .kiseSectionLabel()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: KISEDesign.Spacing.sm) {
                    ForEach(Array(pieceSuggestions.prefix(10)), id: \.id) { suggestion in
                        miniComposition(suggestion, lookup: lookup)
                    }
                }
            }
        }
    }

    private func miniComposition(_ suggestion: OutfitSuggestion, lookup: [UUID: GarmentPiece]) -> some View {
        let pieces = suggestion.pieceIDs.compactMap { lookup[$0] }
        let layout = CompositionLayout.pick(for: suggestion.pieceIDs)
        let sorted = pieces.sorted { a, b in
            CompositionLayout.sizePriority(for: a.category) > CompositionLayout.sizePriority(for: b.category)
        }
        let paired = Array(zip(sorted, layout.blocks))

        return VStack(spacing: KISEDesign.Spacing.xs) {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                ZStack {
                    ForEach(Array(paired.enumerated()), id: \.offset) { _, pair in
                        let (p, block) = pair
                        Rectangle()
                            .fill(Color(hex: p.colorHex))
                            .frame(
                                width: block.relativeWidth * w,
                                height: block.relativeHeight * h
                            )
                            .position(
                                x: (block.relativeX + block.relativeWidth / 2) * w,
                                y: (block.relativeY + block.relativeHeight / 2) * h
                            )
                    }
                }
            }
            .aspectRatio(4 / 3, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: KISEDesign.Radius.sm))

            if let occasion = suggestion.occasion {
                Text(occasion.displayName)
                    .font(KISEDesign.Typography.small)
                    .foregroundStyle(theme.colors.textSecondary)
            }
        }
        .frame(width: 120)
        .kiseCard()
    }
}
