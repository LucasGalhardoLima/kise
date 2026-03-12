// KISE/Tests/Models/GarmentPieceTests.swift
import XCTest
import SwiftData
@testable import KISE

final class GarmentPieceTests: XCTestCase {

    private var container: ModelContainer!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(
            for: StyleProfile.self, GarmentPiece.self, OutfitSuggestion.self,
            configurations: config
        )
    }

    override func tearDown() {
        container = nil
        super.tearDown()
    }

    @MainActor
    func testCreateGarmentPiece() {
        let context = container.mainContext
        let piece = GarmentPiece(
            category: .tShirt,
            color: "white",
            colorHex: "#FFFFFF",
            fit: .slim,
            material: "cotton",
            weight: .light,
            formality: .casual
        )
        context.insert(piece)
        try! context.save()

        let fetched = try! context.fetch(FetchDescriptor<GarmentPiece>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.category, .tShirt)
        XCTAssertEqual(fetched.first?.color, "white")
        XCTAssertTrue(fetched.first?.isActive ?? false)
    }

    @MainActor
    func testCatalogImageID() {
        let piece = GarmentPiece(
            category: .jeans,
            color: "indigo",
            colorHex: "#3F5277",
            fit: .straight,
            material: "denim",
            weight: .mid,
            formality: .casual
        )
        XCTAssertEqual(piece.catalogImageID, "jeans_indigo_straight")
    }

    @MainActor
    func testArchivePiece() {
        let piece = GarmentPiece(
            category: .jacket,
            color: "navy",
            colorHex: "#1B2A4A",
            fit: .regular,
            material: "wool",
            weight: .heavy,
            formality: .smartCasual
        )
        XCTAssertTrue(piece.isActive)
        piece.isActive = false
        XCTAssertFalse(piece.isActive)
    }

    @MainActor
    func testCreateStyleProfile() {
        let context = container.mainContext
        let profile = StyleProfile(archetypes: [.oldMoney, .minimalist])
        context.insert(profile)
        try! context.save()

        let fetched = try! context.fetch(FetchDescriptor<StyleProfile>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.archetypes, [.oldMoney, .minimalist])
    }
}
