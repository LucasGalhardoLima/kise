// KISE/Sources/Models/OutfitSuggestion.swift
import Foundation
import SwiftData

struct AlternativeSwap: Codable, Equatable {
    let swapPieceID: String
    let forPieceID: String
    let reason: String
}

@Model
final class OutfitSuggestion {
    var id: UUID
    var pieceIDs: [UUID]
    var occasion: Occasion?
    var weatherData: Data?
    var reasoning: String
    var layeringNote: String?
    var alternativeSwapData: Data?
    var suggestedAt: Date
    @Relationship var feedback: Feedback?

    var weather: WeatherSnapshot? {
        get {
            guard let data = weatherData else { return nil }
            return try? JSONDecoder().decode(WeatherSnapshot.self, from: data)
        }
        set {
            weatherData = try? JSONEncoder().encode(newValue)
        }
    }

    var alternativeSwap: AlternativeSwap? {
        get {
            guard let data = alternativeSwapData else { return nil }
            return try? JSONDecoder().decode(AlternativeSwap.self, from: data)
        }
        set {
            alternativeSwapData = try? JSONEncoder().encode(newValue)
        }
    }

    init(
        pieceIDs: [UUID],
        occasion: Occasion?,
        weather: WeatherSnapshot?,
        reasoning: String,
        layeringNote: String? = nil,
        alternativeSwap: AlternativeSwap? = nil
    ) {
        self.id = UUID()
        self.pieceIDs = pieceIDs
        self.occasion = occasion
        self.reasoning = reasoning
        self.layeringNote = layeringNote
        self.suggestedAt = Date()
        self.feedback = nil

        self.weatherData = try? JSONEncoder().encode(weather)
        self.alternativeSwapData = try? JSONEncoder().encode(alternativeSwap)
    }
}
