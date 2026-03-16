// KISE/Sources/ViewModels/SuggestionViewModel.swift
import Foundation
import SwiftData

@Observable
final class SuggestionViewModel {
    var currentSuggestion: OutfitSuggestion?
    var suggestedPieces: [GarmentPiece] = []
    var alternativeSwap: AlternativeSwap?
    var alternativeForPiece: GarmentPiece?

    var isLoading = false
    var isRegenerating = false
    var error: String?

    var occasion: Occasion = .everyday
    var boldness: Double = 0.3

    var weather: WeatherSnapshot? {
        weatherService.currentWeather
    }

    var cityName: String? {
        weatherService.currentWeather?.cityName
    }

    private let suggestionService = SuggestionService()
    private let weatherService = WeatherService()

    var hasMinimumPieces: Bool {
        !suggestedPieces.isEmpty || currentSuggestion != nil
    }

    func fetchSuggestion(context: ModelContext, regenerating: Bool = false) async {
        if regenerating {
            isRegenerating = true
        } else {
            isLoading = true
        }
        error = nil

        // Fetch style profile
        let profileDescriptor = FetchDescriptor<StyleProfile>()
        guard let profile = try? context.fetch(profileDescriptor).first,
              !profile.archetypes.isEmpty else {
            error = "Complete style onboarding first"
            isLoading = false
            return
        }

        // Fetch active wardrobe pieces
        let wardrobeDescriptor = FetchDescriptor<GarmentPiece>(
            predicate: #Predicate { $0.isActive }
        )
        let wardrobe = (try? context.fetch(wardrobeDescriptor)) ?? []

        guard wardrobe.count >= 2 else {
            error = "Add at least 2 pieces to get suggestions"
            isLoading = false
            return
        }

        // Fetch recent suggestions (last 5)
        var recentDescriptor = FetchDescriptor<OutfitSuggestion>(
            sortBy: [SortDescriptor(\.suggestedAt, order: .reverse)]
        )
        recentDescriptor.fetchLimit = 5
        let recent = (try? context.fetch(recentDescriptor)) ?? []

        // Fetch weather
        await weatherService.fetchWeather()

        do {
            let response: SuggestionAPIResponse
            do {
                response = try await suggestionService.fetchSuggestion(
                    archetypes: profile.archetypes,
                    boldness: boldness,
                    occasion: occasion,
                    weather: weatherService.currentWeather,
                    wardrobe: wardrobe,
                    recentSuggestions: recent
                )
            } catch {
                // Try on-device fallback on iOS 26+
                response = try await fetchOnDeviceFallback(
                    archetypes: profile.archetypes,
                    wardrobe: wardrobe
                )
            }

            // Map response piece UUIDs to actual GarmentPiece objects
            let pieceMap = Dictionary(uniqueKeysWithValues: wardrobe.map { ($0.id.uuidString, $0) })
            let matched = response.pieces.compactMap { pieceMap[$0] }

            // Build alternative swap if present
            var swap: AlternativeSwap?
            var swapPiece: GarmentPiece?
            if let alt = response.alternative_piece {
                swap = AlternativeSwap(
                    swapPieceID: alt.swap,
                    forPieceID: alt.for,
                    reason: alt.why
                )
                swapPiece = pieceMap[alt.for]
            }

            // Create and persist the suggestion
            let suggestion = OutfitSuggestion(
                pieceIDs: matched.map(\.id),
                occasion: occasion,
                weather: weatherService.currentWeather,
                reasoning: response.reasoning,
                layeringNote: response.layering_note,
                alternativeSwap: swap
            )
            context.insert(suggestion)
            try? context.save()

            currentSuggestion = suggestion
            suggestedPieces = matched
            alternativeSwap = swap
            alternativeForPiece = swapPiece
        } catch {
            self.error = error.localizedDescription
            // Keep showing previous suggestion if available
        }

        isLoading = false
        isRegenerating = false
    }

    func submitFeedback(liked: Bool, context: ModelContext) {
        guard let suggestion = currentSuggestion else { return }
        let feedback = Feedback(liked: liked)
        suggestion.feedback = feedback
        context.insert(feedback)
        try? context.save()
    }

    func regenerate(context: ModelContext) async {
        await fetchSuggestion(context: context, regenerating: true)
    }

    private func fetchOnDeviceFallback(
        archetypes: [StyleArchetype],
        wardrobe: [GarmentPiece]
    ) async throws -> SuggestionAPIResponse {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            let onDevice = OnDeviceSuggestionService()
            return try await onDevice.fetchSuggestion(
                archetypes: archetypes,
                boldness: boldness,
                occasion: occasion,
                weather: weatherService.currentWeather,
                wardrobe: wardrobe
            )
        }
        #endif
        throw SuggestionError.invalidResponse
    }

    func applyAlternative() {
        guard let swap = alternativeSwap,
              let altPiece = alternativeForPiece else { return }

        // Swap the piece in the displayed list
        if let idx = suggestedPieces.firstIndex(where: { $0.id.uuidString == swap.swapPieceID }) {
            suggestedPieces[idx] = altPiece
        }

        // Clear the swap after applying
        alternativeSwap = nil
        alternativeForPiece = nil
    }
}
