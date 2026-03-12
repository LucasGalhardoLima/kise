// KISE/Tests/Models/CompositionLayoutTests.swift
import XCTest
@testable import KISE

final class CompositionLayoutTests: XCTestCase {

    func testTemplatesExistForAllPieceCounts() {
        for count in 2...5 {
            let templates = CompositionLayout.templates(for: count)
            XCTAssertFalse(templates.isEmpty, "Should have templates for \(count) pieces")
            for template in templates {
                XCTAssertEqual(template.blocks.count, count, "Template for \(count) should have \(count) blocks")
            }
        }
    }

    func testBlocksHaveValidRelativeCoordinates() {
        for count in 2...5 {
            for template in CompositionLayout.templates(for: count) {
                for block in template.blocks {
                    XCTAssertTrue(block.relativeX >= 0 && block.relativeX <= 1)
                    XCTAssertTrue(block.relativeY >= 0 && block.relativeY <= 1)
                    XCTAssertTrue(block.relativeWidth > 0 && block.relativeWidth <= 1)
                    XCTAssertTrue(block.relativeHeight > 0 && block.relativeHeight <= 1)
                }
            }
        }
    }

    func testPickIsDeterministic() {
        let ids = [UUID(), UUID(), UUID()]
        let layout1 = CompositionLayout.pick(for: ids)
        let layout2 = CompositionLayout.pick(for: ids)
        XCTAssertEqual(layout1.blocks.count, layout2.blocks.count)
        for (a, b) in zip(layout1.blocks, layout2.blocks) {
            XCTAssertEqual(a.relativeX, b.relativeX)
            XCTAssertEqual(a.relativeY, b.relativeY)
        }
    }

    func testPickVariesByInput() {
        let ids1 = [UUID(), UUID(), UUID()]
        let ids2 = [UUID(), UUID(), UUID()]
        let layout1 = CompositionLayout.pick(for: ids1)
        let layout2 = CompositionLayout.pick(for: ids2)
        XCTAssertEqual(layout1.blocks.count, 3)
        XCTAssertEqual(layout2.blocks.count, 3)
    }

    func testCategorySizePriority() {
        XCTAssertGreaterThan(
            CompositionLayout.sizePriority(for: .jacket),
            CompositionLayout.sizePriority(for: .shoes)
        )
        XCTAssertGreaterThan(
            CompositionLayout.sizePriority(for: .tShirt),
            CompositionLayout.sizePriority(for: .shoes)
        )
    }

    func testFallbackForOutOfRangePieceCount() {
        let templates = CompositionLayout.templates(for: 1)
        XCTAssertFalse(templates.isEmpty)
        XCTAssertEqual(templates[0].blocks.count, 1)

        let capped = CompositionLayout.templates(for: 6)
        XCTAssertFalse(capped.isEmpty)
        XCTAssertEqual(capped[0].blocks.count, 5)
    }
}
