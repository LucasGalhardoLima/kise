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

    func testAllColorsHaveAssetKey() {
        for color in GarmentColor.allColors {
            XCTAssertFalse(color.assetKey.isEmpty, "\(color.name) should have an asset key")
            XCTAssertFalse(color.assetKey.contains(" "), "\(color.name) asset key should not have spaces")
        }
    }

    func testColorLookupByName() {
        let navy = GarmentColor.byName("navy")
        XCTAssertNotNil(navy)
        XCTAssertEqual(navy?.hex, "#1B2A4A")
    }

    func testColorCount() {
        XCTAssertEqual(GarmentColor.allColors.count, 15)
    }
}
