// KISE/Sources/App/AppState.swift
import SwiftUI
import SwiftData

@Observable
final class AppState {
    var hasCompletedOnboarding: Bool = false

    @MainActor
    func checkOnboardingStatus(context: ModelContext) {
        let descriptor = FetchDescriptor<StyleProfile>()
        let profiles = (try? context.fetch(descriptor)) ?? []
        hasCompletedOnboarding = !profiles.isEmpty
    }

    @MainActor
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}
