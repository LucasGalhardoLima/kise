// KISE/Sources/Services/BackgroundPrefetchService.swift
import Foundation
import BackgroundTasks
import SwiftData

enum BackgroundPrefetchService {
    static let taskIdentifier = "com.kise.app.suggestion-prefetch"

    static func register() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            handleRefresh(refreshTask)
        }
    }

    static func scheduleNextRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        // Schedule for early morning — iOS decides the exact time
        request.earliestBeginDate = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 6),
            matchingPolicy: .nextTime
        )
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handleRefresh(_ task: BGAppRefreshTask) {
        // Schedule the next refresh before starting work
        scheduleNextRefresh()

        let fetchTask = Task {
            await prefetchSuggestion()
        }

        task.expirationHandler = {
            fetchTask.cancel()
        }

        Task {
            await fetchTask.value
            task.setTaskCompleted(success: true)
        }
    }

    @MainActor
    private static func prefetchSuggestion() async {
        // Create a temporary model container to access data
        guard let container = try? ModelContainer(
            for: StyleProfile.self, GarmentPiece.self, OutfitSuggestion.self, Feedback.self
        ) else { return }

        let context = container.mainContext

        // Check prerequisites
        let profileDescriptor = FetchDescriptor<StyleProfile>()
        guard let profile = try? context.fetch(profileDescriptor).first,
              !profile.archetypes.isEmpty else { return }

        let wardrobeDescriptor = FetchDescriptor<GarmentPiece>(
            predicate: #Predicate { $0.isActive }
        )
        let wardrobe = (try? context.fetch(wardrobeDescriptor)) ?? []
        guard wardrobe.count >= 2 else { return }

        // Fetch recent suggestions
        var recentDescriptor = FetchDescriptor<OutfitSuggestion>(
            sortBy: [SortDescriptor(\.suggestedAt, order: .reverse)]
        )
        recentDescriptor.fetchLimit = 5
        let recent = (try? context.fetch(recentDescriptor)) ?? []

        // Fetch weather
        let weatherService = WeatherService()
        await weatherService.fetchWeather()

        // Fetch suggestion
        let suggestionService = SuggestionService()
        do {
            let response = try await suggestionService.fetchSuggestion(
                archetypes: profile.archetypes,
                boldness: 0.3,
                occasion: .everyday,
                weather: weatherService.currentWeather,
                wardrobe: wardrobe,
                recentSuggestions: recent
            )

            let pieceMap = Dictionary(uniqueKeysWithValues: wardrobe.map { ($0.id.uuidString, $0) })
            let matched = response.pieces.compactMap { pieceMap[$0] }

            var swap: AlternativeSwap?
            if let alt = response.alternative_piece {
                swap = AlternativeSwap(
                    swapPieceID: alt.swap,
                    forPieceID: alt.for,
                    reason: alt.why
                )
            }

            let suggestion = OutfitSuggestion(
                pieceIDs: matched.map(\.id),
                occasion: .everyday,
                weather: weatherService.currentWeather,
                reasoning: response.reasoning,
                layeringNote: response.layering_note,
                alternativeSwap: swap
            )
            context.insert(suggestion)
            try? context.save()
        } catch {
            // Silently fail — user will get a live request when they open the app
        }
    }
}
