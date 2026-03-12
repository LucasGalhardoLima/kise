// KISE/Tests/ViewModels/OnboardingViewModelTests.swift
import XCTest
import SwiftData
@testable import KISE

final class OnboardingViewModelTests: XCTestCase {

    func testInitialState() {
        let vm = OnboardingViewModel()
        XCTAssertTrue(vm.selectedArchetypes.isEmpty)
        XCTAssertFalse(vm.canContinue)
    }

    func testToggleArchetype() {
        let vm = OnboardingViewModel()
        vm.toggleArchetype(.oldMoney)
        XCTAssertTrue(vm.selectedArchetypes.contains(.oldMoney))
        XCTAssertTrue(vm.canContinue)

        vm.toggleArchetype(.oldMoney)
        XCTAssertFalse(vm.selectedArchetypes.contains(.oldMoney))
        XCTAssertFalse(vm.canContinue)
    }

    func testMultipleSelections() {
        let vm = OnboardingViewModel()
        vm.toggleArchetype(.oldMoney)
        vm.toggleArchetype(.minimalist)
        vm.toggleArchetype(.classic)
        XCTAssertEqual(vm.selectedArchetypes.count, 3)
        XCTAssertTrue(vm.canContinue)
    }

    @MainActor
    func testSaveProfile() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: StyleProfile.self, GarmentPiece.self, OutfitSuggestion.self, Feedback.self,
            configurations: config
        )
        let context = container.mainContext

        let vm = OnboardingViewModel()
        vm.toggleArchetype(.oldMoney)
        vm.toggleArchetype(.minimalist)
        vm.saveProfile(context: context)

        let profiles = try context.fetch(FetchDescriptor<StyleProfile>())
        XCTAssertEqual(profiles.count, 1)
        XCTAssertEqual(Set(profiles.first?.archetypes ?? []), Set([.oldMoney, .minimalist]))
    }
}
