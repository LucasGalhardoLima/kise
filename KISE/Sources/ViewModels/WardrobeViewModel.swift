// KISE/Sources/ViewModels/WardrobeViewModel.swift
import SwiftUI
import SwiftData

@Observable
final class WardrobeViewModel {
    var selectedTab: TabGroup? = nil // nil = "All"
    var showRegistration = false
    var selectedPiece: GarmentPiece?
    var showDormantPieces = false

    // Stats
    private(set) var inRotationCount = 0
    private(set) var rarelyUsedCount = 0
    private(set) var dormantCount = 0
    private(set) var lastUsedLookup: [UUID: Date] = [:]

    func filterPieces(_ pieces: [GarmentPiece]) -> [GarmentPiece] {
        let active = pieces.filter(\.isActive)
        let filtered: [GarmentPiece]
        if let tab = selectedTab {
            filtered = active.filter { $0.category.tabGroup == tab }
        } else {
            filtered = active
        }
        return filtered.sorted { a, b in
            let colorA = GarmentColor.resolve(color: a.color, hex: a.colorHex)
            let colorB = GarmentColor.resolve(color: b.color, hex: b.colorHex)
            if selectedTab == nil {
                // "All" tab: lightness-first (white → black)
                return colorA.lightnessFirstSortValue < colorB.lightnessFirstSortValue
            } else {
                // Category tabs: hue-based sort
                return colorA.hueSortValue < colorB.hueSortValue
            }
        }
    }

    func activePieceCount(_ pieces: [GarmentPiece]) -> Int {
        pieces.filter(\.isActive).count
    }

    func computeStats(pieces: [GarmentPiece], suggestions: [OutfitSuggestion]) {
        // Build last-used lookup: most recent suggestion date per piece
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
        lastUsedLookup = lookup

        var inRotation = 0
        var rarelyUsed = 0
        var dormant = 0

        for piece in pieces where piece.isActive {
            let days = daysUnused(for: piece)
            if days < 30 {
                inRotation += 1
            } else if days < 60 {
                rarelyUsed += 1
            } else {
                dormant += 1
            }
        }

        inRotationCount = inRotation
        rarelyUsedCount = rarelyUsed
        dormantCount = dormant
    }

    func daysUnused(for piece: GarmentPiece) -> Int {
        let referenceDate = lastUsedLookup[piece.id] ?? piece.createdAt
        return Calendar.current.dateComponents([.day], from: referenceDate, to: Date()).day ?? 0
    }

    func lastUsedText(for pieceID: UUID) -> String {
        guard let lastUsed = lastUsedLookup[pieceID] else {
            return String(localized: "lastUsed.new")
        }
        let days = Calendar.current.dateComponents([.day], from: lastUsed, to: Date()).day ?? 0
        if days == 0 { return String(localized: "lastUsed.today") }
        if days < 7 { return "\(days)" + String(localized: "lastUsed.daysShort") }
        if days < 30 { return "\(days / 7)" + String(localized: "lastUsed.weeksShort") }
        return "\(days / 30)" + String(localized: "lastUsed.monthsShort")
    }

    static func archivePiece(_ piece: GarmentPiece) {
        piece.isActive = false
    }

    static func restorePiece(_ piece: GarmentPiece) {
        piece.isActive = true
    }
}
