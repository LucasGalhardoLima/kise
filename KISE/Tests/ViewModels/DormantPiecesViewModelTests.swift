// KISE/Tests/ViewModels/DormantPiecesViewModelTests.swift
import XCTest
import SwiftData
@testable import KISE

final class DormantPiecesViewModelTests: XCTestCase {

    private var container: ModelContainer!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(
            for: StyleProfile.self, GarmentPiece.self, OutfitSuggestion.self, Feedback.self,
            configurations: config
        )
    }

    @MainActor
    func testFiltersOnly30PlusDays() {
        let recent = GarmentPiece(category: .tShirt, color: "white", colorHex: "#FFF", fit: .slim, material: "cotton", weight: .light, formality: .casual)
        let old = GarmentPiece(category: .jeans, color: "blue", colorHex: "#00F", fit: .straight, material: "denim", weight: .mid, formality: .casual)

        let recentSuggestion = OutfitSuggestion(pieceIDs: [recent.id], occasion: .everyday, weather: nil, reasoning: "test")
        recentSuggestion.suggestedAt = Calendar.current.date(byAdding: .day, value: -5, to: Date())!

        let oldSuggestion = OutfitSuggestion(pieceIDs: [old.id], occasion: .everyday, weather: nil, reasoning: "test")
        oldSuggestion.suggestedAt = Calendar.current.date(byAdding: .day, value: -45, to: Date())!

        let vm = DormantPiecesViewModel()
        let result = vm.unusedPieces(pieces: [recent, old], suggestions: [recentSuggestion, oldSuggestion])

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.piece.id, old.id)
        XCTAssertEqual(result.first?.daysUnused, 45)
    }

    @MainActor
    func testKeepRemovesFromList() {
        let piece = GarmentPiece(category: .tShirt, color: "white", colorHex: "#FFF", fit: .slim, material: "cotton", weight: .light, formality: .casual)
        let suggestion = OutfitSuggestion(pieceIDs: [piece.id], occasion: .everyday, weather: nil, reasoning: "test")
        suggestion.suggestedAt = Calendar.current.date(byAdding: .day, value: -90, to: Date())!

        let vm = DormantPiecesViewModel()
        XCTAssertEqual(vm.unusedPieces(pieces: [piece], suggestions: [suggestion]).count, 1)

        vm.keep(piece)
        XCTAssertEqual(vm.unusedPieces(pieces: [piece], suggestions: [suggestion]).count, 0)
        XCTAssertTrue(piece.isActive, "Keep should NOT archive the piece")
    }

    @MainActor
    func testArchiveSetsInactive() {
        let piece = GarmentPiece(category: .tShirt, color: "white", colorHex: "#FFF", fit: .slim, material: "cotton", weight: .light, formality: .casual)
        XCTAssertTrue(piece.isActive)

        let vm = DormantPiecesViewModel()
        vm.archive(piece)
        XCTAssertFalse(piece.isActive)
    }
}
