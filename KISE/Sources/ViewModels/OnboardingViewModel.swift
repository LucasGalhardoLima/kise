// KISE/Sources/ViewModels/OnboardingViewModel.swift
import SwiftUI
import SwiftData

@Observable
final class OnboardingViewModel {
    var selectedArchetypes: Set<StyleArchetype> = []

    var canContinue: Bool {
        !selectedArchetypes.isEmpty
    }

    func toggleArchetype(_ archetype: StyleArchetype) {
        if selectedArchetypes.contains(archetype) {
            selectedArchetypes.remove(archetype)
        } else {
            selectedArchetypes.insert(archetype)
        }
    }

    func isSelected(_ archetype: StyleArchetype) -> Bool {
        selectedArchetypes.contains(archetype)
    }

    @MainActor
    func saveProfile(context: ModelContext) {
        let profile = StyleProfile(archetypes: Array(selectedArchetypes))
        context.insert(profile)
        try? context.save()
    }
}
