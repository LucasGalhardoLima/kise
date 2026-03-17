// KISE/Tests/ViewModels/WardrobeViewModelTests.swift
import XCTest
import SwiftData
@testable import KISE

final class WardrobeViewModelTests: XCTestCase {

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
    func testFilterByTabGroup() {
        let context = container.mainContext
        let tshirt = GarmentPiece(category: .tShirt, color: "white", colorHex: "#FFF", fit: .slim, material: "cotton", weight: .light, formality: .casual)
        let jeans = GarmentPiece(category: .jeans, color: "blue", colorHex: "#00F", fit: .straight, material: "denim", weight: .mid, formality: .casual)
        context.insert(tshirt)
        context.insert(jeans)

        let vm = WardrobeViewModel()
        vm.selectedTab = .tops
        let filtered = vm.filterPieces([tshirt, jeans])
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.category, .tShirt)
    }

    @MainActor
    func testFilterAll() {
        let tshirt = GarmentPiece(category: .tShirt, color: "white", colorHex: "#FFF", fit: .slim, material: "cotton", weight: .light, formality: .casual)
        let jeans = GarmentPiece(category: .jeans, color: "blue", colorHex: "#00F", fit: .straight, material: "denim", weight: .mid, formality: .casual)

        let vm = WardrobeViewModel()
        vm.selectedTab = nil
        let filtered = vm.filterPieces([tshirt, jeans])
        XCTAssertEqual(filtered.count, 2)
    }

    @MainActor
    func testArchivePiece() {
        let piece = GarmentPiece(category: .tShirt, color: "white", colorHex: "#FFF", fit: .slim, material: "cotton", weight: .light, formality: .casual)
        XCTAssertTrue(piece.isActive)
        WardrobeViewModel.archivePiece(piece)
        XCTAssertFalse(piece.isActive)
    }

    @MainActor
    func testPieceCount() {
        let pieces = [
            GarmentPiece(category: .tShirt, color: "white", colorHex: "#FFF", fit: .slim, material: "cotton", weight: .light, formality: .casual),
            GarmentPiece(category: .jeans, color: "blue", colorHex: "#00F", fit: .straight, material: "denim", weight: .mid, formality: .casual),
            GarmentPiece(category: .jacket, color: "navy", colorHex: "#1B2A4A", fit: .regular, material: "wool", weight: .heavy, formality: .smartCasual),
        ]

        let vm = WardrobeViewModel()
        XCTAssertEqual(vm.activePieceCount(pieces), 3)

        pieces[0].isActive = false
        XCTAssertEqual(vm.activePieceCount(pieces), 2)
    }

    @MainActor
    func testFilterPiecesSortedByHue() {
        let white = GarmentPiece(category: .tShirt, color: "white", colorHex: "#FFFFFF", fit: .slim, material: "cotton", weight: .light, formality: .casual)
        let navy = GarmentPiece(category: .tShirt, color: "navy", colorHex: "#1B2A4A", fit: .regular, material: "cotton", weight: .mid, formality: .smartCasual)

        let vm = WardrobeViewModel()
        vm.selectedTab = .tops
        let sorted = vm.filterPieces([white, navy])
        XCTAssertEqual(sorted.first?.color, "navy", "Chromatic colors should sort before neutrals")
    }

    @MainActor
    func testComputeStatsCategorizesCorrectly() {
        let context = container.mainContext

        let piece1 = GarmentPiece(category: .tShirt, color: "white", colorHex: "#FFF", fit: .slim, material: "cotton", weight: .light, formality: .casual)
        let piece2 = GarmentPiece(category: .jeans, color: "blue", colorHex: "#00F", fit: .straight, material: "denim", weight: .mid, formality: .casual)
        let piece3 = GarmentPiece(category: .jacket, color: "green", colorHex: "#0F0", fit: .regular, material: "wool", weight: .heavy, formality: .smartCasual)
        context.insert(piece1)
        context.insert(piece2)
        context.insert(piece3)

        // piece1: suggested 5 days ago → in rotation
        let recent = OutfitSuggestion(
            pieceIDs: [piece1.id],
            occasion: .everyday,
            weather: nil,
            reasoning: "test"
        )
        recent.suggestedAt = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        context.insert(recent)

        // piece2: suggested 45 days ago → rarely used
        let older = OutfitSuggestion(
            pieceIDs: [piece2.id],
            occasion: .everyday,
            weather: nil,
            reasoning: "test"
        )
        older.suggestedAt = Calendar.current.date(byAdding: .day, value: -45, to: Date())!
        context.insert(older)

        // piece3: never suggested, created now → in rotation (0 days)
        let vm = WardrobeViewModel()
        vm.computeStats(pieces: [piece1, piece2, piece3], suggestions: [recent, older])

        XCTAssertEqual(vm.inRotationCount, 2) // piece1 + piece3
        XCTAssertEqual(vm.rarelyUsedCount, 1) // piece2
        XCTAssertEqual(vm.dormantCount, 0)
    }

    @MainActor
    func testLastUsedTextFormatting() {
        let piece = GarmentPiece(category: .tShirt, color: "white", colorHex: "#FFF", fit: .slim, material: "cotton", weight: .light, formality: .casual)

        let suggestion = OutfitSuggestion(
            pieceIDs: [piece.id],
            occasion: .everyday,
            weather: nil,
            reasoning: "test"
        )
        suggestion.suggestedAt = Calendar.current.date(byAdding: .day, value: -3, to: Date())!

        let vm = WardrobeViewModel()
        vm.computeStats(pieces: [piece], suggestions: [suggestion])

        XCTAssertEqual(vm.lastUsedText(for: piece.id), "3" + String(localized: "lastUsed.daysShort"))
    }

    @MainActor
    func testLastUsedTextNewPiece() {
        let vm = WardrobeViewModel()
        vm.computeStats(pieces: [], suggestions: [])
        XCTAssertEqual(vm.lastUsedText(for: UUID()), String(localized: "lastUsed.new"))
    }
}
