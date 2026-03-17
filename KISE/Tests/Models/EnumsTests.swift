// KISE/Tests/Models/EnumsTests.swift
import XCTest
@testable import KISE

final class EnumsTests: XCTestCase {

    func testGarmentCategoryDisplayName() {
        XCTAssertEqual(GarmentCategory.tShirt.displayName, String(localized: "category.tShirt"))
        XCTAssertEqual(GarmentCategory.tShirt.rawValue, "tShirt")  // verify raw value
    }

    func testGarmentCategoryTabGroup() {
        XCTAssertEqual(GarmentCategory.tShirt.tabGroup, .tops)
        XCTAssertEqual(GarmentCategory.jeans.tabGroup, .bottoms)
        XCTAssertEqual(GarmentCategory.jacket.tabGroup, .outerwear)
        XCTAssertEqual(GarmentCategory.shoes.tabGroup, .shoes)
    }

    func testFitAvailabilityByCategory() {
        let jeansFits = GarmentCategory.jeans.availableFits
        XCTAssertTrue(jeansFits.contains(.straight))
        XCTAssertTrue(jeansFits.contains(.slim))

        let tshirtFits = GarmentCategory.tShirt.availableFits
        XCTAssertFalse(tshirtFits.contains(.straight))
        XCTAssertTrue(tshirtFits.contains(.oversized))
    }

    func testMaterialAvailabilityByCategory() {
        let jeansMaterials = GarmentCategory.jeans.availableMaterials
        XCTAssertTrue(jeansMaterials.contains("denim"))
        XCTAssertFalse(jeansMaterials.contains("wool"))

        let sweaterMaterials = GarmentCategory.sweater.availableMaterials
        XCTAssertTrue(sweaterMaterials.contains("wool"))
        XCTAssertFalse(sweaterMaterials.contains("denim"))
    }

    func testStyleArchetypeAssetKey() {
        XCTAssertEqual(StyleArchetype.oldMoney.assetKey, "old-money")
        XCTAssertEqual(StyleArchetype.smartCasual.assetKey, "smart-casual")
    }

    func testOccasionDisplayName() {
        XCTAssertEqual(Occasion.everyday.displayName, String(localized: "occasion.everyday"))
        XCTAssertEqual(Occasion.dateNight.displayName, String(localized: "occasion.dateNight"))
    }
}
