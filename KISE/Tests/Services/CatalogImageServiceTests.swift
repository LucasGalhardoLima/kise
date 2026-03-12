// KISE/Tests/Services/CatalogImageServiceTests.swift
import XCTest
@testable import KISE

final class CatalogImageServiceTests: XCTestCase {

    func testExactMatchKey() {
        let key = CatalogImageService.imageKey(
            category: .tShirt, color: "white", fit: .slim
        )
        XCTAssertEqual(key, "tshirt_white_slim")
    }

    func testKeyWithColorLookup() {
        let key = CatalogImageService.imageKey(
            category: .jeans, color: "Navy", fit: .straight
        )
        XCTAssertEqual(key, "jeans_navy_straight")
    }

    func testFallbackKey() {
        // When exact key has no asset, fall back to default fit
        let fallback = CatalogImageService.fallbackKey(
            category: .polo, color: "terracotta", defaultFit: .regular
        )
        XCTAssertEqual(fallback, "polo_terracotta_regular")
    }
}
