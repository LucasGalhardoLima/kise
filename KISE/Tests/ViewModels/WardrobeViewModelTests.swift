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
        let navy = GarmentPiece(category: .polo, color: "navy", colorHex: "#1B2A4A", fit: .regular, material: "cotton", weight: .mid, formality: .smartCasual)

        let vm = WardrobeViewModel()
        vm.selectedTab = nil
        let sorted = vm.filterPieces([white, navy])
        XCTAssertEqual(sorted.first?.color, "navy", "Chromatic colors should sort before neutrals")
    }
}
