// KISE/Sources/Services/SuggestionService.swift
import Foundation

struct SuggestionAPIResponse: Codable {
    let pieces: [String]
    let reasoning: String
    let layering_note: String?
    let alternative_piece: AlternativePieceResponse?

    struct AlternativePieceResponse: Codable {
        let swap: String
        let `for`: String
        let why: String
    }
}

struct SuggestionAPIError: Codable {
    let error: String
}

final class SuggestionService {
    static let proxyBaseURL = "https://kise-proxy.lima-galhardo.workers.dev"

    func fetchSuggestion(
        archetypes: [StyleArchetype],
        boldness: Double,
        occasion: Occasion,
        weather: WeatherSnapshot?,
        wardrobe: [GarmentPiece],
        recentSuggestions: [OutfitSuggestion]
    ) async throws -> SuggestionAPIResponse {
        let url = URL(string: "\(Self.proxyBaseURL)/suggest")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let payload = buildPayload(
            archetypes: archetypes,
            boldness: boldness,
            occasion: occasion,
            weather: weather,
            wardrobe: wardrobe,
            recentSuggestions: recentSuggestions
        )

        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SuggestionError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let apiError = try? JSONDecoder().decode(SuggestionAPIError.self, from: data) {
                throw SuggestionError.serverError(apiError.error)
            }
            throw SuggestionError.httpError(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(SuggestionAPIResponse.self, from: data)
    }

    private func buildPayload(
        archetypes: [StyleArchetype],
        boldness: Double,
        occasion: Occasion,
        weather: WeatherSnapshot?,
        wardrobe: [GarmentPiece],
        recentSuggestions: [OutfitSuggestion]
    ) -> SuggestionPayload {
        let wardrobeItems = wardrobe.map { piece in
            WardrobeItem(
                id: piece.id.uuidString,
                category: piece.category.rawValue,
                color: piece.color,
                fit: piece.fit.rawValue,
                material: piece.material,
                weight: piece.weight.rawValue,
                formality: piece.formality.rawValue
            )
        }

        let recent = recentSuggestions.suffix(5).map { suggestion in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return RecentSuggestionItem(
                date: dateFormatter.string(from: suggestion.suggestedAt),
                piece_ids: suggestion.pieceIDs.map(\.uuidString),
                feedback: suggestion.feedback?.payloadValue ?? "none"
            )
        }

        var weatherPayload: WeatherPayload?
        if let w = weather {
            weatherPayload = WeatherPayload(
                temperature: w.temperature,
                feels_like: w.feelsLike,
                humidity: w.humidity,
                wind: w.windSpeed,
                condition: w.condition,
                hourly_forecast: w.hourlyForecast.map { entry in
                    HourlyForecastItem(
                        hour: entry.hour,
                        temp: entry.temperature,
                        condition: entry.condition
                    )
                }
            )
        }

        return SuggestionPayload(
            style_archetypes: archetypes.map(\.assetKey),
            boldness: boldness,
            occasion: occasion.rawValue,
            weather: weatherPayload,
            wardrobe: wardrobeItems,
            recent_suggestions: recent
        )
    }
}

// MARK: - Payload Types

struct SuggestionPayload: Encodable {
    let style_archetypes: [String]
    let boldness: Double
    let occasion: String
    let weather: WeatherPayload?
    let wardrobe: [WardrobeItem]
    let recent_suggestions: [RecentSuggestionItem]
}

struct WeatherPayload: Encodable {
    let temperature: Double
    let feels_like: Double
    let humidity: Double
    let wind: Double
    let condition: String
    let hourly_forecast: [HourlyForecastItem]
}

struct HourlyForecastItem: Encodable {
    let hour: Int
    let temp: Double
    let condition: String
}

struct WardrobeItem: Encodable {
    let id: String
    let category: String
    let color: String
    let fit: String
    let material: String
    let weight: String
    let formality: String
}

struct RecentSuggestionItem: Encodable {
    let date: String
    let piece_ids: [String]
    let feedback: String
}

// MARK: - Errors

enum SuggestionError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case serverError(String)
    case noActivePieces

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "Invalid response from server"
        case .httpError(let code): "Server returned status \(code)"
        case .serverError(let msg): msg
        case .noActivePieces: "Add some pieces to your wardrobe first"
        }
    }
}
