// KISE/Sources/ViewModels/WardrobeViewModel.swift
import SwiftUI
import SwiftData

@Observable
final class WardrobeViewModel {
    var selectedTab: TabGroup? = nil // nil = "All"
    var showRegistration = false
    var selectedPiece: GarmentPiece?

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
            return colorA.hueSortValue < colorB.hueSortValue
        }
    }

    func activePieceCount(_ pieces: [GarmentPiece]) -> Int {
        pieces.filter(\.isActive).count
    }

    static func archivePiece(_ piece: GarmentPiece) {
        piece.isActive = false
    }

    static func restorePiece(_ piece: GarmentPiece) {
        piece.isActive = true
    }
}
