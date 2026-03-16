// KISE/Tests/ViewModels/RegistrationViewModelTests.swift
import XCTest
import SwiftData
@testable import KISE

final class RegistrationViewModelTests: XCTestCase {

    func testInitialStep() {
        let vm = RegistrationViewModel()
        XCTAssertEqual(vm.currentStep, .category)
    }

    func testSelectCategory() {
        let vm = RegistrationViewModel()
        vm.selectCategory(.tShirt)
        XCTAssertEqual(vm.selectedCategory, .tShirt)
        XCTAssertEqual(vm.currentStep, .color)
    }

    func testSelectColor() {
        let vm = RegistrationViewModel()
        vm.selectCategory(.tShirt)
        vm.selectColor(GarmentColor.allColors[0]) // White
        XCTAssertEqual(vm.selectedColor?.name, "White")
        XCTAssertEqual(vm.currentStep, .fit)
    }

    func testAvailableFitsFilteredByCategory() {
        let vm = RegistrationViewModel()
        vm.selectCategory(.jeans)
        XCTAssertTrue(vm.availableFits.contains(.straight))
        XCTAssertFalse(vm.availableFits.contains(.oversized))
    }

    func testAvailableMaterialsFilteredByCategory() {
        let vm = RegistrationViewModel()
        vm.selectCategory(.sweater)
        XCTAssertTrue(vm.availableMaterials.contains("wool"))
        XCTAssertFalse(vm.availableMaterials.contains("denim"))
    }

    func testAutoSuggestedWeight() {
        let vm = RegistrationViewModel()
        vm.selectCategory(.sweater)
        vm.selectColor(GarmentColor.allColors[0])
        vm.selectFit(.regular)
        vm.selectMaterial("wool")
        XCTAssertEqual(vm.selectedWeight, .heavy)
    }

    func testAutoSuggestedFormality() {
        let vm = RegistrationViewModel()
        vm.selectCategory(.tShirt)
        XCTAssertEqual(vm.suggestedFormality, .casual)
    }

    func testFullFlowProducesPiece() {
        let vm = RegistrationViewModel()
        vm.selectCategory(.jeans)
        vm.selectColor(GarmentColor.byName("indigo")!)
        vm.selectFit(.straight)
        vm.selectMaterial("denim")
        vm.selectWeight(.mid)
        vm.selectFormality(.casual)

        let piece = vm.buildPiece()
        XCTAssertNotNil(piece)
        XCTAssertEqual(piece?.category, .jeans)
        XCTAssertEqual(piece?.color, "indigo")
        XCTAssertEqual(piece?.fit, .straight)
    }

    func testGoBack() {
        let vm = RegistrationViewModel()
        vm.selectCategory(.tShirt)
        vm.selectColor(GarmentColor.allColors[0])
        XCTAssertEqual(vm.currentStep, .fit)
        vm.goBack()
        XCTAssertEqual(vm.currentStep, .color)
    }

    func testFormalityIsLastStep() {
        let vm = RegistrationViewModel()
        vm.selectCategory(.jeans)
        vm.selectColor(GarmentColor.byName("indigo")!)
        vm.selectFit(.straight)
        vm.selectMaterial("denim")
        vm.selectWeight(.mid)
        vm.selectFormality(.casual)
        // After formality, step stays at .formality (no .confirm)
        XCTAssertEqual(vm.currentStep, .formality)
    }

    func testReset() {
        let vm = RegistrationViewModel()
        vm.selectCategory(.tShirt)
        vm.selectColor(GarmentColor.allColors[0])
        vm.reset()
        XCTAssertEqual(vm.currentStep, .category)
        XCTAssertNil(vm.selectedCategory)
    }

    // MARK: - Shoe Flow

    func testShoeFlowSkipsFit() {
        let vm = RegistrationViewModel()
        vm.selectCategory(.shoes)
        vm.selectColor(GarmentColor.allColors[0])
        // Should skip .fit and go to .shoeType
        XCTAssertEqual(vm.currentStep, .shoeType)
    }

    func testNonShoeFlowSkipsShoeType() {
        let vm = RegistrationViewModel()
        vm.selectCategory(.tShirt)
        vm.selectColor(GarmentColor.allColors[0])
        // Should go to .fit, not .shoeType
        XCTAssertEqual(vm.currentStep, .fit)
    }

    func testShoeGoBackFromMaterial() {
        let vm = RegistrationViewModel()
        vm.selectCategory(.shoes)
        vm.selectColor(GarmentColor.allColors[0])
        vm.selectShoeType(.sneakers)
        XCTAssertEqual(vm.currentStep, .material)
        vm.goBack()
        // Should go back to .shoeType, not .fit
        XCTAssertEqual(vm.currentStep, .shoeType)
    }

    func testShoeGoBackFromShoeType() {
        let vm = RegistrationViewModel()
        vm.selectCategory(.shoes)
        vm.selectColor(GarmentColor.allColors[0])
        XCTAssertEqual(vm.currentStep, .shoeType)
        vm.goBack()
        XCTAssertEqual(vm.currentStep, .color)
    }

    func testShoeFullFlow() {
        let vm = RegistrationViewModel()
        vm.selectCategory(.shoes)
        vm.selectColor(GarmentColor.byName("black")!)
        vm.selectShoeType(.oxfords)
        vm.selectMaterial("leather")
        vm.selectWeight(.mid)
        vm.selectFormality(.smart)

        let piece = vm.buildPiece()
        XCTAssertNotNil(piece)
        XCTAssertEqual(piece?.category, .shoes)
        XCTAssertEqual(piece?.shoeType, .oxfords)
        XCTAssertEqual(piece?.fit, .regular) // default for shoes
    }

    func testShoeBuildPieceFailsWithoutShoeType() {
        let vm = RegistrationViewModel()
        vm.selectCategory(.shoes)
        vm.selectColor(GarmentColor.allColors[0])
        // Skip shoeType selection
        vm.selectMaterial("leather")
        vm.selectWeight(.mid)
        vm.selectFormality(.casual)

        XCTAssertNil(vm.buildPiece())
    }

    func testResetClearsShoeType() {
        let vm = RegistrationViewModel()
        vm.selectCategory(.shoes)
        vm.selectColor(GarmentColor.allColors[0])
        vm.selectShoeType(.boots)
        vm.reset()
        XCTAssertNil(vm.selectedShoeType)
    }
}
