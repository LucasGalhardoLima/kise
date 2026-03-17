// KISE/Tests/Models/GarmentColorTests.swift
import XCTest
@testable import KISE

final class GarmentColorTests: XCTestCase {

    func testAllColorsHaveValidHex() {
        for color in GarmentColor.allColors {
            XCTAssertTrue(color.hex.hasPrefix("#"), "\(color.name) hex should start with #")
            XCTAssertEqual(color.hex.count, 7, "\(color.name) hex should be 7 chars")
        }
    }

    func testCuratedColorsAreNotCustom() {
        for color in GarmentColor.allColors {
            XCTAssertFalse(color.isCustom, "\(color.name) should not be custom")
        }
    }

    func testColorLookupByName() {
        let navy = GarmentColor.byName("navy")
        XCTAssertNotNil(navy)
        XCTAssertEqual(navy?.hex, "#1B2A4A")
    }

    func testColorCount() {
        XCTAssertEqual(GarmentColor.allColors.count, 22)
    }

    func testNearestCuratedForExactMatch() {
        let nearest = GarmentColor.nearestCurated(hex: "#1B2A4A")
        XCTAssertEqual(nearest.id, "navy")
    }

    func testNearestCuratedForCloseMatch() {
        let nearest = GarmentColor.nearestCurated(hex: "#1C2B4B")
        XCTAssertEqual(nearest.id, "navy")
    }

    func testCustomColorInit() {
        let custom = GarmentColor(customHex: "#FF6B35")
        XCTAssertTrue(custom.isCustom)
        XCTAssertEqual(custom.hex, "#FF6B35")
        XCTAssertEqual(custom.id, "custom-FF6B35")
        XCTAssertEqual(custom.name, String(localized: "color.custom"))
    }

    func testCustomColorNaming() {
        let custom = GarmentColor(customHex: "#FF0000")
        XCTAssertEqual(custom.name, String(localized: "color.custom"))
        XCTAssertEqual(custom.id, "custom-FF0000")
    }

    func testResolveBackwardCompatibility() {
        let legacy = GarmentColor.resolve(color: "custom", hex: "#FF6B35")
        XCTAssertTrue(legacy.isCustom)
        XCTAssertEqual(legacy.id, "custom-FF6B35")

        let newFormat = GarmentColor.resolve(color: "custom-FF6B35", hex: "#FF6B35")
        XCTAssertTrue(newFormat.isCustom)
        XCTAssertEqual(newFormat.id, "custom-FF6B35")

        let curated = GarmentColor.resolve(color: "navy", hex: "#1B2A4A")
        XCTAssertFalse(curated.isCustom)
        XCTAssertEqual(curated.id, "navy")
    }

    func testLightnessFirstSortOrder() {
        let white = GarmentColor.allColors.first { $0.id == "white" }!
        let black = GarmentColor.allColors.first { $0.id == "black" }!
        let navy = GarmentColor.allColors.first { $0.id == "navy" }!
        XCTAssertLessThan(white.lightnessFirstSortValue, black.lightnessFirstSortValue)
        XCTAssertLessThan(white.lightnessFirstSortValue, navy.lightnessFirstSortValue)
    }

    func testHueSortValue() {
        let white = GarmentColor.allColors.first { $0.id == "white" }!
        let navy = GarmentColor.allColors.first { $0.id == "navy" }!
        XCTAssertGreaterThan(white.hueSortValue, navy.hueSortValue)
    }
}
