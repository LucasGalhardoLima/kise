// KISE/Sources/Services/OnDeviceSuggestionService.swift
import Foundation

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26, *)
@Generable
struct OnDeviceSuggestionOutput {
    @Guide(description: "Array of garment piece UUIDs forming the outfit")
    var pieces: [String]

    @Guide(description: "1-2 sentence explanation of why this combination works")
    var reasoning: String

    @Guide(description: "Optional note about layering for weather transitions")
    var layeringNote: String?
}

@available(iOS 26, *)
final class OnDeviceSuggestionService {

    func fetchSuggestion(
        archetypes: [StyleArchetype],
        boldness: Double,
        occasion: Occasion,
        weather: WeatherSnapshot?,
        wardrobe: [GarmentPiece]
    ) async throws -> SuggestionAPIResponse {
        let session = LanguageModelSession()

        let prompt = buildPrompt(
            archetypes: archetypes,
            boldness: boldness,
            occasion: occasion,
            weather: weather,
            wardrobe: wardrobe
        )

        let response = try await session.respond(to: prompt, generating: OnDeviceSuggestionOutput.self)
        let output = response.content

        return SuggestionAPIResponse(
            pieces: output.pieces,
            reasoning: output.reasoning,
            layering_note: output.layeringNote,
            alternative_piece: nil // On-device model doesn't suggest alternatives
        )
    }

    private func buildPrompt(
        archetypes: [StyleArchetype],
        boldness: Double,
        occasion: Occasion,
        weather: WeatherSnapshot?,
        wardrobe: [GarmentPiece]
    ) -> String {
        var parts: [String] = []

        parts.append("You are a personal wardrobe consultant. Select an outfit from these pieces.")
        parts.append("Style: \(archetypes.map(\.displayName).joined(separator: ", "))")
        parts.append("Occasion: \(occasion.displayName)")
        parts.append("Boldness: \(boldness) (0=safe, 1=bold)")

        if let w = weather {
            parts.append("Weather: \(Int(w.temperature))°C, \(w.condition)")
        }

        parts.append("\nWardrobe:")
        for piece in wardrobe {
            parts.append("- \(piece.id.uuidString): \(piece.color) \(piece.category.displayName) (\(piece.fit.displayName), \(piece.material), \(piece.weight.displayName))")
        }

        parts.append("\nSelect 2-4 pieces that form a cohesive outfit. Return their UUIDs and explain why they work together.")

        return parts.joined(separator: "\n")
    }
}
#endif
