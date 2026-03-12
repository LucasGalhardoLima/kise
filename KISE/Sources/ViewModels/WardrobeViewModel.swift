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
        guard let tab = selectedTab else { return active }
        return active.filter { $0.category.tabGroup == tab }
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
