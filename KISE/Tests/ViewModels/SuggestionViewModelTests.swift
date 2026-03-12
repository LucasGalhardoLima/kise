// KISE/Tests/ViewModels/SuggestionViewModelTests.swift
import Testing
@testable import KISE

struct SuggestionViewModelTests {
    @Test func initialState() {
        let vm = SuggestionViewModel()
        #expect(vm.currentSuggestion == nil)
        #expect(vm.suggestedPieces.isEmpty)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
        #expect(vm.occasion == .everyday)
        #expect(vm.boldness == 0.3)
    }

    @Test func defaultBoldnessIsSafe() {
        let vm = SuggestionViewModel()
        #expect(vm.boldness >= 0.0 && vm.boldness <= 0.3)
    }

    @Test func occasionCanBeChanged() {
        let vm = SuggestionViewModel()
        vm.occasion = .dateNight
        #expect(vm.occasion == .dateNight)
    }
}
