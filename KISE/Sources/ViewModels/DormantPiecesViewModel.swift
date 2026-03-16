// KISE/Sources/ViewModels/DormantPiecesViewModel.swift
import SwiftUI
import SwiftData

struct DormantPieceInfo: Identifiable {
    let piece: GarmentPiece
    let daysUnused: Int
    var id: UUID { piece.id }
}

@Observable
final class DormantPiecesViewModel {
    private var dismissedIDs: Set<UUID> = []

    func unusedPieces(pieces: [GarmentPiece], suggestions: [OutfitSuggestion]) -> [DormantPieceInfo] {
        let lookup = buildLastUsedLookup(suggestions)
        let now = Date()

        return pieces
            .filter { $0.isActive && !dismissedIDs.contains($0.id) }
            .compactMap { piece in
                let days = self.daysUnused(for: piece, lookup: lookup, now: now)
                guard days >= 30 else { return nil }
                return DormantPieceInfo(piece: piece, daysUnused: days)
            }
            .sorted { $0.daysUnused > $1.daysUnused }
    }

    func keep(_ piece: GarmentPiece) {
        dismissedIDs.insert(piece.id)
    }

    func archive(_ piece: GarmentPiece) {
        piece.isActive = false
    }

    func archiveAll(_ infos: [DormantPieceInfo]) {
        for info in infos {
            info.piece.isActive = false
        }
    }

    private func buildLastUsedLookup(_ suggestions: [OutfitSuggestion]) -> [UUID: Date] {
        var lookup: [UUID: Date] = [:]
        for suggestion in suggestions {
            for pieceID in suggestion.pieceIDs {
                if let existing = lookup[pieceID] {
                    if suggestion.suggestedAt > existing {
                        lookup[pieceID] = suggestion.suggestedAt
                    }
                } else {
                    lookup[pieceID] = suggestion.suggestedAt
                }
            }
        }
        return lookup
    }

    private func daysUnused(for piece: GarmentPiece, lookup: [UUID: Date], now: Date) -> Int {
        let ref = lookup[piece.id] ?? piece.createdAt
        return Calendar.current.dateComponents([.day], from: ref, to: now).day ?? 0
    }
}
